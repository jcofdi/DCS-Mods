#define complex float2
#define real x
#define imag y
#define PI 3.1415926535
#define PIx2 6.283185307179586476925286

complex c_mul(complex a, complex b)
{
    return float2(a.real * b.real - a.imag * b.imag, a.real * b.imag + a.imag * b.real);
}

void c_madsub(inout complex a, inout complex b, complex w)
{
    complex c = c_mul(b, w);
    complex t = a;
    a = t + c;
    b = t - c;
}

#if defined(COMPILER_ED_FXC)
void c_madsub(inout complex x[8], uint indexA, uint indexb, complex w)
{
    complex c = c_mul(x[indexb], w);
    complex t = x[indexA];
    x[indexA] = t + c;
    x[indexb] = t - c;
}
#endif

float select4(float4 v, int i)
{
    return (i & 2)
        ? (i & 1) ? v.w : v.z 
        : (i & 1) ? v.y : v.x;
}

complex twiddle(int index, int size, bool inverse)
{
    float angle = -PIx2 * float(index) / float(size);
    if (inverse)
        angle = -angle;
    //sincos(x, out s, out c)
    complex res;
    sincos(angle, res.y, res.x);
    return res;
    //return complex(cos(angle), sin(angle));
}

static const int c_bitrev8[8] = { 0, 4, 2, 6, 1, 5, 3, 7 };
static const int c_bitrev16[16] = { 0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15 };

groupshared complex s_TransposeBuffer8x8[4][8][9];

void transpose16x8(inout complex x[16], uint column, uint sequence, uint base)
{
    uint n;
    [unroll]
    for (n = 0; n < 8; n++)
        s_TransposeBuffer8x8[sequence][column][n] = x[base + n];
    GroupMemoryBarrierWithGroupSync();
    [unroll]
    for (n = 0; n < 8; n++)
        x[base + c_bitrev8[n]] = s_TransposeBuffer8x8[sequence][n][column];
    GroupMemoryBarrierWithGroupSync();
}

groupshared complex s_TransposeBuffer16x16[4][16][17];

void transpose16x16(inout complex x[16], uint column, uint sequence)
{
    uint n;
    [unroll]
    for (n = 0; n < 16; n++)
        s_TransposeBuffer16x16[sequence][column][n] = x[n];
    GroupMemoryBarrierWithGroupSync();
    [unroll]
    for (n = 0; n < 16; n++)
        x[c_bitrev16[n]] = s_TransposeBuffer16x16[sequence][n][column];
}

void fft8(inout complex x[8], float sign)
{
#if defined(COMPILER_ED_FXC)
	// At the moment of writing (release-1.8.2407), DXC was failing to compile:
	// c_madsub(x[...], x[...], ...)
	// with -fspv-debug=vulkan-with-source which is needed for shader debugging.
    // Error:
    // fatal error: generated SPIR-V is invalid:
    // NonSemantic.Shader.DebugInfo.100 DebugDeclare: expected operand Variable must be a result id of OpVariable or OpFunctionParameter
    c_madsub(x, 0, 1, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 2, 3, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 4, 5, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 6, 7, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 0, 2, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 4, 6, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 1, 3, complex(0.0000000, -1.0000000 * sign));
    c_madsub(x, 5, 7, complex(0.0000000, -1.0000000 * sign));
    c_madsub(x, 0, 4, complex(1.0000000, 0.0000000 * sign));
    c_madsub(x, 1, 5, complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x, 2, 6, complex(0.0000000, -1.0000000 * sign));
    c_madsub(x, 3, 7, complex(-0.70710678118f, -0.70710678118f * sign));
#else
    c_madsub(x[0], x[1], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[2], x[3], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[4], x[5], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[6], x[7], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[0], x[2], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[4], x[6], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[1], x[3], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[5], x[7], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[0], x[4], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[1], x[5], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[2], x[6], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[3], x[7], complex(-0.70710678118f, -0.70710678118f * sign));
#endif
}

void fft8(inout complex x[16], int base, float sign)
{
    c_madsub(x[base + 0], x[base + 1], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 2], x[base + 3], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 4], x[base + 5], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 6], x[base + 7], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 0], x[base + 2], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 4], x[base + 6], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 1], x[base + 3], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 5], x[base + 7], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 0], x[base + 4], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 1], x[base + 5], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 2], x[base + 6], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 3], x[base + 7], complex(-0.70710678118f, -0.70710678118f * sign));
}

void fft16(inout complex x[16], float sign)
{
    c_madsub(x[0], x[1], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[2], x[3], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[4], x[5], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[6], x[7], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[8], x[9], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[10], x[11], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[12], x[13], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[14], x[15], complex(1.0000000, 0.0000000 * sign));

    c_madsub(x[0], x[2], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[4], x[6], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[8], x[10], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[12], x[14], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[1], x[3], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[5], x[7], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[9], x[11], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[13], x[15], complex(0.0000000, -1.0000000 * sign));

    c_madsub(x[0], x[4], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[8], x[12], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[1], x[5], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[9], x[13], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[2], x[6], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[10], x[14], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[3], x[7], complex(-0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[11], x[15], complex(-0.70710678118f, -0.70710678118f * sign));

    c_madsub(x[0], x[8], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[1], x[9], complex(0.92387953251f, -0.38268343236f * sign));
    c_madsub(x[2], x[10], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[3], x[11], complex(0.38268343236f, -0.92387953251f * sign));
    c_madsub(x[4], x[12], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[5], x[13], complex(-0.38268343236f, -0.92387953251f * sign));
    c_madsub(x[6], x[14], complex(-0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[7], x[15], complex(-0.92387953251f, -0.38268343236f * sign));
}

void fft16b(inout complex x[32], int base, float sign)
{
    c_madsub(x[base + 0], x[base + 1], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 2], x[base + 3], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 4], x[base + 5], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 6], x[base + 7], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 8], x[base + 9], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 10], x[base + 11], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 12], x[base + 13], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 14], x[base + 15], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 0], x[base + 2], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 4], x[base + 6], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 8], x[base + 10], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 12], x[base + 14], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 1], x[base + 3], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 5], x[base + 7], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 9], x[base + 11], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 13], x[base + 15], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 0], x[base + 4], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 8], x[base + 12], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 1], x[base + 5], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 9], x[base + 13], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 2], x[base + 6], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 10], x[base + 14], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 3], x[base + 7], complex(-0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 11], x[base + 15], complex(-0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 0], x[base + 8], complex(1.0000000, 0.0000000 * sign));
    c_madsub(x[base + 1], x[base + 9], complex(0.92387953251f, -0.38268343236f * sign));
    c_madsub(x[base + 2], x[base + 10], complex(0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 3], x[base + 11], complex(0.38268343236f, -0.92387953251f * sign));
    c_madsub(x[base + 4], x[base + 12], complex(0.0000000, -1.0000000 * sign));
    c_madsub(x[base + 5], x[base + 13], complex(-0.38268343236f, -0.92387953251f * sign));
    c_madsub(x[base + 6], x[base + 14], complex(-0.70710678118f, -0.70710678118f * sign));
    c_madsub(x[base + 7], x[base + 15], complex(-0.92387953251f, -0.38268343236f * sign));
}

void calc_twiddles8(out complex w[8], int column, int size, bool inverse)
{
    w[0] = complex(1, 0);
    w[1] = twiddle(column, size, inverse);
    w[2] = twiddle(column * 2, size, inverse);
    w[3] = c_mul(w[2], w[1]);
    w[4] = twiddle(column * 4, size, inverse);
    w[5] = c_mul(w[4], w[1]);
    w[6] = c_mul(w[4], w[2]);
    w[7] = c_mul(w[6], w[1]);
}

void calc_twiddles16(out complex w[16], int column, int size, bool inverse)
{
    w[0] = complex(1, 0);
    for (uint n = 1; n < 16; n++)
        w[n] = twiddle(column * n, size, inverse);
}
