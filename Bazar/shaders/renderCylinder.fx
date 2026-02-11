#include "common/States11.hlsl"

float4 Color;
matrix WVP;
float3 RadiusLength; // (First cap radius, Second cap radius, Distance between caps)


void vs_main(in float4 vPos : POSITION, out float4 oPos : SV_POSITION)
{
    float4 pos = float4(vPos.x, vPos.y, vPos.z, 1.0f);
    if (vPos.x == 0.0f)
    {
        pos.x = 0.0f;
        pos.yz *= RadiusLength.x;
    }
	else
    {
        pos.x = RadiusLength.z;
        pos.yz *= RadiusLength.y;
    }
	
    oPos = mul(pos, WVP);
}

float4 ps_main(in float4 oPos : SV_POSITION) : SV_TARGET0
{
	return Color;
}

technique10 Solid
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_4_0, vs_main()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_4_0, ps_main()));

		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetRasterizerState(wireframe);
	}
}

