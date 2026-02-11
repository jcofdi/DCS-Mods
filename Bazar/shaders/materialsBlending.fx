#include "deferred/GBuffer.hlsl"
#include "common/samplers11.hlsl"
#include "common/materialsBlendingSamplers.hlsl"
#include "Common/States11.hlsl"

Texture2DArray albedoTexture;
Texture2DArray aoTexture;
Texture2DArray heightMap;
Texture2DArray metallicTexture;
Texture2DArray normalMap;
Texture2DArray roughnessTexture;

Texture2D<uint> mask;
Texture2D weights;

Texture2D sampleTexture;

float4x4 WVP;
float halfSize;
float materialTexTiling;

int mip;

uint maskChannel;

bool fR;
bool fG;
bool fB;

bool takeColorFromAlbedo;

struct VS_INPUT
{
	float3 posL : POSITION;
};

struct VS_OUTPUT
{
	float4 posH  : SV_Position;
	// UV coordinates for mask and weights
	float2 tex0 : TEXCOORD0; 
};

VS_OUTPUT vs(VS_INPUT vin)
{
	VS_OUTPUT vout;

	vout.posH = mul(float4(vin.posL, 1), WVP);
	vout.tex0 = 0.5f * (vin.posL.xy / halfSize + 1);

	return vout;
}

GBuffer ps(
	VS_OUTPUT pin
#if USE_SV_SAMPLEINDEX
	, uint sv_sampleIndex: SV_SampleIndex
#endif
)
{
	MaskAndWeightsOfNeighbourMips m = sampleMaskAndWeights(mask, weights, pin.tex0);
	float4 albedo = sampleTex(albedoTexture, WrapSampler, materialTexTiling * pin.tex0, m);

	return BuildGBuffer(pin.posH.xy,
#if USE_SV_SAMPLEINDEX
		sv_sampleIndex,
#endif
		albedo, float3(0, 1, 0), float4(1, 1, 0, 0), 0,
#if USE_MOTION_VECTORS
		0, // TODO: correct motion vector to use calcMotionVector()
#endif
		0
	);
}

GBuffer ps_mask_and_weights(
	VS_OUTPUT pin,
#if USE_SV_SAMPLEINDEX
	uint sv_sampleIndex: SV_SampleIndex,
#endif
	uniform bool renderMask,
	uniform bool renderWeights
)
{
	float4 albedo = float4(0, 0, 0, 1);
	if (!renderWeights && !renderMask)
	{
		uint width = 0;
		uint height = 0;
		mask.GetDimensions(width, height);
		MaskAndWeightsOfTheMIP m = sampleMaskAndWeights(mask, weights, width, height, pin.tex0, mip);
		albedo = sampleTex(albedoTexture, WrapSampler, materialTexTiling * pin.tex0, m);
	}
	if (renderWeights && !renderMask)
	{
		albedo = sampleWeights(weights, pin.tex0, mip);
	}

	if (!fR)
		albedo.r = 0;
	if (!fG)
		albedo.g = 0;
	if (!fB)
		albedo.b = 0;

	if (renderMask)
	{
		uint m = sampleMask(mask, pin.tex0, mip);
		float4 w = 1;
		if (renderWeights)
			w = sampleWeights(weights, pin.tex0, mip);

		uint ci = arrayIndex(maskChannel);
		float4 c = 1;
		if (takeColorFromAlbedo)
			c = albedoTexture.Sample(WrapSampler, float3(materialTexTiling * pin.tex0, ci));

		uint wi = weightIndex(m, maskChannel);
		bool r = maskChannel & m;
		r = r && ((fR && wi == 0) || (fG && wi == 1) || (fB && wi == 2) || !renderWeights);
		if (r)
			albedo.xyz = w[wi] * c.xyz;
	}

	return BuildGBuffer(pin.posH.xy,
#if USE_SV_SAMPLEINDEX
		sv_sampleIndex,
#endif
		albedo, float3(0,1,0), float4(1, 1, 0, 0), 0,
#if USE_MOTION_VECTORS
		0,	// TODO: correct motion vector to use calcMotionVector()
#endif
		0
	);
}

GBuffer ps_albedo(
	VS_OUTPUT pin
#if USE_SV_SAMPLEINDEX
	, uint sv_sampleIndex: SV_SampleIndex
#endif
)
{
	uint ci = arrayIndex(maskChannel);
	float4 albedo = albedoTexture.SampleLevel(WrapSampler, float3(pin.tex0, ci), mip);

	if (!fR)
		albedo.r = 0;
	if (!fG)
		albedo.g = 0;
	if (!fB)
		albedo.b = 0;

	return BuildGBuffer(pin.posH.xy,
#if USE_SV_SAMPLEINDEX
		sv_sampleIndex,
#endif
		albedo, float3(0, 1, 0), float4(1, 1, 0, 0), 0,
#if USE_MOTION_VECTORS
		0,	// TODO: correct motion vector to use calcMotionVector()
#endif
		0
	);
}

GBuffer ps_sample(
	VS_OUTPUT pin
#if USE_SV_SAMPLEINDEX
	, uint sv_sampleIndex: SV_SampleIndex
#endif
)
{
	float4 albedo = sampleTexture.SampleLevel(WrapLinearSampler, pin.tex0, mip);

	if (!fR)
		albedo.r = 0;
	if (!fG)
		albedo.g = 0;
	if (!fB)
		albedo.b = 0;

	return BuildGBuffer(pin.posH.xy,
#if USE_SV_SAMPLEINDEX
		sv_sampleIndex,
#endif
		albedo, float3(0, 1, 0), float4(1, 1, 0, 0), 0,
#if USE_MOTION_VECTORS
		0,	// TODO: correct motion vector to use calcMotionVector()
#endif
		0
	);
}

technique11 materialsBlending
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps()));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P1
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_mask_and_weights(false, false)));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P2
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_mask_and_weights(false, true)));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P3
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_mask_and_weights(true, false)));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P4
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_mask_and_weights(true, true)));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P5
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_sample()));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
	pass P6
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps_albedo()));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
};