
//#define DEBUG_HUGE_PARTICLE

static const float snowflakeScale = 0.03;
static const float snowflakeLengthFactor = 1.0;

static const float snowSpecularPower = 0.2;
static const float snowSpecularAphaFactor = 0.1;
static const float snowOpacityBase = 0.4;
static const float snowHaloFactor = 1.5;
static const float snowHaloAlphaFactor = 0.15;
static const float snowLightsAlphaFactor = 0.1;


#if !defined(PRECIPITATION_TILED_LIGHTING)

static const float snowflakeBrightness = 0.7;
static const float snowDiffusePower = 500.0f * snowflakeBrightness;

#else

static const float snowflakeBrightness = 2.5;
// Tweak this to change impact of light sources 
static const float snowDiffusePower = 1.5f;
static const float snowExposurePower = 0.05f;

#endif


// GEOMETRY SHADER ---------------------------------
//ориентируем партикл вдоль вектора скорости в МСК и поворачиваем вокруг него на камеру
[maxvertexcount(4)]
void gsSnow(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT_RAIN> outputStream)
{
	float RAND = input[0].pos.w;

	float effectPower = SampleCloudsDensity(input[0].pos.xyz);

	if (effectPower==0 || (float(input[0].vertId) > particlesMax * effectPower))
		return;
	
	float4 vPos = mul(float4(input[0].pos.xyz,1), gView); vPos /= vPos.w;

	float nDistToCam = min(1, length(input[0].pos.xyz - gCameraPos.xyz) / (clipRadius + clipSphereOffset));
	float scale = snowflakeScale * (0.5+RAND) * (1 + 3*pow(nDistToCam*0.6,1.5)) * (0.8+0.2*effectPower);

	float3 speedWorldSpace = -cameraVel + rainVel;
	float3 speedViewSpace = mul(speedWorldSpace, (float3x3)gView);
	float  speedValue = length(speedViewSpace);
	float3 speedDir = speedViewSpace / speedValue;
	float  blurOffset = -(speedDir.z)*0.5;

	//считаем проекцию вектора скорости на экран
	float3 dir = getScreenDirLength(vPos, speedViewSpace);
	
	float screenDist = dir.z;
	float stretchFactor = max(1, min(60,  screenDist * (1+min(speedValue, 1000) * 0.12) )) * snowflakeLengthFactor;
	float opacityFactor = 1.0 / (1 + 0.5 * screenDist + 0.02*(speedValue));

#ifdef DEBUG_HUGE_PARTICLE
	// Note: this removes length change of particles due to screen projected speed!
	stretchFactor = 1.0;
	scale *= 10.0;
#endif

	speedDir = float3(dir.xy, 0) * stretchFactor * scale;
	float3 side = float3(-dir.y, dir.x, 0) * scale;
	
	PS_INPUT_RAIN o;
	//o.randomSeed = input[0].vertId;
#if !defined(PRECIPITATION_TILED_LIGHTING)
	o.sunDirM = 0;
#endif
	o.wPos.xyz = input[0].pos.xyz - gCameraPos.xyz;
	o.wPos.w = getHaloFactor(gSunDir, o.wPos.xyz, 16);

	float shadow = getCloudsShadow(input[0].pos.xyz)*0.9+0.1;
	o.wPos.w *= shadow;

	o.params.z = max(0, 1 - max(0, nDistToCam-0.8)*5);// fade factor
	o.params.z *= opacityFactor;
	o.params.w = saturate(vPos.z-1);

#if (PRECIPITATION_TILED_LIGHTING)
	float3 billboardUp = -normalize(speedWorldSpace); 
	float3 billboardToCamera = -normalize(o.wPos.xyz);
	float3 billboardRight = normalize(cross(billboardUp, billboardToCamera));
	o.billboardToWorld = float3x3(billboardRight, billboardUp, billboardToCamera);
	o.exposureFactor = 1.0 / max(1.0, stretchFactor * snowExposurePower);
#endif 

	[unroll]
	for (uint ii = 0; ii < 4; ++ii)
	{
		float4 p = {staticVertexData[ii].xy, vPos.z, 1};
		p.xy = vPos.xy + side.xy * p.x + speedDir.xy * (p.y+blurOffset);
		o.pos = mul(p, gProj);
		o.params.xy = staticVertexData[ii].zw;//uv
		outputStream.Append(o);
	}
	outputStream.RestartStrip();
}

#if !defined(PRECIPITATION_TILED_LIGHTING)

float4 psSnow(in PS_INPUT_RAIN i, uniform bool bLighting = false) : SV_TARGET0
{
	float fadeFactor = i.params.z;
	float haloFactor = i.wPos.w;

	float3 toCam = normalize(-i.wPos.xyz);

	float4 normSphere = particleTex.Sample(gTrilinearClampSampler, i.params.xy);
	normSphere.a *= fadeFactor;
	clip(normSphere.a - 0.01);

	float3 diffuse = (AmbientTop + sunDiffuse.xyz * gSunIntensity) * (snowflakeBrightness / PI);

	//---------- ореол ----------------------
	float haloAlpha = haloFactor * (1-normSphere.a);
	float3 sunHalo = sunDiffuse.xyz * haloFactor * (1-normSphere.a*0.5) * gSunIntensity * snowHaloFactor;
	diffuse += sunHalo;
	//---------------------------------------

	float opacity = snowOpacityBase + haloAlpha*snowHaloAlphaFactor;
	if(bLighting)
	{
		float4 additiveLightColor = calculateSumLighting(toCam, i.wPos.xyz);
		diffuse.rgb += additiveLightColor.rgb*0.4;
		opacity += additiveLightColor.a * snowLightsAlphaFactor;
		return float4(min(1,diffuse), normSphere.a * opacity * i.params.w );
	}

	return float4(diffuse, normSphere.a * opacity * i.params.w );
}

#else

float4 psSnow(in PS_INPUT_RAIN i, uniform bool bLighting = false) : SV_TARGET0
{
	float fadeFactor = i.params.z;
	float haloFactor = i.wPos.w;

	float3 toCam = normalize(-i.wPos.xyz);

	float4 normSphere = particleTex.Sample(gTrilinearClampSampler, i.params.xy);
	normSphere.a *= fadeFactor;
	clip(normSphere.a - 0.01);

	float3 worldNormal = normalize(mul(normSphere.xyz, i.billboardToWorld).xyz);
	
	float sunAmbient = dot(worldNormal, gSunDir) * 0.25 + 0.75;
	float3 ambient = (AmbientTop + 0.02 * sunDiffuse.xyz * gSunIntensity) * snowflakeBrightness * sunAmbient;

	float3 diffuse = 0.1;

	float haloAlpha = haloFactor * (1-normSphere.a);
	float3 sunHalo = sunDiffuse.xyz * haloFactor * (1-normSphere.a*0.5) * gSunIntensity * snowHaloFactor;

	float opacity = snowOpacityBase + haloAlpha * snowHaloAlphaFactor;

	float diffusePower = snowDiffusePower;
	float3 normSphereWorld = normalize(mul(normSphere.xyz, i.billboardToWorld).xyz);
	float3 additiveLightColor = CalculateDynamicLightingTiled(i.pos.xy, diffuse, 0.25f,
		0.2f, worldNormal.xyz, -toCam, i.wPos.xyz + gCameraPos, 0.0f, float2(diffusePower, 1.0f), 1.0f, LL_TRANSPARENT, false, false);
	
	float3 finalColor = additiveLightColor.rgb + ambient + sunHalo;

	return float4(finalColor, normSphere.a * opacity * i.params.w) * i.exposureFactor;
}

#endif
