#ifndef _LENS_COMPUTE_HLSL
#define _LENS_COMPUTE_HLSL

#include "common/samplers11.hlsl"
#include "common/context.hlsl"
#define FOG_ENABLE
#include "common/fog2.hlsl"
#include "deferred/shadows.hlsl"

struct LensData
{
	float2 params;
};
#define sbShadow			lensData[0].params.x //текущая затененость камеры
#define sbSunlightSmooth	lensData[0].params.y //освещенность

RWStructuredBuffer<LensData> lensData: register (u0);

Texture2D cloudsShadowMap;

#ifdef MSAA
	Texture2DMS<float, MSAA> distanceMap;
	float SampleDepthMap(uint2 uv) { return distanceMap.Load(uv, 0).r; }
#else
	Texture2D<float> distanceMap;
	float SampleDepthMap(uint2 uv) { return distanceMap.Load(uint3(uv, 0)).r; }
#endif
uint2	dims;
	
float4x4 cloudsProj;
float3 sunScreenPos;
float3 cameraOrigin;
float timeDelta;

static const float2 Poisson25[] = {
	{-0.978698, -0.0884121},
	{-0.841121, 0.521165},
	{-0.71746, -0.50322},
	{-0.702933, 0.903134},
	{-0.663198, 0.15482},
	{-0.495102, -0.232887},
	{-0.364238, -0.961791},
	{-0.345866, -0.564379},
	{-0.325663, 0.64037},
	{-0.182714, 0.321329},
	{-0.142613, -0.0227363},
	{-0.0564287, -0.36729},
	{-0.0185858, 0.918882},
	{0.0381787, -0.728996},
	{0.16599, 0.093112},
	{0.253639, 0.719535},
	{0.369549, -0.655019},
	{0.423627, 0.429975},
	{0.530747, -0.364971},
	{0.566027, -0.940489},
	{0.639332, 0.0284127},
	{0.652089, 0.669668},
	{0.773797, 0.345012},
	{0.968871, 0.840449},
	{0.991882, -0.657338},
};


float getCloudShadow()
{
	return SampleShadowClouds(gCameraPos);
}

static const uint samplesCount = 25;
static const float samplesCountInv = 1.0/samplesCount;

groupshared float sharedBuffer[samplesCount];

[numthreads(samplesCount, 1, 1)]
void csCameraOcclusion(uint id : SV_GroupIndex, uint3 groupId : SV_GroupId)
{
	float shadow=0;
	float2 pos = float2(sunScreenPos.x, -sunScreenPos.y)*0.5+0.5;
	float zoomCoef = gProj._11/1.73;

	float2  p = pos + Poisson25[id]*0.02*zoomCoef;
	if(!any(max(0, abs(p*2-1)-1))) // test if p in range [0..1]
		sharedBuffer[id] = SampleDepthMap(p*dims).r>0? 0.0f : 1.0f;
	else
		sharedBuffer[id] = 0;

	GroupMemoryBarrierWithGroupSync();

	[unroll(uint(ceil(log2(32/*nearest value from the set of powers of 2 greater than 'samplesCount'*/))))]
	for (uint s = 32/2; s > 0; s >>= 1)
	{
		if(id < s && (id + s) < samplesCount)
			sharedBuffer[id] += sharedBuffer[id + s];
		GroupMemoryBarrierWithGroupSync();
	}

	if(id == 0)
		sbShadow = getCloudShadow() * sharedBuffer[0] * samplesCountInv;
}

technique10 lensCompute
{
	pass P0
	{
		SetComputeShader(CompileShader(cs_5_0, csCameraOcclusion()));
	}
}

#endif