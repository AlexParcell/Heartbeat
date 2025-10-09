return function()
	local gfxUtil = {}	

	function gfxUtil:ColouredDraw(func, r, g, b, a)
		love.graphics.setColor(r, g, b, a)
		func()
		love.graphics.setColor(1, 1, 1, 1)
	end

	function gfxUtil:DrawLine(width, x1, y1, x2, y2, ...)
		love.graphics.setLineStyle("rough")
		local priorWidth = love.graphics.getLineWidth()
		love.graphics.setLineWidth(width)
		love.graphics.line(x1, y1, x2, y2, ...)
		love.graphics.setLineWidth(priorWidth)
	end

	return gfxUtil

end