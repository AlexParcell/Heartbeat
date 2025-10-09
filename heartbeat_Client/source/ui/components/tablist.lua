return function(x, y, w, h, tab_entries)
	local tablist = {}

	tablist.bSelected = false
	tablist.tabEntries = tab_entries
	tablist.entryBatches = {}
	for _,entry in pairs(tab_entries) do
		tablist.entryBatches[entry] = love.graphics.newTextBatch(g_ui.font, entry)
	end
	tablist.selectedTab = 1
	tablist.hoveredTab = nil
	tablist.individualTabSize = w / #tab_entries

	tablist.position = {
		["x"] = x,
		["y"] = y
	}

	tablist.size = {
		["w"] = w,
		["h"] = h
	}

	function tablist:GetPosition()
		return self.position
	end

	function tablist:GetSize()
		return self.size
	end

	function tablist:CheckTabBeingHovered()
		local mx, my = love.mouse.getPosition()

		for i,tabEntry in pairs(self.tabEntries) do
			local startX, endX = self:GetTabStartAndEndX(i)

			if (mx >= startX and mx <= endX) then
				self.hoveredTab = i
				break
			end
		end
	end

	function tablist:GetCurrentTab()
		return self.tabEntries[self.selectedTab]
	end

	function tablist:onSelect()
		self:CheckTabBeingHovered()
	end
	
	function tablist:onEndSelect()
		self.hoveredTab = nil
	end

	tablist.onTabChanged = {}
	function tablist:BindToOnTabChanged(func, caller)
		table.insert(self.onTabChanged, {["caller"] = caller, ["func"] = func})
	end

	function tablist:TabChanged()
		for _,funcPair in pairs(self.onTabChanged) do
			funcPair["func"](funcPair["caller"], self.tabEntries[self.selectedTab])
		end
	end


	function tablist:OnMousePressed(x, y, button, consumed)
		if (consumed or not self.bSelected) then
			return false
		end

		if (self.hoveredTab and self.hoveredTab ~= self.selectedTab) then
			self.selectedTab = self.hoveredTab
			self:TabChanged()
		end

		return true
	end
	g_input:BindToMousePressed(tablist.OnMousePressed, tablist)

	function tablist:update(deltaTime)
		if (self.bSelected) then
			self:CheckTabBeingHovered()
		end
	end

	function tablist:GetTabStartAndEndX(tabIdx)
		local start = self.position.x + ((tabIdx-1) * self.individualTabSize)
		return start, start + self.individualTabSize
	end

	function tablist:draw()
		g_gfxUtil:ColouredDraw(function()
			love.graphics.rectangle("fill", self.position.x, self.position.y, self.size.w, self.size.h)
		end,
		0.2,0.2,0.2,0.4)

		if (self.hoveredTab ~= nil) then
			g_gfxUtil:ColouredDraw(function()
				local startX, endX = self:GetTabStartAndEndX(self.hoveredTab)
				
				love.graphics.rectangle("fill", startX, self.position.y, self.individualTabSize, self.size.h)
			end,
			0.5,0.5,0.5,0.25)
		end

		g_gfxUtil:ColouredDraw(function()
			local startX, endX = self:GetTabStartAndEndX(self.selectedTab)

			g_gfxUtil:DrawLine(4, startX, self.position.y + self.size.h - 2, endX, self.position.y + self.size.h - 2)
		end,
		1, 1, 1)

		for i,tabText in pairs(self.tabEntries) do
			local textBatch = self.entryBatches[tabText]
			local textWidth = textBatch:getWidth()
			local startX, endX = self:GetTabStartAndEndX(i)
			local halfX = startX + (self.individualTabSize/2)
			local centerAlignX = halfX - (textWidth/2)

			local textHeight = textBatch:getHeight()
			local centerAlignY = self.position.y + (self.size.h/2) - (textHeight/2) + 1

			love.graphics.draw(textBatch, centerAlignX, centerAlignY - 2)

		end
	end

	return tablist
end