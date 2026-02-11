#ifndef DEBUG_DRAW_HLSLI
#define DEBUG_DRAW_HLSLI

// Must be specified before include to enable internal functionality
//#define ENABLE_GPU_DEBUG_DRAW

#include "common/Packing.hlsl"

struct Line
{
	float3 start;
	uint colorA;
	float3 end;
	uint colorB;
};

struct Triangle
{
	float3 a;
	uint colorA;
	float3 b;
	uint colorB;
	float3 c;
	uint colorC;
};

struct Character
{
	uint position;
	uint scale;
	uint character;
	uint color;
};


RWBuffer<uint>                debugDrawStorageBuffer; // this must be the only RWByteAddressBuffer, but we need templated Load<> and Store<> operations
RWStructuredBuffer<Line>      debugDrawStorageBufferLines;
RWStructuredBuffer<Triangle>  debugDrawStorageBufferTriangles;
RWStructuredBuffer<Character> debugDrawStorageBufferCharacters;

RWBuffer<uint>                debugDrawStorageBufferStream; // encoded stream for text related stuff, special stage convert this into characters

int2 debugDrawCursor;

// -----------------------------------------------------------------------------
// GPU-side Debug Draw rendering for usage from shaders
// -----------------------------------------------------------------------------

// Provides debug storage buffer access to others systems
struct DebugStorage
{
	static const uint PrimTypes = 3;
	static const uint MaxLines = (1 << 14);
	static const uint MaxTriangles = (1 << 14);
	static const uint MaxCharacters = (1 << 14);

	static const uint LineCounterIndex = 0;
	static const uint TriangleCounterIndex = 1;
	static const uint CharacterCounterIndex = 2;

	static const uint LineCounterByteOffset = LineCounterIndex * 4;
	static const uint TriangleCounterByteOffset = TriangleCounterIndex * 4;
	static const uint CharacterCounterByteOffset = CharacterCounterIndex * 4;

	/*
		debugDrawStorageBufferStream layout:
		first 4 uints: [xyzw] arguments for indirect compute, that converts stream into characters
			w is used for counting offsets in uints
		next 'MaxPackets' uints: offsets for each packet inside other part of buffer
	*/
	static const uint StreamCountersOffset = 4; // xyz for dispatch and w is just for uints counting
	static const uint MaxTextStringLength = 64;
	static const uint MaxPackets = 256;
	static const uint MaxStreamEntries = (1 << 14) - MaxPackets - StreamCountersOffset;

#if defined(ENABLE_GPU_DEBUG_DRAW)

	static bool reserveLines(uint count, out uint offset)
	{
		InterlockedAdd(debugDrawStorageBuffer[LineCounterIndex], count, offset);
		return (offset + count) < MaxLines;
	}

	static bool reserveTriangles(uint count, out uint offset)
	{
		InterlockedAdd(debugDrawStorageBuffer[TriangleCounterIndex], count, offset);
		return (offset + count) < MaxTriangles;
	}

	static bool reserveCharacters(uint count, out uint offset)
	{
		InterlockedAdd(debugDrawStorageBuffer[CharacterCounterIndex], count, offset);
		return (offset + count) < MaxCharacters;
	}

	static void storeLine(float3 start, float3 end, float4 colorA, float4 colorB, bool screenSpaceCoords, uint offset)
	{
		Line instance;
		instance.start = start;
		instance.colorA = packUnorm4x8(colorA);
		instance.end = end;
		instance.colorB = packUnorm4x8(colorB);

		// Store info about coordinate systems in lower bit of colorA
		// Additional info can be stored in lower bit of colorB
		instance.colorA &= 0xFFFFFFFEu;
		instance.colorA |= screenSpaceCoords ? 0x1u : 0x0u;

		debugDrawStorageBufferLines[offset] = instance;
	}

	static void storeTriangle(float3 a, float3 b, float3 c, float4 colorA, float4 colorB, float4 colorC, uint offset)
	{
		Triangle instance;
		instance.a = a;
		instance.colorA = packUnorm4x8(colorA);
		instance.b = b;
		instance.colorB = packUnorm4x8(colorB);
		instance.c = c;
		instance.colorC = packUnorm4x8(colorC);
		debugDrawStorageBufferTriangles[offset] = instance;
	}

	static void storeCharacter(uint character, float2 position, float4 color, float scale, uint offset)
	{
		Character instance;
		instance.position = pack_F16F16_to_UI32(position);
		instance.scale = asuint(scale);
		instance.character = character;
		instance.color = packUnorm4x8(color);
		debugDrawStorageBufferCharacters[offset] = instance;
	}

	static bool reservePacket(uint payloadSize, out uint offset)
	{
		uint count = 4 + payloadSize; // header size must be added
		uint packetId = 0;
		InterlockedAdd(debugDrawStorageBufferStream[0], 1, packetId);   // increment packets counter
		InterlockedAdd(debugDrawStorageBufferStream[3], count, offset); // count total relative offset
		debugDrawStorageBufferStream[StreamCountersOffset + packetId] = offset; // store packet offset in offsets table
		return (packetId < MaxPackets) && ((offset + count) < MaxStreamEntries);
	}

	static void storePacketHeader(uint info, float2 position, float4 color, float scale, uint offset)
	{
		debugDrawStorageBufferStream[offset + 0] = info;
		debugDrawStorageBufferStream[offset + 1] = pack_F16F16_to_UI32(position);
		debugDrawStorageBufferStream[offset + 2] = packUnorm4x8(color);
		debugDrawStorageBufferStream[offset + 3] = asuint(scale);
	}

	static void storePacketValue(uint value, uint offset)
	{
		debugDrawStorageBufferStream[offset] = value;
	}

	static uint loadPacketOffset(uint packetId)
	{
		return debugDrawStorageBufferStream[StreamCountersOffset + packetId];
	}

#else

	static bool reserveLines(uint count, out uint offset)
	{
		offset = 0;
		return false;
	}

	static bool reserveTriangles(uint count, out uint offset)
	{
		offset = 0;
		return false;
	}

	static bool reserveCharacters(uint count, out uint offset)
	{
		offset = 0;
		return false;
	}

	static void storeLine(float3 start, float3 end, float4 colorA, float4 colorB, bool screenSpaceCoords, uint offset)
	{
	}

	static void storeTriangle(float3 a, float3 b, float3 c, float4 colorA, float4 colorB, float4 colorC, uint offset)
	{
	}

	static void storeCharacter(uint character, float2 position, float4 color, float scale, uint offset)
	{
	}

	static bool reservePacket(uint payloadSize, out uint offset)
	{
		offset = 0;
		return false;
	}

	static void storePacketHeader(uint info, float2 position, float4 color, float scale, uint offset)
	{
	}

	static void storePacketValue(uint value, uint offset)
	{
	}

	static uint loadPacketOffset(uint packetId)
	{
		return 0;
	}

#endif

	static void clearStreamArguments()
	{
		debugDrawStorageBufferStream[0] = 0; // clear packets counter
		debugDrawStorageBufferStream[1] = 1; // default dim for dispatch
		debugDrawStorageBufferStream[2] = 1; // default dim for dispatch
		debugDrawStorageBufferStream[3] = StreamCountersOffset + MaxPackets; // clear offset counter for packets data
	}
}; // struct DebugDtorage

// Draw geometric primitives from GPU
// Objects are stored in DebugStorage
struct DebugDraw
{
	bool bActive;

	static DebugDraw make()
	{
		DebugDraw res;
		res.bActive = true;
		return res;
	}

	void setActive(bool value) { bActive = value; }
	bool isActive() { return bActive; }

	void addLine(float3 start, float3 end, float4 color = float4(1, 1, 1, 1))
	{
		if (!isActive()) return;

		uint offset;
		if (DebugStorage::reserveLines(1, offset))
		{
			DebugStorage::storeLine(start, end, color, color, false, offset++);
		}
	}

	void addScreenLine(float2 start, float2 end, float4 color = float4(1, 1, 1, 1))
	{
		if (!isActive()) return;

		uint offset;
		if (DebugStorage::reserveLines(1, offset))
		{
			DebugStorage::storeLine(float3(start, 0.0f), float3(end, 0.0f), color, color, true, offset++);
		}
	}

	void addScreenRect(float2 a, float2 b, float4 color = float4(1, 1, 1, 1))
	{
		if (!isActive()) return;

		uint offset;
		if (DebugStorage::reserveLines(4, offset))
		{
			DebugStorage::storeLine(float3(a.x, a.y, 0.0), float3(b.x, a.y, 0.0), color, color, true, offset++);
			DebugStorage::storeLine(float3(a.x, a.y, 0.0), float3(a.x, b.y, 0.0), color, color, true, offset++);
			DebugStorage::storeLine(float3(b.x, a.y, 0.0), float3(b.x, b.y, 0.0), color, color, true, offset++);
			DebugStorage::storeLine(float3(a.x, b.y, 0.0), float3(b.x, b.y, 0.0), color, color, true, offset++);
		}
	}

	void addAxles(float4x4 transform, float radius = 1)
	{
		if (!isActive()) return;

		uint offset;
		if (DebugStorage::reserveLines(3, offset))
		{
			float3 origin = mul(float4(0, 0, 0, 1), transform).xyz;
			float3 x      = mul(float4(1, 0, 0, 1), transform).xyz;
			float3 y      = mul(float4(0, 1, 0, 1), transform).xyz;
			float3 z      = mul(float4(0, 0, 1, 1), transform).xyz;
			DebugStorage::storeLine(origin, x * radius, float4(1, 0, 0, 1), float4(1, 0, 0, 1), false, offset++);
			DebugStorage::storeLine(origin, y * radius, float4(0, 1, 0, 1), float4(0, 1, 0, 1), false, offset++);
			DebugStorage::storeLine(origin, z * radius, float4(0, 0, 1, 1), float4(0, 0, 1, 1), false, offset++);
		}
	}

	void addAxles(float3 origin, float3x3 rotation, float radius = 1.0f)
	{
		if (!isActive()) return;

		uint offset;
		if (DebugStorage::reserveLines(3, offset))
		{
			float3 x = normalize(mul(float3(1, 0, 0), rotation));
			float3 y = normalize(mul(float3(0, 1, 0), rotation));
			float3 z = normalize(mul(float3(0, 0, 1), rotation));
			DebugStorage::storeLine(origin, origin + x * radius, float4(1, 0, 0, 1), float4(1, 0, 0, 1), false, offset++);
			DebugStorage::storeLine(origin, origin + y * radius, float4(0, 1, 0, 1), float4(0, 1, 0, 1), false, offset++);
			DebugStorage::storeLine(origin, origin + z * radius, float4(0, 0, 1, 1), float4(0, 0, 1, 1), false, offset++);
		}
	}

	void addTriangle(float3 a, float3 b, float3 c, float4 color = float4(1, 1, 1, 1), bool isOpaque = false)
	{
		if (!isActive()) return;

		if (isOpaque)
		{
			uint offset;
			if (DebugStorage::reserveTriangles(1, offset))
			{
				DebugStorage::storeTriangle(a, b, c, color, color, color, offset++);
			}
		}
		else
		{
			uint offset;
			if (DebugStorage::reserveLines(3, offset))
			{
				DebugStorage::storeLine(a, b, color, color, false, offset++);
				DebugStorage::storeLine(b, c, color, color, false, offset++);
				DebugStorage::storeLine(c, a, color, color, false, offset++);
			}
		}
	}

	void addQuad(float3 a, float3 b, float3 c, float3 d, float4 color = float4(1, 1, 1, 1), bool isOpaque = false)
	{
		if (!isActive()) return;

		if (isOpaque)
		{
			uint offset;
			if (DebugStorage::reserveTriangles(2, offset))
			{
				DebugStorage::storeTriangle(a, b, c, color, color, color, offset++);
				DebugStorage::storeTriangle(c, d, a, color, color, color, offset++);
			}
		}
		else
		{
			uint offset;
			if (DebugStorage::reserveLines(4, offset))
			{
				DebugStorage::storeLine(a, b, color, color, false, offset++);
				DebugStorage::storeLine(b, c, color, color, false, offset++);
				DebugStorage::storeLine(c, d, color, color, false, offset++);
				DebugStorage::storeLine(d, a, color, color, false, offset++);
			}
		}
	}

	void addBox(float3 position, float3 extent, float4 color = float4(1, 1, 1, 1), bool isOpaque = false)
	{
		if (!isActive()) return;

		const float3 p0 = position + float3(-1, -1, -1) * extent;
		const float3 p1 = position + float3( 1, -1, -1) * extent;
		const float3 p2 = position + float3(-1,  1, -1) * extent;
		const float3 p3 = position + float3(-1, -1,  1) * extent;
		const float3 p4 = position + float3( 1,  1,  1) * extent;
		const float3 p5 = position + float3( 1,  1, -1) * extent;
		const float3 p6 = position + float3(-1,  1,  1) * extent;
		const float3 p7 = position + float3( 1, -1,  1) * extent;

		if (isOpaque)
		{
			uint offset;
			if (DebugStorage::reserveTriangles(12, offset))
			{
				DebugStorage::storeTriangle(p1, p7, p4, color, color, color, offset++);
				DebugStorage::storeTriangle(p4, p5, p1, color, color, color, offset++);
				DebugStorage::storeTriangle(p5, p4, p6, color, color, color, offset++);
				DebugStorage::storeTriangle(p6, p2, p5, color, color, color, offset++);
				DebugStorage::storeTriangle(p2, p6, p3, color, color, color, offset++);
				DebugStorage::storeTriangle(p3, p0, p2, color, color, color, offset++);
				DebugStorage::storeTriangle(p0, p3, p7, color, color, color, offset++);
				DebugStorage::storeTriangle(p7, p1, p0, color, color, color, offset++);
				DebugStorage::storeTriangle(p7, p3, p6, color, color, color, offset++);
				DebugStorage::storeTriangle(p6, p4, p7, color, color, color, offset++);
				DebugStorage::storeTriangle(p5, p2, p0, color, color, color, offset++);
				DebugStorage::storeTriangle(p0, p1, p5, color, color, color, offset++);
			}
		}
		else
		{
			uint offset;
			if (DebugStorage::reserveLines(12, offset))
			{
				DebugStorage::storeLine(p0, p1, color, color, false, offset++);
				DebugStorage::storeLine(p0, p2, color, color, false, offset++);
				DebugStorage::storeLine(p0, p3, color, color, false, offset++);
				DebugStorage::storeLine(p4, p5, color, color, false, offset++);
				DebugStorage::storeLine(p4, p6, color, color, false, offset++);
				DebugStorage::storeLine(p4, p7, color, color, false, offset++);
				DebugStorage::storeLine(p6, p3, color, color, false, offset++);
				DebugStorage::storeLine(p5, p1, color, color, false, offset++);
				DebugStorage::storeLine(p7, p3, color, color, false, offset++);
				DebugStorage::storeLine(p1, p7, color, color, false, offset++);
				DebugStorage::storeLine(p2, p5, color, color, false, offset++);
				DebugStorage::storeLine(p2, p6, color, color, false, offset++);
			}
		}
	}

	void addBoxOriented(float3 position, float3 extent, float4x4 transform, float4 color = float4(1, 1, 1, 1), bool isOpaque = false)
	{
		if (!isActive()) return;

		const float3 p0 = mul(float4(position + float3(-1, -1, -1) * extent, 1), transform).xyz;
		const float3 p1 = mul(float4(position + float3( 1, -1, -1) * extent, 1), transform).xyz;
		const float3 p2 = mul(float4(position + float3(-1,  1, -1) * extent, 1), transform).xyz;
		const float3 p3 = mul(float4(position + float3(-1, -1,  1) * extent, 1), transform).xyz;
		const float3 p4 = mul(float4(position + float3( 1,  1,  1) * extent, 1), transform).xyz;
		const float3 p5 = mul(float4(position + float3( 1,  1, -1) * extent, 1), transform).xyz;
		const float3 p6 = mul(float4(position + float3(-1,  1,  1) * extent, 1), transform).xyz;
		const float3 p7 = mul(float4(position + float3( 1, -1,  1) * extent, 1), transform).xyz;

		if (isOpaque)
		{
			uint offset;
			if (DebugStorage::reserveTriangles(12, offset))
			{
				DebugStorage::storeTriangle(p1, p7, p4, color, color, color, offset++);
				DebugStorage::storeTriangle(p4, p5, p1, color, color, color, offset++);
				DebugStorage::storeTriangle(p5, p4, p6, color, color, color, offset++);
				DebugStorage::storeTriangle(p6, p2, p5, color, color, color, offset++);
				DebugStorage::storeTriangle(p2, p6, p3, color, color, color, offset++);
				DebugStorage::storeTriangle(p3, p0, p2, color, color, color, offset++);
				DebugStorage::storeTriangle(p0, p3, p7, color, color, color, offset++);
				DebugStorage::storeTriangle(p7, p1, p0, color, color, color, offset++);
				DebugStorage::storeTriangle(p7, p3, p6, color, color, color, offset++);
				DebugStorage::storeTriangle(p6, p4, p7, color, color, color, offset++);
				DebugStorage::storeTriangle(p5, p2, p0, color, color, color, offset++);
				DebugStorage::storeTriangle(p0, p1, p5, color, color, color, offset++);
			}
		}
		else
		{
			uint offset;
			if (DebugStorage::reserveLines(12, offset))
			{
				DebugStorage::storeLine(p0, p1, color, color, false, offset++);
				DebugStorage::storeLine(p0, p2, color, color, false, offset++);
				DebugStorage::storeLine(p0, p3, color, color, false, offset++);
				DebugStorage::storeLine(p4, p5, color, color, false, offset++);
				DebugStorage::storeLine(p4, p6, color, color, false, offset++);
				DebugStorage::storeLine(p4, p7, color, color, false, offset++);
				DebugStorage::storeLine(p6, p3, color, color, false, offset++);
				DebugStorage::storeLine(p5, p1, color, color, false, offset++);
				DebugStorage::storeLine(p7, p3, color, color, false, offset++);
				DebugStorage::storeLine(p1, p7, color, color, false, offset++);
				DebugStorage::storeLine(p2, p5, color, color, false, offset++);
				DebugStorage::storeLine(p2, p6, color, color, false, offset++);
			}
		}
	}
}; // struct DebugDraw


// -----------------------------------------------------------------------------
// GPU-side text rendering
// -----------------------------------------------------------------------------

// Text represented as int array of character codes
// int str[] = {'t','e','x','t'};

static const uint2 glyphFontSize = uint2(8, 12);
static const uint2 glyphSpacing = glyphFontSize;
static const uint  glyphBitWidth = 3u * glyphFontSize.x;
static const uint  fractionalWidth = 5u;
static const uint  fractionalPartScale = pow(10u, fractionalWidth);

// Helper for fine alignment of start positions
float2 getGlyphAlignedTextPosition(float2 charsOffset)
{
	return charsOffset * glyphSpacing;
}

// Helpers for calculating total value characters before actual conversion
uint getUintCharactersCount(uint value)
{
	return value > 0 ? (log10(value) + 1) : 1;
}

uint getIntCharactersCount(int value)
{
	uint size = 0;
	size += sign(value) < 0 ? 1u : 0u;
	value = abs(value);
	size += getUintCharactersCount(value);
	return size;
}

uint getFloatCharactersCount(float value)
{
	if (isnan(value) || isinf(value))
		return 3;

	uint size = 0;
	size += sign(value) < 0 ? 1u : 0u;
	value = abs(value);

	uint integer = floor(value);
	uint fractional = floor(frac(value) * fractionalPartScale);

	size += getUintCharactersCount(integer); // integer part
	size += 1u; // dot between integer and fractional parts
	size += max(fractionalWidth, getUintCharactersCount(fractional));
	return size; // NaN and Inf already occupy min 3 slots
}

/*
	Header packing:
		1 bit packet type
		2 bits data type (uint, int, float)
		2 bits dimensions (1,2,3,4)
		16 bit string size
*/

uint packHeaderInfo(in uint packetType, in uint dataType, in uint valueDims, in uint stringSize)
{
	uint info = 0;
	info |= stringSize << 16;
	info |= valueDims << 3;
	info |= dataType << 1;
	info |= packetType;
	return info;
}

void unpackHeaderInfo(in uint info, out uint packetType, out uint dataType, out uint valueDims, out uint stringSize)
{
	packetType = (info) & 0x1;
	dataType   = (info >> 1) & 0x3;
	valueDims  = (info >> 3) & 0x3;
	stringSize = (info >> 16) & 0xFFFF;
}

uint makeValueHeader(uint value, uint stringSize)   { return packHeaderInfo(1, 0, 0, stringSize); }
uint makeValueHeader(uint2 value, uint stringSize)  { return packHeaderInfo(1, 0, 1, stringSize); }
uint makeValueHeader(uint3 value, uint stringSize)  { return packHeaderInfo(1, 0, 2, stringSize); }
uint makeValueHeader(uint4 value, uint stringSize)  { return packHeaderInfo(1, 0, 3, stringSize); }
uint makeValueHeader(int value, uint stringSize)    { return packHeaderInfo(1, 1, 0, stringSize); }
uint makeValueHeader(int2 value, uint stringSize)   { return packHeaderInfo(1, 1, 1, stringSize); }
uint makeValueHeader(int3 value, uint stringSize)   { return packHeaderInfo(1, 1, 2, stringSize); }
uint makeValueHeader(int4 value, uint stringSize)   { return packHeaderInfo(1, 1, 3, stringSize); }
uint makeValueHeader(float value, uint stringSize)  { return packHeaderInfo(1, 2, 0, stringSize); }
uint makeValueHeader(float2 value, uint stringSize) { return packHeaderInfo(1, 2, 1, stringSize); }
uint makeValueHeader(float3 value, uint stringSize) { return packHeaderInfo(1, 2, 2, stringSize); }
uint makeValueHeader(float4 value, uint stringSize) { return packHeaderInfo(1, 2, 3, stringSize); }

// Forms stream of packets for characters rendering from GPU
// Stream are stored in DebugStorage and later converted into actual characters
struct DebugTextStreamWriter
{
	float2 startLocation;
	float2 cursor;
	float4 color;
	float scale;

	bool bActive;

	static DebugTextStreamWriter make(float2 position, float4 color = float4(1, 1, 1, 1))
	{
		DebugTextStreamWriter res;
		res.startLocation = position;
		res.cursor = position;
		res.color = color;
		res.scale = 1.0f;
		res.bActive = true; // manual filtering must be done
		return res;
	}

	void setColor(float4 value) { color = value; }
	void setScale(float value) { scale = value;	}

	void setActive(bool value) { bActive = value; }
	bool isActive() { return bActive; }

	void newLine()
	{
#if 0
		// during cloudsUpsampling ps_ shaders compilation this code causes
		// access violation inside fxo compiler
		if (!isActive()) return;
		cursor.y += glyphSpacing.y * scale;
		cursor.x = startLocation.x;
#else
		// fxo compiler workaround
		cursor.y += isActive() ? glyphSpacing.y * scale : 0.0f;
		cursor.x = isActive() ? startLocation.x : cursor.x;
#endif
	}

#define STORE_TEXT_N(N)																\
	void text(int str[N])															\
	{																				\
		[branch] if (!isActive()) return;											\
		uint offset;																\
		if (DebugStorage::reservePacket(N, offset))									\
		{																			\
			uint header = packHeaderInfo(0, 0, 0, N);								\
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);	\
			offset += 4;															\
			[unroll]																\
			for (uint i = 0; i < N; ++i)											\
				DebugStorage::storePacketValue(str[i], offset + i);					\
			cursor.x += glyphSpacing.x * scale * N;									\
		}																			\
	}																				\

	STORE_TEXT_N(1)
	STORE_TEXT_N(2)
	STORE_TEXT_N(3)
	STORE_TEXT_N(4)
	STORE_TEXT_N(5)
	STORE_TEXT_N(6)
	STORE_TEXT_N(7)
	STORE_TEXT_N(8)
	STORE_TEXT_N(9)
	STORE_TEXT_N(10)
	STORE_TEXT_N(11)
	STORE_TEXT_N(12)
	STORE_TEXT_N(13)
	STORE_TEXT_N(14)
	STORE_TEXT_N(15)
	STORE_TEXT_N(16)
	STORE_TEXT_N(17)
	STORE_TEXT_N(18)
	STORE_TEXT_N(19)
	STORE_TEXT_N(20)
	STORE_TEXT_N(21)
	STORE_TEXT_N(22)
	STORE_TEXT_N(23)
	STORE_TEXT_N(24)
	STORE_TEXT_N(25)
	STORE_TEXT_N(26)
	STORE_TEXT_N(27)
	STORE_TEXT_N(28)
	STORE_TEXT_N(29)
	STORE_TEXT_N(30)
	STORE_TEXT_N(31)
	STORE_TEXT_N(32)
	STORE_TEXT_N(33)
	STORE_TEXT_N(34)
	STORE_TEXT_N(35)
	STORE_TEXT_N(36)
	STORE_TEXT_N(37)
	STORE_TEXT_N(38)
	STORE_TEXT_N(39)
	STORE_TEXT_N(40)
	STORE_TEXT_N(41)
	STORE_TEXT_N(42)
	STORE_TEXT_N(43)
	STORE_TEXT_N(44)
	STORE_TEXT_N(45)
	STORE_TEXT_N(46)
	STORE_TEXT_N(47)
	STORE_TEXT_N(48)
	STORE_TEXT_N(49)
	STORE_TEXT_N(50)
	STORE_TEXT_N(51)
	STORE_TEXT_N(52)
	STORE_TEXT_N(53)
	STORE_TEXT_N(54)
	STORE_TEXT_N(55)
	STORE_TEXT_N(56)
	STORE_TEXT_N(57)
	STORE_TEXT_N(58)
	STORE_TEXT_N(59)
	STORE_TEXT_N(60)
	STORE_TEXT_N(61)
	STORE_TEXT_N(62)
	STORE_TEXT_N(63)
	STORE_TEXT_N(64)

	void print(int value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(1, offset))
		{
			uint charactersCount =
				getIntCharactersCount(value);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(int2 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(2, offset))
		{
			uint charactersCount = 2 +
				getIntCharactersCount(value.x) +
				getIntCharactersCount(value.y);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(int3 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(3, offset))
		{
			uint charactersCount = 4 +
				getIntCharactersCount(value.x) +
				getIntCharactersCount(value.y) +
				getIntCharactersCount(value.z);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);
			DebugStorage::storePacketValue(asuint(value.z), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(int4 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(4, offset))
		{
			uint charactersCount = 6 +
				getIntCharactersCount(value.x) +
				getIntCharactersCount(value.y) +
				getIntCharactersCount(value.z) +
				getIntCharactersCount(value.w);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);
			DebugStorage::storePacketValue(asuint(value.z), offset++);
			DebugStorage::storePacketValue(asuint(value.w), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(uint value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(1, offset))
		{
			uint charactersCount =
				getUintCharactersCount(value);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(value, offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(uint2 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(2, offset))
		{
			uint charactersCount = 2 +
				getUintCharactersCount(value.x) +
				getUintCharactersCount(value.y);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(value.x, offset++);
			DebugStorage::storePacketValue(value.y, offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(uint3 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(3, offset))
		{
			uint charactersCount = 4 +
				getUintCharactersCount(value.x) +
				getUintCharactersCount(value.y) +
				getUintCharactersCount(value.z);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(value.x, offset++);
			DebugStorage::storePacketValue(value.y, offset++);
			DebugStorage::storePacketValue(value.z, offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(uint4 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(4, offset))
		{
			uint charactersCount = 6 +
				getUintCharactersCount(value.x) +
				getUintCharactersCount(value.y) +
				getUintCharactersCount(value.z) +
				getUintCharactersCount(value.w);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(value.x, offset++);
			DebugStorage::storePacketValue(value.y, offset++);
			DebugStorage::storePacketValue(value.z, offset++);
			DebugStorage::storePacketValue(value.w, offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(float value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(1, offset))
		{
			uint charactersCount =
				getFloatCharactersCount(value);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(float2 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(2, offset))
		{
			uint charactersCount = 2 +
				getFloatCharactersCount(value.x) +
				getFloatCharactersCount(value.y);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(float3 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(3, offset))
		{
			uint charactersCount = 4 +
				getFloatCharactersCount(value.x) +
				getFloatCharactersCount(value.y) +
				getFloatCharactersCount(value.z);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);
			DebugStorage::storePacketValue(asuint(value.z), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}

	void print(float4 value)
	{
		if (!isActive()) return;
		uint offset;
		if (DebugStorage::reservePacket(4, offset))
		{
			uint charactersCount = 6 +
				getFloatCharactersCount(value.x) +
				getFloatCharactersCount(value.y) +
				getFloatCharactersCount(value.z) +
				getFloatCharactersCount(value.w);

			uint header = makeValueHeader(value, charactersCount);
			DebugStorage::storePacketHeader(header, cursor, color, scale, offset);
			offset += 4;
			DebugStorage::storePacketValue(asuint(value.x), offset++);
			DebugStorage::storePacketValue(asuint(value.y), offset++);
			DebugStorage::storePacketValue(asuint(value.z), offset++);
			DebugStorage::storePacketValue(asuint(value.w), offset++);

			cursor.x += glyphSpacing.x * scale * charactersCount;
		}
	}
};

// -----------------------------------------------------------------------------
// Various helpers
// -----------------------------------------------------------------------------

static DebugDraw debugDraw;// = DebugDraw::make();
static DebugTextStreamWriter debugTextWriter;// = DebugTextStreamWriter::make(0.0.xx);

float4 valueToColor(float value)  { return float4(value, 0.0, 0.0, 1.0); }
float4 valueToColor(float2 value) { return float4(value, 0.0, 1.0); }
float4 valueToColor(float3 value) { return float4(value, 1.0); }
float4 valueToColor(float4 value) { return value; }

#if defined(ENABLE_GPU_DEBUG_DRAW)

static void initDefaultDebugTools(bool accessActivationCondition, float2 position)
{
	debugDraw = DebugDraw::make();
	debugDraw.setActive(accessActivationCondition);

	debugTextWriter = DebugTextStreamWriter::make(position);
	debugTextWriter.setActive(accessActivationCondition);
}

#if defined(COMPILER_ED_FXC)
	#define TEXT(name, ...) int name[] = __VA_ARGS__
	#define PRINT_WRITER_VALUE_COLORED_QUAD(writer, value) { float4 prevClr = writer.color; writer.setColor(valueToColor(value)); TEXT(quad, {' ', '~'+1,' '}); writer.text(quad); writer.setColor(prevClr); }
	#define PRINT_WRITER_VALUE_LINE_QC(writer, value, ...) { int str[] = __VA_ARGS__; writer.text(str); writer.print(value); PRINT_WRITER_VALUE_COLORED_QUAD(writer, value); writer.newLine(); }
	#define PRINT_WRITER_VALUE_LINE(writer, value, ...) { int str[] = __VA_ARGS__; writer.text(str); writer.print(value); writer.newLine(); }
	#define PRINT_WRITER_TEXT_LINE(writer, ...) { int str[] = __VA_ARGS__; writer.text(str); writer.newLine(); }
	#define PRINT_WRITER_TEXT_LINE_C(writer, clr, ...) { int str[] = __VA_ARGS__; float4 tmp = writer.color; writer.setColor(clr); writer.text(str); writer.setColor(tmp); writer.newLine(); }
#else
	#define TEXT(name, txt) int name[] = txt
	#define PRINT_WRITER_VALUE_COLORED_QUAD(writer, value) { float4 prevClr = writer.color; writer.setColor(valueToColor(value)); TEXT(quad, {' ', '~'+1,' '}); writer.text(quad); writer.setColor(prevClr); }
	#define PRINT_WRITER_VALUE_LINE_QC(writer, value, txt) { int str[] = txt; writer.text(str); writer.print(value); PRINT_WRITER_VALUE_COLORED_QUAD(writer, value); writer.newLine(); }
	#define PRINT_WRITER_VALUE_LINE(writer, value, txt) { int str[] = txt; writer.text(str); writer.print(value); writer.newLine(); }
	#define PRINT_WRITER_TEXT_LINE(writer, txt) { int str[] = txt; writer.text(str); writer.newLine(); }
	#define PRINT_WRITER_TEXT_LINE_C(writer, clr, txt) { int str[] = txt; float4 tmp = writer.color; writer.setColor(clr); writer.text(str); writer.setColor(tmp); writer.newLine(); }
#endif

#else

static void initDefaultDebugTools(bool accessActivationCondition, float2 position)
{
	debugDraw.setActive(false);
	debugTextWriter.setActive(false);
}

#if defined(COMPILER_ED_FXC)
	#define TEXT(name, ...)
	#define PRINT_WRITER_VALUE_COLORED_QUAD(writer, value)	{}
	#define PRINT_WRITER_VALUE_LINE_QC(writer, value, ...)	{}
	#define PRINT_WRITER_VALUE_LINE(writer, value, ...)		{}
	#define PRINT_WRITER_TEXT_LINE(writer, ...)				{}
	#define PRINT_WRITER_TEXT_LINE_C(writer, clr, ...)		{}
#else
	#define TEXT(name, txt)
	#define PRINT_WRITER_VALUE_COLORED_QUAD(writer, value)	{}
	#define PRINT_WRITER_VALUE_LINE_QC(writer, value, txt)	{}
	#define PRINT_WRITER_VALUE_LINE(writer, value, txt)		{}
	#define PRINT_WRITER_TEXT_LINE(writer, txt)				{}
	#define PRINT_WRITER_TEXT_LINE_C(writer, clr, txt)		{}
#endif

#endif

#if defined(COMPILER_ED_FXC)
	#define PRINT_VALUE_COLORED_QUAD(value) 	PRINT_WRITER_VALUE_COLORED_QUAD(debugTextWriter, value)
	#define PRINT_VALUE_LINE_QC(value, ...) 	PRINT_WRITER_VALUE_LINE_QC(debugTextWriter, value, __VA_ARGS__)
	#define PRINT_VALUE_LINE(value, ...) 		PRINT_WRITER_VALUE_LINE(debugTextWriter, value, __VA_ARGS__)
	#define PRINT_TEXT_LINE(...)				PRINT_WRITER_TEXT_LINE(debugTextWriter, __VA_ARGS__)
	#define PRINT_TEXT_LINE_C(clr, ...)			PRINT_WRITER_TEXT_LINE_C(debugTeWriter, __VA_ARGS__, clr)
#else
	#define PRINT_VALUE_COLORED_QUAD(value) 	PRINT_WRITER_VALUE_COLORED_QUAD(debugTextWriter, value)
	#define PRINT_VALUE_LINE_QC(value, txt) 	PRINT_WRITER_VALUE_LINE_QC(debugTextWriter, value, txt)
	#define PRINT_VALUE_LINE(value, txt) 		PRINT_WRITER_VALUE_LINE(debugTextWriter, value, txt)
	#define PRINT_TEXT_LINE(txt)				PRINT_WRITER_TEXT_LINE(debugTextWriter, txt)
	#define PRINT_TEXT_LINE_C(clr, txt)			PRINT_WRITER_TEXT_LINE_C(debugTeWriter, txt, clr)
#endif

// -----------------------------------------------------------------------------
// Packets stream converter into actual characters
// -----------------------------------------------------------------------------

struct DebugTextStreamConverter
{
	float4 color;
	float scale;
	uint baseOffset;
	uint localOffset;
	uint cursorIndex;
	float2 cursor;

	static DebugTextStreamConverter make(float2 position, float4 color, float scale, uint storageOffset, uint localOffset)
	{
		DebugTextStreamConverter res;
		res.color = color;
		res.scale = scale;
		res.baseOffset = storageOffset + localOffset;
		res.localOffset = localOffset;
		res.cursorIndex = 0;
		res.cursor = position + float2(glyphSpacing.x * scale * localOffset, 0.0f);
		return res;
	}

	void storeCharacterGlyph(uint character)
	{
		DebugStorage::storeCharacter(character, cursor, color, scale, baseOffset + cursorIndex);
		cursor.x += glyphSpacing.x * scale;
		cursorIndex++;
	}

	void printInternal(uint value, uint width = 1)
	{
		uint length = value > 0 ? log10(value) + 1 : 1;
		uint divider = round(pow(10, length - 1));

		for (int i = 0; i < (int(width) - int(length)); ++i)
			storeCharacterGlyph('0');

		while (length > 0)
		{
			uint digit = value / divider;
			storeCharacterGlyph('0' + digit);
			--length;

			value = value - digit * divider;
			divider /= 10;
		}
	}

	void printInternal(int value)
	{
		if (value < 0)
		{
			storeCharacterGlyph('-');
			value = -value;
		}

		uint length = value > 0 ? log10(value) + 1 : 1;
		uint divider = round(pow(10, length - 1));

		while (length > 0)
		{
			uint digit = value / divider;
			storeCharacterGlyph('0' + digit);
			--length;

			value = value - digit * divider;
			divider /= 10;
		}
	}

	void printInternal(float value)
	{
		if (isnan(value))
		{
			storeCharacterGlyph('N');
			storeCharacterGlyph('a');
			storeCharacterGlyph('N');
		}
		else if (isinf(value))
		{
			storeCharacterGlyph('I');
			storeCharacterGlyph('n');
			storeCharacterGlyph('f');
		}
		else
		{
			if (value < 0)
			{
				storeCharacterGlyph('-');
			}
			value = abs(value);

			uint integer = floor(value);
			uint fractional = floor(frac(value) * fractionalPartScale);

			printInternal(integer);
			storeCharacterGlyph('.');
			printInternal(fractional, fractionalWidth);
		}
	}

	void print(uint value)
	{
		if (localOffset > 0)
		{
			storeCharacterGlyph(',');
			storeCharacterGlyph(' ');
		}
		printInternal(value);
	}

	void print(int value)
	{
		if (localOffset > 0)
		{
			storeCharacterGlyph(',');
			storeCharacterGlyph(' ');
		}
		printInternal(value);
	}

	void print(float value)
	{
		if (localOffset > 0)
		{
			storeCharacterGlyph(',');
			storeCharacterGlyph(' ');
		}
		printInternal(value);
	}
};

#endif // DEBUG_DRAW_HLSLI
