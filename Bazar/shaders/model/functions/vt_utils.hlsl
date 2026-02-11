#ifndef VT_UTILS_HLSL
#define VT_UTILS_HLSL

#if defined(AIRCRAFT_REGISTRATION) && defined(ENABLE_DAMAGE_ARGUMENTS) && !defined(NEED_DIR_IN_STRUCT_BUF)
struct PositionStruct
{
	float3 pos[4];
	float3 prevPos[4];
	float tailNumberU[8];
	float tailNumberV[8];
	float damage;
	float3 dummy;
};
#elif defined(AIRCRAFT_REGISTRATION) && !defined(ENABLE_DAMAGE_ARGUMENTS) && !defined(NEED_DIR_IN_STRUCT_BUF)
struct PositionStruct
{
	float3 pos[4];
	float3 prevPos[4];
	float tailNumberU[8];
	float tailNumberV[8];
};
#elif !defined(AIRCRAFT_REGISTRATION) && defined(ENABLE_DAMAGE_ARGUMENTS) && !defined(NEED_DIR_IN_STRUCT_BUF)
struct PositionStruct
{
	float3 pos[4];
	float3 prevPos[4];
	float damage;
	float3 dummy;
};
#elif !defined(AIRCRAFT_REGISTRATION) && !defined(ENABLE_DAMAGE_ARGUMENTS) && !defined(NEED_DIR_IN_STRUCT_BUF)
struct PositionStruct
{
	float3 pos[4];
	float3 prevPos[4];
};
#elif !defined(AIRCRAFT_REGISTRATION) && !defined(ENABLE_DAMAGE_ARGUMENTS) && defined(NEED_DIR_IN_STRUCT_BUF)
struct PositionStruct
{
	float3 pos[4];
	float3 prevPos[4];
	float3 dir;
	float dummy;
};
#endif

StructuredBuffer<PositionStruct> sbPositions;

float4x4 convert_matrix(float3 p[4]) {
	/*
	float4x4 m = {
		p[0].x, p[1].x, p[2].x, 0.0,
		p[0].y, p[1].y, p[2].y, 0.0,
		p[0].z, p[1].z, p[2].z, 0.0,
		p[0].w, p[1].w, p[2].w, 1.0
	};
	*/


	float4x4 m = {
		p[0].x, p[0].y, p[0].z, 0,
		p[1].x, p[1].y, p[1].z, 0,
		p[2].x, p[2].y, p[2].z, 0,
		p[3].x, p[3].y, p[3].z, 1
	};

	return m;
}

float4x4 get_matrix(uint i) {
	return convert_matrix(sbPositions[posStructOffset + i].pos);
}

float4x4 get_matrix_prev(uint i) {
	return convert_matrix(sbPositions[posStructOffset + i].prevPos);
}

float4x4 sa_get_transform_matrix(in float packedBonesIndices, in float4 bonesWeights)
{
	uint d = asuint(packedBonesIndices);
	uint4 bonesIndices = (uint4(d, d >> 8, d >> 16, d >> 24) & 0xff) + 1;

	float4x4 mat=	saturate(1.0 - bonesWeights.x - bonesWeights.y - bonesWeights.z - bonesWeights.w) * get_matrix(0) +
					bonesWeights.x * get_matrix(bonesIndices.x) +
					bonesWeights.y * get_matrix(bonesIndices.y) +
					bonesWeights.z * get_matrix(bonesIndices.z) +
					bonesWeights.w * get_matrix(bonesIndices.w);

	return mat;
}

float4x4 sa_get_transform_matrix_prev(in float packedBonesIndices, in float4 bonesWeights)
{
	uint d = asuint(packedBonesIndices);
	uint4 bonesIndices = (uint4(d, d >> 8, d >> 16, d >> 24) & 0xff) + 1;

	float4x4 mat=	saturate(1.0 - bonesWeights.x - bonesWeights.y - bonesWeights.z - bonesWeights.w) * get_matrix_prev(0) +
					bonesWeights.x * get_matrix_prev(bonesIndices.x) +
					bonesWeights.y * get_matrix_prev(bonesIndices.y) +
					bonesWeights.z * get_matrix_prev(bonesIndices.z) +
					bonesWeights.w * get_matrix_prev(bonesIndices.w);

	return mat;
}



float3 get_direction(uint i)
{
#ifdef NEED_DIR_IN_STRUCT_BUF
	return sbPositions[posStructOffset+i].dir;
#else
	return float3(1.0, 0.0, 0.0);
#endif
}

float2 get_tail_number(uint i, uint j)
{
#ifdef AIRCRAFT_REGISTRATION
	return float2(
		sbPositions[posStructOffset+i].tailNumberU[j],
		sbPositions[posStructOffset+i].tailNumberV[j]);
#else
	return 0;
#endif
}

#ifdef ENABLE_SKELETAL_ANIMATION
	#define get_transform_matrix(input) sa_get_transform_matrix(input.pos.w, input.bonesWeights);
#else
	#define get_transform_matrix(input) get_matrix((uint)input.pos.w);//TODO: input.pos.w записать в вершине как *(float*)&index, прочитать тут как asuint
#endif

#ifdef ENABLE_SKELETAL_ANIMATION
	#define get_transform_matrix_prev(input) sa_get_transform_matrix_prev(input.pos.w, input.bonesWeights);
#else
	#define get_transform_matrix_prev(input) get_matrix_prev((uint)input.pos.w);//TODO: input.pos.w записать в вершине как *(float*)&index, прочитать тут как asuint
#endif


#endif
