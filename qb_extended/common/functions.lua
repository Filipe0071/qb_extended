local Charset = {}

for i = 48, 57 do
	table.insert(Charset, string.char(i))
end

for i = 65, 90 do
	table.insert(Charset, string.char(i))
end

for i = 97, 122 do
	table.insert(Charset, string.char(i))
end

QBEXT.GetRandomString = function(length)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return QBEXT.GetRandomString(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ""
	end
end

QBEXT.GetConfig = function()
	return Config
end

QBEXT.DumpTable = function(table, nb)
	if nb == nil then
		nb = 0
	end
	if type(table) == "table" then
		local s = ""
		for i = 1, nb + 1, 1 do
			s = s .. "    "
		end
		s = "{\n"
		for k,v in pairs(table) do
			if type(k) ~= "number" then k = '"'..k..'"' end
			for i = 1, nb, 1 do
				s = s .. "    "
			end
			s = s .. "["..k.."] = " .. QBEXT.DumpTable(v, nb + 1) .. ",\n"
		end
		for i = 1, nb, 1 do
			s = s .. ""
		end
		return s .. "}"
	else
		return tostring(table)
	end
end

QBEXT.Round = function(value, numDecimalPlaces)
	return QBEXT.Math.Round(value, numDecimalPlaces)
end