//#include "common/cpp.hlsl"
#include "animator_common.hlsl"
#include "quaternion.hlsl"

#define MAX_BLENDSPACE_POINTS_NUM 50

struct AnimationKey
{
    float4 rotation;
    float4 translation;
//    float4x4 m;
};

struct ClipInfo
{
    int _clip_offset_in_keys;
    int _num_channels;
    int _num_keys_per_channel;
    float _frequency;
};

uint root_transform_index = 1;

AnimationKey sample_animation(int anim_id, int channel_index, float phase, StructuredBuffer<ClipInfo> clips_info, StructuredBuffer<AnimationKey> animations)
{
    ClipInfo clip_info      = clips_info[anim_id];
   
    int start_key_ind       = clip_info._clip_offset_in_keys + clip_info._num_keys_per_channel*channel_index;
    float key_f             = phase*(clip_info._num_keys_per_channel-1);
    int key_ind_0           = key_f;
    int key_ind_1           = key_ind_0 + 1;
    /*
    if (key_ind_0 == clip_info._num_keys_per_channel)
    {
        return animations[start_key_ind + key_ind_0];
    }
    */
    //int key_ind_1           = clamp(key_ind_0 + 1, key_ind_0, clip_info._num_keys_per_channel - 1);
    //int key_ind_1           = key_ind_0 + 1; //clamp(key_ind_0 + 1, key_ind_0, clip_info._num_keys_per_channel - 1);
    //key_ind_1  = (key_ind_1 >= clip_info._num_keys_per_channel) ? 1 : key_ind_1; 
    
    float inter_key_phase   = key_f - key_ind_0;
    AnimationKey key_0      = animations[start_key_ind + key_ind_0];
    AnimationKey key_1      = animations[start_key_ind + key_ind_1];
    float4 rot              = interpolate_quat ( key_0.rotation, key_1.rotation, inter_key_phase);
    float4 trans            = lerp ( key_0.translation, key_1.translation, inter_key_phase);
    AnimationKey res = {rot, trans};
    return res;
}

float get_animation_duration(ClipInfo clip_info)
{
    float duration = float((clip_info._num_keys_per_channel - 1))/clip_info._frequency;
    return duration;
}

void get_weights(float2 p, int buffer_shift, int num_points, StructuredBuffer<float4> blendspace_buffer, out float weights[MAX_BLENDSPACE_POINTS_NUM])
{
    for (int i = 0; i < num_points; ++i)
    {
        float h[MAX_BLENDSPACE_POINTS_NUM];
        float2 p_i = blendspace_buffer[buffer_shift + i].xy;
        int counter = 0;
        for (int j = 0; j < num_points; ++j)
        {
            if (i != j)
            {
				float2 p_j = blendspace_buffer[buffer_shift + j].xy;
                float num = (p.x - p_i.x)*(p_j.x - p_i.x) + (p.y - p_i.y)*(p_j.y - p_i.y);//dot(p - p_i, p_j - p_i);
                float denum = (p_j.x - p_i.x)*(p_j.x - p_i.x) + (p_j.y - p_i.y)*(p_j.y - p_i.y);//dot(p_j - p_i, p_j - p_i);
                float r = clamp(1 - num / denum, 0, 1);
                h[counter] = r;
                ++counter;
            }
        }
        float w_min = h[0];
        for (int k = 1; k < num_points-1; ++k)
            w_min = min(w_min, h[k]);
        weights[i] = w_min;
    }
    float w_sum = 0;
    for (int i = 0; i < num_points; ++i)
        w_sum += weights[i];
    for (int i = 0; i < num_points; ++i)
    {
        weights[i] = weights[i] / w_sum;
    }
}

float4 fast_lerp(float4 op1, float4 op2, float weight)
{
	// To ensure the 'shortest route', we make sure the dot product between the both rotations is positive.
	float DotResult = dot(op1, op2);
	float Bias = (DotResult > 0) ? 1.0f : -1.0f;
	return (op2 * weight) + (op1 * (Bias * (1.0f - weight)));
}

float check_mask(
    ShaderAnimation                 shader_anim, 
    uint                            channel_index, 
    StructuredBuffer<float> 	    masks,
    int num_nodes)
{
    //int override_animation_id = shader_anim._override_animation.x;
    int mask_id = shader_anim._override_animation.y;
    //int index = NUM_NODES * mask_id + channel_index;
    int index = num_nodes * mask_id + channel_index;
    float mask_value = masks[index];
    return mask_value;
}

AnimationKey get_animation(float t, uint channel_index, 
	InstanceData 					instance_data,
	ShaderAnimation 				shader_anim, 
    StructuredBuffer<ClipInfo> 		clips_info, 
    StructuredBuffer<AnimationKey> 	animations,
    StructuredBuffer<float> 		masks, 
    StructuredBuffer<float4> 		blendspace_buffer,
    int num_nodes,
	out bool masked_channel)
{
	masked_channel = false;
    AnimationKey res;
	int num_points = blendspace_buffer[shader_anim._buffer_shift - 1].y;
    if (num_points == 1)
    {
        //float anim_id = shader_anim._animation_id;
        float anim_id = blendspace_buffer[shader_anim._buffer_shift + 0].z;
        float duration = get_animation_duration(clips_info[anim_id]);
        float dt = t - shader_anim._start_time_duration_end.x;
        float phase = (shader_anim._loop[0] > 0) ? fmod(dt, duration)/duration : saturate(dt/duration);
        if (shader_anim._arg_number >= 0)
			phase = instance_data._args[shader_anim._arg_number];        
        if (shader_anim._loop[0] > 0)
        {
            float loop_start = shader_anim._loop.y;
            float loop_end = shader_anim._loop.z;
            if ( (loop_start >= 0) && (loop_end >= 0) )
            {
				float loop_start_time = shader_anim._start_time_duration_end.x + loop_start;
                float loop_length = loop_end - loop_start;
                if (t >= loop_start_time)
                {
                    float t_loop = fmod(t - loop_start_time, loop_length);
                    float t      = t_loop + loop_start;
                    phase = fmod(t, duration)/duration;
                }
            }
        }
        res = sample_animation(anim_id, channel_index, phase, clips_info, animations);    
    }
    else
    {
        float weights[MAX_BLENDSPACE_POINTS_NUM];
        //get_weights(shader_anim._blend_ratio, shader_anim._buffer_shift, shader_anim._num_points, blendspace_buffer, weights);
        get_weights(shader_anim._blend_ratio, shader_anim._buffer_shift, num_points, blendspace_buffer, weights);
        float duration = blendspace_buffer[shader_anim._buffer_shift + 0].w*weights[0];
        for (int i = 1; i < num_points; ++i)
        {
            duration += blendspace_buffer[shader_anim._buffer_shift + i].w*weights[i];
        }

        float dt = t - shader_anim._start_time_duration_end.x;
        float phase = (shader_anim._loop[0] > 0) ? fmod(dt, duration)/duration : saturate(dt/duration);
        
        int anim_id = blendspace_buffer[shader_anim._buffer_shift + 0].z;
        AnimationKey key = sample_animation(anim_id, channel_index, phase, clips_info, animations);
        float4 rot = key.rotation*weights[0];
        float4 trans = key.translation*weights[0];
        for (int i = 1; i < num_points; ++i)
        {
            float w = weights[i];
            if (w > 1e-5)
            {
                anim_id = blendspace_buffer[shader_anim._buffer_shift + i].z;
                key = sample_animation(anim_id, channel_index, phase, clips_info, animations);
                float4 q = key.rotation;
                //rot = fast_lerp(rot, key.rotation, w);                
                float _dot = dot(key.rotation, rot);
                if (_dot < 0)
                    q = -q;                    
                rot += q* w;                
                //trans = lerp(trans, key.translation, w);
                trans += key.translation*w;
            }
        }
        res.translation = trans;    
        res.rotation = normalize(rot);
    }

    int override_animation_id = shader_anim._override_animation.x;
    int mask_id = shader_anim._override_animation.y;    
    
    if (override_animation_id >= 0)
    {   // старая схема: берём простую анимацию по id и сэмплируем её по маске, замещая предыдущее значение
        float mask = check_mask(shader_anim, channel_index, masks, num_nodes);
        if (mask > 0)
        {// оверайд проигрывается один раз с заданного времени
            ClipInfo clip_info = clips_info[override_animation_id];
            float duration = get_animation_duration(clip_info);
            float start_time_override = shader_anim._override_animation.z;//время начала проигрывания
            float current_time_shift = t - start_time_override;// текущая продолжительность проирывания
            if (start_time_override < 0)//время старта не задано - проигрываем цыклически
            {
                float start_time = shader_anim._start_time_duration_end.x;
                float phase = fmod((t - start_time), duration) / duration;
                res = sample_animation(override_animation_id, channel_index, phase, clips_info, animations);
            }
            else if (duration >= current_time_shift)// еще можно проигрывать - не превышает длинны анимации
            {
                float phase = current_time_shift / duration;
                //float phase = (shader_anim._loop[0] > 0) ? fmod((t - start_time), duration) / duration:
                //saturate((t - start_time) / duration);
                res = sample_animation(override_animation_id, channel_index, phase, clips_info, animations);
            }
            else
            {
                float phase = current_time_shift / duration;
            }
        }
    }
	else if (mask_id >= 0)
	{   // новая схема: проверяем маску и возвращаем результат проверки, чтобы смешаться с другой анимацией в стеке
        masked_channel = check_mask(shader_anim, channel_index, masks, num_nodes);
	}
    return res;
}


AnimationKey get_gesture(uint channel_index,
	InstanceData instance_data,
	ShaderAnimation shader_anim,
    StructuredBuffer<ClipInfo> clips_info,
    StructuredBuffer<AnimationKey> animations,
    StructuredBuffer<float> masks,
    StructuredBuffer<float4> blendspace_buffer,
    int num_nodes
    )
{
    AnimationKey res;
	int num_points = blendspace_buffer[shader_anim._buffer_shift - 1].y;
    if (num_points == 1)
    {
        float phase = shader_anim._blend_ratio[0];
        if (shader_anim._arg_number >= 0)
            phase = instance_data._args[shader_anim._arg_number];
		float anim_id = blendspace_buffer[shader_anim._buffer_shift + 0].z;
        //res = sample_animation(shader_anim._animation_id, channel_index, phase, clips_info, animations);
        res = sample_animation(anim_id, channel_index, phase, clips_info, animations);
    }
    else
    {
        float weights[MAX_BLENDSPACE_POINTS_NUM];
        get_weights(shader_anim._blend_ratio, shader_anim._buffer_shift, num_points, blendspace_buffer, weights);
        
        int anim_id = blendspace_buffer[shader_anim._buffer_shift + 0].z;
        float phase = blendspace_buffer[shader_anim._buffer_shift + 0].x == 0 &&
                      blendspace_buffer[shader_anim._buffer_shift + 0].y == 0 ? 0 : 1;
        AnimationKey key = sample_animation(anim_id, channel_index, phase, clips_info, animations);
        float4 rot = key.rotation * weights[0];
        float4 trans = key.translation * weights[0];
        for (int i2 = 1; i2 < num_points; ++i2)
        {
            float w = weights[i2];
            if (w > 1e-5)
            {
                anim_id = blendspace_buffer[shader_anim._buffer_shift + i2].z;
                float phase = blendspace_buffer[shader_anim._buffer_shift + i2].x == 0 &&
                              blendspace_buffer[shader_anim._buffer_shift + i2].y == 0 ? 0 : 1;
                key = sample_animation(anim_id, channel_index, phase, clips_info, animations);
                float4 q = key.rotation;
                //rot = fast_lerp(rot, key.rotation, w);                
                float _dot = dot(key.rotation, rot);
                if (_dot < 0)
                    q = -q;
                rot += q * w;
                //trans = lerp(trans, key.translation, w);
                trans += key.translation * w;
            }
        }
        res.translation = trans;
        res.rotation = normalize(rot);
    }
    return res;
}


float4x4 get_animation_matrix(
    float t, 
    InstanceData data, 
    uint channel_index, 
    StructuredBuffer<ShaderAnimation>  per_instance_animations,
    StructuredBuffer<ClipInfo> clips_info,
    StructuredBuffer<AnimationKey> animations,
    StructuredBuffer<float> masks,
    StructuredBuffer<float4> blendspace_buffer,
    int num_nodes,
    bool remove_root)
{
    bool unused = false; // not used here
    AnimationKey key;
    if (data._timeline_params.y > 0)
    {
        t = data._timeline_params.x + fmod(t - data._timeline_params.x, data._timeline_params.y);
    }

    {
        bool b_first_base = false;
        int i_default = 0;
        bool b_use_default = true;
        bool b_gesture = false;
        bool b_additive = false;
        AnimationKey key_gesture;
        AnimationKey key_gesture_neutral;
        AnimationKey key_additive;
        float mask_gesture = 0;
        float mask_additive = 1;
        int neutral_anim_id = -1;
        
        for (int i = 0; i < data._stack_size; ++i)
        {
            int anim_index = data._animations_stack[i];
            if (anim_index < 0)
                continue;
            
            ShaderAnimation shader_anim = per_instance_animations[anim_index];
            float transition_start_time = shader_anim._transition_params.x;
			int num_points = blendspace_buffer[shader_anim._buffer_shift - 1].y;           
            switch (shader_anim._processing_type)
            {            
                case ANIM_TYPE_GESTURE:
                    {
                        if (t > transition_start_time)
                        {
                            mask_gesture = check_mask(shader_anim, channel_index, masks, num_nodes);
                            b_gesture = mask_gesture;
                            if (b_gesture)
                            {
                                key_gesture = get_gesture(channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes);
                            
                                for (int i = 0; i < num_points; ++i)
                                {
                                    if (blendspace_buffer[shader_anim._buffer_shift + i].x == 0
                                    && blendspace_buffer[shader_anim._buffer_shift + i].y == 0)
                                    {
                                        neutral_anim_id = blendspace_buffer[shader_anim._buffer_shift + i].z;
                                        key_gesture_neutral = sample_animation(neutral_anim_id, channel_index, 0, clips_info, animations);
                                        break;
                                    }
                            
                                }
                            }
                        }
                        break;
                    }
                case ANIM_TYPE_ADDITIVE:
                    {
                    
                        mask_additive = check_mask(shader_anim, channel_index, masks, num_nodes);
                        b_additive = mask_additive;
                        if (b_additive)
                        {
                        
                            //int base_anim_id = shader_anim._animation_id;
                            int base_anim_id = blendspace_buffer[shader_anim._buffer_shift + 0].z;
                            key_additive = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
                            AnimationKey key_additive_neutral = sample_animation(base_anim_id, channel_index, 0, clips_info, animations);

                            key_additive.rotation = divide_quat(key_additive.rotation, key_additive_neutral.rotation);
                            key_additive.translation = key_additive.translation - key_additive_neutral.translation;

                        }
                    
                        break;
                    }
                default:
                    {
                        if (b_first_base == false)
                        {
                            b_first_base = true;
                            key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
                            break;
                        }
                    
            
                        
                        float transition_end_time = shader_anim._transition_params.x + shader_anim._transition_params.y;
                        if (t > transition_start_time)
                        {
                            if (t >= transition_end_time)
                            {
                                //if (i_default < i)
                                //    i_default = i;
                                key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
                            }
                            else
                            {
                                b_use_default = false;
                            
                                float transition_duration = shader_anim._transition_params.y;
                                float transition_time = transition_start_time;
                                float blend_factor = saturate((t - transition_time) / transition_duration);
                                AnimationKey key1 = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
                                key.rotation = interpolate_quat(key.rotation, key1.rotation, blend_factor);
                                key.translation = lerp(key.translation, key1.translation, blend_factor);
                                if (channel_index == root_transform_index)
                                {
                                    if (data._timeline_params.y > 0) // do not blend root in timeline
                                    {
                                        key.rotation = key1.rotation;
                                        key.translation = key1.translation;
                                    }
                                    else
                                    {
                                        if (shader_anim._transition_params.z == 0) // do not blend root
                                        {
                                            key.rotation = key1.rotation;
                                            key.translation = key1.translation;
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
            }
        }
    
        //if (b_use_default)
        //{
        //    int anim_index = data._animations_stack[i_default];
        //    ShaderAnimation shader_anim = per_instance_animations[anim_index];
        //    key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
        //}
                    
        
        if (b_gesture)
        {
               
            if (neutral_anim_id >= 0)
            {
                //additive compensator
                float4 d_rotation = divide_quat(key.rotation, key_gesture_neutral.rotation);
                float4 correct_gesture_rotation = multiple_quat(d_rotation, key_gesture.rotation);
                float4 correct_gesture_translation = key_gesture.translation + key.translation - key_gesture_neutral.translation;
                //additive compensator
                key.rotation = interpolate_quat(key.rotation, correct_gesture_rotation, mask_gesture);
                key.translation = lerp(key.translation, correct_gesture_translation, mask_gesture);
            }
            else
            {
                key.rotation = interpolate_quat(key.rotation, key_gesture.rotation, mask_gesture);
                key.translation = lerp(key.translation, key_gesture.translation, mask_gesture);
            }
        }
        
        
        if (b_additive)
        {
            key.rotation = multiple_quat(key_additive.rotation, key.rotation);
            key.translation += key_additive.translation;
        }

    }

//#ifdef REMOVE_ROOT_MOTION    
    if (remove_root && ( channel_index == root_transform_index))
    {
		key.rotation = float4(0, 0, 0, 1);
		key.translation = float4(0,0,0, 1);
    }
//#endif    
   
    float4x4 m       = make_matrix       ( key.rotation, key.translation);
    return m;
}


float4x4 get_animation_matrix_old(
    float t,
    InstanceData data,
    uint channel_index,
    StructuredBuffer<ShaderAnimation> per_instance_animations,
    StructuredBuffer<ClipInfo> clips_info,
    StructuredBuffer<AnimationKey> animations,
    StructuredBuffer<float> masks,
    StructuredBuffer<float4> blendspace_buffer,
    int num_nodes,
    bool remove_root)
{
    bool unused = false; // not used here
    AnimationKey key;
    if (data._timeline_params.y > 0)
    {
        t = data._timeline_params.x + fmod(t - data._timeline_params.x, data._timeline_params.y);
    }
    int stack_size = data._stack_size;
    if (stack_size == 1)
    {
        int anim_index = data._animations_stack[0];
        ShaderAnimation shader_anim = per_instance_animations[anim_index];
        key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
    }
    else
    {
        int ind0 = data._animations_stack[0];
        ShaderAnimation bs0 = per_instance_animations[ind0];
        key = get_animation(t, channel_index, data, bs0, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
        for (int i = 1; i < data._stack_size; ++i)
        {
            int anim_index = data._animations_stack[i];
            ShaderAnimation shader_anim = per_instance_animations[anim_index];
            float transition_start_time = shader_anim._transition_params.x;
            float transition_end_time 	= shader_anim._transition_params.x + shader_anim._transition_params.y;
            if (t > transition_start_time)
            {
                if (t >= transition_end_time)
                {
                    key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
                }
                else
                {
					float transition_duration   = shader_anim._transition_params.y;
					float transition_time       = transition_start_time;
					float blend_factor          = saturate((t - transition_time)/transition_duration);
					AnimationKey key1           = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
					key.rotation           = interpolate_quat  ( key.rotation,        key1.rotation,       blend_factor);
					key.translation        = lerp              ( key.translation,     key1.translation,    blend_factor);
					if ( channel_index == root_transform_index)					
					{
						if (data._timeline_params.y > 0) // do not blend root in timeline
						{
							key.rotation           = key1.rotation;
							key.translation        = key1.translation;
						}
						else 
						{
							if (shader_anim._transition_params.z == 0) // do not blend root
							{
								key.rotation           = key1.rotation;
								key.translation        = key1.translation;
							}
						}
					}
                }
            }
        }
    }

//#ifdef REMOVE_ROOT_MOTION    
    if (remove_root && ( channel_index == root_transform_index))
    {
		key.rotation = float4(0, 0, 0, 1);
		key.translation = float4(0,0,0, 1);
    }
//#endif    
   
    float4x4 m       = make_matrix       ( key.rotation, key.translation);
    return m;
}

/// Blends 'masked_key' on top of 'key' depending on 'masked_channel'
/// Blends 'masked_key' on top of 'key' depending on 'masked_channel'
AnimationKey blend_masked_key(float t, int channel_index, AnimationKey key, AnimationKey masked_key, float2 transition_params, bool masked_channel)
{
    if (masked_channel) 
        return key; // 'masked_key' really masked and not uesd
    
    float transition_start_time = transition_params.x;
    if (t <= transition_start_time) 
        return key; // transition has not started yet, using 'key'        
    
	float transition_end_time 	= transition_params.x + transition_params.y;
	if (t >= transition_end_time)
        return masked_key; // transition has already ended using 'masked_key'
    
    // we are inside transition
    float transition_duration = transition_params.y;
	float blend_factor          = saturate((t - transition_start_time)/transition_duration);    
	if ( channel_index == root_transform_index)
	{// not blending root
        return masked_key;
    }
    else
    {// blending
        AnimationKey res;
        res.rotation = interpolate_quat(key.rotation, masked_key.rotation, blend_factor);
        res.translation = lerp(key.translation, masked_key.translation, blend_factor);
        return res;
    }    
}

float4x4 get_animation_matrix2(
    float t, 
    InstanceData data, 
    uint channel_index, 
    StructuredBuffer<ShaderAnimation>  per_instance_animations,
    StructuredBuffer<ClipInfo> clips_info,
    StructuredBuffer<AnimationKey> animations,
    StructuredBuffer<float> masks,
    StructuredBuffer<float4> blendspace_buffer,
    int num_nodes, 
    bool remove_root)
{
    AnimationKey key;
	bool masked_channel = false;
	bool unused = false;
	int stack_size = data._stack_size;
	if (stack_size == 1)
	{
		int anim_index = data._animations_stack[0];
		ShaderAnimation shader_anim = per_instance_animations[anim_index];
		key = get_animation(t, channel_index, data, shader_anim, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
	}
	else if (stack_size == 2)
	{
		ShaderAnimation bs0 = per_instance_animations[data._animations_stack[0]];
		ShaderAnimation bs1 = per_instance_animations[data._animations_stack[1]];
        AnimationKey key0 = get_animation(t, channel_index, data, bs0, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
		AnimationKey key1 = get_animation(t, channel_index, data, bs1, clips_info, animations, masks, blendspace_buffer, num_nodes, masked_channel);
		key = blend_masked_key(t, channel_index, key0, key1, bs1._transition_params, masked_channel);
	}
	else if (stack_size > 2)
	{
		ShaderAnimation bs0 = per_instance_animations[data._animations_stack[0]];
		ShaderAnimation bs1 = per_instance_animations[data._animations_stack[1]];
		ShaderAnimation bs2 = per_instance_animations[data._animations_stack[2]];
        AnimationKey key0 = get_animation(t, channel_index, data, bs0, clips_info, animations, masks, blendspace_buffer, num_nodes, unused);
        AnimationKey key1 = get_animation(t, channel_index, data, bs1, clips_info, animations, masks, blendspace_buffer, num_nodes, masked_channel);
        AnimationKey key01 = blend_masked_key(t, channel_index, key0, key1, bs1._transition_params, masked_channel);
		AnimationKey key2 = get_animation(t, channel_index, data, bs2, clips_info, animations, masks, blendspace_buffer, num_nodes, masked_channel);
		AnimationKey key02 = blend_masked_key(t, channel_index, key0, key2, bs2._transition_params, masked_channel);
		key = blend_masked_key(t, channel_index, key01, key02, bs2._transition_params, masked_channel);		
	}
 
    if (remove_root && ( channel_index == root_transform_index))
    {
		key.rotation = float4(0, 0, 0, 1);
		key.translation = float4(0,0,0, 1);
    }
 
    float4x4 m       = make_matrix       ( key.rotation, key.translation);
    return m;
}
