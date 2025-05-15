-- Notification.lua v4.0 - Enhanced Notification System
local NotificationModule = {}

-- Configuration with better defaults
local SETTINGS = {
    types = {
        info = { Color = Color3.fromRGB(47, 49, 54), Icon = "rbxassetid://6031094678" },
        success = { Color = Color3.fromRGB(87, 242, 135), Icon = "rbxassetid://6031094667" },
        warning = { Color = Color3.fromRGB(254, 231, 92), Icon = "rbxassetid://6031094661" },
        error = { Color = Color3.fromRGB(237, 66, 69), Icon = "rbxassetid://6031094634" },
        custom = { Color = Color3.fromRGB(114, 137, 218), Icon = nil }
    },
    textColor = Color3.fromRGB(255, 255, 255),
    font = Enum.Font.GothamMedium,
    titleSize = 16,
    bodySize = 14,
    cornerRadius = UDim.new(0, 8),
    notificationWidth = 300,
    minHeight = 50,
    maxWidth = 0.3, -- Percentage of screen width
    spacing = 8,
    maxNotifications = 5,
    defaultDuration = 4,
    longDuration = 6,
    zIndex = 100,
    slideOffset = 50,
    fadeTime = 0.2,
    slideTime = 0.25,
    hoverPause = true,
    closeButton = true,
    richText = true,
    responsive = true
}

-- Object pooling for better performance
local objectPool = {
    frames = {},
    icons = {},
    titles = {},
    bodies = {},
    closeButtons = {}
}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Utility functions
local function safeDestroy(obj)
    if obj and obj.Parent then
        pcall(function()
            obj:Destroy()
        end)
    end
end

local function getFromPool(pool)
    for i, obj in ipairs(pool) do
        if not obj.Parent then
            table.remove(pool, i)
            return obj
        end
    end
    return nil
end

local function returnToPool(obj, pool)
    if obj then
        obj.Parent = nil
        table.insert(pool, obj)
    end
end

-- Dynamic sizing based on screen size
local function calculateDimensions()
    if SETTINGS.responsive then
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local maxWidth = math.floor(viewportSize.X * SETTINGS.maxWidth)
        return math.min(SETTINGS.notificationWidth, maxWidth)
    end
    return SETTINGS.notificationWidth
end

-- Notification frame template
local function createNotificationFrame()
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(0, calculateDimensions(), 0, SETTINGS.minHeight)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BorderSizePixel = 0
    frame.ZIndex = SETTINGS.zIndex
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = SETTINGS.cornerRadius
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = frame

    return frame
end

-- Notification content template
local function createContentFrame()
    local content = Instance.new("Frame")
    content.Name = "ContentFrame"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.LayoutOrder = 1

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = content

    return content
end

-- Notification icon template
local function createIcon()
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.LayoutOrder = 1
    return icon
end

-- Notification text container
local function createTextContainer()
    local container = Instance.new("Frame")
    container.Name = "TextContainer"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, -32, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.LayoutOrder = 2

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    return container
end

-- Notification title template
local function createTitle()
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Font = SETTINGS.font
    title.TextSize = SETTINGS.titleSize
    title.TextColor3 = SETTINGS.textColor
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, SETTINGS.titleSize)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.TextWrapped = true
    title.RichText = SETTINGS.richText
    title.LayoutOrder = 1
    return title
end

-- Notification body template
local function createBody()
    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Font = SETTINGS.font
    body.TextSize = SETTINGS.bodySize
    body.TextColor3 = SETTINGS.textColor
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 0, SETTINGS.bodySize)
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.RichText = SETTINGS.richText
    body.TextTransparency = 0.3
    body.LayoutOrder = 2
    return body
end

-- Close button template
local function createCloseButton()
    local button = Instance.new("ImageButton")
    button.Name = "CloseButton"
    button.Image = "rbxassetid://6031094677"
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(0, 16, 0, 16)
    button.Position = UDim2.new(1, -16, 0, 8)
    button.ZIndex = SETTINGS.zIndex + 1
    return button
end

-- Animation functions
local function animateIn(notification)
    notification.Position = UDim2.new(1, SETTINGS.slideOffset, 0, 0)
    notification.BackgroundTransparency = 1
    notification.Visible = true

    local fadeIn = TweenService:Create(notification, TweenInfo.new(SETTINGS.fadeTime), {
        BackgroundTransparency = 0.2
    })
    
    local slideIn = TweenService:Create(notification, TweenInfo.new(SETTINGS.slideTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 0, 0, 0)
    })

    fadeIn:Play()
    slideIn:Play()
end

local function animateOut(notification, callback)
    local fadeOut = TweenService:Create(notification, TweenInfo.new(SETTINGS.fadeTime), {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, SETTINGS.slideOffset, 0, notification.Position.Y.Offset)
    })

    fadeOut.Completed:Connect(function()
        safeDestroy(notification)
        if callback then pcall(callback) end
    end)
    
    fadeOut:Play()
end

-- Notification management
local function enforceNotificationLimit(container)
    local notifications = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Frame") and child.Name == "NotificationFrame" then
            table.insert(notifications, child)
        end
    end

    table.sort(notifications, function(a, b)
        return (a:GetAttribute("CreationTime") or 0) < (b:GetAttribute("CreationTime") or 0)
    end)

    while #notifications > SETTINGS.maxNotifications do
        animateOut(table.remove(notifications, 1))
    end
end

-- Core notification function
local function showNotification(options)
    assert(NotificationModule._container, "NotificationModule not initialized. Call init() first.")
    
    -- Merge options with defaults
    local config = {
        title = options.title or "Notification",
        body = options.body or "",
        duration = options.duration or (options.body and #options.body > 100 and SETTINGS.longDuration or SETTINGS.defaultDuration),
        notificationType = options.notificationType or "info",
        callback = options.callback,
        icon = options.icon,
        color = options.color
    }

    -- Get or create notification elements from pool
    local notification = getFromPool(objectPool.frames) or createNotificationFrame()
    local content = getFromPool(objectPool.contentFrames) or createContentFrame()
    local icon = getFromPool(objectPool.icons) or createIcon()
    local textContainer = getFromPool(objectPool.textContainers) or createTextContainer()
    local title = getFromPool(objectPool.titles) or createTitle()
    local body = getFromPool(objectPool.bodies) or createBody()
    local closeButton = SETTINGS.closeButton and (getFromPool(objectPool.closeButtons) or createCloseButton())

    -- Configure notification type
    local notificationStyle = SETTINGS.types[config.notificationType] or SETTINGS.types.info
    notification.BackgroundColor3 = config.color or notificationStyle.Color
    
    -- Configure icon
    icon.Image = config.icon or notificationStyle.Icon
    if not icon.Image then
        icon.Visible = false
    else
        icon.Visible = true
    end

    -- Configure text
    title.Text = config.title
    body.Text = config.body
    body.Visible = #config.body > 0

    -- Assemble notification
    textContainer.Parent = content
    title.Parent = textContainer
    body.Parent = textContainer
    
    icon.Parent = content
    content.Parent = notification
    
    if closeButton then
        closeButton.Parent = notification
        closeButton.MouseButton1Click:Connect(function()
            animateOut(notification, config.callback)
        end)
    end

    notification.Parent = NotificationModule._container
    notification:SetAttribute("CreationTime", tick())

    -- Handle hover pause
    if SETTINGS.hoverPause then
        local hoverTime = 0
        local originalDuration = config.duration
        
        notification.MouseEnter:Connect(function()
            hoverTime = tick()
        end)
        
        notification.MouseLeave:Connect(function()
            if hoverTime > 0 then
                config.duration = originalDuration - (tick() - hoverTime)
                hoverTime = 0
            end
        end)
    end

    -- Animate in
    animateIn(notification)
    enforceNotificationLimit(NotificationModule._container)

    -- Auto-dismiss after duration
    task.delay(config.duration, function()
        if notification and notification.Parent then
            animateOut(notification, config.callback)
        end
    end)
end

-- Public API
function NotificationModule.init(playerGui, customSettings)
    -- Apply custom settings
    if customSettings then
        for key, value in pairs(customSettings) do
            if SETTINGS[key] ~= nil then
                SETTINGS[key] = value
            elseif key == "types" then
                for typeName, typeSettings in pairs(value) do
                    if SETTINGS.types[typeName] then
                        for setting, val in pairs(typeSettings) do
                            SETTINGS.types[typeName][setting] = val
                        end
                    end
                end
            end
        end
    end

    -- Clean up existing GUI
    local oldGui = playerGui:FindFirstChild("NotificationGui")
    if oldGui then oldGui:Destroy() end

    -- Create new GUI
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.IgnoreGuiInset = true
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, calculateDimensions(), 1, -20)
    container.Position = UDim2.new(1, -10, 0, 10)
    container.AnchorPoint = Vector2.new(1, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = notificationGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, SETTINGS.spacing)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    NotificationModule._container = container
end

function NotificationModule.notify(options)
    if typeof(options) == "string" then
        options = { title = options }
    end
    showNotification(options)
end

-- Convenience methods
function NotificationModule.info(title, body, duration, callback)
    showNotification({
        title = title,
        body = body,
        duration = duration,
        notificationType = "info",
        callback = callback
    })
end

function NotificationModule.success(title, body, duration, callback)
    showNotification({
        title = title,
        body = body,
        duration = duration,
        notificationType = "success",
        callback = callback
    })
end

function NotificationModule.warning(title, body, duration, callback)
    showNotification({
        title = title,
        body = body,
        duration = duration,
        notificationType = "warning",
        callback = callback
    })
end

function NotificationModule.error(title, body, duration, callback)
    showNotification({
        title = title,
        body = body,
        duration = duration,
        notificationType = "error",
        callback = callback
    })
end

-- Auto-initialize for local player
if RunService:IsClient() then
    local player = Players.LocalPlayer
    if player then
        player:GetPropertyChangedSignal("PlayerGui"):Connect(function()
            if player.PlayerGui then
                NotificationModule.init(player.PlayerGui)
            end
        end)
        
        if player.PlayerGui then
            NotificationModule.init(player.PlayerGui)
        end
    end
end

return NotificationModule