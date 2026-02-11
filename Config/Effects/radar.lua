radar = 
{
	presets = 
	{

		MAP =  {
			viewport = { 0.09, 0.09, 0.82, 0.82 },
			color = {0.0, 1.0, 0.0, 1.0},
			blurAngle = 3.3,
			mode = "rbm"
		},
		EXP1 =  {
			viewport = { 0.09, 0.09, 0.82, 0.82 },
			color = {0.0, 1.0, 0.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 19;
			quantization = 8;
			blankAngle = 5.0,
			mode = "dbs"
		},
		EXP2 =  {
			viewport = { 0.09, 0.09, 0.82, 0.82 },
			color = {0.0, 1.0, 0.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 67;
			quantization = 8;
			blankAngle = 5.0,
			mode = "dbs"
		},
		EXP3 =  {
			viewport = { 0.09, 0.09, 0.82, 0.82 },
			color = {0.0, 1.0, 0.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 120;
			quantization = 8;
			blankAngle = 5.0,
			mode = "dbs"
		},

		JF_17 =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {0.0, 1.0, 0.0, 1.0},
			blurAngle = 3.3,
			mode = "rbm"
		},

		GM_F16 =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			blurAngle = 1.0,
			mode = "rbm"
		},
		GM_F16_RBM =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			blurAngle = 3.3,
			mode = "rbm"
		},
		EXP_F16 =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 19;
			quantization = 8;
			blankAngle = 0.0,
			mode = "dbs"
		},
		DBS1_F16 =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 67;
			quantization = 8;
			blankAngle = 0.0,
			mode = "dbs"
		},
		DBS2_F16 =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			blurAngle = 3.3,
			omega = 1.13446;
			resolution = 120;
			quantization = 8;
			blankAngle = 0.0,
			mode = "dbs"
		},
		AH64D_RMAP =  {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			verticalAngle = 6.25,
			overlapAngle = 0.125,
			blurAngle = 0.0,
			mode = "rmap"
		},
		AH64D_TPM_FAR = {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			deadSpace = { 251.7 / 2500, -295.9 / 2500 },
			elevationBias = 4.8768,
			clearancePlane = 30.48,
			mode = "tpm"
		},
		AH64D_TPM_NEAR = {
			viewport = { 0.0, 0.0, 1.0, 1.0 },
			color = {1.0, 1.0, 1.0, 1.0},
			deadSpace = { 141.9 / 2500, -407.2 / 2500 },
			elevationBias = 4.8768,
			clearancePlane = 30.48,
			mode = "tpm"
		},
		F18_TA = {
			viewport = { 0.09, 0.09, 0.82, 0.82 },
			color = {1.0, 1.0, 1.0, 1.0},
			clearancePlane = 152.4,
			mode = "ta"
		},

	}
};
