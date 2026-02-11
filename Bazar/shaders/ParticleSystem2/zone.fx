#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/platform.hlsl"
#include "common/ambientCube.hlsl"
#include "common/softParticles.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"

float4		params;
float4		baseColor;

#define time		params.x
#define baseHeight	params.y
#define fresnelFactor params.z
#define baseRadius	params.w
#define opacityMax	baseColor.w

static const float radiusScale = 1.1;

struct VS_BLASTWAVE_OUTPUT
{
	float4 pos:		POSITION0;
	float2 params:	TEXCOORD0;
};

struct DS_BLASTWAVE_OUTPUT
{
	float4 pos:		SV_POSITION0;
	float  params:	TEXCOORD0;
	float4 projPos: TEXCOORD1;
	float4 vPos:	TEXCOORD2;
	float3 norm:	NORMAL0;
};

//depth test in View coord sys
void depthTest(in float2 projPos, in float vPosZ)
{
	float depth = g_DepthTexture.SampleLevel(gPointClampSampler, float2(projPos.x, -projPos.y)*0.5 + 0.5, 0).r;

	float4 vDepth = mul(float4(projPos, depth, 1), gProjInv);
	if(vDepth.z/vDepth.w - vPosZ < 0)
		discard;
}

float getHeightOffset()
{
	return 0;
}

VS_BLASTWAVE_OUTPUT vsZoneSphere(uint vertId: SV_VertexId, uniform bool bScreenSpace = false)
{
	VS_BLASTWAVE_OUTPUT o;
	o.pos = staticVertexData[vertId];
	o.pos.xy *= 2;
	o.params.x = baseRadius;
	o.params.y = opacityMax;
	return o;
}

struct HS_CONST_OUTPUT
{
	float edges[4] : SV_TessFactor;
	float inside[2]: SV_InsideTessFactor;
	float dist: TEXCOORD0;
};

HS_CONST_OUTPUT hsConstant(InputPatch<VS_BLASTWAVE_OUTPUT, 4> ip, uint pid : SV_PrimitiveID)
{
	float radius = ip[0].params.x;
	float dist = length(worldOffset.xyz - gCameraPos.xyz);
	float lod = 1 - min( 1, abs(dist-radius) / (2.5*radius) );
	float edge = 8 + lod * 24;
	float insideFactor = edge;

	HS_CONST_OUTPUT o;
	o.edges[0] = edge;
	o.edges[1] = edge; 
	o.edges[2] = edge;
	o.edges[3] = edge;
	o.inside[0] = insideFactor;
	o.inside[1] = insideFactor;
	o.dist = dist;
	return o;
}

[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("hsConstant")]
VS_BLASTWAVE_OUTPUT hsZoneSphere(InputPatch<VS_BLASTWAVE_OUTPUT, 4> ip, uint cpid : SV_OutputControlPointID)
{
	VS_BLASTWAVE_OUTPUT o = ip[cpid];
	return o;
}

//y - up, p:[-1,1]
float3 getPointOnHemisphereOnXZPlane(float2 p, float angMax, float radius, float height)
{
	float pDist = length(p);
	float2 sc;
	sincos(pDist * angMax / 180 * PI, sc.x, sc.y);
	float3 pos;
	pos.xz = p * (abs(sc.x) / pDist * radius);
	pos.y = sc.y * height;
	return pos;
}

float sdEllipsoid(float3 p, float3 r) 
{
	float k0 = length(p/r);
	float k1 = length(p/(r*r));
	return k0*(k0-1.0)/k1;
}

[domain("quad")]
DS_BLASTWAVE_OUTPUT dsZoneSphere(HS_CONST_OUTPUT input, float2 UV : SV_DomainLocation, OutputPatch<VS_BLASTWAVE_OUTPUT, 4> patch)
{
	const float angMax = 120;//grad

	float radius	= patch[0].params.x;//radius
	float opacity	= patch[0].params.y;//opacity
	float3 viewDir  = normalize(worldOffset.xyz - gCameraPos);
	
	float4 pos = lerp(
						lerp(patch[0].pos, patch[1].pos, UV.x),
						lerp(patch[2].pos, patch[3].pos, UV.x),
						UV.y
					);

	float len = max(abs(pos.x), abs(pos.y));
	pos.xy *= (len>0.0001) ? len / length(pos.xy) : 1;//quad -> circle

	float height = sqrt(1.001 - pos.x*pos.x - pos.y*pos.y);

	DS_BLASTWAVE_OUTPUT o;
	float dist = sdEllipsoid(worldOffset.xyz - gCameraPos, float3(radius,baseHeight,radius));
	if(dist<0) 
	{
		//hemisphere on XZ plane
		o.pos.xyz = getPointOnHemisphereOnXZPlane(pos.xy, angMax, radius, baseHeight);
		o.projPos.w = 1;//inside
	}
	else
	{
		if(baseHeight == baseRadius)
		{
			float3 Z = normalize(cross(viewDir, float3(0,1,0)));
			float3 X = cross(viewDir, Z);
			float3x3 M = {X, viewDir, Z};
			o.pos.xyz = mul(float3(pos.x, -height, pos.y)*radius, M);
		}
		else
		{
			o.pos.xyz = getPointOnHemisphereOnXZPlane(pos.xy, angMax, radius, baseHeight);
			o.pos.x = -o.pos.x;
		}
		o.projPos.w = -1;//outside
	}

	o.norm = -mul(o.pos.xyz, (float3x3)gView);
	o.params = saturate(1 - o.pos.y / baseHeight);

	o.pos.xyz += worldOffset.xyz;
	o.pos.w = 1;
	o.pos = mul(o.pos, gViewProj);
	o.projPos.xyz = o.pos.xyw;
	o.vPos = mul(o.pos, gProjInv);
	return o;
}

struct PS_OUTPUT
{
	TARGET_LOCATION_INDEX(0, 0) float3 colorAdd : SV_TARGET0;
	TARGET_LOCATION_INDEX(0, 1) float4 colorMul : SV_TARGET1;
};

PS_OUTPUT psZoneSphere(in DS_BLASTWAVE_OUTPUT i)
{
	float gradY = i.params;
	bool inside = i.projPos.w > 0;
	i.vPos /= i.vPos.w;
	depthTest(i.projPos.xy/i.projPos.z, i.vPos.z);

	float groundFactor = saturate(1 - (1-gradY) * 4);
	groundFactor = lerp(1, groundFactor, fresnelFactor);

	float opacity;

	if(inside)
		opacity = groundFactor;
	else
	{
		float NoV = max(0, dot(normalize(i.norm), normalize(i.vPos.xyz)));
		NoV = sqrt(NoV);
		opacity = max((1 - NoV*fresnelFactor), groundFactor);
	}

	PS_OUTPUT o;
	o.colorAdd = 0;
	o.colorMul = lerp(float4(baseColor.rgb,1), 1, 1-opacity*opacityMax);
	return o;
}

BlendState dualBS
{
	BlendEnable[0] = TRUE;

	SrcBlend = ONE;
	// SrcBlend = ZERO;
	DestBlend = SRC1_COLOR;
	BlendOp = ADD;

	SrcBlendAlpha = ZERO;
	DestBlendAlpha = INV_SRC_ALPHA;
	BlendOpAlpha = ADD;


	RenderTargetWriteMask[0] = 0x0f; //RED | GREEN | BLUE | ALPHA
};

technique10 tech
{
	pass zoneSphere
	{
		SetVertexShader(CompileShader(vs_4_0, vsZoneSphere(true)));
		SetHullShader(CompileShader(hs_5_0, hsZoneSphere()));
		SetDomainShader(CompileShader(ds_5_0, dsZoneSphere()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, psZoneSphere()));
		// SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetBlendState(dualBS, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetRasterizerState(cullBack);
	}
}
