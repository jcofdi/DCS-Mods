#include "common/States11.hlsl"
#include "common/Samplers11.hlsl"

#define M_RBM	0 
#define M_DBS	1
#define M_RMAP	3
#define M_TPM	4
#define M_TA	5

Texture2D	src;
Texture2D<float>	srcDepth;
Texture2DArray<float>	shadowmap;

cbuffer cbUniforms {
	float4x4 viewProjInv;
	float4x4 shadowmapProj[3];
	float4x4 rotMatrix;
	float4x4 sampleMatrix;

	float3 radarPos;
	float scanDir;

	float3 radarDir;
	uint quant;

	float3 radarOrigin;
	float offsetBlur;

	float3 aircraftDir;
	float _dummy0;

	float3 aircraftVel;
	float _dummy1;

	float4 color;
	float4 params, params2, scanCut;
};

struct VS_OUTPUT {
	float4 pos:	SV_POSITION0;
	float2 projPos:	TEXCOORD0;
	float2 uv:	TEXCOORD1;
};

static const float2 quad[4] = {
    float2(-1, -1), 
    float2( 1, -1), 
    float2(-1,  1), 
    float2( 1,  1), 
};

VS_OUTPUT VS(uint vid: SV_VertexID) {
	VS_OUTPUT o;
	o.projPos = quad[vid];
	o.pos = float4(o.projPos, 0, 1);
	o.uv = float2(o.projPos.x*0.5 + 0.5, -o.projPos.y*0.5 + 0.5);
	return o;
}

VS_OUTPUT VS_ROT(uint vid: SV_VertexID) {
	VS_OUTPUT o;
	o.projPos = quad[vid]*2;
	o.pos = mul(float4(o.projPos, 0, 1), rotMatrix);
	o.uv = float2(o.projPos.x*0.5 + 0.5, -o.projPos.y*0.5 + 0.5);
	return o;
}

float gaussian(float x, float s) {
	return exp(-x*x /(2*s*s));
}

float rpRBM(float x, float s) {
	float xx = x / s;
	return max(0, sqrt(1 - xx * xx * 0.8));
}

float rpDBS(float x, float s) {
	float xx = x * 17 / s;
	return max(0, sin(xx) / xx);
}

float compensationRadarValue(float p, float3 wpos) {						// ideal compensation, it can be different on real radars
	float3 V = radarPos - float3(wpos.x, -radarOrigin.y, wpos.z);
	float R = length(V);
	V /= R;
	R *= 0.001;
	return p * pow(R, 3) / V.y;
}

float blur(float2 uv, float sigma, float2 offset, uniform uint KERNEL_SIZE) {

	float sw = 1; // gaussian(0, sigma);
	float acc = src.SampleLevel(gBilinearClampSampler, uv, 0).x * sw;
	[unroll(KERNEL_SIZE)]
	for (uint k = 1; k <= KERNEL_SIZE; ++k) {
		float w = gaussian(k, sigma);
		sw += 2 * w;
		acc += (src.SampleLevel(gBilinearClampSampler, uv + offset * k, 0).x + src.SampleLevel(gBilinearClampSampler, uv - offset * k, 0).x) * w;
	}
	return acc / sw;
}

#define PI 3.1415926535897932384626433832795

float2 blurRadial(float2 uv, float2 originUV, float angle, float sigma, uniform uint KERNEL_SIZE, uniform uint radiationPattern) {
	float2 s0 = src.SampleLevel(gBilinearClampSampler, uv, 0).xy;

	float sw = 1; // gaussian(0, sigma);
	float acc = s0.x * sw;
	[unroll(KERNEL_SIZE)]
	for (uint k = 1; k <= KERNEL_SIZE; ++k) {
		float s, c;
		sincos(k*(angle / KERNEL_SIZE * 0.5 / 180*PI), s, c);	// 3.3 degree
		float2x2 mr = { c,-s,
					    s, c };
		float2 p = uv - originUV;
		float2 delta = mul(p, mr) - p;

		float w = 0;
		switch (radiationPattern) {
		case M_RBM:
			w = rpRBM(k, sigma*KERNEL_SIZE);
			break;
		case M_DBS:
			w = rpDBS(k, sigma*KERNEL_SIZE);
			break;
		default:
			w = gaussian(k, sigma*KERNEL_SIZE);
			break;
		}

		sw += 2 * w;
		acc += (src.SampleLevel(gTrilinearClampSampler, uv + delta, 0).x + src.SampleLevel(gTrilinearClampSampler, uv - delta, 0).x) * w;
	}
	return float2(acc / sw, s0.y);
}

float2 blurRadialDBS(VS_OUTPUT i, float2 originUV, float angle, float resolution, float omega, float cosBlankAngle, uniform uint KERNEL_SIZE) {

	float2 uv = i.uv;
	float depth = srcDepth.Load(uint3(i.pos.xy, 0)).x;
	float4 wpos = mul(float4(i.projPos, depth, 1), viewProjInv);	// restore world position
	float2 vXZ = normalize(wpos.xz / wpos.w - radarPos.xz);
	float lengthAircraftVelXZ = length(aircraftVel.xz);

	const float lambda = 0.03;
	const float teta = angle / 180 * PI;
	float teta_dopler = acos(saturate(lambda / (2 * lengthAircraftVelXZ) * (2 * dot(aircraftVel.xz, vXZ) / lambda + omega / teta))-1e-7) * 2;

//	return teta_dopler*0.5;

	float2 s0 = src.SampleLevel(gBilinearClampSampler, uv, 0).xy;
	float sw = 1; 
	float acc = s0.x * sw;
	[unroll(KERNEL_SIZE)]
	for (uint k = 1; k <= KERNEL_SIZE; ++k) {
		float s, c;
		sincos(k*(teta * 0.5 / KERNEL_SIZE), s, c);	
		float2x2 mr = { c,-s,
						s, c };
		float2 p = uv - originUV;
		float2 delta = mul(p, mr) - p;

		float x = k * teta_dopler / KERNEL_SIZE * resolution * 0.5;	
		float w = sin(x) / x;

		sw += 2 * w;
		acc += (src.SampleLevel(gTrilinearClampSampler, uv + delta, 0).x + src.SampleLevel(gTrilinearClampSampler, uv - delta, 0).x) * w;
	}

	float result = 	max(0, acc / sw);
//	result *= 1 - (1 - step(dot(aircraftVel.xz / lengthAircraftVelXZ, vXZ), cosBlankAngle)) * 0.9;
	result *= step(dot(aircraftVel.xz / lengthAircraftVelXZ, vXZ), cosBlankAngle);

	return float2(result, s0.y);
}

float quantize(float x, uniform uint levels) {
	return round(x*levels) / levels;
}

float calcShadow(float4 wpos, uint idx) {
	float4 smPos = mul(wpos, shadowmapProj[idx]);
	smPos.xyz /= smPos.w;
	float shadow = shadowmap.SampleCmpLevelZero(gCascadeShadowSampler, float3(smPos.xy, idx), saturate(smPos.z));
	return lerp(1, shadow, smPos.z > 0);
}

float4 PS_SOURCE(VS_OUTPUT input, uniform uint shadowmapCount, uniform int mode): SV_TARGET0 {
	float val = src.Load(uint3(input.pos.xy, 0)).x;

	float depth = srcDepth.Load(uint3(input.pos.xy, 0)).x;
	float4 wpos = mul(float4(input.projPos, depth, 1), viewProjInv);

	wpos /= wpos.w;
	float dist = length(wpos.xz - radarPos.xz);

	if (dist > params[0] || dist < params[1])
		discard;

	float3 vd = radarPos - wpos.xyz;
	
	float2 p = normalize(input.projPos - float2(0, -(1+offsetBlur*2)));
	float d1 = dot(scanCut.xy, p);
	float d2 = dot(scanCut.zw, p);

	if (scanCut.x < 1e-3 ? (d2 > 0 || d1 > 0) : (d2 > 0 && d1 > 0) )
		discard;

	float shadow = 1.0;
	[unroll]
	for (uint i = 0; i < shadowmapCount; ++i)
		shadow = min(shadow, calcShadow(wpos, i));

	if (mode == M_TPM) {
		float dist = distance(radarPos, wpos.xyz);
		float dy = wpos.y - radarPos.y;
		uint deadSpace = (dy / dist > params2.x) || (dy / dist < params2.y) || (shadow < 0.1);
		uint hazard = dy + params2.z > 0;
		uint potentiallyHazard = dy + params2.z + params2.w > 0;
		
		const float color[4] = { 0, 0.2, 1.0, 0.5 };
		uint c = max(deadSpace * 3, hazard + potentiallyHazard);

		return float4(color[c], 0, 0, 1);
		
	} else if (mode == M_TA) {
		if(shadow < 0.1)
			return 0;
		
		float3 bn = cross(radarDir, params2.xyz);
		vd -= bn * dot(bn, vd);
		float3 v = normalize(vd);
		
		float dd = dot(vd, params2.xyz);
		bool in_angle = abs(dot(v, params2.xyz)) < 0.05233595624; // sin(+/-3 degrees)
		
		uint hazard = dd < 0 && in_angle;
		uint potentiallyHazard = dd < params2.w && in_angle;

		const float color[3] = { 0, 0.2, 1.0 };
		uint c = potentiallyHazard + hazard;
		return float4(color[c], 0, 0, 1);
		
	} else {
		float3 v = normalize(vd);

		float2 v0 = float2(sqrt(1 - params2[0] * params2[0]), params2[0]);
	//	float2 vp = float2(sqrt(1 - v.y * v.y)*sign(dot(aircraftDir.xz, -v.xz)), v.y);
		float2 vp = float2(sqrt(1 - v.y * v.y), v.y);
		float dotV = dot(v0, vp);
		float mulp = v.y >= params2[0];
		float rp = mulp * max(0, sin(2.29 * pow(acos(max(0, 1 - (1 - dotV) * params2[1])), 0.7))); // vertical radiation pattern 
	//	float rp = mulp * max(0, sin(2.29 * pow(acos(dot(v0, vp)), 0.7))); // vertical radiation pattern 90 degrees
	//	float rp = mulp * pow(max(0, sin(dot(v0, vp) * PI)), 0.1);	// some test

		if (mode == M_RMAP)	{
			rp = sqrt(rp);
		}

		val *= rp;
		val = compensationRadarValue(val, wpos.xyz);
		val *= shadow;
	
		if (mode == M_RMAP)	{
			float vv = 1 - (1 - dotV) * params2[1];
			float m[2] = { vv > params2[2], mulp };
			rp = m[uint(scanDir + 1) / 2];
		}
	
		return float4(val, rp, 0, 1);
	}
}

float4 PS_BLUR_RADIAL(VS_OUTPUT i, uniform uint radiationPattern) : SV_TARGET0 {
	return float4(blurRadial(i.uv, float2(0.5, 1 + offsetBlur), params.x, 1, 10, radiationPattern), 0, 1);
}

float4 PS_BLUR_RADIAL_DBS(VS_OUTPUT i) : SV_TARGET0 {
	return float4(blurRadialDBS(i, float2(0.5, 1 + offsetBlur), params.x, params.y, params.z, params2.x, 10), 0, 1);
}

float sigmoid(float x, float k) {
	x = 0.5 - x;
	float s = sign(x);
	x = saturate(abs(x) * 2.0);
	return s * x / (x * (k - 1.0) - k) * 0.5 + 0.5;
}

float exp_saturate(float x, float k) {
	float kx = k * x;
	return (x + kx) / (kx + 1.0);
}

float4 PS_FINAL(VS_OUTPUT i, uniform bool useQuantization) : SV_TARGET0 {
	float3 val = src.SampleLevel(gTrilinearClampSampler, i.uv, 0).xyz;

	val.x = exp_saturate(val.x, 1);

	val.x = val.x * params.x * 2;
//	val = sigmoid(val, 1.0 / (params.x + 0.00000001) - 1);	// contrast

	if(useQuantization)
		val.x = quantize(val.x, quant-1);

	return float4(color.xyz * (val.x + val.y), val.z);
}

float4 PS_FINAL_TPM(VS_OUTPUT i) : SV_TARGET0 {
	float3 val = src.SampleLevel(gTrilinearClampSampler, i.uv, 0).xyz;
	val.x = val.x * params.x * 2;
	return float4(color.xyz * val.x, 1);
}

float4 PS_SCAN(VS_OUTPUT i, uniform bool useRotate) : SV_TARGET0 {
	float2 p0 = i.projPos - float2(0, -(1 + params.w * 2));
	float2 p = normalize(p0);

	if(useRotate)
		p = mul(p, (float2x2)rotMatrix);

	float d0 = dot(params.xy, p) * params.z;
	float d1 = p.x * params.z * (params.y * params.z > 0);

//	if (dot(float2(-params.y, params.x), p) > 0.999) return float4(0, 1, 0, 1);	// check scanline
//	return float4(d0 > 0 || d1 > 0 ? 0 : 1, 0, 0, 1);	// check clipping

	if (d0 > 0 || d1 > 0)
		discard;

	float2 val = src.SampleLevel(gTrilinearBlackBorderSampler, i.uv, 0).xy;

#if 1
	#if 1
		float grad = length(p0) * 0.5 / (1 + params.w);		// grad - normalized distance
	#else
		float grad = (length(p0) - params.w * 2) * 0.5;
	#endif
	float footprint = (grad * grad) * val.y * params2.y * (0.5 + (1 - params.z)*0.25);	// val.y - vertical radiation pattern, params2.y - footprint intensity, params.z - scan direction
#else
	float d1 = dot(float2(-params.y, params.x), p);
	float footprint = val.y * params2.y * saturate(d1*0.5+0.5);	// bright scanline
//	float footprint = val.y * params2.y * smoothstep(params2.x, 1, d1);	
#endif	
	return float4(val.x, footprint, 1, 1);
}

float4 PS_SCAN_RMAP(VS_OUTPUT i) : SV_TARGET0
{
	if (i.projPos.x * params.w * 0.5 + 0.5 > params.z)
		discard;
//		return float4(1, 0, 0, 1);

	float dist = (i.projPos.y * 0.5 + 0.5) * (params.y - params.x) + params.x;
	
	float a = i.projPos.x * params2.x;
	float s, c;
	sincos(a, s, c);
	float2 uv = mul(float4(s * dist, c * dist, 0, 1), sampleMatrix).xy;
	
	float2 val = src.SampleLevel(gTrilinearBlackBorderSampler, uv, 0).xy;
	
//	if (val.y * params.w > 0)	// scan split, param.w scanDir
//		discard;

	if (val.y == 0)	// scan split, param.w scanDir
		discard;
	
	return float4(val.x, 0, 1, 1);
}

float4 PS_CLEAR() : SV_TARGET0 {
	return 0;
}

BlendState clearB {
	BlendEnable[0] = FALSE;
	RenderTargetWriteMask[0] = 0x4;
};


#define END_PASS 		SetComputeShader(NULL); \
						SetGeometryShader(NULL); \
						SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF); \
						SetDepthStencilState(disableDepthBuffer, 0); \
						SetRasterizerState(cullNone);

VertexShader vs = CompileShader(vs_5_0, VS());
PixelShader psFinal = CompileShader(ps_5_0, PS_FINAL(true));

technique10 Radar {
	pass P0 {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(1, M_RBM)));
		END_PASS
	}
	pass P1 {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(2, M_RBM)));
		END_PASS
	}
	pass P2 {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(3, M_RBM)));
		END_PASS
	}
	pass P3	{
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(1, M_RMAP)));
		END_PASS
	}
	pass P4	{
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(1, M_TPM)));
		END_PASS
	}
	pass P5	{
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(2, M_TPM)));
		END_PASS
	}
	pass P6	{
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SOURCE(1, M_TA)));
		END_PASS
	}

	pass P7_BLUR_RADIAL_RBM {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_BLUR_RADIAL(M_RBM)));
		END_PASS
	}
	pass P8_BLUR_RADIAL_DBS {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_BLUR_RADIAL_DBS()));
		END_PASS
	}

	pass P9_RBM {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SCAN(false)));
		END_PASS
	}
	pass P10_DBS {
		SetVertexShader(CompileShader(vs_5_0, VS_ROT()));
		SetPixelShader(CompileShader(ps_5_0, PS_SCAN(true)));
		END_PASS
	}
	pass P11_RMAP {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_SCAN_RMAP()));
		END_PASS
	}

	pass P12_FINAL {
		SetVertexShader(vs);
		SetPixelShader(psFinal);
		END_PASS
	}
	pass P13_FINAL_TPM {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_FINAL_TPM()));
		END_PASS
	}

	pass P14_CLEAR {
		SetVertexShader(vs);
		SetPixelShader(CompileShader(ps_5_0, PS_CLEAR()));
		SetComputeShader(NULL); 
		SetGeometryShader(NULL);
		SetBlendState(clearB, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(disableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
}


