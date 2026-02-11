#include "FFTCommon.hlsl"

#define INVERSE 1
#define CHANNELS 2
#define SIZE 512

#if INVERSE 
#define TWIDDLE true
#define W -1.0f
#else
#define TWIDDLE false
#define W 1.0f
#endif

RWTexture2DArray<complex> u_FFT;

groupshared complex s_TransposeBuffer[CHANNELS][8][8][8 + 1];

[numthreads(8, 8, CHANNELS)]
void CS_FFT(uint3 threadIdx : SV_GroupThreadId, uint3 groupIdx : SV_GroupId, uniform bool HORIZONTAL)
{
    complex x[8];

    uint channel = threadIdx.z; // 0..3
    uint imageRow = groupIdx.y; // 0..height (512)
    uint n1, n2, n3;

    n2 = threadIdx.x; // 0..7 height
    n3 = threadIdx.y; // 0..7 width
	// n1 = depth
    [unroll]
    for (n1 = 0; n1 < 8; n1++)
    {
        uint n = 64 * n1 + 8 * n2 + n3;
        complex rgba;
    	if(HORIZONTAL) 
            rgba = u_FFT[uint3(n, imageRow, channel)];
        else
            rgba = u_FFT[uint3(imageRow, n, channel)];
     
        x[c_bitrev8[n1]] = rgba;
    }
    
    fft8(x, W);

    
    [unroll]
    for (n1 = 0; n1 < 8; n1++)
    {
        s_TransposeBuffer[channel][n3][n2][n1] = x[n1];
    }

    s_TransposeBuffer[0][threadIdx.y][threadIdx.x][8] = twiddle(threadIdx.x * threadIdx.y, 64, TWIDDLE);

    GroupMemoryBarrierWithGroupSync();

    n1 = threadIdx.x;
    
    [unroll]
    for (n2 = 0; n2 < 8; n2++)
    {
      complex ww = s_TransposeBuffer[0][n2][n1][8];
        x[c_bitrev8[n2]] = c_mul(s_TransposeBuffer[channel][n3][n2][n1], ww);
    }

    GroupMemoryBarrierWithGroupSync();

    fft8(x, W);

    
    [unroll]
    for (n2 = 0; n2 < 8; n2++)
    {
        s_TransposeBuffer[channel][n3][n2][n1] = x[n2];
    }

    GroupMemoryBarrierWithGroupSync();

    n2 = threadIdx.y;
    
    complex w[8];
    calc_twiddles8(w, n1 + 8 * n2, 512, TWIDDLE);

    [unroll]
    for (n3 = 0; n3 < 8; n3++)
    {
        x[c_bitrev8[n3]] = c_mul(s_TransposeBuffer[channel][n3][n2][n1], w[n3]);
    }

    fft8(x, W);


    [unroll]
    for (n3 = 0; n3 < 8; n3++) // store only the left half of the result
    {
        uint n = n1 + 8 * n2 + 64 * n3;
        
		uint3 addr;
		if (HORIZONTAL)
			addr = uint3(n, imageRow, channel);
        else
            addr = uint3(imageRow, n, channel);

#if INVERSE
        u_FFT[addr] = x[n3];// * (1.0f / SIZE);
#else
		u_FFT[addr] = x[n3] * (1.0f / SIZE);
#endif

    }

}