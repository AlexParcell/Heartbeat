local requirePath = (...):match("(.-)[^%.]+$")
local Stack = require(requirePath.."stack")
local FileIO = require(requirePath.."file_io")
local heartbeat = {}

heartbeat.stack = Stack.new()

-- scopes
function heartbeat:PushNamedScope(name)
    if (not self.captureActive) then
        return
    end

    local stats = love.graphics.getStats()
    local newScope = {}

    newScope.name = name
    newScope.parentName = (self.stack:peek() ~= nil) and self.stack:peek().name or nil
    newScope.startGCMemory = collectgarbage("count") / 1024 
    newScope.startTime = love.timer.getTime()
    newScope.startTextureMemory = stats.texturememory / (1024 * 1024)
    self.stack:push(newScope)
end

heartbeat.completedScopes = {}
function heartbeat:PopScope()
    if (not self.captureActive) then
        return
    end

    local stats = love.graphics.getStats()
    local scope = self.stack:pop()
    
    if (scope) then
        scope.endTime = love.timer.getTime()
        scope.endGCMemory = collectgarbage("count") / 1024
        scope.endTextureMemory = stats.texturememory / (1024 * 1024)
        table.insert(self.completedScopes, scope)
    end
end

function heartbeat:WithNamedScope(name, fn)
    self:PushNamedScope(name)
    local retA, retB, retC, retD, retE, retF = fn()
    self:PopScope()
    return retA, retB, retC, retD, retE, retF
end

heartbeat.captureActive = false
function heartbeat:StartCapture()
    self.captureActive = true
    FileIO:StartFile("capture")
end

function heartbeat:HeartbeatStart()
    if (not self.captureActive) then
        return
    end

    self:PushNamedScope("Heartbeat")
end

-- frames
function heartbeat:HeartbeatEnd()
    if (not self.captureActive) then
        return
    end

    self:PopScope()
    self:PopScope()

    local root = nil
    for _,scope in pairs(self.completedScopes) do
        if (scope.name == "Heartbeat") then
            root = scope
        end
    end

    if not root then return end

    local heartbeatTime = root.endTime - root.startTime

    local stats = love.graphics.getStats()

    local frame = {}
    frame.FPS = math.floor((1/(heartbeatTime or 0)) + 0.5)
    frame.drawCalls = stats.drawcalls
    frame.drawCallsBatched = stats.drawCallsBatched
    frame.textureMemory = stats.texturememory / (1024 * 1024)
    frame.gcMemory = collectgarbage("count") / 1024

    local outData = {
        frame = frame,
        scopes = self.completedScopes
    }
    self.completedScopes = {}

    FileIO:AppendFile(outData)
end

return heartbeat