#ifndef DAMAGE_RGBA_MASK_HLSL
#define DAMAGE_RGBA_MASK_HLSL

#include "common/samplers11.hlsl"
#include "functions/damage_constants.hlsl"

// damage
Texture2D Damage;
// damage alpha
Texture2D DamageMaskRGBA;
#ifdef DAMAGE_NORMAL_MAP_UV
// damage normal map
Texture2D DamageNormalMap;
#endif

// calculates normal using normal map
float3 calculateDamageNormal(const VS_OUTPUT input)
{
#ifdef DAMAGE_NORMAL_MAP_UV
#ifdef DAMAGE_TANGENT_SIZE
	float4 tex = DamageNormalMap.Sample(gAnisotropicWrapSampler, input.DAMAGE_NORMAL_MAP_UV.xy + diffuseShift);
	return calculateNormal(input.Normal, tex, input.DamageTangent);
#else
	float4 tex = DamageNormalMap.Sample(gAnisotropicWrapSampler, input.DAMAGE_NORMAL_MAP_UV.xy + diffuseShift);
	return calculateNormal(input.Normal, tex, input.Tangent);
#endif
#else
	return normalize(input.Normal);
#endif
}

float sampleMask(int damageLevel, in float2 uv, in float dist){
	float lod=dist*LOD_DIST_INV;
	float alpha = DamageMaskRGBA.SampleLevel(gBilinearWrapSampler, (uv + diffuseShift).xy, lod)[damageLevel];
	if(alpha > HOLE_LOW_THRESHOLD) discard;
	return alpha;
}

void testDamageAlphaCommon(int damageLevel, float2 uv, in float dist)
{
	if(damageLevel < 0){
		return;
	}
	
	sampleMask(damageLevel, uv, dist);
}

void testDamageAlpha(const VS_OUTPUT input, in float dist){
	testDamageAlphaCommon(input.DamageLevel, input.DAMAGE_UV, dist);
}

void testDamageAlpha(const VS_OUTPUT_RADAR input, in float dist){
	testDamageAlphaCommon(input.DamageLevel, input.DAMAGE_UV, dist);
}

#if defined(SHADOW_WITH_ALPHA_TEST)
void testDamageAlpha(const VS_OUTPUT_SHADOWS input, in float dist){
	testDamageAlphaCommon(input.DamageLevel, input.DAMAGE_UV, dist);
}
#endif

void addDamage(const VS_OUTPUT input, in float dist, inout float4 diffuseColor, inout float3 normal, inout float4 aorms)
{
	if(input.DamageLevel < 0.0){
		return;
	}

	float alpha = sampleMask(input.DamageLevel, input.DAMAGE_UV + diffuseShift, dist);
	float4 damage = Damage.Sample(gAnisotropicWrapSampler, input.DAMAGE_UV.xy + diffuseShift);

	normal = lerp(normal, calculateDamageNormal(input), alpha);

#ifndef GLASS_MATERIAL
	diffuseColor.rgb=lerp(diffuseColor.rgb,damage.rgb,alpha);
#else
	diffuseColor=lerp(diffuseColor,damage,alpha);
#endif

	float d = length(damage.rgb) / 1.7320508075688772;
	if(d < 0.5){
		d = 0;
	}
	aorms.y = lerp(aorms.y, alpha, alpha);
	aorms.z = lerp(aorms.z, 1.0, alpha * d);
}

void addDamageNew(const VS_OUTPUT input, in float dist, inout float4 diffuseColor, inout float3 normal, inout float4 aorms)
{
	if(input.DamageLevel < 0.0){
		return;
	}

	float alpha = sampleMask(input.DamageLevel, input.DAMAGE_UV + diffuseShift, dist);
	float4 damage = Damage.Sample(gAnisotropicWrapSampler, input.DAMAGE_UV.xy + diffuseShift);

	normal = lerp(normal, calculateDamageNormal(input), alpha);

#ifndef GLASS_MATERIAL
	diffuseColor.rgb=lerp(diffuseColor.rgb,damage.rgb,alpha);
#else
	diffuseColor=lerp(diffuseColor,damage,alpha);
#endif

	float d = length(damage.rgb) / 1.7320508075688772;
	if(d < 0.5){
		d = 0;
	}
	aorms.y = lerp(aorms.y, alpha, alpha);
	aorms.z = lerp(aorms.z, 1.0, alpha * d);
}

#endif
