#ifndef _ede6fb494f802b03d5b0dc877303936d_HLSL
#define _ede6fb494f802b03d5b0dc877303936d_HLSL

#ifdef ENABLE_DEBUG_UNIFORMS

// GENERATED CODE BEGIN ID: fake_lights_debug_uniforms
cbuffer fake_lights_debug_uniforms {
	float FL_DBG_SIZE_MULT;	// Multiplier of source size.
	float FL_DBG_LUMINANCE_MULT;	// Multiplier of luminance.
	float FL_DBG_MIN_SIZE_IN_PIXELS_MULT;	// Self describing.
	float FL_DBG_DISTANCE_MULT;	// Self describing.
	float FL_DBG_scatteringWeight;	// Controls how scattering affects final result. Range: [0, 1].
	float FL_DBG_softParticleMult;	// Self describing.
	float FL_DBG_transparencyVal;	// Self describing. [0, 1]
	float FL_DBG_shiftToCamera;	// Self describing. [-5, 5]
}
// GENERATED CODE END ID: fake_lights_debug_uniforms

#else

static const float FL_DBG_SIZE_MULT = 1;	// Multiplier of source size.
static const float FL_DBG_LUMINANCE_MULT = 1;	// Multiplier of luminance.
static const float FL_DBG_MIN_SIZE_IN_PIXELS_MULT = 1;	// Self describing.
static const float FL_DBG_DISTANCE_MULT = 10;	// Arttu - Change number to change the distance. DCS default is 1.
static const float FL_DBG_scatteringWeight = 1;	// Self describing.
static const float FL_DBG_softParticleMult = 1;	// Self describing.
static const float FL_DBG_transparencyVal = 0;
static const float FL_DBG_shiftToCamera = 1;

#endif

#endif
