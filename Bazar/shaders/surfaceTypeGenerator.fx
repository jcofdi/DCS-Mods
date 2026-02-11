#include "common/colorTransform.hlsl"

Texture2D ref;
RWTexture2D<uint> surfType;

#define MAX_COUNT_OF_SURFACE_TYPES 32
#define GROUP_SIZE_X 16
#define GROUP_SIZE_Y 16
#define GROUP_SIZE_Z 1

float4 hsvMin[MAX_COUNT_OF_SURFACE_TYPES];
float4 hsvMax[MAX_COUNT_OF_SURFACE_TYPES];
int countOfSurfaceTypes;

int quadSideInPixels;

float4 sampleTextureQuad(Texture2D tex, int2 ij, int quadSideInPixels)
{
	int2 texSize = 0;
	tex.GetDimensions(texSize.x, texSize.y);

	ij = ij * quadSideInPixels;
	int2 ij_next = ij + quadSideInPixels;

	ij = clamp(ij, 0, texSize - 1);
	ij_next = clamp(ij_next, 0, texSize);

	float4 avgColor = 0;
	for (int i = ij.x; i < ij_next.x; ++i)
	{
		for (int j = ij.y; j < ij_next.y; ++j)
		{
			avgColor += tex.mips[0][uint2(i, j)];
		}
	}
	avgColor /= ij_next.x - ij.x;
	avgColor /= ij_next.y - ij.y;

	return avgColor;
}

int surfaceType(float4 hsvMin[MAX_COUNT_OF_SURFACE_TYPES], float4 hsvMax[MAX_COUNT_OF_SURFACE_TYPES], int count, float3 hsv)
{
	for (int i = 0; i < count; ++i)
	{
		if (hsvMin[i].x <= hsv.x && 
			hsvMin[i].y <= hsv.y &&
			hsvMin[i].z <= hsv.z &&
			hsv.x <= hsvMax[i].x &&
			hsv.y <= hsvMax[i].y &&
			hsv.z <= hsvMax[i].z) 
			return i;
	}

	return -1;
}

[numthreads(GROUP_SIZE_X, GROUP_SIZE_Y, GROUP_SIZE_Z)]
void CS(int3 dispatchThreadID : SV_DispatchThreadID)
{
	float4 color = sampleTextureQuad(ref, dispatchThreadID.xy, quadSideInPixels);
	color.xyz = srgb2rgb(color.xyz);
	color.xyz = rgb2hsv(color.xyz);

	int st = surfaceType(hsvMin, hsvMax, countOfSurfaceTypes, color.xyz);
	surfType[dispatchThreadID.xy] = st < 0 ? 0 : 1 << st;
}

technique11 surface_type_technique
{
	pass P0
	{
		SetVertexShader(NULL);
		SetPixelShader(NULL);
		SetComputeShader(CompileShader(cs_5_0, CS()));
	}
};