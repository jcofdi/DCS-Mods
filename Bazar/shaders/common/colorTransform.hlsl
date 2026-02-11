#ifndef _COLOR_TRANSFORM_HLSL
#define _COLOR_TRANSFORM_HLSL

float3 hsv2rgb(float3 c)
{
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 rgb2hsv(float3 c)
{
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	const float e = 1.0e-10;

    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float srgb2rgb(float c)
{
	return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

float3 srgb2rgb(float3 c)
{
	float3 ret = 0;
	ret.x = srgb2rgb(c.x);
	ret.y = srgb2rgb(c.y);
	ret.z = srgb2rgb(c.z);

	float3x3 m = float3x3(0.4124, 0.3576, 0.1805,
		0.2126, 0.7152, 0.0722,
		0.0193, 0.1192, 0.9505);

	ret = mul(m, ret);

	return ret;
}

float rgb2srgb(float c)
{
	return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

float3 rgb2srgb(float3 c)
{
	float3 ret;

	float3x3 m = float3x3(3.2406, -1.5372, -0.4986,
		-0.9689, 1.8758, 0.0415,
		0.0557, -0.2040, 1.0570);

	ret = mul(m, c);

	ret.x = rgb2srgb(ret.x);
	ret.y = rgb2srgb(ret.y);
	ret.z = rgb2srgb(ret.z);

	return ret;
}

#endif
