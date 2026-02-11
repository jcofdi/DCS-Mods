#ifndef LK_SHADOW_HLSL
#define LK_SHADOW_HLSL

#include "functions/structs.hlsl"
#include "functions/vt_utils.hlsl"

VS_OUTPUT_SHADOWS lk_shadow_vs(const VS_INPUT_SHADOWS input)
{
	VS_OUTPUT_SHADOWS o;

	float4x4 posMat = get_transform_matrix(input);

	float4 Pos = mul(float4(input.pos.xyz,1.0),posMat);
	o.Position = mul(Pos, gViewProj);
	o.Pos = Pos;	

#if defined(SHADOW_WITH_ALPHA_TEST)
	#include "functions/set_texcoords.hlsl"

	#if defined(DAMAGE_UV)
		o.DamageLevel = get_damage_argument((int)input.pos.w);
	#endif
#endif

	return o;
}

void lk_shadow_ps(const VS_OUTPUT_SHADOWS input)
{
#if defined(SHADOW_WITH_ALPHA_TEST)
	clipByDiffuseAlpha(GET_DIFFUSE_UV(input), 0.4);
	testDamageAlpha(input, distance(input.Pos.xyz, gCameraPos.xyz) * gNearFarFovZoom.w);
#endif
}

void lk_shadow_transparent_ps(const VS_OUTPUT_SHADOWS input)
{
#if defined(GLASS_MATERIAL) || !defined(SHADOW_WITH_ALPHA_TEST)
	discard;
#else
	#if defined(DIFFUSE_UV) && (BLEND_MODE == BM_ALPHA_TEST || BLEND_MODE == BM_TRANSPARENT || (BLEND_MODE == BM_SHADOWED_TRANSPARENT))
		float4 diff = Diffuse.Sample(gAnisotropicWrapSampler, input.DIFFUSE_UV.xy + diffuseShift);
		if(diff.a < 0.25)
			discard;
	#endif

	testDamageAlpha(input, distance(input.Pos.xyz, gCameraPos.xyz) * gNearFarFovZoom.w);

#endif
}


#endif
