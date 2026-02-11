#ifndef MODEL_VERTEX_SHADER_HLSL
#define MODEL_VERTEX_SHADER_HLSL

#include "functions/structs.hlsl"
#include "functions/vt_utils.hlsl"
#include "functions/damage.hlsl"
#include "common/context.hlsl"

VS_OUTPUT model_vs(VS_INPUT input)
{
	VS_OUTPUT o;

	float4x4 posMat = get_transform_matrix(input);
	float4x4 prevPosMat = get_transform_matrix_prev(input);

	o.Pos = mul(float4(input.pos.xyz,1.0),posMat);

	o.projPos = o.Position = mul(o.Pos, gViewProj);
    o.prevFrameProjPos = mul(mul(o.Pos, prevPosMat), gPrevFrameViewProj); //prevFrameTransform

	float3x3 normMat = (float3x3)posMat;

#ifdef NORMAL_SIZE
	o.Normal = mul(input.normal,normMat);
#else
	o.Normal = mul(float3(0.0,1.0,0.0),normMat);
#endif

#if TANGENT_SIZE == 4
	o.Tangent = float4(mul(input.tangent.xyz, normMat), input.tangent.w);
#elif TANGENT_SIZE == 3
	o.Tangent = float4(mul(input.tangent.xyz, normMat), 1);
#endif

#if DAMAGE_TANGENT_SIZE == 4
	o.DamageTangent = float4(mul(input.damage_tangent.xyz, normMat), input.damage_tangent.w);
#elif DAMAGE_TANGENT_SIZE == 3
	o.DamageTangent = float4(mul(input.damage_tangent.xyz, normMat), 1);
#endif

	#include "functions/set_texcoords.hlsl"

#if defined(DAMAGE_UV)
	o.DamageLevel = get_damage_argument((int)input.pos.w);
#endif

#ifdef AIRCRAFT_REGISTRATION
	o.TailNumber = get_tail_number((int)input.pos.w, (int)input.bonesWeights);
#endif

	return o;
}

#endif
