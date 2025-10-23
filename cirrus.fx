#include "common/TextureSamplers.hlsl"
#include "common/States11.hlsl"
#include "common/samplers11.hlsl"
#include "common/context.hlsl"
#include "common/ambientCube.hlsl"
#include "common/haloSampling.hlsl"
#include "deferred/atmosphere.hlsl"

//------------------------------------------------------------------------------
// Texture arrays bound to t0 and t1
//------------------------------------------------------------------------------
Texture2DArray DiffTex   : register(t0);
Texture2DArray DiffTex2  : register(t1);

float4 params;
#define time    gModelTime
#define phase   params.y
#define origin  gOrigin

//-------------------------------------------------------------------------------
// Geometry & placement 
//-------------------------------------------------------------------------------
static const float cirrusAltitude     = 12000.0;
static const float quadSize           = 550000.0;
static const float fadeInv            = 1.0 / 1000.0;
static const float earthRadiusBottom    = gEarthRadius * 0.25;
static const float earthRadiusTop       = gEarthRadius;
static const float rangeInv             = 2.0 / quadSize;
static const float rangeTopInv          = 2.0 / 450000.0;
static const float tile                 = 8.0;
static const float windSpeed            = 150.0;

//-------------------------------------------------------------------------------
// Scattering & cloud appearance
//-------------------------------------------------------------------------------
static const float cirrusThickness      = 1.0;
static const float cirrusThicknessMax   = 60.0;
static const float extinction           = 0.35 * 0.8;
static const float albedo               = 0.6;
static const float shadowExtinctionMult = 8.0;
static const float shadowRadius         = 300000.0;
static const float multipleScatCoef     = 0.6;
static const float opacityClamp         = 0.001;
static const float altitudeBlurIntensity = 0.0;


//------------------------------------------------------------------------------
// Texture array and slice timing
//------------------------------------------------------------------------------
static const int LAYERS_PER_ARRAY = 5;
static const int NUM_CLOUD_TEX    = 10;
static const float SLICE_HOLD_TIME    = 600.0;
static const float SLICE_FADE_TIME    = 120.0;
static const float SLICE_PERIOD       = SLICE_HOLD_TIME + 4.0 * SLICE_FADE_TIME;
static const float SLICE_CYCLE_TIME   = SLICE_PERIOD * NUM_CLOUD_TEX;

//-------------------------------------------------------------------------------
// ==== Per-mission shuffled slice order =======================
//-------------------------------------------------------------------------------
uint SliceOrderSeed()
{
    uint u = (uint)abs(phase * 131.0 + 0.5);
    u ^= u >> 16; u *= 0x7feb352du;
    u ^= u >> 15; u *= 0x846ca68bu;
    u ^= u >> 16;
    if (u == 0u) u = 0x85ebca6bu;

#ifdef SLICE_RANDOM_SEED_OVERRIDE
    u ^= (uint)(SLICE_RANDOM_SEED_OVERRIDE) * 0x27d4eb2du;
    if (u == 0u) u = 0x9e3779b9u;
#endif
    return u;
}

uint PickA(uint s) {
    const uint table[4] = {1u, 3u, 7u, 9u};
    uint idx = (s ^ (s >> 7) ^ (s >> 13)) & 3u;
    return table[idx];
}
uint PickB(uint s) {
    uint x = s * 1103515245u + 12345u;
    return ((x >> 27) % 10u);
}

int PermuteSlice(int k)
{
    uint seed = SliceOrderSeed();
    uint a = PickA(seed);
    uint b = PickB(seed);
    if ((a % 10u) == 1u && (b % 10u) == 0u) { b = 5u; }
    return int((a * uint(k) + b) % 10u);
}


//------------------------------------------------------------------------------
// Input/Output structs
//------------------------------------------------------------------------------
struct VS_INPUT
{
    float2 vPos : POSITION0;
    float2 vTex : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 oPos         : SV_POSITION;
    float3 oT0          : TEXCOORD0;
    float4 params       : TEXCOORD1;
    float3 inscatter    : TEXCOORD2;
    float3 sunColor     : TEXCOORD3;
    float3 transmittance : TEXCOORD4;
    float3 posWS        : POSITION1;
    float3 normal       : TEXCOORD5;
};

#define mieG 0.7
#define M_PI 3.14159265

//------------------------------------------------------------------------------
// Phase functions
//------------------------------------------------------------------------------
float cosine01(float t) { return 0.5 - 0.5 * cos(saturate(t) * M_PI); }

float numericalMieFit(float costh)
{
    float bestParams[10];
    bestParams[0]=9.805233e-06;
    bestParams[1]=-6.500000e+01;
    bestParams[2]=-5.500000e+01;
    bestParams[3]=8.194068e-01;
    bestParams[4]=1.388198e-01;
    bestParams[5]=-8.370334e+01;
    bestParams[6]=7.810083e+00;
    bestParams[7]=2.054747e-03;
    bestParams[8]=2.600563e-02;
    bestParams[9]=-4.552125e-12;

    float p1 = costh + bestParams[3];
    float4 expValues = exp(float4(bestParams[1] *costh+bestParams[2], bestParams[5] *p1*p1, bestParams[6] *costh, bestParams[9] *costh));
    float4 expValWeight= float4(bestParams[0], bestParams[4], bestParams[7], bestParams[8]);
    float x = 1.0 - saturate((1.0 - costh) / 0.04);
    return dot(expValues, expValWeight) * 0.25 + 2.7 * ((x*x)*(x*x));
}

//------------------------------------------------------------------------------
// Geometric & atmosphere helpers
//------------------------------------------------------------------------------
float distanceToCirrus(float r, float mu)
{
    const float rg = gEarthRadius;
    float rc = cirrusAltitude*0.001 + rg;
    Area discriminant = r * r * (mu * mu - 1.0) + rc * rc;
    float dist;
    if(rc>r)
        dist = ClampDistance(-r * mu + SafeSqrt(discriminant));
    else
        dist = ClampDistance(-r * mu - SafeSqrt(discriminant));
    return max(dist, 0.001);
}

float3 getRealCirrusPos(float3 camera, float3 pos)
{
    float3 cpos = (pos - camera) * 0.001;
    float d = length(cpos);
    float3 view = cpos / d;
    float mu = view.y;
    float r = length(camera);
    return camera + view * distanceToCirrus(r, view.y);
}

float3 calculateAtmosphereForCirrus(float3 cameraPos, float3 pos, out float3 transmittance)
{
    return GetSkyRadianceToPoint(cameraPos, pos, 0.0, gSunDir, transmittance) * gAtmIntensity;
}

//------------------------------------------------------------------------------
// Vertex Shader 
//------------------------------------------------------------------------------
VS_OUTPUT VertOut(VS_INPUT i)
{
    i.vPos.xy *= quadSize;
    float ex = i.vPos.x*0.001;
    float ez = i.vPos.y*0.001;

    float cameraAltitude = gCameraAltitude;
    float cameraAboveCirrus = step(cirrusAltitude, cameraAltitude);

    float r0 = earthRadiusBottom + cirrusAltitude*0.001;
    float r1 = earthRadiusTop + cirrusAltitude*0.001;
    float ey0 = sqrt(r0*r0 - ex*ex - ez*ez) - earthRadiusBottom;
    float ey1 = sqrt(r1*r1 - ex*ex - ez*ez) - earthRadiusTop;

    float3 tw;
    tw.xz = i.vPos.xy;
    tw.y = lerp(ey0, ey1, cameraAboveCirrus)*1000.0 - origin.y;

    VS_OUTPUT o;
    o.posWS = tw + float3(gCameraPos.x, 0, gCameraPos.z);
    o.oPos  = mul(float4(o.posWS,1), gViewProj);

    float windOffset = time * windSpeed;
    o.oT0.xy = (i.vTex + (origin.xz/quadSize) + (gCameraPos.xz+windOffset)/quadSize) * tile;
    float nDist = length(tw.xz)*lerp(rangeInv, rangeTopInv, cameraAboveCirrus);
    o.oT0.z = nDist;

    float fadeFactor = min(abs(cirrusAltitude - cameraAltitude)*fadeInv, 1);
    
    o.params.xy = float2(1.0, 1.0);

    float tVS = fmod(time, SLICE_CYCLE_TIME);
    o.params.z = saturate(min(tVS / SLICE_FADE_TIME, 1.0));
    o.params.w = fadeFactor * fadeFactor;

    float3 posAS = OriginSpaceToAtmosphereSpace(o.posWS);
    float3 camAS = float3(gEarthCenter.x,
                                max(0.0, gEarthCenter.y-gEarthRadius) + gEarthRadius,
                                gEarthCenter.z);
    float3 realPos = getRealCirrusPos(camAS, posAS);
    o.inscatter      = calculateAtmosphereForCirrus(camAS, realPos, o.transmittance);
    o.normal         = normalize(realPos);
    float NoL        = dot(gSunDir, o.normal);
    NoL              = smoothstep(-0.123, 0.0213, NoL);
    o.sunColor       = GetSunRadiance(realPos, gSunDir) * gSunIntensity;
    o.sunColor      *= 0.6 + 0.4*NoL*NoL;

    return o;
}

//------------------------------------------------------------------------------
// SampleCirrus: hold, fade-out current, fade-in next using a shuffled order
//------------------------------------------------------------------------------
float4 SampleCirrus(float2 uv, float2 opacity, float ratio, float bias)
{
    float tM     = fmod(time, SLICE_CYCLE_TIME);
    int   baseI  = (int)(tM / SLICE_PERIOD);
    float sliceT = tM - baseI * SLICE_PERIOD;
    int slice0 = PermuteSlice(baseI);
    int nextI  = PermuteSlice((baseI + 1) % NUM_CLOUD_TEX);
    float4 texCurr = (slice0 < LAYERS_PER_ARRAY)
        ? DiffTex .SampleBias(WrapLinearSampler, float3(uv, slice0), bias)
        : DiffTex2.SampleBias(WrapLinearSampler, float3(uv, slice0 - LAYERS_PER_ARRAY), bias);
    float4 texNext = (nextI < LAYERS_PER_ARRAY)
        ? DiffTex .SampleBias(WrapLinearSampler, float3(uv, nextI), bias)
        : DiffTex2.SampleBias(WrapLinearSampler, float3(uv, nextI - LAYERS_PER_ARRAY), bias);
    float opCurr = (slice0 < LAYERS_PER_ARRAY) ? opacity.x : opacity.y;
    float opNext = (nextI  < LAYERS_PER_ARRAY) ? opacity.x : opacity.y;

    if (sliceT < SLICE_HOLD_TIME)
    {
        return texCurr * opCurr;
    }

    if (sliceT < SLICE_HOLD_TIME + SLICE_FADE_TIME)
    {
        float t = (sliceT - SLICE_HOLD_TIME) / SLICE_FADE_TIME;
        float fade = cosine01(t);
        float w0 = 1.0 - fade;
        float w1 = fade;
        return texCurr * (w0 * opCurr) + texNext * (w1 * opNext);
    }

    return texNext * opNext;
}



//------------------------------------------------------------------------------
// Shadows
//------------------------------------------------------------------------------
float GetShadowTransmittance(float extinction, float2 uv, float2 lightDir, float2 opacity, float ratio, float bias, float distToEye)
{
    if(distToEye < shadowRadius)
    {
        float distNorm = distToEye / shadowRadius;
        float localShadowPower = saturate(1 - distNorm*distNorm*distNorm);

        const float step0 = 0.02;
        const uint count = 1;
        const float stepFactor = 2;

        float d = 0.0;
        for (uint i = 0; i < count; ++i)
        {
            float stepMultiplier = pow(1.8, i); // Steps get exponentially larger
			float s = step0 * stepMultiplier;
			uv += lightDir * s;
            float density = SampleCirrus(uv, opacity, ratio, bias + i).a;
            density = max(0, density - i*0.01);
            d += density * s;
        }

        return 1 - localShadowPower + localShadowPower * exp( -extinction * max(0, d));
    }
    return 1;
}

//------------------------------------------------------------------------------
// -------- PatchMask noise helpers (FBM blobs) --------
//------------------------------------------------------------------------------
float hash11(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    float2 u = f*f*f*(f*(f*6.0 - 15.0) + 10.0);
    float a = hash11(i);
    float b = hash11(i + float2(1, 0));
    float c = hash11(i + float2(0, 1));
    float d = hash11(i + float2(1, 1));
    return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
}

float fbm3(float2 p) {
    float a = 0.0;
    float amp = 0.5;
    float2 pp = p;
    [unroll] for (int k=0; k<3; ++k) {
        a += amp * noise2D(pp);
        pp = pp * 2.03 + 11.7;
        amp *= 0.5;
    }
    return a;
}

//------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------
float4 psCirrus(VS_OUTPUT i, uniform bool FLIR_mode, uniform bool HALO_mode): SV_TARGET0
{
    float psDist = i.oT0.z*i.oT0.z;
    float psDistSq = i.oT0.z*i.oT0.z;
    float2 psVis = i.params.xy;
    float psLerpFactor = i.params.z;
    float psFadeFactor = i.params.w;

    if (!FLIR_mode)
        clip(0.99 - psDistSq);

    float distToEye = length(i.posWS.xyz - gCameraPos.xyz);
    float3 viewDir = normalize(i.posWS.xyz - gCameraPos.xyz);

    const float maxBlurAltitude = 30000.0;
    const float maxAltitudeBlur = 8.0 * altitudeBlurIntensity;
    float altitudeBlurFactor = saturate(i.params.w / maxBlurAltitude);
    float lodBias = psDistSq * 10.0 + (altitudeBlurFactor * maxAltitudeBlur);

    float density = SampleCirrus(i.oT0.xy, psVis, psLerpFactor, lodBias).a;
    density = max(0, density);

    float cosVN = abs(dot(viewDir, normalize(i.normal)));
    float thicknessScale = 1.0 / max(0.20, cosVN);
    float cirrusSlopeThickness = min(cirrusThickness * thicknessScale, cirrusThicknessMax);
    float shadowLength = min(cirrusThickness / abs(dot(gSunDir, normalize(i.normal))), cirrusThicknessMax);

    float opacity = 1 - exp(-extinction * density * cirrusSlopeThickness);
    float opacityHack = psFadeFactor * max(0, 1 - 2*psDistSq*(1-saturate(gSurfaceNdotL*8))); 
	
    if (!FLIR_mode)
        clip(opacity - opacityClamp);

    float edgesDecay = smoothstep(opacityClamp, opacityClamp*2, opacity);

    float miePhase = numericalMieFit(dot(gSunDir, viewDir));
    float posToLightTransmittance =
        GetShadowTransmittance(extinction * shadowExtinctionMult * shadowLength,
                               i.oT0.xy, gSunDir.xz, psVis, psLerpFactor, lodBias, distToEye);
    float3 ambientLight = GetSkyIrradiance(OriginSpaceToAtmosphereSpace(i.posWS), gSunDir)
                          * (gSunIntensity * gIBLIntensity);
    float4 color;
    color.rgb = i.sunColor * ((albedo/3.1415) * (multipleScatCoef + miePhase) * posToLightTransmittance) + (albedo/3.1415) * ambientLight;
    //color.a = opacity * opacityHack * edgesDecay * patchMask;
	color.a = opacity * opacityHack * edgesDecay;
	
			  
    if ((HALO_mode && !FLIR_mode) && gIceHaloParams.cirrusCloudsFactor > 0)
    {
        float3 iceHalo = sampleHalo(gBilinearClampSampler, viewDir, gSunDir);
        color.rgb += i.sunColor * iceHalo * (posToLightTransmittance * gIceHaloParams.cirrusCloudsFactor);
    }

    color.rgb *= i.transmittance;
    color.rgb += i.inscatter;

    // --- PatchMask ---
    static const float UV_PER_METER = tile / quadSize;
    const float BLOB_SIZE_KM   = 60.0;
    const float BLOB_FILL      = 0.25;
    const float BLOB_SOFTNESS  = 0.15;
    const float BLOB_JITTER    = 0.75;
    #define  BLOB_FIELDS        3

    float blobPeriodUV = BLOB_SIZE_KM * 1000.0 * UV_PER_METER;
    float2 patchUV     = i.oT0.xy / max(blobPeriodUV, 1e-5);

    float baseN   = fbm3(patchUV);
    float detailN = fbm3(patchUV * 2.3 + 17.0);
    float n0      = lerp(baseN, baseN * 0.6 + 0.4 * detailN, BLOB_JITTER);
    float n = n0;
	
	#if BLOB_FIELDS > 1
		float n1 = fbm3(patchUV + 37.21);
		n = min(n, n1);
	#endif

	#if BLOB_FIELDS > 2
		float n2 = fbm3(patchUV * float2(1.03, 0.97) + 11.7);
		n = min(n, n2);
	#endif

    float mask = smoothstep(BLOB_FILL, BLOB_FILL + BLOB_SOFTNESS, n);
    color.a *= mask;
    if (FLIR_mode)
    {
        color.rgb = lerp(0, color.rgb, gFLIR_CloudsIntesity);
        color = lerp(color, 1, gFLIR_SkyIntesity);
    }

    return color;
}


RasterizerState cirrusRS
{
    CullMode = None;
    FillMode = Solid;
    MultisampleEnable = false;
    DepthClipEnable = false;
};

VertexShader vsComp = CompileShader(vs_4_0, VertOut());

technique10 T0
{
    pass MAIN
    {
        SetVertexShader(vsComp);
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, psCirrus(false, false)));
        SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetDepthStencilState(enableDepthBufferNoWrite, 0);
        SetRasterizerState(cirrusRS);
    }
    pass FLIR
    {
        SetVertexShader(vsComp);
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, psCirrus(true, false)));
        SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetDepthStencilState(enableDepthBufferNoWrite, 0);
        SetRasterizerState(cirrusRS);
    }
    pass MAIN_wHalo
    {
        SetVertexShader(vsComp);
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, psCirrus(false, true)));
        SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetDepthStencilState(enableDepthBufferNoWrite, 0);
        SetRasterizerState(cirrusRS);
    }
    pass FLIR_wHalo
    {
        SetVertexShader(vsComp);
        SetGeometryShader(NULL);
        SetPixelShader(CompileShader(ps_5_0, psCirrus(true, true)));
        SetBlendState(enableAlphaBlend, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xFFFFFFFF);
        SetDepthStencilState(enableDepthBufferNoWrite, 0);
        SetRasterizerState(cirrusRS);
    }
}