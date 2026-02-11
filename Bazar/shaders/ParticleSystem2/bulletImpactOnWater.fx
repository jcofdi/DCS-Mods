#include "common/TextureSamplers.hlsl"
#include "common/States11.hlsl"
#include "common/samplers11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"

#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"
#include "common/random.hlsl"
#include "common/stencil.hlsl"
#include "deferred/reflections.fx"

Texture2D	texWaterNormal;

float2 params;

#define 	nAge		params.x
#define		scale		params.y

struct VS_OUTPUT_ON_WATER {
	float4 	sunColor: 	TEXCOORD0;
};

struct GS_OUTPUT_ON_WATER {
	float4 	pos: 		SV_POSITION0;
	float4 	sunColor: 	TEXCOORD0;
	float2 	uv: 		TEXCOORD1;
};



VS_OUTPUT_ON_WATER vs_on_water(uniform bool bClouds) 
{
	VS_OUTPUT_ON_WATER o;

	if (bClouds) {
		o.sunColor.xyz = getPrecomputedSunColor(0);
		o.sunColor.w = min(getAtmosphereTransmittance(0).r, 1.0);
	}

	else {
		o.sunColor.xyz = gSunDiffuse;
		o.sunColor.w = 1.0;
	}

	return o;

}


[maxvertexcount(4)]
void gs_on_water(point VS_OUTPUT_ON_WATER i[1], inout TriangleStream<GS_OUTPUT_ON_WATER> outputStream)
{

	GS_OUTPUT_ON_WATER o;

	float4 uvOffsetScale = getTextureFrameUV8x8(pow(nAge, 0.5)*(8*8-1));
	o.sunColor = i[0].sunColor;

	[unroll]
	for (int ii = 0; ii < 4; ++ii)
	{
		float4 vPos = float4(scale*staticVertexData[ii].x, 0.0, scale*staticVertexData[ii].y, 1);
		vPos.xyz -= worldOffset;
		o.pos = mul(vPos, gViewProj);
		o.uv = staticVertexData[ii].zw * uvOffsetScale.xy + uvOffsetScale.zw;
		outputStream.Append(o);
	}

	outputStream.RestartStrip();
}


float4 ps_on_water(GS_OUTPUT_ON_WATER i, uniform bool bClouds): SV_TARGET0
{

	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy);
	clr = clr*clr;
	float4 norm = texWaterNormal.Sample(ClampLinearSampler, i.uv.xy);
	norm = norm*norm;

	norm.xyz = norm.xyz*2-1;

	float light = dot(-norm.xyz, gSunDirV.xyz)*0.5+0.5;

	clr.rgb = shading_AmbientSun(0.6, AmbientAverage, i.sunColor.xyz * max(0, light) / PI);

	clr.a *= 1.0-nAge;
	clr.a *= i.sunColor.w;

	if (bClouds) {
		return float4(applyPrecomputedAtmosphere(clr.rgb, 0), clr.a);
	}

	return clr;

}


DepthStencilState foamDS
{
	DepthEnable		= false;
	DepthWriteMask	= false;
	DepthFunc		= ALWAYS;

	TEST_COMPOSITION_TYPE_IN_STENCIL;
};



BlendState foamAlphaBlend
{
	BlendEnable[0] = TRUE;
	SrcBlend = SRC_ALPHA;
	DestBlend = INV_SRC_ALPHA;
	BlendOp = ADD;

	//SrcBlendAlpha = ONE;
	//DestBlendAlpha = ONE;
	//BlendOpAlpha = MAX;

	SrcBlendAlpha = ZERO;
	DestBlendAlpha = INV_SRC_ALPHA;
	BlendOpAlpha = ADD;

	RenderTargetWriteMask[0] = 0x0f;
};

technique10 Textured
{

	pass splashTexture
	{
		SetRasterizerState(cullFront);
		SetVertexShader(CompileShader(vs_5_0, vs_on_water(false)));
		SetGeometryShader(CompileShader(gs_5_0, gs_on_water()));
		SetPixelShader(CompileShader(ps_5_0, ps_on_water(false)));
		SetDepthStencilState(foamDS, STENCIL_COMPOSITION_WATER);
		SetBlendState(foamAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
	}

	pass splashTextureAtm
	{
		SetRasterizerState(cullFront);
		SetVertexShader(CompileShader(vs_5_0, vs_on_water(true)));
		SetGeometryShader(CompileShader(gs_5_0, gs_on_water()));
		SetPixelShader(CompileShader(ps_5_0, ps_on_water(true)));
		SetDepthStencilState(foamDS, STENCIL_COMPOSITION_WATER);
		SetBlendState(foamAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
	}

}
