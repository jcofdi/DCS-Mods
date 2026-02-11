#include "common/States11.hlsl"
#include "common/ShadowStates.hlsl"

#include "flag_uniforms.hlsl"
#include "flag_vs.hlsl"
#include "flag_ps.hlsl"
#include "flag_gs.hlsl"

// compile shaders
VertexShader flag_vs_c = COMPILE_VERTEX_SHADER(flag_vs());
VertexShader flag_forces_vs_c = COMPILE_VERTEX_SHADER(flag_forces_vs());
PixelShader flag_deferred_ps_c = COMPILE_PIXEL_SHADER(flag_deferred_ps());
PixelShader flag_forces_deferred_ps_c = COMPILE_PIXEL_SHADER(flag_forces_deferred_ps());
GeometryShader flag_forces_gs_c = CompileShader(gs_4_0, flag_forces_gs());

#define TECHNIQUE_POSTFIX
#include "flag_material_techniques.hlsl"
#undef TECHNIQUE_POSTFIX
