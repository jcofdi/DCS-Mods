
technique11 normal{
	pass P0{
		FRONT_CULLING;

		DISABLE_ALPHA_BLEND;

		ENABLE_DEPTH_BUFFER;

		COMPILED_VERTEX_SHADER(flag_vs_c)
		COMPILED_PIXEL_SHADER(flag_deferred_ps_c)
		GEOMETRY_SHADER_PLUG
	}
}

technique11 forces{
	pass P0{
		FRONT_CULLING;

		DISABLE_ALPHA_BLEND;

		ENABLE_DEPTH_BUFFER;

		COMPILED_VERTEX_SHADER(flag_forces_vs_c)
		COMPILED_PIXEL_SHADER(flag_forces_deferred_ps_c)
		SetGeometryShader(flag_forces_gs_c);
	}
}
