local input = {}

input.onKeyPressed = {}
input.onKeyReleased = {}
input.onMousePressed = {}
input.onMouseReleased = {}
input.onTextInput = {}
input.onMouseWheelMoved = {}
input.onMouseMoved = {}

function input:BindToKeyPressed(func, caller)
	table.insert(self.onKeyPressed, {["caller"] = caller, ["func"] = func})
end

function input:BindToKeyReleased(func, caller)
	table.insert(self.onKeyReleased, {["caller"] = caller, ["func"] = func})
end

function input:BindToMousePressed(func, caller)
	table.insert(self.onMousePressed, {["caller"] = caller, ["func"] = func})
end

function input:BindToMouseReleased(func, caller)
	table.insert(self.onMouseReleased, {["caller"] = caller, ["func"] = func})
end

function input:BindToTextInput(func, caller)
	table.insert(self.onTextInput, {["caller"] = caller, ["func"] = func})
end

function input:BindToWheelMoved(func, caller)
	table.insert(self.onMouseWheelMoved, {["caller"] = caller, ["func"] = func})
end

function input:BindToMouseMoved(func, caller)
	table.insert(self.onMouseMoved, {["caller"] = caller, ["func"] = func})
end

function input:RemoveBindings(obj, bindingsArray)
	for i,binding in pairs(bindingsArray) do
		if (binding.caller == obj) then
			table.remove(bindingsArray, i)
		end
	end
end

function input:RemoveAnyBindings(obj)
	if not obj then return end

	self:RemoveBindings(obj, self.onKeyPressed)
	self:RemoveBindings(obj, self.onKeyReleased)
	self:RemoveBindings(obj, self.onMousePressed)
	self:RemoveBindings(obj, self.onMouseReleased)
	self:RemoveBindings(obj, self.onTextInput)
	self:RemoveBindings(obj, self.onMouseWheelMoved)
	self:RemoveBindings(obj, self.onMouseMoved)
end

function love.keypressed(key)
	local consumed = false

	for _,funcPair in pairs(input.onKeyPressed) do
		local ret = funcPair["func"](funcPair["caller"], key, consumed)
		local consumed = consumer or ret
	end
end

function love.keyreleased(key)
	for _,funcPair in pairs(input.onKeyReleased) do
		funcPair["func"](funcPair["caller"], key)
	end
end

function love.mousepressed(x, y, button)
	local consumed = false

	for _,funcPair in pairs(input.onMousePressed) do
		local ret = funcPair["func"](funcPair["caller"], x, y, button, consumed)
		consumed = consumed or ret
	end
end

function love.mousereleased(x, y, button)
	for _,funcPair in pairs(input.onMouseReleased) do
		funcPair["func"](funcPair["caller"], x, y, button)
	end
end

function love.textinput(text)
	local consumed = false
	
	for _,funcPair in pairs(input.onTextInput) do
		local ret = funcPair["func"](funcPair["caller"], text, consumed) 
		consumed = consumed or ret
	end
end

function love.wheelmoved(x, y)
	local consumed = false

	for _,funcPair in pairs(input.onMouseWheelMoved) do
		local ret = funcPair["func"](funcPair["caller"], x, y, consumed) 
		consumed = consumed or ret
	end
end

function love.mousemoved(x, y, dx, dy, istouch)
	for _,funcPair in pairs(input.onMouseMoved) do
		funcPair["func"](funcPair["caller"], x, y, dx, dy, istouch)
	end
end

return input