function getLightInfo(effectRadius)
	return {
		Color = {1, 0.59, 0.1313725},
		Radius = 50.0 * effectRadius,
		Lifetime = 0.7,
		Offset = {0, 2.5, 0},
	}
end

defaultEffectRadiusHint = 8

Effect =
{
	effectRadiusHint = defaultEffectRadiusHint,
	{
		Type = "FFX",
		Technique = "techUpdateDefault",

		IsShadowCaster = false,
		IsOriented = false,
		IsLightControlledByFFX = true,
		IsComputed = true, 

		FXFiles = {
			-- "clusterTestFX",
			-- "clusterTestFX2",
			"groundExplosion_03_01",
			-- "groundExplosion_03_02",
			-- "groundExplosion_03_03",
			-- "groundExplosion_03_04",
			-- "groundExplosion_03_05",
		},

		Texture = "puff01.dds",

		EffectSize = 1.0,
		LODdistance0 = 1000,
		LODdistance1 = 25000,
		ZFeather = 0,
		PositionOffset = {0, 0.12, 0},
		LightFlirAmount = 1.5,
		LightFlirLifetime = 1.0,
		LightFlirYOffset = 4.0,
		LightFlirRadius = 8.0,
		
		Light = getLightInfo(8 --[[effectRadiusHint]] )
	},
	{
		Type = "groundPuff",
		-- ShadingFX = "ParticleSystem2/groundPuff.fx",
		-- UpdateFX = "ParticleSystem2/groundPuffComp.fx",
		Technique = "techUpdateReal",
		-- TechniqueLighting = "techLightingForFFX",
		IsComputed = true,
		Texture = "puff01.dds",
		LODdistance = 10000,
		EffectRadius = 40.000000,
		ClustersCount = 250,
		ParticlesPerCluster = 3,
		ClusterRadius = 1.600000,
		ParticleSize = 5.000000,
		Lifetime = 20.0,
		EffectOpacity = 1.0,
		ZFeather = 0.0,

		Color = {0.600000,0.557000,0.502000},
		
		FixedUpdateDelta = 20, --миллисекунды
		
		PositionOffset = {0, -0.1, 0}
	},
	{
		Type = "blastWave",
		Texture = "blastWave2.dds",
		LODdistance = 10000,
		RadiusMin = 20.0,
		RadiusMax = 140.0,
		Opacity = 0.16,
		WaveSpeed = 340.29,
		PositionOffset = {0, 3, 0},
	},
	{
		Type = "blastWaveRefraction",
		Target = "hotAir",
		LODdistance = 10000,
		RadiusMin = 20.0,
		RadiusMax = 140.0 * 1.5,
		WaveSpeed = 340.29,
		PositionOffset = {0, 3, 0},
		Opacity = 1.0,
	},
	{
		Type = "debris",
		Pass = "Opaque",

		LODdistance = 1700,

		ReferenceExplosionRadius = defaultEffectRadiusHint, -- same as effectRadiusHint

		-- mesh file | min instances | max instances | mass to streamlining ratio | min scale | max scale
		-- Final mass of each mesh instance = (mass randomized a bit) * (scale randomized)^3.
		-- Mass to streamlining ratio affects initial speed of each mesh
		-- Mass to streamlining ratio is expected to be in range of 0.02 to 0.06, less is for solid and inswept objects, more for some fluff
		Metal = {
			"IronDestruction_V1", 0, 15, 0.04, 0.5, 1.5,
			"IronDestruction_V2", 0, 15, 0.025, 0.5, 1.5,
			"IronDestruction_V3", 0, 15, 0.05, 0.5, 1.5,
			"IronDestruction_V4", 0, 15, 0.06, 0.5, 1.5,
			"IronDestruction_V5", 0, 15, 0.02, 0.5, 1.5,
		},
		Dirt = {
			"Ground_V1", 0, 15, 0.035, 0.11, 1.9,
			"Ground_V2", 0, 15, 0.04, 0.11, 1.9,
			"Ground_V3", 0, 15, 0.021, 0.11, 1.9,
			"Ground_V4", 0, 15, 0.055, 0.11, 1.9,
			"Ground_V5", 0, 15, 0.025, 0.11, 1.9,
		},
		Brick = {
			"Bricks_V1", 0, 15, 0.02, 1, 1,
			"Bricks_V2", 0, 15, 0.03, 1, 1,
			"Bricks_V3", 0, 15, 0.02, 1, 1,
			"Bricks_V4", 0, 15, 0.03, 1, 1,
		},
		Concrete = {
			"ConcreteDestruction_V1", 0, 10, 0.03, 0.9, 1.1,
			"ConcreteDestruction_V2", 0, 10, 0.035, 0.9, 1.1,
			"ConcreteDestruction_V3", 0, 10, 0.02, 0.9, 1.1,
			"ConcreteDestruction_V4", 0, 10, 0.03, 0.9, 1.1,
			"ConcreteDestruction_V5", 0, 10, 0.04, 0.9, 1.1,
		},
		Wood = {
			"WoodBar_V1", 0, 15, 0.025, 0.8, 1.2,
			"WoodBar_V2", 0, 15, 0.03, 0.8, 1.2,
			"WoodBar_V3", 0, 15, 0.02, 0.8, 1.2,
		},
		Log = {
			"Log_V1", 0, 10, 0.025, 0.8, 1.2,
			"Log_V2", 0, 10, 0.026, 0.8, 1.2,
			"Log_V3", 0, 10, 0.019, 0.8, 1.2,
		},
	},
	{
		Type = "volumetricPointLight",
		LODdistance0 = 20000,
		Segments = 1,
		Intensity = 1,
		Softness = 1.0,
		DensityFactor = 0.0009,
		RadiusFactor = 1.0,
		Color = {255/255.0, 127/255.0, 40/255.0},
		PositionOffset = {0, 5, 0}
	}
}

Presets = {}
Presets.hedgehogForIgor = deepcopy(Effect)
Presets.hedgehogForIgor.effectRadiusHint = 10 -- 10 as if a explosion doesn't touch the ground (~5 real radius)
Presets.hedgehogForIgor[1] =
{
	Type = "GPUExplosion",
	ShadingFX = "ParticleSystem2/GPUExplosion.fx",
	UpdateFX  = "ParticleSystem2/hedgehogExplosionComp.fx",
	Technique = "techHedgehog",
	IsComputed = true, 

	Texture = "puff01.dds",
	LODdistance0 = 1500,
	LODdistance1 = 25000,
	ClustersCount = 1000,
	ParticlesCount = 1,
	ClusterRadius = 1.6,
	ParticleSize = 5.0,
	Lifetime = 15.0,
	VertSpeedFactorMax = {2.0, 3.8},

	VariantsCount = 5,

	Color = {120/255.0, 108/255.0, 92/255.0},
	
	FixedUpdateDelta = 20, --миллисекунды
	
	PositionOffset = {0, 0.12, 0},
	
	GlowBillboardSizeMax = 150,
	GlowBillboardBrightness = 0.5,
	GlowBillboardPos = {0, 2, 0},
	GlowPowerOverLive = {{0.0, 0.5},{0.1, 1.0},{0.3, 0.0}},
	
	LightFlirAmount = 1.5,
	LightFlirLifetime = 1.0,
	LightFlirYOffset = 4.0,
	LightFlirRadius = 8.0,

	Light = getLightInfo(Presets.hedgehogForIgor.effectRadiusHint),
}

-- NAPALM
Presets.napalm = deepcopy(Effect)
Presets.napalm.effectRadiusHint = 20.0
Presets.napalm[1] =
{
	Type = "FFX",
	FXFiles = {
		"groundExplosion_napalm",
	},
	Light = getLightInfo(Presets.napalm.effectRadiusHint),
	LightFlirAmount = 1.5,
	LightFlirLifetime = 1.0,
	LightFlirYOffset = 4.0,
	LightFlirRadius = 8.0,
	IsComputed = true, 
}
Presets.napalm[1].Light.Radius = 30 * Presets.napalm.effectRadiusHint
Presets.napalm[1].Light.Lifetime = 2.5
Presets.napalm[6].DensityFactor = 0.005
Presets.napalm[2].FixedUpdateDelta = 20 --миллисекунды
Presets.napalm[2].EffectRadius = 60.000000
Presets.napalm[2].ClustersCount = 250
Presets.napalm[2].ParticlesPerCluster = 2
Presets.napalm[2].ClusterRadius = 2.600000
Presets.napalm[2].ParticleSize = 10.000000
Presets.napalm[2].Color = {0.600000,0.557000,0.502000}
Presets.napalm[3] = {
	Type = "blastWave",
	LODdistance = 12000,
	RadiusMin = 20.0,
	RadiusMax = 190.0,
	WaveSpeed = 340.29,
	Opacity = 0.16,
}
Presets.napalm[4] = {
	Type = "blastWaveRefraction",
	LODdistance = 12000,
	RadiusMin = 20.0,
	RadiusMax = 190.0 * 1.5,
	WaveSpeed = 340.29,
	Opacity = 1.0,
	Target = "hotAir"
}

-- BIG
Presets.big = deepcopy(Effect)
Presets.big.effectRadiusHint = 20.0
Presets.big[1] = {
	Type = "FFX",
	FXFiles = {
		"groundExplosion_big",
	},
	Light = getLightInfo(Presets.big.effectRadiusHint),
	LightFlirAmount = 1.5,
	LightFlirLifetime = 1.0,
	LightFlirYOffset = 4.0,
	LightFlirRadius = 8.0,
	IsComputed = true, 
}
Presets.big[2].Type = "groundPuff"
Presets.big[2].EffectRadius = 80.000000
Presets.big[2].ClustersCount = 250
Presets.big[2].ParticlesPerCluster = 3
Presets.big[2].ClusterRadius = 2.600000
Presets.big[2].ParticleSize = 10.000000
Presets.big[2].Color = {0.600000,0.557000,0.502000}
Presets.big[3] = {
	Type = "blastWave",	
	LODdistance = 12000,
	RadiusMin = 20.0,
	RadiusMax = 240.0,
	WaveSpeed = 340.29,
	Opacity = 0.16,
}
Presets.big[4] = {
	Type = "blastWaveRefraction",
	Target = "hotAir",
	LODdistance = 12000,
	RadiusMin = 20.0,
	RadiusMax = 240.0 * 1.5,
	WaveSpeed = 340.29,
	Opacity = 1.0,
}

-- NAR
Presets.nar = deepcopy(Effect)
Presets.nar.effectRadiusHint = 11.0
Presets.nar[1] = {
	Type = "FFX",
	FXFiles = {
		"groundExplosion_nar",
	},
	Light = getLightInfo(Presets.nar.effectRadiusHint),
	EffectSize = 1.0,
	SortPoint = 1.0,
	LightFlirAmount = 1.5,
	LightFlirLifetime = 1.0,
	LightFlirYOffset = 4.0,
	IsComputed = true, 
	LightFlirRadius = 8.0,
}
Presets.nar[2] = {
	Type = "groundPuff",
	IsComputed = true,
	FixedUpdateDelta = 20, --миллисекунды
	Texture = "puff01.dds",
	EffectRadius = 30.000000,
	ClustersCount = 100,
	ParticlesPerCluster = 3,
	ClusterRadius = 1.600000,
	ParticleSize = 5.000000,
	Color = {0.600000,0.557000,0.502000},
	PositionOffset = {0, -0.1, 0}
}
Presets.nar[3] = {
	Type = "blastWave",	
	LODdistance = 10000,
	RadiusMin = 15.0,
	RadiusMax = 100.0,
	WaveSpeed = 340.29,
	Opacity = 0.16,
}
Presets.nar[4] = {
	Type = "blastWaveRefraction",
	LODdistance = 10000,
	RadiusMin = 15.0,
	RadiusMax = 100.0 * 1.5,
	WaveSpeed = 340.29,
	Opacity = 1.0,
	Target = "hotAir"
}

Presets.narSmall = deepcopy(Effect)
Presets.narSmall.effectRadiusHint = 11.0 * 0.75
Presets.narSmall[1] = {
	Type = "FFX",
	FXFiles = {
		"groundExplosion_nar",
	},
	Light = getLightInfo(Presets.narSmall.effectRadiusHint),
	EffectSize = 0.75,
	LightFlirAmount = 1.2,
	LightFlirLifetime = 1.0,
	LightFlirYOffset = 4.0,
	LightFlirRadius = 6.0,
	IsComputed = true, 
}
Presets.narSmall[2] = {
	Type = "groundPuff",
	IsComputed = true,
	FixedUpdateDelta = 20, --миллисекунды
	Texture = "puff01.dds",
	EffectRadius = 20.000000,
	ClustersCount = 80,
	ParticlesPerCluster = 3,
	ClusterRadius = 1.200000,
	ParticleSize = 5.000000,
	Color = {0.600000,0.557000,0.502000},
	PositionOffset = {0, -0.1, 0}
}
Presets.narSmall[3] = {
	Type = "blastWave",	
	LODdistance = 10000,
	RadiusMin = 12.0,
	RadiusMax = 75.0,
	WaveSpeed = 340.29,
	Opacity = 0.16,
}
Presets.narSmall[4] = {
	Type = "blastWaveRefraction",
	LODdistance = 10000,
	RadiusMin = 12.0,
	RadiusMax = 75.0 * 1.5,
	WaveSpeed = 340.29,
	Opacity = 1.0,
	Target = "hotAir"
}

