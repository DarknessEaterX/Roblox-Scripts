-- Notification.lua v3.1 (with better transitions)
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
    slideOffset = 32, -- How far it slides in/out horizontally
}

local cachedObjects = {}

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

local function safeDestroy(obj)
    if obj and obj.Parent then
        obj:Destroy()
    end
end

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

local function getNotificationFrame()
    if cachedObjects.Frame then
        return cachedObjects.Frame:Clone()
    end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(1, 0, 0, SETTINGS.notificationHeight)
    frame.BackgroundTransparency = 1 -- Initially fully transparent for fade-in
    frame.BorderSizePixel = 0
    frame.ZIndex = SETTINGS.zIndex
    frame.ClipsDescendants = true

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

local function betterTransition(notif, startX, endX, fadeIn, fadeOut)
    -- Slide in with fade
    notif.Position = UDim2.new(0, startX, 0, 0)
    notif.BackgroundTransparency = 1
    notif.Visible = true
    notif:TweenPosition(UDim2.new(0, endX, 0, 0), "Out", "Quad", 0.22, true)
    -- Fade in
    for i = 1, 10 do
        notif.BackgroundTransparency = 1 - (i * 0.08)
        task.wait(0.015)
    end
    notif.BackgroundTransparency = 0.2

    if fadeIn then fadeIn() end
    -- Will slide/fade out on removal with fadeOut()
end

local function slideOutAndDestroy(notif, callback)
    -- Slide to the right and fade out
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

local function showNotification(message, duration, notifType, isParagraph, callback)
    assert(NotificationModule._container, "NotificationModule is not initialized! Call init(playerGui) first.")

    local nType = SETTINGS.types[notifType] and notifType or "info"
    duration = duration or (isParagraph and SETTINGS.paragraphDuration or SETTINGS.defaultDuration)

    local notif = getNotificationFrame()
    local textLabel = notif:FindFirstChild("NotificationText")
    notif.BackgroundColor3 = SETTINGS.types[nType].Color
    notif.LayoutOrder = -tick()
    notif.Position = UDim2.new(0, SETTINGS.slideOffset, 0, 0) -- Start off to the right
    notif.Visible = false

    if isParagraph then
        textLabel.TextYAlignment = Enum.TextYAlignment.Top
        textLabel.TextWrapped = true
        textLabel.Text = tostring(message)
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        notif.Size = UDim2.new(1, 0, 0, math.max(SETTINGS.notificationHeight, textLabel.TextBounds.Y + 16))
    else
        textLabel.TextYAlignment = Enum.TextYAlignment.Center
        textLabel.TextWrapped = false
        textLabel.Text = tostring(message)
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        notif.Size = UDim2.new(1, 0, 0, SETTINGS.notificationHeight)
    end

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

function NotificationModule.showNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, false, callback)
end

function NotificationModule.paragraphNotification(message, duration, notifType, callback)
    showNotification(message, duration, notifType, true, callback)
end

return NotificationModule