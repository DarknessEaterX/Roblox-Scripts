-- Notification.lua v3.0
local NotificationModule = {}

local SETTINGS = {
    types = {
        info = { Color = Color3.fromRGB(30, 30, 30) },
        success = { Color = Color3.fromRGB(34, 139, 34) },
        warning = { Color = Color3.fromRGB(255, 165, 0) },
        error = { Color = Color3.fromRGB(220, 20, 60) },
    },
    textColor = Color3.new(1, 1, 1),
    font = Enum.Font.GothamSemibold,
    textSize = 14,
    cornerRadius = UDim.new(0, 6),
    notificationWidth = 320,
    notificationHeight = 36,
    notificationSpacing = 8,
    maxNotifications = 6,
    defaultDuration = 3,
    paragraphDuration = 5,
    zIndex = 10,
}

local cachedObjects = {}

-- Utility: UIListLayout caching for performance and ordering
local function ensureLayout(container)
    if not container:FindFirstChild("NotificationLayout") then
        local layout = Instance.new("UIListLayout")
        layout.Name = "NotificationLayout"
        layout.Padding = UDim.new(0, SETTINGS.notificationSpacing)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
    end
end

-- Utility: Defensive destroy
local function safeDestroy(obj)
    if obj and obj.Parent then
        obj:Destroy()
    end
end

-- Utility: Enforce max notification count
local function enforceLimit(container)
    local notifs = {}
    for _, c in ipairs(container:GetChildren()) do
        if c:IsA("Frame") and c.Name == "NotificationFrame" then
            table.insert(notifs, c)
        end
    end
    table.sort(notifs, function(a, b)
        return (a:GetAttribute("TimeStamp") or 0) < (b:GetAttribute("TimeStamp") or 0)
    end)
    while #notifs > SETTINGS.maxNotifications do
        safeDestroy(table.remove(notifs, 1))
    end
end

-- Core notification frame creator, cached for performance
local function getNotificationFrame()
    if cachedObjects.Frame then
        return cachedObjects.Frame:Clone()
    end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(1, 0, 0, SETTINGS.notificationHeight)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = SETTINGS.zIndex

    local corner = Instance.new("UICorner")
    corner.CornerRadius = SETTINGS.cornerRadius
    corner.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = frame

    local label = Instance.new("TextLabel")
    label.Name = "NotificationText"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = SETTINGS.textColor
    label.Font = SETTINGS.font
    label.TextSize = SETTINGS.textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.ClipsDescendants = true
    label.ZIndex = SETTINGS.zIndex + 1
    label.Parent = frame

    cachedObjects.Frame = frame
    return frame:Clone()
end

-- UI initialization
function NotificationModule.init(playerGui, opts)
    opts = opts or {}
    SETTINGS.maxNotifications = opts.maxNotifications or SETTINGS.maxNotifications

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
    container.Size = UDim2.new(0, SETTINGS.notificationWidth, 1, -20)
    container.Position = UDim2.new(1, -SETTINGS.notificationWidth - 10, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Parent = notificationGui

    ensureLayout(container)
    NotificationModule._container = container
end

-- Internal: Show a notification (single or paragraph)
local function showNotification(message, duration, notifType, isParagraph, callback)
    assert(NotificationModule._container, "NotificationModule is not initialized! Call init(playerGui) first.")

    local nType = SETTINGS.types[notifType] and notifType or "info"
    duration = duration or (isParagraph and SETTINGS.paragraphDuration or SETTINGS.defaultDuration)

    local notif = getNotificationFrame()
    local textLabel = notif:FindFirstChild("NotificationText")
    notif.BackgroundColor3 = SETTINGS.types[nType].Color
    notif.LayoutOrder = -tick()
    notif.Size = UDim2.new(1, 0, 0, isParagraph and notif.TextBounds and (textLabel.TextBounds.Y + 16) or SETTINGS.notificationHeight)
    notif.Parent = NotificationModule._container

    textLabel.Text = tostring(message)
    textLabel.TextYAlignment = isParagraph and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    notif:SetAttribute("TimeStamp", tick())

    enforceLimit(NotificationModule._container)

    -- Animate In
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif:TweenSize(isParagraph and UDim2.new(1, 0, 0, textLabel.TextBounds.Y + 16) or UDim2.new(1, 0, 0, SETTINGS.notificationHeight), "Out", "Quad", 0.23, true)

    -- Auto-destroy after duration
    task.spawn(function()
        task.wait(duration)
        if notif and notif.Parent then
            notif:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.18, true)
            task.wait(0.18)
            safeDestroy(notif)
            if typeof(callback) == "function" then
                pcall(callback)
            end
        end
    end)
end

-- Public API: single-line notification
function NotificationModule.showNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, false, callback)
end

-- Public API: paragraph (multi-line) notification
function NotificationModule.paragraphNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, true, callback)
end

return NotificationModule