-- DragnirNotif System (Enhanced with Real Icons & Mobile-Ready)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Notif = {}
Notif.__index = Notif

-- Icon & Color config (using FontAwesome icons)
local Icons = {
    Success = "",
    Warning = "",
    Error = "！",
    Info = ""
}

-- Alternative FontAwesome icons (uncomment if you have the font installed)
-- local Icons = {
--     Success = "", -- FontAwesome check
--     Warning = "", -- FontAwesome exclamation triangle
--     Error = "",   -- FontAwesome times circle
--     Info = ""     -- FontAwesome info circle
-- }

local Colors = {
    Success = Color3.fromRGB(0, 255, 0),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 60, 60),
    Info = Color3.fromRGB(100, 200, 255)
}

-- Get or create the GUI container once
local function getOrCreateGui()
    local gui = player:FindFirstChild("PlayerGui"):FindFirstChild("DragnirNotif")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "DragnirNotif"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        gui.Parent = player:WaitForChild("PlayerGui")

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Position = UDim2.new(0, 0, 0, 0)
        container.AnchorPoint = Vector2.new(1, 0)
        container.AutomaticSize = Enum.AutomaticSize.None
        container.ClipsDescendants = false
        container.Parent = gui

        -- Dynamic top-right positioning
        local viewportSize = Camera.ViewportSize
        container.Position = UDim2.new(1, -20, 0, 20)

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        layout.Parent = container

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = container
    end
    return gui
end

-- Send notification
function Notif:Send(type, message, duration)
    local gui = getOrCreateGui()
    local container = gui:FindFirstChild("Container")
    if not container then return end

    local screenSize = Camera.ViewportSize
    local frameWidth = math.clamp(screenSize.X * 0.4, 240, 400)
    local frameHeight = 50

    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    notifFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    notifFrame.BackgroundTransparency = 0.1
    notifFrame.BorderSizePixel = 0
    notifFrame.ClipsDescendants = true
    notifFrame.LayoutOrder = os.clock() * 1000
    notifFrame.AnchorPoint = Vector2.new(1, 0)
    notifFrame.Position = UDim2.new(1, 0, 0, 0)
    notifFrame.Parent = container

    local iconColor = Colors[type] or Color3.fromRGB(255, 255, 255)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = iconColor
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = notifFrame

    -- Icon container with padding
    local iconContainer = Instance.new("Frame")
    iconContainer.Size = UDim2.new(0, 40, 1, 0)
    iconContainer.BackgroundTransparency = 1
    iconContainer.Parent = notifFrame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.Text = Icons[type] or "?"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24
    icon.TextColor3 = iconColor
    icon.BackgroundTransparency = 1
    icon.Parent = iconContainer

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -50, 1, 0)
    text.Position = UDim2.new(0, 45, 0, 0)
    text.Text = message or "Notification"
    text.Font = Enum.Font.Gotham
    text.TextSize = 16
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.BackgroundTransparency = 1
    text.Parent = notifFrame

    -- Tween in from the right
    local initialPos = notifFrame.Position
    notifFrame.Position = UDim2.new(1, frameWidth + 40, 0, 0)

    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = initialPos
    })
    tweenIn:Play()

    task.delay(duration or 3, function()
        local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, frameWidth + 40, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notifFrame:Destroy()
    end)
end

return Notif