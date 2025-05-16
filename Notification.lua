-- DragnirNotif System (Improved Version)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Notif = {}
Notif.__index = Notif

-- Color configuration
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
        container.ClipsDescendants = false
        container.Parent = gui

        -- Dynamic top-right positioning
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
    -- Validate input
    if not type or not Colors[type] then
        warn("Invalid notification type: "..tostring(type))
        type = "Info"
    end
    
    if not message or type(message) ~= "string" then
        message = "Notification"
    end
    
    duration = tonumber(duration) or 3

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

    local iconColor = Colors[type]

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = notifFrame

    -- Add border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = iconColor
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = notifFrame

    -- Type label (top-left with padding)
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0, 0, 0, 20)
    typeLabel.Position = UDim2.new(0, 5, 0, 5)
    typeLabel.Text = string.upper(type)
    typeLabel.Font = Enum.Font.GothamBold
    typeLabel.TextSize = 14
    typeLabel.TextColor3 = iconColor
    typeLabel.BackgroundTransparency = 1
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.AutomaticSize = Enum.AutomaticSize.X
    typeLabel.Parent = notifFrame

    -- Main message text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -10, 1, -30)
    text.Position = UDim2.new(0, 5, 0, 25)
    text.Text = message
    text.Font = Enum.Font.Gotham
    text.TextSize = 16
    text.TextColor3 = Color3.new(1, 1, 1)
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.TextWrapped = true
    text.BackgroundTransparency = 1
    text.Parent = notifFrame

    -- Close button (top-right with padding)
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 18
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.BackgroundTransparency = 1
    closeButton.Parent = notifFrame

    -- Close button hover effect
    closeButton.MouseEnter:Connect(function()
        closeButton.TextColor3 = Color3.new(1, 1, 1)
    end)
    
    closeButton.MouseLeave:Connect(function()
        closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    end)

    -- Close functionality
    local function closeNotification()
        if notifFrame then
            local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, frameWidth + 40, 0, 0)
            })
            tweenOut:Play()
            tweenOut.Completed:Wait()
            notifFrame:Destroy()
        end
    end

    closeButton.MouseButton1Click:Connect(closeNotification)

    -- Tween in from the right
    local initialPos = notifFrame.Position
    notifFrame.Position = UDim2.new(1, frameWidth + 40, 0, 0)

    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = initialPos
    })
    tweenIn:Play()

    -- Auto-close after duration
    if duration > 0 then
        task.delay(duration, closeNotification)
    end
end

return Notif