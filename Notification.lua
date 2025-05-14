-- Notification.lua v3.2 - Complete In-One Script
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
    slideOffset = 32,
}

local cachedObjects = {}

-- Layout helper
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

-- Safe destroy
local function safeDestroy(obj)
    if obj and obj.Parent then pcall(function() obj:Destroy() end) end
end

-- Limit notifications
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

-- Frame template (supports paragraph mode)
local function getNotificationFrame(isParagraph)
    local cacheKey = isParagraph and "ParagraphFrame" or "Frame"
    if cachedObjects[cacheKey] then
        return cachedObjects[cacheKey]:Clone()
    end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(1, 0, 0, SETTINGS.notificationHeight)
    frame.BackgroundTransparency = 1 -- Start fully transparent for fade
    frame.BorderSizePixel = 0
    frame.ZIndex = SETTINGS.zIndex
    frame.ClipsDescendants = true
    if isParagraph then
        frame.AutomaticSize = Enum.AutomaticSize.Y
    end

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
    label.BackgroundTransparency = 1
    label.TextColor3 = SETTINGS.textColor
    label.Font = SETTINGS.font
    label.TextSize = SETTINGS.textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ClipsDescendants = true
    label.ZIndex = SETTINGS.zIndex + 1
    if isParagraph then
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.Size = UDim2.new(1, 0, 0, 0)
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Top
    else
        label.Size = UDim2.new(1, 0, 1, 0)
        label.TextWrapped = false
        label.TextYAlignment = Enum.TextYAlignment.Center
    end
    label.Parent = frame

    cachedObjects[cacheKey] = frame
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

-- Slide and fade in
local function betterTransition(notif, startX, endX)
    notif.Position = UDim2.new(0, startX, 0, 0)
    notif.BackgroundTransparency = 1
    notif.Visible = true
    notif:TweenPosition(UDim2.new(0, endX, 0, 0), "Out", "Quad", 0.22, true)
    for i = 1, 10 do
        notif.BackgroundTransparency = 1 - (i * 0.08)
        task.wait(0.013)
    end
    notif.BackgroundTransparency = 0.2
end

local function slideOutAndDestroy(notif, callback)
    local currentPos = notif.Position
    local outPos = UDim2.new(0, SETTINGS.slideOffset, 0, currentPos.Y.Offset)
    notif:TweenPosition(outPos, "In", "Quad", 0.16, true)
    for i = 1, 10 do
        notif.BackgroundTransparency = 0.2 + (i * 0.08)
        task.wait(0.012)
    end
    notif.BackgroundTransparency = 1
    safeDestroy(notif)
    if typeof(callback) == "function" then
        pcall(callback)
    end
end

-- Core notification (single or paragraph)
local function showNotification(message, duration, notifType, isParagraph, callback)
    assert(NotificationModule._container, "NotificationModule is not initialized! Call init(playerGui) first.")

    local nType = SETTINGS.types[notifType] and notifType or "info"
    duration = duration or (isParagraph and SETTINGS.paragraphDuration or SETTINGS.defaultDuration)

    local notif = getNotificationFrame(isParagraph)
    notif.BackgroundColor3 = SETTINGS.types[nType].Color
    notif.LayoutOrder = -tick()
    notif.Position = UDim2.new(0, SETTINGS.slideOffset, 0, 0)
    notif.Visible = false

    local textLabel = notif:FindFirstChild("NotificationText")
    textLabel.Text = tostring(message)

    notif.Parent = NotificationModule._container
    notif:SetAttribute("TimeStamp", tick())

    enforceLimit(NotificationModule._container)

    -- Animate In: Slide + Fade
    task.spawn(function()
        betterTransition(notif, SETTINGS.slideOffset, 0)
    end)

    -- Auto-destroy after duration
    task.spawn(function()
        task.wait(duration)
        if notif and notif.Parent then
            slideOutAndDestroy(notif, callback)
        end
    end)
end

-- Single-line notification
function NotificationModule.showNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, false, callback)
end

-- Paragraph (multi-line, auto-resizing!) notification
function NotificationModule.paragraphNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, true, callback)
end

return NotificationModule