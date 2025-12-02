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

	
	function gfxUtil:LerpRGB(a,b,t)
		return {
			["r"] = a.r*(1-t)+b.r*t,
			["g"] = a.g*(1-t)+b.g*t,
			["b"] = a.b*(1-t)+b.b*t
		}
	end

	return gfxUtil

end