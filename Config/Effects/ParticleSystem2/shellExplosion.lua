Effect = {
	{
		Type = "billboard",
		ColorGradientTexture = "fireGradient01.dds",
		Texture = "flak01.dds",
		AthlasSize = {16, 8},
		IsSoftParticle = true,

		Visibility = 15000,

		Size = {0.8, 1.2}, -- base size min|max
		Scale = { -- scale over normalized time
			{0.0, 0.4},
			{0.03, 1.0},
			{0.5, 2.3},
			{1.0, 3.5},
		},

		Angle = {0.0, 360.0}, -- min|max
		Opacity = {0.20, 0.55}, -- min|max
		OpacityFading = {0, 0.40}, -- {fadeIn stop, fadeOut start} in percents of lifetime
		Lifetime = {2.0, 7.0}, -- min|max, seconds

		FlamePower = {60, 125}, -- min|max power
		Flame = { -- flame visibility over time
			{0, 0.5},
			{0.06, 0.9},
			{0.20, 0.0},
		},

		WindInfluence = {2, 1}, -- wind influence over time starting from zero. {0, 1} means full wind influence(1) from the beginning (time 0)

		Light =
		{
			Color = {230.0/255.0, 140.0/255.0, 52.0/255.0},
			Radius = 15.0,
			Lifetime = 0.11,
			Offset = {0, 0.5, 0}
		},
		SpeedAttTime = 0.45,
		AnimationLoop = 0,
		AnimationFPSFactor = 0.4,-- if animation is not looped: frame = framesCount*pow(normalizedAge, AnimationFPSFactor); if it's looped: frame = animFPSFactor*emitterTime

		Color = {18/255.0, 25/255.0, 35/255.0, 1.0},
	},
	{
		Type = "sparks",
		LODdistance = 1000,
		ParticlesLimit = 4,
		NumParticlesMin = 2,
		NumParticlesMax = 4,
		Lifetime = 0.4,
		Texture = "spark.png",
		Speed = 0.0,
		SpeedFactor = 1.0,
		SpreadFactor = 2.6;
		Scale = 2.0,
		Color = {240/255.0*2.5, 230/255.0*2.5, 0.0}
	},
	{
		Type = "debrisParticle",
		LODdistance = 1700,
		ParticlesLimit = 40,
		Lifetime = 8.0,
		Pass = "Opaque",

		WindInfluence = 0.2,
		Texture = "boom_partikles.dds",
		Scale = 0.15,
		Presets = {
		-- sort presets by scale!!!
		-- UVMin.x , UVMin.y, UVMax.x, UVMax.y, Size.x, Size.y, NumberMin, NumberMax, ScaleMin,ScaleMax, LODDistance
			-- 0.0, 	0.5, 		1.0, 	0.75, 	4, 		1, 		2, 			4, 1.2,1.6, 
			-- 0.0, 	0.75, 		1.0, 	1.0, 	4, 		1, 		2, 			3, 1.0,1.5,
			-- 0.0, 	0.0, 		1.0, 	0.25, 	4, 		1, 		2, 		    3, 1.0,1.5,
			-- 0.0, 	0.25, 		1.0, 	0.5, 	4, 		1, 		15, 		25, 0.5,0.75,
			0.0, 	0.0, 		1.0, 	0.625, 	8, 		5, 		1, 		2, 0.05,0.15,
			0.0, 	0.0, 		1.0, 	0.625, 	8, 		5, 		0.5, 		1, 0.3,0.5
		},
	}
}

Presets = {}

Presets.flak02 = deepcopy(Effect)
Presets.flak02[1].Texture = "flak02.dds"

Presets.flak03 = deepcopy(Effect)
Presets.flak03[1].Texture = "flak03.dds"


flakColor = {90/255.0, 90/255.0, 90/255.0, 1.0}

Presets.flakGrey01 = deepcopy(Effect)
Presets.flakGrey01[1].Color = flakColor

Presets.flakGrey02 = deepcopy(Presets.flak02)
Presets.flakGrey02[1].Color = flakColor

Presets.flakGrey03 = deepcopy(Presets.flak03)
Presets.flakGrey03[1].Color = flakColor


flakColor = {95/255.0, 95/255.0, 90/255.0, 1.0}

Presets.flakDust01 = deepcopy(Effect)
Presets.flakDust01[1].Color = flakColor

Presets.flakDust02 = deepcopy(Presets.flak02)
Presets.flakDust02[1].Color = flakColor

Presets.flakDust03 = deepcopy(Presets.flak03)
Presets.flakDust03[1].Color = flakColor


flakColor = {255/255.0, 217/255.0, 163/255.0, 1.0}
Presets.flakTerrains01 = deepcopy(Effect)
Presets.flakTerrains01[1].Color = flakColor

Presets.flakTerrains02 = deepcopy(Presets.flak02)
Presets.flakTerrains02[1].Color = flakColor

Presets.flakTerrains03 = deepcopy(Presets.flak03)
Presets.flakTerrains03[1].Color = flakColor

Presets.explosion = deepcopy(Effect)
Presets.explosion[2].Scale = 50*Presets.explosion[2].Scale
Presets.explosion[2].ParticlesLimit = 100
Presets.explosion[2].NumParticlesMin = 50
Presets.explosion[2].NumParticlesMax = 100
Presets.explosion[3].Scale = 50*Presets.explosion[3].Scale 
Presets.explosion[3].ParticlesLimit = 100
Presets.explosion[3].Presets = {
	-- sort presets by scale!!!
	-- UVMin.x , UVMin.y, UVMax.x, UVMax.y, Size.x, Size.y, NumberMin, NumberMax, ScaleMin,ScaleMax, LODDistance
		-- 0.0, 	0.5, 		1.0, 	0.75, 	4, 		1, 		2, 			4, 1.2,1.6, 
		-- 0.0, 	0.75, 		1.0, 	1.0, 	4, 		1, 		2, 			3, 1.0,1.5,
		-- 0.0, 	0.0, 		1.0, 	0.25, 	4, 		1, 		2, 		    3, 1.0,1.5,
		-- 0.0, 	0.25, 		1.0, 	0.5, 	4, 		1, 		15, 		25, 0.5,0.75,
		0.0, 	0.0, 		1.0, 	0.625, 	8, 		5, 		10, 		25, 0.05,0.15,
		0.0, 	0.0, 		1.0, 	0.625, 	8, 		5, 		10, 		25, 0.3,0.5
	}
