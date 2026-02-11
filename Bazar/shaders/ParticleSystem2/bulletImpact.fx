#include "common/TextureSamplers.hlsl"
#include "common/States11.hlsl"
#include "common/samplers11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"

#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "ParticleSystem2/common/noiseSimplex.hlsl"
#include "common/random.hlsl"
#include "common/stencil.hlsl"

Texture3D	texFoam;
Texture2D	texTerrainNoise;

float2		uParams;
float3		wind;
float 		emitTimer;

#define power				uParams.x
#define effectLifetimeInv	uParams.y

struct VS_OUTPUT_SPLASH
{
	float4 pos:					POSITION0;
	float3 params:				TEXCOORD0; // UV, transparency, alphaMult, rand2 as radius
	float4 speed:				TEXCOORD1; //speed dir and scalar
	nointerpolation int v_id: 	TEXCOORD2;
};

struct PS_INPUT_SPLASH
{
	float4 pos:							SV_POSITION0;
	float2 uv:							TEXCOORD0; // UV, transparency, alphaMult
	nointerpolation float4 params2:		TEXCOORD1;
	nointerpolation float3 sunColor: 	TEXCOORD2;
	nointerpolation float id_particle: 	TEXCOORD3;
};

struct PS_INPUT_TERRAINS
{
	float4 pos:							SV_POSITION0;
	float2 uv:							TEXCOORD0; // UV, transparency, alphaMult
	nointerpolation float4 params2:		TEXCOORD1;
	nointerpolation float3 sunColor: 	TEXCOORD2;
	nointerpolation int	v_id: TEXCOORD4;
};

VS_OUTPUT_SPLASH VS_SPLASH(
	float4 params:	TEXCOORD0, //startSpeedDir, startSpeedValue
	float4 params2:	TEXCOORD1, uint id: SV_VertexID)
{
	float _sin, _cos; 
	float age = emitTimer - params2.z;
	sincos(params2.y*PI2*14.32, _sin, _cos );

	float3 startPos = float3(_sin, 0, _cos)*params2.y*power;

	VS_OUTPUT_SPLASH o;
	o.pos = float4(startPos - worldOffset, age);
	o.speed = params;
	o.params.x = age * effectLifetimeInv;
	o.params.y = params2.x;
	o.params.z = params2.y;
	o.v_id = id;
	return o;

}

float calcHorisontalTransWithAirResistSplash(in float startSpeed, in float mass, in float c, in float time)
{
	c = 2.5;
	return mass*startSpeed/c*(1-exp(-c*time/mass));

}

float calcHorisontalSpeed(in float startSpeed, in float mass, in float c, in float time)
{
	c = 2.5;

	const float g = 9.80665f;
	const float Vt = mass*g/c;
	const float k = (1-exp(-g*time/Vt))*Vt/g;

	float tau = mass/(c*startSpeed);

	return startSpeed*(exp(-c*time/mass));

}

float calcVerticalTransWithAirResistSplash(in float vertSpeed, in float mass, in float c, in float time)
{
	c = 3.05;
	vertSpeed *= 2.8;

	const float g = 9.80665f;
	const float Vt = mass*g/c;
	const float k = (1-exp(-g*time/Vt))*Vt/g;

	float tau = mass/(c*vertSpeed);

	return (vertSpeed+Vt)*k - Vt*time;

}

float calcVerticalSpeed(in float vertSpeed, in float mass, in float c, in float time)
{
	c = 1.0;

	const float g = 9.80665f;
	const float Vt = mass*g/c;
	const float k = (1-exp(-g*time/Vt))*Vt/g;

	float tau = mass/(c*vertSpeed);

	return Vt-exp(-c*time/mass)*(Vt-vertSpeed);

}

float calcHorisontalTransWithAirResistSpray(in float vertSpeed, in float mass, in float c, in float time)
{
	c = 1.0;
	float tau = mass/(c*vertSpeed);

	return vertSpeed*tau*log(1+time/tau);

}

float calcVerticalTransWithAirResistSpray(in float vertSpeed, in float mass, in float c, in float time)
{
	c = 1.0;

	float tau = mass/(c*vertSpeed);

	return vertSpeed*tau*log(1+time/tau);
	return vertSpeed*mass/c*log(1+time*c/mass*vertSpeed);

}

float calcHorisontalTransWithAirResistTerrains(in float startSpeed, in float mass, in float c, in float time)
{
	c = 1.0;
	mass = 0.3;
	return mass*startSpeed/c*(1-exp(-c*time/mass));

}

float calcVerticalTransWithAirResistTerrains(in float vertSpeed, in float mass, in float c, in float time)
{
	c = 6.5;
	mass = 0.6;
	vertSpeed *= 1.0;
	const float g = 9.80665f;
	const float Vt = mass*g/c;
	const float k = (1-exp(-g*time/Vt))*Vt/g;

	float tau = mass/(c*vertSpeed);

	return (vertSpeed+Vt)*k - Vt*time;

}


float3 calcTranslationWithAirResistanceSpray(in float3 startSpeed, in float mass, in float c, in float time)
{
	return float3(calcHorisontalTransWithAirResistSpray(startSpeed.x, mass, c, time), calcVerticalTransWithAirResistSpray(startSpeed.y, mass, c, time), calcHorisontalTransWithAirResistSpray(startSpeed.z, mass, c, time));
}

float3 calcTranslationWithAirResistanceSplash(in float3 startSpeed, in float mass, in float c, in float time)
{
	return float3(calcHorisontalTransWithAirResistSplash(startSpeed.x, mass, c, time), calcVerticalTransWithAirResistSplash(startSpeed.y, mass, c, time), calcHorisontalTransWithAirResistSplash(startSpeed.z, mass, c, time));
}

float calcNewOpacity(in float time, in float dens_const)
{

	return exp(-dens_const*time);
}

float3 calcTranslationWithAirResistanceTerrains(in float3 startSpeed, in float mass, in float c, in float time)
{
	return float3(calcHorisontalTransWithAirResistTerrains(startSpeed.x, mass, c, time), calcVerticalTransWithAirResistTerrains(startSpeed.y, mass, c, time), calcHorisontalTransWithAirResistTerrains(startSpeed.z, mass, c, time));
}

#define particlesCount 3
#define GSSplash gsMain
#include "bulletImpactWater.hlsl"

#undef GSSplash
#undef particlesCount
//lod
#define LOD
#define particlesCount 2
#define GSSplash gsLod
#include "bulletImpactWater.hlsl"
#undef GSSplash
#undef particlesCount

#define particlesCount 2
#define GSTerrains gsTerrains
#include "bulletImpactTerrains.hlsl"
#undef GSTerrain
#undef particlesCount

float luminance(float3 v){
	return 0.3*v.x + 0.59*v.y + 0.11*v.z;
}

float4 psWaterSplash(PS_INPUT_SPLASH i, uniform bool bLod): SV_TARGET0
{
	float	_sin		= i.params2.x;
	float	_cos		= i.params2.y;
	float	OPACITY 	= i.params2.w;
	float	LERP_FACTOR = i.params2.z;
	
	float4 norm = tex.Sample(ClampLinearSampler, i.uv);
	clip(norm.a-0.1);

	norm.xyz = norm.xyz*2-1;
	norm.z *= 0.5;
	if(!bLod)
		norm.xy = float2( norm.x*_cos - norm.y*_sin, norm.x*_sin + norm.y*_cos );

	float light = dot(-normalize(norm.xyz), gSunDirV.xyz)*0.5+0.5;

	float4 color = 1;
	color.a = norm.a * lerp(1, texFoam.Sample(gTrilinearWrapSampler, float3(i.uv, LERP_FACTOR)).r, LERP_FACTOR) * OPACITY;
	
	color.rgb = shading_AmbientSun(0.8, color.rgb*length(AmbientAverage), i.sunColor * max(0, light) / PI);
	if (i.id_particle) {
		color.a *= 0.7;
	}
	else {
		color.rgb *= i.sunColor;
	}

	return color;
}

float4 psFlirSplash(PS_INPUT_SPLASH i): SV_TARGET0
{
	float	_sin		= i.params2.x;
	float	_cos		= i.params2.y;
	float	OPACITY 	= i.params2.w;
	float	LERP_FACTOR = i.params2.z;
	
	float4 norm = tex.Sample(ClampLinearSampler, i.uv);
	clip(norm.a-0.1);

	norm.xyz = norm.xyz*2-1;
	norm.z *= 0.5;

	float4 color = 1;
	color.a = norm.a * lerp(1, texFoam.Sample(gTrilinearWrapSampler, float3(i.uv, LERP_FACTOR)).r, LERP_FACTOR) * OPACITY;

	if (i.id_particle) {
		color.a *= 0.7;
	}
	else {
		color.rgb *= float3(0.53, 0.72, 0.93);
	}
	float l = luminance(color)/5.0;
	return float4(l, l, l, color.a);

}

SamplerState MirrorLinearSampler
{
	Filter        = MIN_MAG_MIP_LINEAR;
	AddressU      = MIRROR;
	AddressV      = MIRROR;
	AddressW      = MIRROR;
	MaxAnisotropy = MAXANISOTROPY_DEFAULT;
	BorderColor   = float4(0, 0, 0, 0);
};

float4 psTerrainImpacts(PS_INPUT_TERRAINS i, uniform bool bLod): SV_TARGET0
{
	float	_sin		= i.params2.x;
	float	_cos		= i.params2.y;
	float	OPACITY 	= i.params2.w;
	float	LERP_FACTOR = i.params2.z;
	
	float4 norm = tex.Sample(ClampLinearSampler, i.uv);
	clip(norm.a-0.1);

	norm.xyz = norm.xyz*2-1;
	norm.z *= 0.5;

	float NoL = saturate(dot(norm.xyz, gSunDirV.xyz)*0.4+0.2);

	float4 color = 1;
	float3 noise = texTerrainNoise.Sample(WrapLinearSampler, i.uv).rgb;

	float alpha = noise.r;
	float4 clrSmoke = tex.Sample(MirrorLinearSampler, i.uv).a;
	color.a = norm.a * clrSmoke.a * OPACITY;

	float3 clrr = float3(0.0, 0.0, 0.0);
	if (i.v_id%3 == 0) {
		clrr = float3(220.0/255.0, 170.0/255.0, 104.0/255.0);
	}
	else if (i.v_id%3 == 1) {
		clrr = float3(0.95, 0.76, 0.49);
	}
	else {
		clrr = float3(78.0/255.0, 59.0/255.0, 41.0/255.0);
	}

	color.rgb = shading_AmbientSun(clrr, AmbientTop, i.sunColor*NoL/PI);
	return float4(applyPrecomputedAtmosphere(color.rgb, 0), color.a);


	return color;
}

float4 psTerrainsFlir(PS_INPUT_TERRAINS i): SV_TARGET0
{
	float	_sin		= i.params2.x;
	float	_cos		= i.params2.y;
	float	OPACITY 	= i.params2.w;
	float	LERP_FACTOR = i.params2.z;
	
	float4 norm = tex.Sample(ClampLinearSampler, i.uv);
	clip(norm.a-0.1);

	norm.xyz = norm.xyz*2-1;
	norm.z *= 0.5;

	float NoL = saturate(dot(norm.xyz, gSunDirV.xyz)*0.4+0.2);

	float4 color = 1;
	float3 noise = texTerrainNoise.Sample(WrapLinearSampler, i.uv).rgb;

	float alpha = noise.r;
	float4 clrSmoke = tex.Sample(MirrorLinearSampler, i.uv).a;
	color.a = norm.a * clrSmoke.a * OPACITY;
	float3 clrr = float3(0.0, 0.0, 0.0);
	if (i.v_id%2 == 0) {
		clrr = float3(0.59, 0.48, 0.37);
	}
	else {
		clrr = float3(0.95, 0.76, 0.49);
	}

	float l = luminance(clrr)/3.0;
	return float4(l, l, l, color.a);

}


technique10 Textured
{
	pass splashMain
	{
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsMain())
		PIXEL_SHADER(psWaterSplash(false))
	}
	pass splashlod
	{
		ENABLE_RO_DEPTH_BUFFER;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsLod())
		PIXEL_SHADER(psWaterSplash(true))
	}


	pass terrains
	{
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsTerrains())
		PIXEL_SHADER(psTerrainImpacts(false))
	}

	pass splashFlir
	{
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsMain())
		PIXEL_SHADER(psFlirSplash())
	}

	pass splashLodFlir
	{
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsLod())
		PIXEL_SHADER(psFlirSplash())
	}


	pass terrainsFlir
	{
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		ENABLE_ALPHA_BLEND;
		DISABLE_CULLING;

		VERTEX_SHADER(VS_SPLASH())
		GEOMETRY_SHADER(gsTerrains())
		PIXEL_SHADER(psTerrainsFlir())
	}
}
