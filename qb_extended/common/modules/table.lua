QBEXT.Table = {}

function QBEXT.Table.SizeOf(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end

function QBEXT.Table.Set(t)
	local set = {}
	for k, v in ipairs(t) do
		set[v] = true
	end
	return set
end

function QBEXT.Table.IndexOf(t, value)
	for i = 1, #t, 1 do
		if t[i] == value then
			return i
		end
	end
	return -1
end

function QBEXT.Table.LastIndexOf(t, value)
	for i = #t, 1, -1 do
		if t[i] == value then
			return i
		end
	end
	return -1
end

function QBEXT.Table.Find(t, cb)
	for i = 1, #t, 1 do
		if cb(t[i]) then
			return t[i]
		end
	end
	return nil
end

function QBEXT.Table.FindIndex(t, cb)
	for i = 1, #t, 1 do
		if cb(t[i]) then
			return i
		end
	end
	return -1
end

function QBEXT.Table.Filter(t, cb)
	local newTable = {}
	for i = 1, #t, 1 do
		if cb(t[i]) then
			table.insert(newTable, t[i])
		end
	end
	return newTable
end

function QBEXT.Table.Map(t, cb)
	local newTable = {}
	for i = 1, #t, 1 do
		newTable[i] = cb(t[i], i)
	end
	return newTable
end

function QBEXT.Table.Reverse(t)
	local newTable = {}
	for i = #t, 1, -1 do
		table.insert(newTable, t[i])
	end
	return newTable
end

function QBEXT.Table.Clone(t)
	if type(t) ~= "table" then
		return t
	end
	local meta = getmetatable(t)
	local target = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = QBEXT.Table.Clone(v)
		else
			target[k] = v
		end
	end
	setmetatable(target, meta)
	return target
end

function QBEXT.Table.Concat(t1, t2)
	local t3 = QBEXT.Table.Clone(t1)
	for i = 1, #t2, 1 do
		table.insert(t3, t2[i])
	end
	return t3
end

function QBEXT.Table.Join(t, sep)
	local sep = sep or ","
	local str = ""
	for i = 1, #t, 1 do
		if i > 1 then
			str = str .. sep
		end
		str = str .. t[i]
	end
	return str
end

function QBEXT.Table.Sort(t, order)
	local keys = {}
	for k, _ in pairs(t) do
		keys[#keys + 1] = k
	end
	if order then
		table.sort(keys, function(a, b)
			return order(t, a, b)
		end)
	else
		table.sort(keys)
	end
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end