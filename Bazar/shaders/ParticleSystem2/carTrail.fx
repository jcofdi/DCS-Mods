/*
	���� �� ���� �� �������� + ������ � ��� ����
*/
#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/ambientCube.hlsl"
#include "common/stencil.hlsl"
#include "common/softParticles.hlsl"
#include "ParticleSystem2/common/psCommon.hlsl"

#define MODEL_SHADING_OPACITY_CONTROL
#include "ParticleSystem2/common/modelShading.hlsl"
#include "ParticleSystem2/common/splines.hlsl"

float 		wheelWidth;
int 		lastParticle;	//number of particles currently being drawn
float2 		segmentLength;  
static const int 	segments = 10;
static const float 	width = 1.0;

struct VS_OUTPUT
{
	float4 pos	  : TEXCOORD0; 
	float3 vel 	  : TEXCOORD1;	
};

struct HS_PATCH_OUTPUT
{
	float edges[2] : SV_TessFactor;
	float3 p1	: TEXCOORD5;
	float3 p2	: TEXCOORD6;
	float tang1	: TEXCOORD7;
	float tang2	: TEXCOORD8;
};

struct DS_OUTPUT
{
	float4 pos1	  		: TEXCOORD0;
	float3 vel1   		: TEXCOORD1;
	float3 vel2   		: TEXCOORD2;
	float4 pos2	  		: TEXCOORD4;
	float4 opacitygs	: TEXCOORD5;
};

struct PS_INPUT
{
	float4 pos		 : SV_POSITION;
	float4 projPos	 : TEXCOORD0;
	float2 TextureUV : TEXCOORD1;
};


VS_OUTPUT VS_Trail(
	float3 startPos	: TEXCOORD0, 
	float3 startVelIn: TEXCOORD1,
	uint   vertId:  SV_VertexID) 
{
	
	float3 startVel = normalize(startVelIn.xyz);

	float3 posOffset = startPos - worldOffset;

	VS_OUTPUT o;
	o.pos.xyz	= posOffset;
	o.pos.w 	= vertId;
	o.vel.xyz	= -startVel;
	return o;
}

//compute extra control points for bezier curve
HS_PATCH_OUTPUT HSconst_shaderName(InputPatch<VS_OUTPUT, 2> ip)
{
	
	HS_PATCH_OUTPUT o;
	

	o.edges[0] = 1; 
	o.edges[1] = segments; 
	
	float len = distance(ip[0].pos.xyz, ip[1].pos.xyz);
	const float coef = 1.0/3.0 * len;

	o.p1.xyz = ip[0].pos.xyz - normalize(ip[0].vel.xyz)*coef;
	o.p2.xyz = ip[1].pos.xyz + normalize(ip[1].vel.xyz)*coef;


	o.tang1 = ip[0].pos.w;
	o.tang2 = ip[1].pos.w;

	
	return o;
}

[domain("isoline")]
[partitioning("integer")]
[outputtopology("point")]
[outputcontrolpoints(2)]
[patchconstantfunc("HSconst_shaderName")]
VS_OUTPUT HS_shaderName(InputPatch<VS_OUTPUT, 2> ip, uint id : SV_OutputControlPointID)
{
    VS_OUTPUT o;
	
	o = ip[id];
    return o;
}

//make bezier curves and compute opacity based vertex ID
[domain("isoline")]
DS_OUTPUT DS_shaderName(HS_PATCH_OUTPUT input, OutputPatch<VS_OUTPUT, 2> op, float2 uv : SV_DomainLocation)
{
	#define POS_MSK(x)			op[x].pos.xyz
	#define SPEED_DIR_VALUE(x)	op[x].vel.xyz

	DS_OUTPUT o;
	float t1 = uv.x;
	float t2 = min(t1+1.0/segments, 1.0);

	o.opacitygs.z = uv.x;
	o.opacitygs.w = min(uv.x+1.0/segments, 1.0);

	o.opacitygs.x = 1.0;
	o.opacitygs.y = 1.0;

	o.pos1.xyz		= BezierCurve3(t1, POS_MSK(0), input.p1.xyz, input.p2.xyz, POS_MSK(1));
	o.vel1.xyz   = lerp(SPEED_DIR_VALUE(0),	SPEED_DIR_VALUE(1),	 t1);
	o.vel2.xyz   = lerp(SPEED_DIR_VALUE(0),	SPEED_DIR_VALUE(1),	 t2);

	o.pos2.xyz = BezierCurve3(t2, POS_MSK(0), input.p1.xyz, input.p2.xyz, POS_MSK(1));

	if (input.tang2 == 0) {
		float3 pp1 =   POS_MSK(0)*segmentLength.y + (1.0-segmentLength.y)*POS_MSK(1);
		float3 pp2 =   POS_MSK(1);
		o.pos1.xyz = t1*pp1 + (1.0-t1)*pp2;
		o.pos2.xyz = t2*pp1 + (1.0-t2)*pp2;

		float tt1 = smoothstep(0.0, 0.1*(1.0-segmentLength.y), 1.0-t1);
		float tt2 = smoothstep(0.0, 0.1*(1.0-segmentLength.y), 1.0-t2);


		o.opacitygs.x = tt1;
		o.opacitygs.y = tt2;
	}

	o.pos1.w = (input.tang1+t1)/lastParticle;
	o.pos2.w = (input.tang1+t2)/lastParticle;


	float tailLength = 0.1*segmentLength.x;

	if (((lastParticle - input.tang2) == 2)) {
		float tt1 = max(t1, tailLength/segmentLength.x);
		float tt2 = max(t2, tailLength/segmentLength.x);

		tt1 = smoothstep(0.0, tailLength/segmentLength.x, t1);
		tt2 = smoothstep(0.0, tailLength/segmentLength.x, t2);

		o.opacitygs.x = tt1;
		o.opacitygs.y = tt2;
	}


	#undef SPEED_DIR_VALUE
	#undef POS_MSK
    return o;	
}


[maxvertexcount(4)]
void GS_Trail(point DS_OUTPUT input[1], inout TriangleStream<MODEL_PS_INPUT> outputStream)
{
	float3 posOffset	= input[0].pos1.xyz;
	float2 opacity		= input[0].opacitygs.xy;
	float2 gs			= input[0].opacitygs.zw;

	MODEL_PS_INPUT o;


	float3 offset1 = normalize(cross(float3(0.0, 1.0, 0.0), input[0].vel1.xyz));
	float3 offset2 = normalize(cross(float3(0.0, 1.0, 0.0), input[0].vel2.xyz));

	o.normal = float3(0.0, -1.0, 0.0);
	o.tangent = -float3(0.0, 0, 1.0);

	o.opacity = opacity.x;
	float3 tt = posOffset + offset1*wheelWidth*width;
	o.wPos = float4(tt, 1.0);
	o.pos = o.projPos = mul(float4(tt, 1), gViewProj);
	o.uv.xy = float2(1.0, 0.5);
	outputStream.Append(o);

	tt = posOffset - offset1*wheelWidth*width;
	o.wPos = float4(tt, 1.0);
	o.pos = o.projPos = mul(float4(tt, 1), gViewProj);
	o.uv.xy = float2(0.0, 0.5);
	outputStream.Append(o);

	o.opacity = opacity.y;
	tt = input[0].pos2 + offset2*wheelWidth*width;
	o.wPos = float4(tt, 1.0);
	o.pos = o.projPos = mul(float4(tt, 1), gViewProj);
	o.uv.xy = float2(1.0, 0.5);
	outputStream.Append(o);
	
	tt = input[0].pos2 - offset2*wheelWidth*width;
	o.wPos = float4(tt, 1.0);
	o.pos = o.projPos = mul(float4(tt, 1), gViewProj);
	o.uv.xy = float2(0.0, 0.5);
	outputStream.Append(o);

	outputStream.RestartStrip();

}

float4 MODEL_FORWARD_PS_SHADER_NAME_CAR(MODEL_PS_INPUT i, uniform int flags): SV_Target0
{
	MaterialParams mp = GetMaterialParams(i, flags);

	float shadow = 1.0;
	float2 cloudShadowAO = SampleShadowClouds(mp.pos);
	shadow = cloudShadowAO.x;
	if(flags & MAT_FLAG_CASCADE_SHADOWS)
		shadow = min(shadow, applyShadow(float4(mp.pos, i.pos.z), mp.normal));

#ifdef MODEL_SHADING_OPACITY_CONTROL
	mp.diffuse.a *= i.opacity;
#endif

	float3 sunColor = SampleSunRadiance(mp.pos.xyz, gSunDir);
	float4 finalColor = float4(ShadeHDR(i.pos.xy, sunColor, mp.diffuse.rgb, mp.normal, mp.aorm.y, mp.aorm.z, mp.emissive, shadow, mp.aorm.x, cloudShadowAO, mp.toCamera, mp.pos, float2(1,mp.aorm.w)), mp.diffuse.a);

	return float4(applyAtmosphereLinear(gCameraPos.xyz, mp.pos, i.projPos, finalColor.rgb), finalColor.a);
}


DepthStencilState trailDS
{
	DepthEnable		= false;
	DepthWriteMask	= false;
	DepthFunc		= ALWAYS;

	TEST_COMPOSITION_TYPE_IN_STENCIL;
};
technique10 CarTrail
{
	pass TrailFirst
	{
		SetDepthStencilState(trailDS, STENCIL_COMPOSITION_SURFACE);
		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);

		SetVertexShader(CompileShader(vs_4_0, VS_Trail()));
		SetHullShader(CompileShader(hs_5_0, HS_shaderName()));
		SetDomainShader(CompileShader(ds_5_0, DS_shaderName()));
		SetGeometryShader(CompileShader(gs_5_0, GS_Trail()));
		SetPixelShader(CompileShader(ps_5_0, MODEL_FORWARD_PS_SHADER_NAME_CAR(MAT_FLAG_DIFFUSE_MAP | MAT_FLAG_SPECULAR_MAP | MAT_FLAG_NORMAL_MAP | MAT_FLAG_CASCADE_SHADOWS)));
	}

}
