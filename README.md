# Heartbeat
A simple profiler for Love2D

# How to use

To use heartbeat, simply just drop heartbeat_Integrate into your project (removing the "_Integrate" from the folder name if you like), and then keep heartbeat_Client somewhere else. You want to make sure that you call **heartbeat:HeartbeatStart()** at the top of **love.update** and **heartbeat:HeartbeatEnd()** at the end of **love.draw**. You also want to call **Heartbeat::StartCapture** at the top of **love.load()**. Here's a minimal example:

```
local heartbeat = require("heartbeat_Integrate.heartbeat")

function love.load()
    heartbeat:StartCapture()
end

function love.update(dt)
    heartbeat:HeartbeatStart()

    -- all your update code goes here
end

function love.draw()
    -- all your draw code goes here

    heartbeat:HeartbeatEnd()
end
```

In addition to capturing performance data, Heartbeat can also capture sections within scopes and display them to help you identify problem areas. To use it, just do the following:

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

# Running Heartbeat Client
When you run the Heartbeat client, make sure you pass your game's identity into the start parameters. This is so that Heartbeat can retrieve the capture data (which is saved in your savedata as capture.lua). You can do this like so:

```
love.exe Heartbeat_Client {$YourGameName}
```

# Capture Data as Lua
Capture Data is output as Lua tables (one table per frame, one frame per line), formatted akin to JSONL. You can parse these in with load() and do some operations of your own on your capture data if you prefer not to use Heartbeat client.

# Enjoy!