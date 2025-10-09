-- SERA.AP: man i really should converge this with the other scrollbox class to save on code duplication
-- but not now

return function(x, y, w, h, callback)
	local scrollbox = {}
	scrollbox.scrollX = 0
	scrollbox.contentWidth = 0

	-- SERA.AP: this isn't reflective of actual size and position
	-- it's the size and position of the notch
	scrollbox.position = {
		["x"] = x,
		["y"] = y+h-8
	}
	scrollbox.size = {
		["w"] = w,
		["h"] = 8
	}

	function scrollbox:GetPosition()
		return self.position
	end

	function scrollbox:GetSize()
		return self.size
	end

	function scrollbox:GetActualSize()
		return {["w"]=w, ["h"]=h}
	end

	scrollbox.bSelected = false
	scrollbox.bHovered = false
	scrollbox.bDown = false
	scrollbox.zIndex = 0
	scrollbox.goToRightOnExpand = false
	scrollbox.contentWidthLastFrame = 0
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
		self.scrollX = self.scrollX + (dx * (self.contentWidth/w))
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
			if (g_uiUtil.aabb(
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
		if (self.contentWidth > w) then
			self.scrollX = math.min(math.max(self.scrollX, 0), self.contentWidth - w)
		else
			self.scrollX = 0
		end

		for _,registeredComponent in pairs(self.components) do
			registeredComponent.comp.position.x = registeredComponent.initialPos.x - self.scrollX
		end

		if (self.contentWidth > self.contentWidthLastFrame and self.goToRightOnExpand) then
			self:ToRight()
		end

		self.contentWidthLastFrame = self.contentWidth
	end

	function scrollbox:ToRight()
		if (self.contentWidth <= w) then return end
		if (self.bDown) then return end

		self.scrollX = self.contentWidth - w
	end

	function scrollbox:OnMouseWheelMoved(x, y, consumed)
		self.scrollX = self.scrollX - (y * 5)
	end
	g_input:BindToWheelMoved(scrollbox.OnMouseWheelMoved, scrollbox)

	function scrollbox:drawBar()
        local notchY = y+h-8

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x, notchY, w, 8)
		end, 
		0.9, 0.9, 0.9
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x, notchY, w, 2)
		end, 
		0.8, 0.8, 0.8
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", x, notchY, w, 2)
		end, 
		1, 1, 1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("line", x, notchY, w+1, 9)
		end, 
		0, 0, 0
		)

		local notchWidth = (w/self.contentWidth) * w
		local notchX = x + (self.scrollX/self.contentWidth) * w

		local r,g,b = 0.5, 0.5, 0.5
		if (self.bDown) then
			r,g,b = 0.75, 0.75, 0.75
		elseif (self.bHovered) then
			r,g,b = 0.4, 0.4, 0.4
		end

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", notchX, notchY, notchWidth, 8)
		end, 
		r, g, b
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", notchX, notchY + 6, notchWidth, 2)
		end, 
		r-0.1, g-0.1, b-0.1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("fill", notchX, notchY, notchWidth, 2)
		end, 
		r+0.1, g+0.1, b+0.1
		)

		g_gfxUtil:ColouredDraw(
		function()
			love.graphics.rectangle("line", notchX, notchY, notchWidth, 9)
		end, 
		0, 0, 0
		)
	end


	scrollbox.drawCallback = callback
	function scrollbox:draw()
		if not self.drawCallback then return end

		love.graphics.setScissor(x, y, w, h)
		love.graphics.push()

		self.contentWidth = self.drawCallback["func"](self.drawCallback["caller"], self:GetVisibleComponents(), self.scrollX, x, y, w, h)

		love.graphics.pop()
		love.graphics.setScissor()

		if (self.contentWidth <= w) then return end

		self:drawBar()
	end

	return scrollbox
end