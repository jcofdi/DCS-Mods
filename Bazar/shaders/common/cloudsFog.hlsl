#ifndef CLOUDS_FOG_HLSL
#define CLOUDS_FOG_HLSL

// -----------------------------------------------------------------------------
// Clouds integrated spherical fog
// -----------------------------------------------------------------------------

#define USE_SPHERICAL_FOG_DENSITY 1

#include "common/context.hlsl"
#include "common/coordSystems.hlsl"

// https://iquilezles.org/articles/spheredensity/
// https://www.shadertoy.com/view/XljGDy
float sphDensity(float3 ro, float3 rd, float4 sph, float distance)
{
	// Normalize to unit sphere
	distance = distance / sph.w;
	float3 rc = (ro - sph.xyz) / sph.w;

	// Find intersection with unit sphere
	float b = dot(rd, rc);
	float c = dot(rc, rc) - 1.0;
	float d = b * b - c;

	// No intersection
	if (d < 0.0) 
		return 0.0;

	d = sqrt(d);

	// Segment (not clipped!)
	float t1 = -b - d;
	float t2 = -b + d;

	// Not visible (behind camera or exceed segment distance)
	if (t2 < 0.0 || t1 > distance)
		return 0.0;

	// Clip integration segment from camera to segment distance
	t1 = max(t1, 0.0);
	t2 = min(t2, distance);

	// Analytical integration of an inverse squared density
	float i1 = -t1 * mad(t1, mad(t1, 1 / 3.0, b), c);
    float i2 = -t2 * mad(t2, mad(t2, 1 / 3.0, b), c);

	// Normalization of accumulated fog, such that it takes the value 
	//  1.0f in the extreme case of the ray going right through sphere center
	//  all the way from its surface to the back side
	return (i2 - i1) * (3.0 / 4.0);
}

float flatDensity(float3 ro, float3 rd, float4 ph, float distance)
{
	// Normalize to fog volume
	distance = distance / ph.w;
	float3 rc = (ro - ph.xyz) / ph.w;

	// Intersections with two planes
	float tt = -(rc.y - 1.0) / rd.y;
	float tb = -(rc.y) / rd.y;

	// Segment (not clipped!)
	float t1 = min(tt, tb);
	float t2 = max(tt, tb);

	// Not visible (behind camera or exceed segment distance)
	if (t2 < 0.0 || t1 > distance)
		return 0.0;

	// Clip integration segment from camera to segment distance
	t1 = max(t1, 0.0);
	t2 = min(t2, distance);

	float rc2 = rc.y * rc.y;
	float rcd = rc.y * rd.y;
	float rd2 = rd.y * rd.y;

	// Analytical integration of an inverse squared density
	float i1 = -t1 * mad(t1, mad(t1, rd2 / 3.0, rcd), rc2 - 1.0);
	float i2 = -t2 * mad(t2, mad(t2, rd2 / 3.0, rcd), rc2 - 1.0);

	// Normalization of accumulated fog to match sphDensity function
	return (i2 - i1) * (3.0f / 4.0f);
}

float convertToEarthAtmosphereRelative(float distanceKm)
{
	return distanceKm / gAtmTopRadius;
}

float3 convertToEarthAtmosphereRelative(float3 positionKm)
{
	return positionKm / gAtmTopRadius;
}

float getSphericalFogDensity(float3 rayOriginKm, float3 rayDirection, float distanceKm)
{
	float3 rayOrigin = convertToEarthAtmosphereRelative(rayOriginKm);
	float distance = convertToEarthAtmosphereRelative(distanceKm);

#if	USE_SPHERICAL_FOG_DENSITY
	return gFogParams.densityFactor * sphDensity(rayOrigin, rayDirection, float4(0.0, 0.0, 0.0, gFogParams.sphereRadiusAtmosphereRelative), distance);
#else
	return gFogParams.densityFactor * flatDensity(rayOrigin, rayDirection, float4(0.0, 0.0, 0.0, gFogParams.sphereRadiusAtmosphereRelative), distance);
#endif
	//return gFogParams.densityFactor * sphDensity(rayOriginKm, rayDirection, float4(0.0, 0.0, 0.0, gAtmTopRadius * gFogParams.sphereRadiusAtmosphereRelative), distanceKm);
}

float getSphericalFogTransmittance(float3 rayOriginKm, float3 rayDirection, float distanceKm)
{
	return exp(-gFogParams.sigmaExtinction * getSphericalFogDensity(rayOriginKm, rayDirection, distanceKm));
}

#endif // CLOUDS_FOG_HLSL
