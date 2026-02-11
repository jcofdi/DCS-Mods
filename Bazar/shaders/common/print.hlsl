#ifndef COMMON_PRINT_HLSL
#define COMMON_PRINT_HLSL

/*
Print numbers on render target or texture.

!!!!! IMPORTANT !!!!!
1. Printed `value` must be consistent over ALL printing threads.
2. `decimals` param controls only visible number of digits after the decimal point (no rounding!)

Adapted from:
	https://www.shadertoy.com/view/4sBSWW
	https://www.shadertoy.com/view/lt3GRj

Usage notes:
	You don't have to specify `fontSize` manually unless you really need it, use functions without `fontSize` argument.
	If you really need custom `fontSize`, make sure `fontSize` is equal to `baseFontSize` with some integer multiplier.

*	printValue - uses `printPixelCoord` to precisely specify top left pixel coords of rect where value must be printed
*	printValueFromCell - uses `cellOffset` to specify column and row on screen in character positions, like in text mode
*	getFontCellPixelCoordsWithMargin - gives proper pixel coordinates with repsect to margin in character cells count
	printValue can be used in combination with getFontCellPixelCoordsWithMargin to calculate `printPixelCoord` param value
	this way printed value will be always on screen (if you specify proper margin)

All print* functions returns float value that really can be either 0.0 or 1.0.
That value represents is this pixel must be colored to represent proper character.

Example:
	finalColor.rgb = lerp(finalColor.rgb, float3(1.0, 0.0, 0.0), printValue(someValue, renderTargetUV * renderTargetSize.xy, uint2(0, 0), 1, 5));
	Blends final color with value, printed with red color (one digit for value and 5 digits after the decimal point) 

*/

// Multiples of 4x5 work best
static const uint2 baseFontSize = uint2(4, 5);
static const uint2 defaultFontSize = baseFontSize * uint2(3, 3);

float digitBin(const in int x)
{
	switch (x)
	{
	case 0: return 480599.0;
	case 1: return 139810.0;
	case 2: return 476951.0;
	case 3: return 476999.0;
	case 4: return 350020.0;
	case 5: return 464711.0;
	case 6: return 464727.0;
	case 7: return 476228.0;
	case 8: return 481111.0;
	case 9: return 481095.0;
	}
	return 0.0;
}

float printValueInternal(float value, float2 stringSpaceCoords, uint digits, uint decimals)
{
	if (stringSpaceCoords.y < 0.0 || stringSpaceCoords.y >= 1.0) 
		return 0.0;

	stringSpaceCoords.y = 0.99999 - stringSpaceCoords.y;

	float bits = 0.0;
	float digitIndex = float(digits) - floor(stringSpaceCoords.x) + 1.0;
	if (-digitIndex <= float(decimals))
	{
		float power = pow(10.0, digitIndex);
		float absValue = abs(value);
		float pivot = max(absValue, 1.5) * 10.0;
		if (pivot < power)
		{
			if (value < 0.0 && pivot >= power * 0.1)
				bits = 1792.0;
		}
		else if (digitIndex == 0.0)
		{
			if (float(decimals) > 0.0)
				bits = 2.0;
		}
		else
		{
			value = digitIndex < 0.0 ? frac(absValue) : absValue * 10.0;
			bits = digitBin(int(fmod(value / power, 10.0)));
		}
	}

	return floor(fmod(bits / pow(2.0, floor(frac(stringSpaceCoords.x) * 4.0) + floor(stringSpaceCoords.y * 5.0) * 4.0), 2.0));
}

// `cellOffset`				offset in character cells count
// `fontSize`				font size in pixels
uint2 getFontCellPixelCoords(uint2 cellOffset, uint2 fontSize)
{
	// Calculate character cell pixel offset with respect to fontSize 
	// and add little offset by two pixels (to prevent collision with screen borders)
	return fontSize.xx * uint2(1, ceil(float(fontSize.y) / float(fontSize.x))) * cellOffset + 2;
}

// `pixelCoords`			pixel coordinates of desired string top left corner ([(0, 0)..(width, height)])
// `resolution`				pixel resolution of render target (width, height)
// `margin`					margin from border in character cells count (xyzw == left, top, right, bottom)
// `cellOffset`				additional offset in character cells count
// `fontSize`				font size in pixel coordinates
uint2 getFontCellPixelCoordsWithMargin(uint2 pixelCoords, uint2 resolution, uint4 margin, uint2 cellOffset, uint2 fontSize)
{
	return getFontCellPixelCoords(cellOffset, fontSize) + clamp(pixelCoords, 
		getFontCellPixelCoords(margin.xy, fontSize), resolution.xy - getFontCellPixelCoords(margin.zw, fontSize));
}


// Main params (for all function variants):
// `value`					value you printing
// `currentPixelCoords`		thread pixel coordinates in render target
// `digits`					max possible number of digits before the decimal point
// `decimals`				visible number of digits after the decimal point

// `printPixelCoord`		pixel coordinates of desired string top left corner
float printValue(float value, uint2 currentPixelCoords, uint2 printPixelCoord, uint digits, uint decimals)
{
	float2 stringSpaceCoords = float2(currentPixelCoords - printPixelCoord) / float2(defaultFontSize);
	return printValueInternal(value, stringSpaceCoords, digits, decimals);
}

// `printPixelCoord`		pixel coordinates of desired string top left corner
// `fontSize`				font size in pixel coordinates
float printValue(float value, uint2 currentPixelCoords, uint2 printPixelCoord, uint digits, uint decimals, uint2 fontSize)
{
	float2 stringSpaceCoords = float2(currentPixelCoords - printPixelCoord) / float2(fontSize);
	return printValueInternal(value, stringSpaceCoords, digits, decimals);
}

// `cellOffset`				offset in character cells count
float printValueFromCell(float value, uint2 currentPixelCoords, uint2 cellOffset, uint digits, uint decimals)
{
	float2 stringSpaceCoords = float2(currentPixelCoords - getFontCellPixelCoords(cellOffset, defaultFontSize)) / float2(defaultFontSize);
	return printValueInternal(value, stringSpaceCoords, digits, decimals);
}

// `cellOffset`				offset in character cells count
// `fontSize`				font size in pixel coordinates
float printValueFromCell(float value, uint2 currentPixelCoords, uint2 cellOffset, uint digits, uint decimals, uint2 fontSize)
{
	float2 stringSpaceCoords = float2(currentPixelCoords - getFontCellPixelCoords(cellOffset, fontSize)) / float2(fontSize);
	return printValueInternal(value, stringSpaceCoords, digits, decimals);
}


#endif // COMMON_PRINT_HLSL