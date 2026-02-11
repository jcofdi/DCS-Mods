#ifndef _common_triangle_grid_hlsl
#define _common_triangle_grid_hlsl

#include "common/TriangleGridUtilities.hlsl"

#define LINEAR_BLENDING 0
#define BLENDING_BY_HEIGHT 1
#define BLENDING_0 2 // Blending from article https://jcgt.org/published/0011/03/05/

struct ThreePatchesInfo
{
	float3 weights;

	float2 uv1;
	float2 uv2;
	float2 uv3;

	float2 dUVdx;
	float2 dUVdy;

	float2x2 rot1;
	float2x2 rot2;
	float2x2 rot3;
};

struct ThreeSamples2D
{
	float2 sample1;
	float2 sample2;
	float2 sample3;
};

struct ThreeSamples4D
{
	float4 sample1;
	float4 sample2;
	float4 sample3;
};

// Input: uv coordinates and number of triangles per unit edge(rate)
// Output: weights associated with each hex tile and integer centers
ThreePatchesInfo TriangleGrid(float2 uv, float rate, float rotStrength = 0, uniform bool bRotateSamples = false)
{
	ThreePatchesInfo patches = (ThreePatchesInfo)0;
	
	float2 uv0 = uv;

	// Scaling of the input
	uv *= rate;

	// Skew input space into simplex triangle grid.
	const float2x2 gridToSkewedGrid =
		float2x2(1.0, -0.57735027, 0.0, 1.15470054);

	float2 skewedCoord = mul(gridToSkewedGrid, uv);
	int2 baseId = int2(floor(skewedCoord));

	float3 temp = float3(frac(skewedCoord), 0);
	temp.z = 1.0 - temp.x - temp.y;

	float s = step(0.0, -temp.z);
	float s2 = 2 * s - 1;

	patches.weights.x = -temp.z * s2;
	patches.weights.y = s - temp.y * s2;
	patches.weights.z = s - temp.x * s2;

	int2 vertex1 = baseId + int2(s, s);
	int2 vertex2 = baseId + int2(s, 1 - s);
	int2 vertex3 = baseId + int2(1 - s, s);

	patches.rot1 = rot2x2(vertex1, rotStrength);
	patches.rot2 = rot2x2(vertex2, rotStrength);
	patches.rot3 = rot2x2(vertex3, rotStrength);

	float2x2 invSkewMat = float2x2(1.0, 0.5, 0.0, 1.0 / 1.15470054);
	float2 c1 = mul(invSkewMat, vertex1) / rate;
	float2 c2 = mul(invSkewMat, vertex2) / rate;
	float2 c3 = mul(invSkewMat, vertex3) / rate;

	if (bRotateSamples)
	{
		patches.uv1 = mul(uv0 - c1, patches.rot1) + c1 + hash(vertex1);
		patches.uv2 = mul(uv0 - c2, patches.rot2) + c2 + hash(vertex2);
		patches.uv3 = mul(uv0 - c3, patches.rot3) + c3 + hash(vertex3);
	}
	else
	{
		patches.uv1 = uv0 + hash(vertex1);
		patches.uv2 = uv0 + hash(vertex2);
		patches.uv3 = uv0 + hash(vertex3);
	}
	patches.dUVdx = ddx(uv0);
	patches.dUVdy = ddy(uv0);

	return patches;
}

ThreePatchesInfo TriangleGridDomain(float2 uv, float rate, float rotStrength = 0, uniform bool bRotateSamples = false)
{
	ThreePatchesInfo patches = (ThreePatchesInfo)0;
	
	float2 uv0 = uv;

	// Scaling of the input
	uv *= rate;

	// Skew input space into simplex triangle grid.
	const float2x2 gridToSkewedGrid =
		float2x2(1.0, -0.57735027, 0.0, 1.15470054);

	float2 skewedCoord = mul(gridToSkewedGrid, uv);
	int2 baseId = int2(floor(skewedCoord));

	float3 temp = float3(frac(skewedCoord), 0);
	temp.z = 1.0 - temp.x - temp.y;

	float s = step(0.0, -temp.z);
	float s2 = 2 * s - 1;

	patches.weights.x = -temp.z * s2;
	patches.weights.y = s - temp.y * s2;
	patches.weights.z = s - temp.x * s2;

	int2 vertex1 = baseId + int2(s, s);
	int2 vertex2 = baseId + int2(s, 1 - s);
	int2 vertex3 = baseId + int2(1 - s, s);

	patches.rot1 = rot2x2(vertex1, rotStrength);
	patches.rot2 = rot2x2(vertex2, rotStrength);
	patches.rot3 = rot2x2(vertex3, rotStrength);

	float2x2 invSkewMat = float2x2(1.0, 0.5, 0.0, 1.0 / 1.15470054);
	float2 c1 = mul(invSkewMat, vertex1) / rate;
	float2 c2 = mul(invSkewMat, vertex2) / rate;
	float2 c3 = mul(invSkewMat, vertex3) / rate;

	if (bRotateSamples)
	{
		patches.uv1 = mul(uv0 - c1, patches.rot1) + c1 + hash(vertex1);
		patches.uv2 = mul(uv0 - c2, patches.rot2) + c2 + hash(vertex2);
		patches.uv3 = mul(uv0 - c3, patches.rot3) + c3 + hash(vertex3);
	}
	else
	{
		patches.uv1 = uv0 + hash(vertex1);
		patches.uv2 = uv0 + hash(vertex2);
		patches.uv3 = uv0 + hash(vertex3);
	}

	return patches;
}

ThreeSamples4D SampleColors4D(Texture2D tex, SamplerState ss, ThreePatchesInfo patches, uniform bool bRotateSamples = false)
{
	ThreeSamples4D r = (ThreeSamples4D)0;
	if (bRotateSamples)
	{
		r.sample1 = tex.SampleGrad(ss, patches.uv1, mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1));
		r.sample2 = tex.SampleGrad(ss, patches.uv2, mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2));
		r.sample3 = tex.SampleGrad(ss, patches.uv3, mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3));
	}
	else
	{
		r.sample1 = tex.SampleGrad(ss, patches.uv1, patches.dUVdx, patches.dUVdy);
		r.sample2 = tex.SampleGrad(ss, patches.uv2, patches.dUVdx, patches.dUVdy);
		r.sample3 = tex.SampleGrad(ss, patches.uv3, patches.dUVdx, patches.dUVdy);
	}
	return r;
}

ThreeSamples4D SampleColors4D(Texture2DArray tex, SamplerState ss, ThreePatchesInfo patches, uint texIndex, uniform bool bRotateSamples = false)
{
	ThreeSamples4D r = (ThreeSamples4D)0;
	if (bRotateSamples)
	{
		r.sample1 = tex.SampleGrad(ss, float3(patches.uv1, texIndex), mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1));
		r.sample2 = tex.SampleGrad(ss, float3(patches.uv2, texIndex), mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2));
		r.sample3 = tex.SampleGrad(ss, float3(patches.uv3, texIndex), mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3));
	}
	else
	{
		r.sample1 = tex.SampleGrad(ss, float3(patches.uv1, texIndex), patches.dUVdx, patches.dUVdy);
		r.sample2 = tex.SampleGrad(ss, float3(patches.uv2, texIndex), patches.dUVdx, patches.dUVdy);
		r.sample3 = tex.SampleGrad(ss, float3(patches.uv3, texIndex), patches.dUVdx, patches.dUVdy);
	}
	return r;
}

float3 SampleColors1D(Texture2D tex, SamplerState ss, ThreePatchesInfo patches, uniform bool bRotateSamples = false)
{
	float3 r = 0.0f;
	if (bRotateSamples)
	{
		r.x = tex.SampleGrad(ss, patches.uv1, mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1)).r;
		r.y = tex.SampleGrad(ss, patches.uv2, mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2)).r;
		r.z = tex.SampleGrad(ss, patches.uv3, mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3)).r;
	}
	else
	{
		r.x = tex.SampleGrad(ss, patches.uv1, patches.dUVdx, patches.dUVdy).r;
		r.y = tex.SampleGrad(ss, patches.uv2, patches.dUVdx, patches.dUVdy).r;
		r.z = tex.SampleGrad(ss, patches.uv3, patches.dUVdx, patches.dUVdy).r;
	}
	return r;
}

float3 SampleColors1D(Texture2DArray tex, SamplerState ss, ThreePatchesInfo patches, uint texIndex, uniform bool bRotateSamples = false)
{
	float3 r = 0.0f;
	if (bRotateSamples)
	{
		r.x = tex.SampleGrad(ss, float3(patches.uv1, texIndex), mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1)).r;
		r.y = tex.SampleGrad(ss, float3(patches.uv2, texIndex), mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2)).r;
		r.z = tex.SampleGrad(ss, float3(patches.uv3, texIndex), mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3)).r;
	}
	else
	{
		r.x = tex.SampleGrad(ss, float3(patches.uv1, texIndex), patches.dUVdx, patches.dUVdy).r;
		r.y = tex.SampleGrad(ss, float3(patches.uv2, texIndex), patches.dUVdx, patches.dUVdy).r;
		r.z = tex.SampleGrad(ss, float3(patches.uv3, texIndex), patches.dUVdx, patches.dUVdy).r;
	}
	return r;
}

float3 SampleColors1D_Level(Texture2D tex, SamplerState ss, ThreePatchesInfo patches, uint level = 0)
{
	float3 r = 0.0f;

	r.x = tex.SampleLevel(ss, patches.uv1, level).r;
	r.y = tex.SampleLevel(ss, patches.uv2, level).r;
	r.z = tex.SampleLevel(ss, patches.uv3, level).r;

	return r;
}

float3 SampleColors1D_Level(Texture2DArray tex, SamplerState ss, ThreePatchesInfo patches, uint texIndex, uint level = 0)
{
	float3 r = 0.0f;

	r.x = tex.SampleLevel(ss, float3(patches.uv1, texIndex), level).r;
	r.y = tex.SampleLevel(ss, float3(patches.uv2, texIndex), level).r;
	r.z = tex.SampleLevel(ss, float3(patches.uv3, texIndex), level).r;

	return r;
}

ThreeSamples2D SampleDerivs(Texture2D tex, SamplerState ss, ThreePatchesInfo patches, uniform bool bRotateSamples = false)
{
	ThreeSamples2D r = (ThreeSamples2D)0;
	if (bRotateSamples)
	{
		r.sample1 = sampleDeriv(tex, ss, patches.uv1, mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1));
		r.sample2 = sampleDeriv(tex, ss, patches.uv2, mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2));
		r.sample3 = sampleDeriv(tex, ss, patches.uv3, mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3));

		r.sample1 = mul(patches.rot1, r.sample1);
		r.sample2 = mul(patches.rot2, r.sample2);
		r.sample3 = mul(patches.rot3, r.sample3);
	}
	else
	{
		r.sample1 = sampleDeriv(tex, ss, patches.uv1, patches.dUVdx, patches.dUVdy);
		r.sample2 = sampleDeriv(tex, ss, patches.uv2, patches.dUVdx, patches.dUVdy);
		r.sample3 = sampleDeriv(tex, ss, patches.uv3, patches.dUVdx, patches.dUVdy);
	}
	return r;
}

ThreeSamples2D SampleDerivs(Texture2DArray tex, SamplerState ss, ThreePatchesInfo patches, uint texIndex, uniform bool bRotateSamples = false)
{
	ThreeSamples2D r = (ThreeSamples2D)0;
	if (bRotateSamples)
	{
		r.sample1 = sampleDeriv(tex, ss, float3(patches.uv1, texIndex), mul(patches.dUVdx, patches.rot1), mul(patches.dUVdy, patches.rot1));
		r.sample2 = sampleDeriv(tex, ss, float3(patches.uv2, texIndex), mul(patches.dUVdx, patches.rot2), mul(patches.dUVdy, patches.rot2));
		r.sample3 = sampleDeriv(tex, ss, float3(patches.uv3, texIndex), mul(patches.dUVdx, patches.rot3), mul(patches.dUVdy, patches.rot3));

		r.sample1 = mul(patches.rot1, r.sample1);
		r.sample2 = mul(patches.rot2, r.sample2);
		r.sample3 = mul(patches.rot3, r.sample3);
	}
	else
	{
		r.sample1 = sampleDeriv(tex, ss, float3(patches.uv1, texIndex), patches.dUVdx, patches.dUVdy);
		r.sample2 = sampleDeriv(tex, ss, float3(patches.uv2, texIndex), patches.dUVdx, patches.dUVdy);
		r.sample3 = sampleDeriv(tex, ss, float3(patches.uv3, texIndex), patches.dUVdx, patches.dUVdy);
	}
	return r;
}

void applyHeightToPatches(float3 heights, float contrast, inout ThreePatchesInfo patches)
{
	contrast = 1 - contrast;
	contrast = max(0.001, contrast);

	// compute weight with height map
	const float epsilon = 1.0f / 1024.0f;
	patches.weights = float3(patches.weights.x * (heights[0] + epsilon),
		patches.weights.y * (heights[1] + epsilon),
		patches.weights.z * (heights[2] + epsilon));

	// Contrast weights
	float maxWeight = max(patches.weights.x, max(patches.weights.y, patches.weights.z));
	float transition = contrast * maxWeight;
	float threshold = maxWeight - transition;
	float scale = 1.0f / transition;
	patches.weights = saturate((patches.weights - threshold) * scale);
	// Normalize weights.
	float weightScale = 1.0f / (patches.weights.x + patches.weights.y + patches.weights.z);
	patches.weights *= weightScale;
}

float4 blendColors(ThreeSamples4D samples, ThreePatchesInfo patches, float diffuseModulatingParam, float diffuseExponent, float contrast, uniform int iBlendingType = LINEAR_BLENDING)
{
	if (iBlendingType == BLENDING_0)
	{
		// Use luminance as weight.
		float3 Lw = float3(0.299, 0.587, 0.114);
		float3 Dw = float3(dot(samples.sample1.xyz, Lw), dot(samples.sample2.xyz, Lw), dot(samples.sample3.xyz, Lw));

		Dw = lerp(1.0, Dw, diffuseModulatingParam);
		patches.weights = Dw * pow(patches.weights, diffuseExponent);

		patches.weights /= dot(patches.weights, float3(1, 1, 1));
		if (contrast != 0.5) patches.weights = Gain3(patches.weights, contrast);
	}
	return patches.weights[0] * samples.sample1 + patches.weights[1] * samples.sample2 + patches.weights[2] * samples.sample3;
}

float blendColors(float3 samples, ThreePatchesInfo patches, float diffuseModulatingParam, float diffuseExponent, float contrast, uniform int iBlendingType = LINEAR_BLENDING)
{
	if (iBlendingType == BLENDING_0)
	{
		// Use luminance as weight.
		float3 Dw = samples;

		Dw = lerp(1.0, Dw, diffuseModulatingParam);
		patches.weights = Dw * pow(patches.weights, diffuseExponent);

		patches.weights /= dot(patches.weights, float3(1, 1, 1));
		if (contrast != 0.5) patches.weights = Gain3(patches.weights, contrast);
	}
	return dot(patches.weights, samples);
}

float2 blendDerivs(ThreeSamples2D samples, ThreePatchesInfo patches, float diffuseModulatingParam, float diffuseExponent, float contrast, uniform int iBlendingType = LINEAR_BLENDING)
{
	if (iBlendingType == BLENDING_0)
	{
		// Produce sine to the angle between the conceptual normal
		// in tangent space and the Z-axis.
		float3 D = float3(dot(samples.sample1, samples.sample1), dot(samples.sample2, samples.sample2), dot(samples.sample3, samples.sample3));
		float3 Dw = sqrt(D / (1.0 + D));
		Dw = lerp(1.0, Dw, diffuseModulatingParam); // 0.6
		patches.weights = Dw * pow(patches.weights, diffuseExponent); // 7
		patches.weights /= dot(patches.weights, float3(1, 1, 1));
		if (contrast != 0.5) patches.weights = Gain3(patches.weights, contrast);
	}
	return patches.weights[0] * samples.sample1 + patches.weights[1] * samples.sample2 + patches.weights[2] * samples.sample3;
}

float3 toNormal(float2 deriv)
{
	return normalize(float3(-deriv, 1));
}

#endif