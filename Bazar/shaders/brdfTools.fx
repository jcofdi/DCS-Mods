#include "common/context.hlsl"
#include "common/samplers11.hlsl"
#include "common/states11.hlsl"

#define FILTER_LIGHT_DIRECTION

#define DEBUG_MULT 5

Texture2D<float4>	texInput;
RWTexture2D<float4>	texOutput;

uint2		dims;
uint4		brdfDims;//xy - view samples; zw - light samples
uint2		samplePosOut;
float4		params;
float4		params2;
float4x4	WVP;
float4x4	World;

#define KERNEL_SIZE 16

#define TYPE_LUMINANCE	0
#define TYPE_COLOR4		1

static const uint nThreads = KERNEL_SIZE * KERNEL_SIZE;

// LUMINANCE --------------------------------------------------------------------------------------------

float calcLuminance(float3 color)
{
    return dot(color, float3(0.2126f, 0.7152f, 0.0722f));
}

float4 SampleSource(uint2 px)
{
	return texInput.Load(uint3(px, 0));
}

float luminanceMap(uint2 px)
{
	float3 color = SampleSource(px).xyz;
	return calcLuminance(color);
}

float SampleAverageLuminance(uint2 samplePos)
{
	const uint2 offset[4] = {{0,0}, {0,1}, {1,0}, {1,1}};
	float avgLuminance = 0;
	[unroll]
	for(uint i=0; i<4; ++i)
		avgLuminance += calcLuminance(SampleSource(samplePos + offset[i]).xyz);

	return avgLuminance * 0.25;
}

float4 SampleAverageColor(uint2 samplePos)
{
	const uint2 offset[4] = {{0,0}, {0,1}, {1,0}, {1,1}};
	float4 clr = 0;
	[unroll]
	for(uint i=0; i<4; ++i)
		clr += SampleSource(samplePos + offset[i]);

	return clr * 0.25;
}

// Shared memory
groupshared float4 SharedMem[nThreads];

[numthreads(KERNEL_SIZE, KERNEL_SIZE, 1)]
void downsample32(uint3 GroupID: SV_GroupID, uint3 GroupThreadID: SV_GroupThreadID, uint threadId: SV_GroupIndex, uniform int type)
{
	const uint2 sampleId = (GroupID.xy * KERNEL_SIZE + GroupThreadID.xy) * 2;
	
	if(type == TYPE_LUMINANCE)
		SharedMem[threadId] = SampleAverageLuminance(sampleId);
	else if(type == TYPE_COLOR4)
		SharedMem[threadId] = SampleAverageColor(sampleId);

	GroupMemoryBarrierWithGroupSync();

	// parallel reduction
	[unroll(uint(ceil(log2(nThreads))))]
	for(uint s = nThreads / 2; s > 0; s >>= 1)
	{
		if(threadId < s)
			SharedMem[threadId] += SharedMem[threadId + s];

		GroupMemoryBarrierWithGroupSync();
	}

	if(threadId == 0)	
		texOutput[GroupID.xy] = SharedMem[0] / nThreads * DEBUG_MULT;	
}

[numthreads(KERNEL_SIZE, KERNEL_SIZE, 1)]
void downsamle16CopyToTexture(uint3 GroupID: SV_GroupID, uint3 GroupThreadID: SV_GroupThreadID, uint threadId: SV_GroupIndex)
{
	const uint2 sampleId = (GroupID.xy * KERNEL_SIZE + GroupThreadID.xy) * 1;
	
	float4 avgLuminance = SampleSource(sampleId);

	// Store in shared memory
	SharedMem[threadId] = avgLuminance;
	GroupMemoryBarrierWithGroupSync();

	// Parallel reduction
	[unroll(uint(ceil(log2(nThreads))))]
	for(uint s = nThreads / 2; s > 0; s >>= 1)
	{
		if(threadId < s)
			SharedMem[threadId] += SharedMem[threadId + s];

		GroupMemoryBarrierWithGroupSync();
	}

	if(threadId == 0)
		texOutput[samplePosOut] = SharedMem[0] / nThreads;
}


// DEBUG SPHERE VIS ----------------------------------------------------------------------------------------

uint coordToLinearIndex(uint2 coord, uint2 samples)
{
	return coord.y * samples.x + coord.x;
}

float2 directionToUV(float3 dir)
{
	float azimuth = (abs(dir.x) < 1e-6 && abs(dir.z) < 1e-6) ? 0.0 : atan2(dir.x, dir.z);
	if(dir.x < 0)
		azimuth += 3.1415 * 2.0;
	float2 uv;
	uv.x = azimuth / (3.1415 * 2.0);
	uv.y = dir.y * 0.5 + 0.5;
	return uv;
}

float4 SampleBRDF(Texture2D brdf, float3 viewDir, float3 lightDir)
{
	const uint2 viewSamples = brdfDims.xy; // + 1 border pixel by X
	const uint2 lightSamples = brdfDims.zw;

	float nLightSamples = float(lightSamples.x * lightSamples.y);

	float2 uv = directionToUV(viewDir);
	float2 lightUV = directionToUV(-lightDir);

#ifdef FILTER_LIGHT_DIRECTION
	float uvViewOffset = (uv.x * viewSamples.x + 0.5 ) / (viewSamples.x + 1);

	float2 lightSamplePos = lightUV * lightSamples;
	uint2 lsMin = floor(lightSamplePos);
	uint2 lsMax = ceil(lightSamplePos);
	float2 p = frac(lightSamplePos);

	uint2 samples[] = {lsMin, 				{lsMin.x, lsMax.y},		{lsMax.x, lsMin.y},		lsMax};	
	float weights[] = {(1-p.x)*(1-p.y),		(1-p.x)*p.y,			p.x*(1-p.y),	 		p.x*p.y};

	float4 result = 0;
	[unroll]
	for(uint i=0; i<4; ++i)
	{
		uint id = coordToLinearIndex(samples[i], lightSamples);
		uv.x = (uvViewOffset + float(id)) / nLightSamples;
		result += brdf.SampleLevel(gBilinearClampSampler, uv, 0) * weights[i];
	}
	return result;
#else
	uint id = coordToLinearIndex(lightUV * lightSamples, lightSamples);
	// uint id = asuint(params.w);
	uv.x = ( (uv.x * viewSamples.x + 0.5 ) / (viewSamples.x + 1)  + float(id) ) / nLightSamples;

	return brdf.SampleLevel(gBilinearClampSampler, uv, 0);
#endif
}

[numthreads(1, 1, 1)]
void sampleBRDFCopyToTexture(uint3 GroupID: SV_GroupID, uint3 GroupThreadID: SV_GroupThreadID, uint threadId: SV_GroupIndex)
{
	float3 lightDir = params.xyz;
	float3 viewDir = params2.xyz;
	
	lightDir = mul(lightDir, (float3x3)World);
	viewDir = mul(viewDir, (float3x3)World);

	texOutput[samplePosOut] = SampleBRDF(texInput, viewDir, lightDir);	
}

struct VS_OUT
{
	float4 pos  : SV_POSITION0;
	float3 tex0 : TEXCOORD0;
};

VS_OUT vsSphere(float3 vPos : POSITION0)
{
	VS_OUT o;
	o.pos = mul(float4(vPos, 1), WVP);
	// o.pos = mul(float4(i.vPos + float3(0,0,-5), 1), gViewProj);
	o.tex0 = vPos.xyz;	
	return o;
}

float4 psSphere(VS_OUT i): SV_TARGET0
{
	float3 lightDir = params.xyz;
	float3 viewDir = normalize(i.tex0.xyz);

	lightDir = mul(lightDir, (float3x3)World);
	viewDir = mul(viewDir, (float3x3)World);

	return float4(SampleBRDF(texInput, viewDir, lightDir).xyz, 1);
}

technique10 tech
{
	pass downsample32Lum				{ SetComputeShader(CompileShader(cs_5_0, downsample32(TYPE_LUMINANCE))); }
	pass downsample32Color4				{ SetComputeShader(CompileShader(cs_5_0, downsample32(TYPE_COLOR4))); }
	pass downsample16CopyToTexture		{ SetComputeShader(CompileShader(cs_5_0, downsamle16CopyToTexture())); }
	pass sampleBRDFCopyToTexture		{ SetComputeShader(CompileShader(cs_5_0, sampleBRDFCopyToTexture())); }

	pass BRDFSphereWithFixedLightDir
	{
		SetVertexShader(CompileShader(vs_5_0, vsSphere()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, psSphere()));
		
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(cullNone);
	}
}
