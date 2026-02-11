local base = _G

local require	= base.require
local print		= base.print

local MissionGenerator  = require('MissionGenerator')

function createClientAircraftDataServer(parameters)
	--print("---createClientAircraftDataServer----")
	--print("---input table:----")
	
	--base.U.traverseTable(parameters)
	
	local planeDataTbl = MissionGenerator.createClientAircraft(parameters);
	--print("---createClientAircraftDataServer----")
	--print("---out table:----")
	
	--base.U.traverseTable(planeDataTbl)

	if planeDataTbl == nil then
		--print("---out table:----", planeDataTbl)
		return nil
	end

	return planeDataTbl
end
