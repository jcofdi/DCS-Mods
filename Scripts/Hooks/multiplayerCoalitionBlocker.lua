local net = require('net')
local lfs = require('lfs')
local U = require('me_utilities')
local Tools = require('tools')

local filePath = lfs.writedir() .. 'Config/multiplayerCoalitionBlockerUsersList.lua'

local params = {}
local usersTable = {}

local function deleteExpired()
    local currentTime = os.time()

    for ucid, data in pairs(usersTable) do
        if (data.joinTime + params.delayTime) < currentTime then
            usersTable[ucid] = nil
        end
    end
end

local function saveUsersTable()
    deleteExpired()
    U.saveInFile(usersTable, 'usersTable', filePath)
end

local function loadUsersTable()
    local result = Tools.safeDoFile(filePath, false) or {}
	usersTable = result.usersTable or {}

    deleteExpired()
end

function onInitCoalitionBlockerParams(activeFlag, delay, saveBetweenSessionsFlag)
    params.isActive = activeFlag
    params.delayTime = delay
    params.saveBetweenSessions = saveBetweenSessionsFlag

    if params.saveBetweenSessions == true then
        loadUsersTable()
    end
end

function onPlayerTryChangeCoalition(player_id, side)
    if DCS.isServer() == false then
        return false
    end
    if params.isActive == false or side == 0 then
        return true
    end

    local ucid = net.get_player_info(player_id, "ucid")
    if ucid == nil then
        return false
    end

    if usersTable[ucid] == nil then
        return true
    end

    local currentTime = os.time()
    if (usersTable[ucid].joinTime + params.delayTime) < currentTime then
        return true
    else
        if usersTable[ucid].side == side then
            return true
        else
            return false, "changeCoalitionCooldown", usersTable[ucid].joinTime + params.delayTime - currentTime
        end
    end
end

function onPlayerChangeCoalition(player_id, side)
    if params.isActive == false or side == 0 or DCS.isServer() == false then
        return
    end
    
    local ucid = net.get_player_info(player_id, "ucid")
    if ucid == nil then
        return
    end

    local currentTime = os.time()
    
    if usersTable[ucid] == nil or (((usersTable[ucid].joinTime + params.delayTime) < currentTime) and side ~= usersTable[ucid].side) then
        usersTable[ucid] = { joinTime = currentTime, side = side }
    end
end

function onSimulationStart()
    
end

function onSimulationStop()
    onMissionLoadEnd()
end

function onMissionLoadEnd()
    if params.isActive == false or DCS.isServer() == false then
        return
    end

    if params.saveBetweenSessions == true then
        saveUsersTable()
    else
        resetJoinCooldownEndForAll()
    end
end

--functions for server web gui and server-client gui buttons
function resetJoinCooldownEndForAll()
    if params.isActive == false or DCS.isServer() == false then
        return
    end

    usersTable = {}
    os.remove(filePath)
end

function resetJoinCooldownEndForPlayer(player_id)
    if params.isActive == false or DCS.isServer() == false then
        return
    end

    local ucid = net.get_player_info(player_id, "ucid")
    if ucid == nil then
        return
    end

    usersTable[ucid] = nil
end

local hooks = {}
hooks.onInitCoalitionBlockerParams = onInitCoalitionBlockerParams
hooks.onPlayerTryChangeCoalition = onPlayerTryChangeCoalition
hooks.onPlayerChangeCoalition = onPlayerChangeCoalition
hooks.onSimulationStart = onSimulationStart
hooks.onSimulationStop = onSimulationStop
hooks.onMissionLoadEnd = onMissionLoadEnd
hooks.resetJoinCooldownEndForAll = resetJoinCooldownEndForAll
hooks.resetJoinCooldownEndForPlayer = resetJoinCooldownEndForPlayer
DCS.setUserCallbacks(hooks)