#ifndef MODEL_FORWARD_DEF_PS_HLSL
#define MODEL_FORWARD_DEF_PS_HLSL

#include "functions/shading.hlsl"

#ifdef ENABLE_DEBUG_UNIFORMS
#include "common/color_table.hlsl"
#include "common/debug_uniforms.hlsl"
#endif

#define USE_LIGHT_TILES_MATRIX 1

float4 emissivePS(VS_OUTPUT input, uniform int Flags)
{
	MaterialParams mp = calcMaterialParams(input, MP_DIFFUSE | MP_NORMAL);

	float4 finalColor = float4(GammaToLinearSpace(mp.diffuse.rgb) * selfIlluminationValue, mp.diffuse.a*mp.diffuse.a);
#ifdef BANO_MATERIAL
#if defined(COMPILER_ED_FXC)
	// At the moment of writing (release-1.8.2407), DXC was failing to compile:
	// calcBANOAttenuation(..., ..., ..., ..., finalColor.a)
	// with -fspv-debug=vulkan-with-source which is needed for shader debugging.
	// Error:
    // fatal error: generated SPIR-V is invalid:
	// NonSemantic.Shader.DebugInfo.100 DebugDeclare: expected operand Variable must be a result id of OpVariable or OpFunctionParameter
	{
		float temp = finalColor.a;
		calcBANOAttenuation(mp.diffuse.a*mp.diffuse.a, mp.normal, mp.toCamera, mp.camDistance, temp);
		finalColor.a = temp;
	}
#else
	calcBANOAttenuation(mp.diffuse.a*mp.diffuse.a, mp.normal, mp.toCamera, mp.camDistance, finalColor.a);
#endif
#endif
	finalColor.rgb *= 5*finalColor.a;


#if  BLEND_MODE == BM_ADDITIVE || BLEND_MODE == BM_TRANSPARENT
	if(!(Flags & F_IN_COCKPIT))
	{
		AtmosphereSample atm = calculateAtmosphereSample(mp.pos.xyz);
		finalColor.rgb *= atm.transmittance;
		finalColor.a *= atm.transmittance.x;
	}
#endif

	return finalColor;
}

float4 forwardDefaultPS(VS_OUTPUT input, uniform int Flags, uniform int shadingModel)
{
	if(shadingModel == SHADING_EMISSIVE)
		return emissivePS(input, Flags);

	MaterialParams mp = calcMaterialParams(input, MP_ALL);

	const float3 shadow = calculateShadow(float4(mp.pos, input.projPos.z/input.projPos.w), mp.normal, Flags);
	mp.diffuse.rgb = modifyAlbedo(mp.diffuse.rgb, albedoLevel, albedoContrast, mp.aorms.x);

	AtmosphereSample atm = calculateAtmosphereSample(mp.pos.xyz);

	float4 finalColor;

#ifdef ENABLE_DEBUG_UNIFORMS
	if(PaintNodes == 1){
		mp.emissive = CoarseGammaToLinearSpace(color_table[NodeId]);
	}
#endif

	if(shadingModel == SHADING_STANDARD){
#if USE_SEPARATE_AO
		float AO = mp.aorms.x;
#else
		float AO = 1;
#endif

		if(Flags & F_IN_COCKPIT){
			finalColor = float4(ShadeCockpit(input.Position.xy, (Flags & F_COCKPIT_GI), atm.sunColor, mp.diffuse.rgb, mp.normal, mp.aorms.y, mp.aorms.z, mp.emissive, shadow.x, AO, shadow.yz, mp.toCamera, mp.pos, float2(1,mp.aorms.w), true, mp.diffuse.a), mp.diffuse.a);
		}else{
		#if BLEND_MODE == BM_TRANSPARENT || BLEND_MODE == BM_SHADOWED_TRANSPARENT || BLEND_MODE == BM_ADDITIVE
			finalColor = float4(ShadeHDR(input.Position.xy, atm.sunColor, mp.diffuse.rgb, mp.normal, mp.aorms.y, mp.aorms.z, mp.emissive, shadow.x, AO, shadow.yz, mp.toCamera, mp.pos, float2(1, mp.aorms.w), LERP_ENV_MAP, false, float2(0, 0), LL_TRANSPARENT, false, true), mp.diffuse.a);
		#else

#if USE_LIGHT_TILES_MATRIX		
			float4 lt = mul(float4(mp.pos, 1), gLightTilesMatrix);
			uint2 lightTile = clamp(lt.xy / lt.w, 0, gLightTilesDims);
			uint LL = LL_SOLID + gLightTilesDims.x != gTargetDims.x;	// LL_SOLID + 1 = LL_TRANSPARENT, intermediate target case for hub in HelicopterRotor
#else
			uint2 lightTile = input.Position.xy;
			uint LL = LL_SOLID;
#endif
			finalColor = float4(ShadeHDR(lightTile, atm.sunColor, mp.diffuse.rgb, mp.normal, mp.aorms.y, mp.aorms.z, mp.emissive, shadow.x, AO, shadow.yz, mp.toCamera, mp.pos, float2(1, mp.aorms.w), LERP_ENV_MAP, false, float2(0, 0), LL, false, true), mp.diffuse.a);

		#endif
		}
	}else{
		finalColor = float4(1, 0, 0, 1);
	}

	if(!(Flags & F_IN_COCKPIT))
	{
	#if BLEND_MODE == BM_NONE || BLEND_MODE == BM_ALPHA_TEST
		finalColor.rgb = applyAtmosphereLinear(gCameraPos.xyz, mp.pos, input.projPos, finalColor.rgb);
	#else
		finalColor.rgb = finalColor.rgb * atm.transmittance + atm.inscatter;
	#endif
	}

	return finalColor;
}

#endif