#include "common/states11.hlsl"
#include "common/context.hlsl"

#include "animator_common.hlsl"
#include "quaternion.hlsl"

struct NodePath
{
    uint path[MAX_NODE_PATH];
};

#include "animation_compute_core.hlsl"

StructuredBuffer    <uint>          instance_indices;

StructuredBuffer    <InstanceData>  	per_instance_data;
StructuredBuffer    <ShaderAnimation>  	per_instance_animations;

RWStructuredBuffer  <float4x4>      model_transforms_rw;
StructuredBuffer    <float4x4>      local_transforms;
RWStructuredBuffer  <float4x4>      local_transforms_rw;
StructuredBuffer    <float4x4>      pose;

StructuredBuffer    <AnimationKey>  animations;
StructuredBuffer    <float>         masks;
StructuredBuffer    <ClipInfo>      clips_info;
StructuredBuffer    <NodePath>      node_paths;

StructuredBuffer    <float4>        blendspace; // -1: {anim_id, num_points, 0, 0}
StructuredBuffer    <float2>        blendspace_params;

[numthreads(NUM_NODES, 1, 1)]
void cs_animation(uint3 instance: SV_GroupID, uint3 group_thread_id:SV_GroupThreadID)
{ 
    uint instance_id            = instance_indices[instance.x];
    uint instance_offset        = instance_id*NUM_NODES;
    InstanceData data           = per_instance_data[instance_id];
    uint channel_index          = group_thread_id.x;
    if (check_flag(data._flags, DIRECT_POSE_CONTROL))
    {
        local_transforms_rw[instance_offset + channel_index] = pose[data._pose_offset + channel_index];
        return;
    }
    //float t                     = model_time;//(model_time == -1) ? gModelTime : model_time;
    float t                     = model_time;

    bool remove_root = check_flag(data._flags, REMOVE_ROOT_MATRIX);
	if (data._compute_type == 0)
	{
		local_transforms_rw[instance_offset + channel_index] = get_animation_matrix(
			t, data, channel_index, per_instance_animations, clips_info, animations, masks, blendspace, NUM_NODES, remove_root);
	}
	else
	{
		local_transforms_rw[instance_offset + channel_index] = get_animation_matrix2(
			t, data, channel_index, per_instance_animations, clips_info, animations, masks, blendspace, NUM_NODES, remove_root);	
	}
}

groupshared float4x4 shared_local_transforms[NUM_NODES];
[numthreads(NUM_NODES, 1, 1)]
void cs_animation_model_transforms(uint3 instance: SV_GroupID, uint3 group_thread_id:SV_GroupThreadID)
{
    uint instance_id = instance_indices[instance.x];
    uint instance_offset = instance_id*NUM_NODES;
    uint channel_index = group_thread_id.x;
    
    shared_local_transforms[channel_index] = local_transforms[instance_offset + channel_index];
    GroupMemoryBarrierWithGroupSync();
    
    NodePath node_path = node_paths[channel_index];
    float4x4 m = {1, 0, 0, 0,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1};
    for (int i = 0; i < MAX_NODE_PATH; ++i)
    {
        uint node_index = node_path.path[i];
        float4x4 am = shared_local_transforms[node_index]; 
        m = mul(m, am);
    }
    model_transforms_rw[instance_offset + channel_index] = m;
}

technique10 AnimationCompute
{
    pass P0
    {
        SetVertexShader(NULL);
        SetComputeShader(CompileShader(cs_5_0, cs_animation()));
    }
    pass P1
    {
        SetVertexShader(NULL);
        SetComputeShader(CompileShader(cs_5_0, cs_animation_model_transforms()));
    }
}
