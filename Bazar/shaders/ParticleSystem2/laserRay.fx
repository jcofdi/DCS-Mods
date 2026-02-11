#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/softParticles.hlsl"
#include "common/stencil.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"	
#include "PostEffects/NVD_common.hlsl"

//float3		position; 
//float3		position2; 
float4		positionVP; 
float4		positionVPY;
float4		positionVPX; 
float4		positionVPXY;

float		laserParams;

#define 	screenPixelSize		laserParams.x


static const float width 				= 0.08;
static const float opacity 				= 1.0;
static const float brightnessSparks 	= 6.0;

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};

struct VS_OUTPUT {};


struct GS_OUTPUT_LASER
{
	float4 pos				: SV_POSITION0;
	float4 projPos			: TEXCOORD0;
	float2 uv				: TEXCOORD1;
};

struct GS_OUTPUT_LOD
{
	float4 pos				: SV_POSITION0;
	float4 projPos			: TEXCOORD0;
};

void vsLaserDummy()
{
}

[maxvertexcount(4)]
void gsLaserRay(point VS_OUTPUT input[1], inout TriangleStream<GS_OUTPUT_LASER> outputStream)
{
	GS_OUTPUT_LASER o;
	
	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 wPos;

		// /wPos.w = positionVP.w;
		float4 wPos1 = (positionVP*(particle[ii].y+0.5) + positionVPY*(0.5-particle[ii].y));
		float4 wPos2 = (positionVPX*(particle[ii].y+0.5) + positionVPXY*(0.5-particle[ii].y));
		wPos = (wPos1*(particle[ii].x+0.5) + wPos2*(0.5-particle[ii].x));

		o.pos = o.projPos = wPos;


		o.uv.x = particle[ii].x + 0.5;
		o.uv.y = particle[ii].y + 0.5;

		outputStream.Append(o);
	}

	outputStream.RestartStrip();                          
}


[maxvertexcount(2)]
void gsLaserRayLod(point VS_OUTPUT input[1], inout LineStream<GS_OUTPUT_LOD> outputStream)
{
	GS_OUTPUT_LOD o;
	o.pos = o.projPos = positionVP;
	outputStream.Append(o);
	o.pos = o.projPos = positionVPY;
	outputStream.Append(o);	
	outputStream.RestartStrip();
}


float4 psLaserRay(in GS_OUTPUT_LASER i, uniform bool bMask): SV_TARGET0
{
	if (bMask && (getNVDMask(i.projPos.xy/i.projPos.w) <= 0))
		discard;

	float ll = 2.0*abs(abs(i.uv.x - 0.5) - 0.5);

	ll = ll + smoothstep(0.0, 0.9, ll)*2.0;

	float opacityPs = pow((1.0 - i.uv.y)*0.9+0.1, 2)*0.005;
	opacityPs *= (1.0 - smoothstep(0.0, i.uv.y+0.1, 2.0*abs(i.uv.x-0.5)))*0.5 + 0.5;


	return float4(ll, ll, ll, opacityPs*opacity);
}

float4 psLaserRayLod(in GS_OUTPUT_LOD i, uniform bool bMask): SV_TARGET0
{
	if (bMask && (getNVDMask(i.projPos.xy/i.projPos.w) <= 0))
		discard;

	return 0.05*float4(1.0, 1.0, 1.0, screenPixelSize);
}


RasterizerState lineRasterizerState
{
	CullMode = None;
	FillMode = Solid;
	MultisampleEnable = true;
};

technique10 tech
{
	pass laserRay
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserDummy()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserRay()));
		SetPixelShader(CompileShader(ps_5_0, psLaserRay(false)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetRasterizerState(cullNone);
	}

	pass laserRayLod
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserDummy()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserRayLod()));
		SetPixelShader(CompileShader(ps_5_0, psLaserRayLod(false)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetRasterizerState(lineRasterizerState);
	}

	pass laserRayMask
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserDummy()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserRay()));
		SetPixelShader(CompileShader(ps_5_0, psLaserRay(true)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetRasterizerState(cullNone);
	}

	pass laserRayMaskLod
	{
		SetVertexShader(CompileShader(vs_5_0, vsLaserDummy()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(CompileShader(gs_5_0, gsLaserRayLod()));
		SetPixelShader(CompileShader(ps_5_0, psLaserRayLod(true)));
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetRasterizerState(lineRasterizerState);
	}

}
