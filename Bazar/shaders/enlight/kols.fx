#include "common/states11.hlsl"

#define GROUP_X 16
#define GROUP_Y 16

float threshold;
uint2 src_resolution;
uint2 dst_resolution;
uint2 scanPos;

RWTexture2D<float> dst;
RWTexture2DArray<float> dstArr; // for SCAN()
Texture2DArray<float> srcArr;	// for UPSCALE()
Texture2D<float> srcCopy;		// for COPY()

#ifdef MSAA
	Texture2DMS<float4, MSAA> src;
#else
	Texture2D<float4> src;
#endif

groupshared float cashed_col[GROUP_X * GROUP_Y];

float rand(float2 co) {
	return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 437.585453);
}

[numthreads(GROUP_X, GROUP_Y, 1)]
void CS_THRESHOLD(uint2 coord : SV_DispatchThreadId, uint2 gtid: SV_GroupThreadId ) {
	bool valid_coord = coord.x < dst_resolution.x && coord.y < dst_resolution.y;

	float col = 0.0;
	if (valid_coord) {
		uint2 src_coord = (coord * src_resolution) / dst_resolution;
		uint2 src_count = ((coord + 1) * src_resolution) / dst_resolution;
		for (uint y = src_coord.y; y < src_count.y; ++y) {
			for (uint x = src_coord.x; x < src_count.x; ++x) {
#ifdef MSAA
				float3 c = src.Load(uint2(x, y), 0).xyz;
#else
				float3 c = src.Load(uint3(x, y, 0)).xyz;
#endif			
				float res = (c.x + c.y + c.z) * 0.33333333;
				col = max(col, res);
	
			}
		}
		col += (rand(coord) - 0.5) * 0.02;
		cashed_col[gtid.y * GROUP_X + gtid.x] = col;
	}
	GroupMemoryBarrierWithGroupSync();
#if 1
	// thin out
	const uint2 thin = uint2(3, 2);
	uint2 codd = uint2(gtid / thin) * thin;

	[unroll]
	for (uint y = 0; y < thin.y; ++y) {
		[unroll]
		for (uint x = 0; x < thin.x; ++x) {
			float c = cashed_col[(codd.y + y) * GROUP_X + (codd.x + x)];
			if (col < c)
				col = 0;
		}
	}

	GroupMemoryBarrierWithGroupSync();
#endif	
	if(valid_coord)	
		dst[coord] = col > threshold ? 1.0 : 0.0;
}

[numthreads(GROUP_X, GROUP_Y, 1)]
void CS_SCAN(uint2 coord : SV_DispatchThreadId) {
	if (!(coord.x < dst_resolution.x && coord.y < dst_resolution.y))
		return;
	if (coord.x >= scanPos.x && coord.x < scanPos.y)
		dstArr[uint3(coord, 1)] = dstArr[uint3(coord, 0)];
}


[numthreads(GROUP_X, GROUP_Y, 1)]
void CS_CLEAR(uint2 coord : SV_DispatchThreadId) {
	if (!(coord.x < dst_resolution.x && coord.y < dst_resolution.y)) 
		return;
	dst[coord] = 0;
}

static float up_pat[4][4] = {
	0.3151, 0.9134, 0.9134, 0.3151,
	0.9134, 1.0, 1.0, 0.9134,
	0.9134, 1.0, 1.0, 0.9134,
	0.3151, 0.9134, 0.9134, 0.3151,
};

[numthreads(GROUP_X, GROUP_Y, 1)]
void CS_UPSCALE(uint2 coord : SV_DispatchThreadId) {
	if (!(coord.x < dst_resolution.x && coord.y < dst_resolution.y))
		return;
	int2 src_coord = coord / 4;
	int2 pat = coord % 4;
	dst[coord] = srcArr[uint3(src_coord, 1)] * up_pat[pat.x][pat.y];
}

float4 VS(uint i : SV_VertexID) : SV_POSITION0 {
	const float2 vertPos[] = {
		float2(-1, -1),	float2( 1,-1),
		float2(-1,  1),	float2( 1, 1)
	};
	return float4(vertPos[i], 0.5, 1.0);
}

float4 PS(float4 p: SV_POSITION0) : SV_TARGET0 {
	uint2 coord = p.xy;
	return float4(srcCopy.Load(uint3(coord, 0)).xxx, 1);
}


#define COMMON_CS_PART 		SetVertexShader(NULL);		\
							SetHullShader(NULL);		\
							SetDomainShader(NULL);		\
							SetGeometryShader(NULL);	\
							SetPixelShader(NULL);							

technique10 Tech {
	pass P0	{
		SetComputeShader(CompileShader(cs_5_0, CS_THRESHOLD()));
		COMMON_CS_PART
	}
	pass P1	{
		SetComputeShader(CompileShader(cs_5_0, CS_SCAN()));
		COMMON_CS_PART
	}
	pass P2	{
		SetComputeShader(CompileShader(cs_5_0, CS_CLEAR()));
		COMMON_CS_PART
	}
	pass P3	{
		SetComputeShader(CompileShader(cs_5_0, CS_UPSCALE()));
		COMMON_CS_PART
	}
	pass Copy {
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetPixelShader(CompileShader(ps_5_0, PS()));

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);

		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetComputeShader(NULL);
	}

}
