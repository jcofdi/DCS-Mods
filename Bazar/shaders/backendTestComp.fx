Texture2D<float4>	texInput;
RWTexture2D<float4> texOutput;

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

[numthreads(8, 8, 1)]
void CS(uint3 dtId : SV_DispatchThreadID)
{
	float hash = computeHash(dtId.x + dtId.y*200);
	uint width = 0;
	uint height = 0;
	texOutput.GetDimensions(width, height);
	if(dtId.x<width && dtId.y<height)
		texOutput[dtId.xy] = lerp(texInput[dtId.xy], colorizedHash(hash), 0.5);
}

technique11 tech
{
	pass computePipeline
	{
		SetComputeShader(CompileShader(cs_5_0, CS()));     
	}
}
