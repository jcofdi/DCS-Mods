Effect = {
	{
		Type = "bulletImpact",
		LODdistance0 = 3000, -- m
		LODdistance1 = 15000,
		Texture = "normalSemiSphere2.tga",
		TextureFoam = "foam_03.dds",
		TextureTerrainNoise = "smoke5.dds",
		ParticlesLimit = 100,
		Terrain = true,
	},

}

staticEffect = true
staticEffectLifetime = 5

Presets = {}
Presets.water = deepcopy(Effect)
Presets.water[1].Terrain = false
Presets.water[2] = 
{
	Type = "bulletImpactOnWater",
	Spectrum = "visible",
	LODdistance 		= 3000, -- m
	Lifetime 			= 8.0,
	Scale 				= 1.0,
	TextureWater 		= "splashOnWater.png",
	TextureWaterNormal 	= "splashOnWaterNormal.png",
}
