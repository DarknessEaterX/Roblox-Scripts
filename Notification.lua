-- Improved NotificationSystem Module
local NotificationSystem = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui container for notifications (only once)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationSystemGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Configurable parameters
local CONFIG = {
    Width = 320,
    Height = 50,
    Padding = 12,
    Lifetime = 4,
    FadeTime = 0.5,
    BackgroundColor = Color3.fromRGB(25, 25, 25),
    BackgroundTransparency = 0.25,
    TextColor = Color3.new(1,1,1),
    TextStrokeTransparency = 0.75,
    Font = Enum.Font.SourceSansSemibold,
    TextSize = 18,
    SoundId = nil, -- Optional: put a sound asset ID string here to play on notify
}

local notifications = {}

-- Helper: Tween a property and wait for it to complete before continuing
local function tweenProperty(instance, property, goal, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, {[property] = goal})
    tween:Play()
    local completed = false
    tween.Completed:Connect(function()
        completed = true
    end)
    -- Wait until tween finishes
    while not completed do
        RunService.Heartbeat:Wait()
    end
end

-- Helper: Create notification frame + text
local function createNotification(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
    frame.BackgroundColor3 = CONFIG.BackgroundColor
    frame.BackgroundTransparency = 1 -- start transparent
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(1, 0) -- top-right anchor
    frame.Position = UDim2.new(1, -CONFIG.Padding, 0, CONFIG.Padding)
    frame.ClipsDescendants = true
    frame.ZIndex = 10

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = CONFIG.TextColor
    textLabel.TextStrokeTransparency = CONFIG.TextStrokeTransparency
    textLabel.TextWrapped = true
    textLabel.Font = CONFIG.Font
    textLabel.TextSize = CONFIG.TextSize
    textLabel.TextTransparency = 1 -- start transparent
    textLabel.ZIndex = 11
    textLabel.Parent = frame

    frame.Parent = screenGui
    return frame, textLabel
end

-- Helper: reposition notifications smoothly
local function repositionNotifications()
    for i, notif in ipairs(notifications) do
        notif:TweenPosition(
            UDim2.new(1, -CONFIG.Padding, 0, CONFIG.Padding + (i - 1) * (CONFIG.Height + CONFIG.Padding)),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end
end

-- Main notification function
function NotificationSystem:Notify(message)
    -- Play sound if set
    if CONFIG.SoundId then
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.SoundId
        sound.Volume = 0.5
        sound.PlayOnRemove = true
        sound.Parent = playerGui
        sound:Destroy() -- plays and cleans itself
    end

    local frame, textLabel = createNotification(message)
    table.insert(notifications, frame)

    repositionNotifications()

    -- Fade in (non-blocking)
    TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = CONFIG.BackgroundTransparency}):Play()
    TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

    -- Schedule fade out and removal after lifetime
    spawn(function()
        wait(CONFIG.Lifetime)

        -- Fade out (block until done)
        tweenProperty(frame, "BackgroundTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tweenProperty(textLabel, "TextTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        -- Remove notification from list and destroy
        for i, notif in ipairs(notifications) do
            if notif == frame then
                table.remove(notifications, i)
                break
            end
        end

        frame:Destroy()

        -- Reposition remaining notifications
        repositionNotifications()
    end)
end

return NotificationSystem