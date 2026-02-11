#include "common/states11.hlsl"
#include "common/samplers11.hlsl"
#include "common/stencil.hlsl"

cbuffer cb {
	float2 previousViewOrigin;
	float2 previousViewSize;

	float2 viewOrigin;
	float2 viewSize;

	float2 sourceTextureSizeInv;
	float clampingFactor;
	float newFrameWeight;

    float2 motionBlurScale;
    float2 maskScale;
};

Texture2D<float4> t_UnfilteredRT;
Texture2D<float2> t_MotionVectors;
Texture2D<float4> t_FeedbackInput;
Texture2D<uint2> t_Stencil;
Texture2D<float> t_Mask;

RWTexture2D<float4> u_ColorOutput;
RWTexture2D<float4> u_FeedbackOutput;
RWTexture2D<float> u_MaskOutput;

#define s_Sampler gBilinearClampSampler

#define USE_CATMULL_ROM_FILTER 1

#define GROUP_X 16
#define GROUP_Y 16
#define BUFFER_X (GROUP_X + 2)
#define BUFFER_Y (GROUP_Y + 2)
#define RENAMED_GROUP_Y ((GROUP_X * GROUP_Y) / BUFFER_X)

groupshared float4 s_ColorsAndLengths[BUFFER_Y][BUFFER_X];
groupshared float2 s_MotionVectors[BUFFER_Y][BUFFER_X];
groupshared uint s_Mask[BUFFER_Y][BUFFER_X];

float3 PQDecode(float3 image)
{
    float pq_m1 = 0.1593017578125;
    float pq_m2 = 78.84375;
    float pq_c1 = 0.8359375;
    float pq_c2 = 18.8515625;
    float pq_c3 = 18.6875;
    float pq_C = 10000.0;

    float3 Np = pow(max(image, 0.0), 1.0 / pq_m2);
    float3 L = Np - pq_c1;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(max(L, 0.0), 1.0 / pq_m1);

    return L * pq_C; // returns cd/m^2
}

float3 PQEncode(float3 image)
{
    float pq_m1 = 0.1593017578125;
    float pq_m2 = 78.84375;
    float pq_c1 = 0.8359375;
    float pq_c2 = 18.8515625;
    float pq_c3 = 18.6875;
    float pq_C = 10000.0;

    float3 L = image / pq_C;
    float3 Lm = pow(max(L, 0.0), pq_m1);
    float3 N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    image = pow(N, pq_m2);

    return saturate(image);
}

float3 BicubicSampleCatmullRom(Texture2D tex, SamplerState samp, float2 samplePos, float2 invTextureSize)
{
    float2 tc = floor(samplePos - 0.5) + 0.5;
    float2 f = saturate(samplePos - tc);
    float2 f2 = f * f;
    float2 f3 = f2 * f;

    float2 w0 = f2 - 0.5 * (f3 + f);
    float2 w1 = 1.5 * f3 - 2.5 * f2 + 1;
    float2 w3 = 0.5 * (f3 - f2);
    float2 w2 = 1 - w0 - w1 - w3;

    float2 w12 = w1 + w2;

    float2 tc0 = (tc - 1) * invTextureSize;
    float2 tc12 = (tc + w2 / w12) * invTextureSize;
    float2 tc3 = (tc + 2) * invTextureSize;

    float3 result =
        tex.SampleLevel(samp, float2(tc0.x, tc0.y), 0).rgb * (w0.x * w0.y) +
        tex.SampleLevel(samp, float2(tc0.x, tc12.y), 0).rgb * (w0.x * w12.y) +
        tex.SampleLevel(samp, float2(tc0.x, tc3.y), 0).rgb * (w0.x * w3.y) +
        tex.SampleLevel(samp, float2(tc12.x, tc0.y), 0).rgb * (w12.x * w0.y) +
        tex.SampleLevel(samp, float2(tc12.x, tc12.y), 0).rgb * (w12.x * w12.y) +
        tex.SampleLevel(samp, float2(tc12.x, tc3.y), 0).rgb * (w12.x * w3.y) +
        tex.SampleLevel(samp, float2(tc3.x, tc0.y), 0).rgb * (w3.x * w0.y) +
        tex.SampleLevel(samp, float2(tc3.x, tc12.y), 0).rgb * (w3.x * w12.y) +
        tex.SampleLevel(samp, float2(tc3.x, tc3.y), 0).rgb * (w3.x * w3.y);

    return max(0, result);
}

void Preload(int2 sharedID, int2 globalID)
{
    float3 color = PQEncode(t_UnfilteredRT[globalID].rgb);
    float2 motion = t_MotionVectors[round(globalID * motionBlurScale)].rg / motionBlurScale;
    float motionLength = dot(motion, motion);
	float mask = t_Mask[round(globalID * maskScale)].x;
    
    s_ColorsAndLengths[sharedID.y][sharedID.x] = float4(color.rgb, motionLength);
    s_MotionVectors[sharedID.y][sharedID.x] = motion;
	s_Mask[sharedID.y][sharedID.x] = mask;
}

[numthreads(GROUP_X, GROUP_Y, 1)]
void CS(
    in int2 i_threadIdx : SV_GroupThreadID,
    in int2 i_globalIdx : SV_DispatchThreadID
)
{
    int2 pixelPosition = i_globalIdx + int2(viewOrigin);

    // Rename the 16x16 group into a 18x14 group + 4 idle threads in the end

    int2 newID;
    float linearID = i_threadIdx.y * GROUP_X + i_threadIdx.x;
    linearID = (linearID + 0.5) / float(BUFFER_X);
    newID.y = int(floor(linearID));
    newID.x = int(floor(frac(linearID) * BUFFER_X));
    int2 groupBase = pixelPosition - i_threadIdx - 1;

    // Preload the colors and motion vectors into shared memory

    if (newID.y < RENAMED_GROUP_Y)
    {
        Preload(newID, groupBase + newID);
    }

    newID.y += RENAMED_GROUP_Y;

    if (newID.y < BUFFER_Y)
    {
        Preload(newID, groupBase + newID);
    }

    GroupMemoryBarrierWithGroupSync();

    // Calculate the color distribution and find the longest MV in the neighbourhood

    float3 colorMoment1 = 0;
    float3 colorMoment2 = 0;
    float longestMVLength = -1;
    int2 longestMVPos = 0;
    float3 thisPixelColor = 0;
	float mask = 1;

    [unroll]
    for (int dy = 0; dy <= 2; dy++)
    {
        [unroll]
        for (int dx = 0; dx <= 2; dx++)
        {
            int2 pos = i_threadIdx.xy + int2(dx, dy);

            float4 colorAndLength = s_ColorsAndLengths[pos.y][pos.x];
            float3 color = colorAndLength.rgb;
            float motionLength = colorAndLength.a;

            if (dx == 1 && dy == 1)
            {
                thisPixelColor = color;
            }

            colorMoment1 += color;
            colorMoment2 += color * color;

            if (motionLength > longestMVLength)
            {
                longestMVPos = pos;
                longestMVLength = motionLength;
            }
            
			mask = min(mask, s_Mask[pos.y][pos.x]);
        }
    }

    float2 longestMV = s_MotionVectors[longestMVPos.y][longestMVPos.x];

    colorMoment1 /= 9.0;
    colorMoment2 /= 9.0;
    float3 colorVariance = colorMoment2 - colorMoment1 * colorMoment1;
    float3 colorSigma = sqrt(max(0, colorVariance)) * clampingFactor;
    float3 colorMin = colorMoment1 - colorSigma;
    float3 colorMax = colorMoment1 + colorSigma;

    // Sample the previous frame using the longest MV

    float2 sourcePos = float2(pixelPosition.xy) + longestMV + 0.5;

	float history_mask = t_FeedbackInput.SampleLevel(gTrilinearClampSampler, sourcePos * sourceTextureSizeInv, 0).a;

	float history_weight = lerp(1, saturate(history_mask - mask + 1), saturate(longestMVLength));
    
    float3 resultPQ;
    if (newFrameWeight < 1 && all(sourcePos.xy > previousViewOrigin) && all(sourcePos.xy < previousViewOrigin + previousViewSize))
    {
#if USE_CATMULL_ROM_FILTER
        float3 history = BicubicSampleCatmullRom(t_FeedbackInput, s_Sampler, sourcePos, sourceTextureSizeInv);
#else
        float3 history = t_FeedbackInput.SampleLevel(s_Sampler, sourcePos * sourceTextureSizeInv, 0).rgb;
#endif

        // Clamp the old color to the new color distribution
        float3 historyClamped = history;
        if (clampingFactor >= 0)
        {
            historyClamped = min(colorMax, max(colorMin, history));
        }

        // Blend the old color with the new color and store output
		resultPQ = lerp(thisPixelColor, historyClamped, (1 - newFrameWeight) * history_weight);
	}
    else
    {
		resultPQ = thisPixelColor;
	}

    float3 result = PQDecode(resultPQ);

    u_ColorOutput[pixelPosition] = float4(result, 1.0);
	u_FeedbackOutput[pixelPosition] = float4(resultPQ, mask);
}

[numthreads(GROUP_X, GROUP_Y, 1)]
void CS_MASK(int2 pixelPosition : SV_DispatchThreadID) {
	uint stv = t_Stencil.Load(uint3(pixelPosition, 0)).g & (STENCIL_COMPOSITION_MASK | 7);
	u_MaskOutput[pixelPosition] = stv != (STENCIL_COMPOSITION_MODEL | 1) && stv != STENCIL_COMPOSITION_COCKPIT;
}


#define COMMON_PART         SetVertexShader(NULL);                                                              \
                            SetPixelShader(NULL);                                                               \
                            SetGeometryShader(NULL);                                                            \
                            SetHullShader(NULL);                                                                \
                            SetDomainShader(NULL);                                                              \
                            SetDepthStencilState(disableDepthBuffer, 0);                                        \
                            SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);       \
                            SetRasterizerState(cullNone);

technique10 Tech {
    pass P0 {
        SetComputeShader(CompileShader(cs_5_0, CS()));
        COMMON_PART
    }
	pass P1	{
		SetComputeShader(CompileShader(cs_5_0, CS_MASK()));
        COMMON_PART
	}
}

