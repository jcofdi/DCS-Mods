

[maxvertexcount(4)]
void GS_shaderName(point DS_OUTPUT input[1], inout TriangleStream<PS_INPUT_PARTICLE> outputStream, uniform bool bUnderWater=false)
{
	float3 POS_MSK			= input[0].pos.xyz;
	uint  VERT_ID			= asuint(input[0].pos.w) + vertexIdOffset;
	float3 PARTICLE_COLOR	= input[0].params1.rgb;
	float  nAGE				= input[0].params1.a;
	float  ANGLE			= input[0].params2.x; //id тесселированной вершины
	float  OPACITY			= input[0].params2.y;
	float  SCALE			= input[0].params2.z;
	float  OPACITY_BASE		= input[0].params2.w;
	float3 TANGENT_MSK		= input[0].params3.xyz;
	float  SPEED_STRETCH	= input[0].params3.w;

	PS_INPUT_PARTICLE o;

#ifdef DEBUG_OUTPUT
	o.debug = input[0].debug;
#endif

	o.params.w = nAGE;

#ifdef MISSILE
	o.posW.xyz = PARTICLE_COLOR;
#else
	// обесцвечиваем и делаем ярче к хвосту
	float b = min(0.9, max(PARTICLE_COLOR.r, max(PARTICLE_COLOR.g, PARTICLE_COLOR.b)) * 0.5 + 0.4);

	o.posW.xyz = lerp(b, PARTICLE_COLOR, pow(nAGE, 4));
	o.posW.xyz = lerp(PARTICLE_COLOR, o.posW.xyz, colorFadingFactor);
#endif

#ifdef LOD
	//o.posW.xyz *= 0.8;
	//OPACITY *= 0.1;
#endif
	
#if defined(PS_HALO) && !defined(DEBUG_NO_HALO)
	o.posW.w = getHaloFactor(sunDir.xyz, POS_MSK - gViewInv._41_42_43, 6);
#else
	o.posW.w = 0;
#endif

	////////////////////////////
	o.vertId = VERT_ID;
	// float4x4 mBillboard = billboard(POS_MSK, baseScale);//без поворота
	float4x4 mBillboard = billboardOverSpeed(POS_MSK, TANGENT_MSK, SCALE);//вдоль вектора скорости
	o.params2 = float4(mBillboard._21_22_23 * rcp(SCALE), OPACITY);//проекция вектора скорости на экран в МСК
	o.opacityBase = OPACITY_BASE;
#ifndef LOD
	float2x2 Mtex = rotMatrix2x2(ANGLE);
	o.params3.zw = Mtex._21_22;
#else
	float2x2 Mtex = 0;
	o.params3.zw = 0;
#endif

	float3 texOffset = TANGENT_MSK * (effectTime * 0.15);

	//[unroll] глючит как минимум на ATI Radeon 7000 Series, R9 200 Series, NVidia GTX480 и GT630
	for (int ii = 0; ii < 4; ++ii)
	{
		float4 wPos = {staticVertexData[ii].xy, 0, 1};
	#ifndef LOD
		o.params3.xy = mul(wPos.xy, Mtex) + 0.5;//крутим текстурные координаты, партикл стоит на месте
	#else
		o.params3.xy = staticVertexData[ii].zw;//ничо не крутим
	#endif
	
	#ifndef DEBUG_NO_STRETCH
		wPos.y *= SPEED_STRETCH;//растягиваем вдоль вектора скорости
	#endif

		wPos = mul(wPos, mBillboard);
		o.pos = mul(wPos, VP);

		if(bUnderWater){
			float3 v = wPos.xyz - gCameraPos;
			float dist = length(v);
			float waterDepth = max(0, dist * (1 + (gCameraAltitude - g_Level) / v.y));  // thickness of water
			o.alpha.x = calcWaterDeepFactor(waterDepth, 0)*10;
		}
		else{
			float3 v = wPos.xyz - gCameraPos;
			float dist = length(v);

			o.alpha.x = 1.0 - smoothstep(20000, 80000, dist);
		}

		o.alpha.y = staticVertexData[ii].x;
		o.params.xyz = (wPos.xyz + worldOffset)*texTile - texOffset;
		o.params.xyz = o.params.xyz*0.15;
		outputStream.Append(o);
	}
}


[maxvertexcount(4)]
void GS2_shaderName(point DS_OUTPUT input[1], inout TriangleStream<PS_INPUT_PARTICLE> outputStream)
{
	float3 POS_MSK			= input[0].pos.xyz;
	uint  VERT_ID			= asuint(input[0].pos.w) + vertexIdOffset;
	float3 PARTICLE_COLOR	= input[0].params1.rgb;
	float  nAGE				= input[0].params1.a;
	float  ANGLE			= input[0].params2.x; //id тесселированной вершины
	float  OPACITY			= input[0].params2.y;
	float  SCALE			= input[0].params2.z;
	float  OPACITY_BASE		= input[0].params2.w;
	float3 TANGENT_MSK		= input[0].params3.xyz;
	float  SPEED_STRETCH	= input[0].params3.w;
	float  AGE 				= input[0].params4.x;
	
	PS_INPUT_PARTICLE o;

#ifdef DEBUG_OUTPUT
	o.debug = input[0].debug;
#endif

	o.params.w = nAGE;
	
	//обесцвечиваем и делаем ярче к хвосту
	float b = min(0.9, max(PARTICLE_COLOR.r, max(PARTICLE_COLOR.g, PARTICLE_COLOR.b))*0.5 + 0.4);
	o.posW.xyz = PARTICLE_COLOR;
	
#ifdef LOD
	o.posW.xyz *= 0.9;
#endif
	
#if defined(PS_HALO) && !defined(DEBUG_NO_HALO)
	o.posW.w = getHaloFactor(sunDir.xyz, POS_MSK - gViewInv._41_42_43, 6);
#else
	o.posW.w = 0;
#endif
	////////////////////////////
	o.vertId = VERT_ID;
	// float4x4 mBillboard = billboard(POS_MSK, baseScale);//без поворота
	float4x4 mBillboard = billboardOverSpeed(POS_MSK, TANGENT_MSK, SCALE);//вдоль вектора скорости
	o.params2 = float4(mBillboard._21_22_23 * rcp(SCALE), OPACITY);//проекция вектора скорости на экран в МСК
	o.opacityBase = OPACITY_BASE;
#ifndef LOD
	float2x2 Mtex = rotMatrix2x2(ANGLE);
	o.params3.zw = Mtex._21_22;
#else
	float2x2 Mtex = 0;
	o.params3.zw = 0;
#endif
	o.alpha.x = 1.0;

	const float3 texOffset = TANGENT_MSK * (effectTime * 0.15) * 0.15;
	const float texTile15 = texTile * 0.15;

	//[unroll] глючит как минимум на ATI Radeon 7000 Series, R9 200 Series, NVidia GTX480 и GT630
	for (int ii = 0; ii < 4; ++ii)
	{
		float4 wPos = {staticVertexData[ii].xy, 0, 1};

		o.alpha.y = staticVertexData[ii].x;
		o.params3.xy = staticVertexData[ii].zw;

	#ifndef DEBUG_NO_STRETCH
		wPos.y *= SPEED_STRETCH;//растягиваем вдоль вектора скорости
	#endif
		
		wPos = mul(wPos, mBillboard);
		o.pos = mul(wPos, VP);
		o.params.xyz = (wPos.xyz + worldOffset) * texTile15 - texOffset;
		outputStream.Append(o);
	}
}