#ifndef DAMAGE_DEFS_HLSL
#define DAMAGE_DEFS_HLSL

#ifdef DAMAGE_UV

#ifdef DAMAGE_RGBA_MASK						
	#ifdef DAMAGE_TANGENT_SIZE
		#define DAMAGE_VS_OUTPUT							\
			float4 DamageTangent : COLOR6;					\
			nointerpolation int DamageLevel : TEXCOORD8;
	#else
		#define DAMAGE_VS_OUTPUT							\
			nointerpolation int DamageLevel : TEXCOORD8;
	#endif
#else
	#ifdef DAMAGE_TANGENT_SIZE
		#define DAMAGE_VS_OUTPUT							\
			float4 DamageTangent : COLOR6;					\
			nointerpolation float2 DamageLevel : TEXCOORD8;
	#else
		#define DAMAGE_VS_OUTPUT							\
			nointerpolation float2 DamageLevel : TEXCOORD8;
	#endif
#endif


#else // no damage

#define DAMAGE_VS_OUTPUT

#endif
#endif
