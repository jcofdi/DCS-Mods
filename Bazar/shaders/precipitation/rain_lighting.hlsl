#ifndef RAIN_LIGHTING_HLSL
#define RAIN_LIGHTING_HLSL

#if !(PRECIPITATION_TILED_LIGHTING)

#include "common/Attenuation.hlsl"
#include "common/lightsCommon.hlsl"

float4 calculateSumLightingSpecular(float3 toCam, float3 pos, float3 norm, float rainSpecularPower)
{


	float4	sumColor = 0;
	float	Att;

	//споты	
	SpotAttenParams attPrmsSpot;
	attPrmsSpot.theta = 1;//spotsLocal[i].angles.y;//делаем радиальный градиент прямо от центра к краю конуса 
	// attPrmsSpot.phi = spotsLocal[0].angles.x;//делаем радиальный градиент прямо от центра к краю конуса 

	for(uint i=0; i<lightCount.y; ++i)
	{
		//конус затухания от спота
		//----------------------------------------------------
		attPrmsSpot.distance = distance(spotsLocal[i].pos.xyz, pos);
		attPrmsSpot.vLight = -normalize(spotsLocal[i].pos.xyz - pos);
		attPrmsSpot.vLightDirection = spotsLocal[i].dir.xyz;

		float3 Rspec = reflect(-attPrmsSpot.vLight, norm);
		float RdotV = max(0, dot(Rspec, toCam));
		//RdotV = 1.0;

		attPrmsSpot.phi = spotsLocal[i].angles.x;//делаем радиальный градиент прямо от центра к краю конуса
		attPrmsSpot.range = spotsLocal[i].pos.w;
	// #ifdef USE_DCS_DEFERRED
		// Att = angleAttenuation(attPrmsSpot.vLightDirection, attPrmsSpot.phi, attPrmsSpot.theta, -attPrmsSpot.vLight) * distAttenuation(attPrmsSpot.range, attPrmsSpot.distance);
	// #else
		Att = SpotAttenuation(attPrmsSpot);
	// #endif
		//sumColor.rgb += spotsLocal[i].diffuse.rgb * spotsLocal[i].diffuse.a*Att;
		sumColor.rgb += spotsLocal[i].diffuse.rgb * spotsLocal[i].diffuse.a*Att*(pow(RdotV, 3)*0.6+0.4);
		sumColor.a += Att;
	}

	return sumColor;
}

float4 calculateSumLighting(float3 toCam, float3 pos)
{
	float4	sumColor = 0;
	float	Att;

	//споты	
	SpotAttenParams attPrmsSpot;
	attPrmsSpot.theta = 1;//spotsLocal[i].angles.y;//делаем радиальный градиент прямо от центра к краю конуса 
	// attPrmsSpot.phi = spotsLocal[0].angles.x;//делаем радиальный градиент прямо от центра к краю конуса 

	for(uint i=0; i<lightCount.y; ++i)
	{
		//конус затухания от спота
		//----------------------------------------------------
		attPrmsSpot.distance = distance(spotsLocal[i].pos.xyz, pos);
		attPrmsSpot.vLight = -normalize(spotsLocal[i].pos.xyz - pos);
		attPrmsSpot.vLightDirection = spotsLocal[i].dir.xyz;
		attPrmsSpot.phi = spotsLocal[i].angles.x;//делаем радиальный градиент прямо от центра к краю конуса
		attPrmsSpot.range = spotsLocal[i].pos.w;
	// #ifdef USE_DCS_DEFERRED
		// Att = angleAttenuation(attPrmsSpot.vLightDirection, attPrmsSpot.phi, attPrmsSpot.theta, -attPrmsSpot.vLight) * distAttenuation(attPrmsSpot.range, attPrmsSpot.distance);
	// #else
		Att = SpotAttenuation(attPrmsSpot);
	// #endif
		sumColor.rgb += spotsLocal[i].diffuse.rgb * spotsLocal[i].diffuse.a*Att;
		sumColor.a += Att;
	}

	return sumColor;
}

float4 calculateMistSumLighting(float3 toCam, float3 pos)
{	
	float4	sumColor = 0;
	float	Att;

	//споты
	SpotAttenParams attPrmsSpot;
	attPrmsSpot.theta = 1;//spotsLocal[j].angles.y;//делаем радиальный градиент прямо от центра к краю конуса 

	for(uint j=0; j<lightCount.y; ++j)
	{
		//конус затухания от спота
		//----------------------------------------------------
		attPrmsSpot.distance = distance(spotsLocal[j].pos.xyz, pos);
		attPrmsSpot.vLight   = -normalize(spotsLocal[j].pos.xyz - pos);
		

		attPrmsSpot.vLightDirection = spotsLocal[j].dir.xyz;
		attPrmsSpot.phi   = spotsLocal[j].angles.x;  //делаем радиальный градиент прямо от центра к краю конуса
		// attPrmsSpot.theta = spotsLocal[j].angles.y;//делаем радиальный градиент прямо от центра к краю конуса
		attPrmsSpot.range = spotsLocal[j].pos.w;
	// #ifdef USE_DCS_DEFERRED
		// Att = angleAttenuation(attPrmsSpot.vLightDirection, attPrmsSpot.phi, attPrmsSpot.theta, -attPrmsSpot.vLight) * distAttenuation(attPrmsSpot.range, attPrmsSpot.distance);
	// #else
		Att = SpotAttenuation(attPrmsSpot);
	// #endif
		//---------------------------------------------------- 
		Att *= Att;

		sumColor.rgb += spotsLocal[j].diffuse.rgb * spotsLocal[j].diffuse.a * Att; //color * power * attenuation
		sumColor.a += Att;
	}

	return sumColor;
}

#else

/*
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
This functions must be used only with snow and rain particles.
Main difference from standard functions (from common/lightsCommon.hlsl and common/lighting.hlsl) is in abs(NoL) usage for diffuse calculations.
This gives us kind of realistic lighting on raindrops under long exposure.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*/

#include "common/lightsData.hlsl"
#include "deferred/ESM.hlsl"

#include "common/shadingCommon.hlsl"

static const float MIN_LIGHT_AMOUNT = 0.01;

float distAttenuation(float range, float dist) {
	dist = max(dist, 0.01);
	float amount = MIN_LIGHT_AMOUNT * range * range;
	return clamp(amount/(dist*dist)-MIN_LIGHT_AMOUNT, 0, 10);
}

float angleAttenuation(float3 spotDir, float phi, float theta, float3 dir) {
	float a = dot(spotDir, -dir);
	return smoothstep(phi, theta, a);
}

float3 calcOmni(float3 diffuseColor, float3 specularColor, float roughness, float3 normal, float3 viewDir, float3 pos, float4 omniPos, float3 omniDiffuse, float2 energyLobe, float translucency, float specularAmount, uniform bool useSpecular = true) {
	float3 dir = omniPos.xyz - pos;
	float dist = length(dir);
	dir /= dist;
	float NoL = max(0, dot(normal, dir)); 
	float absNoL = max(0, abs(dot(normal, dir)));

	float att = distAttenuation(omniPos.w, dist);
	float3 lightAmount = omniDiffuse * att;

	float3 result = Diffuse_lambert(diffuseColor) * (max(translucency, absNoL) * energyLobe.x); //diffuse
	if (useSpecular)
		result += ShadingDefault(diffuseColor, specularColor, roughness, normal, viewDir, dir, float2(0, energyLobe.y)) * (NoL * specularAmount); //specular
	return result * lightAmount;
}

float3 calcSpot(float3 diffuseColor, float3 specularColor, float roughness, float3 normal, float3 viewDir, float3 pos, float4 spotPos, float4 spotDir, float2 spotAngles, float3 spotDiffuse, float2 energyLobe, float translucency, float specularAmount, uniform bool useSpecular = true) {
	float3 dir = spotPos.xyz - pos;
	float clipNear = max(0, sign(dot(-dir, spotDir.xyz) - spotDir.w));
	float dist = length(dir);
	dir /= dist;

	float NoL = max(0, dot(normal, dir)) * clipNear; 
	float absNoL = max(0, abs(dot(normal, dir))) * clipNear; 

	float att = angleAttenuation(spotDir.xyz, spotAngles.x, spotAngles.y, dir) * distAttenuation(spotPos.w, dist);
	float3 lightAmount = spotDiffuse * att;
	
	float3 result = Diffuse_lambert(diffuseColor) * (max(translucency, absNoL) * energyLobe.x); //diffuse
	if (useSpecular)
		result += ShadingDefault(diffuseColor, specularColor, roughness, normal, viewDir, dir, float2(0, energyLobe.y)) * (NoL * specularAmount); //specular
	return	result * lightAmount;
}

float3 calcOmniIdx(uint idx, float3 diffuseColor, float3 specularColor, float roughness, float3 normal, float3 viewDir, float3 pos, float insideCockpit, float2 energyLobe, float translucency, uniform bool useSpecular) {
	OmniLightInfo o = omnis[idx];
	roughness = lerp(roughness, 1, o.amount.w); // apply light softness
	return calcOmni(diffuseColor, specularColor, roughness, normal, viewDir, pos, o.pos, o.diffuse * lerp(o.amount.x, o.amount.y, insideCockpit), energyLobe, translucency, o.amount.z, useSpecular);
}

float3 calcSpotIdx(uint idx, float3 diffuseColor, float3 specularColor, float roughness, float3 normal, float3 viewDir, float3 pos, float insideCockpit, float2 energyLobe, float translucency, uniform bool useSpecular) {
	SpotLightInfo s = spots[idx];
	roughness = lerp(roughness, 1, s.amount.w); // apply light softness
	return calcSpot(diffuseColor, specularColor, roughness, normal, viewDir, pos, s.pos, s.dir, s.angles.xy, s.diffuse * lerp(s.amount.x, s.amount.y, insideCockpit), energyLobe, translucency, s.amount.z, useSpecular);
}

float3 CalculateDynamicLightingTiled(uint2 uv, float3 diffuseColor, float3 specularColor, float roughness, float3 normal, float3 viewDir, float3 pos, float insideCockpit = 0, float2 energyLobe = float2(1, 1), float translucency = 0, uniform uint LightsList = LL_SOLID, uniform bool useSpecular = true, uniform bool useSecondaryShadowmap = false) {

	if (LightsList == LL_NONE)
		return 0;

	uint4 v = LightsIdxOffsets.Load(uint4(uv / 8, LightsList, 0));

	float sm[MAX_SHADOWMAP_COUNT + 1];
	if (useSecondaryShadowmap) {
		uint4 shii = LightsIdxOffsets.Load(uint4(uv / 8, 2, 0));
		uint2 shi = LightsList == LL_SOLID ? shii.xy : shii.zw;
		sm[0] = 1;
		[loop]
		for (uint j = 0; j < shi.y; ++j) {
			uint idx = LightsIdx[shi.x + j];
			sm[idx + 1] = secondarySSM(float4(pos, 1), idx);
		}
	}

	float3 sumColor = 0;

	[loop]
	for (uint i = 0; i < v.y; ++i) {
		uint idx = LightsIdx[v.x + i];
		sumColor.rgb += calcOmniIdx(idx, diffuseColor, specularColor, roughness, normal, viewDir, pos, insideCockpit, energyLobe, translucency, useSpecular);
	}

	[loop]
	for (i = 0; i < v.w; ++i) {
		uint idx = LightsIdx[v.z + i];
		float3 c = calcSpotIdx(idx, diffuseColor, specularColor, roughness, normal, viewDir, pos, insideCockpit, energyLobe, translucency, useSpecular);
		if (useSecondaryShadowmap)
			c *= sm[spots[idx].shadowmapIdx + 1];
		sumColor.rgb += c;
	}

	return sumColor;
}



#endif

#endif