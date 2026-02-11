
[maxvertexcount(4*particlesCount)]
void GSname(point VS_OUTPUT input[1], inout TriangleStream<PS_INPUT> outputStream, uniform bool bigExplosion = true)
{
	float3 startPos		= input[0].pos.xyz;
	float  age			= input[0].pos.w;
	float3 speedDir		= input[0].speed.xyz;
	float  speedValue	= input[0].speed.w; //*(0.5+power*0.5)
	float  nAge			= input[0].params.x;
	float  Rand			= input[0].params.y;

	PS_INPUT o;
	
#ifdef LOD
	o.params2 = 0;
#endif

	o.sunColor = getPrecomputedSunColor(0);

	[unroll]
	for(float i=0; i<particlesCount; i+=1.0f)
	{
		float param = sqrt(i/(particlesCount-1.0f)); //1 - вершина пика

		float uniqRand = noise1D(Rand+param);
		float uniqAge = min(1, nAge*(1+0.3*step(0.5, uniqRand)));
		
		float tt = smoothstep(0.7, 0.9, 1.0 - nAge);
		tt = 0.8*tt + 0.2;
		float tparam = 4.0 - min(max(power, 3.0), 4.0);

		tt = lerp(1.0, smoothstep(0.0, 0.5, (1.0-param))*tt, tparam);

		o.params2.zw = float2(0.8*pow(nAge,0.3), (1-pow(uniqAge, 2-power/2.5f))*0.8*tt);//смешнивание текстур партиклов / прозрачность
	#ifdef LOD
		o.params2.w *= 2.5;
	#endif

		float airResistance = lerp(1.0, 1.5, tparam)*(2+0.1*(1-param));
		float3 startSpeed = speedDir * speedValue;

		float2 speedValues =  float2( length(startSpeed.xz), startSpeed.y ) * (0.8+0.2*param);
		float2 trans = calcTranslationWithAirResistance(speedValues, (0.9+0.1*power), airResistance, max(0,age));//увеличиваем коэффициент сопротивления для центральной части

		float3 offset = speedDir;

		tt = lerp(sqrt(param+0.5), (0.3+0.7*param), tparam);

		offset.xz *= trans.x*tt;

		//offset.xz *= trans.x*sqrt(param+0.5);
		offset.xz += float2(uniqRand-0.5, noise1D(Rand*param+5.3218325)-0.5) * (age*param*0.3*power);
		offset.xz += speedDir.xz * (saturate(1-offset.y/4) * nAge*(1-speedValue/speedMax)*5*(0.8+0.2*power));//сдвигаем от центра 
		tparam = lerp(sqrt(param), 1.0, tparam);
		tparam = 0.5*tparam + 0.5*param;

		tt = lerp(sqrt(param+0.5), (0.3+0.7*tparam), 4.0 - min(max(power, 3.0), 4.0));
		offset.y = max(0,trans.y)*tt;

		tparam = 4.0 - min(max(power, 0.2), 4.0);
		tparam /= 4.0;
		tparam = lerp(1.0, nAge*nAge, tparam);
		o.params2.w *= tparam;

		float scale;

		if (bigExplosion) {
			o.params2.w *= 1.0 - smoothstep(0.1, 1.0, param); 
			scale = 1.6*(1+3*pow(abs(nAge),2)) + (1-param)*4*min(age*0.5, 1.0);
		}

		else {
			o.params2.w *= 1.0 - smoothstep(0.5, 1.0, param); 
			scale = 0.6*(1+3*pow(abs(nAge),2)) + (1-param)*4*min(age*0.5, 1.0);
		}

		o.params2.w *= (1.0 - smoothstep(0.01, 1.5, nAge*2.0));
		float3 vel = noise3(float3(uniqRand + 0.1971, uniqRand + 0.38735, uniqRand + 0.5024));
		vel.y /= 5.0;
		tt = 0.0*smoothstep(0.3, 0.5, nAge);
		offset += tt*(wind+0.5*vel)*noise1(uniqRand + 0.21487)*age;

		scale *= (0.3+0.7*(4.0*step(3.9, power) + step(power, 3.9)*power/1.3));
		scale *= lerp((sqrt(1.0 - param)*0.5 + 0.5)*2.0, 1.0, 4.0 - min(max(power, 3.0), 4.0));
		
		float3 bilDir = speedDir;
		if (bigExplosion)
			bilDir = nAge*float3(0.0, 1.0, 0.0) + (1.0-nAge)*speedDir;

		float4x4 mBillboard = mul(billboardOverSpeed(startPos+offset, bilDir, scale*1.0), gViewProj);
	#ifndef LOD
		float ang = (Rand+param*3.62174)*PI2+age*0.3*(step(0.5,uniqRand)*2-1)*2;
		float _sin, _cos;
		sincos(ang, _sin, _cos);
		o.params2.xy = float2(-_sin, _cos);//поворот нормалей
	#endif

		[unroll]
		for (int i = 0; i < 4; ++i)
		{
			float4 vPos = {staticVertexData[i].xy, 0, 1};
		#ifndef LOD
			o.uv = float2( vPos.x*_cos - vPos.y*_sin, vPos.x*_sin + vPos.y*_cos ) + 0.5;
		#else
			o.uv = vPos.xy + 0.5;
		#endif

			if (bigExplosion)
				vPos.y *= (1.3+nAge*0.5);

			o.pos = mul(vPos, mBillboard);
			outputStream.Append(o);
		}
		outputStream.RestartStrip();
	}
}