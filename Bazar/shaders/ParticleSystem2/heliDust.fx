#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"
#include "common/stencil.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "common/splines.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"
#include "ParticleSystem2/common/motion.hlsl"
#include "noise/noise3D.hlsl"
#include "common/softParticles.hlsl"

float4 		params;
float3		params2;
float3		params3;

#define		time				params.x
#define		level				params.y
#define 	wind            	params.zw
#define 	startR				params2.x 			
#define 	segmentFloat		params2.y
#define 	rotDir 				params2.z


struct VS_OUTPUT
{
	float3 pos			: TEXCOORD0; 	// pos
	float4 params 		: TEXCOORD1; 	//size, opacity, angle, nAge
	float4 color 		: TEXCOORD2;
	float3 rand			: TEXCOORD3; 	// rand
};

struct PS_INPUT
{
	float4 pos			: SV_POSITION;
	float4 sunColor 	: TEXCOORD0;
	float3 uv 			: TEXCOORD1;
	float4 projPos		: TEXCOORD2;
	float3 rand			: TEXCOORD3;
	float4 color		: TEXCOORD4;
};

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};


VS_OUTPUT VS_HELI_DUST(
	float4 worldNormal		: NORMAL0,			// normal, rand
	float4 startPosBTime	: TEXCOORD0,		// particle position and birth time
	float4 heliSpeed		: TEXCOORD1,		// speed of the helicopter at the moment of particle creation
	float4 colorParticle	: TEXCOORD2,		// color of the particles (to distinguish between dust and water)
	float4 randLifeTime		: TEXCOORD3,		// two rand params
	float4 paramsParticle	: TEXCOORD4,		// sizeX, sizeY, opacityMult, influence of height
	uniform bool 			  bClouds) 		
{
	#define 	startPos 			startPosBTime.xyz
	#define 	birthTime 			startPosBTime.w
	#define		xScale 				paramsParticle.x
	#define		yScale 				paramsParticle.y
	#define		opacityMult 		paramsParticle.z
	#define		infHeli 			paramsParticle.w


	VS_OUTPUT o;
	o.pos.xyz = startPos - worldOffset;


	//particles form a circle
	float2 sc;
	sincos(randLifeTime.z, sc.x, sc.y);


	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	sc = mul(float2(1.0, 0.0), M);

	float3 speed = float3(sc.x, 0.0, sc.y);

	//need this parameter to move some particles along the helicopter speed
	float dotSpeed = dot(speed, heliSpeed.xyz);
	float age = time - birthTime;
	float nAge = age/randLifeTime.w;


	float rand0 = noise1D(randLifeTime.y + 0.492841);
	rand0 *= 0.9;
	rand0 += 0.1;

	float rand2 = noise1D(randLifeTime.x + 0.1204);

	float3 rand3 = float3(noise1D(randLifeTime.x + 0.835), noise1D(randLifeTime.y + 0.128), noise1D(randLifeTime.x + 0.34781));

	float speedMult = 60.0;

	//move particles in circle and heli speed dir with air resistance
	float3 trans = calcTranslationWithAirResistance(speedMult*float3(1.0, 0.0, 0.0)*(infHeli*0.2+0.8), 1.0, 1.6*(1.0 +  2.0*rand3.y), age);

	float rotAngle = -worldNormal.w*sqrt(age)*0.3*infHeli*rotDir;
	float3x3 mNormal = mul(rotMatrixY(rotAngle + randLifeTime.z), basis(worldNormal.xyz));

	o.pos += (1.2*length(trans)+0.4*xScale*infHeli)*mul(float3(1.0, 0.0, 0.0), mNormal);

	//move some more in heli speed direction
	trans = calcTranslationWithAirResistance(1.5*heliSpeed.w*max(dotSpeed, 0.0)*float3(heliSpeed.x, 0.0, heliSpeed.z), 1.0, 3.0, age);
	o.pos.xz += trans.xz;

	//add buoyancy
	o.pos.y += 2.5*yScale*(infHeli*0.5+0.5)*(0.3+0.7*rand2)*pow(age,2)/2;

	//particle size
	float ampl = 30.0*(infHeli*0.5+0.5);
	o.params.x = ampl*(nAge*0.7+0.3)*(rand3.x*0.3 + 0.7);

	//opacity
	o.params.y = 0.38*(1.0-nAge*nAge*nAge);
	o.params.y *= smoothstep(0.0, 0.03, nAge);
	o.params.y *= infHeli;
	o.params.y *= opacityMult;

	if(bClouds)
		o.params.y *= min(getAtmosphereTransmittance(0).r, 1.0);


	//angle of sprite rotation
	o.params.z = randLifeTime.y * 2 * PI;

	o.params.w = nAge;
	o.color = colorParticle;
	o.rand = rand3 - 0.5;

	return o;

	#undef		startPos
	#undef		birthTime	
	#undef		xScale
	#undef		yScale
	#undef		opacityMult
	#undef		infHeli
}


[maxvertexcount(4)]
void GS_HELI_DUST(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream)
{
	PS_INPUT o;
	
	o.sunColor.xyz = getPrecomputedSunColor(0);

	o.sunColor.w = input[0].params.w;

	float4 worldPos = float4(input[0].pos.xyz, 1.0);
	worldPos = mul(worldPos, gView);
	worldPos /= worldPos.w;

	float2 sc;
	sincos(input[0].params.z, sc.x, sc.y);
	sc *= input[0].params.x;

	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	o.color = input[0].color;
	o.rand = input[0].rand;

	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;

		pos.xy += mul(particle[ii].xy, M);

		o.uv.xy = particle[ii].xy + 0.5;
		o.uv.z = input[0].params.y;

		o.pos = mul(pos, gProj);
		o.projPos = o.pos;
		outputStream.Append(o);
	}
	outputStream.RestartStrip();  

}

float4 PS_HELI_DUST(PS_INPUT i): SV_Target0
{

	float spAlphaC = depthAlpha(i.projPos, 1.0f);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;

	float shapeShade = clr.a;

	clr.a *= i.color.w*spAlphaC*i.uv.z*1.5; 

	clip(clr.a - 0.001);

	clr.a = min(clr.a, 1.0);

	clr.rgb = clr.rgb*2-1;


	float light = saturate(dot(-clr.rgb, gSunDirV.xyz))*0.3 + 0.7;

	float3 color = i.color.xyz*shapeShade + 0.6*(1.0-shapeShade)*i.color.xyz;
	color += i.rand*0.1;
	color = saturate(color);

	float lightMult = i.color.w*0.8 + 0.2;


	clr.rgb = shading_AmbientSun(color, AmbientTop.rgb, 0.8*i.sunColor.xyz * max(0, lightMult*light/(2*PI)));
	clr.rgb *= min(gSunIntensity*0.1, 1.0);

	/*if (segmentFloat < 0.3) {
		return float4(segmentFloat*2.0, segmentFloat, 0.0, 1.0);
	}
	else {
		return float4(0.0, abs(segmentFloat-0.5)*2.0, segmentFloat, 1.0);
	}*/

	clr = float4(applyPrecomputedAtmosphere(clr.rgb, 0), saturate(clr.a));
	return clr;
}

#define PASS_BODY(vs, gs, ps)  { SetVertexShader(vs); SetHullShader (NULL); SetDomainShader(NULL); SetGeometryShader(gs); SetPixelShader(ps); \
		ENABLE_DEPTH_BUFFER_NO_WRITE_CLIP_COCKPIT; \
		SetRasterizerState(cullNone); SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);}

GeometryShader	gsCompiled = CompileShader(gs_5_0, GS_HELI_DUST());
PixelShader		psCompiled = CompileShader(ps_5_0, PS_HELI_DUST());

technique10 HeliDust
{
	pass basic			PASS_BODY(CompileShader(vs_5_0, VS_HELI_DUST(false)), gsCompiled, psCompiled)
	pass clouds			PASS_BODY(CompileShader(vs_5_0, VS_HELI_DUST(true)), gsCompiled, psCompiled)
}
