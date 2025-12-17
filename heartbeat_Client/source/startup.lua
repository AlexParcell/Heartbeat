return function(arg)
    love.filesystem.setIdentity(arg[2])

    g_input = require("source.input")

    g_ui = require("source.ui.ui")()
    g_ui:AddWidget("main_widget")
end