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

-- We'll store tweens per notification frame here:
local activeTweens = {}

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
        -- Remove from activeTweens once complete
        if activeTweens[instance] then
            for i, t in ipairs(activeTweens[instance]) do
                if t == tween then
                    table.remove(activeTweens[instance], i)
                    break
                end
            end
            if #activeTweens[instance] == 0 then
                activeTweens[instance] = nil
            end
        end
    end)

    -- Track this tween
    activeTweens[instance] = activeTweens[instance] or {}
    table.insert(activeTweens[instance], tween)

    while not completed do
        RunService.Heartbeat:Wait()
    end
end

-- Cancel all active tweens for an instance
local function cancelTweens(instance)
    if activeTweens[instance] then
        for _, tween in ipairs(activeTweens[instance]) do
            tween:Cancel()
        end
        activeTweens[instance] = nil
    end
end

local function createNotification(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
    frame.BackgroundColor3 = CONFIG.BackgroundColor
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(1, 0)
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
    textLabel.TextTransparency = 1
    textLabel.ZIndex = 11
    textLabel.Parent = frame

    frame.Parent = screenGui
    return frame, textLabel
end

local function repositionNotifications()
    for i, notif in ipairs(notifications) do
        cancelTweens(notif)
        local targetPos = UDim2.new(
            1, -CONFIG.Padding,
            0, CONFIG.Padding + (i - 1) * (CONFIG.Height + CONFIG.Padding)
        )
        -- Tween position but store tween manually
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(notif, tweenInfo, {Position = targetPos})
        tween:Play()

        activeTweens[notif] = activeTweens[notif] or {}
        table.insert(activeTweens[notif], tween)

        tween.Completed:Connect(function()
            -- Remove from active tweens when done
            if activeTweens[notif] then
                for i, t in ipairs(activeTweens[notif]) do
                    if t == tween then
                        table.remove(activeTweens[notif], i)
                        break
                    end
                end
                if #activeTweens[notif] == 0 then
                    activeTweens[notif] = nil
                end
            end
        end)
    end
end

function NotificationSystem:Notify(message)
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

    repositionNotifications()

    TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = CONFIG.BackgroundTransparency}):Play()
    TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

    spawn(function()
        wait(CONFIG.Lifetime)

        tweenProperty(frame, "BackgroundTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tweenProperty(textLabel, "TextTransparency", 1, CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

        for i, notif in ipairs(notifications) do
            if notif == frame then
                table.remove(notifications, i)
                break
            end
        end

        frame:Destroy()
        repositionNotifications()
    end)
end

return NotificationSystem