Effect = {
	{
		Type = "smoke",
		LODdistance = 150000.0,
		Texture = "puff01.dds",
		-- Texture = "puff02.dds",

		ColorGradientTexture = "fireGradient01.dds",
		AlphaGradientTexture = "fireGradient01.dds",

		ParticlesLimit = 7, -- 2 minimum
		Density = 0.2,
		Radius = {150, 750},-- start, finish
		RadiusFactor = 1.0,
		Length = 1500,
		TrailSpeedMin = 15,
		HeightFactor = 0.15,

		AnimSpeed = 30, -- FPS

		Color = {61/255.0, 70/255.0, 73/255.0},
		Opacity = 0.5,
		Lighting = 0.6,

		FlameAttenuation = {-92, 280}, -- meters from smoke start
		FlamePower = 5.0*9,
		FlameFactor = 1.5,
		DyingTime = 30.0,
		Light =
		{
			Color = {1, 0.45, 0.09},
			Radius = 400.0,
			Lifetime = 10000000.0,
			Offset = {0, 0.5, 0},
		}
	},
}

staticEffect = true

volumetricLight = 
{
	Type = "volumetricPointLight",
	LODdistance0 = 10000,
	Segments = 1,
	Intensity = 1,
	Softness = 1.0,
	DensityFactor = 0.001,
	Color = {255/255.0, 127/255.0, 40/255.0},
	PositionOffset = {0, 5, 0}
}

Presets = {}
Presets.hugeSmokeWithFire = deepcopy(Effect)
Presets.hugeSmokeWithFire[1].Light.Color = {1, 0.45, 0.09}
Presets.hugeSmokeWithFire[1].Light.Radius = 500.0
Presets.hugeSmokeWithFire[1].Light.LODdistance = 150000
Presets.hugeSmokeWithFire[1].Light.Lifetime = 1000.0
Presets.hugeSmokeWithFire[1].Light.Offset = {0, 2.0, 0}
Presets.hugeSmokeWithFire[2] = deepcopy(volumetricLight)

Presets.hugeSmoke = deepcopy(Presets.hugeSmokeWithFire)
Presets.hugeSmoke[1].FlameAttenuation = {-100, -1.0}
Presets.hugeSmoke[1].Light.Radius = 0

Presets.largeSmokeWithFire = deepcopy(Effect)
Presets.largeSmokeWithFire[1].Density = 0.2
Presets.largeSmokeWithFire[1].Radius = {80, 370} -- start, finish
Presets.largeSmokeWithFire[1].RadiusFactor = 1.0
Presets.largeSmokeWithFire[1].Length = 800
Presets.largeSmokeWithFire[1].TrailSpeedMin = 10
Presets.largeSmokeWithFire[1].HeightFactor = 0.15
Presets.largeSmokeWithFire[1].LODdistance = 150000
Presets.largeSmokeWithFire[1].AnimSpeed = 60 -- FPS
Presets.largeSmokeWithFire[1].Color = {61/255.0, 70/255.0, 73/255.0}
Presets.largeSmokeWithFire[1].Opacity = 1.0
Presets.largeSmokeWithFire[1].Lighting = 0.6
Presets.largeSmokeWithFire[1].FlameAttenuation = {-50, 150} -- meters from smoke start
Presets.largeSmokeWithFire[1].FlamePower = 5.0*9
Presets.largeSmokeWithFire[1].FlameFactor = 1.5
Presets.largeSmokeWithFire[1].Light.Color = {1, 0.45, 0.09}
Presets.largeSmokeWithFire[1].Light.Radius = 300.0
Presets.largeSmokeWithFire[1].Light.Lifetime = 1000.0
Presets.largeSmokeWithFire[1].Light.Offset = {0, 2.0, 0}
Presets.largeSmokeWithFire[2] = deepcopy(volumetricLight)

Presets.largeSmoke = deepcopy(Presets.largeSmokeWithFire)
Presets.largeSmoke[1].FlameAttenuation = {-100, -1.0}
Presets.largeSmoke[1].Light.Radius = 0

Presets.mediumSmokeWithFire = deepcopy(Effect)
Presets.mediumSmokeWithFire[1].Density = 0.2
Presets.mediumSmokeWithFire[1].Radius = {35, 170} -- start, finish
Presets.mediumSmokeWithFire[1].RadiusFactor = 1.0
Presets.mediumSmokeWithFire[1].Length = 350
Presets.mediumSmokeWithFire[1].TrailSpeedMin = 10
Presets.mediumSmokeWithFire[1].HeightFactor = 0.15
Presets.mediumSmokeWithFire[1].LODdistance = 50000
Presets.mediumSmokeWithFire[1].AnimSpeed = 65 -- FPS
Presets.mediumSmokeWithFire[1].Color = {61/255.0, 70/255.0, 73/255.0}
Presets.mediumSmokeWithFire[1].Opacity = 1.0
Presets.mediumSmokeWithFire[1].Lighting = 0.6
Presets.mediumSmokeWithFire[1].FlameAttenuation = {-20, 60} -- meters from smoke start
Presets.mediumSmokeWithFire[1].FlamePower = 5.0*9
Presets.mediumSmokeWithFire[1].FlameFactor = 1.5
Presets.mediumSmokeWithFire[1].Light.Color = {1, 0.45, 0.09}
Presets.mediumSmokeWithFire[1].Light.Radius = 200.0
Presets.mediumSmokeWithFire[1].Light.Lifetime = 1000.0
Presets.mediumSmokeWithFire[1].Light.Offset = {0, 2.0, 0}
Presets.mediumSmokeWithFire[2] = deepcopy(volumetricLight)

Presets.mediumSmoke = deepcopy(Presets.mediumSmokeWithFire)
Presets.mediumSmoke[1].FlameAttenuation = {-100, -1.0}
Presets.mediumSmoke[1].Light.Radius = 0

Presets.smallSmokeWithFire = deepcopy(Effect)
Presets.smallSmokeWithFire[1].Density = 0.2
Presets.smallSmokeWithFire[1].Radius = {15, 80} -- start, finish
Presets.smallSmokeWithFire[1].RadiusFactor = 1.0
Presets.smallSmokeWithFire[1].Length = 150
Presets.smallSmokeWithFire[1].TrailSpeedMin = 5
Presets.smallSmokeWithFire[1].HeightFactor = 0.25
Presets.smallSmokeWithFire[1].LODdistance = 50000
Presets.smallSmokeWithFire[1].DyingTime = 6.5
Presets.smallSmokeWithFire[1].AnimSpeed = 70 --FPS
Presets.smallSmokeWithFire[1].Color = {61/255.0*0.8, 70/255.0*0.8, 73/255.0*0.8}
Presets.smallSmokeWithFire[1].Opacity = 1.0
Presets.smallSmokeWithFire[1].Lighting = 0.6
Presets.smallSmokeWithFire[1].FlameAttenuation = {-10, 30} -- meters from smoke start
Presets.smallSmokeWithFire[1].FlamePower = 5.0*9
Presets.smallSmokeWithFire[1].FlameFactor = 1.5
Presets.smallSmokeWithFire[1].Light.Color = {1, 0.45, 0.09}
Presets.smallSmokeWithFire[1].Light.Radius = 100.0
Presets.smallSmokeWithFire[1].Light.Lifetime = 1000.0
Presets.smallSmokeWithFire[1].Light.Offset = {0, 2.0, 0}
Presets.smallSmokeWithFire[2] = deepcopy(volumetricLight)

Presets.smallSmoke = deepcopy(Presets.smallSmokeWithFire)
Presets.smallSmoke[1].FlameAttenuation = {-100, -1.0}
Presets.smallSmoke[1].Light.Radius = 0

Presets.smokeMarkerBlack = deepcopy(Presets.smallSmoke)
Presets.smokeMarkerBlack[1].Length = 50
Presets.smokeMarkerBlack[1].Radius = {4, 35}
Presets.smokeMarkerBlack[1].PositionOffsetLocal = {0, -1, 0}

Presets.smokeMarkerGreen = deepcopy(Presets.smokeMarkerBlack)
Presets.smokeMarkerGreen[1].Color = {0.5, 0.95, 0.15}

Presets.smokeMarkerOrange = deepcopy(Presets.smokeMarkerGreen)
Presets.smokeMarkerOrange[1].Color = {0.95, 0.6, 0.15}

Presets.smokeMarkerRed = deepcopy(Presets.smokeMarkerGreen)
Presets.smokeMarkerRed[1].Color = {0.85, 0.15, 0.15}

Presets.miniSmokeWithFire = deepcopy(Effect)
Presets.miniSmokeWithFire[1].Density = 0.2
Presets.miniSmokeWithFire[1].Radius = {8, 40} -- start, finish
Presets.miniSmokeWithFire[1].RadiusFactor = 1.0
Presets.miniSmokeWithFire[1].Length = 80
Presets.miniSmokeWithFire[1].TrailSpeedMin = 2.5
Presets.miniSmokeWithFire[1].HeightFactor = 0.25
Presets.miniSmokeWithFire[1].AnimSpeed = 70 -- FPS
Presets.miniSmokeWithFire[1].LODdistance = 50000
Presets.miniSmokeWithFire[1].Color = {61/255.0*0.8, 70/255.0*0.8, 73/255.0*0.8}
Presets.miniSmokeWithFire[1].Opacity = 1.0
Presets.miniSmokeWithFire[1].Lighting = 0.6
Presets.miniSmokeWithFire[1].FlameAttenuation = {-5, 15} -- meters from smoke start
Presets.miniSmokeWithFire[1].FlamePower = 5.0*9
Presets.miniSmokeWithFire[1].FlameFactor = 1.5
Presets.miniSmokeWithFire[1].Light.Color = {1, 0.45, 0.09}
Presets.miniSmokeWithFire[1].Light.Radius = 75.0
Presets.miniSmokeWithFire[1].Light.Lifetime = 1000.0
Presets.miniSmokeWithFire[1].Light.Offset = {0, 2.0, 0}
Presets.miniSmokeWithFire[2] = deepcopy(volumetricLight)

Presets.areaSmokeWithFire = deepcopy(Effect)
Presets.areaSmokeWithFire[1] = deepcopy(Effect[1])
Presets.areaSmokeWithFire[2] = deepcopy(Effect[1])
Presets.areaSmokeWithFire[3] = deepcopy(Effect[1])
Presets.areaSmokeWithFire[4] = deepcopy(volumetricLight)

Presets.areaSmokeWithFire[1].Density = 0.2
Presets.areaSmokeWithFire[1].Radius = {15, 80} -- start, finish
Presets.areaSmokeWithFire[1].RadiusFactor = 1.0
Presets.areaSmokeWithFire[1].Length = 150
Presets.areaSmokeWithFire[1].TrailSpeedMin = 5
Presets.areaSmokeWithFire[1].HeightFactor = 0.25
Presets.areaSmokeWithFire[1].LODdistance = 50000
Presets.areaSmokeWithFire[1].AnimSpeed = 70 -- FPS
Presets.areaSmokeWithFire[1].Color = {61/255.0*0.8, 70/255.0*0.8, 73/255.0*0.8}
Presets.areaSmokeWithFire[1].Opacity = 1.0
Presets.areaSmokeWithFire[1].Lighting = 0.6
Presets.areaSmokeWithFire[1].FlameAttenuation = {-10, 30} -- meters from smoke start
Presets.areaSmokeWithFire[1].FlamePower = 5.0*9
Presets.areaSmokeWithFire[1].FlameFactor = 1.5

Presets.areaSmokeWithFire[2].Density = 0.25
Presets.areaSmokeWithFire[2].Radius = {5, 50} -- start, finish
Presets.areaSmokeWithFire[2].RadiusFactor = 1.0
Presets.areaSmokeWithFire[2].Length = 65
Presets.areaSmokeWithFire[2].TrailSpeedMin = 4
Presets.areaSmokeWithFire[2].HeightFactor = 0.25
Presets.areaSmokeWithFire[2].AnimSpeed = 90 -- FPS
Presets.areaSmokeWithFire[2].Color = {61/255.0*0.8, 70/255.0*0.8, 73/255.0*0.8}
Presets.areaSmokeWithFire[2].Opacity = 0.9
Presets.areaSmokeWithFire[2].Lighting = 0.65
Presets.areaSmokeWithFire[2].FlameAttenuation = {-10, 38} -- meters from smoke start
Presets.areaSmokeWithFire[2].FlamePower = 5.0*9
Presets.areaSmokeWithFire[2].FlameFactor = 1.4
Presets.areaSmokeWithFire[2].PositionOffsetLocal = {-6.5, -0.5, -7.543}
Presets.areaSmokeWithFire[2].LODdistance = 50000.0
Presets.areaSmokeWithFire[2].Points = 7 -- 2 minimum

Presets.areaSmokeWithFire[3].LODdistance = 50000.0
Presets.areaSmokeWithFire[3].Points = 7 -- 2 minimum
Presets.areaSmokeWithFire[3].Density = 0.15
Presets.areaSmokeWithFire[3].Radius = {4, 40} -- start, finish
Presets.areaSmokeWithFire[3].RadiusFactor = 0.75
Presets.areaSmokeWithFire[3].Length = 80
Presets.areaSmokeWithFire[3].TrailSpeedMin = 3
Presets.areaSmokeWithFire[3].HeightFactor = 0.2
Presets.areaSmokeWithFire[3].AnimSpeed = 85 -- FPS
Presets.areaSmokeWithFire[3].Color = {61/255.0*0.8, 70/255.0*0.8, 73/255.0*0.8}
Presets.areaSmokeWithFire[3].Opacity = 0.95
Presets.areaSmokeWithFire[3].Lighting = 0.5
Presets.areaSmokeWithFire[3].FlameAttenuation = {-10, 35} -- meters from smoke start
Presets.areaSmokeWithFire[3].FlamePower = 5.0*9
Presets.areaSmokeWithFire[3].FlameFactor = 1.6
Presets.areaSmokeWithFire[3].PositionOffsetLocal = {7.23, -0.75, 6.2}

Effect[2] = deepcopy(volumetricLight)