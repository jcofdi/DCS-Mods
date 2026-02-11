#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/softParticles.hlsl"
#include "common/stencil.hlsl"
#define FOG_ENABLE
#include "common/fog2.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"	
#include "PostEffects/NVD_common.hlsl"

float3		position; 

static const float width 				= 0.08;
static const float opacity 				= 1.0;
static const float brightnessSparks 	= 6.0;
static const float glowSize 			= 0.02;
static const float glowOffset 			= 0.02;


static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};

static const float4 particle2[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( 0.5, -0.5, 0, 0),
    float4( -0.5, -0.5, 1, 0)
};

struct VS_OUTPUT {};

struct GS_OUTPUT
{
	float4 pos		: SV_POSITION0;
	float4 projPos	: TEXCOORD0;
	float3 uv		: TEXCOORD1;
};



void vsLaserGlow()
{
}


[maxvertexcount(4)]
void gsLaserGlow(point VS_OUTPUT input[1], inout TriangleStream<GS_OUTPUT> outputStream)
{
	GS_OUTPUT o;

	for (int ii = 0; ii < 4; ++ii)	
	{
		double4 wPos;
		wPos = double4(position, 1.0);
		wPos = mul(wPos, gView);
		wPos = mul(wPos, gProj);
		double temp = double(1.0)/wPos.w;
		wPos.xyz *= temp;

		double zoomCoef = 1.73/gProj[0][0];
		double dist = length(gCameraPos - position)*zoomCoef;
		float dist_thres = 20.0/(gScreenWidth*glowSize);
		dist = smoothstep(0.0, 1800, dist);
		o.pos = o.projPos = float4(float2(particle[ii].x, particle[ii].y*gScreenAspect)*glowSize*min(max((1.0 - dist), dist_thres), 1.0)+wPos.xy, wPos.z, 1.0);
		o.uv.x = particle[ii].x + 0.5;
		o.uv.y = 0.5 - particle2[ii].y;
		o.uv.z = 1.0 - dist;
		outputStream.Append(o);
	}

	outputStream.RestartStrip();                          
}



float4 psLaserGlow(in GS_OUTPUT i, uniform bool bMask): SV_TARGET0
{

	if (bMask && (getNVDMask(i.projPos.xy/i.projPos.w) <= 0))
		discard;

	float4 alpha = tex.Sample(ClampLinearSampler, i.uv.xy).rrrr;
	alpha.a *= 0.15*(i.uv.z*0.9+0.1);
	alpha.rgb *= 4.0 + 6.0*i.uv.z;
	float llx = 2.0*abs(abs(i.uv.x - 0.5) - 0.5);
	float lly = 2.0*abs(abs(i.uv.x - 0.5) - 0.5);
	alpha.rgb += smoothstep(0.0, 0.9, llx*lly)*2.0; 
	return alpha*alpha;
}

DepthStencilState glowDS
{
	DepthEnable		= false;
	DepthWriteMask	= false;
	DepthFunc		= ALWAYS;
};




technique10 laserGlowTech{
	pass laserGlow
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserGlow()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserGlow()));
		SetPixelShader(CompileShader(ps_5_0, psLaserGlow(false)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		//SetDepthStencilState(glowDS, 0);
		SetRasterizerState(cullNone);
	}

	pass laserGlowMask
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserGlow()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserGlow()));
		SetPixelShader(CompileShader(ps_5_0, psLaserGlow(true)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		//SetDepthStencilState(glowDS, 0);
		SetRasterizerState(cullNone);
	}
}