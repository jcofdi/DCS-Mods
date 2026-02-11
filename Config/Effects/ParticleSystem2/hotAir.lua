nozzleSpdMin = 200
kmh_to_ms = 1.0/3.6
Effect = {
	{
		Type = "hotAir",
		Target = "hotAir",
		
		Texture = "smoke5.dds",
		ParticlesLimit = 40,
		LODdistance = 750,

		ScaleBase = 1.3, --  meters
				
		DistMax = { -- distance between particles, m
			{(nozzleSpdMin+0)*kmh_to_ms,   8},
			{(nozzleSpdMin+500)*kmh_to_ms, 3}
		},
		LifeTime = { -- nozzle speed min + aircraft speed, time
			{(nozzleSpdMin+0)*kmh_to_ms,    2.2},
			{(nozzleSpdMin+300)*kmh_to_ms,  1.2},
			{(nozzleSpdMin+500)*kmh_to_ms,  0.5},
			{(nozzleSpdMin+700)*kmh_to_ms, 0.06}
		},
		LifeTimeJitter = { -- result lifetime = LifeTime*(1-LifeTimeJitter)
			{nozzleSpdMin*kmh_to_ms,       0.7},
			{(nozzleSpdMin+500)*kmh_to_ms, 0.5}
		},
		dtMax = { -- to determine the maximum time required for the aircraft to change its trajectory based on the speed (m/s)
			{50,  5},
			{150, 2.5},
			{300, 1}
		},
		TrailLength = {
			{0,				 30},
			{100*kmh_to_ms,	 55},
			{500*kmh_to_ms,	 90},
			{1000*kmh_to_ms, 40}
		}
	},
}

staticEffect = true
updateTimeMin = 0.015
updateTimeMax = 0.1
updateDistMin = 50
updateDistMax = 4000

nozzleSpdMin = 450
Presets = {}
Presets.KO_50 = deepcopy(Effect)
Presets.KO_50[1].ParticlesLimit = 30
Presets.KO_50[1].LODdistance = 350
Presets.KO_50[1].ScaleBase = 0.15 --  meters

Presets.KO_50[1].DistMax = { -- distance between particles, m
		{(nozzleSpdMin+0)*kmh_to_ms,   2},
		{(nozzleSpdMin+500)*kmh_to_ms, 1}
	}

Presets.KO_50[1].LifeTime = { -- nozzle speed min + aircraft speed, time
		{(nozzleSpdMin+0)*kmh_to_ms,	1.2},
		{(nozzleSpdMin+300)*kmh_to_ms,	0.6},
		{(nozzleSpdMin+500)*kmh_to_ms,	0.3},
		{(nozzleSpdMin+700)*kmh_to_ms, 0.06}
	}

	Presets.KO_50[1].LifeTimeJitter = { -- result lifetime = LifeTime*(1-LifeTimeJitter)
		{(nozzleSpdMin)*kmh_to_ms,     0.7},
		{(nozzleSpdMin+500)*kmh_to_ms, 0.5}
	}