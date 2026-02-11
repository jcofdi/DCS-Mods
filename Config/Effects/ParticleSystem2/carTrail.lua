Effect = {
	{
		Type = "carTrail",
		Target = "main",
		Pass = "DecalForward",

		--Texture = "foam2.png",
		--Texture = "track_wheel.dds",
		--TextureCar = "track_wheel.dds",

		--AlbedoTex = "Voronka.dds", 
		AlbedoTex = "track_wheel.dds", 
		RoughMetTex = "Voronka_RoughMet.dds",
		NormalTex = "Voronka_Normal.tga",
		Length = 50,
		LODdistance = 10000,
		--ParticlesLimit = 400,
		SegmentLength = 5.0,
		SpeedThreshold = 0.001,
		
		DistMax = {
			{0, 0.1},
			{50, 0.1},
		},

		LifeTime = {
			{0, 0.0},
			{20, 2.4},
			{50, 2.2},
		}
	}

}


updateTimeMin = 0.015
updateTimeMax = 0.15
updateDistMin = 500
updateDistMax = 4000
