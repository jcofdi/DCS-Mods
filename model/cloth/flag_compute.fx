#include "flag_uniforms.hlsl"
#include "flag_structs.hlsl"

RWStructuredBuffer<float3> buf0;
RWStructuredBuffer<float3> buf1;
RWStructuredBuffer<float3> buf2;
RWStructuredBuffer<float3> colorBuf;
RWStructuredBuffer<float3> forceBuf;
StructuredBuffer<int> controlPoints;

static const float3 g = {0, -9.81f, 0};

float3 calc_spring(float3 p0, float3 p1, float dd0)
{
	float3 dp = p1 - p0;
	float dist = max(length(dp) - dd0, -1.0f);
	//dist = length(dp) - dd0;
	dp = normalize(dp);
	return dp * dist * stifness;
}

float3 calc_stretch_force(in Indices i)
{
	float3 o = 0;
	const float3 p0 = buf1[i.p];

#if 1
	if(i.right >= 0){
		const float3 p = buf1[i.right];
		o += calc_spring(p0, p, d0);
	}

	if(i.left >= 0){
		const float3 p = buf1[i.left];
		o += calc_spring(p0, p, d0);
	}

	if(i.up >= 0){
		const float3 p = buf1[i.up];
		o += calc_spring(p0, p, d0);
	}

	if(i.down >= 0){
		const float3 p = buf1[i.down];
		o += calc_spring(p0, p, d0);
	}
#endif
#if 1
	if(i.left_up >= 0){
		const float3 p = buf1[i.left_up];
		o += calc_spring(p0, p, d0 * 1.41421356237);
	}

	if(i.left_down >= 0){
		const float3 p = buf1[i.left_down];
		o += calc_spring(p0, p, d0 * 1.41421356237);
	}

	if(i.right_up >= 0){
		const float3 p = buf1[i.right_up];
		o += calc_spring(p0, p, d0 * 1.41421356237);
	}

	if(i.right_down >= 0){
		const float3 p = buf1[i.right_down];
		o += calc_spring(p0, p, d0 * 1.41421356237);
	}
#endif

	forceBuf[i.p] = o;

	return o;
}

float3 calc_bending_force(in Indices i)
{
	float3 o = 0;
	const float3 p0 = buf1[i.p];

	if(i.right2 >= 0){
		const float3 p = buf1[i.right2];
		o += calc_spring(p0, p, d0 * 2);
	}

	if(i.left2 >= 0){
		const float3 p = buf1[i.left2];
		o += calc_spring(p0, p, d0 * 2);
	}

	if(i.up2 >= 0){
		const float3 p = buf1[i.up2];
		o += calc_spring(p0, p, d0 * 2);
	}

	if(i.down2 >= 0){
		const float3 p = buf1[i.down2];
		o += calc_spring(p0, p, d0 * 2);
	}

	forceBuf[i.p] = o;

	return o;
}

float3 calc_wind_force(float3 p){
	if(length(windForce) < 0.001){
		return 0;
	}
	return windForce;
}

float3 calc_damping_force(float3 p1, float3 p2){
	float3 v = (p2 - p1) / dt;
	float3 dampingForce = v * damping;
	return dampingForce;
}

#define GROUPSIZE 16
[numthreads(GROUPSIZE, GROUPSIZE, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID){
	Indices i = build_indices(dispatchThreadID.xy, size.x, size.y);

	if(controlPoints[i.p] == 0){
		buf0[i.p] = buf1[i.p];
		return;
	}

	float3 p1 = buf1[i.p];
	float3 p2 = buf2[i.p];

	float3 dampingForce = calc_damping_force(p1, p2);
	float3 springsForce = calc_stretch_force(i);
	float3 bendingForce = calc_bending_force(i);
	float3 windForce = calc_wind_force(p1);

	float3 a1 = g + (dampingForce + windForce) / mass;
	float3 a2 = (springsForce + bendingForce) / mass;
	float3 A = a1 + a2;
	float3 p0 = 2.0f * p1 - p2 + A * dt * dt;
	buf0[i.p] = p0;

	if(length(springsForce) < 0.01){
		colorBuf[i.p] = 0;
	}else{
		float3 n = normalize(springsForce);
		if(n.y < 0){
			colorBuf[i.p] = float3(1,0,0);
		}else{
			colorBuf[i.p] = n;
		}
	}
}

void relax_constrain(in int i0, in int i1, float dd0)
{
	float3 dp = buf0[i1] - buf0[i0];
	float d = (length(dp) - dd0) / 2.0;
	if(d < 0.001){
		return;
	}
	dp = normalize(dp);

	if(controlPoints[i0] == 0 && controlPoints[i1] == 0){
		buf0[i0] += dp * d;
		buf0[i1] -= dp * d;
	}else if(controlPoints[i0] == 0){
		buf0[i1] -= dp * d * 2;
	}else if(controlPoints[i1] == 0){
		buf0[i0] += dp * d * 2;
	}else{
		buf0[i0] += dp * d;
		buf0[i1] -= dp * d;
	}
}

[numthreads(GROUPSIZE, GROUPSIZE, 1)]
void enforcing_constraints(uint3 pos : SV_DispatchThreadID){
	Indices i = build_indices(pos.xy, size.x, size.y);

	for(int j = 0; j < 10; ++j){
	if(i.right >= 0){
		relax_constrain(i.p, i.right, d0);
	}

	if(i.up >= 0){
		relax_constrain(i.p, i.up, d0);
	}

	if(i.left >= 0){
		relax_constrain(i.p, i.left, d0);
	}

	if(i.down >= 0){
		relax_constrain(i.p, i.down, d0);
	}
	}
}

technique10 main_tech{
	pass P0{
		SetComputeShader(CompileShader(cs_5_0, main()));
	}
}

technique10 enforcing_constraints_tech{
	pass P0{
		SetComputeShader(CompileShader(cs_5_0, enforcing_constraints()));
	}
}
