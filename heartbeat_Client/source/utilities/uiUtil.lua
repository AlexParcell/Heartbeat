return function()
	local uiUtil = {}
	function uiUtil:centerAlignX(x, w)
		return x + (w/2)
	end

	function uiUtil:AABB(ax, ay, aw, ah, bx, by, bw, bh)
		return ax < bx + bw and
			ax + aw > bx and
			ay < by + bh and
			ay + ah > by
	end

	-- basically the same as MouseOverlapsObj but no position or size means true
	-- if we arent providing dimensions for a widget, we assume it's because it's all-encompassing
	function uiUtil:MouseOverlapsWidget(widget)
		if (widget.GetPosition == nil or widget.GetSize == nil) then
			return true
		end

		return self:MouseOverlapsObj(widget)
	end

	function uiUtil:MouseOverlapsObj(obj)
		if (obj.GetPosition == nil or obj.GetSize == nil) then
			return false
		end

		local mx, my = love.mouse.getPosition()
		local pos = obj:GetPosition()
		local size = obj:GetSize()

		if not pos or not size then return false end
		return self:AABB(mx, my, 1, 1, pos.x, pos.y, size.w, size.h)
	end

	function uiUtil:IsOnScreen(obj)
		if (obj.position == nil or obj.size == nil) then
			return false
		end

		mx = 0
		my = 0
		local mw = 1200
		local mh = 672
		local pos = obj:GetPosition()
		local size = obj:GetSize()

		if not pos or not size then return false end
		return self:AABB(mx, my, mw, mh, pos.x, pos.y, size.w, size.h)
	end

	function uiUtil:DistanceFromMouse(pos)
		if (pos.x == nil or pos.y == nil) then
			return -1.0
		end

		local mx, my = love.mouse.getPosition()

		local dx, dy = (mx-pos.x),(my-pos.y)
		return math.sqrt((dx*dx) + (dy*dy))
	end

	return uiUtil
end
