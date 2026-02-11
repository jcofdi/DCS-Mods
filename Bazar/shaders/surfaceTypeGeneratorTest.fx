#include "deferred/GBuffer.hlsl"
#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/colorTransform.hlsl"

#define HSV_MEAN_COLOR_DISPLAY_MODE       0
#define COLOR_FROM_REFERENCE_DISPLAY_MODE 1
#define BLACK_AND_WHITE_DISPLAY_MODE      2

Texture2D<uint> surfType;
Texture2D ref;
float4x4 WVP;

#define MAX_COUNT_OF_SURFACE_TYPES 32
float4 surfTypeColors[MAX_COUNT_OF_SURFACE_TYPES];

uint mask;
int displayMode;

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
	vout.tex0 = 0.5f * (vin.posL.xy + 1);

	return vout;
}

GBuffer ps(
	VS_OUTPUT pin
#if USE_SV_SAMPLEINDEX
	, uint sv_sampleIndex: SV_SampleIndex
#endif
)
{
	uint2 size = 0;
	surfType.GetDimensions(size.x, size.y);
	int2 ij = round(pin.tex0 * size - 0.5);

	uint st = surfType.mips[0][ij];
	float4 maskAlbedo = float4(0, 0, 0, 1);
	if (mask & st)
	{
		int index = log2(st);
		if (displayMode == HSV_MEAN_COLOR_DISPLAY_MODE)
		{
			maskAlbedo = surfTypeColors[index];
			maskAlbedo.xyz = hsv2rgb(maskAlbedo.xyz);
			maskAlbedo.xyz = rgb2srgb(maskAlbedo.xyz);
		}

		uint2 refsize = 0;
		ref.GetDimensions(refsize.x, refsize.y);
		int mip = log2(refsize.x / size.x) + 1;
		float4 refAlbedo = ref.SampleLevel(ClampSampler, pin.tex0, mip);

		if (displayMode == COLOR_FROM_REFERENCE_DISPLAY_MODE)
		{
			maskAlbedo = refAlbedo;
		}
		if (displayMode == BLACK_AND_WHITE_DISPLAY_MODE)
		{
			maskAlbedo.xyz = length(refAlbedo.xyz);
			maskAlbedo.w = 1;
		}
	}

	return BuildGBuffer(pin.posH.xy,
#if USE_SV_SAMPLEINDEX
		sv_sampleIndex,
#endif
		maskAlbedo, float3(0, 0, 0), float4(1, 1, 0, 0), 0,
#if USE_VELOCITY_MAP
		0,
#endif
		0
	);
}

technique11 surfTypeTestTech
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
};