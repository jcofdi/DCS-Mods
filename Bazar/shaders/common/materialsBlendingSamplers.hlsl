#ifndef _materials_blending_samplers_hlsl
#define _materials_blending_samplers_hlsl

struct MaskAndWeightsOfTheMIP
{
	uint mask00;
	uint mask01;
	uint mask10;
	uint mask11;

	float4 weights00;
	float4 weights01;
	float4 weights10;
	float4 weights11;

	float2 t;
};

struct MaskAndWeightsOfNeighbourMips
{
	MaskAndWeightsOfTheMIP m0;
	MaskAndWeightsOfTheMIP m1;
	float t;
};

void sampleMaskAndWeights(Texture2D<uint> mask, Texture2D weights, int2 ij, uint mip, uint2 maxIndex, out uint m, out float4 w)
{
	ij = clamp(ij, 0, maxIndex);
	m = mask.mips[mip][ij];
	w = weights.mips[mip][ij];
}

MaskAndWeightsOfTheMIP sampleMaskAndWeights(Texture2D<uint> mask, Texture2D weights, uint width, uint height, float2 uv, uint mip)
{
	MaskAndWeightsOfTheMIP m;

	width = width >> mip;
	height = height >> mip;

	uint2 maxIndex = uint2(width - 1, height - 1);

	float2 ij;
	ij = uv * (maxIndex + 1) - 0.5;

	m.t = frac(ij);
	ij = floor(ij);

	sampleMaskAndWeights(mask, weights, ij, mip, maxIndex, m.mask00, m.weights00);
	sampleMaskAndWeights(mask, weights, ij + int2(0, 1), mip, maxIndex, m.mask01, m.weights01);
	sampleMaskAndWeights(mask, weights, ij + int2(1, 0), mip, maxIndex, m.mask10, m.weights10);
	sampleMaskAndWeights(mask, weights, ij + int2(1, 1), mip, maxIndex, m.mask11, m.weights11);

	return m;
}

MaskAndWeightsOfNeighbourMips sampleMaskAndWeights(Texture2D<uint> mask, Texture2D weights, float2 uv)
{
	MaskAndWeightsOfNeighbourMips m;

	float2 dUVdx = abs(ddx(uv));
	float2 dUVdy = abs(ddy(uv));

	uint width = 0;
	uint height = 0;
	mask.GetDimensions(width, height);

	float2 size = float2(width, height);

	float2 densityX = dUVdx * size;
	float2 densityY = dUVdy * size;

	float density = max(densityX.x, densityX.y);
	density = max(density, densityY.x);
	density = max(density, densityY.y);

	float mip = log2(density);
	mip = max(mip, 0.0f);

	uint mip0 = floor(mip);
	uint mip1 = mip0 + 1;

	m.m0 = sampleMaskAndWeights(mask, weights, width, height, uv, mip0);
	m.m1 = sampleMaskAndWeights(mask, weights, width, height, uv, mip1);
	m.t = frac(mip);

	return m;
}

float fromSRGB(float c)
{
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

float4 fromSRGB(float4 c)
{
	float4 ret = 0;
	ret.x = fromSRGB(c.x);
	ret.y = fromSRGB(c.y);
	ret.z = fromSRGB(c.z);

	float4x4 m = float4x4(0.4124, 0.3576, 0.1805, 0.0,
		0.2126, 0.7152, 0.0722, 0.0,
		0.0193, 0.1192, 0.9505, 0.0,
		0.0, 0.0, 0.0, 1.0);

	ret = mul(m, ret);
	ret.w = c.w;

	return ret;
}

float toSRGB(float c)
{
	return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

float4 toSRGB(float4 c)
{
	float4 ret;

	float4x4 m = float4x4(3.2406, -1.5372, -0.4986, 0.0,
		-0.9689, 1.8758, 0.0415, 0.0,
		0.0557, -0.2040, 1.0570, 0.0,
		0.0, 0.0, 0.0, 1.0);

	ret = mul(m, c);
	
	ret.x = toSRGB(ret.x);
	ret.y = toSRGB(ret.y);
	ret.z = toSRGB(ret.z);
	ret.w = c.w;

	return ret;
}

float4 sampleTex(Texture2DArray tex, SamplerState ss, float2 uv, uint mask, float4 weights)
{
	uint width = 0;
	uint height = 0;
	uint elements = 0;
	tex.GetDimensions(width, height, elements);

	int weightIndex = 0;
	float4 res = 0.0f;
	for (int i = 0; i < elements; ++i)
	{
		if ((1 << i) & mask)
		{
			float4 c = fromSRGB(tex.SampleGrad(ss, float3(uv, i), ddx(uv), ddy(uv)));
			res += weights[weightIndex] * c;
			++weightIndex;
		}
	}
	return toSRGB(res);
}

float4 sampleTex(Texture2DArray tex, SamplerState ss, float2 uv, MaskAndWeightsOfTheMIP m)
{
	float4 c00 = sampleTex(tex, ss, uv, m.mask00, m.weights00);
	float4 c01 = sampleTex(tex, ss, uv, m.mask01, m.weights01);
	float4 c10 = sampleTex(tex, ss, uv, m.mask10, m.weights10);
	float4 c11 = sampleTex(tex, ss, uv, m.mask11, m.weights11);

	float4 c0 = lerp(c00, c10, m.t.x);
	float4 c1 = lerp(c01, c11, m.t.x);
	float4 c = lerp(c0, c1, m.t.y);

	return c;
}

float4 sampleTex(Texture2DArray tex, SamplerState ss, float2 uv, MaskAndWeightsOfNeighbourMips m)
{
	float4 c0 = sampleTex(tex, ss, uv, m.m0);
	float4 c1 = sampleTex(tex, ss, uv, m.m1);
	float4 c = lerp(c0, c1, m.t);

	return c;
}

uint sampleMask(Texture2D<uint> mask, float2 uv, uint mip)
{
	uint width = 0;
	uint height = 0;
	mask.GetDimensions(width, height);

	width = width >> mip;
	height = height >> mip;

	float2 ij;
	ij = uv * float2(width, height) - 0.5;
	ij = floor(ij);

	return mask.mips[mip][ij];
}

float4 sampleWeights(Texture2D weights, float2 uv, uint mip)
{
	uint width = 0;
	uint height = 0;
	weights.GetDimensions(width, height);

	width = width >> mip;
	height = height >> mip;

	float2 ij;
	ij = uv * float2(width, height) - 0.5;
	ij = floor(ij);

	return weights.mips[mip][ij];
}

uint weightIndex(uint mask, uint channel)
{
	uint index = 0;
	channel = channel >> 1;
	for (; channel != 0; channel = channel >> 1)
	{
		if (channel & mask)
			++index;
	}
	return index;
}

uint arrayIndex(uint channel)
{
	return log2(channel);
}

#endif

