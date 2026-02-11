#include "common/States11.hlsl"
#include "common/Samplers11.hlsl"
#include "common/context.hlsl"

Texture2D<float>	srcDepth;
Texture2DArray<float>	shadowmap;
RWStructuredBuffer<float3>	dstPoints;

StructuredBuffer<float3> srcPoints;

cbuffer cbUniforms {
	float4x4 viewProj;
	float4x4 viewProjInv;
	float4x4 shadowmapProj[3];
	float3	radarPos;
	float	dummy0;
	float3	radarDir;
	float	distanceFar;
	float4	distances;
	uint2	srcDims;
};

#define ANGLE_STEP 0.5 
#define POINT_COUNT 361
#define DISTANCE_STEPS 10
#define LINE_WIDTH 0.001
#define SHADOWMAP_BIAS 0.0001
#define PI 3.1415926535897932384626433832795

float calcShadow(float4 wpos, uint idx) {
	float4 smPos = mul(wpos, shadowmapProj[idx]);
	smPos.xyz /= smPos.w;
	float shadow = shadowmap.SampleCmpLevelZero(gCascadeShadowSampler, float3(smPos.xy, idx), smPos.z + SHADOWMAP_BIAS);
	return lerp(1, shadow, smPos.z > 0);
}

float3 calcPos(float2 offset, uniform uint shadowmapCount) {
	float2 p = radarPos.xz + offset;
	float2 pp = mul(float4(p.x, 0, p.y, 1), viewProj).xy;

	float depth = srcDepth.Load(uint3((float2(pp.x, -pp.y) * 0.5 + 0.5) * srcDims, 0)).x;

//	if (pp.x < -1 || pp.x > 1 || pp.y < -1 || pp.y > 1)
	if (depth == 0 || any(step(1, abs(pp.xy))))
		return float3(0, 0, 0);

	float4 wpos = mul(float4(pp.xy, depth, 1), viewProjInv);	// restore world position

	float shadow = 1.0;
	[unroll]
	for (uint i = 0; i < shadowmapCount; ++i)
		shadow = min(shadow, calcShadow(wpos, i));

	if (shadow == 0.0)
		return float3(0, 0, 0);
	
	return wpos.xyz;
}

float2 calcDir(uint idx) {
	float angle = (idx * ANGLE_STEP - 90) / 180 * PI;
	float s, c;
	sincos(angle, s, c);
	float2x2 rot = { c, -s, s, c };
	return normalize(mul(radarDir.xz, rot));
}

[numthreads(POINT_COUNT, 1, 1)]
void CS_TEST(uint li: SV_GroupId, uint pi : SV_GroupThreadId, uniform uint shadowmapCount) {
	uint sbi = li * POINT_COUNT + pi;
	float2 dir = calcDir(pi);
	float dist = distances[li];
	dstPoints[sbi] = calcPos(dir * dist, shadowmapCount);
}

[numthreads(POINT_COUNT, 1, 1)]
void CS_MAX(uint li : SV_GroupId, uint pi : SV_GroupThreadId, uniform uint shadowmapCount) {
	uint sbi = li * POINT_COUNT + pi;
	float2 dir = calcDir(pi);
	float dists[5] = { distances[0], distances[1], distances[2], distances[3], distanceFar };
	float min_dist = dists[li], max_dist = dists[li+1];
	float3 pos = calcPos(dir * min_dist, shadowmapCount);
	[unroll(DISTANCE_STEPS - 1)]
	for (uint i = 1; i < DISTANCE_STEPS; ++i) {
		float dist = lerp(min_dist, max_dist, i / float(DISTANCE_STEPS));
		float3 p = calcPos(dir * dist, shadowmapCount);
		if (p.y > pos.y)
			pos = p;
	}	
	dstPoints[sbi] = pos;
}

struct GS_INPUT_SOLID {
	float4 pos : SV_POSITION;
	float2 tangent : COLOR0;
};		

GS_INPUT_SOLID VS_SOLID(uint vid : SV_VertexID, uniform uint offset) {
	GS_INPUT_SOLID o;
	float3 p = srcPoints[vid + offset];
	float w = any(p);
	o.pos = mul(float4(p, w), gViewProj);
	if (vid == 0 || !any(srcPoints[vid - 1])) {
		float4 p2 = mul(float4(srcPoints[vid + 1], w), gViewProj);
		o.tangent = normalize(o.pos.xy - p2.xy).yx;
	} else {
		float4 p2 = mul(float4(srcPoints[vid - 1], w), gViewProj);
		o.tangent = normalize(p2.xy - o.pos.xy).yx;
	}
	o.tangent.y = -o.tangent.y;
	return o;
}

struct GS_INPUT_DASHED {
	float4 pos : SV_POSITION;
	uint odd : COLOR0;
};

GS_INPUT_DASHED VS_DASHED(uint vid : SV_VertexID, uniform uint dash, uniform uint offset) {
	GS_INPUT_DASHED o;
	float3 p = srcPoints[vid + offset];
	o.pos = mul(float4(p, any(p)), gViewProj);
	o.odd = vid & dash;
	return o;
}

float4 VS_DOTTED(uint vid : SV_VertexID, uniform uint offset): SV_POSITION0 {
	float3 p = srcPoints[vid + offset];
	return mul(float4(p, any(p)), gViewProj);
}

struct PS_INPUT {
	float4 pos: SV_POSITION;
};

[maxvertexcount(4)]
void GS_SOLID(line GS_INPUT_SOLID i[2], inout TriangleStream<PS_INPUT> os) {
	float width = gProj._m00 * LINE_WIDTH;
	PS_INPUT o;
	if (all(float2(i[0].pos.w, i[1].pos.w))) {
		float2 t = i[0].tangent * (i[0].pos.w * width);
		o.pos = float4(i[0].pos.xy + t, i[0].pos.zw);
		os.Append(o);
		o.pos = float4(i[0].pos.xy - t, i[0].pos.zw);
		os.Append(o);
		t = i[1].tangent * (i[1].pos.w * width);
		o.pos = float4(i[1].pos.xy + t, i[1].pos.zw);
		os.Append(o);
		o.pos = float4(i[1].pos.xy - t, i[1].pos.zw);
		os.Append(o);
		os.RestartStrip();
	}
}

[maxvertexcount(4)]
void GS_DASHED(line GS_INPUT_DASHED i[2], inout TriangleStream<PS_INPUT> os) {
	PS_INPUT o;
	
	float2 t = normalize(i[1].pos.yx - i[0].pos.yx); t.x = -t.x;
	t *= gProj._m00 * LINE_WIDTH * i[0].pos.w;
	if (all(float3(i[0].pos.w, i[1].pos.w, i[0].odd)))	{
		o.pos = float4(i[0].pos.xy + t, i[0].pos.zw);
		os.Append(o);
		o.pos = float4(i[0].pos.xy - t, i[0].pos.zw);
		os.Append(o);
		o.pos = float4(i[1].pos.xy + t, i[1].pos.zw);
		os.Append(o);
		o.pos = float4(i[1].pos.xy - t, i[1].pos.zw);
		os.Append(o);
		os.RestartStrip();
	}
}

[maxvertexcount(8)]
void GS_DOTTED(line float4 i[2]: SV_POSITION0, inout TriangleStream<PS_INPUT> os) {
	PS_INPUT o;
	float2 t = normalize(i[1].yx - i[0].yx); t.x = -t.x;
	t *= gProj._m00 * LINE_WIDTH * i[0].w;
	
	if (all(float2(i[0].w, i[1].w))) {
		float4 p[4] = { i[0], lerp(i[0], i[1], 0.25), (i[0] + i[1]) * 0.5, lerp(i[0], i[1], 0.75) };
		o.pos = float4(p[0].xy + t, p[0].zw);
		os.Append(o);
		o.pos = float4(p[0].xy - t, p[0].zw);
		os.Append(o);
		o.pos = float4(p[1].xy + t, p[1].zw);
		os.Append(o);
		o.pos = float4(p[1].xy - t, p[1].zw);
		os.Append(o);
		os.RestartStrip();
		o.pos = float4(p[2].xy + t, p[2].zw);
		os.Append(o);
		o.pos = float4(p[2].xy - t, p[2].zw);
		os.Append(o);
		o.pos = float4(p[3].xy + t, p[3].zw);
		os.Append(o);
		o.pos = float4(p[3].xy - t, p[3].zw);
		os.Append(o);
		os.RestartStrip();
	}
}

[maxvertexcount(2)]
void GS_DEBUG(line float4 p[2] : SV_POSITION0, inout LineStream<PS_INPUT> os) {
	PS_INPUT o;
	if (all(float2(p[0].w, p[1].w))) {
		o.pos = p[0];
		os.Append(o);
		o.pos = p[1];
		os.Append(o);
		os.RestartStrip();
	}
}

float4 PS_DEBUG() : SV_TARGET0 {
	return float4(1, 0, 1, 1);
}

float4 PS() : SV_TARGET0 {
	return float4(0, 3.0, 0, 0.5);
}

#define COMMON_CS_PART 		SetVertexShader(NULL);		\
							SetHullShader(NULL);		\
							SetDomainShader(NULL);		\
							SetGeometryShader(NULL);	\
							SetPixelShader(NULL);							

#define COMMON_PS_PART 									\
		SetPixelShader(CompileShader(ps_5_0, PS()));	\
		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);	\
		SetDepthStencilState(disableDepthBuffer, 0);	\
		SetRasterizerState(cullNone);					\
		SetHullShader(NULL);							\
		SetDomainShader(NULL);							\

technique10 Tech {
	pass P0	{
		SetComputeShader(CompileShader(cs_5_0, CS_TEST(1)));
		COMMON_CS_PART
	}
	pass P1 {
		SetComputeShader(CompileShader(cs_5_0, CS_TEST(2)));
		COMMON_CS_PART
	}
	pass P2 {
		SetComputeShader(CompileShader(cs_5_0, CS_TEST(3)));
		COMMON_CS_PART
	}

	pass P3	{
		SetComputeShader(CompileShader(cs_5_0, CS_MAX(1)));
		COMMON_CS_PART
	}
	pass P4 {
		SetComputeShader(CompileShader(cs_5_0, CS_MAX(2)));
		COMMON_CS_PART
	}
	pass P5	{
		SetComputeShader(CompileShader(cs_5_0, CS_MAX(3)));
		COMMON_CS_PART
	}

	pass P6	{
		SetVertexShader(CompileShader(vs_5_0, VS_SOLID(0)));
		SetGeometryShader(CompileShader(gs_5_0, GS_SOLID()));
		COMMON_PS_PART
	}
	pass P7	{
		SetVertexShader(CompileShader(vs_5_0, VS_DASHED(3, POINT_COUNT)));
		SetGeometryShader(CompileShader(gs_5_0, GS_DASHED()));
		COMMON_PS_PART
	}
	pass P8	{
		SetVertexShader(CompileShader(vs_5_0, VS_DASHED(1, POINT_COUNT * 2)));
		SetGeometryShader(CompileShader(gs_5_0, GS_DASHED()));
		COMMON_PS_PART
	}
	pass P9 {
		SetVertexShader(CompileShader(vs_5_0, VS_DOTTED(POINT_COUNT * 3)));
		SetGeometryShader(CompileShader(gs_5_0, GS_DOTTED()));
		COMMON_PS_PART
	}

	pass P10 {
		SetVertexShader(CompileShader(vs_5_0, VS_DOTTED(0)));
		SetGeometryShader(CompileShader(gs_5_0, GS_DEBUG()));
		SetPixelShader(CompileShader(ps_5_0, PS_DEBUG()));
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(disableDepthBuffer, 0);
		SetRasterizerState(cullNone);
		SetHullShader(NULL);
		SetDomainShader(NULL);
	}
}

