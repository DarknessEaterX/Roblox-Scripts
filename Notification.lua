local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Notif = {}
Notif.__index = Notif

local MAX_NOTIFICATIONS = 5

local Icons = {
    Success = "✓",
    Warning = "⚠",
    Error   = "✕",
    Info    = "ℹ"
}

local Colors = {
    Success = Color3.fromRGB(59, 201, 87),
    Warning = Color3.fromRGB(255, 200, 0),
    Error   = Color3.fromRGB(255, 60, 60),
    Info    = Color3.fromRGB(100, 200, 255)
}

local safeWaitForChild = function(parent, childName, timeout)
    local ok, obj = pcall(function()
        return parent:WaitForChild(childName, timeout or 2)
    end)
    return ok and obj or nil
end

local function getOrCreateGui()
    local pg = safeWaitForChild(player, "PlayerGui")
    if not pg then return nil end

    local gui = pg:FindFirstChild("DragnirNotif")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "DragnirNotif"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        gui.Parent = pg

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Position = UDim2.new(1, -20, 0, 20)
        container.AnchorPoint = Vector2.new(1, 0)
        container.ClipsDescendants = false
        container.Parent = gui

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 7)
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

-- Track notifications for stacking/limiting
local activeNotifications = {}

local function capNotifications(container)
    while #activeNotifications > MAX_NOTIFICATIONS do
        local notif = table.remove(activeNotifications, 1)
        if notif and notif.Close then notif:Close("stacked") end
    end
end

function Notif:Send(type, message, duration, onClose)
    type = Icons[type] and type or "Info"
    duration = tonumber(duration) or 4

    local gui = getOrCreateGui()
    if not gui then return end
    local container = gui:FindFirstChild("Container")
    if not container then return end

    -- Notification frame
    local screenSize = Camera.ViewportSize
    local frameWidth = math.clamp(screenSize.X * 0.4, 240, 420)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, frameWidth, 0, 80)
    notifFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    notifFrame.BackgroundTransparency = 0.07
    notifFrame.BorderSizePixel = 0
    notifFrame.ClipsDescendants = true
    notifFrame.LayoutOrder = os.clock() * 1000
    notifFrame.AnchorPoint = Vector2.new(1, 0)
    notifFrame.Position = UDim2.new(1, 0, 0, 0)
    notifFrame.Parent = container

    -- Drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, -4, 0, -4)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageTransparency = 0.7
    shadow.ZIndex = 0
    shadow.Parent = notifFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = notifFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors[type]
    stroke.Thickness = 1.5
    stroke.Transparency = 0.25
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = notifFrame

    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 8, 0, 8)
    iconLabel.Text = Icons[type]
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 24
    iconLabel.TextColor3 = Colors[type]
    iconLabel.BackgroundTransparency = 1
    iconLabel.ZIndex = 2
    iconLabel.Parent = notifFrame

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 22, 0, 22)
    closeButton.Position = UDim2.new(1, -30, 0, 8)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
    closeButton.BackgroundTransparency = 0.35
    closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    closeButton.AutoButtonColor = true
    closeButton.ZIndex = 2
    closeButton.Parent = notifFrame

    -- Hover effect for close
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
    end)
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end)

    -- Main message
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -75, 1, -26)
    text.Position = UDim2.new(0, 45, 0, 8)
    text.Text = message or "Notification"
    text.Font = Enum.Font.Gotham
    text.TextSize = 16
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.TextWrapped = true
    text.BackgroundTransparency = 1
    text.ZIndex = 2
    text.Parent = notifFrame

    -- Responsive Height
    text.Size = UDim2.new(1, -75, 1, -26)
    text.AutomaticSize = Enum.AutomaticSize.Y
    notifFrame.AutomaticSize = Enum.AutomaticSize.Y

    -- Animation IN (slide + fade)
    notifFrame.Position = UDim2.new(1, frameWidth + 40, 0, notifFrame.Position.Y.Offset)
    notifFrame.BackgroundTransparency = 1
    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 0, 0, notifFrame.Position.Y.Offset),
        BackgroundTransparency = 0.07
    })
    tweenIn:Play()

    local closed = false

    -- Closure handler
    local function doClose(reason)
        if closed then return end
        closed = true
        -- Animation OUT (slide + fade)
        local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.33, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, frameWidth + 40, 0, notifFrame.Position.Y.Offset),
            BackgroundTransparency = 1
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        if notifFrame.Parent then notifFrame:Destroy() end
        if typeof(onClose) == "function" then
            pcall(onClose, reason or "closed")
        end
    end

    -- User close
    closeButton.MouseButton1Click:Connect(function()
        doClose("user")
    end)

    -- Auto close
    if duration > 0 then
        task.delay(duration, function()
            doClose("timeout")
        end)
    end

    -- Closure API
    notifFrame.Close = doClose

    -- Stacking management
    table.insert(activeNotifications, notifFrame)
    capNotifications(container)

    return notifFrame
end

function Notif.new()
    return setmetatable({}, Notif)
end

return Notif