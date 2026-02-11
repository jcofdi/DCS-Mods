#ifndef DAMAGE_VOLUME_MASK_HLSL
#define DAMAGE_VOLUME_MASK_HLSL

#include "common/samplers11.hlsl"
#include "functions/damage_constants.hlsl"

// damage
Texture2D Damage;
// damage alpha
Texture3D DamageMask;
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

void testDamageAlphaCommon(float2 damageLevel, float2 uv, in float dist)
{
	if(damageLevel.x < 0.0){
		return;
	}
	float lod=dist*LOD_DIST_INV;
	float alpha = DamageMask.SampleLevel(gBilinearWrapSampler, float3((uv + diffuseShift).xy, damageLevel.x), lod).r;

	if(alpha.r > HOLE_LOW_THRESHOLD) discard;
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
	if(input.DamageLevel.x < 0.0){
		return;
	}

	float lod=dist*LOD_DIST_INV;
	float4 alpha = DamageMask.SampleLevel(gBilinearWrapSampler, float3(input.DAMAGE_UV.xy + diffuseShift,input.DamageLevel.x), lod);
	// alpha.g - roughness
	// alpha.b - metallic
	// alpha.a - sub mask

	//if(input.DamageLevel.y < alpha.a){
		// Some damage masks have alpha channel repeating red channel. It's bug as for now alpha channel is sub mask.
		// Uncomment when masks are fixed.
		//return;
	//}

	if(alpha.r > HOLE_LOW_THRESHOLD) discard;

	float4 damage = Damage.Sample(gAnisotropicWrapSampler, input.DAMAGE_UV.xy + diffuseShift);

	normal = lerp(normal, calculateDamageNormal(input), alpha.r);

#ifndef GLASS_MATERIAL
	diffuseColor.rgb=lerp(diffuseColor.rgb,damage.rgb,alpha.r);
#else
	diffuseColor=lerp(diffuseColor,damage,alpha.r);
#endif

	const float d = length(damage.rgb) / 1.7320508075688772;
	aorms.y = lerp(aorms.y, alpha.g, alpha.g);
	aorms.z = lerp(aorms.z, alpha.b, alpha.b * d);
}

void addDamageNew(const VS_OUTPUT input, in float dist, inout float4 diffuseColor, inout float3 normal, inout float4 aorms)
{
	if(input.DamageLevel.x < 0.0){
		return;
	}

	float lod=dist*LOD_DIST_INV;
	float4 alpha = DamageMask.SampleLevel(gBilinearWrapSampler, float3(input.DAMAGE_UV.xy + diffuseShift,input.DamageLevel.x), lod);

	// alpha.g - specular
	// alpha.b - reflection
	// alpha.a - sub mask

	if(input.DamageLevel.y < alpha.a){
		// Some damage masks have alpha channel repeating red channel. It's bug as for now alpha channel is sub mask.
		// Uncomment when masks are fixed.
		//return;
	}

	if(alpha.r > HOLE_LOW_THRESHOLD) discard;
	alpha.gb = 1.0 - alpha.gb;

	float4 damage = Damage.Sample(gAnisotropicWrapSampler, input.DAMAGE_UV.xy + diffuseShift);

	normal = lerp(normal, calculateDamageNormal(input), alpha.r);

#ifndef GLASS_MATERIAL
	diffuseColor.rgb=lerp(diffuseColor.rgb,damage.rgb,alpha.r);
#else
	diffuseColor=lerp(diffuseColor,damage,alpha.r);
#endif
	aorms.yz *= alpha.gb;
}

#endif
