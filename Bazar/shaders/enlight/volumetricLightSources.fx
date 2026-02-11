//#define ENABLE_GPU_DEBUG_DRAW
#include "common/debugDraw.hlsl"

#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
#include "common/context.hlsl"
#include "common/stencil.hlsl"
#include "common/fog2.hlsl"
//#include "common/ambientCube.hlsl"
//#include "common/shadingCommon.hlsl"
//#include "common/random.hlsl"
#include "common/lightsCommon.hlsl"
#include "common/atmosphereSamples.hlsl"
#include "common/softParticles.hlsl"
#include "common/quat.hlsl"
#include "enlight/materialParams.hlsl"

#define USE_ANALYTICAL_INTEGRATION 0 // not ready, need energy compensation
#define VISUALIZE_VOLUMES          0

// do raymarching during rendering instead of baked lighting lookup
//#define DEBUG_RAYMARCHING_OMNI

// Main params
float3		worldOffset;
float4		radianceRadius;
float4 		multiSingleShadowDensity;// = float4(1.0, 1.0, 1.0, 0.0);
float3		direction;
float4		angles; // cos(outer), cos(inner), tan(outer), outer
float3		spotBaseEndRadiusMinPhase;

// Params aliases
#define gLightRadiance 	radianceRadius.xyz
#define gRadius 		radianceRadius.w

#define gMultipleScattering multiSingleShadowDensity.x
#define gSingleScattering 	multiSingleShadowDensity.y
#define gShadowBias 		multiSingleShadowDensity.z
#define gDensityFactor		multiSingleShadowDensity.w

//#define gMinimalPhase		0.04
#define gSpotBaseEndRadius	spotBaseEndRadiusMinPhase.xy
#define gMinimalPhase		spotBaseEndRadiusMinPhase.z

// Baked lighting texture
Texture3D<float> volumeSrc;
RWTexture3D<float> volumeDst;

struct OmniLight
{
	float3 pos;
	float radius;
};

struct SpotLight
{
	float3 pos;
	float3 dir;
	float2 angles;  // cos(outer * 0.5), cos(inner * 0.5)
	float2 radius;  // disk radius == base of capped cone
	float distance; // == height of capped cone
};

// -----------------------------------------------------------------------------
// Bounding Boxes
// https://iquilezles.org/articles/diskbbox/
// https://stackoverflow.com/questions/64687380/bounding-box-of-spherical-sector-cone-sphere-intersection
// -----------------------------------------------------------------------------

struct Bounds
{
	float3 a;
	float3 b;
};

// bounding box for a cylinder defined by points pa and pb, and a radius ra
Bounds CylinderAABB(in float3 pa, in float3 pb, in float ra)
{
	float3 a = pb - pa;
	float3 e = ra * sqrt(1.0 - a * a / dot(a, a));

	Bounds bb;
	bb.a = min(pa - e, pb - e);
	bb.b = max(pa + e, pb + e);
	return bb;
}

// bounding box for a cone defined by points pa and pb, and radii ra and rb
Bounds CappedConeAABB(in float3 pa, in float3 pb, in float ra, in float rb)
{
	float3 a = pb - pa;
	float3 e = sqrt(1.0 - a * a / dot(a, a));

	Bounds bb;
	bb.a = min(pa - e * ra, pb - e * rb);
	bb.b = max(pa + e * ra, pb + e * rb);
	return bb;
}

Bounds spotBounds(in SpotLight spot)
{
	// TODO: try exact aabb contruction for spherical sector https://stackoverflow.com/questions/64687380/bounding-box-of-spherical-sector-cone-sphere-intersection
#if 1
	// Spot geometry is capped cone with sphere
	// Merge two bounding boxes (one for cylynder, one for cone)
	float3 start = spot.pos;
	float distanceToSphereCap = angles.x * spot.distance;
	float sphereCapIntersectionRadius = angles.z * distanceToSphereCap;
	float3 capOrigin = spot.pos + spot.dir * distanceToSphereCap;
	float3 end = spot.pos + spot.dir * spot.distance;

	Bounds bbCap = CylinderAABB(capOrigin, end, sphereCapIntersectionRadius);
	Bounds bbCone = CappedConeAABB(start, capOrigin, spot.radius.x, sphereCapIntersectionRadius);
	Bounds res;
	res.a = min(bbCap.a, bbCone.a);
	res.b = max(bbCap.b, bbCone.b);
	return res;
#else
	// Faster, but coarser
	float3 end = spot.pos + spot.dir * spot.distance;
	Bounds res = CappedConeAABB(spot.pos, end, spot.radius.x, spot.radius.y);
	// Find intersection with sphere AABB
	res.a = max(res.a, spot.pos - spot.distance);
	res.b = min(res.b, spot.pos + spot.distance);
	return res;
#endif
}


struct VS_OUTPUT
{
	float4 pos: SV_POSITION0;
	float3 posW: POSITION1;
	float4 clipPos: POSITION2;
	float  density: POSITION3;
};

static float densitymin = 0.0;
static float densitymax = 0.05;
static float densityPow = 4;
static float distmin = 0.0;
static float distmax = 1.0;
static float angleFix = 0.9999;// fix for tangent rays near borders

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
	float distanceKm = 0.025f; // to calculate average density

	float opticalDepth = gFogParams.sigmaExtinction * getSphericalFogDensity(rayOriginKm, rayDirection, distanceKm);
	return 0.02f * opticalDepth / distanceKm;
}

VS_OUTPUT vs(float3 pos: POSITION0, uint vertId: SV_VertexId)
{
	VS_OUTPUT o;
	o.density = sampleCloudsDensity(worldOffset);
	o.density += sampleFogDensity(worldOffset);
	o.density *= gDensityFactor;

	float radius = gRadius * 1.1; // enlarge radius to mitigate proxy geometry size == radius

	if (o.density <= 0.0f)
	{
		// Degenerate triangles
		o.posW = o.clipPos = o.pos = 0.0f;
		return o;
	}

	float3 pL = pos.xyz * radius;
	float3 pW = pL + worldOffset;

	o.posW = pW;
	o.clipPos = mul(float4(pW, 1), gViewProj);
	o.pos = o.clipPos;

	return o;
}


float3 orthogonal(float3 v)
{
	return normalize(cross(v, float3(-v.z, v.x, v.y)));
}

// 'from' and 'to' directions must be normalized!
float4 makeQuatFromTo(float3 from, float3 to)
{
	float kCosTheta = dot(from, to);
	float k = sqrt(dot(from, from) * dot(to, to));

	if (kCosTheta / k == -1.0f)
	{
		// 180 degree rotation around any orthogonal vector
		return float4(normalize(orthogonal(from)), 0.0);
	}
	return normalize(float4(cross(from, to), kCosTheta + k));
}

/*
	Cube geometry, 14 vertices, triangle-strip
	https://twitter.com/vassvik/status/1730961936794161579
	https://twitter.com/Donzanoid/status/616370134278606848
*/
float3 generateCubeVerticesTriangleStrip(uint vertId)
{
	/*
		0x287A == 0b0010100001111010
		0x02AF == 0b0000001010101111
		0x32E3 == 0b0011001011100011
	*/
	const uint bit = (1 << vertId);
	return float3(bool3(uint3(0x287Au, 0x02AFu, 0x31E3u) & bit));
}

VS_OUTPUT vsSpotBounds(uint vertId: SV_VertexId)
{
	VS_OUTPUT o;

	o.density = sampleCloudsDensity(worldOffset);
	o.density += sampleFogDensity(worldOffset);
	o.density *= gDensityFactor;

	if (o.density <= 0.0f)
	{
		// Degenerate triangles
		o.posW = o.clipPos = o.pos = 0.0f;
		return o;
	}

	float3 localPos = generateCubeVerticesTriangleStrip(vertId);

#if 1
	{
		// Oriented Bounding Volume
		float distanceToSphericalSector = angles.x * gRadius;
		float sphericalSectorRadius = angles.z * distanceToSphericalSector;
		// Switch between tight volume and OBB variants based on Spot outer angle cosine
		float radius = angles.x < 0.5 ? sphericalSectorRadius :
			(localPos.x == 0.0f ? gSpotBaseEndRadius.x : gSpotBaseEndRadius.y);
		float3 boxDimensions = float3(gRadius, radius, radius);
		float4 quat = makeQuatFromTo(float3(1.0, 0.0, 0.0), direction);

		localPos.yz = localPos.yz * 2.0 - 1.0;
		localPos *= boxDimensions;
		localPos = mulQuatVec3(quat, localPos);
	}
#else
	{
		// Axis-Aligned Bounding Box
		SpotLight spot;
		spot.pos = 0.0.xxx;
		spot.dir = direction;
		spot.distance = gRadius;
		spot.angles = angles.xy;
		spot.radius = gSpotBaseEndRadius;
		Bounds bb = spotBounds(spot);
		localPos = (bb.b + bb.a) * 0.5 + (localPos * 2.0 - 1.0) * (bb.b - bb.a) * 0.5;
	}
#endif

	float3 worldPos = localPos + worldOffset;
	o.posW = worldPos;
	o.clipPos = mul(float4(worldPos, 1), gViewProj);
	o.pos = o.clipPos;

	return o;
}

// -----------------------------------------------------------------------------
// Intersectors
// https://iquilezles.org/articles/intersectors/
// https://www.realtimerendering.com/intersections.html
// https://www.shadertoy.com/view/4s23DR
// https://www.shadertoy.com/view/MtcXWr
// https://lousodrome.net/blog/light/2017/01/03/intersection-of-a-ray-and-a-cone/
// -----------------------------------------------------------------------------

float maxComp(float3 v)
{
	return max(v.x, max(v.y, v.z));
}

float minComp(float2 v)
{
	return min(v.x, v.y);
}

float inverseLerp(float v, float s, float e)
{
	return saturate((v - s) / (e - s));
}

float dot2(in float3 v)
{
	return dot(v, v);
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



// Custom capped cone intersector (based on iCappedCone by IQ: https://www.shadertoy.com/view/llcfRf)
// Returns distances of two intersection points
float2 cappedConeIntersect(in float3 ro, in float3 rd, in float3 pa, in float3 pb, in float ra, in float rb)
{
	const float invalidValue = -12345.0;

    float3 ba = pb - pa;
    float3 oa = ro - pa;
    float3 ob = ro - pb;

    float m0 = dot(ba, ba);
    float m1 = dot(oa, ba); // squared distance to cap a
    float m2 = dot(ob, ba); // squared distance to cap b
    float m3 = dot(rd, ba);

    /// Caps intersection
	float2 caps = float2(-m1 / m3, -m2 / m3); // raw intersection with two cap planes
	bool2 capsValidity = bool2(
		dot2(oa * m3 - rd * m1) <= (ra * ra * m3 * m3),
		dot2(ob * m3 - rd * m2) <= (rb * rb * m3 * m3)
	);
	caps = capsValidity ? caps : invalidValue; // validation

    /// Body intersection
    float rr = ra - rb;
    float hy = m0 + rr * rr;
    float m4 = dot(rd, oa);
    float m5 = dot(oa, oa);

    float k2 = m0 * m0      - m3 * m3 * hy;
    float k1 = m0 * m0 * m4 - m1 * m3 * hy + m0 * ra * (rr * m3 * 1.0          );
    float k0 = m0 * m0 * m5 - m1 * m1 * hy + m0 * ra * (rr * m1 * 2.0 - m0 * ra);

    float h = k1 * k1 - k2 * k0;
    float2 body = float2(
		(-k1 - sqrt(h)) / k2,
		(-k1 + sqrt(h)) / k2
	);
	float2 y = m1 + body * m3;
	bool2 bodyValidity = (0.0 <= y && y <= m0);

	// PRINT_VALUE_LINE(y, {'y',':',' '});
	// PRINT_VALUE_LINE(body, {'b','o','d','y',':',' '});
	// PRINT_VALUE_LINE(bodyValidity ? 1u : 0u, {'b','o','d','y','V','a','l','i','d','i','t','y',':',' '});

	// Crutch to fix missing caps intersections with good enough body intersection
	/*
		Valid intersection count:
		body	caps	result
		 0		 0 		 no intersection
		 0		 1		 must use relaxed validation to gather another intersection
		 0		 2 		 caps only
		 1		 0		 must use relaxed validation to gather another intersection
		 1		 1		 mixed
		 1		 2		 caps only
		 2		 0		 body only
		 2		 1		 body only
		 2		 2		 caps only (preferred as more stable intersection)

		Relaxation applied to body intersection validity because caps intersection is more stable.
	*/
	bool relaxedBodyValidation =
		(!any(bodyValidity) && !all(capsValidity) && any(capsValidity)) ||
		(!any(capsValidity) && !all(bodyValidity) && any(bodyValidity));
	float minimalThreshold = minComp(min(abs(y), abs(y - m0)));
	bodyValidity = relaxedBodyValidation ? (0.0 - minimalThreshold <= y && y <= m0 + minimalThreshold) : bodyValidity;

	body = bodyValidity ? body : invalidValue; // validation

	// PRINT_VALUE_LINE(relaxedBodyValidation ? 1u : 0u, {'r','e','l','a','x','e','d',':',' '});
	// PRINT_VALUE_LINE(bodyValidity ? 1u : 0u, {'b','o','d','y','V','a','l','i','d','i','t','y',':',' '});
	// PRINT_VALUE_LINE(body, {'b','o','d','y',':',' '});

	const bool allCapsValid = all(capsValidity);
	const bool allBodyValid = all(bodyValidity);
	const bool mixed = !allCapsValid && !allBodyValid;

	float2 ts = mixed ?
		float2(
			bodyValidity.x ? body.x : body.y,
			capsValidity.x ? caps.x : caps.y) :
		allCapsValid ? caps : body;
	ts = ts.x < ts.y ? ts.xy : ts.yx; // final sorting
	// PRINT_VALUE_LINE(ts, {'t','s',':',' '});
	ts = any(ts == invalidValue) ? invalidValue.xx : ts;
	return ts;
}


float2 cappedConeIntersect(in SpotLight spot, in float3 ro, in float3 rd)
{
	return cappedConeIntersect(ro, rd, spot.pos, spot.pos + spot.dir * spot.distance, spot.radius.x, spot.radius.y);
}

float2 cappedConeWithSphereIntersect(in SpotLight spot, in float3 ro, in float3 rd)
{
	float2 tCone = cappedConeIntersect(ro, rd, spot.pos, spot.pos + spot.dir * spot.distance, spot.radius.x, spot.radius.y);
	float2 tSphere = sphIntersect2(ro, rd, spot.pos, spot.distance);

	//PRINT_VALUE_LINE(tCone, {'t','C','o','n','e',':',' '});
	//PRINT_VALUE_LINE(tSphere, {'t','S','p','h','e','r','e',':',' '});

	float2 res = float2(max(tCone.x, tSphere.x), min(tCone.y, tSphere.y));
	res = res.x < res.y ? res : -1.0.xx;
	return res;
}

// -----------------------------------------------------------------------------
// Raymarching
// -----------------------------------------------------------------------------

static float simRadius = 1;


float phaseFunctionUniform()
{
	const float pi = 3.14159265;
	return 1.0 / (4.0 * pi);
}

float phaseFunc_HenyeyGreenstein(float mu, float g)
{
	const float M_PI = 3.14159265;
	return 1.0 / (4.0 * M_PI) * (1.0 - g*g) * pow( abs(1.0 + (g*g) - 2.0*g*mu ), -3.0/2.0);
}

//https://www.shadertoy.com/view/tdcBDj
float numericalMieFit(float costh)
{
	float bestParams[10];
	bestParams[0]=9.805233e-06;
	bestParams[1]=-6.500000e+01;
	bestParams[2]=-5.500000e+01;
	bestParams[3]=8.194068e-01;
	bestParams[4]=1.388198e-01;
	bestParams[5]=-8.370334e+01;
	bestParams[6]=7.810083e+00;
	bestParams[7]=2.054747e-03;
	bestParams[8]=2.600563e-02;
	bestParams[9]=-4.552125e-12;

	float p1 = costh + bestParams[3];
	float4 expValues = exp(float4(bestParams[1] *costh+bestParams[2], bestParams[5] *p1*p1, bestParams[6] *costh, bestParams[9] *costh));
	float4 expValWeight= float4(bestParams[0], bestParams[4], bestParams[7], bestParams[8]);

	float x = 1.0 - saturate((1.0 - costh) / 0.04);

	return dot(expValues, expValWeight) * 0.25 + 2.7 * ((x*x)*(x*x));
}

float applyMiePhase(float3 lightDir, float3 ray)
{
	float mu = dot(lightDir, ray);
	return numericalMieFit(mu);
}

float applyMiePhaseIsotropic(float3 lightDir, float3 ray)
{
	float mu = dot(lightDir, ray);

	const float Gfront = 0.6;
	const float Gback = 0.5;
	const float lf = 0.7;
	return 1.0*lerp(0.5*phaseFunc_HenyeyGreenstein(mu, -Gback), 1.5*phaseFunc_HenyeyGreenstein(mu, Gfront), lf)-0.02;
}

void getParticipatingMedia(in SpotLight spot, in float3 pos, out float sigmaScattering, out float sigmaExtinction)
{
	const float fogScattering = 0.02f;
	const float fogAbsorbtion = 0.013f;
	sigmaScattering = fogScattering;
	sigmaExtinction = max(0.00001, fogScattering + fogAbsorbtion);
}

float3 projectOnPlane(float3 v, float3 n)
{
	return v - n * dot(v, n);
}

// Modified version of distAttenuation from lightsCommon.hlsl
float distAttenuationMod(float range, float dist)
{
	dist = max(dist, 0.01);
	float amount = MIN_LIGHT_AMOUNT * range * range;
	return clamp(amount/(dist*dist)-MIN_LIGHT_AMOUNT, 0, 100000); // original clamp value is too low
}

float distAttenuationImpr(float distanceToLight, float lightPhysicalSize)
{
	// Cem Yuksel's improved attenuation avoiding singularity at distance=0
	// Source: http://www.cemyuksel.com/research/pointlightattenuation/
	const float radiusSq = lightPhysicalSize * lightPhysicalSize;
	const float distanceSq = distanceToLight * distanceToLight;
	return 2.0f / (distanceSq + radiusSq + distanceToLight * (sqrt(distanceSq + radiusSq)));
}

float spotAttenuation(in SpotLight spot, in float3 dirToLight, in float distanceToLight)
{
	float angleAtt = angleAttenuation(spot.dir, spot.angles.x, spot.angles.y, dirToLight);
	float distAtt = distAttenuationImpr(distanceToLight, 1.4) * spot.distance;
	return angleAtt * distAtt;
}

// Schlick’s Bias and Gain Functions
// https://arxiv.org/abs/2010.09714
// t == 0 || t == 1 ~> Schlick's Bias
// t == 0.5 ~> Schlick's Gain
float baseBiasGain(float x, float s, float t)
{
	const float k = s * (t - x) + 1.192092896e-07F;

	if (x < t)
		return (t * x) / (x + k);
	else
		return 1.0 + ((1.0 - t) * (x - 1.0)) / (1.0 - x - k);
}

float biasGain(float x, float sn, float tn)
{
	const float slopeMax = 8.0f;
	const float s =
		sn <= 0.5
		? 1.0 / (slopeMax - 2.0 * (slopeMax - 1) * sn)
		: 1.0 + 2.0 * ((slopeMax - 1) * sn - slopeMax * 0.5f);
	return baseBiasGain(x, s, tn);
}


float calcNormalizedStepOffset(uint stepIndex, uint totalSteps, float redistributionFactor, bool directionForward)
{
	float t = float(stepIndex + 1) / float(totalSteps + 1);
	t = directionForward ? t : 1.0 - t;
	t = lerp(t, pow(t, 6), redistributionFactor);
	//t = lerp(t, biasGain(t, 0.0, 0.0), redistributionFactor);
	return directionForward ? t : 1.0 - t;
}

// Note: baking and marching for omni are directly copied from volumetricLight.fx!
float2 singleScatteringHomogenousSphere(float cosAlpha, float density, float depth=1.0)
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

float2 raymarchConeVariableStep(in SpotLight spot, float3 rayOrig, float3 rayDir, float2 nearFar)
{
	// Isotropic only from sides and back (dot == 0 and dot -> -1.0), combined from front (dot -> 1)
	const float DoD = dot(-spot.dir, rayDir);
	const float mieBlendFactor = saturate(DoD);
	const bool distributionDirection = sign(DoD) < 0.0;
	const float distributionFactor = abs(DoD);
	//PRINT_VALUE_LINE(distributionDirection ? 1u : 0u, {'d','i','s','t','r','i','b','u','t','i','o','n','D','i','r','e','c','t','i','o','n',':',' '});
	//PRINT_VALUE_LINE(distributionFactor, {'d','i','s','t','r','i','b','u','t','i','o','n','F','a','c','t','o','r',':',' '});

	const uint maxSteps = 16;
	const float totalDistance = (nearFar.y - nearFar.x);
	const float baseStepSize = totalDistance / float(maxSteps);
	const float totalDistanceClamped = totalDistance - baseStepSize;
	//const float totalDistanceClamped = totalDistance - 0.5 * baseStepSize;

	// First sample stepSize is halved to be initially in better sampling position
	float stepOffsetFactor = calcNormalizedStepOffset(0, maxSteps, distributionFactor, distributionDirection);
	//PRINT_VALUE_LINE(stepOffsetFactor, {'s','t','e','p','O','f','f','s','e','t','F','a','c','t','o','r',':',' '});
	float stepSize = totalDistance * stepOffsetFactor;

	float3 pos = rayOrig + rayDir * nearFar.x;

	float distanceTravelledInside = 0;
	float transmittance = 1.0;
	float scatteredLight = 0.0;

	float sigmaS;
	float sigmaE; // total reduction of radiance due to absorbtion and out scattering
	getParticipatingMedia(spot, pos, sigmaS, sigmaE);
	//PRINT_VALUE_LINE(sigmaS, {'s','i','g','m','a','S',':',' '});
	//PRINT_VALUE_LINE(sigmaE, {'s','i','g','m','a','E',':',' '});

	uint totalSteps = 0;
	[loop]
	for (uint i = 0; (i < maxSteps) && (transmittance > 0.0001f); ++i)
	{
		totalSteps += 1;

		float stepOffsetFactor = calcNormalizedStepOffset(i, maxSteps, distributionFactor, distributionDirection);
		float stepSize = totalDistance * stepOffsetFactor - distanceTravelledInside;

		// Move sampling position further along ray dir
		distanceTravelledInside += stepSize;
		pos += rayDir * stepSize;

		//stepSize = i == maxSteps - 1 ? 0.5 * stepSize : stepSize;

		// Where is the light?
		float3 posToLight = spot.pos - pos;
		float distanceToLight = length(posToLight);
		float3 dirToLight = posToLight / distanceToLight;

		// Phase function based on direction from sample to light and current ray dir
		float miePhase = applyMiePhase(dirToLight, rayDir);
		float miePhaseIsotropic = applyMiePhaseIsotropic(dirToLight, rayDir);
		float miePhaseDiff = miePhase - miePhaseIsotropic;
		float phase = max(gMinimalPhase, miePhaseIsotropic + mieBlendFactor * miePhaseDiff);

		// Evaluate light sample
		float transmittanceCur = exp(-sigmaE * stepSize);
		float posToLightTransmittance = exp(-sigmaE * distanceToLight);
		float att = spotAttenuation(spot, dirToLight, distanceToLight);
		float lightIn = att * phase * posToLightTransmittance; // Incoming light
		float lightInStep = (lightIn - lightIn * transmittanceCur) * sigmaS / sigmaE; // Integrate along the current step segment
		//float lightInStep = lightIn * sigmaS / sigmaE; // Integrate along the current step segment // TODO?

		// Accumulate scattered light and transmittance
		scatteredLight += lightInStep * transmittance;
		transmittance *= transmittanceCur;
	}

	//PRINT_VALUE_LINE(totalSteps, {'t','o','t','a','l','S','t','e','p','s',':',' '});
	//PRINT_VALUE_LINE(distanceTravelledInside, {'d','i','s','t','a','n','c','e','T','r','a','v','e','l','l','e','d',':',' '});

	return float2(scatteredLight, transmittance);
}


// -----------------------------------------------------------------------------
// Light space analytical integration of attenuation for omni and spots
// https://ijdykeman.github.io/graphics/simple_fog_shader
// https://medium.com/@akidevcat/analytic-volumetric-lighting-9d02cc6a95c7
// https://github.com/akidevcat/UnityPackage-AnalyticalVolumetricLighting-Public
// -----------------------------------------------------------------------------

float3x3 constructRayRotation(float3 lightPos, float3 rayOrig, float3 rayDir)
{
	float3x3 res;
	res[0].xyz = rayDir;
	res[2].xyz = normalize(cross(rayDir, lightPos - rayOrig));
	res[1].xyz = cross(res[0].xyz, res[2].xyz);
	return res;
}

float integrateOmniAttenuationInterval(float2 ro, float2 interval)
{
	float divisor = rsqrt(ro.y * ro.y);
	float a = ro.x + interval.x;
	float b = ro.x + interval.y;
	return (atan(b * divisor) - atan(a * divisor)) * divisor;
}

float integrateOmniAttenuation(in OmniLight omni, float3 rayOrig, float3 rayDir, float2 nearFar)
{
	// Constructing a rotation matrix in such a way that the direction of the ray coincides
	// with X-axis, and the light source will lie in XY-plane.
	float3x3 rotate = constructRayRotation(omni.pos, rayOrig, rayDir);

	// Convert rayOrigin into light space (rotate around light)
	rayOrig -= omni.pos;
	rayOrig.xy = float2(dot(rotate[0], rayOrig), dot(rotate[1], rayOrig));

	return integrateOmniAttenuationInterval(rayOrig.xy, nearFar);
}

float integrateAnalyticalSpotAttenuation(float2 rayOrig, float3 spotDir, float2 spotAngles, float t)
{
	float2 pos = float2(rayOrig.x + t, rayOrig.y);
	float distanceToLight = length(pos);

	return
		(pos.x * spotDir.y - pos.y * spotDir.x - atan2(pos.x, pos.y) * spotAngles.x * distanceToLight) /
		((spotAngles.y - spotAngles.x) * pos.y * distanceToLight);
}

float integrateSpotAttenuation(in SpotLight spot, float3 rayOrig, float3 rayDir, float2 nearFar)
{
	// Constructing a rotation matrix in such a way that the direction of the ray coincides
	// with X-axis, and the light source will lie in XY-plane.
	float3x3 rotate = constructRayRotation(spot.pos, rayOrig, rayDir);

	// Convert rayOrigin into light space (rotate around light)
	rayOrig -= spot.pos;
	rayOrig.xy = float2(dot(rotate[0], rayOrig), dot(rotate[1], rayOrig));
	spot.dir.xy = float2(dot(rotate[0], spot.dir), dot(rotate[1], spot.dir));

	return
		integrateAnalyticalSpotAttenuation(rayOrig.xy, spot.dir, spot.angles, nearFar.y) -
		integrateAnalyticalSpotAttenuation(rayOrig.xy, spot.dir, spot.angles, nearFar.x);
}

static const float attenuationAtRangeDistance = 0.001f;

float approxLightIntensityFromRange(float range)
{
	// attenuation = light.intensity / (distanceToLight * distanceToLight);
	// intensity = attenuation * (distanceToLight * distanceToLight)
	return attenuationAtRangeDistance * (range * range);
}

float approxLightRangeFromIntensity(float intensity)
{
	// attenuation = intensity / (distanceToLight * distanceToLight);
	// distanceToLight = sqrt(intensity / attenuation);
	return sqrt(intensity / attenuationAtRangeDistance);
}

// -----------------------------------------------------------------------------
// Pixel shaders for Omni and Spot lights
// -----------------------------------------------------------------------------

float sampleViewDistance(float2 ndcPos)
{
	float2 uv = float2(ndcPos.x, -ndcPos.y) * 0.5 + 0.5;
	float depth = g_DepthTexture.SampleLevel(gPointClampSampler, uv, 0).r;
	float4 p1 = mul(float4(ndcPos.xy, depth, 1), gProjInv);
	return length(p1.xyz / p1.w);
}

//#define DEBUG_RT
float4 psOmni(VS_OUTPUT i) : SV_TARGET0
{
	float3 mediaTransmittance = SamplePrecomputedAtmosphere(0).transmittance;
	if (mediaTransmittance.r < 0.005)
		discard;

	float3 rayOrigin = gCameraPos.xyz;
	float3 rayDir = normalize(i.posW - gCameraPos.xyz);

#if defined(ENABLE_GPU_DEBUG_DRAW)
	const uint2 pixelId = floor(i.pos.xy);
	initDefaultDebugTools(all(pixelId == debugDrawCursor), float2(pixelId + 50u.xx));
	float2 screenUV = float2(i.clipPos.x, -i.clipPos.y) / i.clipPos.w * 0.5 + 0.5;
	PRINT_VALUE_LINE(screenUV, {'u','v',':',' '});
	debugDraw.addScreenRect(screenUV, screenUV + 0.001, 1.0.xxxx);
#endif

	float2 nearFar = sphIntersect2(gCameraPos.xyz, rayDir, worldOffset, gRadius); // two intersection points on sphere
	if (all(nearFar == -1.0))
		discard;

	float distToGeometry = sampleViewDistance(i.clipPos.xy / i.clipPos.w);

	// Manual depth test
	if (distToGeometry < nearFar.x)
		discard;

	// Clamp far plane based on depth
	nearFar.y = min(nearFar.y, distToGeometry + gRadius * gShadowBias);

	PRINT_VALUE_LINE(nearFar, {'n','e','a','r','F','a','r',':',' '});

	float inscattered;

	OmniLight omni;
	omni.pos = worldOffset;
	omni.radius = gRadius;

	float3 intersectionPoint0 = gCameraPos.xyz + rayDir * nearFar.x;
	float3 intersectionToCenter = normalize(omni.pos - intersectionPoint0);
	float cosAngle = dot(rayDir, intersectionToCenter);

	float cosThreshold = 0.99;
	float borderAttenuation = (1.0 - saturate(cosThreshold - cosAngle) / cosThreshold);

#if USE_ANALYTICAL_INTEGRATION
	inscattered = integrateOmniAttenuation(omni, rayOrigin, rayDir, nearFar);
	inscattered *= i.density;
#else
	// Baked lighting coords calculation and lookup
	float firstSampleDistance = inverseLerp((-nearFar.x) / (2.0 * omni.radius), distmin, distmax);
	float secondSampleDistance = inverseLerp((nearFar.y - nearFar.x) / (2.0 * omni.radius), distmin, distmax); // how far we travelled?

	float density = sqrt(inverseLerp(i.density, densitymin, densitymax));
	float angle = sqrt(sqrt(1.0 - cosAngle * cosAngle)); // sqrt(sin())

	float inscattered0 = volumeSrc.SampleLevel(gBilinearClampSampler, float3(density, angle, firstSampleDistance), 0);
	float inscattered1 = volumeSrc.SampleLevel(gBilinearClampSampler, float3(density, angle, secondSampleDistance), 0);

#ifdef DEBUG_RAYMARCHING_OMNI
	inscattered0 = singleScatteringHomogenousSphere(cosAngle, i.density, firstSampleDistance).x;
	inscattered1 = singleScatteringHomogenousSphere(cosAngle, i.density, secondSampleDistance).x;
#endif
 	inscattered = inscattered1 - inscattered0;
#endif

	float alpha = borderAttenuation;
	float3 color = gLightRadiance * inscattered * mediaTransmittance;

	PRINT_VALUE_LINE(mediaTransmittance, {'m','e','d','i','a','T','r','a','n','s','m','i','t','t','a','n','c','e',':',' '});
	PRINT_VALUE_LINE(alpha, {'a','l','p','h','a',':',' '});
	PRINT_VALUE_LINE(color, {'c','o','l','o','r',':',' '});
	PRINT_VALUE_LINE(gLightRadiance, {'g','L','i','g','h','t','R','a','d','i','a','n','c','e',':',' '});

	return float4(color.rgb, alpha);
}

float4 psSpot(VS_OUTPUT i) : SV_TARGET0
{
	float3 mediaTransmittance = SamplePrecomputedAtmosphere(0).transmittance;
	if (mediaTransmittance.r < 0.005)
		discard;

	float3 rayOrigin = gCameraPos.xyz;
	float3 rayDir = normalize(i.posW - rayOrigin);

	float2 screenUV = float2(i.clipPos.x, -i.clipPos.y) / i.clipPos.w * 0.5 + 0.5;
#if defined(ENABLE_GPU_DEBUG_DRAW)
	const uint2 pixelId = floor(i.pos.xy);
	initDefaultDebugTools(all(pixelId == debugDrawCursor), float2(pixelId + 50u.xx));
	//debugTextWriter.setActive(false);
	PRINT_VALUE_LINE(screenUV, {'u','v',':',' '});
	debugDraw.addScreenRect(screenUV, screenUV + 0.001, 1.0.xxxx);
#endif

	SpotLight spot;
	spot.pos = worldOffset;
	spot.dir = direction;
	spot.distance = gRadius;
	spot.angles = angles.xy;
	spot.radius = gSpotBaseEndRadius;

	float2 cone = cappedConeWithSphereIntersect(spot, rayOrigin, rayDir);
	PRINT_VALUE_LINE(cone, {'c','o','n','e',':',' '});
	if (cone.x == cone.y || all(cone < 0.0f))
	{
#if VISUALIZE_VOLUMES
		return float4(0.0, 0.0, 0.1, 1.0);
#endif
		discard;
	}
	float distToGeometry = sampleViewDistance(i.clipPos.xy / i.clipPos.w);

	// Manual depth test based on cone intersection
	if (distToGeometry < cone.x)
		discard;

#if defined(ENABLE_GPU_DEBUG_DRAW)
	float3 end = spot.pos + spot.dir * spot.distance;
	float3 right = normalize(cross(spot.dir, float3(0.0, 1.0, 0.0)));
	float3 up = normalize(cross(spot.dir, right));

	float distanceToSphereCap = angles.x * spot.distance;
	float sphereCapRadius = angles.z * distanceToSphereCap;
	float3 sphereCapIntersectionPos = spot.pos + spot.dir * distanceToSphereCap;

	debugDraw.addLine(spot.pos, end);
	debugDraw.addLine(spot.pos - up * spot.radius.x, spot.pos + up * spot.radius.x);
	debugDraw.addLine(spot.pos - right * spot.radius.x, spot.pos + right * spot.radius.x);

	debugDraw.addLine(sphereCapIntersectionPos - up * sphereCapRadius, sphereCapIntersectionPos + up * sphereCapRadius);
	debugDraw.addLine(sphereCapIntersectionPos - right * sphereCapRadius, sphereCapIntersectionPos + right * sphereCapRadius);

	// debugDraw.addLine(end - up * spot.radius.y, end + up * spot.radius.y);
	// debugDraw.addLine(end - right * spot.radius.y, end + right * spot.radius.y);

	// debugDraw.addLine(spot.pos, end - right * spot.radius.y);
	// debugDraw.addLine(spot.pos, end + right * spot.radius.y);
	// debugDraw.addLine(spot.pos, end - up * spot.radius.y);
	// debugDraw.addLine(spot.pos, end + up * spot.radius.y);

	// Bounds bb = spotBounds(spot);
	// debugDraw.addBox((bb.b + bb.a) * 0.5, (bb.b - bb.a) * 0.5);
#endif

	if (spot.radius.x > 0.0f)
	{
		// Crutch! Not to sample real surface of light
		// Note: angles.w == 1.0f / tan(outerAngle * 0.5f);
		float offset = (spot.radius.x * angles.w);
		spot.pos -= spot.dir * offset; // move spot backwards
		spot.distance += offset; // increase distance with the same amount
	}

	float2 nearFar = float2(
		max(cone.x, 0.0), // clamp near plane by ray origin
		min(cone.y, distToGeometry + gRadius * gShadowBias) // clamp far plane based on depth
	);
	PRINT_VALUE_LINE(nearFar, {'n','e','a','r','F','a','r',':',' '});

	float inscattered = 0.0;
	float alpha = 1.0; // we don't care about transmittance from raymarching, only from media (clouds, fog, atmosphere)

#if USE_ANALYTICAL_INTEGRATION
	//if (1)//(screenUV.x < gDev1.w)
	{
		// Phase is incorrect, but this is the best way for stable picture
		float3 dirToLight = normalize(rayOrigin - spot.pos);
		float DoD = dot(-spot.dir, rayDir);
		float mieBlendFactor = saturate(DoD);
		float miePhase = applyMiePhase(spot.dir, dirToLight);
		float miePhaseIsotropic = applyMiePhaseIsotropic(spot.dir, dirToLight);
		float miePhaseDiff = miePhase - miePhaseIsotropic;
		float phase = max(gMinimalPhase, miePhaseIsotropic + mieBlendFactor * miePhaseDiff);

		float sigmaE = 0.2 * i.density;
		float transmittance = exp(-sigmaE * spot.distance);
		PRINT_VALUE_LINE(i.density, {'i','.','d','e','n','s','i','t','y',':',' '});
		PRINT_VALUE_LINE(transmittance, {'t','r','a','n','s','m','i','t','t','a','n','c','e',':',' '});

		// !!! TODO: tweak intensity to hide light on far border?
		// If we limit range of light source -> intensity must be also tweaked
		// Current integral rely on distance, so on far border intensity is not zero
		inscattered = integrateSpotAttenuation(spot, rayOrigin, rayDir, nearFar);
		inscattered *= phase * i.density;
	}
#else
	//else
	{
		inscattered = raymarchConeVariableStep(spot, rayOrigin, rayDir, nearFar).x;
		inscattered *= i.density;
	}
#endif

	float3 radiance = gLightRadiance;
#if 0
	float radianceMaxComp = maxComp(radiance);
	float approxRange = approxLightRangeFromIntensity(radianceMaxComp);
	float approxIntensity = approxLightIntensityFromRange(spot.distance);
	PRINT_VALUE_LINE(approxIntensity, {'a','p','p','r','o','x','I','n','t','e','n','s','i','t','y',':',' '});
	PRINT_VALUE_LINE(approxRange, {'a','p','p','r','o','x','R','a','n','g','e',':',' '});
	radiance = radianceMaxComp > 1.0 ? radiance / radianceMaxComp : radiance;
#endif

	float3 color = radiance * inscattered * mediaTransmittance;

	PRINT_VALUE_LINE(spot.distance, {'s','p','o','t','.','d','i','s','t','a','n','c','e',':',' '});
	PRINT_VALUE_LINE(radiance, {'r','a','d','i','a','n','c','e',':',' '});
	PRINT_VALUE_LINE(mediaTransmittance, {'m','e','d','i','a','T','r','a','n','s','m','i','t','t','a','n','c','e',':',' '});
	PRINT_VALUE_LINE(alpha, {'a','l','p','h','a',':',' '});
	PRINT_VALUE_LINE(color, {'c','o','l','o','r',':',' '});

#if VISUALIZE_VOLUMES
	return float4(0.1, 0.0, 0.0, 1.0);
#endif

	return float4(color.rgb, alpha);
}

// -----------------------------------------------------------------------------
// Baking
// -----------------------------------------------------------------------------

static const uint bakerGroupSizeX = 1;
static const uint bakerGroupSizeY = 32;
static const uint bakerGroupSizeZ = 32;

[numthreads(bakerGroupSizeX, bakerGroupSizeY, bakerGroupSizeZ)]
void csOmniBaking(uint3 gid: SV_GroupId, uint3 dtid: SV_DispatchThreadID)
{
	uint3 dims;
	volumeDst.GetDimensions(dims.x, dims.y, dims.z);

	if (any(dtid >= dims))
		return;

	float densityrange = densitymax - densitymin;

	float3 uvw = dtid / float3(dims - 1u); // sample locations vs pixels?

	float density = pow(uvw.x, densityPow) * densityrange + densitymin;
	float angle = asin(pow(uvw.y, 2));
	float cosAngle = cos(angle * angleFix); // fix for tangent rays near borders
	float depth = uvw.z * (distmax - distmin) + distmin;

	volumeDst[dtid] = singleScatteringHomogenousSphere(cosAngle, density, depth).x;
}

[numthreads(bakerGroupSizeX, bakerGroupSizeY, bakerGroupSizeZ)]
void csSpotBaking(uint3 gid: SV_GroupId, uint3 dtid: SV_DispatchThreadID)
{
	uint3 dims;
	volumeDst.GetDimensions(dims.x, dims.y, dims.z);

	if (any(dtid >= dims))
		return;

	float densityrange = densitymax - densitymin;

	float3 uvw = dtid / float3(dims - 1u); // sample locations vs pixels?

	float density = pow(uvw.x, densityPow) * densityrange + densitymin;
	float angle = asin(pow(uvw.y, 2));
	float cosAngle = cos(angle * angleFix); // fix for tangent rays near borders
	float depth = uvw.z * (distmax - distmin) + distmin;

	volumeDst[dtid] = singleScatteringHomogenousSphere(cosAngle, density, depth).x;
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

technique10 techOmni
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, psOmni()));
		// full shell and manual depth read to find far distance for "marching", but skip cockpit
		SetDepthStencilState(disableDepthBufferClipCockpit, STENCIL_COMPOSITION_COCKPIT);
		//DISABLE_DEPTH_BUFFER;
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		//ENABLE_ALPHA_BLEND;
		SetRasterizerState(cull);
		SetComputeShader(NULL);

	}
}

technique10 techSpot
{
	pass p0
	{
		SetVertexShader(CompileShader(vs_5_0, vsSpotBounds()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, psSpot()));
		// full shell and manual depth read to find far distance for "marching", but skip cockpit
		SetDepthStencilState(disableDepthBufferClipCockpit, STENCIL_COMPOSITION_COCKPIT);
		//DISABLE_DEPTH_BUFFER;
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		//ENABLE_ALPHA_BLEND;
		SetRasterizerState(cull);
		SetComputeShader(NULL);

	}
}

technique10 bakeOmni
{
	pass p0
	{
	 	SetComputeShader(CompileShader(cs_5_0, csOmniBaking()));
		SetVertexShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(NULL);
	}
}

technique10 bakeSpot
{
	pass p0
	{
	 	SetComputeShader(CompileShader(cs_5_0, csSpotBaking()));
		SetVertexShader(NULL);
		SetGeometryShader(NULL);
		SetPixelShader(NULL);
	}
}
