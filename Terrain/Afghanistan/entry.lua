if not USE_TERRAIN4 then
	return
end

theatre =
{
	['developerName'] = "Eagle Dynamics";
	['state'] = "installed";
	['type'] = "terrain";
	['version'] = "";
	['update_id'] = "AFGHANISTAN_terrain";

	['Skins'] = 
	{
		{
			name = _("Afghanistan"),
			dir  = "Theme",
		};
	};

	['image'] = 'map.png';
	['description'] = _("Afghanistan has been one of the most important combat theaters of the past half century and the location of the War on Terror and the Soviet operations of the 1980s. Few war zones have ever seen more A-10C, AH-64D, F-16C, F/A-18C, CH-47F, Mi-24P, Mi-8MTV2, and Su-25 sorties than here. Afghanistan offers a varied landscape consisting of vast deserts, towering mountains, and lush river valleys.");
	['id'] = "Afghanistan";

	['localizedName'] = "Afghanistan";
	['creditsFile'] = "credits.txt";
	['nodesMapFile'] = "MissionGenerator/nodesMap.png";
	['nodesFile'] = "MissionGenerator/nodes.lua";
} -- end of theatre

dofile(current_mod_path .. '/' .. 'MissionGenerator/nodesMap.lua')

local self_ID = "Afghanistan";
declare_plugin(self_ID, theatre);
plugin_done()
