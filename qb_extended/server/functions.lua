QBEXT.SetTimeout = function(msec, cb)
	local id = QBEXT.TimeoutCount + 1
	SetTimeout(msec, function()
		if QBEXT.CancelledTimeouts[id] then
			QBEXT.CancelledTimeouts[id] = nil
		else
			cb()
		end
	end)
	QBEXT.TimeoutCount = id
	return id
end

QBEXT.ClearTimeout = function(id)
	QBEXT.CancelledTimeouts[id] = true
end

QBEXT.RegisterServerCallback = function(name, cb)
	QBEXT.ServerCallbacks[name] = cb
end

QBEXT.TriggerServerCallback = function(name, requestId, source, cb, ...)
	if QBEXT.ServerCallbacks[name] then
		QBEXT.ServerCallbacks[name](source, cb, ...)
	else
		print(('[^3WARNING^7] Server callback ^5"%s"^0 does not exist. ^1Please Check The Server File for Errors!'):format(name))
	end
end
