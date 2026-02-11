#ifndef NOISE_FRACTAL_FUNC
#define NOISE_FRACTAL_FUNC

#include "noise/noise2D.hlsl"


#define NCELLS 1000
#define CELLSIZE (1/NCELLS)


float3 tilesShader(float2 uv, float3 baseColor, float3 pointColor, float time)
{
    float scell, tcell;

    scell = floor(uv.x*NCELLS);
    tcell = floor(uv.y*NCELLS);

    float cellID = scell*(NCELLS-1) + tcell;
    cellID = cellID/(NCELLS*NCELLS);

    float t = (uv.x*NCELLS - scell - 0.5)*(uv.x*NCELLS - scell - 0.5) + (uv.y*NCELLS - tcell - 0.5)*(uv.y*NCELLS - tcell - 0.5);

    scell /= NCELLS;
    tcell /= NCELLS;

    //abs(sin(scell*2*PI))

    float timeCells = 100;

    //float t2 = floor((time+noise1D(scell+tcell+0.2492))*0.03*timeCells);

    float t2 = floor((time + noise1D(cellID*10.2474+0.2492))*0.03*timeCells);

    t2 = frac(t2/timeCells);

    float t3 = floor(time*0.2*timeCells);

    t3 = frac(t3/timeCells);


    //if ((t < 0.25) && (noise1D(scell*tcell + 0.1394 + t2) < 0.1))
    //if ((t < 0.25) && (noise1D((scell*0.9+0.1)*(0.9*tcell+0.1) + 0.1394 + t2) < 0.001))
    if ((t < 0.25) && (noise1D(cellID*24.35905 + 0.1394 + t2) < 0.0001))
        return pointColor;

    //if (abs(uv.x-0.5) > 0.48 || abs(uv.y-0.5) > 0.48)
       // return pointColor;

    return baseColor;
    
}

#endif