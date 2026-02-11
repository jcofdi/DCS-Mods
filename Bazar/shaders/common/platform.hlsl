#ifndef PLATFORM_HLSL
#define PLATFORM_HLSL

#if defined(COMPILER_ED_FXC) && defined(__spirv__)

	#define PUSH_CONSTANT_BUFFER_N(structName, varName) [[vk::push_constant]] ConstantBuffer<structName> varName;
	#define TARGET_LOCATION_INDEX(_location, _index) [[vk::location(_location), vk::index(_index)]]

	#define ED_PRINTF(...) printf(__VA_ARGS__)

#else

	#define PUSH_CONSTANT_BUFFER_N(structName, varName) cbuffer pushConst { structName varName; }; //emulation variant for FXC and SM 5.0
	#define TARGET_LOCATION_INDEX(_location, _index)

	#define ED_PRINTF

#endif

#define PUSH_CONSTANT_BUFFER(structName) PUSH_CONSTANT_BUFFER_N(structName, pushConst)

#endif // PLATFORM_HLSL