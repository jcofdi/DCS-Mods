Effect = {
	{
		Type = "FFX",
		IsShadowCaster = false,
		IsOriented = false,
		IsLightControlledByFFX = false,
		EffectSize = 1.0,
		IsComputed = true, 

		FXFiles = {
			"steamExplosion_01",
		},

		TextureDiffuse = "puff01.dds",
		Texture = "puff01.dds",
		ShadingFX = "airExplosion.fx",
		Technique = "techUpdateDefault",
		LODdistance0 = 1300,
		LODdistance1 = 10000,
		ZFeather = 0,
		PositionOffset = {0, 0.12, 0},
	}
}
