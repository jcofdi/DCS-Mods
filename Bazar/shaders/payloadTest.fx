
float noise1(float param, float factor = 13758.937545312382)
{
	return frac(sin(param) * factor);
}

uint iterations;

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

float4 PS(VS_OUTPUT i): SV_TARGET0
{ 
	float hash = i.vPos.x + i.vPos.y*200;
	for(uint i = 0; i < iterations; ++i)
		hash = noise1(hash, hash * 1.51231 + 5.3121);
	
	hash = hash*0.5+0.5;
	return float4((iterations%10)/10.0, hash, hash, 1) * 0.6;
}

DepthStencilState disableDepthBuffer
{
	DepthEnable        = FALSE;
	DepthWriteMask     = ZERO;
	// DepthFunc          = GREATER_EQUAL;

	StencilEnable      = FALSE;
	StencilReadMask    = 0;
	StencilWriteMask   = 0;
};

BlendState disableAlphaBlend
{
	BlendEnable[0] = FALSE;
	BlendEnable[1] = FALSE;
};

RasterizerState cullNone
{
	CullMode = None;
	FillMode = Solid;
	MultisampleEnable = FALSE;
};


technique10 tech {
	pass P0{
		SetVertexShader(CompileShader(vs_5_0, VS()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, PS()));
		SetComputeShader(NULL);

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);      
	}
}
