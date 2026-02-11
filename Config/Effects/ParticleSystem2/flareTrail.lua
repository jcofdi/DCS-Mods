Effect = {	
	{
		Type = "flareTrail",
		Texture = "smoke6_nm.dds",
		TextureGlow = "flareGlow.dds",
		GlowOnly = false, -- no trail if true
		LODdistance = 4000, -- m
		Length = 1000,	-- m
		SegmentLength = 30,	-- m
		ScaleBase = 1.4, --  meters
		Lighting = 0.85,
		DetailFactorMax = 5.0, --  max particles in segment = 2^(1+detailFactor). 5 - maximum
		GlowDistFactor = 0.0005, -- glow scale = scale * (1 + GlowDistFactor * depth)
		DifferentGlow = false,
		FlirBrightnessFactor = 0.9,
	},
}

Presets = {}

--сигнальная ракета
Presets.signalFlare = deepcopy(Effect)
Presets.signalFlare[1].LODdistance = 2000 -- m
Presets.signalFlare[1].Length = 200	-- m
Presets.signalFlare[1].SegmentLength = 20 -- m
Presets.signalFlare[1].ScaleBase = 0.8 -- meters
Presets.signalFlare[1].GlowDistFactor = 0.0018

--tracking flare for MCLOS missiles
Presets.trackingFlare = deepcopy(Effect)
Presets.trackingFlare[1].LODdistance = 10000 -- m
Presets.trackingFlare[1].Length = 100 -- m
Presets.trackingFlare[1].SegmentLength = 10 -- m
Presets.trackingFlare[1].ScaleBase = 0.7 -- meters
Presets.trackingFlare[1].GlowDistFactor = 0.0018

-- tracking flare stage 2
Presets.trackingFlare2 = deepcopy(Effect)
Presets.trackingFlare2[1].LODdistance = 10000 -- m
Presets.trackingFlare2[1].Length = 300 -- m
Presets.trackingFlare2[1].SegmentLength = 30 -- m
Presets.trackingFlare2[1].ScaleBase = 1.2 -- meters
Presets.trackingFlare2[1].GlowDistFactor = 0.0018

-- Rapier flare trail
Presets.rapierFlareTrail = deepcopy(Effect)
Presets.rapierFlareTrail[1].LODdistance = 10000 --
Presets.rapierFlareTrail[1].ScaleBase = 0.08 -- meters
Presets.rapierFlareTrail[1].SegmentLength = 10
Presets.rapierFlareTrail[1].Length = 50
Presets.rapierFlareTrail[1].GlowDistFactor = 0.0018
Presets.rapierFlareTrail[1].GlowOnly = true

--сигнальная ракета на земле
Presets.signalFlareGround = deepcopy(Effect)
Presets.signalFlareGround[1].LODdistance = 10000 -- m
Presets.signalFlareGround[1].GlowOnly = true
Presets.signalFlareGround[1].GlowDistFactor = 0.0018

--сигнальная ракета на земле
Presets.differentGlow = deepcopy(Effect)
Presets.differentGlow[1].LODdistance = 10000 -- m
Presets.differentGlow[1].DifferentGlow = true