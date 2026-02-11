float4 effectParams2;//emitter time, phase, wind.xy
float3 smokeColor;
float3 effectParams;
#define EMITTER_TIME_NORM		effectParams2.x
#define EFFECT_SCALE			effectParams.y
#define PARTICLE_SCALE			effectParams.z

#ifdef PUFF_SOFT_PARTICLES
	#define SOFT_PARTICLES		effectParams.x
#endif
#include "ParticleSystem2/common/clusterCommon.hlsl"


#define CLUSTER_CUSTOM_VS_NAME vsGroundPuff

VS_OUTPUT CLUSTER_CUSTOM_VS_NAME(in uint vertId: SV_VertexId)
{
	VS_OUTPUT o;
	o.vertId = sbSortedIndices[vertId];
	const CLUSTER_STRUCT i = sbParticles[o.vertId];
	o.posRadius = i.posRadius * EFFECT_SCALE;
	o.posRadius.xyz += worldOffset;
	o.sizeLifeOpacityRnd = i.sizeLifeOpacityRnd;
	o.sizeLifeOpacityRnd.x *= EFFECT_SCALE * PARTICLE_SCALE;
	o.clusterLight.xyz = i.clusterLight;
#ifdef CLUSTER_WORLD_NORMAL
	o.worldNormal = i.reserved.xyz;
#endif
	return o;
}

// #define CLUSTER_COLOR dbg.xyz
#define CLUSTER_COLOR			smokeColor.xyz
#define CLUSTER_DETAIL_SPEED	0.02
#define CLUSTER_DETAIL_TILE		0.2
#define ANIMATION_SPEED			20
#include "ParticleSystem2/common/clusterShading.hlsl"
