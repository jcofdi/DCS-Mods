#ifndef MODEL_CONSTANTS_HLSL
#define MODEL_CONSTANTS_HLSL

#ifndef BUILDING_MATERIAL
	#define DEF_DEPTH_BIAS 1.0e2f
#else
	#define DEF_DEPTH_BIAS 1.0e1f
#endif

#endif
