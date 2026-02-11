Effect = {
	effectRadiusHint = 16,
	{
		Type = "FFX",
		IsShadowCaster = false,
		IsOriented = false,
		IsLightControlledByFFX = false,
		IsComputed = true, 

		FXFiles = {
			"airExplosion_01",
		},
		
		Texture = "puff01.dds",
		EffectSize = 1.0,

		Technique = "techUpdateDefault",
		LODdistance0 = 1300,
		LODdistance1 = 25000,
		ZFeather = 0,
		PositionOffset = {0, 0.12, 0},
		LightFlirAmount = 1.0,
		LightFlirLifetime = 2.0,
		LightFlirLifetimeYOffset = 0.0,
		LightFlirRadius = 8.0,
		Light =
		{
			Color = {1, 0.59, 0,1313725},
			Radius = 50 * 16, -- 16 is effectRadiusHint!
			Lifetime = 0.35,
		}
	},
	{
		Type = "blastWaveRefraction",
		Target = "hotAir",
		LODdistance = 10000,
		ExplosionRadiusHint = 16,-- must be the same as in airExplosion_01.lua config
		RadiusMin = 10.0,
		RadiusMax = 140.0 * 1.5,
		Opacity = 1.0,
		WaveSpeed = 340.29,
	},
	{
		Type = "volumetricPointLight",
		LODdistance0 = 10000,
		Segments = 1,
		Intensity = 1,
		Softness = 1.0,
		DensityFactor = 0.001,
		Color = {255/255.0, 127/255.0, 40/255.0}
	}
}

Presets = {}

Presets.fuelExplosion = deepcopy(Effect)
Presets.fuelExplosion[1].SmokeColor = {12.0/255.0, 14.0/255.0, 18.0/255.0}