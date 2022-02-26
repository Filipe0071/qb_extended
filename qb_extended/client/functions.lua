QBEXT = {}

QBEXT.CurrentRequestId = 0
QBEXT.ServerCallbacks = {}
QBEXT.TimeoutCallbacks = {}

QBEXT.UI = {}
QBEXT.UI.Menu = {}
QBEXT.UI.Menu.RegisteredTypes = {}
QBEXT.UI.Menu.Opened = {}

QBEXT.Game = {}
QBEXT.Game.Utils = {}

QBEXT.Scaleform = {}
QBEXT.Scaleform.Utils = {}

QBEXT.Streaming = {}

QBEXT.SetTimeout = function(msec, cb)
	table.insert(QBEXT.TimeoutCallbacks, {time = GetGameTimer() + msec, cb = cb})
	return #QBEXT.TimeoutCallbacks
end

QBEXT.ClearTimeout = function(i)
	QBEXT.TimeoutCallbacks[i] = nil
end

QBEXT.TriggerServerCallback = function(name, cb, ...)
	QBEXT.ServerCallbacks[QBEXT.CurrentRequestId] = cb
	TriggerServerEvent("qbext:triggerServerCallback", name, QBEXT.CurrentRequestId, ...)
	if QBEXT.CurrentRequestId < 65535 then
		QBEXT.CurrentRequestId = QBEXT.CurrentRequestId + 1
	else
		QBEXT.CurrentRequestId = 0
	end
end

QBEXT.UI.Menu.RegisterType = function(type, open, close)
	QBEXT.UI.Menu.RegisteredTypes[type] = {open = open, close = close}
end

QBEXT.UI.Menu.Open = function(type, namespace, name, data, submit, cancel, change, close)
	local menu = {}
	menu.type = type
	menu.namespace = namespace
	menu.name = name
	menu.data = data
	menu.submit = submit
	menu.cancel = cancel
	menu.change = change
	menu.close = function()
		QBEXT.UI.Menu.RegisteredTypes[type].close(namespace, name)
		for i = 1, #QBEXT.UI.Menu.Opened, 1 do
			if QBEXT.UI.Menu.Opened[i] then
				if QBEXT.UI.Menu.Opened[i].type == type and QBEXT.UI.Menu.Opened[i].namespace == namespace and QBEXT.UI.Menu.Opened[i].name == name then
					QBEXT.UI.Menu.Opened[i] = nil
				end
			end
		end
		if close then
			close()
		end
	end
	menu.update = function(query, newData)
		for i = 1, #menu.data.elements, 1 do
			local match = true
			for k, v in pairs(query) do
				if menu.data.elements[i][k] ~= v then
					match = false
				end
			end
			if match then
				for k, v in pairs(newData) do
					menu.data.elements[i][k] = v
				end
			end
		end
	end
	menu.refresh = function()
		QBEXT.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data)
	end
	menu.setElement = function(i, key, val)
		menu.data.elements[i][key] = val
	end
	menu.setElements = function(newElements)
		menu.data.elements = newElements
	end
	menu.setTitle = function(val)
		menu.data.title = val
	end
	menu.removeElement = function(query)
		for i = 1, #menu.data.elements, 1 do
			for k, v in pairs(query) do
				if menu.data.elements[i] then
					if menu.data.elements[i][k] == v then
						table.remove(menu.data.elements, i)
						break
					end
				end
			end
		end
	end
	table.insert(QBEXT.UI.Menu.Opened, menu)
	QBEXT.UI.Menu.RegisteredTypes[type].open(namespace, name, data)
	return menu
end

QBEXT.UI.Menu.Close = function(type, namespace, name)
	for i = 1, #QBEXT.UI.Menu.Opened, 1 do
		if QBEXT.UI.Menu.Opened[i] then
			if QBEXT.UI.Menu.Opened[i].type == type and QBEXT.UI.Menu.Opened[i].namespace == namespace and QBEXT.UI.Menu.Opened[i].name == name then
				QBEXT.UI.Menu.Opened[i].close()
				QBEXT.UI.Menu.Opened[i] = nil
			end
		end
	end
end

QBEXT.UI.Menu.CloseAll = function()
	for i = 1, #QBEXT.UI.Menu.Opened, 1 do
		if QBEXT.UI.Menu.Opened[i] then
			QBEXT.UI.Menu.Opened[i].close()
			QBEXT.UI.Menu.Opened[i] = nil
		end
	end
end

QBEXT.UI.Menu.GetOpened = function(type, namespace, name)
	for i = 1, #QBEXT.UI.Menu.Opened, 1 do
		if QBEXT.UI.Menu.Opened[i] then
			if QBEXT.UI.Menu.Opened[i].type == type and QBEXT.UI.Menu.Opened[i].namespace == namespace and QBEXT.UI.Menu.Opened[i].name == name then
				return QBEXT.UI.Menu.Opened[i]
			end
		end
	end
end

QBEXT.UI.Menu.GetOpenedMenus = function()
	return QBEXT.UI.Menu.Opened
end

QBEXT.UI.Menu.IsOpen = function(type, namespace, name)
	return QBEXT.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

QBEXT.Game.GetPedMugshot = function(ped, transparent)
	if DoesEntityExist(ped) then
		local mugshot
		if transparent then
			mugshot = RegisterPedheadshotTransparent(ped)
		else
			mugshot = RegisterPedheadshot(ped)
		end
		while not IsPedheadshotReady(mugshot) do
			Citizen.Wait(0)
		end
		return mugshot, GetPedheadshotTxdString(mugshot)
	else
		return
	end
end

QBEXT.Game.Teleport = function(entity, coords, cb)
	local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or vec(coords.x, coords.y, coords.z, coords.heading or 0.0)
	if DoesEntityExist(entity) then
		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(entity) do
			Citizen.Wait(0)
		end
		SetEntityCoords(entity, vector.xyz, false, false, false, false)
		SetEntityHeading(entity, vector.w)
	end
	if cb then
		cb()
	end
end

QBEXT.Game.SpawnObject = function(object, coords, cb, networked)
	local model = type(object) == "number" and object or GetHashKey(object)
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
	networked = networked == nil and true or networked
	Citizen.CreateThread(function()
		QBEXT.Streaming.RequestModel(model)
		local obj = CreateObject(model, vector.xyz, networked, false, true)
		if cb then
			cb(obj)
		end
	end)
end

QBEXT.Game.SpawnLocalObject = function(object, coords, cb)
	QBEXT.Game.SpawnObject(object, coords, cb, false)
end

QBEXT.Game.DeleteVehicle = function(vehicle)
	SetEntityAsMissionEntity(vehicle, false, true)
	DeleteVehicle(vehicle)
end

QBEXT.Game.DeleteObject = function(object)
	SetEntityAsMissionEntity(object, false, true)
	DeleteObject(object)
end

QBEXT.Game.SpawnVehicle = function(vehicle, coords, heading, cb, networked)
	local model = (type(vehicle) == "number" and vehicle or GetHashKey(vehicle))
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
	networked = networked == nil and true or networked
	Citizen.CreateThread(function()
		QBEXT.Streaming.RequestModel(model)
		local vehicle = CreateVehicle(model, vector.xyz, heading, networked, false)
		if networked then
			local id = NetworkGetNetworkIdFromEntity(vehicle)
			SetNetworkIdCanMigrate(id, true)
			SetEntityAsMissionEntity(vehicle, true, false)
		end
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetModelAsNoLongerNeeded(model)
		SetVehRadioStation(vehicle, "OFF")
		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(vehicle) do
			Citizen.Wait(0)
		end
		if cb then
			cb(vehicle)
		end
	end)
end

QBEXT.Game.SpawnLocalVehicle = function(vehicle, coords, heading, cb)
	QBEXT.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

QBEXT.Game.IsVehicleEmpty = function(vehicle)
	local passengers = GetVehicleNumberOfPassengers(vehicle)
	local driverSeatFree = IsVehicleSeatFree(vehicle, -1)
	return passengers == 0 and driverSeatFree
end

QBEXT.Game.GetObjects = function()
	return GetGamePool("CObject")
end

QBEXT.Game.GetPeds = function(onlyOtherPeds)
	local peds, myPed, pool = {}, PlayerPedId(), GetGamePool("CPed")
	for i = 1, #pool do
        if ((onlyOtherPeds and pool[i] ~= myPed) or not onlyOtherPeds) then
            table.insert(peds, pool[i])
        end
    end
	return peds
end

QBEXT.Game.GetVehicles = function()
	return GetGamePool("CVehicle")
end

QBEXT.Game.GetPlayers = function(onlyOtherPlayers, returnKeyValue, returnPeds)
	local players, myPlayer = {}, PlayerId()
	for k, player in ipairs(GetActivePlayers()) do
		local ped = GetPlayerPed(player)
		if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
			if returnKeyValue then
				players[player] = ped
			else
				table.insert(players, returnPeds and ped or player)
			end
		end
	end
	return players
end

QBEXT.Game.GetClosestObject = function(coords, modelFilter)
	return QBEXT.Game.GetClosestEntity(QBEXT.Game.GetObjects(), false, coords, modelFilter)
end

QBEXT.Game.GetClosestPed = function(coords, modelFilter)
	return QBEXT.Game.GetClosestEntity(QBEXT.Game.GetPeds(true), false, coords, modelFilter)
end

QBEXT.Game.GetClosestPlayer = function(coords)
	return QBEXT.Game.GetClosestEntity(QBEXT.Game.GetPlayers(true, true), true, coords, nil)
end

QBEXT.Game.GetClosestVehicle = function(coords, modelFilter)
	return QBEXT.Game.GetClosestEntity(QBEXT.Game.GetVehicles(), false, coords, modelFilter)
end

QBEXT.Game.GetPlayersInArea = function(coords, maxDistance)
	return EnumerateEntitiesWithinDistance(QBEXT.Game.GetPlayers(true, true), true, coords, maxDistance)
end

QBEXT.Game.GetVehiclesInArea = function(coords, maxDistance)
	return EnumerateEntitiesWithinDistance(QBEXT.Game.GetVehicles(), false, coords, maxDistance)
end

QBEXT.Game.IsSpawnPointClear = function(coords, maxDistance)
	return #QBEXT.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

QBEXT.Game.GetClosestEntity = function(entities, isPlayerEntities, coords, modelFilter)
	local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil
	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end
	if modelFilter then
		filteredEntities = {}
		for k, entity in pairs(entities) do
			if modelFilter[GetEntityModel(entity)] then
				table.insert(filteredEntities, entity)
			end
		end
	end
	for k, entity in pairs(filteredEntities or entities) do
		local distance = #(coords - GetEntityCoords(entity))
		if closestEntityDistance == -1 or distance < closestEntityDistance then
			closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
		end
	end
	return closestEntity, closestEntityDistance
end

QBEXT.Game.GetVehicleInDirection = function()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
	if hit == 1 and GetEntityType(entityHit) == 2 then
		local entityCoords = GetEntityCoords(entityHit)
		return entityHit, entityCoords
	end
	return nil
end

QBEXT.Game.GetVehicleProperties = function(vehicle)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		local extras = {}
		for extraId = 0, 12 do
			if DoesExtraExist(vehicle, extraId) then
				local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
				extras[tostring(extraId)] = state
			end
		end
		return {model = GetEntityModel(vehicle), plate = QBEXT.Math.Trim(GetVehicleNumberPlateText(vehicle)), plateIndex = GetVehicleNumberPlateTextIndex(vehicle), bodyHealth = QBEXT.Math.Round(GetVehicleBodyHealth(vehicle), 1), engineHealth = QBEXT.Math.Round(GetVehicleEngineHealth(vehicle), 1), tankHealth = QBEXT.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1), fuelLevel = QBEXT.Math.Round(GetVehicleFuelLevel(vehicle), 1), dirtLevel = QBEXT.Math.Round(GetVehicleDirtLevel(vehicle), 1), color1 = colorPrimary, color2 = colorSecondary, pearlescentColor = pearlescentColor, wheelColor = wheelColor, wheels = GetVehicleWheelType(vehicle), windowTint = GetVehicleWindowTint(vehicle), xenonColor = GetVehicleXenonLightsColour(vehicle), neonEnabled = {IsVehicleNeonLightEnabled(vehicle, 0), IsVehicleNeonLightEnabled(vehicle, 1), IsVehicleNeonLightEnabled(vehicle, 2), IsVehicleNeonLightEnabled(vehicle, 3)}, neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)), extras = extras, tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)), modSpoilers = GetVehicleMod(vehicle, 0), modFrontBumper = GetVehicleMod(vehicle, 1), modRearBumper = GetVehicleMod(vehicle, 2), modSideSkirt = GetVehicleMod(vehicle, 3), modExhaust = GetVehicleMod(vehicle, 4), modFrame = GetVehicleMod(vehicle, 5), modGrille = GetVehicleMod(vehicle, 6), modHood = GetVehicleMod(vehicle, 7), modFender = GetVehicleMod(vehicle, 8), modRightFender = GetVehicleMod(vehicle, 9), modRoof = GetVehicleMod(vehicle, 10), modEngine = GetVehicleMod(vehicle, 11), modBrakes = GetVehicleMod(vehicle, 12), modTransmission = GetVehicleMod(vehicle, 13), modHorns = GetVehicleMod(vehicle, 14), modSuspension = GetVehicleMod(vehicle, 15), modArmor = GetVehicleMod(vehicle, 16), modTurbo = IsToggleModOn(vehicle, 18), modSmokeEnabled = IsToggleModOn(vehicle, 20), modXenon = IsToggleModOn(vehicle, 22), modFrontWheels = GetVehicleMod(vehicle, 23), modBackWheels = GetVehicleMod(vehicle, 24), modPlateHolder = GetVehicleMod(vehicle, 25), modVanityPlate = GetVehicleMod(vehicle, 26), modTrimA = GetVehicleMod(vehicle, 27), modOrnaments = GetVehicleMod(vehicle, 28), modDashboard = GetVehicleMod(vehicle, 29), modDial = GetVehicleMod(vehicle, 30), modDoorSpeaker = GetVehicleMod(vehicle, 31), modSeats = GetVehicleMod(vehicle, 32), modSteeringWheel = GetVehicleMod(vehicle, 33), modShifterLeavers = GetVehicleMod(vehicle, 34), modAPlate = GetVehicleMod(vehicle, 35), modSpeakers = GetVehicleMod(vehicle, 36), modTrunk = GetVehicleMod(vehicle, 37), modHydrolic = GetVehicleMod(vehicle, 38), modEngineBlock = GetVehicleMod(vehicle, 39), modAirFilter = GetVehicleMod(vehicle, 40), modStruts = GetVehicleMod(vehicle, 41), modArchCover = GetVehicleMod(vehicle, 42), modAerials = GetVehicleMod(vehicle, 43), modTrimB = GetVehicleMod(vehicle, 44), modTank = GetVehicleMod(vehicle, 45), modWindows = GetVehicleMod(vehicle, 46), modLivery = GetVehicleLivery(vehicle)}
	else
		return
	end
end

QBEXT.Game.SetVehicleProperties = function(vehicle, props)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleModKit(vehicle, 0)
		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
		if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
		if props.color1 then SetVehicleColours(vehicle, props.color1, colorSecondary) end
		if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
		if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor) end
		if props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor) end
		if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
		if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
		if props.neonEnabled then
			SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
			SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
			SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
			SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
		end
		if props.extras then
			for extraId,enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(extraId), 0)
				else
					SetVehicleExtra(vehicle, tonumber(extraId), 1)
				end
			end
		end
		if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
		if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) end
		if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
		if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
		if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
		if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
		if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
		if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
		if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
		if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
		if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
		if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
		if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
		if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
		if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
		if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
		if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
		if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
		if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
		if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
		if props.modTurbo then ToggleVehicleMod(vehicle,  18, props.modTurbo) end
		if props.modXenon then ToggleVehicleMod(vehicle,  22, props.modXenon) end
		if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
		if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
		if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
		if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
		if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
		if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
		if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
		if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
		if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
		if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
		if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
		if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
		if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
		if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
		if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
		if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
		if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
		if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
		if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
		if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
		if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
		if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
		if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
		if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end
		if props.modLivery then SetVehicleMod(vehicle, 48, props.modLivery, false) SetVehicleLivery(vehicle, props.modLivery) end
	end
end

QBEXT.Game.Utils.DrawText3D = function(coords, text, size, font)
	local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
	local camCoords = GetGameplayCamCoords()
	local distance = #(vector - camCoords)
	if not size then size = 1 end
	if not font then font = 0 end
	local scale = (size/distance)*2
	local fov = (1/GetGameplayCamFov())*100
	scale = scale*fov
	SetTextScale(0.0*scale, 0.55*scale)
	SetTextFont(font)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	SetDrawOrigin(vector.xyz, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
end

RegisterNetEvent("qbext:serverCallback")
AddEventHandler("qbext:serverCallback", function(requestId, ...)
	QBEXT.ServerCallbacks[requestId](...)
	QBEXT.ServerCallbacks[requestId] = nil
end)

Citizen.CreateThread(function()
	while true do
		local sleep = 100
		if #QBEXT.TimeoutCallbacks > 0 then
			local currTime = GetGameTimer()
			sleep = 0
			for i = 1, #QBEXT.TimeoutCallbacks, 1 do
				if currTime >= QBEXT.TimeoutCallbacks[i].time then
					QBEXT.TimeoutCallbacks[i].cb()
					QBEXT.TimeoutCallbacks[i] = nil
				end
			end
		end
		Citizen.Wait(sleep)
	end
end)