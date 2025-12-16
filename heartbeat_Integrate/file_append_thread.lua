local requestChannel = love.thread.getChannel("request")
local requirePath = (...).requirePath
local filePath = (...).filePath
local mp = require(requirePath.."messagepack")

while true do
    local request = requestChannel:demand()
    if request.type == "append" then
        local filedata = request.filedata
        local payload = mp.pack(filedata)
        local header  = love.data.pack("string", ">I4", #payload) -- 4-byte big-endian length

        local f = assert(love.filesystem.openFile(filePath, "a"))
        assert(f:write(header))
        assert(f:write(payload))
        f:close()
    end
end