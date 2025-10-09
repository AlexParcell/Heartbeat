local luaWriter = {}

function luaWriter:EncodeSimpleType(value)
    local datumType = type(value)
    return (datumType == "nil" and "nil")
        or (datumType == "boolean" and tostring(value))
        or (datumType == "number" and tostring(value))
        or (datumType == "string" and '"' .. value .. '"')
end 

-- if all keys are sequential numbers, it's an array
function luaWriter:EncodeArrayTable(value, depth)
    local items = {}

    for i=1, #value do
        table.insert(items, self:Encode(value[i], depth + 1))
    end

    return "[" .. table.concat(items, ",") .. "]"
end

function luaWriter:EncodeTable(value, depth)
    local items = {}

    for k,v in pairs(value) do
        local key = self:EncodeSimpleType(k)
        local val = ""
        if type(v) == "table" then
            val = self:EncodeTable(v, depth + 1)
        else
            val = self:EncodeSimpleType(v)
        end
        local indexIsNumber = type(k) == "number"
        local outText = "[" .. key .. "]=" .. val
        table.insert(items, outText) 
    end
    return "{" .. table.concat(items, ",") .. "}"
end

function luaWriter:Encode(value, depth)
    depth = depth or 0

    local datumType = type(value)
    if datumType == "table" then
        return self:EncodeTable(value, depth)
    else
        return self:EncodeSimpleType(value)
    end
end

function luaWriter:StartFile(path)
    self.path = path and path .. ".lua" or "capture.lua"
    love.filesystem.write(self.path, "")
end

function luaWriter:AppendFile(data)
    local serializedData = self:Encode(data)
    love.filesystem.append(self.path, serializedData .. "\n")
    return serializedData
end

return luaWriter