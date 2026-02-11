#include "common/context.hlsl"
#include "common/random.hlsl"
#define USE_PREV_POS 1
#include "ParticleSystem2/common/modelShading.hlsl"
#include "ParticleSystem2/common/quat.hlsl"
#include "ParticleSystem2/common/motion.hlsl"
#include "ParticleSystem2/common/basis.hlsl"
#include "common/platform.hlsl"

struct PushConst {
	uint  instanceIdOffset;
	float globalScale;
	float tauXPreCalc;
	float tauYPreCalc;
	float VtPreCalc;
	float explosionWavePressure;
};
PUSH_CONSTANT_BUFFER(PushConst)

float4	worldOffset;
float4	spreadDir;//xyz - dir, w - power factor
float3 	randomNumbers;
float	weightSpeedY;
float	dt;

static const float time = worldOffset.w;
static const float powerFactor = spreadDir.w;

static const float initialSpeedFactor = 650.0;

struct Instance
{
	float3 pos;
	float scale;
	float massRhoRatio;
	float glueFactor;
	float lifetime;
	float2 rnd;
};
StructuredBuffer<Instance> sbInstanced;

MODEL_PS_INPUT vsDebris(
	in float3 pos: POSITION0,
	in float3 norm: NORMAL0,
	in float4 tangent: NORMAL1,
	in float2 uv: TEXCOORD0,
	in uint instId: SV_InstanceID
)
{
	instId += pushConst.instanceIdOffset;
	const float instanceScale = sbInstanced[instId].scale;
	const float massRhoRatio = sbInstanced[instId].massRhoRatio;
	const float glueFactor = sbInstanced[instId].glueFactor;
	const float2 rnd2 = sbInstanced[instId].rnd;
	const float birthTime = 0;//sbInstanced[instId].birthTime;
	const float age = max(0, time - birthTime);
	const float prevAge = max(age-dt, 0.);

	pos *= instanceScale * pushConst.globalScale;

	//вращение вокруг собственной оси
	float4 rnd4 = noise4(float4(rnd2.x, rnd2.x+1.421312, rnd2.y, rnd2.y+1.6231235))-0.5;
	float freq = 4.0 / (15 * massRhoRatio + 0.5) * exp(-massRhoRatio* age * rnd2.x * 10);
	float4 quat = makeQuat(normalize(rnd4.xyz), 3.1415*(freq*pow(age*2, 0.6) + rnd2.x));
	
	float freqPrev = 4.0 / (15 * massRhoRatio + 0.5) * exp(-massRhoRatio * prevAge * rnd2.x * 10);
	float4 quatPrev = makeQuat(normalize(rnd4.xyz), 3.1415*(freqPrev*pow(prevAge*2, 0.6) + rnd2.x));

	float3 prevPos = qTransform(quatPrev, pos);
	pos = qTransform(quat, pos);

	float3 vel = sbInstanced[instId].pos.xyz+0.5;
	vel += randomNumbers;
	vel = frac(vel);
	
	int2 rndSign;
	if (rnd2.x > 0.5)
		rndSign.x = 1;
	else
		rndSign.x = -1;
	if (rnd2.y > 0.5)
		rndSign.y = 1;
	else
		rndSign.y = -1;

	vel = noise3(vel) / 300.0;
	vel.xz *= rndSign;
	vel.y = abs(vel.y)*(1.8+weightSpeedY);
	vel.xz *= max((1.0-weightSpeedY*0.6), 0.3);

	//переводим ее в МСК
	float3x3 mWorld = basis(spreadDir.xyz);
	vel = mul(vel, mWorld);

// выкладки из DCSCORE-10608:
	float v0 = calcStartVelocityAfterExplosion(pushConst.explosionWavePressure, massRhoRatio, instanceScale, glueFactor);// коэффициент начальной скорости
	float3 Vstart = vel * (v0 * powerFactor * initialSpeedFactor);
	
	float Vt = sqrt(pushConst.VtPreCalc / massRhoRatio);
	float tauX = pushConst.tauXPreCalc / (massRhoRatio * massRhoRatio);
	float tauY = pushConst.tauYPreCalc * tauX;

	float3 trans = calcTranslationWithAirResistanceV2(Vstart, age, Vt, tauX, tauY);

	float3 prevTrans = calcTranslationWithAirResistanceV2(Vstart, prevAge, Vt, tauX, tauY);
	
	//базис вдоль мирового вектора скорости
	// float3x3 mVel = basis((trans1-trans0));
	// pos.y *= 1 + min( 1, distance(trans0, trans1));
	// pos = mul(pos, mVel);
	
	//ставим на стартовую позицию
	pos += sbInstanced[instId].pos*4;
	prevPos += sbInstanced[instId].pos*4;
	
	MODEL_PS_INPUT o;
	o.wPos.w = saturate(3 -  3 * time / (sbInstanced[instId].lifetime * (0.3+0.7*powerFactor)));
	o.wPos.xyz = pos - worldOffset.xyz + trans;
	o.pos = o.projPos = mul(float4(o.wPos.xyz, 1), gViewProj);
	o.prevProjPos = mul(mul(float4(prevPos - worldOffset.xyz + prevTrans, 1), gViewProj), 
						gPrevFrameTransform);
	// norm = mul(norm, mWorld);
	o.normal = qTransform(quat, norm);
	o.tangent = qTransform(quat, tangent.xyz);
	o.uv = uv;
	return o;
}

technique10 tech
{
	pass diffSpec
	{
		SetVertexShader(CompileShader(vs_5_0, vsDebris()));
		SetHullShader(NULL);
		SetDomainShader(NULL);
		SetGeometryShader(NULL);
		SetComputeShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, psModel(MAT_FLAGS_ALL_MAPS)));
		
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
	}
}
