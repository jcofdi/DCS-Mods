#ifndef COMMON_PACKING_HLSL
#define COMMON_PACKING_HLSL

//--------------------------------------------------------------------------
// U24 U8  <->  U32
//--------------------------------------------------------------------------
// пакуем uint24 и uint8 в uint32; i24=[0;16777215]  i8=[0;255]
uint packUI24UI8(in uint i24,in uint i8)
{
	return i24*256+i8;
}

void unpackUI24UI8(in uint packedUI, out uint i24, out uint i8)
{
	i24 = packedUI*0.00390625;//  /256;
	i8 = fmod(packedUI, 256);
	return;
}


//--------------------------------------------------------------------------
// U16 F32  <->  U32
//--------------------------------------------------------------------------
// если на вход идет u32 не забыть отклампить! u16 = (u32 & 0xffff)
uint pack_U16F32_to_U32(in uint u16, in float f32)
{
	uint f16 = f32tof16(f32);
	return (f16 << 16) | (u16);
}

void unpack_U16F32_from_U32(in uint packedU32, out uint u16, out float f32)
{
	u16 = packedU32 & 0xffff;
	f32 = f16tof32(packedU32>>16);
}


//--------------------------------------------------------------------------
// U16 F32  <->  F32
//--------------------------------------------------------------------------
// если на вход идет u32 не забыть отклампить! u16 = (u32 & 0xffff)
float pack_U16F32_to_F32(in uint u16, in float f32)
{
	return asfloat( pack_U16F32_to_U32(u16, f32) );
}

void unpack_U16F32_from_F32(in float packedf32, out uint u16, out float f32)
{
	unpack_U16F32_from_U32(asuint(packedf32), u16, f32);
}


//--------------------------------------------------------------------------
// F16 F16  <->  UI32
//--------------------------------------------------------------------------
//'val' will be clamped to 65504!
uint pack_F16F16_to_UI32(float2 val)
{
	uint2 u16 = f32tof16(val);
	return (u16.x << 16) | (u16.y);
}

float2 unpack_F16F16_from_UI32(uint val)
{
	return float2(f16tof32(val >> 16), f16tof32(val));
}


// -----------------------------------------------------------------------------
// Common packing functions F32 <-> U8
// -----------------------------------------------------------------------------

uint packUnorm1x8(float value, float d = 0.5f)
{
	const uint mask = (1u << 8) - 1u;
	return uint(floor(value * mask + d)) & mask;
}

float unpackUnorm1x8(uint value)
{
	const uint mask = (1u << 8) - 1u;
	return float(value & mask) / float(mask);
}

uint packUnorm2x8(float2 value, float2 d = float2(0.5, 0.5))
{
	uint r = packUnorm1x8(value.r, d.r);
	uint g = packUnorm1x8(value.g, d.g) << 8;

	return r | g;
}

float2 unpackUnorm2x8(uint value)
{
	return float2(
		unpackUnorm1x8(value),
		unpackUnorm1x8(value >> 8)
	);
}

uint packUnorm3x8(float3 value, float3 d = float3(0.5, 0.5, 0.5))
{
	uint r = packUnorm1x8(value.r, d.r);
	uint g = packUnorm1x8(value.g, d.g) << 8;
	uint b = packUnorm1x8(value.b, d.b) << 16;

	return r | g | b;
}

float3 unpackUnorm3x8(uint value)
{
	return float3(
		unpackUnorm1x8(value),
		unpackUnorm1x8(value >> 8),
		unpackUnorm1x8(value >> 16)
	);
}

uint packUnorm4x8(float4 value, float4 d = float4(0.5, 0.5, 0.5, 0.5))
{
	uint r = packUnorm1x8(value.r, d.r);
	uint g = packUnorm1x8(value.g, d.g) << 8;
	uint b = packUnorm1x8(value.b, d.b) << 16;
	uint a = packUnorm1x8(value.a, d.a) << 24;

	return r | g | b | a;
}

float4 unpackUnorm4x8(uint value)
{
	return float4(
		unpackUnorm1x8(value),
		unpackUnorm1x8(value >> 8),
		unpackUnorm1x8(value >> 16),
		unpackUnorm1x8(value >> 24)
	);
}

uint packSnorm1x8(float value)
{
	return int(clamp(value, -1.0, 1.0) * 127.0) & 0xFF;
}

float unpackSnorm1x8(uint value)
{
	int signedValue = int(value << 24) >> 24;
	return clamp(float(signedValue) / 127.0, -1.0, 1.0);
}

uint packSnorm2x8(float3 value)
{
	uint r = packSnorm1x8(value.r);
	uint g = packSnorm1x8(value.g) << 8;
	return r | g;
}

float2 unpackSnorm2x8(uint value)
{
	return float2(
		unpackSnorm1x8(value),
		unpackSnorm1x8(value >> 8)
	);
}

uint packSnorm3x8(float3 value)
{
	uint r = packSnorm1x8(value.r);
	uint g = packSnorm1x8(value.g) << 8;
	uint b = packSnorm1x8(value.b) << 16;
	return r | g | b;
}

float3 unpackSnorm3x8(uint value)
{
	return float3(
		unpackSnorm1x8(value),
		unpackSnorm1x8(value >> 8),
		unpackSnorm1x8(value >> 16)
	);
}

uint packSnorm4x8(float4 value)
{
	uint r = packSnorm1x8(value.r);
	uint g = packSnorm1x8(value.g) << 8;
	uint b = packSnorm1x8(value.b) << 16;
	uint a = packSnorm1x8(value.a) << 24;
	return r | g | b | a;
}

float4 unpackSnorm4x8(uint value)
{
	return float4(
		unpackSnorm1x8(value),
		unpackSnorm1x8(value >> 8),
		unpackSnorm1x8(value >> 16),
		unpackSnorm1x8(value >> 24)
	);
}

#endif
