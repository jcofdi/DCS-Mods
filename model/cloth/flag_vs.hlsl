#include "common/context.hlsl"
#include "flag_structs.hlsl"

static const float ALMOST_ZERO = 0.0001;

StructuredBuffer<float3> buf0;
StructuredBuffer<float3> colorBuf;
StructuredBuffer<float3> forceBuf;
StructuredBuffer<float3> normalsBuf;

float3 get_force(int2 posInd)
{
	int ind = posInd.x + posInd.y * flagSize.x;
	float3 p = forceBuf[ind];
	return p;
}

float3 get_pos(int2 posInd)
{
	int ind = posInd.x + posInd.y * flagSize.x;
	float3 p = buf0[ind];
	return p;
}

float3 calc_unormal(float3 p0, float3 p1, float3 p2){
	float3 a = p1 - p0;
	float3 b = p2 - p0;
	float3 c = cross(b, a);	
	return c;
}

float3 calc_avg_normal(float3 p0, int2 ind)
{
	float3 o = 0;

	if(ind.x == 0 && ind.y == 0){
		float3 p1 = buf0[(ind.y + 1) * flagSize.x + ind.x];
		float3 p2 = buf0[ind.y * flagSize.x + ind.x + 1];
		float3 n = calc_unormal(p0, p1, p2);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.x == 0 && ind.y == (flagSize.y - 1)){
		float3 p1 = buf0[(ind.y - 1) * flagSize.x + ind.x];
		float3 p2 = buf0[ind.y * flagSize.x + ind.x + 1];
		float3 n = calc_unormal(p0, p1, p2);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.x == (flagSize.x - 1) && ind.y == (flagSize.y - 1)){
		float3 p1 = buf0[ind.y * flagSize.x + ind.x - 1];
		float3 p2 = buf0[(ind.y - 1) * flagSize.x + ind.x];
		float3 n = calc_unormal(p0, p1, p2);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.x == (flagSize.x - 1) && ind.y == 0){
		float3 p1 = buf0[(ind.y + 1) * flagSize.x + ind.x];
		float3 p2 = buf0[ind.y * flagSize.x + ind.x - 1];
		
		float3 n = calc_unormal(p0, p1, p2);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.x == 0){
		float3 p1 = buf0[(ind.y - 1) * flagSize.x + ind.x];
		float3 p2 = buf0[ind.y * flagSize.x + ind.x + 1];
		float3 p3 = buf0[(ind.y + 1) * flagSize.x + ind.x];
		
		float3 n = calc_unormal(p0, p1, p2) + calc_unormal(p0, p2, p3);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.y == 0){
		float3 p1 = buf0[ind.y * flagSize.x + ind.x + 1];
		float3 p2 = buf0[(ind.y + 1) * flagSize.x + ind.x];
		float3 p3 = buf0[ind.y * flagSize.x + ind.x - 1];
		
		float3 n = calc_unormal(p0, p1, p2) + calc_unormal(p0, p2, p3);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.x == (flagSize.x - 1)){
		float3 p1 = buf0[(ind.y + 1) * flagSize.x + ind.x];
		float3 p2 = buf0[ind.y * flagSize.x + ind.x - 1];
		float3 p3 = buf0[(ind.y - 1) * flagSize.x + ind.x];
		
		float3 n = calc_unormal(p0, p1, p2) + calc_unormal(p0, p2, p3);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}

	if(ind.y == (flagSize.y - 1)){
		float3 p1 = buf0[ind.y * flagSize.x + ind.x - 1];
		float3 p2 = buf0[(ind.y - 1) * flagSize.x + ind.x];
		float3 p3 = buf0[ind.y * flagSize.x + ind.x + 1];
		
		float3 n = calc_unormal(p0, p1, p2) + calc_unormal(p0, p2, p3);
		if(length(n) < ALMOST_ZERO){
			return 0;
		}
		return normalize(n);
	}
	
	float3 p1 = buf0[ind.y * flagSize.x + ind.x + 1];
	float3 p2 = buf0[(ind.y + 1) * flagSize.x + ind.x];
	float3 p3 = buf0[ind.y * flagSize.x + ind.x - 1];
	float3 p4 = buf0[(ind.y - 1) * flagSize.x + ind.x];
	
	float3 n = calc_unormal(p0, p1, p2) + calc_unormal(p0, p2, p3) + calc_unormal(p0, p3, p4) + calc_unormal(p0, p4, p1);
	if(length(n) < ALMOST_ZERO){
		return 0;
	}
	return normalize(n);
}

VS_FLAG_OUTPUT flag_vs(VS_FLAG_INPUT input)
{
	VS_FLAG_OUTPUT o;
	float3 p0 = get_pos(input.posInd.xy);
	o.Normal = calc_avg_normal(p0, input.posInd.xy);

	float3x3 normMat = (float3x3)worldPos;
	o.Normal = mul(o.Normal, normMat);

	if(input.posInd.z == 1){
		o.Normal = -o.Normal;
	}

	o.Pos = mul(float4(p0, 1), worldPos);
	o.Position = mul(o.Pos, gViewProj);
	o.Color = colorBuf[input.posInd.x + input.posInd.y * flagSize.x];

	return o;
}

VS_FLAG_FORCE_OUTPUT flag_forces_vs(VS_FLAG_INPUT input)
{
	VS_FLAG_FORCE_OUTPUT o;
	float3 p0 = get_pos(input.posInd.xy);
	float3 force = get_force(input.posInd.xy);
	float3 p1 = p0 + force;
	
	o.Pos0 = mul(float4(p0, 1), worldPos);
	o.Pos1 = mul(float4(p1, 1), worldPos);

	o.Position0 = mul(o.Pos0, gViewProj);
	o.Position1 = mul(o.Pos1, gViewProj);

	float3x3 normMat = (float3x3)worldPos;
	o.Normal = mul(normalize(force), normMat);

	return o;
}
