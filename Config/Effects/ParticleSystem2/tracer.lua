function gammaToLinearSpace(srgb)
	return {srgb[1]*srgb[1], srgb[2]*srgb[2], srgb[3]*srgb[3], srgb[4]}
end

Effect =
{
	{
		Type = "tracer",
		Texture = "tracer2.dds",

		Visibility = 40000,
		Size = {4.0, 0.6}, -- length, width
		SunFactors = {0.06, 0.2, 2.0}, -- scaling of tracer length by sunY, length = Size.x * (1.0f + SunFactors.z * (1.0f - saturate((sunY + SunFactors.x)/SunFactors.y)));
		Brightness = 4.0,

		Color = {255/255.0, 140/255.0, 30/255.0, 1.0}, -- gold
	},
	{
		Type = "volumetricPointLight",
		LODdistance0 = 10000,
		Segments = 1,
		Softness = 0.9,
		Intensity = 15,
		DensityFactor = 0.01,
		ScaleX = 2.5,
		LocalOffset = {-5, 0, 0},
		Color = gammaToLinearSpace({255/255.0, 140/255.0, 30/255.0, 1.0}), -- gold
	}
}


Presets = {}

Presets.white = deepcopy(Effect)
Presets.white[1].Color = {0.65, 0.65, 0.65, 1.0}
Presets.white[2].Color = gammaToLinearSpace(Presets.white[1].Color)

Presets.red = deepcopy(Effect)
Presets.red[1].Color = {1.0, 0.2, 0.2, 1.0}
Presets.red[2].Color = gammaToLinearSpace(Presets.red[1].Color)

Presets.green = deepcopy(Effect)
Presets.green[1].Color = {44/255.0, 255/255.0, 11/255.0, 1.0}
Presets.green[2].Color = gammaToLinearSpace(Presets.green[1].Color)

Presets.yellow = deepcopy(Effect)
Presets.yellow[1].Color = {255/255.0, 180/255.0, 21/255.0, 1.0}
Presets.yellow[2].Color = gammaToLinearSpace(Presets.yellow[1].Color)

Presets.gold 		  = deepcopy(Effect)
Presets.gold[1].Color = {255/255.0, 140/255.0, 10/255.0, 1.0}
Presets.gold[2].Color = gammaToLinearSpace(Presets.gold[1].Color)

Presets.FLIR =
{
	{
		Type = "tracer",
		Target = "FLIR",
		Color = {0.5, 0.5, 0.5, 1.0},
		Size = {0.2, 0.4}, -- length, width
		Brightness = 0.5,
	}
}
