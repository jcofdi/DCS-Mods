#define NO_SPECULAR
#define METROUGH_MAP

static const float albedoContrast = 1;
static const float albedoLevel = 0;

#define TEXCOORD0_SIZE 2
#define TEXCOORD1_SIZE 2
#define NORMAL_MAP_UV
#define NORMAL_SIZE 3
#define TANGENT_SIZE 3
#define BINORMAL_SIZE 3 // deprecated
#define diffuseShift float2(0, 0)

#include "../common/States11.hlsl"
#include "common/enums.hlsl"

#include "common/shader_macroses.hlsl"
#include "deck_material/deck_uniforms.hlsl"
#include "deck_material/deck_vs.hlsl"
#include "deck_material/deck_ps.hlsl"

#include "functions/flat_shadow.hlsl"
#include "functions/lk_shadow.hlsl"
#include "functions/radar.hlsl"

#include "../common/ShadowStates.hlsl"
#include "common/states.hlsl"

float4 deck_flat_shadow_ps(VS_OUTPUT_SHADOWS input): SV_TARGET0 {
	if(input.Pos.w < FlatShadowProps.y)
		discard;

#if defined(SHADOW_WITH_ALPHA_TEST)
	float4 baseColorTiled = BaseColorTiledMap.Sample(gAnisotropicWrapSampler, input.tc0.xy);
	clip(baseColorTiled.a - 0.5);
	testDamageAlpha(input, distance(input.Pos.xyz, gCameraPos.xyz) * gNearFarFovZoom.w);
#endif
	return float4(0,0,0,gFlatShadowAlpha);
}

void deck_lk_shadow_ps(const VS_OUTPUT_SHADOWS input)
{
#if defined(SHADOW_WITH_ALPHA_TEST)
	float4 baseColorTiled = BaseColorTiledMap.Sample(gAnisotropicWrapSampler, input.tc0.xy);
	clip(baseColorTiled.a - 0.5);
	testDamageAlpha(input, distance(input.Pos.xyz, gCameraPos.xyz) * gNearFarFovZoom.w);
#endif
}

// compile shaders
VertexShader_t deck_vs_c = COMPILE_VERTEX_SHADER(deck_vs());
VertexShader_t flat_shadow_vs_c = COMPILE_VERTEX_SHADER(flat_shadow_vs());
VertexShader_t lk_shadow_vs_c = COMPILE_VERTEX_SHADER(lk_shadow_vs());

PixelShader_t deferred_ps_c = COMPILE_PIXEL_SHADER(deck_deferred_ps(0));
PixelShader_t fwd_ps_c = COMPILE_PIXEL_SHADER(deck_forward_ps(0));
PixelShader_t fwd_nsm_ps_c = COMPILE_PIXEL_SHADER(deck_forward_ps(F_DISABLE_SHADOWMAP));

PixelShader_t deck_ps_map_c = COMPILE_PIXEL_SHADER(deck_ps_map());
PixelShader_t deck_ps_sat_c = COMPILE_PIXEL_SHADER(deck_ps_sat());
#if 1 //IR
PixelShader_t deck_ps_ir_c = COMPILE_PIXEL_SHADER(deck_ps_ir());
#endif
PixelShader_t deck_flat_shadow_ps_c = COMPILE_PIXEL_SHADER(deck_flat_shadow_ps());
PixelShader_t deck_lk_shadow_ps_c = COMPILE_PIXEL_SHADER(deck_lk_shadow_ps());

VertexShader_t radar_vs_c = COMPILE_VERTEX_SHADER(radar_vs());
PixelShader_t radar_ps_c = COMPILE_PIXEL_SHADER(radar_ps());
PixelShader_t radar_edge_ps_c = COMPILE_PIXEL_SHADER(radar_edge_ps());
GeometryShader radar_edge_gs_c = CompileShader(gs_4_0, radar_edge_gs());

#define TECHNIQUE_POSTFIX
#include "deck_material/deck_material_techniques.hlsl"
#undef TECHNIQUE_POSTFIX

technique11 flat_shadow
{
	pass P0
	{
		SET_RASTER_STATE_FLAT_SHADOW;

		FLAT_SHADOW_ALPHA_BLEND;

		ENABLE_FLAT_SHADOW_DEPTH_BUFFER;

		COMPILED_VERTEX_SHADER(flat_shadow_vs_c)
		SetPixelShader(deck_flat_shadow_ps_c);

		GEOMETRY_SHADER_PLUG
	}
}

technique11 lockon_shadows
{
	pass P0
	{
		COMPILED_VERTEX_SHADER(lk_shadow_vs_c)
	#if defined(SHADOW_WITH_ALPHA_TEST)
		COMPILED_PIXEL_SHADER(deck_lk_shadow_ps_c)
	#else
		SetPixelShader(NULL);
	#endif
		SetGeometryShader(NULL);
		SetDepthStencilState(shadowmapDepthState, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(shadowmapRasterizerState);
	}
}

technique11 radar
{
	pass P0
	{
		COMPILED_VERTEX_SHADER(radar_vs_c)
		COMPILED_PIXEL_SHADER(radar_ps_c)
		SetGeometryShader(NULL);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetBlendState(disableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullFront);
	}
	pass P1
	{
		SetVertexShader(radar_vs_c);
		SetGeometryShader(radar_edge_gs_c);
		SetPixelShader(radar_edge_ps_c);
		SetDepthStencilState(enableDepthBuffer, 0);
		SetBlendState(additiveAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
		SetRasterizerState(cullFront);
	}
}
