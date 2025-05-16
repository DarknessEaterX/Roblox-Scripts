local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Notif = {}
Notif.__index = Notif

local Icons = {
    Success = "✓",
    Warning = "⚠",
    Error = "✕",
    Info = "ℹ"
}

local Colors = {
    Success = Color3.fromRGB(0, 255, 0),
    Warning = Color3.fromRGB(255, 200, 0),
    Error = Color3.fromRGB(255, 60, 60),
    Info = Color3.fromRGB(100, 200, 255)
}

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
        container.Position = UDim2.new(1, -20, 0, 20)
        container.AnchorPoint = Vector2.new(1, 0)
        container.ClipsDescendants = false
        container.Parent = gui

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

function Notif:Send(type, message, duration)
    local gui = getOrCreateGui()
    local container = gui:FindFirstChild("Container")
    if not container then return end

    local screenSize = Camera.ViewportSize
    local frameWidth = math.clamp(screenSize.X * 0.4, 240, 400)
    local frameHeight = 80  -- Increased height for multiline support

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

    -- TextLabel (top-left) instead of icon, with padding 5,5
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 5, 0, 5)
    iconLabel.Text = Icons[type] or "?"
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 24
    iconLabel.TextColor3 = iconColor
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextWrapped = true
    iconLabel.Parent = notifFrame

    -- Close button top-right with 5 padding
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5) -- 5 right padding, 5 top padding
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundTransparency = 0.5
    closeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    closeButton.AutoButtonColor = true
    closeButton.Parent = notifFrame

    -- Text content label with wrapping and padding to avoid icon and close button
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, 0) -- leave space for icon + close
    text.Position = UDim2.new(0, 40, 0, 0)
    text.Text = message or "Notification"
    text.Font = Enum.Font.Gotham
    text.TextSize = 16
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.BackgroundTransparency = 1
    text.Parent = notifFrame

    -- Tween in from the right
    local initialPos = notifFrame.Position
    notifFrame.Position = UDim2.new(1, frameWidth + 40, 0, 0)

    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = initialPos
    })
    tweenIn:Play()

    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, frameWidth + 40, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notifFrame:Destroy()
    end)

    -- Auto close only if duration is a positive number
    if duration and duration > 0 then
        task.delay(duration, function()
            if notifFrame and notifFrame.Parent then
                local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Position = UDim2.new(1, frameWidth + 40, 0, 0)
                })
                tweenOut:Play()
                tweenOut.Completed:Wait()
                notifFrame:Destroy()
            end
        end)
    end
end
return Notif