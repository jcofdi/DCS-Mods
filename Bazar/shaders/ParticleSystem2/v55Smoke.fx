#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"
#include "common/stencil.hlsl"
#include "common/softParticles.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "common/splines.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"
#include "ParticleSystem2/common/splines.hlsl"
//#include "noise/noise3D.hlsl"

float2 		params;
float3 		baseColor;
#define		time					params.x
#define		segmentLength			params.y

static const int 	segments = 20;

struct VS_OUTPUT
{
	float3 pos	  		: TEXCOORD0; 
	//float4 params 		: TEXCOORD1; //size, opacity, angle, nAge
	float4 params 		: TEXCOORD1; //size, opacity, angle, age
	float3 startSpeed	: TEXCOORD2;
	float3 randVertID	: TEXCOORD3;
};

struct HS_PATCH_OUTPUT
{
	float edges[2] 		: SV_TessFactor;
	float3 pos1			: TEXCOORD0;
	float3 pos2			: TEXCOORD1;
	float3 dir			: TEXCOORD2;
	float2  orderOffset  : TEXCOORD3;
};

struct DS_OUTPUT
{
	float3 pos	  : TEXCOORD0;
	float3 params : TEXCOORD1;
};

struct PS_INPUT
{
	float4 pos			: SV_POSITION;
	float3 normal		: TEXCOORD0;
	float3 sunColor 	: TEXCOORD1;
	float3 uv 			: TEXCOORD2;
	float4 projPos		: TEXCOORD3;
};

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};


VS_OUTPUT VS_V55_SMOKE(
	float4 startPosBTime	: TEXCOORD0,		// particle position and birth time
	float4 offsetLifeTime	: TEXCOORD1,		// random offset for each particle (up direction is y, and xz is perpendicular to y and to speed vector); particle life time
	float4 randWind			: TEXCOORD2,		// two rand params and wind
	float3 startSpeed		: TEXCOORD3,
	uint   vertId			: SV_VertexID,
	uniform bool 			  bClouds) 		
{
	#define 	startPos 			startPosBTime.xyz
	#define 	birthTime 			startPosBTime.w

	VS_OUTPUT o;
	o.pos = startPos - worldOffset;
	float age = time - birthTime;
	float nAge = max(min(age/offsetLifeTime.w, 1.0), 0.0);

	o.pos.xyz += offsetLifeTime.xyz*nAge*50.0*(noise1D(randWind.y+0.34893) - 0.5);
	//o.pos.y += offsetLifeTime.y*nAge*3.0;

	//o.pos.xz += age*randWind.zw*0.3*smoothstep(offsetLifeTime.w/20.0, offsetLifeTime.w/10.0, age)*(0.5+0.5*noise1D(randWind.x+0.29124)); 
	o.pos += 0.1*age*startSpeed; 
	o.pos.y += 0.1*pow(age,2)/2;
	//o.pos.y = max(o.pos.y, 0.0);

	//o.pos.y += 20.0;

	float ampl = 20.0;

	float size = 0.1+0.8*smoothstep(0.0, 0.01, nAge);
	size += 2.0*smoothstep(0.01, 0.2, nAge);
	size += 4.0*smoothstep(0.2, 1.0, nAge);

	o.params.x = (0.5 + 0.3*randWind.y*min(age*10.0, 1.0)*abs(sin(100.0*2*PI*frac(birthTime))))*ampl*size;
	float newSize = (0.5 + 0.3*randWind.y*min(age*10.0, 1.0))*ampl*size;

	float lerpParam = smoothstep(0.05, 0.07, nAge);

	o.params.x = (1.0 - lerpParam)*newSize + lerpParam*o.params.x;

	o.params.y = 1.0 - smoothstep(0.0, 1.0, nAge);

	if(bClouds)
		o.params.y *= min(getAtmosphereTransmittance(0).r, 1.0);

	//o.params.y *= smoothstep(5.0, 6.0, age);

	float rotSpeed = smoothstep(0.0, offsetLifeTime.w/15.0, age);
	//rotSpeed = age*lerp(1.0, 0.1, rotSpeed);

	o.params.y *= 0.5+0.5*noise1D(randWind.x+0.2304);
	o.params.z = randWind.y*2*PI - 2*PI*rotSpeed*(0.8+0.2*randWind.y);
	//o.params.z = 0.0;
	//o.params.w = nAge;
	o.startSpeed = startSpeed;
	o.randVertID.xy = randWind.xy;
	o.randVertID.z = asfloat(vertId);
	o.params.w = age;

	return o;

	#undef		startPos
	#undef		birthTime	
}


//compute extra control points for bezier curve
HS_PATCH_OUTPUT HSconst_shaderName(InputPatch<VS_OUTPUT, 2> ip)
{
	float isFirstSegment = asuint(ip[0].randVertID.z) == 1;
	isFirstSegment = 0.0;
	if ( asuint(ip[0].randVertID.z) == 1)
		isFirstSegment = 1.0;

	HS_PATCH_OUTPUT o;
	
	float len = distance(ip[0].pos.xyz, ip[1].pos.xyz);

	o.edges[0] = 1; 
	o.edges[1] = segments;

	if (len < 0.001)
		o.edges[1] = 0.0;
	//o.edges[1] = segments*len/segmentLength; 


	const float coef = 1.0/3.0 * len;

	o.pos1.xyz = ip[0].pos.xyz - normalize(ip[0].startSpeed.xyz)*coef;
	o.pos2.xyz = ip[1].pos.xyz + normalize(ip[1].startSpeed.xyz)*coef;
	o.dir = ip[0].startSpeed;
	//o.dir = ip[1].startSpeed;
	o.orderOffset.x = isFirstSegment;
	o.orderOffset.y = len/segmentLength;

	
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
	DS_OUTPUT o;
	o.pos = op[0].pos;
	o.params = op[0].params;
	//float segStep = 1.0/segments;
	float segStep = 1.0/input.orderOffset;
	//float tInt = segments*segStep*uv.x;
	//float tInt = floor(uv.x*input.edges[1])/segments;
	//float realUV = 
	//float tInt = uv.x*segments/(segments+1);
	//float tInt = uv.x;
	float t1 = (uv.x*segments);
	//t2 = 1.0 - t2;
	t1 = (t1+1)/(segments+1);
	//t1 = 1.0 - t1;
	
	
	float rand = op[0].randVertID.x*(1.0-t1) + op[1].randVertID.x*t1;
	rand = noise1D(rand+uv.x);

	o.pos.xyz = BezierCurve3(t1, op[0].pos.xyz, input.pos1.xyz, input.pos2.xyz, op[1].pos.xyz);

	//o.pos.xyz = op[0].pos.xyz*(1.0-tInt) + op[1].pos.xyz*tInt;
	//o.pos.xyz = op[0].pos.xyz - input.dir*segmentLength*tInt;

	o.params = op[0].params*(1.0-t1) + op[1].params*t1;

	if (input.orderOffset.x == 1.0) {
		float3 pos1 = o.pos.xyz;
		float3 pos2 = (op[0].pos.xyz - input.dir*segmentLength*t1);
		//float3 pos2 = (op[0].pos.xyz - input.dir*segmentLength*t2);
		o.pos.xyz = input.orderOffset.y*pos1 + (1.0 - input.orderOffset.y)*pos2;

		//o.pos.xyz = pos2;

		if (uv.x >  input.orderOffset.y)
			o.params.y = 0.0;

		//float newT = (input.orderOffset.y*segments + 1)/(segments+1);

		//newT = smoothstep(0.0, newT, t1);

		//newT = max((t1 - newT), 0.0)/max(t1-newT, 0.001);
		//o.params.x = op[0].params.x *(1.0 - newT) + newT*op[1].params.x;

		//rand = op[0].randVertID.x*(1.0-t1) + op[1].randVertID.x*t1;
		//rand = noise1D(rand+uv.x);

		//o.params.y = smoothstep(0.2, 1.0, uv.x);
		//o.params.y = 0.0;
		//float age2 = op[1].params.w;
		//float age1 = 
	}

	//o.params.y = uv.x;

	o.params.z = rand*2*PI;
	//o.params.z = 0.0;
	//o.params.x = 10.0;
	//o.params.y = 1.0;
	//o.params.y = uv.x == 1.0 ? 0.0 : 1.0;
	return o;
}


[maxvertexcount(4)]
void GS_V55_SMOKE(point DS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream)
{
	PS_INPUT o;
	
	o.sunColor = getPrecomputedSunColor(0);

	float4 worldPos = float4(input[0].pos, 1.0);
	worldPos = mul(worldPos, gView);
	//worldPos /= worldPos.w;

	float2 sc;
	sincos(input[0].params.z, sc.x, sc.y);
	sc *= input[0].params.x;
	//sc.x *= 2.0;

	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	//float4 uvOffsetScale = getTextureFrameUV16x8(pow(input[0].params.w, 0.5)*(16*8-1));

	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;

		pos.xy += mul(particle[ii].xy, M);

		o.uv.xy = particle[ii].xy + 0.5;
		//o.uv.xy = (particle[ii].xy+0.5) * uvOffsetScale.xy + uvOffsetScale.zw;

		o.uv.z = input[0].params.y;
		o.pos = mul(pos, gProj);
		o.normal = normalize(gCameraPos - input[0].pos);
		o.projPos = o.pos;
		outputStream.Append(o);
	}
	outputStream.RestartStrip();  

}

float4 PS_V55_SMOKE(PS_INPUT i): SV_Target0
{
	//float spAlphaC = depthAlpha(i.projPos, 1.0f);
	float spAlphaC = 1.0;
	//float2 newUV = noise2D(i.uv.xy);
	//newUV = 0.9*i.uv.xy + 0.1*saturate(newUV);
	float2 newUV;
	//newUV.x = i.uv.x + pnoise(i.pos.xyz, 1.0);
	//newUV.x = max(min(newUV.x, 1.0), 0.0);
	//newUV.y = i.uv.y + pnoise(i.pos.xyz + 0.239832, 1.0);
	//newUV.y = max(min(newUV.y, 1.0), 0.0);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;

	float lightCoef = clr.a;

	clr.a *= i.uv.z*spAlphaC*clr.a*0.5; 

	clip(clr.a - 0.01);

	clr.rgb = clr.rgb*2-1;

	float light = saturate(dot(-clr.rgb, gSunDirV.xyz))*0.1 + 0.9;

	float3 color = baseColor;

	lightCoef = 1.0 - lightCoef;
	lightCoef = 0.8 + 0.2*lightCoef;

	clr.rgb = shading_AmbientSun(color, AmbientTop.rgb, lightCoef*i.sunColor * max(0, light/(2*PI)));

	clr.rgb *= min(gSunIntensity*0.1, 1.0);
	clr = float4(applyPrecomputedAtmosphere(clr.rgb, 0), clr.a*0.8);
	return clr;
}

#define PASS_BODY(vs, hs, ds, gs, ps)  { SetVertexShader(vs); SetHullShader (hs); SetDomainShader(ds); SetGeometryShader(gs); SetPixelShader(ps); \
		SetDepthStencilState(enableDepthBufferNoWrite, 0); \
		SetRasterizerState(cullNone); SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);}

GeometryShader	gsCompiled = CompileShader(gs_5_0, GS_V55_SMOKE());
HullShader      hsCompiled = CompileShader(hs_5_0, HS_shaderName());
DomainShader    dsCompiled = CompileShader(ds_5_0, DS_shaderName());
PixelShader		psCompiled = CompileShader(ps_5_0, PS_V55_SMOKE());

technique10 V55Smoke
{

	pass basic
	{
		SetDepthStencilState(enableDepthBufferNoWrite, 0);
		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);

		SetVertexShader(CompileShader(vs_5_0, VS_V55_SMOKE(false)));
		SetHullShader(CompileShader(hs_5_0, HS_shaderName()));
		SetDomainShader(CompileShader(ds_5_0, DS_shaderName()));
		SetGeometryShader(CompileShader(gs_5_0, GS_V55_SMOKE()));
		SetPixelShader(CompileShader(ps_5_0, PS_V55_SMOKE()));
	}

	//pass basic			PASS_BODY(CompileShader(vs_5_0, VS_V55_SMOKE(false)), hsCompiled, dsCompiled, gsCompiled, psCompiled)

}
