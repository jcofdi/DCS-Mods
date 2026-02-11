Effect = {
	{
		Type 			= "carDust",
		Texture 		= "smoke6_nm.dds",
		LODdistance0 = 1500,
		LODdistance1 = 20000,
		ParticlesLimit = 400,
		ParticleLifetime = 10.0, -- must be less than ParticlesLimit*segmentLength/maxSpeedofVehicle(m/s)
		SegmentLength 	= 1.2,
		MinVel 			= 0.0,
		MaxVel 			= 15.0, 
		BaseColor       = {1.0, 0.70, 0.40},
		SecondaryColor  = {0.6, 0.4, 0.2},
	}

}

Presets =
{
	snow =
	{
		{
			Type 			= "carDust",
			Texture 		= "smoke6_nm.dds",
			LODdistance0 = 1500,
			LODdistance1 = 10000,
			ParticlesLimit = 400,
			ParticleLifetime = 10.0,
			SegmentLength 	= 1.2,
			MinVel 			= 0.0,
			MaxVel 			= 15.0, 
			BaseColor       = {1.0, 1.0, 1.0},
			SecondaryColor  = {1.0, 1.0, 1.0},
		}
	}
}