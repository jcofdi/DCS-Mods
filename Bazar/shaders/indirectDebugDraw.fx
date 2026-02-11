#include "common/samplers11.hlsl"
#include "common/States11.hlsl"
#include "common/context.hlsl"
#include "deferred/DecoderCommon.hlsl"

#define ENABLE_GPU_DEBUG_DRAW
#include "common/debugDraw.hlsl"

// -----------------------------------------------------------------------------
// Dummy pass to init stream counters into proper state
// -----------------------------------------------------------------------------

[numthreads(1, 1, 1)]
void clear_all()
{
	DebugStorage::clearStreamArguments();
	debugDrawStorageBuffer[DebugStorage::LineCounterIndex] = 0;
	debugDrawStorageBuffer[DebugStorage::TriangleCounterIndex] = 0;
	debugDrawStorageBuffer[DebugStorage::CharacterCounterIndex] = 0;
}

// -----------------------------------------------------------------------------
// Packets stream conversion from data to character instances
// -----------------------------------------------------------------------------

/*
	1 bit packet type
	2 bits data type (uint, int, float)
	2 bits dimensions (1,2,3,4)
	16 bit string size
*/
groupshared uint packetType; // 0 text, 1 values
groupshared uint dataType; // 0 uint, 1 int, 2 float
groupshared uint valueDims; // [0-3] -> 1, 2, 3, 4
groupshared uint stringSize;

groupshared float2 startLocation;
groupshared float4 color;
groupshared float scale;

groupshared uint packetReadOffset;
groupshared uint charactersWriteOffset;

//groupshared uint4  value;

[numthreads(DebugStorage::MaxTextStringLength, 1, 1)]
void convert_stream(uint tid : SV_GroupIndex, uint3 gid : SV_GroupID)
{
	if (tid == 0)
	{
		packetReadOffset = DebugStorage::loadPacketOffset(gid.x);

		uint info = debugDrawStorageBufferStream[packetReadOffset++];
		startLocation = unpack_F16F16_from_UI32(debugDrawStorageBufferStream[packetReadOffset++]);
		color = unpackUnorm4x8(debugDrawStorageBufferStream[packetReadOffset++]);
		scale = asfloat(debugDrawStorageBufferStream[packetReadOffset++]);

		unpackHeaderInfo(info, packetType, dataType, valueDims, stringSize);
		DebugStorage::reserveCharacters(stringSize, charactersWriteOffset);

		// TODO?
		// if (packetType == 1)
		// 	value = DebugStorage::loadPacketValue(valueDims);
	}

	GroupMemoryBarrierWithGroupSync();

	if (packetType == 0 && tid < stringSize)
	{
		uint character = debugDrawStorageBufferStream[packetReadOffset + tid]; // load by tid
		float2 cursor = startLocation;
		cursor.x += glyphSpacing.x * scale * tid;
		DebugStorage::storeCharacter(character, cursor, color, scale, charactersWriteOffset + tid);
	}
	else if (packetType == 1 && tid <= valueDims)
	{
		// distribute work over threads? each thread == one character? or one thread == one value?
		// one value will be simplier for now

		// Note: read more than actually needed for simplicity, need whole 4 values to calculate proper offset of individual values
		uint4 value = uint4(
			debugDrawStorageBufferStream[packetReadOffset + 0],
			debugDrawStorageBufferStream[packetReadOffset + 1],
			debugDrawStorageBufferStream[packetReadOffset + 2],
			debugDrawStorageBufferStream[packetReadOffset + 3]
		);

		uint valueCharsCount[3] = { 0u, 0u, 0u };
		switch (dataType)
		{
		case 0:
			valueCharsCount[0] = getUintCharactersCount(value.x);
			valueCharsCount[1] = getUintCharactersCount(value.y);
			valueCharsCount[2] = getUintCharactersCount(value.z);
			//valueCharsCount[3] = getUintCharactersCount(value.w);
			break;
		case 1:
			valueCharsCount[0] = getIntCharactersCount(asint(value.x));
			valueCharsCount[1] = getIntCharactersCount(asint(value.y));
			valueCharsCount[2] = getIntCharactersCount(asint(value.z));
			//valueCharsCount[3] = getIntCharactersCount(asint(value.w));
			break;
		case 2:
			valueCharsCount[0] = getFloatCharactersCount(asfloat(value.x));
			valueCharsCount[1] = getFloatCharactersCount(asfloat(value.y));
			valueCharsCount[2] = getFloatCharactersCount(asfloat(value.z));
			//valueCharsCount[3] = getFloatCharactersCount(asfloat(value.w));
			break;
		}

		uint localOffsets[4] = { 
			0u, 
			valueCharsCount[0], 
			2 + valueCharsCount[0] + valueCharsCount[1], 
			4 + valueCharsCount[0] + valueCharsCount[1] + valueCharsCount[2] 
		};

		uint currentValue = value[tid];
		uint currentLocalOffset = localOffsets[tid];

		DebugTextStreamConverter converter = DebugTextStreamConverter::make(startLocation, color, scale, charactersWriteOffset, currentLocalOffset);
		switch (dataType)
		{
		case 0: converter.print(currentValue); break;
		case 1: converter.print(asint(currentValue)); break;
		case 2: converter.print(asfloat(currentValue)); break;
		}
	}
}

// -----------------------------------------------------------------------------
// Indirect commands build from storage counters
// -----------------------------------------------------------------------------

struct DrawIndirectCommand
{
	uint vertexCount;
	uint instanceCount;
	uint firstVertex;
	uint firstInstance;
};
RWBuffer<uint> cmdsBuffer;

[numthreads(1, 1, 1)]
void build_indirect_cs()
{
	DebugStorage::clearStreamArguments();

	uint linesCount = debugDrawStorageBuffer[DebugStorage::LineCounterIndex];
	debugDrawStorageBuffer[DebugStorage::LineCounterIndex] = 0;

	uint trianglesCount = debugDrawStorageBuffer[DebugStorage::TriangleCounterIndex];
	debugDrawStorageBuffer[DebugStorage::TriangleCounterIndex] = 0;

	uint charactersCount = debugDrawStorageBuffer[DebugStorage::CharacterCounterIndex];
	debugDrawStorageBuffer[DebugStorage::CharacterCounterIndex] = 0;

	uint cmdOffset = 0;
	DrawIndirectCommand cmd = (DrawIndirectCommand)0;

	cmd.vertexCount = 2;
	cmd.instanceCount = min(linesCount, DebugStorage::MaxLines);
	cmdsBuffer[cmdOffset + 0] = cmd.vertexCount;
	cmdsBuffer[cmdOffset + 1] = cmd.instanceCount;
	cmdsBuffer[cmdOffset + 2] = cmd.firstVertex;
	cmdsBuffer[cmdOffset + 3] = cmd.firstInstance;
	cmdOffset += 8;

	cmd.vertexCount = 3;
	cmd.instanceCount = min(trianglesCount, DebugStorage::MaxTriangles);
	cmdsBuffer[cmdOffset + 0] = cmd.vertexCount;
	cmdsBuffer[cmdOffset + 1] = cmd.instanceCount;
	cmdsBuffer[cmdOffset + 2] = cmd.firstVertex;
	cmdsBuffer[cmdOffset + 3] = cmd.firstInstance;
	cmdOffset += 8;

	cmd.vertexCount = 4;
	cmd.instanceCount = min(charactersCount, DebugStorage::MaxCharacters);
	cmdsBuffer[cmdOffset + 0] = cmd.vertexCount;
	cmdsBuffer[cmdOffset + 1] = cmd.instanceCount;
	cmdsBuffer[cmdOffset + 2] = cmd.firstVertex;
	cmdsBuffer[cmdOffset + 3] = cmd.firstInstance;
	cmdOffset += 8;
}

// -----------------------------------------------------------------------------
// Indirect debug rendering directly from GPU
// -----------------------------------------------------------------------------

#if !defined(MSAA)
	Texture2D<float> depthTexture;
#else
	Texture2DMS<float, MSAA> depthTexture;
#endif
float2 viewportSizeInv;
uint2 textDepthModes;

StructuredBuffer<Line>      debugDrawStorageBufferLinesRO;
StructuredBuffer<Triangle>  debugDrawStorageBufferTrianglesRO;
StructuredBuffer<Character> debugDrawStorageBufferCharactersRO;

// Same as -> enum class DepthTestMode : int
#define DEPTHTEST_DISABLED  0
#define DEPTHTEST_ENABLED   1
#define DEPTHTEST_CHECKER   2

float sampleDepthAverage(uint2 pixel)
{
#if !defined(MSAA)
	return SampleMap(depthTexture, pixel, 0).x;
#else
	float depth = 0.0;
	[unroll]
	for (uint sampleIdx = 0; sampleIdx < MSAA; ++sampleIdx)
	{
		depth += SampleMap(depthTexture, pixel, sampleIdx).x;
	}
	depth /= MSAA;
	return depth;
#endif
}

Line getLineInstance(uint instanceId)
{
	return debugDrawStorageBufferLinesRO.Load(instanceId);
}

Triangle getTriangleInstance(uint instanceId)
{
	return debugDrawStorageBufferTrianglesRO.Load(instanceId);
}

Character getCharacterInstance(uint instanceId)
{
	return debugDrawStorageBufferCharactersRO.Load(instanceId);
}


struct VertexOutput
{
	float4 pos : SV_Position;
	float4 color : COLOR;
};

VertexOutput lines_vs(
	uint vertexId : SV_VertexID, 
	uint instanceId : SV_InstanceID)
{
	Line instance = getLineInstance(instanceId);

	float3 position = vertexId == 0 ? instance.start : instance.end;
	uint packedColor = vertexId == 0 ? instance.colorA : instance.colorB;
	bool isScreenSpace = bool(instance.colorA & 0x1u);

	VertexOutput o;
	o.pos = isScreenSpace ? 
		float4(float2(1.0, -1.0) * (position.xy * 2.0 - 1.0), 1.0, 1.0) :
		mul(float4(position.xyz, 1.0), gViewProj);
	o.color = unpackUnorm4x8(packedColor);
	return o;
}

float4 lines_ps(VertexOutput i) : SV_Target0
{
	const uint depthMode = textDepthModes.y;
	uint2 pixel = i.pos.xy;
	float depth = sampleDepthAverage(pixel);
	bool occluded = depth > i.pos.z;

	if (depthMode == DEPTHTEST_ENABLED && occluded)
		discard;

	float checkers = (pixel.x + pixel.y) % 2 == 0 ? 1.0f : 0.0f;
	float alpha = occluded ? checkers * 0.7f : 1.0f;

	if (depthMode == DEPTHTEST_DISABLED)
		alpha = 1.0;

	float4 color = float4(i.color.xyz, i.color.w * alpha);
	return color;
}


VertexOutput triangles_vs(
	uint vertexId : SV_VertexID, 
	uint instanceId : SV_InstanceID)
{
	Triangle instance = getTriangleInstance(instanceId);

	float3 position = vertexId == 0 ? instance.a : (vertexId == 1 ? instance.b : instance.c);
	uint packedColor = vertexId == 0 ? instance.colorA : (vertexId == 1 ? instance.colorB : instance.colorC);

	VertexOutput o;
	o.pos = mul(float4(position.xyz, 1.0), gViewProj);
	o.color = unpackUnorm4x8(packedColor);
	return o;
}


// -----------------------------------------------------------------------------
// Stuff for rendering character glyphs on screen
// -----------------------------------------------------------------------------

// Based on https://www.shadertoy.com/view/wdSSD1

// Same as -> enum class TextMode : int
#define TEXTMODE_NORMAL     0
#define TEXTMODE_INVERTED   1
#define TEXTMODE_UNDERLINED 2

// Note: all glyphs must be implemented inside storage
// For special characters not related to ASCII we need special macros and/or special codes
static const uint glyphStorageCodeOffset = 0x20; // Zero symbol is 'space' 
static const uint glyphSpecialCharacterCount = 1;
static const uint glyphStorageSize = uint('~') + glyphSpecialCharacterCount - glyphStorageCodeOffset + 1;

static const uint4 glyphStorage[] =
{
	uint4(0x000000,0x000000,0x000000,0x000000), // ch_spc
	uint4(0x003078,0x787830,0x300030,0x300000), // ch_exc !
	uint4(0x006666,0x662400,0x000000,0x000000), // ch_quo "
	uint4(0x006C6C,0xFE6C6C,0x6CFE6C,0x6C0000), // ch_hsh #
	uint4(0x30307C,0xC0C078,0x0C0CF8,0x303000), // ch_dol $
	uint4(0x000000,0xC4CC18,0x3060CC,0x8C0000), // ch_pct %
	uint4(0x0070D8,0xD870FA,0xDECCDC,0x760000), // ch_amp &
	uint4(0x003030,0x306000,0x000000,0x000000), // ch_apo '
	uint4(0x000C18,0x306060,0x603018,0x0C0000), // ch_lbr (
	uint4(0x006030,0x180C0C,0x0C1830,0x600000), // ch_rbr )
	uint4(0x000000,0x663CFF,0x3C6600,0x000000), // ch_ast *
	uint4(0x000000,0x18187E,0x181800,0x000000), // ch_crs +
	uint4(0x000000,0x000000,0x000038,0x386000), // ch_com ,
	uint4(0x000000,0x0000FE,0x000000,0x000000), // ch_dsh -
	uint4(0x000000,0x000000,0x000038,0x380000), // ch_per .
	uint4(0x000002,0x060C18,0x3060C0,0x800000), // ch_lsl /
	uint4(0x007CC6,0xD6D6D6,0xD6D6C6,0x7C0000), // ch_0  
	uint4(0x001030,0xF03030,0x303030,0xFC0000), // ch_1  
	uint4(0x0078CC,0xCC0C18,0x3060CC,0xFC0000), // ch_2  
	uint4(0x0078CC,0x0C0C38,0x0C0CCC,0x780000), // ch_3  
	uint4(0x000C1C,0x3C6CCC,0xFE0C0C,0x1E0000), // ch_4  
	uint4(0x00FCC0,0xC0C0F8,0x0C0CCC,0x780000), // ch_5  
	uint4(0x003860,0xC0C0F8,0xCCCCCC,0x780000), // ch_6  
	uint4(0x00FEC6,0xC6060C,0x183030,0x300000), // ch_7  
	uint4(0x0078CC,0xCCEC78,0xDCCCCC,0x780000), // ch_8  
	uint4(0x0078CC,0xCCCC7C,0x181830,0x700000), // ch_9  
	uint4(0x000000,0x383800,0x003838,0x000000), // ch_col :
	uint4(0x000000,0x383800,0x003838,0x183000), // ch_scl ;
	uint4(0x000C18,0x3060C0,0x603018,0x0C0000), // ch_les <
	uint4(0x000000,0x007E00,0x7E0000,0x000000), // ch_equ =
	uint4(0x006030,0x180C06,0x0C1830,0x600000), // ch_grt >
	uint4(0x0078CC,0x0C1830,0x300030,0x300000), // ch_que ?
	uint4(0x007CC6,0xC6DEDE,0xDEC0C0,0x7C0000), // ch_ats @
	uint4(0x003078,0xCCCCCC,0xFCCCCC,0xCC0000), // ch_A  
	uint4(0x00FC66,0x66667C,0x666666,0xFC0000), // ch_B  
	uint4(0x003C66,0xC6C0C0,0xC0C666,0x3C0000), // ch_C  
	uint4(0x00F86C,0x666666,0x66666C,0xF80000), // ch_D  
	uint4(0x00FE62,0x60647C,0x646062,0xFE0000), // ch_E  
	uint4(0x00FE66,0x62647C,0x646060,0xF00000), // ch_F  
	uint4(0x003C66,0xC6C0C0,0xCEC666,0x3E0000), // ch_G  
	uint4(0x00CCCC,0xCCCCFC,0xCCCCCC,0xCC0000), // ch_H  
	uint4(0x007830,0x303030,0x303030,0x780000), // ch_I  
	uint4(0x001E0C,0x0C0C0C,0xCCCCCC,0x780000), // ch_J  
	uint4(0x00E666,0x6C6C78,0x6C6C66,0xE60000), // ch_K  
	uint4(0x00F060,0x606060,0x626666,0xFE0000), // ch_L  
	uint4(0x00C6EE,0xFEFED6,0xC6C6C6,0xC60000), // ch_M  
	uint4(0x00C6C6,0xE6F6FE,0xDECEC6,0xC60000), // ch_N  
	uint4(0x00386C,0xC6C6C6,0xC6C66C,0x380000), // ch_O  
	uint4(0x00FC66,0x66667C,0x606060,0xF00000), // ch_P  
	uint4(0x00386C,0xC6C6C6,0xCEDE7C,0x0C1E00), // ch_Q  
	uint4(0x00FC66,0x66667C,0x6C6666,0xE60000), // ch_R  
	uint4(0x0078CC,0xCCC070,0x18CCCC,0x780000), // ch_S  
	uint4(0x00FCB4,0x303030,0x303030,0x780000), // ch_T  
	uint4(0x00CCCC,0xCCCCCC,0xCCCCCC,0x780000), // ch_U  
	uint4(0x00CCCC,0xCCCCCC,0xCCCC78,0x300000), // ch_V  
	uint4(0x00C6C6,0xC6C6D6,0xD66C6C,0x6C0000), // ch_W  
	uint4(0x00CCCC,0xCC7830,0x78CCCC,0xCC0000), // ch_X  
	uint4(0x00CCCC,0xCCCC78,0x303030,0x780000), // ch_Y  
	uint4(0x00FECE,0x981830,0x6062C6,0xFE0000), // ch_Z  
	uint4(0x003C30,0x303030,0x303030,0x3C0000), // ch_lsb [
	uint4(0x000080,0xC06030,0x180C06,0x020000), // ch_rsl
	uint4(0x003C0C,0x0C0C0C,0x0C0C0C,0x3C0000), // ch_rsb ]
	uint4(0x10386C,0xC60000,0x000000,0x000000), // ch_hat ^
	uint4(0x000000,0x000000,0x000000,0x00FF00), // ch_usc _
	uint4(0x006030,0x180000,0x000000,0x000000), // ch_acc `
	uint4(0x000000,0x00780C,0x7CCCCC,0x760000), // ch_a  
	uint4(0x00E060,0x607C66,0x666666,0xDC0000), // ch_b  
	uint4(0x000000,0x0078CC,0xC0C0CC,0x780000), // ch_c  
	uint4(0x001C0C,0x0C7CCC,0xCCCCCC,0x760000), // ch_d  
	uint4(0x000000,0x0078CC,0xFCC0CC,0x780000), // ch_e  
	uint4(0x00386C,0x6060F8,0x606060,0xF00000), // ch_f  
	uint4(0x000000,0x0076CC,0xCCCC7C,0x0CCC78), // ch_g  
	uint4(0x00E060,0x606C76,0x666666,0xE60000), // ch_h  
	uint4(0x001818,0x007818,0x181818,0x7E0000), // ch_i  
	uint4(0x000C0C,0x003C0C,0x0C0C0C,0xCCCC78), // ch_j  
	uint4(0x00E060,0x60666C,0x786C66,0xE60000), // ch_k  
	uint4(0x007818,0x181818,0x181818,0x7E0000), // ch_l  
	uint4(0x000000,0x00FCD6,0xD6D6D6,0xC60000), // ch_m  
	uint4(0x000000,0x00F8CC,0xCCCCCC,0xCC0000), // ch_n  
	uint4(0x000000,0x0078CC,0xCCCCCC,0x780000), // ch_o  
	uint4(0x000000,0x00DC66,0x666666,0x7C60F0), // ch_p  
	uint4(0x000000,0x0076CC,0xCCCCCC,0x7C0C1E), // ch_q  
	uint4(0x000000,0x00EC6E,0x766060,0xF00000), // ch_r  
	uint4(0x000000,0x0078CC,0x6018CC,0x780000), // ch_s  
	uint4(0x000020,0x60FC60,0x60606C,0x380000), // ch_t  
	uint4(0x000000,0x00CCCC,0xCCCCCC,0x760000), // ch_u  
	uint4(0x000000,0x00CCCC,0xCCCC78,0x300000), // ch_v  
	uint4(0x000000,0x00C6C6,0xD6D66C,0x6C0000), // ch_w  
	uint4(0x000000,0x00C66C,0x38386C,0xC60000), // ch_x  
	uint4(0x000000,0x006666,0x66663C,0x0C18F0), // ch_y  
	uint4(0x000000,0x00FC8C,0x1860C4,0xFC0000), // ch_z  
	uint4(0x001C30,0x3060C0,0x603030,0x1C0000), // ch_lpa {
	uint4(0x001818,0x181800,0x181818,0x180000), // ch_bar |
	uint4(0x00E030,0x30180C,0x183030,0xE00000), // ch_rpa }
	uint4(0x0073DA,0xCE0000,0x000000,0x000000), // ch_tid ~
	// special characters
	uint4(0xFFFFFF,0xFFFFFF,0xFFFFFF,0xFFFFFF), // opaque quad
};

// Extracts bit b from the given number
uint checkBit(uint value, uint bit)
{
	bit = clamp(bit, 0u, 24u); // bits from 24 to 31 are empty in all glyphs, so we can safely clamp to 24 as empty cell
	return (value & (1u << bit)) > 0 ? 1 : 0;
}

uint4 getGlyphByCode(int charCode)
{
	return glyphStorage[charCode - glyphStorageCodeOffset];
}

// Returns the pixel at uv in the given bit-packed glyph
float getPixel(uint4 glyph, float2 pixelId)
{
	pixelId = floor(pixelId);

	// Calculate the bit to extract (x + y * width)
	uint bit = pixelId.x + pixelId.y * glyphFontSize.x;

	// Clipping bound to remove garbage outside the glyph's boundaries
	bool bounds = all(pixelId >= 0.0.xx) && all(pixelId < float2(glyphFontSize));

	// Least significant bits storing the rightmost pixels
	// Each uint of glyph contains 3 lines of 8 pixels each (24 bits in total)
	// 8 most significant bits are empty by design
	uint pixel = 0;
	pixel |= checkBit(glyph.x, 1 * glyphBitWidth - 1 - bit);
	pixel |= checkBit(glyph.y, 2 * glyphBitWidth - 1 - bit);
	pixel |= checkBit(glyph.z, 3 * glyphBitWidth - 1 - bit);
	pixel |= checkBit(glyph.w, 4 * glyphBitWidth - 1 - bit);
	return (bounds && (pixel > 0)) ? 1.0 : 0.0;
}

float printGlyph(uint4 glyph, float2 pixelPos, float2 printPos)
{
	if (textDepthModes.x == TEXTMODE_INVERTED)//TextMode::Inverted)
	{
		// Inverts all of the valid bits in the glyph
		glyph = ~glyph & 0x00FFFFFFu;
	}
	if (textDepthModes.x == TEXTMODE_UNDERLINED)//TextMode::Underlined)
	{
		// Makes the bottom 8 bits all 1
		glyph.w = glyph.w | 0x000000FFu;
	}
 
	return getPixel(glyph, pixelPos - printPos);
}


struct VertexOutputGlyph
{
	float4 pos : SV_Position;
	float4 color : COLOR;
	float2 uv : TEXCOORD0;
	nointerpolation uint character : INDEX;
};

VertexOutputGlyph glyphs_vs(
	uint vertexId : SV_VertexID, 
	uint instanceId : SV_InstanceID
)
{
	float2 uv = float2(vertexId >> 1, vertexId & 1);

	Character instance = getCharacterInstance(instanceId);

	float2 position = float2(uv.x, uv.y);
	position *= glyphFontSize;
	position *= asfloat(instance.scale);
	position += unpack_F16F16_from_UI32(instance.position);
	position *= viewportSizeInv;

	VertexOutputGlyph res;
	res.pos = float4(float2(1.0, -1.0) * (position * 2.0 - 1.0), 0.0, 1.0);
	res.color = unpackUnorm4x8(instance.color);
	res.uv = uv * glyphFontSize;
	res.character = instance.character;
	return res;
}

float4 glyphs_ps(in VertexOutputGlyph i) : SV_Target0
{
	// i.uv == pixelPos
	float ch = printGlyph(getGlyphByCode(i.character), i.uv, 0.0);
	if (ch == 0.0)
		discard;
	return float4(i.color);
}

technique10 clearAll
{
	pass P0 { SetComputeShader(CompileShader(cs_5_0, clear_all())); }
}

technique10 convertStream
{
	pass P0 { SetComputeShader(CompileShader(cs_5_0, convert_stream())); }
}

technique10 buildCmds
{
	pass P0 { SetComputeShader(CompileShader(cs_5_0, build_indirect_cs())); }
}

technique10 linesRender
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, lines_vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, lines_ps()));

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);
	}
}

technique10 trianglesRender
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, triangles_vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, lines_ps()));

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);
	}
}

technique10 charactersRender
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, glyphs_vs()));
		SetGeometryShader(NULL);
		SetPixelShader(CompileShader(ps_5_0, glyphs_ps()));

		SetDepthStencilState(disableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullNone);
	}
}
