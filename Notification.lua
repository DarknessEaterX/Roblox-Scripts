local NotificationModule = {}

-- Settings table for easy theme adjustments and future extensibility
local SETTINGS = {
    colors = {
        info = Color3.fromRGB(30, 30, 30),
        success = Color3.fromRGB(34, 139, 34),
        warning = Color3.fromRGB(255, 165, 0),
        error = Color3.fromRGB(220, 20, 60),
    },
    textColor = Color3.new(1, 1, 1),
    font = Enum.Font.GothamSemibold,
    textSize = 14,
    cornerRadius = UDim.new(0, 6),
    defaultDuration = 3,
    paragraphDuration = 5,
    notificationSpacing = 6,
    notificationWidth = 320,
    notificationHeight = 36,
    paragraphMinHeight = 36,
    paragraphMaxWidth = 380,
    zIndex = 10,
}

-- Helper: Create styled notification label
local function createNotificationLabel(options)
    local notif = Instance.new("TextLabel")
    notif.Name = options.name or "Notification"
    notif.Size = options.size or UDim2.new(1, 0, 0, SETTINGS.notificationHeight)
    notif.Position = options.position or UDim2.new(0, 0, 0, 0)
    notif.BackgroundColor3 = options.backgroundColor or SETTINGS.colors.info
    notif.BackgroundTransparency = 0.25
    notif.TextColor3 = options.textColor or SETTINGS.textColor
    notif.Font = SETTINGS.font
    notif.TextSize = SETTINGS.textSize
    notif.TextXAlignment = options.textXAlignment or Enum.TextXAlignment.Left
    notif.TextYAlignment = options.textYAlignment or Enum.TextYAlignment.Center
    notif.TextWrapped = options.textWrapped or false
    notif.Text = options.text or ""
    notif.ZIndex = SETTINGS.zIndex
    notif.AutomaticSize = options.automaticSize or Enum.AutomaticSize.None
    notif.ClipsDescendants = true
    notif.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
    notif.LayoutOrder = options.layoutOrder or 0

    -- Padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = notif

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = SETTINGS.cornerRadius
    corner.Parent = notif

    return notif
end

-- Internal: Reorder notifications using UIListLayout
local function ensureLayout(container)
    if not container:FindFirstChild("NotificationLayout") then
        local layout = Instance.new("UIListLayout")
        layout.Name = "NotificationLayout"
        layout.Padding = UDim.new(0, SETTINGS.notificationSpacing)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Parent = container
    end
end

-- Internal: Remove old notifications if limit exceeded (optional feature)
local function enforceLimit(container, limit)
    local children = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextLabel") then
            table.insert(children, child)
        end
    end
    if #children > limit then
        table.sort(children, function(a, b)
            return (a:GetAttribute("TimeStamp") or 0) < (b:GetAttribute("TimeStamp") or 0)
        end)
        for i = 1, #children - limit do
            children[i]:Destroy()
        end
    end
end

-- Public: Setup notification system
function NotificationModule.init(playerGui, options)
    options = options or {}

    local oldGui = playerGui:FindFirstChild("NotificationGui")
    if oldGui then oldGui:Destroy() end

    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.IgnoreGuiInset = true
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui

    -- Main notification container
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, SETTINGS.notificationWidth, 1, -20)
    container.Position = UDim2.new(1, -SETTINGS.notificationWidth - 10, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = notificationGui

    ensureLayout(container)

    -- Internal reference for module functions
    NotificationModule._container = container
    NotificationModule._maxNotifications = options.maxNotifications or 5
end

-- Public: Show a single-line notification
function NotificationModule.showNotification(message, duration, notifType)
    assert(NotificationModule._container, "NotificationModule is not initialized! Call init(playerGui) first.")

    duration = duration or SETTINGS.defaultDuration
    notifType = notifType or "info"

    local notif = createNotificationLabel{
        name = "Notification",
        text = message,
        backgroundColor = SETTINGS.colors[notifType] or SETTINGS.colors.info,
        size = UDim2.new(1, 0, 0, SETTINGS.notificationHeight),
        textXAlignment = Enum.TextXAlignment.Left,
        textYAlignment = Enum.TextYAlignment.Center,
    }
    notif.Parent = NotificationModule._container
    notif:SetAttribute("TimeStamp", tick())
    notif.LayoutOrder = -tick() -- Newest at top

    enforceLimit(NotificationModule._container, NotificationModule._maxNotifications)

    -- Animate in
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif:TweenSize(UDim2.new(1, 0, 0, SETTINGS.notificationHeight), "Out", "Quad", 0.3, true)

    -- Auto-destroy after duration
    task.delay(duration, function()
        if notif and notif.Parent then
            notif:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.25, true)
            task.wait(0.25)
            notif:Destroy()
        end
    end)
end

-- Public: Show a multi-line (paragraph) notification
function NotificationModule.paragraphNotification(message, duration, notifType)
    assert(NotificationModule._container, "NotificationModule is not initialized! Call init(playerGui) first.")

    duration = duration or SETTINGS.paragraphDuration
    notifType = notifType or "info"

    local notif = createNotificationLabel{
        name = "ParagraphNotification",
        text = message,
        backgroundColor = SETTINGS.colors[notifType] or SETTINGS.colors.info,
        size = UDim2.new(1, 0, 0, 0), -- Auto Y
        textXAlignment = Enum.TextXAlignment.Left,
        textYAlignment = Enum.TextYAlignment.Top,
        textWrapped = true,
        automaticSize = Enum.AutomaticSize.Y,
    }
    notif.Parent = NotificationModule._container
    notif:SetAttribute("TimeStamp", tick())
    notif.LayoutOrder = -tick() -- Newest at top

    enforceLimit(NotificationModule._container, NotificationModule._maxNotifications)

    -- Animate in
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif:TweenSize(UDim2.new(1, 0, 0, notif.TextBounds.Y + 20), "Out", "Quad", 0.3, true)

    -- Auto-destroy after duration
    task.delay(duration, function()
        if notif and notif.Parent then
            notif:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.25, true)
            task.wait(0.25)
            notif:Destroy()
        end
    end)
end

return NotificationModule