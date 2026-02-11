Effect = {
	{
		Type = "wingtipContrail",
		Texture = "wingtipContrail2.bmp",
		Spectrum = "visible",
		LODdistance0 = 450, -- no perlin over length
		LODdistance1 = 2500, -- not drawn
		ParticlesLimit = 400,

		ScaleBase = 0.23,
		Side = -1,

		DistMax = {
			{50*kmh_to_ms, 0.27},
			{1000*kmh_to_ms, 0.27}
		},

		TrailLength = {
			{40*kmh_to_ms, 10},
			{100*kmh_to_ms, 45},
			{500*kmh_to_ms, 80},
			{2000*kmh_to_ms, 25}
		}

	}
}

Presets = {}
Presets.leftSide = deepcopy(Effect)
Presets.leftSide[1].Side = 1
