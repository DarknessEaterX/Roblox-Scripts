local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Default configuration
local CONFIG = {
    Position = "TopRight",
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
    Icons = {
        Info = "rbxassetid://6031094678",
        Success = "rbxassetid://6031094667",
        Warning = "rbxassetid://6031094661",
        Error = "rbxassetid://6031094634"
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
    Interactive = true,
    ProgressBar = true,
    RichText = true,
    HoverPause = true
}

-- Helper function to merge tables
local function mergeTables(t1, t2)
    local result = table.clone(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

-- Class constructor
function NotificationSystem.new(player)
    local self = setmetatable({}, NotificationSystem)
    self._player = player
    self._notifications = {}
    self:_setupGui()
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
        }
    }
    local config = positions[CONFIG.Position] or positions.TopRight
    self._container.AnchorPoint = config.Anchor
    self._container.Position = config.Position
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
        local position = UDim2.new(0, 0, 0, offset)
        self:_animateElement(notification, {Position = position}, CONFIG.SlideTime)
    end
end

-- Public methods
function NotificationSystem:Notify(options)
    local notification = Instance.new("Frame")
    notification.BackgroundColor3 = CONFIG.BackgroundColor
    notification.BackgroundTransparency = 1
    notification.Size = UDim2.new(1, 0, 0, 0)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.ClipsDescendants = true

    -- Add styling
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = notification

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
    corner.Parent = notification

    -- Add content
    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -16, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Position = UDim2.new(0, 8, 0, 8)
    content.Parent = notification

    local title = Instance.new("TextLabel")
    title.Text = options.Title
    title.Font = CONFIG.TextStyles.Title.Font
    title.TextSize = CONFIG.TextStyles.Title.Size
    title.TextColor3 = CONFIG.TextStyles.Title.Color
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.AutomaticSize = Enum.AutomaticSize.Y
    title.TextWrapped = true
    title.RichText = CONFIG.RichText
    title.Parent = content

    if options.Body then
        local body = Instance.new("TextLabel")
        body.Text = options.Body
        body.Font = CONFIG.TextStyles.Body.Font
        body.TextSize = CONFIG.TextStyles.Body.Size
        body.TextColor3 = CONFIG.TextStyles.Body.Color
        body.BackgroundTransparency = 1
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.TextWrapped = true
        body.RichText = CONFIG.RichText
        body.Position = UDim2.new(0, 0, 0, title.AbsoluteSize.Y + 4)
        body.Parent = content
    end

    notification.Parent = self._container
    table.insert(self._notifications, 1, notification)

    -- Animate in
    self:_animateElement(notification, {
        BackgroundTransparency = CONFIG.BackgroundTransparency
    }, CONFIG.FadeTime)

    -- Auto-dismiss
    if options.Lifetime and options.Lifetime > 0 then
        task.delay(options.Lifetime, function()
            self:Dismiss(notification)
        end)
    end

    -- Enforce max notifications
    while #self._notifications > CONFIG.MaxNotifications do
        self:Dismiss(self._notifications[#self._notifications])
    end

    self:_repositionNotifications()
    return notification
end

function NotificationSystem:Dismiss(notification)
    self:_animateElement(notification, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0)
    }, CONFIG.FadeTime).Completed:Connect(function()
        for i, n in ipairs(self._notifications) do
            if n == notification then
                table.remove(self._notifications, i)
                notification:Destroy()
                break
            end
        end
        self:_repositionNotifications()
    end)
end

-- Type-specific methods
function NotificationSystem:Info(title, body, options)
    return self:Notify(mergeTables(options or {}, {
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Info,
        Lifetime = CONFIG.Lifetime
    }))
end

function NotificationSystem:Success(title, body, options)
    return self:Notify(mergeTables(options or {}, {
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Success,
        Lifetime = CONFIG.Lifetime
    }))
end

function NotificationSystem:Warning(title, body, options)
    return self:Notify(mergeTables(options or {}, {
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Warning,
        Lifetime = options and options.Lifetime or CONFIG.Lifetime + 2
    }))
end

function NotificationSystem:Error(title, body, options)
    return self:Notify(mergeTables(options or {}, {
        Title = title,
        Body = body,
        AccentColor = CONFIG.AccentColors.Error,
        Lifetime = 0 -- Persistent by default
    }))
end

-- Auto-initialize for local player
local service = NotificationSystem.new(Players.LocalPlayer)
return service