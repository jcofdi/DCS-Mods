Effect = {
	{
		Type = "debris",
		Pass = "Opaque",

		LODdistance = 4000,

		-- mesh file | min instances | max instances |  mass to streamlining ratio | min scale | max scale
		-- final mass of each mesh instance = (mass randomized a bit) * (scale randomized)^3
		Metal = {
			"IronDestruction_V1", 0, 5, 0.03, 0.7, 1.3,
			"IronDestruction_V2", 0, 5, 0.03, 0.7, 1.3,
			"IronDestruction_V3", 0, 5, 0.03, 0.7, 1.3,
			"IronDestruction_V4", 0, 5, 0.03, 0.7, 1.3,
			"IronDestruction_V5", 0, 5, 0.03, 0.7, 1.3,
		},
		Wood = {
			"WoodBar_V1", 0, 15, 0.03, 0.8, 1.2,
			"WoodBar_V2", 0, 15, 0.03, 0.8, 1.2,
			"WoodBar_V3", 0, 15, 0.03, 0.8, 1.2,
		},
	},
}
