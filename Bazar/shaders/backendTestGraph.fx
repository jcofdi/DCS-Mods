#include "common/samplers11.hlsl"
#include "common/states11.hlsl"
// #include "common/random.hlsl"

Texture2D<float4>	texInput;

uint				iterations;

float noise1(float param, float factor = 13758.937545312382)
{
	return frac(sin(param) * factor);
}

float computeHash(float hash)
{
	for(uint i = 0; i < iterations; ++i)
		hash = noise1(hash, hash * 1.51231 + 5.3121);
	
	return hash*0.5+0.5;
}

float4 colorizedHash(float hash)
{
	return float4((iterations%10)/10.0, hash, hash, 1) * 0.6;
}

struct VS_OUTPUT
 {
	float4 vPos			:SV_POSITION;
	float2 vTexCoords	:TEXCOORD0;
};

VS_OUTPUT VS(uint vid: SV_VertexID)
{
	float4 pos = float4((vid & 1)? 1.0 : -1.0, (vid & 2)? 1.0 : -1.0, 0, 1);

	VS_OUTPUT o;
    o.vPos = pos;
	o.vTexCoords = float2(pos.x * 0.5 + 0.5, -pos.y * 0.5 + 0.5);
    return o;    
}

VS_OUTPUT VS2(uint vid: SV_VertexID)
{
	float4 pos = float4((vid & 1)? 1.0 : -1.0, (vid & 2)? 1.0 : -1.0, 0, 1);

	VS_OUTPUT o;
	o.vPos = pos;
	o.vTexCoords = float2(pos.x * 0.5 + 0.5, -pos.y * 0.5 + 0.5);
	o.vTexCoords.y = 1 - o.vTexCoords.y;
	return o;
}

float4 PS(VS_OUTPUT i): SV_TARGET0
{ 
	float hash = computeHash(i.vPos.x + i.vPos.y*200);
	return lerp(texInput.Load(int3(i.vPos.xy, 0)), colorizedHash(hash), 0.5);
}

float4 PS2(VS_OUTPUT i): SV_TARGET0
{
	float hash = computeHash(i.vPos.x + i.vPos.y*200);
	return lerp(texInput.Load(int3(i.vPos.xy, 0)), colorizedHash(hash).zxyw, 0.5);
}

technique11 tech
{
	pass graphicPipelineVariant1
	{
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, PS()));
		SetComputeShader(NULL);

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);
	}

	pass graphicPipelineVariant2
	{
		SetVertexShader(CompileShader(vs_5_0, VS2()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, PS2()));
		SetComputeShader(NULL);

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);
	}
}
