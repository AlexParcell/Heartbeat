local requestChannel = love.thread.getChannel("request")
local responseChannel = love.thread.getChannel("response")

local function truncate(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult) / mult
end

return function()
    local mainWidget = {}

    local fileThread = love.thread.newThread("source/utilities/file_thread.lua")
    fileThread:start()

    mainWidget.position = {
        ["x"] = 0,
        ["y"] = 0
    }

    mainWidget.size = {
        ["w"] = 1200,
        ["h"] = 672
    }

    mainWidget.buttons = {}

    mainWidget.graphStartX = 100

    function mainWidget:GetSelectableComponents()
        local comps = {}
        table.insert(comps, self.graphScrollbox)
        local scrollboxComps = self.graphScrollbox:GetVisibleComponents()
        for _, vComp in pairs(scrollboxComps) do
            table.insert(comps, vComp)
        end

        table.insert(comps, self.scopeScrollbox)
        local scopeScrollboxComps = self.scopeScrollbox:GetVisibleComponents()
        for _, vComp in pairs(scopeScrollboxComps) do
            table.insert(comps, vComp)
        end

        for _, comp in pairs(self.buttons) do
            table.insert(comps, comp)
        end

        table.insert(comps, self.tablist)
        table.insert(comps, self.slider)

        return comps
    end

    mainWidget.fileCache = {}
    mainWidget.fileLength = 0
    mainWidget.needData = false
    mainWidget.cacheTime = 2
    mainWidget.cacheElapsed = 0.0
    function mainWidget:Update(dt)
        self.cacheElapsed = self.cacheElapsed + dt
        if (((self.cacheElapsed > self.cacheTime) or self.needData) and requestChannel:getCount() == 0) then
            requestChannel:clear()

            local baseX = math.floor(self.graphScrollbox.scrollX)
            local scrollX = self.graphScrollbox:GetPosition().x
            local scrollW = self.graphScrollbox:GetActualSize().w

            requestChannel:push({
                type = "frames",
                x = baseX,
                sX = scrollX,
                sw = scrollW,
                clickedFrame = self
                    .clickedFrame,
                zoom = self.zoom
            })
            self.cacheElapsed = 0.0
        end

        local batch = responseChannel:pop()
        if batch then
            self.fileCache = batch.data
            self.fileLength = batch.length
            self.needData = false
        end

        self.tablist:update(dt)
        self.graphScrollbox:update(dt)
        self.slider:update(dt)
        self.scopeScrollbox:update(dt)
    end

    mainWidget.graphHeight = 250
    function mainWidget:DrawMarkers()
        local divisions = 10
        local bottom = self.position.y + self.size.h - 20
        local top = (mainWidget.position.y + self.size.h) - self.graphHeight

        local valueIncrement = (self.upperBound * 1.1) / divisions
        local posIncrement = (bottom - top) / divisions

        local currentValue = 0
        local currentPos = bottom

        love.graphics.line(self.graphStartX, top, self.graphStartX, self.position.y + self.size.h)
        love.graphics.line(self.size.w - 200, top, self.size.w - 200, self.position.y + self.size.h)

        for i = 0, divisions do
            local currentValueString = ""
            if (self.tablist:GetCurrentTab() == "FPS") then
                currentValueString = tostring(math.floor(currentValue))
            else
                currentValueString = tostring(truncate(currentValue, 2) .. "mb")
            end

            local valWidth = g_ui.font:getWidth(currentValueString)
            local baseX = self.graphStartX - valWidth - 5

            if (i ~= 0 and i ~= divisions) then
                love.graphics.setColor(1, 1, 1, 0.75)
            end
            love.graphics.line(self.graphStartX, currentPos, self.size.w - 200, currentPos)
            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.print(currentValueString, g_ui.font, baseX, currentPos - (g_ui.font:getHeight() / 2))

            currentValue = currentValue + valueIncrement
            currentPos = currentPos - posIncrement
        end
    end

    mainWidget.zoom = 1
    function mainWidget:Draw()
        self.slider:draw()
        self.tablist:draw()
        self.graphScrollbox:draw()
        self.scopeScrollbox:draw()
        self:DrawMarkers()
    end

    mainWidget.mouseDown = false
    function mainWidget:OnMouseDown(x, y, button, consumed)
        if consumed then return false end

        self.mouseDown = true

        return false
    end

    g_input:BindToMousePressed(mainWidget.OnMouseDown, mainWidget)

    function mainWidget:OnMouseUp(x, y, button)
        self.clickedFrame = self.selectedFrame
        self.mouseDown = false
    end

    g_input:BindToMouseReleased(mainWidget.OnMouseUp, mainWidget)

    mainWidget.selectedFrame = 0
    mainWidget.clickedFrame = 0
    mainWidget.upperBound = 0
    function mainWidget:GraphScrollboxDraw(components, scrollX, x, y, w, h)
        local baseX = math.floor(scrollX)
        self.selectedFrame = self.clickedFrame
        local x_offset = x
        local contentWidth = 0

        if (self.fileLength == 0) then
            self.needData = true
            return 0
        end

        -- ------------------------------------------------------------
        -- Pass 1: compute a stable upper bound for scaling this draw
        -- ------------------------------------------------------------
        local maxValue = 0

        for lineIdx = 1, self.fileLength do
            if (lineIdx % self.zoom == 0) then
                local data = self.fileCache[lineIdx]
                if data then
                    local value
                    if (self.tablist:GetCurrentTab() == "FPS") then
                        value = data.frame.FPS
                    elseif (self.tablist:GetCurrentTab() == "RAM") then
                        value = data.frame.gcMemory
                    else
                        value = data.frame.textureMemory
                    end

                    if value > maxValue then maxValue = value end
                end
            end
        end

        self.upperBound = maxValue

        -- avoid divide-by-zero if everything is 0 / missing
        local denom = (self.upperBound * 1.1)
        if denom <= 0 then denom = 1e-9 end
        local scaledUnit = h / denom

        -- ------------------------------------------------------------
        -- Pass 2: draw using the fixed scale from above
        -- ------------------------------------------------------------
        for lineIdx = 1, self.fileLength do
            if (lineIdx % self.zoom == 0) then
                contentWidth = math.max(x_offset + 3, contentWidth)

                local data = self.fileCache[lineIdx]
                if data then
                    local value
                    if (self.tablist:GetCurrentTab() == "FPS") then
                        value = data.frame.FPS
                    elseif (self.tablist:GetCurrentTab() == "RAM") then
                        value = data.frame.gcMemory
                    else
                        value = data.frame.textureMemory
                    end

                    local heightRatio = (value * scaledUnit)

                    local mx, my = love.mouse.getPosition()
                    if (g_uiUtil:AABB(mx, my, 1, 1, (x_offset - baseX) - 1, y, 3, h - 8)) then
                        self.selectedFrame = lineIdx
                        g_ui:SetTooltip(
                            "Frame: " .. lineIdx .. "\n\
                        FPS: " .. data.frame.FPS .. "\n\
                        RAM: " .. truncate(data.frame.gcMemory, 2) .. "mb\n\
                        VRAM: " .. truncate(data.frame.textureMemory, 2) .. "mb\n\
                        Drawcalls: " .. data.frame.drawCalls, 0.5, 600)
                    end

                    if (self.clickedFrame == lineIdx) then
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.rectangle("fill", x_offset - baseX - 1, y, 3, h)
                        love.graphics.setColor(1, 1, 1, 1)
                    elseif (self.selectedFrame == lineIdx) then
                        love.graphics.setColor(1, 0, 1, 1)
                        love.graphics.rectangle("fill", x_offset - baseX - 1, y, 3, h)
                        love.graphics.setColor(1, 1, 1, 1)
                    end

                    local r, g, b = 0.75, 0, 0.75
                    love.graphics.setColor(r, g, b, 1)
                    love.graphics.rectangle("fill", x_offset - baseX, (y + h) - heightRatio, 1, heightRatio)
                    love.graphics.setColor(1, 1, 1, 1)
                elseif (((x_offset - baseX) <= scrollX + w) and ((x_offset - baseX) >= scrollX)) or self.clickedFrame == lineIdx then
                    self.needData = true
                end

                x_offset = x_offset + 3
            end
        end

        return contentWidth - x
    end

    function mainWidget:TabChanged()
        self.upperBound = 0
    end

    mainWidget.tablist = require("source.ui.components.tablist")(
        mainWidget.position.x, (mainWidget.position.y + (mainWidget.size.h) - mainWidget.graphHeight) - 64, 1200, 48,
        { "FPS", "RAM", "VRAM" }
    )
    mainWidget.tablist:BindToOnTabChanged(mainWidget.TabChanged, mainWidget)

    mainWidget.graphScrollbox = require("source.ui.components.horizontal_scrollbox")(
        mainWidget.position.x + mainWidget.graphStartX,
        mainWidget.position.y + (mainWidget.size.h) - mainWidget.graphHeight,
        mainWidget.size.w - mainWidget.graphStartX - 200, mainWidget.graphHeight,
        { ["caller"] = mainWidget, ["func"] = mainWidget.GraphScrollboxDraw }
    )

    mainWidget.slider = require("source.ui.components.slider")(
        mainWidget.position.x + mainWidget.size.w - 175,
        mainWidget.position.y + mainWidget.size.h - 50,
        150,
        { "1", "2", "4", "8", "16", "32" }
    )

    function mainWidget:OnSliderChoiceChanged(newChoice, oldChoice)
        local oldZoom = tonumber(oldChoice)
        local newZoom = tonumber(newChoice)
        local factor = oldZoom / newZoom
        self.graphScrollbox.scrollX = (self.graphScrollbox.scrollX * factor)
        self.clickedFrame = self.clickedFrame + self.clickedFrame % newChoice
        self.zoom = newZoom
    end

    function mainWidget:ScopeScrollboxDraw(visibleComponents, scrollY, x, y, w, h)
        local data = self.fileCache[self.clickedFrame]
        if data == nil then return 0 end

        local scopes     = data.scopes

        local frameStart = math.huge
        local frameEnd   = -math.huge
        for i = 1, #scopes do
            frameStart = math.min(frameStart, scopes[i].startTime)
            frameEnd   = math.max(frameEnd, scopes[i].endTime)
        end

        local totalSpan = math.max(frameEnd - frameStart, 1e-9) -- avoid /0
        local function time_to_x(t) return x + (t - frameStart) / totalSpan * (w - 8) end
        local function span_to_w(s, e) return (e - s) / totalSpan * (w - 8) end

        table.sort(scopes, function(a, b)
            if a.startTime ~= b.startTime then return a.startTime < b.startTime end
            return (a.endTime - a.startTime) > (b.endTime - b.startTime)
        end)

        local open = {}
        local lanes = {}
        for i = 1, #scopes do
            local s = scopes[i]
            while #open > 0 and open[#open].endTime <= s.startTime do
                table.remove(open) -- pop
            end
            lanes[i] = #open
            table.insert(open, s)
        end

        local rowHeight  = 32
        local rowSpacing = 4
        local baseY      = y + 2

        for i = 1, #scopes do
            local s = scopes[i]
            local lane = lanes[i]
            local rx = time_to_x(s.startTime)
            local rw = span_to_w(s.startTime, s.endTime)
            local ry = baseY + lane * (rowHeight + rowSpacing)

            -- clamp zero/very tiny widths so they’re visible
            if rw < 1 then rw = 1 end

            local mx, my = love.mouse.getPosition()
            local hovered = false
            if (g_uiUtil:AABB(mx, my, 1, 1, rx, ry, rw, rowHeight)) then
                hovered = true
                g_ui:SetTooltip(
                    "Name: " .. s.name .. "\n\
                Duration: " .. truncate((s.endTime - s.startTime) * 1000, 4) .. "ms\n\
                RAM: " .. truncate((s.endGCMemory - s.startGCMemory) * 1024, 4) .. "kb\n\
                VRAM: " .. truncate((s.endTextureMemory - s.startTextureMemory) * 1024, 4) .. "kb\n\
                ", 0.5, 600)
            end

            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.rectangle("fill", rx, ry, rw, rowHeight)
            love.graphics.setColor(1, 1, 1, 1)
            if (hovered) then
                love.graphics.rectangle("line", rx, ry, rw, rowHeight)
            end


            love.graphics.setScissor(rx, ry, rw, rowHeight)
            love.graphics.push()
            local text = scopes[i].name .. " (" .. ((scopes[i].endTime - scopes[i].startTime) * 1000) .. "ms)"
            love.graphics.print(text, rx + 3, ry + 2)
            love.graphics.pop()
            love.graphics.setScissor()
        end

        local totalLanes = 0
        for i = 1, #lanes do
            totalLanes = math.max(totalLanes, lanes[i])
        end

        local neededHeight = (totalLanes + 1) * (rowHeight + rowSpacing) + 8
        return neededHeight
    end

    mainWidget.scopeScrollbox = require("source.ui.components.scrollbox")(
        8, 64,
        mainWidget.size.w - 8, mainWidget.size.h - mainWidget.graphHeight - 128,
        { ["caller"] = mainWidget, ["func"] = mainWidget.ScopeScrollboxDraw }
    )

    mainWidget.slider:BindToSliderChoiceChanged(mainWidget.OnSliderChoiceChanged, mainWidget)

    return mainWidget
end
