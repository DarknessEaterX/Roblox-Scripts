
local NotificationModule = {}

-- Configuration
local SETTINGS = {
    types = {
        info = { Color = Color3.fromRGB(47, 49, 54), Icon = "rbxassetid://6031094678" },
        success = { Color = Color3.fromRGB(87, 242, 135), Icon = "rbxassetid://6031094667" },
        warning = { Color = Color3.fromRGB(254, 231, 92), Icon = "rbxassetid://6031094661" },
        error = { Color = Color3.fromRGB(237, 66, 69), Icon = "rbxassetid://6031094634" },
    },
    textColor = Color3.fromRGB(255, 255, 255),
    font = Enum.Font.GothamMedium,
    titleSize = 16,
    bodySize = 14,
    cornerRadius = UDim.new(0, 8),
    notificationWidth = 300,
    minHeight = 50,
    spacing = 8,
    maxNotifications = 5,
    defaultDuration = 4,
    longDuration = 6,
    zIndex = 100,
    slideTime = 0.25,
    fadeTime = 0.2,
    hoverPause = true
}

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Initialize the notification system
function NotificationModule.init(player)
    -- Wait for player's PlayerGui to exist
    while not player:FindFirstChild("PlayerGui") do
        task.wait()
    end
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Remove old notification GUI if exists
    local oldGui = playerGui:FindFirstChild("NotificationGui")
    if oldGui then oldGui:Destroy() end
    
    -- Create new ScreenGui
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui
    
    -- Create container frame
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, SETTINGS.notificationWidth, 1, -20)
    container.Position = UDim2.new(1, -10, 0, 10)
    container.AnchorPoint = Vector2.new(1, 0)
    container.BackgroundTransparency = 1
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = notificationGui
    
    -- Layout for notifications
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, SETTINGS.spacing)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container
    
    NotificationModule._container = container
end

-- Core notification function
local function showNotification(title, body, duration, notifType, callback)
    if not NotificationModule._container then
        warn("Notification system not initialized! Call NotificationModule.init(player) first")
        return
    end

    local notificationType = SETTINGS.types[notifType] or SETTINGS.types.info
    duration = duration or (body and #body > 100 and SETTINGS.longDuration or SETTINGS.defaultDuration)

    -- Create notification frame
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, SETTINGS.notificationWidth, 0, SETTINGS.minHeight)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = notificationType.Color
    frame.BackgroundTransparency = 1 -- Start transparent
    frame.Position = UDim2.new(1, SETTINGS.notificationWidth, 0, 0)
    frame.ZIndex = SETTINGS.zIndex
    frame.ClipsDescendants = true

    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = SETTINGS.cornerRadius
    corner.Parent = frame

    -- Content layout
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -24, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Position = UDim2.new(0, 12, 0, 12)
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = title
    titleLabel.Font = SETTINGS.font
    titleLabel.TextSize = SETTINGS.titleSize
    titleLabel.TextColor3 = SETTINGS.textColor
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, SETTINGS.titleSize)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.AutomaticSize = Enum.AutomaticSize.Y
    titleLabel.TextWrapped = true
    titleLabel.LayoutOrder = 1

    -- Body text (if provided)
    if body and #body > 0 then
        local bodyLabel = Instance.new("TextLabel")
        bodyLabel.Name = "Body"
        bodyLabel.Text = body
        bodyLabel.Font = SETTINGS.font
        bodyLabel.TextSize = SETTINGS.bodySize
        bodyLabel.TextColor3 = SETTINGS.textColor
        bodyLabel.BackgroundTransparency = 1
        bodyLabel.Size = UDim2.new(1, 0, 0, SETTINGS.bodySize)
        bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
        bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
        bodyLabel.TextWrapped = true
        bodyLabel.LayoutOrder = 2
        bodyLabel.TextTransparency = 0.3
        bodyLabel.Parent = content
    end

    titleLabel.Parent = content
    content.Parent = frame
    frame.Parent = NotificationModule._container

    -- Animate in
    frame.Visible = true
    local fadeIn = TweenService:Create(frame, TweenInfo.new(SETTINGS.fadeTime), {
        BackgroundTransparency = 0.2
    })
    
    local slideIn = TweenService:Create(frame, TweenInfo.new(SETTINGS.slideTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 0, 0, 0)
    })

    fadeIn:Play()
    slideIn:Play()

    -- Auto-dismiss after duration
    task.delay(duration, function()
        if frame and frame.Parent then
            local fadeOut = TweenService:Create(frame, TweenInfo.new(SETTINGS.fadeTime), {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, SETTINGS.notificationWidth, 0, frame.Position.Y.Offset)
            })

            fadeOut.Completed:Connect(function()
                frame:Destroy()
                if callback then pcall(callback) end
            end)
            
            fadeOut:Play()
        end
    end)
end

-- Public API methods
function NotificationModule.info(title, body, duration, callback)
    showNotification(title, body, duration, "info", callback)
end

function NotificationModule.success(title, body, duration, callback)
    showNotification(title, body, duration, "success", callback)
end

function NotificationModule.warning(title, body, duration, callback)
    showNotification(title, body, duration, "warning", callback)
end

function NotificationModule.error(title, body, duration, callback)
    showNotification(title, body, duration or 0, "error", callback) -- Errors don't auto-dismiss by default
end

-- Auto-initialize for local player when used in a LocalScript
if game:GetService("RunService"):IsClient() then
    local player = Players.LocalPlayer
    if player then
        player:GetPropertyChangedSignal("PlayerGui"):Connect(function()
            NotificationModule.init(player)
        end)
        
        if player:FindFirstChild("PlayerGui") then
            NotificationModule.init(player)
        end
    end
end

return NotificationModule