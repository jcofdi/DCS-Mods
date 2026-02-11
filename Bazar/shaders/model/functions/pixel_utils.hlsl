#ifndef ED_MODEL_PIXEL_UTILS_HLSL
#define ED_MODEL_PIXEL_UTILS_HLSL

#include "common/softParticles.hlsl"
#include "common/fake_lights_debug_uniforms.hlsl"

float calc_size_in_pixels(float4 p, float s)
{
	float4 p1 = float4(p.x - s, p.y - s, p.z, 1);
	float4 p2 = float4(p.x + s, p.y + s, p.z, 1);

	p1 = mul(p1, gProj);
	p2 = mul(p2, gProj);

	p1.xy /= p1.w;
	p2.xy /= p2.w;

	return min(abs(p2.x - p1.x), abs(p2.y - p1.y)) / 2.0;
}

float calc_size_in_pixels2(float4 p, float s)
{
	float4 p1 = float4(p.x - s, p.y - s, p.z, 1);
	float4 p2 = float4(p.x + s, p.y + s, p.z, 1);

	p1 = mul(p1, gProj);
	p2 = mul(p2, gProj);

	p1.xy /= p1.w;
	p2.xy /= p2.w;

	return abs(p2.y - p1.y) * gSreenParams.y / 2.0;
}

float make_soft_sphere(float4 projPos, float radius) {
	float depth = g_DepthTexture.SampleLevel(gPointClampSampler, float2(projPos.x, -projPos.y) / projPos.w*0.5 + 0.5, 0).r;
	float4 p0 = mul(projPos, gProjInv);
	float4 p1 = mul(float4(projPos.xy / projPos.w, depth, 1), gProjInv);
	return saturate((p1.z / p1.w - p0.z / p0.w) * radius * FL_DBG_softParticleMult);
}

#endif
