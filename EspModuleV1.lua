-- EspModuleV1.lua
-- Cross-platform ESP module with modern design and smooth functionality

local EspModule = {}
EspModule.__index = EspModule

-- Configuration constants
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
local ENEMY_COLOR = Color3.fromRGB(255, 50, 50)
local TEAM_COLOR = Color3.fromRGB(50, 255, 50)
local FOV_CIRCLE_COLOR = Color3.fromRGB(255, 255, 255)
local FOV_CIRCLE_TRANSPARENCY = 0.7
local SMOOTHING_FACTOR = 0.15 -- Lower values = smoother aim assist

-- Module state
local enabled = false
local settings = {
    nameESP = true,
    boxESP = true,
    distance = true,
    tracers = true,
    teamCheck = true,
    fovCircle = true,
    aimAssist = true,
    fovRadius = 100
}

-- UI elements cache
local espCache = {}
local fovCircle
local connections = {}

-- Utility functions
local function worldToViewport(position)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local screenPos, onScreen = camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function calculateDistance(position)
    local camera = workspace.CurrentCamera
    if not camera or not camera.CFrame then return 0 end
    
    return (position - camera.CFrame.Position).Magnitude
end

local function createLabel()
    local label = Drawing.new("Text")
    label.Size = 14
    label.Center = true
    label.Outline = true
    label.Font = 2 -- Gothic SemiBold
    return label
end

local function createLine()
    local line = Drawing.new("Line")
    line.Thickness = 1
    return line
end

local function createSquare()
    local square = Drawing.new("Square")
    square.Thickness = 1
    square.Filled = false
    return square
end

local function createCircle()
    local circle = Drawing.new("Circle")
    circle.Thickness = 1
    circle.Filled = false
    circle.NumSides = 64
    return circle
end

-- ESP functions
local function updatePlayerESP(player, character)
    if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
        if espCache[player] then
            for _, drawing in pairs(espCache[player]) do
                drawing:Remove()
            end
            espCache[player] = nil
        end
        return
    end

    local rootPart = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    local humanoid = character.Humanoid
    
    -- Initialize cache if not exists
    if not espCache[player] then
        espCache[player] = {
            nameLabel = createLabel(),
            distanceLabel = createLabel(),
            box = createSquare(),
            tracer = createLine()
        }
    end
    
    local cache = espCache[player]
    local screenPosition, onScreen, depth = worldToViewport(rootPart.Position)
    local headPosition = head and worldToViewport(head.Position)
    
    -- Team check
    local isTeamMate = settings.teamCheck and (player.Team == game.Players.LocalPlayer.Team)
    local color = isTeamMate and TEAM_COLOR or ENEMY_COLOR
    
    -- Name ESP
    if settings.nameESP then
        cache.nameLabel.Visible = onScreen
        cache.nameLabel.Position = screenPosition + Vector2.new(0, -40)
        cache.nameLabel.Text = player.DisplayName or player.Name
        cache.nameLabel.Color = color
    else
        cache.nameLabel.Visible = false
    end
    
    -- Distance ESP
    if settings.distance then
        cache.distanceLabel.Visible = onScreen
        cache.distanceLabel.Position = screenPosition + Vector2.new(0, -25)
        cache.distanceLabel.Text = string.format("[%d studs]", calculateDistance(rootPart.Position))
        cache.distanceLabel.Color = color
    else
        cache.distanceLabel.Visible = false
    end
    
    -- Box ESP
    if settings.boxESP and headPosition then
        local height = (screenPosition.Y - headPosition.Y) * 2
        local width = height * 0.65
        
        cache.box.Visible = onScreen
        cache.box.Position = screenPosition - Vector2.new(width/2, height/2)
        cache.box.Size = Vector2.new(width, height)
        cache.box.Color = color
    else
        cache.box.Visible = false
    end
    
    -- Tracers
    if settings.tracers then
        local viewportSize = workspace.CurrentCamera.ViewportSize
        
        cache.tracer.Visible = onScreen
        cache.tracer.From = Vector2.new(viewportSize.X/2, viewportSize.Y)
        cache.tracer.To = Vector2.new(screenPosition.X, screenPosition.Y)
        cache.tracer.Color = color
    else
        cache.tracer.Visible = false
    end
    
    -- Aim assist logic
    if settings.aimAssist and onScreen and not isTeamMate then
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local center = Vector2.new(viewportSize.X/2, viewportSize.Y/2)
        local distanceToCenter = (screenPosition - center).Magnitude
        
        if distanceToCenter <= settings.fovRadius then
            -- This would be where aim assist logic goes
            -- Note: Actual aimbot implementation is not provided as it would violate ethical guidelines
        end
    end
end

local function updateFOVCircle()
    if not settings.fovCircle then
        if fovCircle then
            fovCircle:Remove()
            fovCircle = nil
        end
        return
    end
    
    if not fovCircle then
        fovCircle = createCircle()
        fovCircle.Color = FOV_CIRCLE_COLOR
        fovCircle.Transparency = FOV_CIRCLE_TRANSPARENCY
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local viewportSize = camera.ViewportSize
    fovCircle.Position = Vector2.new(viewportSize.X/2, viewportSize.Y/2)
    fovCircle.Radius = settings.fovRadius
    fovCircle.Visible = true
end

-- Main loop
local function espLoop()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            updatePlayerESP(player, player.Character)
        end
    end
end

-- Module methods
function EspModule:Toggle(state)
    enabled = state
    
    if enabled then
        -- Initialize connections
        connections.playerAdded = game.Players.PlayerAdded:Connect(function(player)
            connections[player] = player.CharacterAdded:Connect(function(character)
                updatePlayerESP(player, character)
            end)
        end)
        
        connections.playerRemoving = game.Players.PlayerRemoving:Connect(function(player)
            if connections[player] then
                connections[player]:Disconnect()
                connections[player] = nil
            end
            if espCache[player] then
                for _, drawing in pairs(espCache[player]) do
                    drawing:Remove()
                end
                espCache[player] = nil
            end
        end)
        
        connections.characterAdded = game.Players.LocalPlayer.CharacterAdded:Connect(function()
            -- Refresh all ESP when local player respawns
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    updatePlayerESP(player, player.Character)
                end
            end
        end)
        
        connections.renderStep = game:GetService("RunService").RenderStepped:Connect(function()
            espLoop()
            updateFOVCircle()
        end)
        
        -- Initialize existing players
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                connections[player] = player.CharacterAdded:Connect(function(character)
                    updatePlayerESP(player, character)
                end)
                updatePlayerESP(player, player.Character)
            end
        end
    else
        -- Clean up connections and drawings
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        connections = {}
        
        for _, cache in pairs(espCache) do
            for _, drawing in pairs(cache) do
                drawing:Remove()
            end
        end
        espCache = {}
        
        if fovCircle then
            fovCircle:Remove()
            fovCircle = nil
        end
    end
end

function EspModule:UpdateSetting(setting, value)
    if settings[setting] ~= nil then
        settings[setting] = value
        return true
    end
    return false
end

function EspModule:SetFOVRadius(radius)
    settings.fovRadius = math.clamp(radius, 10, 500)
end

function EspModule:GetSettings()
    return table.clone(settings)
end

return EspModule