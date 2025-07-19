local WallhopVisualizer = {}
WallhopVisualizer.__index = WallhopVisualizer

-- Constants
local COLORS = {
    Perfect = Color3.fromRGB(0, 255, 0),
    Wall = Color3.fromRGB(255, 0, 0),
    Height = Color3.fromRGB(0, 0, 255)
}
local DEFAULT_RAY_LENGTH = 50
local DEFAULT_RAY_COUNT = 36 -- 180° at 5° increments

local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")

-- Helper to create a part for visualization
local function createVisualPart(template, size, position, color)
    local part = template:Clone()
    part.Size = size
    part.Position = position
    part.Color = color
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.7
    part.Parent = workspace
    return part
end

function WallhopVisualizer.new(localPlayer, visualizationPart)
    local self = setmetatable({}, WallhopVisualizer)
    self.LocalPlayer = localPlayer

    self.VisualizationPart = visualizationPart or Instance.new("Part")
    self.VisualizationPart.Name = "WallhopBaseVisual"
    self.VisualizationPart.Anchored = true
    self.VisualizationPart.CanCollide = false
    self.VisualizationPart.Transparency = 0.7
    self.VisualizationPart.Parent = workspace

    self.RayLength = DEFAULT_RAY_LENGTH
    self.RayCount = DEFAULT_RAY_COUNT
    self.ActiveVisuals = {}

    -- Pre-create raycast params
    self.RaycastParams = RaycastParams.new()
    self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    return self
end

function WallhopVisualizer:CalculateOptimalJump(wallPosition, wallNormal)
    local character = self.LocalPlayer.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return nil end

    local playerPos = root.Position
    local toWall = wallPosition - playerPos
    local horizontalDistance = Vector3.new(toWall.X, 0, toWall.Z).Magnitude
    local verticalDistance = toWall.Y

    -- Jump physics
    local gravity = workspace.Gravity
    local jumpPower = humanoid.JumpPower
    -- Correct jump height formula: maxHeight = (jumpPower^2) / (2 * gravity)
    local maxHeight = (jumpPower ^ 2) / (2 * gravity)
    local timeToPeak = jumpPower / gravity

    local canReach = verticalDistance <= maxHeight

    if canReach then
        local requiredHorizontalSpeed = horizontalDistance / (2 * timeToPeak)
        return {
            Position = wallPosition,
            Normal = wallNormal,
            RequiredSpeed = requiredHorizontalSpeed,
            IsPerfect = math.abs(requiredHorizontalSpeed - humanoid.WalkSpeed) < 3
        }
    end
    return nil
end

function WallhopVisualizer:UpdateVisualization()
    -- Clear previous visuals
    for _, v in ipairs(self.ActiveVisuals) do v:Destroy() end
    self.ActiveVisuals = {}

    local character = self.LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local origin = root.Position
    local lookVector = root.CFrame.LookVector

    local bestJump = nil
    local jumps = {}

    self.RaycastParams.FilterDescendantsInstances = {character}

    for i = 0, self.RayCount - 1 do
        local angle = math.rad(180 * (i / (self.RayCount - 1) - 0.5))
        local rayDirection = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), angle) * lookVector

        local result = workspace:Raycast(origin, rayDirection * self.RayLength, self.RaycastParams)
        if result then
            local jumpData = self:CalculateOptimalJump(result.Position, result.Normal)
            if jumpData then
                table.insert(jumps, jumpData)

                -- Wall visual (red)
                table.insert(self.ActiveVisuals, createVisualPart(
                    self.VisualizationPart, Vector3.new(0.2, 0.2, 0.2), result.Position, COLORS.Wall
                ))

                -- Height visual (blue)
                local height = math.abs(result.Position.Y - origin.Y)
                local midY = (result.Position.Y + origin.Y) / 2
                table.insert(self.ActiveVisuals, createVisualPart(
                    self.VisualizationPart, Vector3.new(0.2, height, 0.2),
                    Vector3.new(result.Position.X, midY, result.Position.Z),
                    COLORS.Height
                ))
            end
        end
    end

    -- Find best jump from all candidates
    if #jumps > 0 then
        table.sort(jumps, function(a, b)
            if a.IsPerfect ~= b.IsPerfect then
                return a.IsPerfect -- Prefer perfect
            end
            return a.RequiredSpeed < b.RequiredSpeed -- Then lowest speed
        end)
        bestJump = jumps[1]
    end

    if bestJump then
        local perfectVisual = createVisualPart(
            self.VisualizationPart, Vector3.new(1, 1, 1), bestJump.Position, COLORS.Perfect
        )
        table.insert(self.ActiveVisuals, perfectVisual)

        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = perfectVisual
        billboard.Size = UDim2.new(4, 0, 2, 0)
        billboard.StudsOffset = Vector3.new(0, 2, 0)

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = string.format("Optimal Jump\nX: %.1f Y: %.1f Z: %.1f",
            bestJump.Position.X, bestJump.Position.Y, bestJump.Position.Z)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Parent = billboard
        billboard.Parent = perfectVisual
    end
end

function WallhopVisualizer:Start()
    if self.HeartbeatConnection then return end
    self.HeartbeatConnection = runService.Heartbeat:Connect(function()
        self:UpdateVisualization()
    end)
end

function WallhopVisualizer:Stop()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end
    for _, v in ipairs(self.ActiveVisuals) do v:Destroy() end
    self.ActiveVisuals = {}
end

return WallhopVisualizer