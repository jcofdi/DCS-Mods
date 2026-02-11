#ifndef MODEL_FLAG_PS_HLSL
#define MODEL_FLAG_PS_HLSL

#include "deferred/GBuffer.hlsl"

GBuffer flag_deferred_ps(VS_FLAG_OUTPUT input
#if USE_SV_SAMPLEINDEX
	,uint sv_sampleIndex: SV_SampleIndex
#endif
) {

	//float2 motion = calcMotionVector(input.projPos, input.prevFrameProjPos);
	float2 motion = 0;

	float3 emissive = 0;

	float3 normal = input.Normal;
	float4 aormsOut= 1;
	float4 color = float4(input.Color, 1);
	return BuildGBuffer(input.Position.xy,
#if USE_SV_SAMPLEINDEX
						sv_sampleIndex,
#endif
						color, normal, aormsOut.xyzw, emissive, motion);
}

GBuffer flag_forces_deferred_ps(GS_FLAG_FORCE_OUTPUT input
#if USE_SV_SAMPLEINDEX
	,uint sv_sampleIndex: SV_SampleIndex
#endif
) {

	//float2 motion = calcMotionVector(input.projPos, input.prevFrameProjPos);
	float2 motion = 0;

	float3 emissive = input.Color;

	float3 normal = normalize(input.Normal);
	float4 aormsOut= 1;
	float4 color = float4(input.Color, 1);
	return BuildGBuffer(input.Position.xy,
#if USE_SV_SAMPLEINDEX
						sv_sampleIndex,
#endif
						color, normal, aormsOut.xyzw, emissive, motion);
}

#endif
