#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "common/AmbientCube.hlsl"
#include "common/stencil.hlsl"
#include "common/softParticles.hlsl"
#include "ParticleSystem2/common/perlin.hlsl"
#include "common/motion.hlsl"
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"

float2 		params;
float4x4	World;
float4 		currentPos;

#define time 			params.x
#define radiusWheel 	params.y

//InitPositionBox = {Min = {-0.01, 0.7, 0.02}, Max = {0.01, 0.7, -0.02}}

static const float maxSize			= 5.0;
static const float rotAmp 			= 0.2; 
static const float startAngle		= 4.0;

struct VS_OUTPUT
{
	float3 pos	  	: TEXCOORD0; 
	float3 params 	: TEXCOORD1;
	float3 speed  	: TEXCOORD2;
};

struct PS_INPUT
{
	float4 pos			: SV_POSITION;
	float3 uv 			: TEXCOORD0;
};

static const float4 particle[4] = {
    float4( -0.5,  0.5, 0, 1),
    float4( 0.5,  0.5, 1, 1),
    float4( -0.5, -0.5, 0, 0),
    float4( 0.5, -0.5, 1, 0)
};


VS_OUTPUT VS_DIRT(
	float4 startPosBTime	: TEXCOORD0,		// particle position and birth time
	float4 speedLifeTime	: TEXCOORD1,		// speed for each particle, particle life time
	float2 rand				: TEXCOORD2,		// two rand params
	uniform bool 			  bClouds) 		
{
	#define 	startPos 			startPosBTime.xyz
	#define 	birthTime 			startPosBTime.w

	VS_OUTPUT o;
	o.pos = startPos - worldOffset;
	float age = time - birthTime;
	float nAge = age/speedLifeTime.w;

	o.pos += calcTranslation(0.1*speedLifeTime.xyz, age);
	//o.pos = float3(0.0, 0.0, 0.0);

	//o.pos.y += 1.0;
	//o.pos += 4.0*offsetLifeTime.xyz;
	float temp_age;
	float ampl = maxSize;
	float speedGrow = 4.0*(1.0+rand.x);
	float opacityTemp = smoothstep(0.0, 0.1, nAge);
	o.params.y = opacityTemp;
	opacityTemp =  smoothstep(0.1, 0.8, nAge);
	o.params.y += lerp(1.0, 0.8, opacityTemp)*(1.0 - step(0.1, nAge));
	opacityTemp =  smoothstep(0.8, 1.0, nAge);
	o.params.y += lerp(0.8, 0.3, opacityTemp)*(1.0 - step(0.8, nAge));
	
	if(bClouds)
		o.params.y *= min(getAtmosphereTransmittance(0).r, 1.0);

	float rotSpeed = rotAmp*nAge;

	o.params.x = lerp(0.5, 1.2, nAge);
	o.params.z = 4 + 2*PI*rotSpeed*(0.8+0.2*rand.y);
	o.speed = speedLifeTime.xyz;
	return o;

	#undef		startPos
	#undef		birthTime	
}

float4x4 billboardOverSpeedCust(float3 pos, float3 speed, float scale) 
{
	float3 speedProjX = mul(speed, (float3x3)gView).xyz;
	speedProjX.z = 0;
	speedProjX = normalize(speedProjX);
	speedProjX.xy *= scale;

	float4x4 M = {
	-speedProjX.y, 0.0, speedProjX.x, 0, 
	0, 1.0, 0, 0.0,
	-speedProjX.x,  0.0, -speedProjX.y, 0, 
	  0,	 0, 0, 1};

	M = mul(M, gViewInv);	
	M[3][0] = pos.x;
	M[3][1] = pos.y;
	M[3][2] = pos.z;
	return M;
}

[maxvertexcount(4)]
void GS_DIRT(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream)
{
	PS_INPUT o;
	
	float4 worldPos = float4(input[0].pos, 1.0);

	float2 sc;
	sincos(input[0].params.z, sc.x, sc.y);
	sc *= input[0].params.x;

	float2x2 M = {
	sc.y, sc.x,
	-sc.x,  sc.y};

	float4x4 BS = billboardOverSpeedCust(input[0].pos, input[0].speed, 1.0);

	for (int ii = 0; ii < 4; ++ii)	
	{
		float4 pos = worldPos;
		float2 resMul = mul(float2(particle[ii].x, 2.0*particle[ii].y), M);

		//float4 billboardedPos = float4(resMul, 0.3, 1.0);
		float4 billboardedPos = float4(resMul, 0.0, 1.0);
		//billboardedPos.y += 0.9;
		//billboardedPos.y += radiusWheel;
		//billboardedPos.y += 0.7;
		//billboardedPos.x -= 0.6;


		//billboardedPos.z -= 5.0;
		billboardedPos = mul(billboardedPos, World);
		//float3 rearrangePos = float3(billboardedPos.y, billboardedPos.x, billboardedPos.z);
		billboardedPos = mul(billboardedPos, BS);
		//billboardedPos.y += 0.7;
		//billboardedPos.x -= 0.6;
		//billboardedPos.z += 1.0;
		//billboardedPos.xyz += input[0].pos;
		o.uv.xy = particle[ii].xy + 0.5;
		o.uv.z = input[0].params.y;
		o.pos = mul( billboardedPos , gViewProj);
		
		outputStream.Append(o);
	}
	outputStream.RestartStrip();  

}

float4 PS_DIRT(PS_INPUT i): SV_Target0
{
	clip(-1);
	float4 clr = tex.Sample(ClampLinearSampler, i.uv.xy).rgba;
	clr = clr*clr;
	clr.a *= i.uv.z;
	clr.rgb *= 0.35*(0.3, 0.3, 0.27);

	return clr;
}

float4 PS_DIRT_FLIR(PS_INPUT i): SV_Target0
{
	clip(-1);
	return float4(1.0, 0.70, 0.40, 0.1);
}

#define PASS_BODY(vs, gs, ps)  { SetVertexShader(vs); SetGeometryShader((gs)); SetPixelShader(ps); \
		SetDepthStencilState(enableDepthBufferNoWrite, 0); \
		SetRasterizerState(cullNone); SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);}

GeometryShader	gsCompiled = CompileShader(gs_5_0, GS_DIRT());
PixelShader		psCompiled = CompileShader(ps_5_0, PS_DIRT());
PixelShader		psCompiledFlir = CompileShader(ps_5_0, PS_DIRT_FLIR());

technique10 carDirt
{
	pass basic				PASS_BODY(CompileShader(vs_5_0, VS_DIRT(false)), gsCompiled, psCompiled)
	pass basicWithClouds	PASS_BODY(CompileShader(vs_5_0, VS_DIRT(true)),  gsCompiled, psCompiled)
	pass flir				PASS_BODY(CompileShader(vs_5_0, VS_DIRT(false)), gsCompiled, psCompiledFlir)

}
