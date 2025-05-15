local NotificationSystem = {}
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration with better defaults
local CONFIG = {
    Width = 300,
    Height = 60,
    Padding = 12,
    Spacing = 8,
    Lifetime = 4,
    FadeTime = 0.3,
    BackgroundColor = Color3.fromRGB(30, 30, 35),
    BackgroundTransparency = 0.2,
    TextColor = Color3.new(1, 1, 1),
    TextStrokeColor = Color3.new(0, 0, 0),
    TextStrokeTransparency = 0.7,
    Font = Enum.Font.GothamMedium,
    TextSize = 16,
    CornerRadius = 8,
    MaxNotifications = 5,
    SoundId = nil,
    SoundVolume = 0.5
}

-- System variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationSystem"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local notifications = {}
local activeTweens = {}

-- Helper functions
local function cancelTween(tween)
    if tween then
        tween:Cancel()
    end
end

local function cleanupNotification(notification)
    -- Remove from active notifications
    for i, notif in ipairs(notifications) do
        if notif == notification then
            table.remove(notifications, i)
            break
        end
    end
    
    -- Cancel any active tweens
    if activeTweens[notification] then
        cancelTween(activeTweens[notification])
        activeTweens[notification] = nil
    end
    
    -- Destroy the notification
    if notification and notification.Parent then
        notification:Destroy()
    end
end

local function repositionNotifications()
    for i, notification in ipairs(notifications) do
        cancelTween(activeTweens[notification])
        
        local targetPosition = UDim2.new(
            1, -CONFIG.Padding,
            0, CONFIG.Padding + (i - 1) * (CONFIG.Height + CONFIG.Spacing)
        )
        
        local tween = TweenService:Create(
            notification,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = targetPosition}
        )
        
        tween:Play()
        activeTweens[notification] = tween
    end
end

local function createNotificationFrame(text)
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
    frame.BackgroundColor3 = CONFIG.BackgroundColor
    frame.BackgroundTransparency = 1 -- Start transparent
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(1, 0) -- Top-right anchor
    frame.Position = UDim2.new(1, CONFIG.Width, 0, CONFIG.Padding) -- Start off-screen
    frame.ZIndex = 10
    frame.ClipsDescendants = true

    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, CONFIG.CornerRadius)
    corner.Parent = frame

    -- Add subtle stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = frame

    -- Inner padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = frame

    -- Text label
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "NotificationText"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = CONFIG.TextColor
    textLabel.Font = CONFIG.Font
    textLabel.TextSize = CONFIG.TextSize
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextTransparency = 1 -- Start transparent
    textLabel.ZIndex = 11
    textLabel.Parent = frame

    -- Text stroke (outline)
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = CONFIG.TextStrokeColor
    textStroke.Transparency = CONFIG.TextStrokeTransparency
    textStroke.Thickness = 1.5
    textStroke.Parent = textLabel

    return frame, textLabel
end

function NotificationSystem:Notify(message, options)
    options = options or {}
    
    -- Play notification sound if configured
    if CONFIG.SoundId then
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.SoundId
        sound.Volume = options.volume or CONFIG.SoundVolume
        sound.PlayOnRemove = true
        sound.Parent = playerGui
        sound:Destroy()
    end

    -- Create notification frame
    local frame, textLabel = createNotificationFrame(message)
    frame.Parent = screenGui
    table.insert(notifications, 1, frame) -- Add to beginning of list

    -- Enforce maximum notifications
    while #notifications > CONFIG.MaxNotifications do
        cleanupNotification(notifications[#notifications])
    end

    -- Animate in
    local fadeIn = TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime), {
        BackgroundTransparency = CONFIG.BackgroundTransparency,
        Position = UDim2.new(1, -CONFIG.Padding, 0, CONFIG.Padding)
    })
    
    local textFadeIn = TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime), {
        TextTransparency = 0
    })

    fadeIn:Play()
    textFadeIn:Play()

    -- Reposition all notifications
    repositionNotifications()

    -- Set up auto-dismissal
    local lifetime = options.lifetime or CONFIG.Lifetime
    task.delay(lifetime, function()
        if not frame or not frame.Parent then return end
        
        -- Animate out
        local fadeOut = TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, CONFIG.Width, 0, frame.Position.Y.Offset)
        })
        
        local textFadeOut = TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime), {
            TextTransparency = 1
        })

        fadeOut:Play()
        textFadeOut:Play()

        fadeOut.Completed:Wait()
        cleanupNotification(frame)
        repositionNotifications()
        
        if options.callback then
            pcall(options.callback)
        end
    end)
end

-- Add quick notification types
function NotificationSystem:Info(message, options)
    self:Notify(message, options)
end

function NotificationSystem:Success(message, options)
    self:Notify(message, table.concat(options or {}, {
        backgroundColor = Color3.fromRGB(60, 180, 80)
    }))
end

function NotificationSystem:Warning(message, options)
    self:Notify(message, table.concat(options or {}, {
        backgroundColor = Color3.fromRGB(255, 180, 0)
    }))
end

function NotificationSystem:Error(message, options)
    self:Notify(message, table.concat(options or {}, {
        backgroundColor = Color3.fromRGB(220, 60, 60),
        lifetime = options and options.lifetime or 6
    }))
end

return NotificationSystem