local requestChannel = love.thread.getChannel("request")
local responseChannel = love.thread.getChannel("response")
local mp = require("source.utilities.messagepack")

while true do
  local request = requestChannel:demand()
  if request.type == "frames" then
    local baseX, scrollX, scrollW = request.x, request.sX, request.sw
    local clickedFrame, zoom = request.clickedFrame, request.zoom

    local bytes = love.filesystem.read("capture.lua") or "" -- whole file as binary
    local total = #bytes
    local i = 1

    local fileLength = 0
    local ret = {}
    local x_offset = scrollX

    local function read_u32()
      if i + 3 > total then return nil end
      local len, nexti = love.data.unpack(">I4", bytes, i)
      i = nexti
      return len
    end

    while true do
      local len = read_u32()
      if not len then break end
      if i + len - 1 > total then
        -- truncated final record; stop cleanly
        break
      end

      local payload = bytes:sub(i, i + len - 1)
      i = i + len

      -- your sampling / visibility logic
      if (fileLength % zoom == 0) then
        local out_of_view = ((x_offset - baseX > scrollX + scrollW) or ((x_offset - baseX) < scrollX))
        if not (out_of_view and fileLength ~= clickedFrame) then
          local ok, val = pcall(mp.unpack, payload)
          if ok then
            ret[fileLength] = val
          else
            -- corrupted record; skip gracefully
            ret[fileLength] = nil
          end
        end
        x_offset = x_offset + 3
      end

      fileLength = fileLength + 1
    end

    responseChannel:push({ type = "data", data = ret, length = fileLength })
  end
end