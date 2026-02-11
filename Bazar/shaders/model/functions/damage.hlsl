#ifndef DAMAGE_HLSL
#define DAMAGE_HLSL

#include "functions/damage_defs.hlsl"

#ifdef DAMAGE_UV
	#ifdef DAMAGE_RGBA_MASK
		#include "functions/damage_rgba_mask.hlsl"

		int get_damage_argument(uint i){
			#ifdef ENABLE_DAMAGE_ARGUMENTS
				float dmg = saturate(sbPositions[posStructOffset+i].damage);
				if(dmg < 0.1){
					return -1;
				}
				if(dmg < 0.4){
					return 0;
				}
				if(dmg < 0.7){
					return 1;
				}
				if(dmg < 1.0){
					return 2;
				}
				return 3;
			#else
				return -1;
			#endif
			}
	#else
		#include "functions/damage_volume_mask.hlsl"

		float2 get_damage_argument(uint i){
			static const float z_coords[] = {
				0.25 - 0.5 / 4.0,
				0.5 - 0.5 / 4.0,
				0.75 - 0.5 / 4.0,
				1.0 - 0.5 / 4.0,
			};

			#ifdef ENABLE_DAMAGE_ARGUMENTS
				float dmg = saturate(sbPositions[posStructOffset+i].damage);
				float damageLevel = (dmg >= 0.1) ? z_coords[uint(dmg * 3.0 + 1.0e-7)] : -1;
				float damageSubLevel = saturate(dmg / 0.34);
				return float2(damageLevel, damageSubLevel);
			#else
				return float2((0.0 + 1.0e-7 - 0.1) * 3.333333333333333, 1);
			#endif
		}

	#endif
#else

void testDamageAlpha(const VS_OUTPUT input, in float dist)
{
}

void testDamageAlpha(const VS_OUTPUT_RADAR input, in float dist)
{
}

#if defined(SHADOW_WITH_ALPHA_TEST)
void testDamageAlpha(const VS_OUTPUT_SHADOWS input, in float dist)
{
}
#endif

void addDamage(const VS_OUTPUT input, in float dist, inout float4 diffuseColor, inout float3 normal, inout float4 aorms)
{
}

void addDamageNew(const VS_OUTPUT input, in float dist, inout float4 diffuseColor, inout float3 normal, inout float4 aorms)
{
}

#endif

#endif
