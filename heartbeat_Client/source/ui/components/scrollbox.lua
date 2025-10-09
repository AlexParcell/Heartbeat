return function(x, y, w, h, callback)
	local scrollbox = {}
	scrollbox.scrollY = 0
	scrollbox.contentHeight = 0

	-- SERA.AP: this isn't reflective of actual size and position
	-- it's the size and position of the notch
	scrollbox.position = {
		["x"] = x+w-8,
		["y"] = y
	}
	scrollbox.size = {
		["w"] = 8,
		["h"] = h
	}

	function scrollbox:GetPosition()
		return self.position
	end

	function scrollbox:GetSize()
		return self.size
	end

	scrollbox.bSelected = false
	scrollbox.bHovered = false
	scrollbox.bDown = false
	scrollbox.zIndex = 0
	scrollbox.goToBottomOnExpand = false
	scrollbox.contentHeightLastFrame = 0
	scrollbox.components = {} -- components that are inside of the scrollbox

	function scrollbox:onSelect()
		self.bHovered = true
	end

	function scrollbox:onEndSelect()
		self.bHovered = false
	end

	function scrollbox:OnMousePressed(x, y, button, consumed)
		if (self.bHovered) then
			self.bDown = true
		end
	end
	g_input:BindToMousePressed(scrollbox.OnMousePressed, scrollbox)

	function scrollbox:OnMouseMoved(x, y, dx, dy, isTouch)
		if not self.bDown then return end
		self.scrollY = self.scrollY + (dy * (self.contentHeight/h))
	end
	g_input:BindToMouseMoved(scrollbox.OnMouseMoved, scrollbox)

	function scrollbox:OnMouseReleased(x, y, button)
		self.bDown = false
	end
	g_input:BindToMouseReleased(scrollbox.OnMouseReleased, scrollbox)

	function scrollbox:GetAllComponents()
		local ret = {}
		for _,c in pairs(self.components) do
			table.insert(ret, c.comp)
		end
		return ret
	end

	function scrollbox:SetNewInitialPosition(component, newPosition)
		for _,c in pairs(self.components) do
			if (c.comp == component) then
				c.initialPos = {["x"]=newPosition.x, ["y"]=newPosition.y}
			end
		end
	end

	function scrollbox:GetVisibleComponents()
		local ret = {}

		for _,c in pairs(self.components) do
			if (g_uiUtil:AABB(
				x, y, w, h, c.comp.position.x, c.comp.position.y, c.comp.size.w, c.comp.size.h
				)
			) then
				table.insert(ret, c.comp)
			end
		end

		return ret
	end
	
	function scrollbox:RegisterComponent(component, transformToScrollbox)
		if (transformToScrollbox) then
			component.position.x = component.position.x + x
			component.position.y = component.position.y + y
		end

		table.insert(self.components,
		{
			["comp"] = component,
			["initialPos"] = {["x"] = component.position.x, ["y"] = component.position.y}
		})
	end

	function scrollbox:DeregisterComponent(component)
		for i=#self.components, 1, -1 do
			if (self.components.comp == component) then
				table.remove(self.components, i)
			end
		end
	end

	function scrollbox:update(deltaTime)
		if (self.contentHeight > h) then
			self.scrollY = math.min(math.max(self.scrollY, 0), self.contentHeight - h)
		else
			self.scrollY = 0
		end

		for _,registeredComponent in pairs(self.components) do
			registeredComponent.comp.position.y = registeredComponent.initialPos.y - self.scrollY
		end

		if (self.contentHeight > self.contentHeightLastFrame and self.goToBottomOnExpand) then
			self:ToBottom()
		end

		self.contentHeightLastFrame = self.contentHeight
	end

	function scrollbox:ToBottom()
		if (self.contentHeight <= h) then return end

		self.scrollY = self.contentHeight - h
	end

	function scrollbox:OnMouseWheelMoved(x, y, consumed)
		self.scrollY = self.scrollY - (y * 5)
	end
	g_input:BindToWheelMoved(scrollbox.OnMouseWheelMoved, scrollbox)

	function scrollbox:drawBar()
		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-8, y, 8, h)
		end, 
		0.9, 0.9, 0.9
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-2, y, 2, h)
		end, 
		0.8, 0.8, 0.8
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-8, y, 2, h)
		end, 
		1, 1, 1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("line", x+w-8, y, 9, h + 1)
		end, 
		0, 0, 0
		)

		local notchHeight = (h/self.contentHeight) * h
		local notchY = y + (self.scrollY/self.contentHeight) * h

		local r,g,b = 0.5, 0.5, 0.5
		if (self.bDown) then
			r,g,b = 0.75, 0.75, 0.75
		elseif (self.bHovered) then
			r,g,b = 0.4, 0.4, 0.4
		end

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-8, notchY, 8, notchHeight)
		end, 
		r, g, b
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-2, notchY, 2, notchHeight)
		end, 
		r-0.1, g-0.1, b-0.1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x+w-8, notchY, 2, notchHeight)
		end, 
		r+0.1, g+0.1, b+0.1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("line", x+w-8, notchY, 9, notchHeight)
		end, 
		0, 0, 0
		)
	end


	scrollbox.drawCallback = callback
	function scrollbox:draw()
		if not self.drawCallback then return end
		love.graphics.setScissor(x, y, w, h)
		love.graphics.push()

		self.contentHeight = self.drawCallback["func"](self.drawCallback["caller"], self:GetVisibleComponents(), self.scrollY, x, y, w, h)

		love.graphics.pop()
		love.graphics.setScissor()

		if (self.contentHeight <= h) then return end

		self:drawBar()
	end

	return scrollbox
end