#ifndef _0a2ab7b6e21f0bcc7f04b828ef3ca7bb_HLSL
#define _0a2ab7b6e21f0bcc7f04b828ef3ca7bb_HLSL

// GENERATED CODE BEGIN ID: flag_uniforms
cbuffer flag_uniforms {
	uint4 lightCount;	// x - omnis; y - spots, z - omnisDiffuse, w - spotsDiffuse
	float4 FlatShadowPlane;
	float4x4 prevFrameTransform;
	float4x4 worldPos;
	float2 FlatShadowProps;
	int2 flagSize;
}
// GENERATED CODE END ID: flag_uniforms

// GENERATED CODE BEGIN ID: flag_compute_uniforms
cbuffer flag_compute_uniforms {
	float3 windForce;
	float dt;
	int2 size;	// width, height
	float d0;
	float mass;
	float stifness;
	float damping;
	float modelTime;
	float turbulence;
}
// GENERATED CODE END ID: flag_compute_uniforms

#endif
