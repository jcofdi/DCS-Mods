#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"
#include "common/stencil.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "common/splines.hlsl"
#define  ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"
#include "ParticleSystem2/common/motion.hlsl"
#include "noise/noise3D.hlsl"
#include "common/softParticles.hlsl"

float4 		params;
#define		time			params.x
#define		level			params.y
#define 	wind            params.zw

struct VS_OUTPUT
{
	float4 posRad		: TEXCOORD0; // pos, radius 
	float4 params 		: TEXCOORD1; //size, opacity, angle, nAge
};

struct PS_INPUT
{
	float4 pos			: SV_POSITION;
	float4 sunColor 	: TEXCOORD0;
	float4 uv 			: TEXCOORD1;
	float4 projPos		: TEXCOORD2;
	float3 normal		: NORMAL0;
};

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};


float SamplePerlinNoise(float3 uvw, float scale)
{
	scale *= 0.5;
	uvw *= scale;

	float w0 = pnoise(uvw*scale*2, scale*2)*0.5+0.5;
	float w1 = pnoise(uvw*scale*7 + 0.16412, scale*7)*0.5+0.5;
	float w2 = pnoise(uvw*scale*14 + 0.05712, scale*14)*0.5+0.5;
	float w3 = pnoise(uvw*scale*18 + 0.13192, scale*18)*0.5+0.5;

	return 0.6*w0 + 0.25*w1 + 0.1*w2 + w3*0.05;
}

//float calcVerticalTransWithAirResist(float vertSpeed, float mass, float c, float time)
float calcVerticalTransWithAirResistLaunch(float vertSpeed, float c, float timeSmoke, float a)
{
	float mass = 1.0;
	//float c = 3.0;
	//c = 6.5;
	mass = 0.6;
	vertSpeed *= 0.5;
	const float g = a;
	const float Vt = mass*g/c;
	const float k = (1-exp(-g*timeSmoke/Vt))*Vt/g;

	float tau = mass/(c*vertSpeed);

	return (vertSpeed+Vt)*k - Vt*timeSmoke;

}

VS_OUTPUT VS_LAUNCH_SMOKE(
	float4 startPosBTime	: TEXCOORD0,		// particle position and birth time
	float4 offsetLifeTime	: TEXCOORD1,		// random offset for each particle (up direction is y, and xz is perpendicular to y and to speed vector); particle life time
	float3 startSpeed		: TEXCOORD2,
	float2 rand				: TEXCOORD3,		// two rand params
	uniform bool 			  bClouds) 		
{
	#define 	startPos 			startPosBTime.xyz
	#define 	birthTime 			startPosBTime.w

	VS_OUTPUT o;
	o.posRad.xyz = startPos - worldOffset;
	float age = time - birthTime;
	float nAge = age/offsetLifeTime.w;

	float rand0 = noise1D(rand.y + 0.492841);
	rand0 *= 0.9;
	rand0 += 0.1;

	float2 rand2vec = float2(noise1D(rand.x + 0.21485), noise1D(rand.y + 0.3588));
	float rand2 = noise1D(rand.x + 0.1204);

	float speedYMult = 220.0;
	float speedXZMult = 140.0;

	float age_thres = abs(startPos.y - level)/ max(abs(speedYMult*(0.7*rand0+0.3*startSpeed.y)), 0.1);
	float3 trans = calcTranslationWithAirResistance(offsetLifeTime.xyz - 0.5, 1.0, 2.0, age);
	o.posRad.xz += rand2*25.0*trans.xz;


	float3 newOffset = (offsetLifeTime.xyz - 0.5);
	newOffset.y = 0.0;
	newOffset = normalize(newOffset)*smoothstep(0.0, age_thres/offsetLifeTime.w, nAge);
	trans = calcTranslationWithAirResistance(newOffset, 0.1, 5.0, age);

	o.posRad.xz += (rand2*0.5+0.5)*10.0*trans.xz;
	
	float3 cross1 = cross(startSpeed, float3(1.0, 0.0, 0.0));
	cross1 = normalize(cross1);
	float3 cross2 = cross(cross1, startSpeed);
	cross2 = normalize(normalize(cross2));
	//o.posRad.xz += smoothstep(age, age_thres, offsetLifeTime.w)*(rand2*0.5+0.5)*10000.0*trans.xz;

	o.posRad.xz += (rand.x*0.3+0.7)*wind*age*1.2;

	//o.posRad.xz += smoothstep(age_thres, offsetLifeTime.w, age)*10000.0*cross2.xz;

	//o.posRad.xyz = 1.0*smoothstep(age_thres, offsetLifeTime.w, age)*(cross1 + cross2);
	//o.posRad.xyz += speedMult*(rand0*0.7+0.3)*age*startSpeed; 

	float vert_trans = calcVerticalTransWithAirResistLaunch(speedYMult*(rand0*0.7+0.3)*startSpeed.y, 1.4, age, 0.5);

	float y_par = smoothstep(0.0, 10.0, -(startPos.y + vert_trans - level));
	o.posRad.xz += y_par*20.0*float2(rand2vec.x-0.5, rand2vec.y-0.5);


	if (abs(vert_trans) < abs(level - startPos.y)) {
		o.posRad.y += vert_trans;
	}

	else {
		o.posRad.y = level - worldOffset.y;

		//o.posRad.y -= speedYMult*(rand0*0.7+0.3)*min((age-age_thres), 0.15)*startSpeed.y;

		//o.posRad.y += 0.3*(0.5+0.5*rand2)*pow(age,2)/2;
	}

	speedYMult = 10.0;
	float c = 3.0*(1.0 - 0.4*rand2);
	float addY = calcVerticalTransWithAirResistLaunch(-speedYMult*(rand0*0.7+0.3)*startSpeed.y, c, max(age-1.2*age_thres, 0.0), -1.0);
	//addY = 0.0;
	o.posRad.y += 1.3*addY;

	trans = calcTranslationWithAirResistance(speedXZMult*(rand0*0.2+0.8)*startSpeed, 0.8, 2.0, age);

	o.posRad.xz += trans.xz;
	//o.posRad.xz += speedXZMult*(rand0*0.7+0.3)*age*startSpeed.xz;

	//o.posRad.y += 0.5*((1.0 - age_thres/offsetLifeTime.w)*0.5+0.5*rand2 + 0.1)*pow(age,2)/2;

	//o.posRad.y += 0.3*(0.5+0.5*rand2)*pow(age,2)/2;

	float tt = length(offsetLifeTime.xyz - 0.5);
	tt *= rand2;

	o.posRad.w = tt;

	float ampl = 15.0;

	//o.params.x = ampl*abs(sin(100.0*2*PI*frac(birthTime)))*(smoothstep(0.0, 1.0, nAge)*1.0 + 0.4);

	o.params.x = ampl*(noise1D(rand.y + 0.23582)*1.0 + 1.0)*(smoothstep(0.0, 1.0, nAge)*7.0 + 0.65);

	o.params.x *= smoothstep(0.0, 0.1, age);

	//float randY = SamplePerlinNoise(rand2*(offsetLifeTime.xyz - 0.5), 100.0);
	//o.posRad.y = max(o.posRad.y, level + randY*2.0 + o.params.x/10.0 - worldOffset.y);

	//o.posRad.y = max(o.posRad.y, level + o.params.x/10.0 - worldOffset.y);


	//o.posRad.y = level - worldOffset.y + 2.0;
	o.params.y = (1.0 - smoothstep(0.0, 1.0, nAge))*max((1.0 - 0.7*tt), 0.1);

	//o.params.y *= smoothstep(0.0, 0.01, nAge)*max((1.0 - 0.7*tt), 0.1);

	//if(bClouds)
		//o.params.y *= min(getAtmosphereTransmittance(0).r, 1.0);

	o.params.y *= pow(1.0 - smoothstep(0.1, 1.0, nAge), 2);

	float rotSpeed = smoothstep(0.0, offsetLifeTime.w/15.0, age);
	//rotSpeed = age*lerp(1.0, 0.1, rotSpeed);

	rotSpeed = 0.1*age;

	o.params.z = rand.y * 2 * PI - 2 * PI * rotSpeed * (0.1 + 0.9 * 2.0*(rand.x-0.5));
	//o.params.z = rand.y * 2 * PI;
	o.params.w = nAge;
	return o;

	#undef		startPos
	#undef		birthTime	
}


[maxvertexcount(4)]
void GS_LAUNCH_SMOKE(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream)
{
	PS_INPUT o;
	
	o.sunColor.xyz = getPrecomputedSunColor(0);
	o.sunColor.w = max(min(1.0 - input[0].posRad.w, 1.0), 0.0);
	o.sunColor.w = exp(-0.5*o.sunColor.w);

	float4 worldPos = float4(input[0].posRad.xyz, 1.0);
	worldPos = mul(worldPos, gView);
	worldPos /= worldPos.w;

	float2 sc;
	sincos(input[0].params.z, sc.x, sc.y);

	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	float4 uvOffsetScale = getTextureFrameUV16x8(pow(input[0].params.w, 0.5)*(16*8-1));

	#if defined(PS_HALO) && !defined(DEBUG_NO_HALO)
		o.uv.w = getHaloFactor(sunDir.xyz, input[0].posRad.xyz - gViewInv._41_42_43, 6);
	#else
		o.uv.w = 0;
	#endif

	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;

		pos.xy += mul(input[0].params.x*particle[ii].xy, M);

		float3 worldPosNew = mul(pos, gViewInv) + 0.1*normalize(gCameraPos - input[0].posRad.xyz);
		o.normal = normalize(worldPosNew - input[0].posRad.xyz);

		o.uv.xy = particle[ii].xy + 0.5;

		o.uv.z = input[0].params.y;
		o.pos = mul(pos, gProj);
		o.projPos = o.pos;
		outputStream.Append(o);
	}
	outputStream.RestartStrip();  

}

float4 PS_LAUNCH_SMOKE(PS_INPUT i): SV_Target0
{
	float spAlphaC = depthAlpha(i.projPos, 1.0f);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;
	clr.a *= i.uv.z*0.1*spAlphaC; 

	clip(clr.a - 0.01);


	clr.rgb = normalize(clr.rgb*2-1);



	float3 normal = normalize(i.normal);

	float light = saturate(dot(-normal, gSunDir));
	light = light*0.4 + 0.6;
	float3 color = float3(1.0, 1.0, 1.0)*0.8;

	float lightMult = i.sunColor.w;

	#if defined(PS_HALO) && !defined(DEBUG_NO_HALO)
		clr.rgb = shading_AmbientSunHalo(color, AmbientAverage, i.sunColor.xyz*max(0, lightMult*light/(2*PI)), HALO_FACTOR * (1 - min(1, 6*finalColor.a)) );
	#else
		clr.rgb = shading_AmbientSun(color, AmbientAverage, i.sunColor.xyz*max(0, lightMult*light/(2*PI)));
	#endif

	clr.rgb *= min(gSunIntensity*0.1, 1.0);
	clr = float4(applyPrecomputedAtmosphere(clr.rgb, 0), clr.a);
	return clr;
}

#define PASS_BODY(vs, gs, ps)  { SetVertexShader(vs); SetHullShader (NULL); SetDomainShader(NULL); SetGeometryShader(gs); SetPixelShader(ps); \
		SetDepthStencilState(enableDepthBufferNoWrite, 0); \
		SetRasterizerState(cullNone); SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);}

GeometryShader	gsCompiled = CompileShader(gs_5_0, GS_LAUNCH_SMOKE());
PixelShader		psCompiled = CompileShader(ps_5_0, PS_LAUNCH_SMOKE());

technique10 SmokeLaunch
{
	pass basic			PASS_BODY(CompileShader(vs_5_0, VS_LAUNCH_SMOKE(false)), gsCompiled, psCompiled)
	pass clouds			PASS_BODY(CompileShader(vs_5_0, VS_LAUNCH_SMOKE(true)), gsCompiled, psCompiled)
}
