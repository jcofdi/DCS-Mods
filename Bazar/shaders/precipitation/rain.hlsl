
//#define DEBUG_HUGE_PARTICLE
//#define ENABLE_EXPERIMENTAL

static const float raindropScale = 0.015;
static const float raindropLengthFactor = 2.0;


static const float rainSpecularPower = 0.02;
static const float rainSpecularAphaFactor = 0.2;
static const float rainOpacityBase = 0.4;
static const float rainHaloFactor = 1;
//static const float rainHaloAlphaFactor = 0.5333333;
static const float rainHaloAlphaFactor = 0.5333333*0.0;
static const float rainLightsAlphaFactor = 0.1;

#if !defined(PRECIPITATION_TILED_LIGHTING)
static const float raindropBrightness = 6;
#else
// Tweak this to change overall raindrop brightness
static const float raindropBrightness = 4;
// Tweak this to change impact of light sources 
static const float rainBaseDiffusePower = 4.0;
static const float rainBaseSpecularPower = 1.0;
static const float rainBaseTranslucency = 0.2;

#endif

// GEOMETRY SHADER ---------------------------------
//ориентируем партикл вдоль вектора скорости в ћ—  и поворачиваем вокруг него на камеру
[maxvertexcount(4)]
void gsRain(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT_RAIN> outputStream)
{
	float RAND = input[0].pos.w;

	float effectPower = SampleCloudsDensity(input[0].pos.xyz);

	if (effectPower==0 || (float(input[0].vertId) > particlesMax * effectPower))
		return;

	float4 vPos = mul(float4(input[0].pos.xyz,1), gView); vPos /= vPos.w;

	float nDistToCam = min(1, length(input[0].pos.xyz - gCameraPos.xyz) / (clipRadius + clipSphereOffset));
	float scale = raindropScale*(0.5+RAND) * (1+pow(nDistToCam*0.6,1.5)*2) * (0.8+0.2*effectPower);//домножаем на масштаб частицы

	float2 rndVel = 1.5 * (noise2(float2(RAND, RAND+3.4344))*2-1) * effectPower * (0.5+0.5*nDistToCam) * (0.5+0.5*sin((gModelTime*2+RAND)*PI));

	float3 speedWorldSpace = -cameraVel + rainVel + float3(rndVel.x, 0, rndVel.y);
	float3 speedViewSpace = mul(speedWorldSpace, (float3x3)gView);
	float  speedValue = length(speedViewSpace);
	float3 speedDir = speedViewSpace / speedValue;
	float  blurOffset = -(speedDir.z)*0.5;

	//считаем проекцию вектора скорости на экран
	float3 dir = getScreenDirLength(vPos, speedViewSpace);

	float screenDist = dir.z;
	float stretchFactor = max(1 + 15*(1-abs(speedDir.z)), min(60,  screenDist * (1+min(speedValue, 1000)*2)  )) * raindropLengthFactor;
	float opacityFactor = 1.0 / (1 + screenDist + 0.01*(speedValue));
	// float opacityFactor = 1.0 / (1 + stretchFactor*0.005);

#ifdef DEBUG_HUGE_PARTICLE
	// Note: this removes length change of particles due to screen projected speed!
	stretchFactor = 1.0;
	scale *= 10.0;
#endif

	speedDir = float3(dir.xy, 0) * stretchFactor * scale;
	float2 side = float2(-dir.y, dir.x) * scale * (0.5 + 0.5*nDistToCam);

	PS_INPUT_RAIN o;
#if !defined(PRECIPITATION_TILED_LIGHTING)
	float2x2 M = {dir.yx, -dir.x, dir.y};
	o.sunDirM.xyz = float3(-gSunDirV.x, gSunDirV.yz);
	o.sunDirM.xy = mul(o.sunDirM.xy, M);
#endif
	o.wPos.xyz = input[0].pos.xyz - gCameraPos.xyz;
	o.wPos.w = getHaloFactor(gSunDir, o.wPos.xyz, 16);
	o.wPos.w = max(o.wPos.w, getHaloFactor(-gSunDir, o.wPos.xyz, 8) * 0.1 );

	float shadow = getCloudsShadow(input[0].pos.xyz);
	o.wPos.w *= rainHaloFactor * shadow;

	o.params.z = max(0, 1-max(0, nDistToCam-0.8)*5);// fade factor
	o.params.z *= opacityFactor;//////////////////////////////////////////////////////////////////////////////////////////
	o.params.w = saturate(vPos.z-0.8);

#if (PRECIPITATION_TILED_LIGHTING)
	float3 billboardUp = -normalize(speedWorldSpace); 
	float3 billboardToCamera = -normalize(o.wPos.xyz);
	float3 billboardRight = normalize(cross(billboardUp, billboardToCamera));
	o.billboardToWorld = float3x3(billboardRight, billboardUp, billboardToCamera);
	o.exposureFactor = 1.0 / max(1.0, stretchFactor);
#endif
 
	float visibility = o.params.z>3.0e-2 ? 1.0 : 0.0;

	[unroll]
	for (uint ii = 0; ii < 4; ++ii)
	{
		float4 p = {staticVertexData[ii].xy, vPos.z, 1};
		p.xy = vPos.xy + side * p.x + speedDir.xy * (p.y + blurOffset);
		o.pos = mul(p * visibility, gProj);
		o.params.xy = staticVertexData[ii].zw;//uv
		outputStream.Append(o);
	}
	outputStream.RestartStrip();
}

#if !defined(ENABLE_EXPERIMENTAL)

#if !defined(PRECIPITATION_TILED_LIGHTING)

float4 psRain(in PS_INPUT_RAIN i, uniform bool bLighting = false) : SV_TARGET0
{
	float2 UV			= i.params.xy;
	float  fadeFactor	= i.params.z;
	float  haloFactor	= i.wPos.w;

	float3 toCam = normalize(-i.wPos.xyz); // camera origin space

	float4 normSphere = particleTex.Sample(gTrilinearClampSampler, UV);
	normSphere.a *= fadeFactor; //фэйдинг на краях сферы
	clip(normSphere.a - 0.01);
	normSphere.xyz = normalize(normSphere.xyz * 2.0 - 1.0);

	float light = dot(normSphere.xyz, i.sunDirM) * 0.25 + 0.75; // освещенка [0.0; 1]

	//преломление
	float3 refractClr = AmbientLight(-toCam) / PI;
	float3 diffuse = (refractClr + refractClr.bbb) * (0.5 * light * raindropBrightness);

	//спекулярчик
	float3 Rspec = reflect(-i.sunDirM, normSphere.xyz);
	float RdotV = max(0, dot(Rspec, toCam));
	
	float3 specular = sunDiffuse.xyz * (pow(RdotV, 3) * rainSpecularPower * gSunIntensity);
	diffuse += specular;

	//---------- ореол ----------------------
	float haloAlpha = haloFactor * haloFactor * (1 - normSphere.a) * rainHaloAlphaFactor;
	diffuse += sunDiffuse.xyz * (gSunIntensity * haloFactor);
	//---------------------------------------
	
	float opacity = rainOpacityBase + haloAlpha + specular.r * rainSpecularAphaFactor;
	if(bLighting)
	{
		float4 additiveLightColor = calculateSumLightingSpecular(toCam, i.wPos.xyz, normSphere.xyz, rainSpecularPower);
		diffuse.rgb += additiveLightColor.rgb * 0.3 * 0.05;
		opacity += additiveLightColor.a * rainLightsAlphaFactor * 0.05;
	}

	return float4(diffuse, normSphere.a * opacity * i.params.w);
}

#else 

float4 psRain(in PS_INPUT_RAIN i, uniform bool bLighting = false) : SV_TARGET0
{
	float2 UV			= i.params.xy;
	float  fadeFactor	= i.params.z;
	float  haloFactor	= i.wPos.w;

	float3 toCam = normalize(-i.wPos.xyz); // camera origin space

	float4 normSphere = particleTex.Sample(gTrilinearClampSampler, UV);
	normSphere.a *= fadeFactor; //фэйдинг на краях сферы
	clip(normSphere.a - 0.01);
	normSphere.xyz = normalize(normSphere.xyz * 2.0 - 1.0);

	// Important! 
	// Intentionally inverting normal to match light-raindrop interaction nature
	// For lighting our normal must be on the other side of raindrop
	float3 worldNormal = -normalize(mul(normSphere.xyz, i.billboardToWorld).xyz);
	
	// Raindrop base color must be unaware of lighting conditions
	// Refraction can't be used as diffuse for lighting calculations
	//float sunAmbient = dot(normSphere.xyz, i.sunDirM) * 0.25 + 0.75;
	float sunAmbient = dot(worldNormal, gSunDir) * 0.25 + 0.75;
	float3 ambient = AmbientLight(-toCam) / PI;
	float3 refractedAmbient = (ambient + ambient.bbb) * (0.5 * raindropBrightness * sunAmbient);

	float3 sunHalo = sunDiffuse.xyz * (gSunIntensity * haloFactor);

	float3 diffuse = 0.1;

	float3 Rspec = reflect(gSunDir, worldNormal);
	float RdotV = max(0, dot(Rspec, toCam));
	float3 specular = pow(RdotV, 3) * rainSpecularPower;
	float3 sunSpecular = (sunDiffuse.xyz * specular) * gSunIntensity;

	float opacity = rainOpacityBase + specular.r * rainSpecularAphaFactor;

	float diffusePower = rainBaseDiffusePower * i.exposureFactor;
	float specularPower = rainBaseSpecularPower * i.exposureFactor;
	float translucency = rainBaseTranslucency * i.exposureFactor;
	float3 additiveLightColor = CalculateDynamicLightingTiled(i.pos.xy, diffuse, specular,
		0.2f, worldNormal.xyz, -toCam, i.wPos.xyz + gCameraPos, 0.0f, float2(diffusePower, specularPower), translucency, LL_TRANSPARENT, true, false);
		
	float3 finalColor = additiveLightColor.rgb + refractedAmbient + sunSpecular + sunHalo;
	//finalColor *= i.exposureFactor;

	return float4(finalColor, normSphere.a * opacity * i.params.w);// * i.exposureFactor;
}

#endif

#else

/*
	Experimental rain with analitical normals
	Current state: too much aliasing, but clean normals
	TODO: dfdx dfdy for "mip" selecation for normal
*/

float3 raindropWorldNormal(float2 p, float3x3 billboardToWorld)
{
	float3 normal;
	normal.xy = p;
	normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normalize(mul(normal, billboardToWorld));
}

float4 psRain(in PS_INPUT_RAIN i, uniform bool bLighting = false) : SV_TARGET0
{
	float2 uv			= i.params.xy;
	float  fadeFactor	= i.params.z;
	float  haloFactor	= i.wPos.w;

	float3 toCam = normalize(-i.wPos.xyz); // camera origin space
	float2 uvc =  uv * 2.0 - 1.0;
	uvc.y = -uvc.y;
	uvc.x *= lerp(1.0, 1.2, 1.0 - uv.y);                  // Squize top of the raindrop 
	uvc -= 0.1 * sign(uvc) * min(abs(uvc.x), abs(uvc.y)); // Enlarge uv space close to diagonals

	// Calculate fading of border and clip unnecessary pixels
	const float clipCalue = 0.99;
	float borderAlpha = 1.0 - length(uvc);
	borderAlpha *= borderAlpha;
	clip(1.0 - length(uvc));

	float3 worldNormal = -raindropWorldNormal(uvc, i.billboardToWorld);
	return float4(worldNormal, 1.0);

	// Raindrop base color must be unaware of lighting conditions
	// Refraction can't be used as diffuse for lighting calculations
	float sunAmbient = dot(worldNormal, gSunDir) * 0.25 + 0.75;
	float3 ambient = AmbientLight(-toCam) / PI;
	float3 refractedAmbient = (ambient + ambient.bbb) * (0.5 * raindropBrightness * sunAmbient);

	float3 sunHalo = sunDiffuse.xyz * (gSunIntensity * haloFactor);

	float3 diffuse = 0.1;

	float3 Rspec = reflect(gSunDir, worldNormal);
	float RdotV = max(0, dot(Rspec, toCam));
	float3 specular = pow(RdotV, 3) * rainSpecularPower;
	float3 sunSpecular = (sunDiffuse.xyz * specular) * gSunIntensity;

	float opacity = rainOpacityBase + specular.r * rainSpecularAphaFactor;

	float diffusePower = rainBaseDiffusePower * i.exposureFactor;
	float specularPower = rainBaseSpecularPower * i.exposureFactor;
	float translucency = rainBaseTranslucency * i.exposureFactor;
	float3 additiveLightColor = CalculateDynamicLightingTiled(i.pos.xy, diffuse, specular,
		0.2f, worldNormal.xyz, -toCam, i.wPos.xyz + gCameraPos, 0.0f, float2(diffusePower, specularPower), translucency, LL_TRANSPARENT, true, false);
		
	float3 finalColor = additiveLightColor.rgb + refractedAmbient + sunSpecular + sunHalo;
	//finalColor *= i.exposureFactor;

	return float4(finalColor, normSphere.a * opacity * i.params.w);// * i.exposureFactor;
}

#endif