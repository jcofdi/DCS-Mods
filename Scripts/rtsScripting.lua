--CAP sync

CAP_packages = 
{
	["red"] = {},
	["blue"] = {},
	last_idx = 1,
}

local CAP_packages_event_handler = {}
function CAP_packages_event_handler:onEvent(event)
	if event == nil then
		return
	end
	local who = nil
	if event.id == world.event.S_EVENT_CRASH or event.id == world.event.S_EVENT_DEAD or event.id == world.event.S_EVENT_UNIT_LOST then
		if event.initiator == nil then
			return
		end
		who = event.initiator:getName()
	elseif event.id == world.event.S_EVENT_KILL then
		if event.target == nil then
			return
		end
		who = event.target:getName()
	else
		return
	end
	
	if CAP_packages["red"][who] ~= nil then
		CAP_packages["red"][who].alive = false
	end
	if CAP_packages["blue"][who] ~= nil then
		CAP_packages["blue"][who].alive = false
	end
end
--world.addEventHandler(CAP_packages_event_handler)

function addPackage(country, ...)
	if CAP_packages[country] == nil then
		return
	end
	for i = 1, select("#", ...) do
		name = select(i, ...)
		if CAP_packages[country][name] == nil then
			CAP_packages[country][name] = 
			{ 
				CAP_package_idx = CAP_packages.last_idx,
				current_wp = 1,
				alive = true,
				priority = i
			}
		end
	end
	CAP_packages.last_idx = CAP_packages.last_idx + 1
end

function checkCAPSync(country, name)
	--trigger.action.outText("Check "..country.." "..name, 60)
	if CAP_packages[country] == nil then
		--trigger.action.outText('checkCAPSync : Bad country: '..country, 60)
		return true
	end
	
	if CAP_packages[country][name] == nil then
		--trigger.action.outText('checkCAPSync : Bad name: '..name, 60)
		return true
	end
	
	local function checkByPriority(curr, v)
		return v.alive == true and v.CAP_package_idx == curr.CAP_package_idx and curr.priority < v.priority
	end
	
	local function checkByWP(curr, v)
		--return v.current_wp - curr.current_wp < 2
		--trigger.action.outText(tostring(curr.CAP_package_idx).." curr.current_wp="..tostring(curr.current_wp).." v.current_wp="..tostring(v.current_wp), 60)
		--trigger.action.outText("(curr.current_wp + 1) % 4="..tostring((curr.current_wp + 1) % 4), 60)
		return v.current_wp ~= 3
	end
	
	local currPlane = CAP_packages[country][name]
	-- if name == 'US 4.1.2#23' then
		-- trigger.action.outText(tostring(currPlane.CAP_package_idx).." curr.current_wp="..tostring(currPlane.current_wp), 60)
		-- trigger.action.outText("(curr.current_wp + 1) % 4="..tostring((currPlane.current_wp + 1) % 4), 60)
	-- end
	for planeName, v in pairs(CAP_packages[country]) do
		if type(v) == 'table' then
			if planeName ~= name then
				if checkByPriority(currPlane, v) then
					-- if name == 'US 4.1.2#23' then
						-- trigger.action.outText(tostring(currPlane.CAP_package_idx).." v.current_wp="..tostring(v.current_wp), 60)
					-- end
					if checkByWP(currPlane, v) then
						return false
					end
				end
			end
		end
	end
	return true
end

function setFlightCurrentWP(country, name, WPidx)
	if CAP_packages[country][name] ~= nil then
		CAP_packages[country][name].current_wp = WPidx
	end
end

--SEAD attack hack if target didn't spawn yet

function forceAttackGroup(thisName, targetName)
	targetGroup = Group.getByName(targetName)
	thisGroup = Group.getByName(thisName)
	if targetGroup == nil or thisGroup == nil then
		return
	end
	
	AttackGroup = 
	{
		id = 'AttackGroup',
		params = 
		{
			groupId = targetGroup:getID()
		}
	}

	_controller = thisGroup:getController()
	_controller:pushTask(AttackGroup);
end