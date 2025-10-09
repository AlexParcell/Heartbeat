local requestChannel = love.thread.getChannel("request")
local responseChannel = love.thread.getChannel("response")

local function RetrieveData(line)
    local func, err = load("return " .. line)
    if (func) then
        return func()
    end
    return nil
end

while true do
    local request = requestChannel:demand()
    if (request.type == "frames") then
        local baseX = request.x
        local scrollX = request.sX
        local x_offset = scrollX
        local scrollW = request.sw
        local clickedFrame = request.clickedFrame
        local zoom = request.zoom

        local fileLength = 0
        local ret = {}
        for line in love.filesystem.lines("capture.lua") do
            if (fileLength % zoom == 0) then
                if (((x_offset - baseX > scrollX + scrollW) or ((x_offset - baseX) < scrollX)) and fileLength ~= clickedFrame) then
                    ret[fileLength] = nil
                else
                    ret[fileLength] = RetrieveData(line)
                end
                x_offset = x_offset + 3
            end
            fileLength = fileLength + 1
        end
    
        responseChannel:push({type="data", data=ret, length=fileLength})
    end
end