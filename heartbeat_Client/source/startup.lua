return function(arg)
    local flags = {};
	flags.fullscreen = false
	flags.fullscreentype = "desktop"
	flags.vsync = 0
	flags.stencil = false
	flags.resizable = false
	flags.borderless = false
	flags.centered = true
	flags.displayindex = 1
	flags.minwidth = 1
	flags.minheight = 1
    love.window.setMode(1200, 672, flags)

    love.filesystem.setIdentity(arg[2])

    g_input = require("source.input")

    g_ui = require("source.ui.ui")()
    g_ui:AddWidget("main_widget")
end