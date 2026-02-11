#include "flag_structs.hlsl"

[maxvertexcount(4)]
void flag_forces_gs(point VS_FLAG_FORCE_OUTPUT i[1], inout LineStream<GS_FLAG_FORCE_OUTPUT> outputStream)
{
	GS_FLAG_FORCE_OUTPUT o0, o1;

	o0.Position = i[0].Position0;
	o0.Normal = i[0].Normal;
	o0.Color = float3(1, 0, 0);

	o1.Position = i[0].Position1;
	o1.Normal = i[0].Normal;
	o1.Color = float3(0, 1, 0);

	outputStream.Append(o0);
	outputStream.Append(o1);

	outputStream.RestartStrip();
}
