return function()
	local ui = {}
	ui.widgets = {}
	ui.focusedWidget = nil
	ui.font = love.graphics.newFont(16)

	ui.tooltipDuration = 1.5
	ui.tooltipTimeUp = 0.0
	ui.toolTipText = ""
	ui.toolTipWidth = 150
	ui.componentToSelect = nil

	function ui:ProcessSelection()
		self.componentToSelect = nil

		if self.focusedWidget ~= nil and self.focusedWidget.GetSelectableComponents ~= nil then
			if (g_uiUtil:MouseOverlapsWidget(self.focusedWidget)) then
				for _,component in pairs(self.focusedWidget:GetSelectableComponents()) do
					if component ~= nil then
						if g_uiUtil:MouseOverlapsObj(component) and g_uiUtil:IsOnScreen(component) then
							if not self.componentToSelect 
								or (self.componentToSelect and component.zIndex > self.componentToSelect.zIndex) then
								self.componentToSelect = component
							end
						end
					end
				end
			end

			if self.componentToSelect and not self.componentToSelect.bSelected then
				self.componentToSelect.bSelected = true
				self.componentToSelect:onSelect()
			end

			for _,component in pairs(self.focusedWidget:GetSelectableComponents()) do
				if component ~= self.componentToSelect and component.bSelected then
					component.bSelected = false
					component:onEndSelect()
				end
			end
		end
	end

	function ui:UpdateTooltip(deltaTime)
		if (self.toolTipText ~= "") then
			self.tooltipTimeUp = self.tooltipTimeUp + deltaTime
			if (self.tooltipTimeUp >= self.tooltipDuration) then
				self.toolTipText = ""
				self.tooltipTimeUp = 0
			end
		end
	end

	function ui:Update(deltaTime)
		self:ProcessSelection()
		self:UpdateTooltip(deltaTime)

		for _,widget in pairs(self.widgets) do
			if widget ~= nil then
				widget:Update(deltaTime)
			end
		end
	end

	function ui:OnMouseDown(x, y, button, consumed)
		if consumed then return false end

		return false
	end

	g_input:BindToMousePressed(ui.OnMouseDown, ui)

	function ui:Draw()
		if (self.focusedWidget) then
			if (self.focusedWidget.drawOnlyThis) then
				self.focusedWidget:Draw()
			else
				-- always draw the HUD first
				if (self.widgets["main_widget"]) then
					self.widgets["main_widget"]:Draw()
				end

				for key,widget in pairs(self.widgets) do
					if widget ~= nil and key ~= "main_widget" and widget ~= self.focusedWidget then
						widget:Draw()
					end
				end
			end
		end

		if (self.toolTipText ~= "") then
			self:DrawTooltip(self.toolTipText, self.font, self.toolTipWidth)
		end

		love.graphics.print("FPS: "..tostring(love.timer.getFPS()), self.font, 0, 0)
	end

	function ui:IsWidgetOpen(WidgetName)
		return self.widgets[WidgetName] ~= nil
	end

	function ui:AddWidget(WidgetName, ...)
		self.widgets[WidgetName] = require("source.ui.widgets." .. WidgetName)(...)
		if self.focusedWidget == nil then
			self.focusedWidget = self.widgets[WidgetName]
		end
		return self.widgets[WidgetName]
	end

	function ui:SetTooltip(text, duration, width)
		self.tooltTipWidth = width
		self.toolTipText = text
		self.tooltipDuration = duration
		self.tooltipTimeUp = 0
	end

	function ui:DrawTooltip(text, font, maxWidth)
		local mx, my = love.mouse.getPosition()
		local xPadding = 20
		local yPadding = 10

		local lines = g_stringUtil:BreakStringIntoWrappedLines(text, maxWidth, font)
		local boxWidth, boxHeight = 0
		for _,line in pairs(lines) do
			boxWidth = math.max(boxWidth, font:getWidth(line)) + (xPadding * 2)
		end
		boxHeight = ((#lines+1) * font:getHeight()) + (yPadding * 2)

		if (my + boxHeight > 672) then
			my = my - boxHeight
		end

		if (mx + boxWidth > 1200) then
			mx = mx - boxWidth
		end

		g_gfxUtil:ColouredDraw(function()
			love.graphics.rectangle("fill", mx, my, boxWidth, boxHeight)
		end, 0, 0, 0, 0.6)

		local textY = my
		for _,line in pairs(lines) do
			love.graphics.print(line, font, mx + xPadding, textY, 0, 1, 1)

			love.graphics.print(line, font, mx + xPadding, textY, 0, 0, 0, 1, 1, 1)

			textY = textY + font:getHeight() + yPadding
		end
	end

	function ui:SetFocus(widget)
		local oldFocusedWidget = self.focusedWidget

		if widget == nil then
			self.focusedWidget = self.widgets["main_widget"]
		else
			self.focusedWidget = widget
		end

		-- end selection on formerly focused and selected components
		if oldFocusedWidget ~= self.focusedWidget then
			for _,component in pairs(oldFocusedWidget:GetSelectableComponents()) do
				if component.bSelected then
					component.bSelected = false
					component:onEndSelect()
				end
			end
		end
	end

	function ui:RemoveWidget(WidgetName)
		local widget = self.widgets[WidgetName]
		if (widget == self.focusedWidget) then	
			self:SetFocus(nil)
		end
		if (widget) then
			g_input:RemoveAnyBindings(widget)
			for _,comp in pairs(widget:GetSelectableComponents()) do
				self:DestroyComponent(comp)
			end

			self.widgets[WidgetName] = nil
		end
	end

	function ui:DestroyComponent(comp)
		if comp.onDestroy then
			comp:onDestroy()
		end

		if comp.bSelected then
			comp.bSelected = false
			comp:onEndSelect()
		end

		g_input:RemoveAnyBindings(comp)
	end

	return ui
end