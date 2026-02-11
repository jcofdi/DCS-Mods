#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/ambientCube.hlsl"
#include "common/shadingCommon.hlsl"
#include "common/random.hlsl"
#include "common/stencil.hlsl"
#include "enlight/materialParams.hlsl"
#include "common/softParticles.hlsl"
#include "common/fog2.hlsl"
//#include "common/dithering.hlsl"
#define CLOUDS_COLOR
#define ATMOSPHERE_COLOR
#include "ParticleSystem2/common/psCommon.hlsl"

// #define ENABLE_GPU_DEBUG_DRAW
//#include "common/debugDraw.hlsl"

// #define DEBUG_NO_DENSITY_SAMPLING

#ifdef MSAA
	Texture2DMS<float, MSAA> depthMap;
#else
	Texture2D<float> depthMap;
#endif

Texture3D<float>	volumeSRC;
RWTexture3D<float>	volumeDST;

float4		radianceRadius;
float4 		multiSingleShadowDensity;
float3		eyePosLocal;
// float		ditheringFactor;
float4x4	world;
float4x4	worldInv;

#define gLightRadiance 		radianceRadius.xyz
#define gRadius 			radianceRadius.w

#define gMultipleScattering multiSingleShadowDensity.x
#define gSingleScattering 	multiSingleShadowDensity.y
#define gShadowBias 		multiSingleShadowDensity.z
#define gDensityFactor		multiSingleShadowDensity.w

struct VS_OUTPUT
{
	float4 pos: SV_POSITION0;
	float3 posW: POSITION1;
	float4 clipPos: POSITION2;
	float  density: POSITION3;
};

float sampleCloudsDensity(float3 pos)
{
	float3 uvw = pos * gCloudVolumeScale + gCloudVolumeOffset;
	float2 s = cloudsDensityMap.SampleLevel(gBilinearClampSampler, uvw.xzy, 0).xy;
	s.y *= s.y;
	float densityGrad = s.x * 2 - 1;
	float shapeSignal = saturate(densityGrad * 3 + 0.1);
	float density = shapeSignal * 0.05 * s.y;
	return max(0.0, density);
}

float sampleFogDensity(float3 pos)
{
	float3 rayOriginKm = WorldSpaceToEarthSpace(pos + gOrigin);
	float3 rayDirection = float3(0.0, 1.0, 0.0);
	float distanceKm = 0.025f;// to calculate average density

	float density = getSphericalFogDensity(rayOriginKm, rayDirection, distanceKm);
	return density / (distanceKm) * 0.002;
}

VS_OUTPUT vs(float3 pos: POSITION0)
{
	VS_OUTPUT o;
#ifndef DEBUG_NO_DENSITY_SAMPLING
	o.density = sampleCloudsDensity(worldOffset);
	o.density += sampleFogDensity(worldOffset);
	o.density *= gDensityFactor * 1.25;
#else
	o.density = 0.05 * gDensityFactor * 1.25;
#endif

	if (o.density <= 0.0f)
	{
		// Degenerate triangles
		o.posW = o.clipPos = o.pos = 0.0f;
		return o;
	}

#if 1
	float3 pW = mul(float4(pos, 1), world).xyz;
#else
	float radius = gRadius*1.1; // enlarge radius to mitigate proxy geometry size == radius
	float3 pL = pos.xyz*radius;
	float3 pW = pL+worldOffset;
#endif

	o.posW = pW;
	o.clipPos = mul(float4(pW, 1), gViewProj);
	o.pos = o.clipPos;

	return o;
}

float inverseLerp(float v, float s, float e)
{
	return saturate((v - s) / (e - s));
}

// sphere of size ra centered at point ce
float2 sphIntersect(in float3 ro, in float3 rd, in float3 ce, float ra)
{
	float3 oc = ro - ce;
	float b = dot(oc, rd);
	float c = dot(oc, oc) - ra * ra;
	float h = b * b - c;
	if (h < 0.0)
		return -1.0; // no intersection
	h = sqrt(h);
	return float2(-b - h, -b + h);
}
/*
 Alternative method computes h (the squared distance from the closest ray point to the sphere, qc below)
 with a projection rather than by using Pythagoras' theorem.
 This is less precision hungry because we don't generate large numbers
 (in comparison to the size of the sphere) since we don't square triangle edges (b*b):
*/

// sphere of size ra centered at point ce
float2 sphIntersect2(in float3 ro, in float3 rd, in float3 ce, float ra)
{
    float3 oc = ro - ce;
    float b = dot( oc, rd );
    float3 qc = oc - b * rd;
    float h = ra * ra - dot(qc, qc);
    if (h<0.0)
		return -1.0.xx; // no intersection
    h = sqrt(h);
    return float2(-b-h, -b+h);
}

static float simRadius = 3;

float2 singleScatteringHomogenousSphere(uint3 dtid, float cosAlpha, float density, float depth=1.0)
{
	const uint NSAMPLES = 500;
	const uint NSAMPLES_MAX = 500;

	float3 pos = float3(1.0, 0.0, 0.0) * simRadius;

	float3 dir = -float3(cosAlpha, sqrt(1.0 - cosAlpha*cosAlpha), 0.0);
	dir = normalize(dir);
	float2 t = sphIntersect2(pos, dir, float3(0.0f, 0.0f, 0.0f), 1.0*simRadius);

	float3 start = t.x * dir + pos;
	float3 end = t.y * dir + pos;
	end = (end - start) * depth + start;

	uint nSamples = NSAMPLES_MAX * (0.4 + 0.6 * depth);

	float3 step = (end - start) / float(nSamples);
	float3 samplePos = start;
	float stepSize = length(step);
	float inScattered = 0.0;
	float distanceTravelled = 0.0;
	for(uint i = 0; i < nSamples; i++)
	{
		float l = length(samplePos);
		float li = exp(-density * l) / (l * l); //incoming point light

		float l2 = pow(l, 1.2);
		float li2 = exp(-density * l) / (l2 * l2); //incoming inscattered light

		//clamp infinity
		{
			const float li2Max = 0.3;
			const float li2Factor = 7;
			li2 *= 1.0 / li2Factor;
			if(li2>li2Max)//li2 is increasing linearly until reaches li2Max
				li2 = (li2Max + 1) - exp(li2Max - li2);
			li2 *= li2Factor;
		}

		float light = li * gSingleScattering;
		light += li2 * gMultipleScattering * 0.9;// multiple scattering (типа)

		inScattered += light * exp(-distanceTravelled*density);
		distanceTravelled += stepSize;
		samplePos += step;
	}

	return float2(inScattered * density * stepSize, 1.0);
}

static float densitymin = 0.0;
static float densitymax = 0.05;
static float densityPow = 4;
static float distmin = 0.0;
static float distmax = 1.0;
static float angleFix = 0.9999;// fix for tangent rays near borders

[numthreads(1, 32, 32)]
void CS(uint3 gid: SV_GroupId, uint3 gtid: SV_GroupThreadID, uint3 dtid: SV_DispatchThreadID)
{
    uint3 idx = uint3(gid.x, gtid.y + gid.y * 32, gtid.z);

	float densityrange = densitymax - densitymin;

	float3 uvw = idx / float3(31, 63, 31);

	float density = pow(uvw.x, densityPow) * densityrange + densitymin;
	float angle = asin(pow(uvw.y, 2));
	float cosAngle = cos(angle * angleFix); // fix for tangent rays near borders
	float depth = uvw.z * (distmax - distmin) + distmin;

	volumeDST[idx] = singleScatteringHomogenousSphere(dtid, cosAngle, density, depth).x;
}

float sampleViewDistance(float2 ndcPos)
{
	float2 uv = float2(ndcPos.x, -ndcPos.y) * 0.5 + 0.5;
	float depth = g_DepthTexture.SampleLevel(gPointClampSampler, uv, 0).r;
	float4 p1 = mul(float4(ndcPos.xy, depth, 1), gProjInv);
	return length(p1.xyz / p1.w);
}

// float3 applyDitheringOnLowLuminance(uint2 pixel, float3 color, float lumMaxInv)
// {
// 	float lum = dot(color, 0.333333);
// 	return color * lerp((0.8 + 0.3 * dither_ordered8x8(pixel)), 1, saturate(lum * lumMaxInv));
// }

// #define DEBUG_RT
float4 ps(VS_OUTPUT i): SV_TARGET0
{
	float3 posL = mul(float4(i.posW, 1), worldInv).xyz;
	// float3 eyePosL = mul(float4(gCameraPos.xyz, 1), worldInv).xyz;
	float3 eyePosL = eyePosLocal;
	float3 rayDir = normalize(posL - eyePosL);

	float sRadius = 1/1.1;

	float2 nearFar = sphIntersect2(eyePosL, rayDir, 0, sRadius); // two intersection points on sphere
	if (all(nearFar == -1.0))
		discard;

	// Clamp far plane based on depth
	float3 mediaTransmittance = SamplePrecomputedAtmosphere(0).transmittance;
	if(mediaTransmittance.r < 0.005)
		discard;

	float distToGeometry = sampleViewDistance(i.clipPos.xy / i.clipPos.w);

	float3 p0 = gCameraPos.xyz + normalize(i.posW - gCameraPos.xyz) * distToGeometry;
	distToGeometry = length(mul(float4(p0.xyz, 1), worldInv).xyz - eyePosL);

	// Manual depth test
	if (distToGeometry < nearFar.x)
		discard;

	const bool bInside = nearFar.x < 0;

	nearFar.y = min(nearFar.y, distToGeometry + gRadius * gShadowBias);
	float inscattered;

	// Baked lighting coords calculation and lookup
	float3 intersectionPoint0 = eyePosL + rayDir * nearFar.x;
	float3 intersectionToCenter = normalize( - intersectionPoint0);
	float cosAngle = dot(rayDir, intersectionToCenter);

	float firstSampleDistance = inverseLerp((-nearFar.x) / (2.0 * sRadius), distmin, distmax);
	float secondSampleDistance = inverseLerp((nearFar.y - nearFar.x) / (2.0 * sRadius), distmin, distmax); // how far we travelled?

	float density = pow(inverseLerp(i.density, densitymin, densitymax), 1/densityPow);
	cosAngle *= angleFix;
	float angle = sqrt(sqrt(1.0 - cosAngle * cosAngle)); // sqrt(sin())

	float inscattered0 = volumeSRC.SampleLevel(gBilinearClampSampler, float3(density, angle, firstSampleDistance), 0);
	float inscattered1 = volumeSRC.SampleLevel(gBilinearClampSampler, float3(density, angle, secondSampleDistance), 0);
#ifdef DEBUG_RT
	inscattered0 = singleScatteringHomogenousSphere(cosAngle, i.density, firstSampleDistance).x;
	inscattered1 = singleScatteringHomogenousSphere(cosAngle, i.density, secondSampleDistance).x;
#endif
 	inscattered = inscattered1 - inscattered0;

	float cosThreshold = 0.99;
	float borderAttenuation = (1.0 - saturate(cosThreshold - cosAngle) / cosThreshold);

	float alpha = borderAttenuation;
	float3 color = gLightRadiance * inscattered * mediaTransmittance;

	// if(ditheringFactor>0)
		// color = applyDitheringOnLowLuminance(i.pos.xy, color, 1 / 0.1);

	return float4(color, alpha);
}

RasterizerState cull
{
	CullMode = Back;
	FillMode = Solid;
};

DepthStencilState disableDepthBufferClipCockpit
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
	DepthFunc = GREATER_EQUAL;

	StencilEnable = TRUE;
	StencilReadMask = STENCIL_COMPOSITION_COCKPIT;
	StencilWriteMask = 0;

	FrontFaceStencilFunc = NOT_EQUAL;
	FrontFaceStencilPass = KEEP;
	FrontFaceStencilFail = KEEP;
	BackFaceStencilFunc = NOT_EQUAL;
	BackFaceStencilPass = KEEP;
	BackFaceStencilFail = KEEP;
};

technique10 tech
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, ps()));

		// full shell and manual depth read to find far distance for "marching", but skip cockpit
		SetDepthStencilState(disableDepthBufferClipCockpit, STENCIL_COMPOSITION_COCKPIT);
		//DISABLE_DEPTH_BUFFER;
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		//ENABLE_ALPHA_BLEND;
		SetRasterizerState(cull);
		SetComputeShader(NULL);

	}
}

technique10 bake
{
	pass p0
	{
	 	SetComputeShader(CompileShader(cs_5_0, CS()));
		SetVertexShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(NULL);
	}
}
