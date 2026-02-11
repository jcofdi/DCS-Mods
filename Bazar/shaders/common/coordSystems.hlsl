#ifndef COORDINATE_SYSTEMS_DCS_HLSL
#define COORDINATE_SYSTEMS_DCS_HLSL

#include "common/context.hlsl"

#define heightHack 0.1

float3 OriginSpaceToEarthSpace(float3 pos)
{
#ifdef GEOTERRAIN
	pos = (pos + gOrigin);
	return (pos + length(pos)*1) * 0.001;
#else
	/*AtmosphereParameters atmParams; initAtmosphereParameters(atmParams);*/
	/*return float3((pos.x - gCameraPos.x) * 0.001, atmParams.bottom_radius + heightHack + (pos.y + gOrigin.y)*0.001, (pos.z - gCameraPos.z) * 0.001);*/
	return float3((pos.x - gCameraPos.x) * 0.001, gEarthRadius + (pos.y + gOrigin.y)*0.001, (pos.z - gCameraPos.z) * 0.001);

#endif
}

float3 WorldSpaceToEarthSpace(float3 pos)
{
#ifdef GEOTERRAIN
	return (pos + length(pos)*1) * 0.001;
#else
	return float3((pos.x - gCameraPos.x - gOrigin.x) * 0.001, gEarthRadius + pos.y*0.001, (pos.z - gCameraPos.z - gOrigin.z) * 0.001);
#endif
}

float3 OriginSpaceToAtmosphereSpace(float3 pos)
{
	float3 epos = OriginSpaceToEarthSpace(pos);
	return epos + heightHack*gSurfaceNormal;
}

// https://www.desmos.com/calculator/1qtxb2oacu
// altitude is ignored to simplify the math !!!
float calcSphereFactorApprox(float distXZSq, float radiusKm)
{
	return (0.5 / (radiusKm * 1000.0)) * distXZSq;
}

// Fake conversion to sphere-like space, more far from camera -> more height
float3 ProjectOriginSpaceToSphere(float3 pos)
{
	return float3(pos.x, pos.y + calcSphereFactorApprox(dot(pos.xz - gCameraPos.xz, pos.xz - gCameraPos.xz), gEarthRadius), pos.z);
}

#endif // COORDINATE_SYSTEMS_DCS_HLSL
