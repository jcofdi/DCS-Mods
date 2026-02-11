Effect = {
	{
		Type 				= "heliDust",
		Texture 			= "smoke6_nm.dds",
		LODdistance 		= 40000,
		EffectTime 			= 1.0,
		ParticlesLimit 		= 400,
		ParticleLifetime 	= 4.0,
		Radius 				= 6.0,
		HeightThres			= 35.0,
		DustColor 			= {1.0, 0.70, 0.40, 0.4},
		WaterColor 			= {1.0, 1.0, 1.0, 0.1},
		SortingPointRadius  = 0.2,				-- should be from 0 to 1, this parameter shows the approximate radius to choose for the sorting point
		SortingUpdateTime   = 0.01,
	}

}


Presets =
{
	airplane =
	{
		{
			Type 				= "heliDust",
			Texture 			= "smoke6_nm.dds",
			LODdistance 		= 40000,
			EffectTime 			= 1.0,
			ParticlesLimit 		= 100,
			ParticleLifetime 	= 3.0,
			Radius 				= 4.0,
			HeightThres			= 10.0,
			DustColor 			= {0.46, 0.31, 0.18, 0.3},
			WaterColor 			= {0.9, 0.94, 0.97, 0.1},
			SortingPointRadius  = 0.2,				-- should be from 0 to 1, this parameter shows the approximate radius to choose for the sorting point
			SortingUpdateTime   = 0.001,
		}
	}
}