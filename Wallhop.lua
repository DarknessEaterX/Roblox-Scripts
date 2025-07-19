local WallhopScientist = {}
WallhopScientist.__index = WallhopScientist

local PI = math.pi
local function deg2rad(deg) return deg * PI / 180 end

local COLORS = {
    Optimal = Color3.fromRGB(0, 255, 0),
    Wall = Color3.fromRGB(255, 0, 0),
    Trajectory = Color3.fromRGB(255, 255, 0),
    Angle = Color3.fromRGB(0, 255, 255),
    Probability = Color3.fromRGB(128, 0, 128)
}

local DEFAULT_RAY_LENGTH = 50
local DEFAULT_RAY_COUNT = 72
local TRAJECTORY_RESOLUTION = 20

local function predictTrajectory(origin, velocity, gravity, steps)
    local points = {}
    for i = 0, steps do
        local t = i / steps * 2 * velocity.Y / gravity
        local pos = origin + velocity * t + Vector3.new(0, -0.5 * gravity * t^2, 0)
        table.insert(points, pos)
    end
    return points
end

local function computeWallAngle(jumpDirection, wallNormal)
    local cosTheta = jumpDirection:Dot(wallNormal) / (jumpDirection.Magnitude * wallNormal.Magnitude)
    local theta = math.acos(math.clamp(cosTheta, -1, 1))
    return math.deg(theta)
end

function WallhopScientist.new(localPlayer, visualizationPart)
    local self = setmetatable({}, WallhopScientist)
    self.LocalPlayer = localPlayer

    self.VisualizationPart = visualizationPart or Instance.new("Part")
    self.VisualizationPart.Name = "WallhopScientistVisual"
    self.VisualizationPart.Anchored = true
    self.VisualizationPart.CanCollide = false
    self.VisualizationPart.Transparency = 0.7
    self.VisualizationPart.Parent = workspace

    self.RayLength = DEFAULT_RAY_LENGTH
    self.RayCount = DEFAULT_RAY_COUNT
    self.ActiveVisuals = {}

    self.RaycastParams = RaycastParams.new()
    self.RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    return self
end

function WallhopScientist:AnalyzeJump(wallPos, wallNormal)
    local character = self.LocalPlayer.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return nil end

    local origin = root.Position
    local gravity = workspace.Gravity
    local jumpPower = humanoid.JumpPower
    local walkSpeed = humanoid.WalkSpeed

    local toWall = wallPos - origin
    local horizontalDist = Vector3.new(toWall.X, 0, toWall.Z).Magnitude
    local verticalDist = toWall.Y

    local timeToPeak = jumpPower / gravity
    local maxHeight = (jumpPower ^ 2) / (2 * gravity)

    local canReach = verticalDist <= maxHeight

    local t_flight = (jumpPower + math.sqrt(jumpPower^2 + 2 * gravity * verticalDist)) / gravity
    local requiredHorizontalSpeed = horizontalDist / t_flight

    local wallAngle = computeWallAngle((wallPos - origin).Unit, wallNormal)

    local sigma = 5
    local mu = walkSpeed
    local probability = math.exp(-(requiredHorizontalSpeed - mu)^2 / (2 * sigma^2))

    return {
        Position = wallPos,
        Normal = wallNormal,
        RequiredSpeed = requiredHorizontalSpeed,
        CanReach = canReach,
        WallAngle = wallAngle,
        Probability = probability,
        TrajectoryPoints = predictTrajectory(origin, Vector3.new(0, jumpPower, 0) + (wallPos - origin).Unit * walkSpeed, gravity, TRAJECTORY_RESOLUTION)
    }
end

local function createVisual(template, size, position, color)
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

function WallhopScientist:UpdateVisualization()
    for _, v in ipairs(self.ActiveVisuals) do v:Destroy() end
    self.ActiveVisuals = {}

    local character = self.LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local origin = root.Position
    local lookVector = root.CFrame.LookVector
    self.RaycastParams.FilterDescendantsInstances = {character}

    local bestJump = nil
    local jumpCandidates = {}

    for i = 0, self.RayCount - 1 do
        local angle = deg2rad(180 * (i / (self.RayCount - 1) - 0.5))
        local direction = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), angle) * lookVector
        local result = workspace:Raycast(origin, direction * self.RayLength, self.RaycastParams)
        if result then
            local jumpData = self:AnalyzeJump(result.Position, result.Normal)
            if jumpData then
                table.insert(jumpCandidates, jumpData)
                table.insert(self.ActiveVisuals, createVisual(self.VisualizationPart, Vector3.new(0.2, 0.2, 0.2), result.Position, COLORS.Wall))

                local angleVisual = createVisual(self.VisualizationPart, Vector3.new(0.4, 0.4, 0.4), result.Position + result.Normal * 0.6, COLORS.Angle)
                local billboard = Instance.new("BillboardGui")
                billboard.Adornee = angleVisual
                billboard.Size = UDim2.new(4, 0, 2, 0)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.Text = string.format("Wall Angle: %.2f°", jumpData.WallAngle)
                textLabel.BackgroundTransparency = 1
                textLabel.TextColor3 = Color3.new(0,1,1)
                textLabel.Parent = billboard
                billboard.Parent = angleVisual
                table.insert(self.ActiveVisuals, angleVisual)

                for i = 1, #jumpData.TrajectoryPoints do
                    local trajVisual = createVisual(self.VisualizationPart, Vector3.new(0.1, 0.1, 0.1), jumpData.TrajectoryPoints[i], COLORS.Trajectory)
                    table.insert(self.ActiveVisuals, trajVisual)
                end
            end
        end
    end

    table.sort(jumpCandidates, function(a, b)
        if a.CanReach ~= b.CanReach then
            return a.CanReach
        end
        return a.Probability > b.Probability
    end)
    bestJump = jumpCandidates[1]

    if bestJump then
        local optimalVisual = createVisual(self.VisualizationPart, Vector3.new(1, 1, 1), bestJump.Position, COLORS.Optimal)
        table.insert(self.ActiveVisuals, optimalVisual)
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = optimalVisual
        billboard.Size = UDim2.new(6, 0, 2, 0)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.Text = string.format(
            "Scientist Jump:\nX: %.2f Y: %.2f Z: %.2f\nWall Angle: %.2f°\nRequired Speed: %.2f\nSuccess Probability: %.2f%%",
            bestJump.Position.X, bestJump.Position.Y, bestJump.Position.Z,
            bestJump.WallAngle, bestJump.RequiredSpeed, bestJump.Probability * 100
        )
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Parent = billboard
        billboard.Parent = optimalVisual
    end
end

function WallhopScientist:Start()
    if self.HeartbeatConnection then return end
    self.HeartbeatConnection = game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateVisualization()
    end)
end

function WallhopScientist:Stop()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end
    for _, v in ipairs(self.ActiveVisuals) do v:Destroy() end
    self.ActiveVisuals = {}
end

return WallhopScientist