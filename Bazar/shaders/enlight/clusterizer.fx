#include "common/context.hlsl"

#define GROUP_DIM 32

uint srcCount;

//#define EXTERN_ATMOSPHERE_INSCATTER_ID
//#include "common/atmosphereSamples.hlsl"
struct AtmosphereSample
{
	float3 sunColor;
	float3 transmittance; // color multiplier
	float3 inscatter; // color additive
};

StructuredBuffer<uint> srcIdx;
StructuredBuffer<AtmosphereSample> srcSamples;
RWStructuredBuffer<AtmosphereSample> dstSamples;


[numthreads(GROUP_DIM, GROUP_DIM, 1)]
void PROPAGATE(uint3 gtid : SV_GroupThreadID) {

	for (uint gIdx = gtid.y * GROUP_DIM + gtid.x; gIdx < srcCount; gIdx += GROUP_DIM * GROUP_DIM) {

		uint idx = srcIdx[gIdx];
		dstSamples[gIdx] = srcSamples[idx];
		
	}

}

#define COMMON_COMPUTE	SetVertexShader(NULL);		\
						SetGeometryShader(NULL);	\
						SetPixelShader(NULL);

technique10 Tech {
	pass P0 {
		SetComputeShader(CompileShader(cs_5_0, PROPAGATE()));
		COMMON_COMPUTE
	}
}

