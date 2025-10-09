require("source.globals")

function love.load()
    require("source.startup")(arg)
end

function love.update(dt)
    require("source.update")(dt)
end

function love.draw()
    require("source.draw")()
end

function love.quit()

end