QBEXT = {}

QBEXT.ServerCallbacks = {}

AddEventHandler("qbext:getSharedObject", function(cb)
	cb(QBEXT)
end)

function getSharedObject()
	return QBEXT
end

RegisterServerEvent("qbext:triggerServerCallback")
AddEventHandler("qbext:triggerServerCallback", function(name, requestId, ...)
	local playerId = source
	QBEXT.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent("qbext:serverCallback", playerId, requestId, ...)
	end, ...)
end)
