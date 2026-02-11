#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/platform.hlsl"
#define ATMOSPHERE_COLOR

#include "common/ambientCube.hlsl"
#include "common/shadingCommon.hlsl"
#include "common/random.hlsl"
#include "deferred/shading.hlsl"
#include "ParticleSystem2/common/psCommon.hlsl"
//#include "noise/noise2D.hlsl"
#include "noise/noise3D.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "ParticleSystem2/common/noiseFractal.hlsl"
#include "common/stencil.hlsl"

Texture2D   GBufferComposed;


float4 params0;
float3 gOrigin2;
float4x4 gWorld;

uint params1;


struct VS_OUTPUT
{
	float4 pos: SV_POSITION0;
	float3 posW: POSITION0;
	float3 normalW: POSITION1;
	float2 uv: TEXCOORD0;
};

struct PS_OUTPUT {
	TARGET_LOCATION_INDEX(0, 0) float4 colorAdd : SV_TARGET0;
	TARGET_LOCATION_INDEX(0, 1) float4 colorMul : SV_TARGET1;
};


#define gMulPos 		params0.x
#define gMulNeg 		params0.y
#define time 			params0.z
#define gGBufferWidth 	params1.x
#define gGBufferHeight 	params1.y


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


VS_OUTPUT vs(float3 posL: POSITION0, float3 normalL: POSITION1, float2 uv: TEXCOORD0)
{
	VS_OUTPUT o;

	
	float3 p = posL;



	if(p.z > 0.0){
		p.xy *= gMulPos;
	}
	else{
		p.xy *= gMulNeg;
	}	

	o.posW = mul_v3xm44(p, gWorld)-gOrigin2;
	//o.posW += 10.0;
	o.pos = mul_v3xm44(o.posW, gViewProj);

	o.normalW = mul(normalL, (float3x3)gWorld);
	o.uv = uv;

	return o;
}


VS_OUTPUT vsLine(float3 posL: POSITION0, float3 normalL: POSITION1, float2 uv: TEXCOORD0)
{
	VS_OUTPUT o;

	
	float3 p = posL;



	if(p.z > 0.0){
		p.xy *= gMulPos;
	}
	else{
		p.xy *= gMulNeg;
	}	

	o.posW = mul_v3xm44(p, gWorld)-gOrigin2;
	o.normalW = mul(normalL, (float3x3)gWorld);
	o.posW += o.normalW*0.05;
	o.posW.y += 2.0;
	o.pos = mul_v3xm44(o.posW, gViewProj);
	o.pos.z += 0.0002;
	o.uv = uv;

	return o;
}


PS_OUTPUT ps(VS_OUTPUT i)
{
	float3 reflectance;
	float3 refraction;
	
	float3 normalW = normalize(i.normalW);
	float3 viewW = normalize(-(i.posW-gCameraPos));
	
	float nov = dot(normalW, viewW);
	if(nov < 0.0){
		nov *= -1;
		normalW *= -1;
	}


	float fresnel = Fresnel_schlick(0.02, nov);	

	float3 atmosphereMul, atmosphereAdd;
	getPrecomputedAtmosphere(0, atmosphereMul, atmosphereAdd);
	
	atmosphereMul = 1.0;
	atmosphereAdd = 0.0;

	PS_OUTPUT o;
	float3 importLightDirV = reflect(-viewW, normalW);

	float3 ref = SampleEnvironmentMapDetailed(importLightDirV, 3);
	reflectance = (fresnel*ref*1.0+0.1)*float3(0.75, 1.0, 0.55);
	refraction = (1.0-fresnel)*float3(1.0, 1.0, 1.0)*1.15;

	float3 refractionAtmosphere = refraction*atmosphereMul;
	o.colorAdd = float4(reflectance*atmosphereMul+atmosphereAdd*(float3(1.0, 1.0, 1.0)-refractionAtmosphere), 1.0);
	o.colorMul = float4(0.7*refractionAtmosphere, 1.0);

	float t = length(gSunAmbient);
	t *= gSunIntensity;

	float k = max(min(t, 1.0), 0.00);
	k = 1.0 - k;
	float k1 = 0.1*k;
	float k2 = 0.2*k;

	o.colorAdd.xyz = (1.0 - k1)*o.colorAdd.xyz + k1*float3(0.0, 1.0, 0.5);
	//float3 colorSparks = (1.0 - k2)*o.colorAdd.xyz + k2*float3(0.0, 1.0, 0.0);

	float3 colorSparks = (1.0 - k2)*float3(0.5, 1.0, 0.5) + k2*float3(0.0, 1.0, 0.0);

	t = max(min(t, 1.0), 0.05);
	o.colorAdd.xyz *= t;
	o.colorAdd.xyz = tilesShader(i.uv, o.colorAdd.xyz*1.2, colorSparks*1.2, time);
	return o;

}


PS_OUTPUT psLine(in VS_OUTPUT i)
{
	float3 reflectance;
	float3 refraction;
	
	float3 normalW = normalize(i.normalW);
	float3 viewW = normalize(-(i.posW-gCameraPos));
	
	float nov = dot(normalW, viewW);
	if(nov < 0.0){
		nov *= -1;
		normalW *= -1;
	}


	float fresnel = Fresnel_schlick(0.02, nov);	

	float3 atmosphereMul, atmosphereAdd;
	getPrecomputedAtmosphere(0, atmosphereMul, atmosphereAdd);
	
	atmosphereMul = 1.0;
	atmosphereAdd = 0.0;

	PS_OUTPUT o;
	float3 importLightDirV = reflect(-viewW, normalW);

	float3 ref = SampleEnvironmentMapDetailed(importLightDirV, 3);
	reflectance = (fresnel*ref*1.0+0.1)*float3(0.75, 1.0, 0.55);
	refraction = (1.0-fresnel)*float3(1.0, 1.0, 1.0)*1.15;

	float3 refractionAtmosphere = refraction*atmosphereMul;
	o.colorAdd = float4(reflectance*atmosphereMul+atmosphereAdd*(float3(1.0, 1.0, 1.0)-refractionAtmosphere), 1.0);

	o.colorMul = float4(0.1*refractionAtmosphere, 1.0);

	float t = length(gSunAmbient);
	t *= gSunIntensity;

	float k = max(min(t, 1.0), 0.00);
	k = 1.0 - k;
	float k2 = 0.2*k;

	o.colorAdd.xyz = 1.2*(1.0 - k2)*o.colorAdd.xyz + 2.0*k2*float3(0.3, 0.6, 0.3);
	o.colorMul.xyz = (1.0 - k2)*0.7*refractionAtmosphere + k2*o.colorMul.xyz;

	t = max(min(t, 1.0), 0.05);
	o.colorAdd.xyz *= t;

	return o;

}


BlendState enableGlassAlphaBlend
{
	BlendEnable[0] = TRUE;

	//SrcBlend = ONE;
	SrcBlend = INV_SRC1_COLOR;
	DestBlend = SRC1_COLOR;
	BlendOp = ADD;

	SrcBlendAlpha = ZERO;
	DestBlendAlpha = INV_SRC_ALPHA;
	BlendOpAlpha = ADD;


	RenderTargetWriteMask[0] = 0x0f; //RED | GREEN | BLUE | ALPHA
};



RasterizerState lineRasterizerState
{
	CullMode = None;
	FillMode = Solid;
	MultisampleEnable = true;
};

DepthStencilState energyLineDs
{
	DepthEnable		= false;
	DepthWriteMask	= false;
	DepthFunc		= ALWAYS;

	TEST_COMPOSITION_TYPE_IN_STENCIL;
};

technique10 tech
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_4_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, ps()));
		SetBlendState(enableGlassAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}

	pass lines
	{
		SetVertexShader(CompileShader(vs_5_0, vsLine()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, psLine()));
		SetBlendState(enableGlassAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT;
		//SetDepthStencilState(enableDepthBuffer, 0);
		//SetDepthStencilState(energyLineDs, STENCIL_COMPOSITION_GRASS || STENCIL_COMPOSITION_SURFACE || STENCIL_COMPOSITION_EMPTY);
		SetRasterizerState(lineRasterizerState);
	}
}
