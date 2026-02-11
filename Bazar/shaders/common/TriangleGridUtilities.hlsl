#ifndef _common_triangle_grid_utilities_hlsl
#define _common_triangle_grid_utilities_hlsl

float2 hash(float2 p)
{
	float2 r = mul(float2x2(127.1, 311.7, 269.5, 183.3), p);
	return frac(sin(r) * 43758.5453);
}

#define M_PI 3.141593
float2x2 rot2x2(int2 idx, float rotStrength)
{
	float angle = abs(idx.x * idx.y) + abs(idx.x + idx.y) + M_PI;
	// Remap to +/-pi.
	angle = fmod(angle, 2 * M_PI);
	if (angle < 0) angle += 2 * M_PI;
	if (angle > M_PI) angle -= 2 * M_PI;
	angle *= rotStrength;
	float cs = cos(angle), si = sin(angle);
	return float2x2(cs, -si, si, cs);
}

// Input: vM is the tangent-space normal in [-1, 1]
// Output: convert vM to a derivative
float2 TspaceNormalToDerivative(float3 vM)
{
	const float scale = 1.0 / 128.0;
	// Ensure vM delivers a positive third component using abs() and
	// constrain vM.z so the range of the derivative is [-128, 128].
	const float3 vMa = abs(vM);
	const float z_ma = max(vMa.z, scale * max(vMa.x, vMa.y));
	// Set to match positive vertical texture coordinate axis.
	const bool gFlipVertDeriv = true;
	const float s = gFlipVertDeriv ? -1.0 : 1.0;
	return -float2(vM.x, s * vM.y) / z_ma;
}

float2 sampleDeriv(Texture2D nmap, SamplerState samp, float2 st,
	float2 dSTdx, float2 dSTdy)
{
	// Sample
	float3 vM = 2.0 * nmap.SampleGrad(samp, st, dSTdx, dSTdy).xyz - 1.0;
	return TspaceNormalToDerivative(vM);
}

float2 sampleDeriv(Texture2DArray nmap, SamplerState samp, float3 st,
	float2 dSTdx, float2 dSTdy)
{
	// Sample
	float3 vM = 2.0 * nmap.SampleGrad(samp, st, dSTdx, dSTdy).xyz - 1.0;
	return TspaceNormalToDerivative(vM);
}

float3 Gain3(float3 x, float r)
{
	r = clamp(r, 0.001, 0.999);

	// Increase contrast when r > 0.5 and
	// reduce contrast if less.
	float k = log(1 - r) / log(0.5);
	float3 s = 2 * step(0.5, x);
	float3 m = 2 * (1 - s);
	float3 res = 0.5 * s + 0.25 * m * pow(max(0.0, s + x * m), k);
	return res.xyz / (res.x + res.y + res.z);
}


#endif