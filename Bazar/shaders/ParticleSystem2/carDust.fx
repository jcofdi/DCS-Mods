#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"
#include "common/stencil.hlsl"
#include "common/softParticles.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"

float params;
float3 baseColor;
float3 secondaryColor;

#define		time			params.x

struct VS_OUTPUT
{
	float3 pos	  : TEXCOORD0; 
	float3 params : TEXCOORD1;
};

struct PS_INPUT
{
	float4 pos			: SV_POSITION;
	float3 normal		: TEXCOORD0;
	float3 sunColor 	: TEXCOORD1;
	float4 uv 			: TEXCOORD2;
	float4 projPos		: TEXCOORD3;
};

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};


VS_OUTPUT VS_DUST(
	float4 startPosBTime	: TEXCOORD0,		// particle position and birth time
	float4 offsetLifeTime	: TEXCOORD1,		// random offset for each particle (up direction is y, and xz is perpendicular to y and to speed vector); particle life time
	float3 randVel			: TEXCOORD2,		// two rand params and normalized speed of the vehicle
	float2 wind				: TEXCOORD3,
	uniform bool 			  bClouds) 		
{
	#define 	startPos 			startPosBTime.xyz
	#define 	birthTime 			startPosBTime.w

	VS_OUTPUT o;
	o.pos = startPos - worldOffset;
	float age = time - birthTime;

	o.pos.xz += offsetLifeTime.xz*age*1.6;
	o.pos.y += offsetLifeTime.y*age*0.3;

	o.pos.xz += age*wind*0.4*smoothstep(offsetLifeTime.w/40.0, offsetLifeTime.w/8.0, age)*(0.5+0.5*noise1D(randVel.x+0.29124)); 

	float temp_age;
	temp_age = age/20.0;
	float ampl = (randVel.z*0.5 + 0.5)*13.0;
	float speedGrow = 4.0*(1.0+randVel.x);
	o.params.x = max(ampl*min(0.5, speedGrow*temp_age)*(randVel.x+1.0) + 2.0*smoothstep(10.0, 30.0, age), 3.0*min(age+0.2, 1.0)); //particle's size
	o.params.y = 1.0 - smoothstep(offsetLifeTime.w/9.0, offsetLifeTime.w, age);
	o.params.y *= 1.5 - smoothstep(offsetLifeTime.w - 0.0001, offsetLifeTime.w, age); //opacity of the particle
	float velMul = smoothstep(randVel.z, 0.0, 0.1);
	o.params.y *= velMul*velMul;
	
	if(bClouds)
		o.params.y *= min(getAtmosphereTransmittance(0).r, 1.0);

	float rotSpeed = smoothstep(0.0, offsetLifeTime.w/15.0, age);
	rotSpeed = age*lerp(1.0, 0.1, rotSpeed);

	o.params.z = randVel.y*2*PI - 2*PI*rotSpeed*(0.8+0.2*randVel.y);

	return o;

	#undef		startPos
	#undef		birthTime	
}


[maxvertexcount(4)]
void GS_DUST(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream)
{
	PS_INPUT o;
	
	o.sunColor = getPrecomputedSunColor(0);

	float4 worldPos = float4(input[0].pos, 1.0);
	worldPos = mul(worldPos, gView);
	worldPos /= worldPos.w;

	float y_min = input[0].pos.y;
	float y_max = input[0].pos.y;
	float4 ys = input[0].pos.y;

	float2 sc;
	sincos(input[0].params.z, sc.x, sc.y);
	sc *= input[0].params.x;

	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	y_min = input[0].pos.y - input[0].params.x;
	y_max = input[0].pos.y + input[0].params.x;


	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;
		
		pos.xy += mul(particle[ii].xy, M);
		pos = mul(pos, gViewInv);
		pos /= pos.w;
		ys[ii] = (pos.y - y_min)/(y_max-y_min); //get our y coords for the particle (for colour interpolation)
	}


	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;

		pos.xy += mul(particle[ii].xy, M);
		o.uv.xy = particle[ii].xy + 0.5;
		o.uv.z = input[0].params.y;
		o.uv.w = ys[ii];
		o.pos = mul(pos, gProj);
		o.normal = normalize(gCameraPos - input[0].pos);
		o.projPos = o.pos;
		outputStream.Append(o);
	}
	outputStream.RestartStrip();  

}

float4 PS_DUST(PS_INPUT i): SV_Target0
{
	float spAlphaC = depthAlpha(i.projPos, 1.0f);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;

	//clip(clr.a - 0.001);

	float opacityInt = smoothstep(0.03, 0.5, clr.a);
	float3 color2 = 0.8*opacityInt*float3(1.0, 1.0, 1.0) + (1.0 - opacityInt)*secondaryColor;
	clr.a *= i.uv.z*spAlphaC*1.5*(1.0-i.uv.w); 

	clip(clr.a - 0.01);

	clr.rgb = clr.rgb*2-1;

	float light = saturate(dot(-clr.rgb, gSunDirV.xyz))*0.8 + 0.9;

	float3 color = i.uv.w*baseColor + 0.5*(1.0-max(min(i.uv.w, 1.0), 0.0))*secondaryColor;
	color *= color2;

	clr.a *= i.uv.w*0.5 + (1.0 - i.uv.w)*1.2*min(i.pos.z/max(i.pos.w, 0.01), 1.0);
	clr.a *= 1.5;
	clr.rgb = shading_AmbientSun(color, AmbientTop.rgb, i.sunColor * max(0, light/(2*PI)));

	clr.rgb *= min(gSunIntensity*0.1, 1.0);
	clr = float4(applyPrecomputedAtmosphere(clr.rgb, 0), clr.a);
	return clr;
}


/*float4 PS_DUST_LOD(PS_INPUT i): SV_Target0
{
	float spAlphaC = depthAlpha(i.projPos, 1.0f);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;
	clr.a *= i.uv.z*spAlphaC*1.5*(1.0-i.uv.w); 
	clip(clr.a - 0.01);
	clr.rgb = float3(1.0, 0.7, 0.4);
	float light = saturate(dot(-clr.rgb, gSunDirV.xyz))*0.5 + 0.5;
	clr.rgb = shading_AmbientSun(clr.rgb, AmbientTop.rgb, i.sunColor * max(0, light/(2*PI)));
	clr.rgb *= min(gSunIntensity*0.1, 1.0);
	//return float4(0.7, 0.4, 0.22, clr.a);
	return clr;
}*/

float4 PS_DUST_FLIR(PS_INPUT i): SV_Target0
{
	clip(-1);
	return float4(1.0, 0.70, 0.40, 0.1);
}

#define PASS_BODY(vs, gs, ps)  { SetVertexShader(vs); SetGeometryShader((gs)); SetPixelShader(ps); \
		SetDepthStencilState(enableDepthBufferNoWrite, 0); \
		SetRasterizerState(cullNone); SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);}

GeometryShader	gsCompiled = CompileShader(gs_5_0, GS_DUST());
PixelShader		psCompiled = CompileShader(ps_5_0, PS_DUST());
//PixelShader		psCompiledLod = CompileShader(ps_5_0, PS_DUST_LOD());
PixelShader		psCompiledFlir = CompileShader(ps_5_0, PS_DUST_FLIR());

technique10 carDust
{
	pass basic			PASS_BODY(CompileShader(vs_5_0, VS_DUST(false)), gsCompiled, psCompiled)
	pass basicWithClouds	PASS_BODY(CompileShader(vs_5_0, VS_DUST(true)),  gsCompiled, psCompiled)
	pass lod			PASS_BODY(CompileShader(vs_5_0, VS_DUST(false)), gsCompiled, psCompiled)
	pass lodWithClouds	PASS_BODY(CompileShader(vs_5_0, VS_DUST(true)),  gsCompiled, psCompiled)
	pass flir			PASS_BODY(CompileShader(vs_5_0, VS_DUST(false)), gsCompiled, psCompiledFlir)

}
