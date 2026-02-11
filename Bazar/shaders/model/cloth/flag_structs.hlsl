#ifndef FLAG_STRUCTS_HLSL
#define FLAG_STRUCTS_HLSL

struct VS_FLAG_INPUT
{
	int3 posInd : POSITION0;
};

struct VS_FLAG_OUTPUT
{
	float4 Position		: SV_POSITION0;		// vertex position in projection space
	float4 Pos			: COLOR0;		// vertex position in world space, w component holds height in world coordinates
	float3 Normal		: NORMAL0;
	float3 Color		: COLOR1;
};

struct VS_FLAG_FORCE_OUTPUT
{
	float4 Position0	: SV_POSITION0;		// vertex position in projection space
	float4 Position1	: COLOR0;
	float4 Pos0			: COLOR1;		// vertex position in world space, w component holds height in world coordinates
	float4 Pos1			: COLOR2;		// vertex position in world space, w component holds height in world coordinates
	float3 Normal		: NORMAL0;
};

struct GS_FLAG_FORCE_OUTPUT {
	float4 Position		: SV_POSITION0;
	float3 Normal		: NORMAL0;
	float3 Color		: COLOR0;
};

// Pixel shader o structure
struct PS_FLAG_OUTPUT
{
	float4 RGBColor : SV_TARGET0;  // Pixel color
};

struct Indices{
	int p;

	int up;
	int down;
	int left;
	int right;

	int left_up;
	int right_up;
	int right_down;
	int left_down;

	int up2;
	int down2;
	int left2;
	int right2;
};

Indices build_indices(int2 ind, int width, int height){
	Indices i;
	int n = width * height;

	i.p = ind.x + ind.y * width;

	i.up = ind.x + (ind.y + 1) * width;
	i.down = ind.x + (ind.y - 1) * width;
	i.left = ind.x - 1 + ind.y * width;
	i.right = ind.x + 1 + ind.y * width;

	i.left_up = ind.x - 1 + (ind.y + 1) * width;
	i.right_up = ind.x + 1 + (ind.y + 1) * width;
	i.right_down = ind.x + 1 + (ind.y - 1) * width;
	i.left_down = ind.x - 1 + (ind.y - 1) * width;

	i.up2 = ind.x + (ind.y + 2) * width;
	i.down2 = ind.x + (ind.y - 2) * width;
	i.left2 = ind.x - 2 + ind.y * width;
	i.right2 = ind.x + 2 + ind.y * width;

	if(ind.y == (height - 1)){
		i.up = -1;
		i.left_up = -1;
		i.right_up = -1;
	}else if(ind.y == 0){
		i.down = -1;
		i.right_down = -1;
		i.left_down = -1;
	}

	if(ind.x == (width - 1)){
		i.right = -1;
		i.right_up = -1;
		i.right_down = -1;
	}else if(ind.x == 0){
		i.left = -1;
		i.left_up = -1;
		i.left_down = -1;
	}

	if(ind.y >= (height - 2)){
		i.up2 = -1;
	}else if(ind.y <= 1){
		i.down2 = -1;
	}

	if(ind.x >= (width - 2)){
		i.right2 = -1;
	}else if(ind.x <= 1){
		i.left2 = -1;
	}

	return i;
}

#endif
