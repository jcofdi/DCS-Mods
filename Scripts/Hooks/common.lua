local net = require('net')
local InputVisualizerDialog = require('InputVisualizerDialog')
local MultiplayerSelectRoleDialog = require('MultiplayerSelectRoleDialog')
local MultiplayerSelectDynamicDialog = require('MultiplayerSelectDynamicDialog')
--local ImportantNoticeDialog = require('ImportantNoticeDialog')

function onNetMissionEnd() 
	if DCS.isServer() == true then
		net.load_next_mission() 
	end
end

function onActivatePlane(unitType)
	-- Entry point commented because its work in progress
	--InputVisualizerDialog.onActivatePlane(unitType)
	--ImportantNoticeDialog.showForUnit(unitType) --TODO CREATE MOCK FOR CHINOOK
end

function onATCTerminalAcquireChanged()
	MultiplayerSelectRoleDialog.onATCTerminalAcquireChanged()
	MultiplayerSelectDynamicDialog.onATCTerminalAcquireChanged()
end

local hooks = {}
hooks.onNetMissionEnd = onNetMissionEnd
hooks.onActivatePlane = onActivatePlane
hooks.onATCTerminalAcquireChanged = onATCTerminalAcquireChanged
DCS.setUserCallbacks(hooks)