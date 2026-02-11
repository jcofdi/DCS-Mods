--[[
['SunInfluenceValue'] = 1.0; -- day cycle influence
params quartet:
['GROUND_UNITS'] = 
			{
				0.001; -- environment temperature difference  influence(from base T=-15 degrees)
				0.40; -- base argVal
				0.55; -- alive to dead models coefficient
				0.0; -- not in use
			};
]]

FLIR =
{
	['seasons'] = 
	{
		['autumn'] = 
		{
			['SunInfluenceValue'] = 1.0;
			['GROUND_UNITS'] = 
			{
				0.001;
				0.38;
				0.55;
				0.0;
			};
		};
		['spring'] = 
		{
			['SunInfluenceValue'] = 1.0;
			['GROUND_UNITS'] = 
			{
				0.001;
				0.38;
				0.55;
				0.0;
			};
		};
		['winter'] = 
		{
			['SunInfluenceValue'] = 0.8;
			['GROUND_UNITS'] = 
			{
				0.002;
				0.19;
				0.55;
				0.0;
			};
		};
		['default'] = 
		{
			['SunInfluenceValue'] = 1.0;
			['GROUND_UNITS'] = 
			{
				0.002;
				0.38;
				0.55;
				0.0;
			};
		};
		['summer'] = 
		{
			['SunInfluenceValue'] = 1.0;
			['GROUND_UNITS'] = 
			{
				0.002;
				0.30;
				0.55;
				0.0;
			};
		};
	};
};
