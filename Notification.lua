local NotificationSystem = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationSystemGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

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
    SoundId = nil,
}

local notifications = {}

-- Helper to tween a property and wait for completion
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
    while not completed do
        RunService.Heartbeat:Wait()
    end
end

-- Helper to cancel all tweens on a given instance (important to prevent overlap/jitter)
local function cancelTweens(instance)
    local tweens = TweenService:GetPlayingTweens(instance)
    for _, tween in ipairs(tweens) do
        tween:Cancel()
    end
end

-- Create notification frame and text label
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

-- Reposition notifications stacked top-right with spacing, cancelling any running tweens
local function repositionNotifications()
    for i, notif in ipairs(notifications) do
        cancelTweens(notif)
        local targetPos = UDim2.new(
            1, -CONFIG.Padding,
            0, CONFIG.Padding + (i - 1) * (CONFIG.Height + CONFIG.Padding)
        )
        notif:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
    end
end

-- Main Notify function
function NotificationSystem:Notify(message)
    -- Optional sound play
    if CONFIG.SoundId then
        local sound = Instance.new("Sound")
        sound.SoundId = CONFIG.SoundId
        sound.Volume = 0.5
        sound.PlayOnRemove = true
        sound.Parent = playerGui
        sound:Destroy()
    end

    local frame, textLabel = createNotification(message)
    table.insert(notifications, frame)

    -- Reposition all notifications immediately to avoid overlap
    repositionNotifications()

    -- Fade in
    TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = CONFIG.BackgroundTransparency}):Play()
    TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

    -- Schedule fade out and removal
    spawn(function()
        wait(CONFIG.Lifetime)

        tweenProperty(frame, "BackgroundTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tweenProperty(textLabel, "TextTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        -- Remove from notifications list and destroy
        for i, notif in ipairs(notifications) do
            if notif == frame then
                table.remove(notifications, i)
                break
            end
        end

        frame:Destroy()
        -- Reposition remaining notifications after removal
        repositionNotifications()
    end)
end

return NotificationSystem