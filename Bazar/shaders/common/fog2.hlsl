#ifndef FOG_NEW_HLSL
#define FOG_NEW_HLSL

#include "common/cloudsFog.hlsl"
#include "common/fogCommon.hlsl"

float getFogTransparency(float heightAboveGroundMeters, float viewDirYComp, float distanceMeters)
{
	float3 rayOriginEarthSpaceKm = float3(0.0f, WorldSpaceToEarthSpace(float3(0.0f, heightAboveGroundMeters, 0.0f)).y, 0.0f);
	float3 rayDirection = float3(sqrt(1.0 - viewDirYComp * viewDirYComp), viewDirYComp, 0.0f); // restore fake ray dir in XY plane
	return getSphericalFogTransmittance(rayOriginEarthSpaceKm, rayDirection, distanceMeters * 0.001f);
}

float getFogTransparency(float3 cameraPos, float3 pos)
{
	float3 rayOriginEarthSpaceKm = float3(0.0f, OriginSpaceToEarthSpace(cameraPos).y, 0.0f);
	float3 deltaRay = pos - cameraPos;
	float3 rayDirection = normalize(deltaRay);
	float distanceMeters = length(deltaRay);

	return getSphericalFogTransmittance(rayOriginEarthSpaceKm, rayDirection, distanceMeters * 0.001f);
}

// deprecated!
float3 applyFog(float3 color, float3 rayDirection, float distanceMeters, uniform bool bSky = false)
{
	float3 fogColor = (gFogParams.color + gSunDiffuse.rgb) * gSunIntensity * 0.1;
	float3 rayOriginEarthSpaceKm = WorldSpaceToEarthSpace(float3(0.0f, gCameraHeightAbs, 0.0f));

	float fogTransmittance = getSphericalFogTransmittance(rayOriginEarthSpaceKm, rayDirection, distanceMeters * 0.001f);

	return lerp(fogColor, color, fogTransmittance);
}

// deprecated!
float3 applyFog(float3 color, float3 cameraPos, float3 pos)
{
	float3 fogColor = (gFogParams.color + gSunDiffuse.rgb) * gSunIntensity * 0.1;
	float fogTransmittance = getFogTransparency(cameraPos, pos);
	return lerp(fogColor, color, fogTransmittance);
}

#endif // FOG_NEW_HLSL
