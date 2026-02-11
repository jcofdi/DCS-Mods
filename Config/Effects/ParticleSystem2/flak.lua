Effect = {
	{
		Type = "billboard",
		ColorGradientTexture = "fireGradient01.dds",
		Texture = "flak01.dds",
		AthlasSize = {16, 8},

		Visibility = 15000,
		Size = {8.75, 12.2}, -- min|max

		Scale = { -- scale over normalized time
			{0.0, 0.4},
			{0.3, 1.0},
			{1.0, 2.0},
		},
		
		Angle = {0.0, 360.0}, -- min|max
		Opacity = {0.9, 1.0}, -- min|max
		OpacityFading = {0, 0.40}, -- {fadeIn stop, fadeOut start} in percents of lifetime
		Lifetime = {15.0, 30.0}, -- min|max, seconds
		FlamePower = 10.5, -- power
		Flame = { -- flame visibility over time
			{0, 0.5},
			{0.05, 0.9},
			{0.1, 0.0},
		},

		IsSoftParticle = false,
		AnimationLoop = 0,
		AnimationFPSFactor = 0.6,-- if animation is not looped: frame = framesCount*pow(nnormalizedAge, AnimationFPSFactor); if it's looped: frame = animFPSFactor*emitterTime

		Color = {61/255.0, 70/255.0, 73/255.0, 1.0},
	},
}

Presets = {}

Presets.flak02 = deepcopy(Effect)
Presets.flak02[1].Texture = "flak02.dds"

Presets.flak03 = deepcopy(Effect)
Presets.flak03[1].Texture = "flak03.dds"
