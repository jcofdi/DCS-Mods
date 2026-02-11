#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/stencil.hlsl"

float4 LightCoordinate;
int2 WaveOffset;
float2 InvDepthTextureSize;

#ifdef MSAA
	Texture2DMS<float, MSAA> DepthTexture;
	Texture2DMS<uint2, MSAA> StencilTexture;
    #define	SampleMap(name, uv)  name.Load(uint2(uv), 0)
#else	
	Texture2D<float> DepthTexture;
	Texture2D<uint2> StencilTexture;
    #define	SampleMap(name, uv)  name.Load(uint3(uv, 0))
#endif

RWTexture2D<float> OutputTexture;

#define WAVE_SIZE 64
#define SAMPLE_COUNT 60	
#define HARD_SHADOW_SAMPLES 4
#define FADE_OUT_SAMPLES 8

#define USE_HALF_PIXEL_OFFSET 1	
#define USE_UV_PIXEL_BIAS 1

#include "bend_sss_gpu.hlsl"


[numthreads(WAVE_SIZE, 1, 1)]
void CS(in int3 inGroupID : SV_GroupID, in int inGroupThreadID : SV_GroupThreadID) {
	
	float fovFactor = 1.0 / gProj._m11;
    DispatchParameters p;
	p.SurfaceThickness = fovFactor * 0.005;
	p.BilinearThreshold = fovFactor * 0.02;
	p.ShadowContrast = 4;
	p.IgnoreEdgePixels = true;
	p.UsePrecisionOffset = false;
	p.BilinearSamplingOffsetMode = false;
        
	p.DebugOutputEdgeMask = false;
	p.DebugOutputThreadIndex = false;
	p.DebugOutputWaveIndex = false;
        
	p.DepthBounds = float2(0, 1);
	p.UseEarlyOut = false;
        
	p.LightCoordinate = LightCoordinate;
	p.WaveOffset = WaveOffset;
	p.FarDepthValue = 0;
	p.NearDepthValue = 1;
	p.InvDepthTextureSize = InvDepthTextureSize;
		
	WriteScreenSpaceShadow(p, inGroupID, inGroupThreadID);
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
}

