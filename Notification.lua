local NotificationModule = {}

local DEFAULTS = {
    duration = 3,
    backgroundColors = {
        info = Color3.fromRGB(30, 30, 30),
        success = Color3.fromRGB(34, 139, 34),
        warning = Color3.fromRGB(255, 165, 0),
        error = Color3.fromRGB(220, 20, 60)
    },
    textColor = Color3.new(1, 1, 1),
    font = Enum.Font.GothamSemibold,
    textSize = 14,
    cornerRadius = UDim.new(0, 6),
    maxNotifications = 5
}

local guiRefs = {}

-- Internal notification creation function
local function createNotification(container, message, options)
    options = options or {}
    local notifType = options.type or "info"
    local duration = options.duration or DEFAULTS.duration
    local icon = options.icon

    -- Limit number of notifications
    local currentNotifs = #container:GetChildren()
    if currentNotifs >= (options.maxNotifications or DEFAULTS.maxNotifications) then
        local oldest = container:GetChildren()[1]
        if oldest then oldest:Destroy() end
    end

    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Size = UDim2.new(1, 0, 0, 36)
    notif.BackgroundColor3 = DEFAULTS.backgroundColors[notifType] or DEFAULTS.backgroundColors.info
    notif.BackgroundTransparency = 0.25
    notif.ClipsDescendants = true

    -- Add icon if provided
    if icon then
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Name = "Icon"
        iconLabel.Image = icon
        iconLabel.Size = UDim2.new(0, 20, 0, 20)
        iconLabel.Position = UDim2.new(0, 8, 0, 8)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Parent = notif
    end

    local text = Instance.new("TextLabel")
    text.Name = "NotificationText"
    text.Size = UDim2.new(1, icon and -40 or -20, 1, 0)
    text.Position = UDim2.new(0, icon and 36 or 10, 0, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = options.textColor or DEFAULTS.textColor
    text.Font = options.font or DEFAULTS.font
    text.TextSize = options.textSize or DEFAULTS.textSize
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = message
    text.Parent = notif

    local corner = Instance.new("UICorner")
    corner.CornerRadius = options.cornerRadius or DEFAULTS.cornerRadius
    corner.Parent = notif

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = notif

    notif.Parent = container
    notif:SetAttribute("TimeStamp", tick())

    -- Tween in
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif:TweenSize(UDim2.new(1, 0, 0, 36), "Out", "Quad", 0.25, true)

    -- Remove after duration
    task.delay(duration, function()
        if notif and notif.Parent then
            notif:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.25, true)
            task.wait(0.25)
            notif:Destroy()
            if options.onDismiss then options.onDismiss() end
        end
    end)
end

-- Initialize notification system
function NotificationModule.init(playerGui)
    -- Remove old GUI if exists
    local oldGui = playerGui:FindFirstChild("NotificationGui")
    if oldGui then oldGui:Destroy() end

    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.IgnoreGuiInset = true
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 320, 1, -20)
    container.Position = UDim2.new(1, -330, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = notificationGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    guiRefs[playerGui] = container

    -- Expose show function for this GUI
    function NotificationModule.show(message, options)
        createNotification(container, message, options)
    end
end

return NotificationModule