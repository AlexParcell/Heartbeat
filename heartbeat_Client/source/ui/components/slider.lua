return function(x, y, w, items)
	local slider = {}

	slider.bSelected = false
	slider.bHovered = false
	slider.bClickedOn = false
	slider.items = items
	slider.selectedItemIdx = 1

	slider.onSliderChoiceChanged = {}
	function slider:BindToSliderChoiceChanged(func, caller)
		table.insert(self.onSliderChoiceChanged, {["caller"] = caller, ["func"] = func})
	end
	function slider:SliderChoiceChanged(oldChoice)
		for _,funcPair in pairs(self.onSliderChoiceChanged) do
			funcPair["func"](funcPair["caller"], slider.items[slider.selectedItemIdx], oldChoice)
		end
	end

	slider.position = {
		["x"] = x,
		["y"] = y
	}
	slider.size = {
		["w"] = w,
		["h"] = 10
	}

	function slider:GetPosition()
		return self.position
	end

	function slider:GetSize()
		return self.size
	end

	function slider:onSelect()
		self.bHovered = true
	end

	function slider:onEndSelect()
		self.bHovered = false
	end

	function slider:OnMousePressed(x, y, button, consumed)
		if (consumed) then
			if (not self.bSelected) then
				self.bClickedOn = false
			end
			return false
		end

		self.bClickedOn = self.bSelected
		return self.bClickedOn
	end
	g_input:BindToMousePressed(slider.OnMousePressed, slider)

	function slider:GetChoice()
		return self.items[self.selectedItemIdx]
	end


	slider.notchPointLocations = {}
	function slider:draw()
		local sliderX = self.position.x
		local sliderY = self.position.y
		local sliderW = self.size.w

		sliderY = sliderY + 5
		sliderX = sliderX + 5
		sliderW = sliderW - 10

		g_gfxUtil:ColouredDraw(
			function()
			g_gfxUtil:DrawLine(3, sliderX-1, sliderY, sliderX+sliderW+1, sliderY)
			end, 0, 0, 0)

		local selectedNotchX = 0
		local selectedNotchText = ""
		for idx,item in pairs(slider.items) do
			local notchXOffset = (idx - 1) * (1/(#slider.items-1)) * sliderW
			local notchX = sliderX + notchXOffset

			g_gfxUtil:ColouredDraw(
			function()
				g_gfxUtil:DrawLine(3,  notchX, sliderY - 3, notchX, sliderY + 3)
			end, 0, 0, 0)

			g_gfxUtil:DrawLine(1, notchX, sliderY - 2, notchX, sliderY + 2)

			self.notchPointLocations[idx] = {["x"] = notchX, ["y"] = sliderY - 2}

			love.graphics.print(item, g_ui.font, notchX - (g_ui.font:getWidth(item)/2), sliderY + 5)
			
			if (idx == self.selectedItemIdx) then
				selectedNotchX = notchX
				selectedNotchText = item
			end
		end

		g_gfxUtil:DrawLine(1, sliderX, sliderY, sliderX+sliderW, sliderY)

		local r,g,b = 1,1,1
		if (self.bClickedOn) then
			r,g,b = 0.5, 0.5, 0.5
		elseif (self.bHovered) then
			r,g,b = 0.75, 0.75, 0.75
		end

		g_gfxUtil:ColouredDraw(
		function()
			g_gfxUtil:DrawLine(5, selectedNotchX, sliderY - 5, selectedNotchX, sliderY + 5)
		end, 0, 0, 0)

		g_gfxUtil:ColouredDraw(
		function()
			g_gfxUtil:DrawLine(3, selectedNotchX, sliderY - 4, selectedNotchX, sliderY + 3)
		end, r, g, b)


		local lineY = sliderY + 8 + g_ui.font:getHeight()
		local lineX = selectedNotchX - (g_ui.font:getWidth(selectedNotchText)/2)

		g_gfxUtil:ColouredDraw(
		function()
			g_gfxUtil:DrawLine(3, lineX-1, lineY, lineX + g_ui.font:getWidth(selectedNotchText)+3, lineY)
		end, 0, 0, 0)

		g_gfxUtil:DrawLine(1, lineX, lineY, lineX + g_ui.font:getWidth(selectedNotchText)+2, lineY)
	end

	function slider:update(deltaTime)
		if (self.bClickedOn and not love.mouse.isDown(1)) then
			self.bClickedOn = false
		end

		if (self.bClickedOn) then
			local currentIdx = self.selectedItemIdx
			local closestDist = 999999
			local closestIdx = -1

			for idx,point in pairs(self.notchPointLocations) do
				if (g_uiUtil:DistanceFromMouse(point) < closestDist) then
					closestDist = g_uiUtil:DistanceFromMouse(point)
					closestIdx = idx
				end
			end

			self.selectedItemIdx = closestIdx
			if (currentIdx ~= self.selectedItemIdx) then
				self:SliderChoiceChanged(items[currentIdx])
			end
		end
	end

	return slider
end