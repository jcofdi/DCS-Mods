#ifndef MODEL_FAKE_LIGHTS_COMMON_29_HLSL
#define MODEL_FAKE_LIGHTS_COMMON_29_HLSL

struct FakeSpotPositionStruct
{
	float3 pos[4];
	float3 normalMatrix[4];
	float3 dir;
	float dummy;
};

StructuredBuffer<FakeSpotPositionStruct> sbFakeSpotsPositions;

float4x4 convert_matrix_fl(float3 p[4]) {
	float4x4 m = {
		p[0].x, p[0].y, p[0].z, 0,
		p[1].x, p[1].y, p[1].z, 0,
		p[2].x, p[2].y, p[2].z, 0,
		p[3].x, p[3].y, p[3].z, 1
	};

	return m;
}

float4x4 get_matrix_fl(uint i){
	return convert_matrix_fl(sbFakeSpotsPositions[posStructOffset + i].pos);
}

float3 get_direction_fl(uint i){
	return sbFakeSpotsPositions[posStructOffset+i].dir;
}

float4x4 get_normal_matrix_fl(uint i){
	return convert_matrix_fl(sbFakeSpotsPositions[posStructOffset + i].normalMatrix);
}

#endif