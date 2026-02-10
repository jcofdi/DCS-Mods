#ifndef SSS_HLSL
#define SSS_HLSL

Texture2D<float> SSSMap;
Texture2D<float> SSS_Depth;

float getSSS(uint2 texCoord) {
	return SSSMap.Load(uint3(texCoord, 0)).x;
}

static const int2 offs[] = {
	{ 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 },
};

float getSSS_MSAA(uint2 texCoord, float depth) {
	const float SIGMA = 0.001;
	
	float acc = 0, wa = 1e-9;
	
	[unroll]
	for (uint i = 0; i < 4; ++i) {
		uint2 tc = texCoord + offs[i];
		float s = SSSMap.Load(uint3(tc, 0)).x;
		float d = SSS_Depth.Load(uint3(tc, 0)).x;
		float w = SC_gaussian(d - depth, SIGMA);
		
		acc += s * w;
		wa += w;
	}
	return acc / wa;
}


#endif
