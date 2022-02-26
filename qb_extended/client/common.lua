AddEventHandler("qbext:getSharedObject", function(cb)
	cb(QBEXT)
end)

function getSharedObject()
	return QBEXT
end