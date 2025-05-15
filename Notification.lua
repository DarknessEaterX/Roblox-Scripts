local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Default configuration
local CONFIG = {
    Position = "TopRight", -- TopRight, BottomRight, TopLeft, BottomLeft
    Width = 300,
    MaxNotifications = 5,
    Spacing = 8,
    Padding = 12,
    Lifetime = 4,
    FadeTime = 0.25,
    SlideTime = 0.3,
    BackgroundColor = Color3.fromRGB(30, 30, 35),
    BackgroundTransparency = 0.1,
    CornerRadius = 8,
    AccentColors = {
        Info = Color3.fromRGB(65, 140, 220),
        Success = Color3.fromRGB(85, 190, 110),
        Warning = Color3.fromRGB(240, 175, 60),
        Error = Color3.fromRGB(220, 70, 70)
    },
    TextStyles = {
        Title = {
            Font = Enum.Font.GothamSemibold,
            Size = 16,
            Color = Color3.new(1, 1, 1)
        },
        Body = {
            Font = Enum.Font.Gotham,
            Size = 14,
            Color = Color3.fromRGB(200, 200, 200)
        }
    },
    Icons = {
        Info = "rbxassetid://6031094678",
        Success = "rbxassetid://6031094667",
        Warning = "rbxassetid://6031094661",
        Error = "rbxassetid://6031094634"
    },
    Sounds = {
        Default = nil,
        Info = nil,
        Success = nil,
        Warning = nil,
        Error = nil
    },
    Interactive = true,
    ProgressBar = true,
    RichText = true,
    HoverPause = true
}

-- Class constructor
function NotificationSystem.new(player)
    local self = setmetatable({}, NotificationSystem)
    
    self._player = player
    self._notifications = {}
    self._activeTweens = {}
    self._objectPool = {
        Frames = {},
        Icons = {},
        Titles = {},
        Bodies = {},
        ProgressBars = {},
        CloseButtons = {}
    }

    self:_setupGui()
    self:_connectResizeHandler()

    return self
end

-- Private methods
function NotificationSystem:_setupGui()
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "NotificationSystem"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self._screenGui.Parent = self._player.PlayerGui

    self._container = Instance.new("Frame")
    self._container.BackgroundTransparency = 1
    self._container.Size = UDim2.new(0, CONFIG.Width, 1, -CONFIG.Padding*2)
    self._container.ClipsDescendants = true
    self._container.AutomaticSize = Enum.AutomaticSize.Y
    self._container.Parent = self._screenGui

    self:_updatePosition()
end

function NotificationSystem:_updatePosition()
    local positions = {
        TopRight = {
            Anchor = Vector2.new(1, 0),
            Position = UDim2.new(1, -CONFIG.Padding, 0, CONFIG.Padding)
        },
        BottomRight = {
            Anchor = Vector2.new(1, 1),
            Position = UDim2.new(1, -CONFIG.Padding, 1, -CONFIG.Padding)
        },
        TopLeft = {
            Anchor = Vector2.new(0, 0),
            Position = UDim2.new(0, CONFIG.Padding, 0, CONFIG.Padding)
        },
        BottomLeft = {
            Anchor = Vector2.new(0, 1),
            Position = UDim2.new(0, CONFIG.Padding, 1, -CONFIG.Padding)
        }
    }

    local config = positions[CONFIG.Position] or positions.TopRight
    self._container.AnchorPoint = config.Anchor
    self._container.Position = config.Position
end

function NotificationSystem:_connectResizeHandler()
    local function updateLayout()
        self:_updatePosition()
        self:_repositionNotifications()
    end

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateLayout)
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)
end

function NotificationSystem:_getFromPool(poolName)
    return table.remove(self._objectPool[poolName]) or nil
end

function NotificationSystem:_returnToPool(obj, poolName)
    if obj then
        obj.Parent = nil
        table.insert(self._objectPool[poolName], obj)
    end
end

function NotificationSystem:_createBaseFrame()
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = CONFIG.BackgroundColor
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = true

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
    corner.Parent = frame

    return frame
end

function NotificationSystem:_animateElement(element, properties, duration, easing)
    local tween = TweenService:Create(
        element,
        TweenInfo.new(duration or CONFIG.FadeTime, easing or Enum.EasingStyle.Quad),
        properties
    )
    tween:Play()
    return tween
end

function NotificationSystem:_repositionNotifications()
    for i, notification in ipairs(self._notifications) do
        local offset = (i - 1) * (notification.AbsoluteSize.Y + CONFIG.Spacing)
        local position = CONFIG.Position:find("Bottom") 
            and UDim2.new(0, 0, 1, -offset - notification.AbsoluteSize.Y)
            or UDim2.new(0, 0, 0, offset)

        self:_animateElement(notification, {
            Position = position
        }, CONFIG.SlideTime, Enum.EasingStyle.Back)
    end
end

-- Public methods
function NotificationSystem:Notify(options)
    local notification = {
        Id = tick(),
        Config = table.clone(CONFIG)
    }

    -- Merge custom config
    if options then
        for k, v in pairs(options) do
            if type(v) == "table" then
                notification.Config[k] = table.clone(v)
            else
                notification.Config[k] = v
            end
        end
    end

    -- Create notification frame
    local frame = self:_getFromPool("Frames") or self:_createBaseFrame()
    frame.Parent = self._container
    table.insert(self._notifications, 1, frame)

    -- Add icon
    local icon = self:_getFromPool("Icons") or Instance.new("ImageLabel")
    icon.Image = notification.Config.Icons[notification.Config.Type] or notification.Config.Icons.Info
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.BackgroundTransparency = 1
    icon.Parent = frame

    -- Add text content
    local textContainer = Instance.new("Frame")
    textContainer.BackgroundTransparency = 1
    textContainer.Size = UDim2.new(1, -32, 0, 0)
    textContainer.AutomaticSize = Enum.AutomaticSize.Y
    textContainer.Position = UDim2.new(0, 32, 0, 8)
    textContainer.Parent = frame

    local title = self:_getFromPool("Titles") or Instance.new("TextLabel")
    title.Text = options.Title or "Notification"
    title.Font = notification.Config.TextStyles.Title.Font
    title.TextSize = notification.Config.TextStyles.Title.Size
    title.TextColor3 = notification.Config.TextStyles.Title.Color
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextYAlignment = Enum.TextYAlignment.Top
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.TextWrapped = true
    title.RichText = CONFIG.RichText
    title.Parent = textContainer

    local body = self:_getFromPool("Bodies") or Instance.new("TextLabel")
    body.Text = options.Body or ""
    body.Font = notification.Config.TextStyles.Body.Font
    body.TextSize = notification.Config.TextStyles.Body.Size
    body.TextColor3 = notification.Config.TextStyles.Body.Color
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextWrapped = true
    body.RichText = CONFIG.RichText
    body.Parent = textContainer

    -- Add progress bar
    if CONFIG.ProgressBar then
        local progressBar = self:_getFromPool("ProgressBars") or Instance.new("Frame")
        progressBar.Size = UDim2.new(1, 0, 0, 2)
        progressBar.Position = UDim2.new(0, 0, 1, -2)
        progressBar.BackgroundColor3 = notification.Config.AccentColors[notification.Config.Type] or CONFIG.AccentColors.Info
        progressBar.BorderSizePixel = 0
        progressBar.Parent = frame

        self:_animateElement(progressBar, {
            Size = UDim2.new(0, 0, 0, 2)
        }, notification.Config.Lifetime, Enum.EasingStyle.Linear)
    end

    -- Add close button
    if CONFIG.Interactive then
        local closeButton = self:_getFromPool("CloseButtons") or Instance.new("ImageButton")
        closeButton.Image = "rbxassetid://6031094677"
        closeButton.Size = UDim2.new(0, 16, 0, 16)
        closeButton.Position = UDim2.new(1, -20, 0, 8)
        closeButton.BackgroundTransparency = 1
        closeButton.MouseButton1Click:Connect(function()
            self:Dismiss(notification.Id)
        end)
        closeButton.Parent = frame
    end

    -- Animate in
    frame.BackgroundTransparency = 1
    self:_animateElement(frame, {
        BackgroundTransparency = CONFIG.BackgroundTransparency
    }, CONFIG.FadeTime)

    -- Auto-dismiss
    if notification.Config.Lifetime > 0 then
        task.delay(notification.Config.Lifetime, function()
            self:Dismiss(notification.Id)
        end)
    end

    -- Enforce max notifications
    while #self._notifications > CONFIG.MaxNotifications do
        self:Dismiss(self._notifications[#self._notifications])
    end

    self:_repositionNotifications()
    return notification.Id
end

function NotificationSystem:Dismiss(notificationId)
    for i, notification in ipairs(self._notifications) do
        if notification.Id == notificationId then
            self:_animateElement(notification, {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0)
            }, CONFIG.FadeTime).Completed:Connect(function()
                self:_cleanupNotification(notification)
                table.remove(self._notifications, i)
                self:_repositionNotifications()
            end)
            break
        end
    end
end

function NotificationSystem:_cleanupNotification(notification)
    -- Return elements to pool
    for _, child in ipairs(notification:GetChildren()) do
        if child:IsA("ImageLabel") then
            self:_returnToPool(child, "Icons")
        elseif child:IsA("TextLabel") then
            if child.Name == "Title" then
                self:_returnToPool(child, "Titles")
            else
                self:_returnToPool(child, "Bodies")
            end
        elseif child:IsA("ImageButton") then
            self:_returnToPool(child, "CloseButtons")
        elseif child:IsA("Frame") and child.Name == "ProgressBar" then
            self:_returnToPool(child, "ProgressBars")
        end
    end
    self:_returnToPool(notification, "Frames")
end

-- Type-specific methods
function NotificationSystem:Info(title, body, options)
    return self:Notify(table.join(options or {}, {
        Type = "Info",
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Info,
        Icon = CONFIG.Icons.Info,
        Sound = CONFIG.Sounds.Info
    }))
end

function NotificationSystem:Success(title, body, options)
    return self:Notify(table.join(options or {}, {
        Type = "Success",
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Success,
        Icon = CONFIG.Icons.Success,
        Sound = CONFIG.Sounds.Success
    }))
end

function NotificationSystem:Warning(title, body, options)
    return self:Notify(table.join(options or {}, {
        Type = "Warning",
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Warning,
        Icon = CONFIG.Icons.Warning,
        Sound = CONFIG.Sounds.Warning,
        Lifetime = options and options.Lifetime or 6
    }))
end

function NotificationSystem:Error(title, body, options)
    return self:Notify(table.join(options or {}, {
        Type = "Error",
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Error,
        Icon = CONFIG.Icons.Error,
        Sound = CONFIG.Sounds.Error,
        Lifetime = 0 -- Persistent by default
    }))
end

-- Auto-initialize for local player
local player = Players.LocalPlayer
local notificationService = NotificationSystem.new(player)

return notificationService