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
local activeTweens = {}

local function cancelTween(tween)
    if tween then tween:Cancel() end
end

local function repositionNotifications()
    for i, notif in ipairs(notifications) do
        cancelTween(activeTweens[notif])

        local targetPos = UDim2.new(
            1, -CONFIG.Padding,
            0, CONFIG.Padding + (i - 1) * (CONFIG.Height + CONFIG.Padding)
        )

        local tween = TweenService:Create(
            notif,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = targetPos}
        )
        tween:Play()
        activeTweens[notif] = tween
    end
end

local function createNotification(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, CONFIG.Width, 0, CONFIG.Height)
    frame.BackgroundColor3 = CONFIG.BackgroundColor
    frame.BackgroundTransparency = 1 -- start fully transparent
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(1, 0) -- top-right
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
    textLabel.TextTransparency = 1 -- start fully transparent
    textLabel.ZIndex = 11
    textLabel.Parent = frame

    frame.Parent = screenGui
    return frame, textLabel
end

function NotificationSystem:Notify(message)
    -- Optional sound on notify
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

    -- Fade in
    TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = CONFIG.BackgroundTransparency}):Play()
    TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

    spawn(function()
        wait(CONFIG.Lifetime)

        -- Fade out
        local bgFade = TweenService:Create(frame, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
        local textFade = TweenService:Create(textLabel, TweenInfo.new(CONFIG.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})

        bgFade:Play()
        textFade:Play()
        bgFade.Completed:Wait()

        -- Remove notification
        for i, notif in ipairs(notifications) do
            if notif == frame then
                table.remove(notifications, i)
                break
            end
        end

        -- Cancel tween if any and cleanup
        if activeTweens[frame] then
            activeTweens[frame]:Cancel()
            activeTweens[frame] = nil
        end

        frame:Destroy()

        repositionNotifications()
    end)
end

return NotificationSystem