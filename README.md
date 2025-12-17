# Heartbeat
A simple profiler for LÖVE

(docs/Heartbeat.png)

# Features
- Capture performance data such as frame rate, frame time, RAM usage, VRAM usage, and other such relevant performance data.
- Fully kitted out and capable performance data viewer.
- Integration into your game minimizes RAM usage and offsets file I/O onto another thread, making sure the profiler does not make a big dent on your game's performance.

# How to use

Heartbeat is split into two folders:
- heartbeat_Client
- heartbeat_Integrate

The Heartbeat Client is the viewer for your profiling data. Heartbeat Integrate is what you put into your game project. To setup Heartbeat, simply just put heartbeat_Integrate somewhere in your LÖVE project, and then require it where you want to capture performance data.

You want to ensure that you call **heartbeat:StartCapture()** before you capture any profiling data (typically, during **love.load()**) -- this sets up the file that the data will be sent to.

You also want to make sure that at the start of your profiling epoch, you call **heartbeat:HeartbeatStart()**, and then at the end, **heartbeat:HeartbeatEnd()**. This will typically be at the start and end of your frame respectively. I personally hook my Heartbeat into **love.run**'s game loop, like so:

```
function gameloop()
    if (programFlags.HEARTBEAT_TRACE_ENABLED) then
        heartbeat:HeartbeatStart()
    end

    if love.event then
        heartbeat:WithNamedScope("events", function()
            love.event.pump()
            for name, a, b, c, d, e, f, g, h in love.event.poll() do
                if name == "quit" then
                    if c or not love.quit or not love.quit() then
                        return a or 0, b
                    end
                end
                love.handlers[name](a, b, c, d, e, f, g, h)
            end
        end)
    end

    local dt = love.timer and love.timer.step() or 0

    if love.update then
        heartbeat:WithNamedScope("update", function()
            love.update(dt)
        end)
    end

    if love.graphics and love.graphics.isActive() then
        heartbeat:WithNamedScope("predraw", function()
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
        end)

        if (love.draw) then
            heartbeat:WithNamedScope("draw", function()
                love.draw()
            end)
        end

        heartbeat:WithNamedScope("present", function()
            love.graphics.present()
        end)
    end

    if (programFlags.HEARTBEAT_TRACE_ENABLED) then
        heartbeat:HeartbeatEnd()
    end
end
```

# Frame Data

**HeartbeatStart** and **HeartbeatEnd** define the start and end of a frame, and will therefore record the length of a frame, as well as how much RAM, VRAM, drawcalls, etc. happen inside that frame. This is visualized in the profiler nicely so you can keep track of what's going on.

# Scopes

Using either **heartbeat:PushNamedScope(text)** and **heartbeat:PopScope()**, or **heartbeat:WithNamedScope(name, func)** for the more RAII minded folks, you can define sections of code for which you want to measure performance impact. This will be populated in the viewer to enable you to track down and identify specific problem areas in your codebase.

Here's an example of using **PopScope** and **PushNamedScope**:

```
local heartbeat = require("heartbeat_Integrate.heartbeat")

-- etc.

function obj:ExpensiveFunc()
    -- doesn't need to match the name of the function, this is just a convention I personally use
    heartbeat:PushNamedScope("obj.ExpensiveFunc")

    -- ..

    -- maybe the bottleneck is in here..
    heartbeat:PushNamedScope("obj.ExpensiveFunc.Operation")

    heartbeat:PopScope()

    -- ..

    heartbeat:PopScope()
end
```

Here's the same code, using **WithNamedScope**:

```
local heartbeat = require("heartbeat_Integrate.heartbeat")

-- etc.

function obj:ExpensiveFunc()
    -- doesn't need to match the name of the function, this is just a convention I personally use
    heartbeat:WithNamedScope("obj.ExpensiveFunc", function()
        heartbeat:WithNamedScope("obj.ExpensiveFunc.Operation", function()
            -- maybe the bottleneck is in here..
        end)
    end)
end
```

I personally prefer WithNamedScope, but the choice is yours!

# Running Heartbeat Client
When you run the Heartbeat client, make sure you pass your game's identity into the start parameters. This is so that Heartbeat can retrieve the capture data (which is saved in your savedata as capture.lua). You can do this like so:

```
love.exe Heartbeat_Client {$YourGameName}
```

# Shoutout to MessagePack!

MessagePack is used to serialize and deserialize data. It's fast and results in small files. Credit for MessagePack 100% goes to François Perrad and can be found at https://fperrad.frama.io/lua-MessagePack/

# Enjoy!