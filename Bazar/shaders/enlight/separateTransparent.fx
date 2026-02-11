#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/platform.hlsl"

#define USE_Z_DISTANCE 0

#ifdef MSAA
	#define TEXTURE_2D(type, name) Texture2DMS<type, MSAA> name
    #define	LoadMap(name, uv, idx)  name.Load(uint2(uv), idx)
#else
	#define TEXTURE_2D(type, name) Texture2D<type> name
    #define	LoadMap(name, uv, idx)  name.Load(uint3(uv, 0))
#endif

TEXTURE_2D(float, srcDepth);
Texture2D<float> transparentDepth;
Texture2D<float4> transparentColor;

static const float2 quad[4] = {	{-1, -1}, {1, -1},	{-1,  1}, {1,  1} };

float4 VS(uint vid: SV_VertexID): SV_POSITION {
	return float4(quad[vid], 0, 1);
}

float PS_DOWNSCALE(float4 pos: SV_POSITION): SV_DEPTH {
	uint2 coord = pos.xy;
	uint2 src_coord = coord * 2;
	float d = LoadMap(srcDepth, src_coord, 0);
	if ((src_coord.x + src_coord.y) & 1 == 0) {
		d = min(d, LoadMap(srcDepth, src_coord + uint2(0, 1), 0));
		d = min(d, LoadMap(srcDepth, src_coord + uint2(1, 0), 0));
		d = min(d, LoadMap(srcDepth, src_coord + uint2(1, 1), 0));
	} else {
		d = max(d, LoadMap(srcDepth, src_coord + uint2(0, 1), 0));
		d = max(d, LoadMap(srcDepth, src_coord + uint2(1, 0), 0));
		d = max(d, LoadMap(srcDepth, src_coord + uint2(1, 1), 0));
	}
	return d;
}

void sampleValue(uint2 coord, out float z, out float4 value) {
#if USE_Z_DISTANCE
	float depth = transparentDepth.Load(uint3(coord, 0)).x;
	float4 vp = mul(float4(0, 0, depth, 1), gProjInv);
	z = vp.z/vp.w;
#else
	z = transparentDepth.Load(uint3(coord, 0)).x;
#endif
	value = transparentColor.Load(uint3(coord, 0));
}

float gaussian(float x, float s) {
	return exp(-x * x / (2 * s*s));
}

float4 PS_COMPOSE(float4 pos: SV_POSITION): SV_TARGET0 {
	uint2 coord = pos.xy;

#if USE_Z_DISTANCE
	float depth = LoadMap(srcDepth, coord, 0).x;
	float4 vp = mul(float4(0, 0, depth, 1), gProjInv);
	float z = vp.z/vp.w;
#else
	float z = LoadMap(srcDepth, coord, 0).x;
#endif

	uint2 coord2 = coord / 2;

//	return transparentColor.Load(uint3(coord2, 0));

	float z00, z01, z10, z11;
	float4 v00, v01, v10, v11;
	sampleValue(coord2 + uint2(0, 0), z00, v00);
	sampleValue(coord2 + uint2(0, 1), z01, v01);
	sampleValue(coord2 + uint2(1, 0), z10, v10);
	sampleValue(coord2 + uint2(1, 1), z11, v11);

	float2 f = frac(float2(coord) * 0.5);
	float2 f1 = 1 - f;

	const float sigma = 1.0;

	float w00 = gaussian(abs(z - z00), sigma) * f1.x * f1.y;
	float w01 = gaussian(abs(z - z01), sigma) * f1.x * f.y;
	float w10 = gaussian(abs(z - z10), sigma) * f.x  * f1.y;
	float w11 = gaussian(abs(z - z11), sigma) * f.x  * f.y;
	w00 += 1e-9;

	float4 v = (v00 * w00 + v01 * w01 + v10 * w10 + v11 * w11) / (w00 + w01 + w10 + w11);

	return v;
}

BlendState composeAlphaBlend {
	BlendEnable[0] = TRUE;
	SrcBlend = ONE;
	DestBlend = SRC_ALPHA;
	BlendOp = ADD;
	RenderTargetWriteMask[0] = 0x0f;
};


#define COMMON_PART 		SetRasterizerState(cullNone);	\
							SetHullShader(NULL);		\
							SetDomainShader(NULL);		\
							SetGeometryShader(NULL);	\
							SetComputeShader(NULL);		

technique10 Tech {
	pass P0	{
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetPixelShader(CompileShader(ps_5_0, PS_DOWNSCALE()));
		SetDepthStencilState(alwaysDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		COMMON_PART
	}
	pass P1	{
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetPixelShader(CompileShader(ps_5_0, PS_COMPOSE()));
		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(composeAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		COMMON_PART
	}
}
