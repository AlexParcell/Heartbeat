local luaWriter = {}
local requirePath = (...):match("(.-)[^%.]+$")
local requestChannel = love.thread.getChannel("request")

local filePath = (...):match("(.-)[^%.]+$"):gsub("%.", "/")
local appendThread = love.thread.newThread(filePath.."file_append_thread.lua")

function luaWriter:StartFile(path)
    self.path = path and path .. ".lua" or "capture.lua"
    appendThread:start({requirePath = requirePath, filePath = self.path})
    love.filesystem.write(self.path, "")
end

function luaWriter:AppendFile(data)
    requestChannel:push({type="append", filedata=data})
end

return luaWriter