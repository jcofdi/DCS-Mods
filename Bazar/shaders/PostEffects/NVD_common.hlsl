#ifndef _NVD_COMMON_
#define _NVD_COMMON_

#include "common/context.hlsl"

#define MASK_SIZE (1.0/0.8)

float getMask(float2 c, float mul)
{
	return saturate(mul*(1 - sqrt(dot(c, c))));
}

float2 calcMaskCoord(float2 projPos)
{
	return float2((projPos.x - gNVDpos.x) * gNVDaspect, projPos.y - gNVDpos.y) * MASK_SIZE;
}

float getNVDMask(float2 projPos) {
	float2 uvm = calcMaskCoord(projPos);
	return getMask(uvm, 10);
}

float getMask2(float d, float mul)
{
	return 1 - saturate(mul * (1 - d));
}

float2 calcMaskCoord2(float2 projPos)
{
	float4 vp = mul(float4(projPos, 1, 1), gProjInv);
	float3 vp3 = normalize(vp.xyz / vp.w);
	float mul = sqrt(gNVDmul);
	return float2(dot(gNVDdir, vp3) * gNVDmul, sqrt(1.0 - 1.0 / (gNVDmul * gNVDmul)));
}

float getNVDMask2(float2 projPos)
{
	float2 d = calcMaskCoord(projPos);
	return getMask(d.x, 10 * d.x / d.y);
}

#endif
