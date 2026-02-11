
Texture2D<float4> SrcTexture;
RWStructuredBuffer<float4> Output;
uint OutputID;
RWTexture2D<float4> DebugOutput;

#define TG_SIZE_X 32
#define TG_SIZE_Y 16
#define CHUNK_X	2
#define CHUNK_Y	4

static const uint TotalNumThreads = TG_SIZE_X * TG_SIZE_Y;
groupshared float4 SharedMem[TotalNumThreads];

float4 SampleAverage(uint2 samplePos) {
	float4 sm = 0.0;
	[unroll]
	for (uint y = 0; y < CHUNK_Y; ++y)
		for (uint x = 0; x < CHUNK_X; ++x) {
			float4 c = SrcTexture[samplePos + uint2(x, y)];
			sm += float4(c.xyz, saturate(c.a));
		}
	return sm;
}


[numthreads(TG_SIZE_X, TG_SIZE_Y, 1)]
void CS(uint3 GroupThreadID : SV_GroupThreadID, uint threadId : SV_GroupIndex)
{
	const uint2 sampleId = GroupThreadID.xy * uint2(CHUNK_X, CHUNK_Y);
	
	float4 avg = SampleAverage(sampleId);

	SharedMem[threadId] = avg;
	GroupMemoryBarrierWithGroupSync();

	// Parallel reduction
	[unroll(uint(ceil(log2(TotalNumThreads))))]
	for (uint s = TotalNumThreads / 2; s > 0; s >>= 1) {
		if (threadId < s)
			SharedMem[threadId] += SharedMem[threadId + s];

		GroupMemoryBarrierWithGroupSync();
	}

	if (threadId == 0) {
		float4 c = SharedMem[0];
		c = float4(c.xyz / (c.a + 1e-9), c.a * (1.0 / (TotalNumThreads * CHUNK_X * CHUNK_Y)) );
//		c = float4(1, 0, 0, 1);
		
		Output[OutputID] = c;
		DebugOutput[uint2(0, 0)] = c;
	}
}


technique10 Tech
{
    pass P0
	{
		SetComputeShader(CompileShader(cs_5_0, CS()));
		SetVertexShader(NULL);
		SetPixelShader(NULL);
		SetGeometryShader(NULL);
		SetHullShader(NULL);
		SetDomainShader(NULL);
    }
}
