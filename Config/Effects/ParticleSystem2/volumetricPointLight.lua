Effect = {	
	{
		Type = "volumetricPointLight",
		LODdistance0 = 10000,
		Segments = 1,
		Intensity = 1,
		Softness = 1.0,
		DensityFactor = 0.025,
		Color = {255/255.0, 127/255.0, 40/255.0}
	}
}

Presets = {}
Presets.flare = deepcopy(Effect)
Presets.flare[1].Intensity = 16
Presets.flare[1].DensityFactor = 0.01
Presets.flare[1].LocalOffset = {0, 0, 0}


Presets.missiles = deepcopy(Effect)
Presets.missiles[1].RadiusFactor = 1.5

