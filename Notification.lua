-- NotificationSystem Module
local NotificationSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create a ScreenGui container for notifications
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationSystemGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- UI parameters
local NOTIF_WIDTH = 300
local NOTIF_HEIGHT = 50
local NOTIF_PADDING = 10
local NOTIF_LIFETIME = 4 -- seconds visible
local FADE_TIME = 0.4

local notifications = {}

local function createNotification(text)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(1, 0) -- top-right anchor
    frame.Position = UDim2.new(1, -NOTIF_PADDING, 0, NOTIF_PADDING)
    frame.ClipsDescendants = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.7
    textLabel.TextWrapped = true
    textLabel.Font = Enum.Font.SourceSansSemibold
    textLabel.TextSize = 18
    textLabel.Parent = frame

    frame.Parent = screenGui
    frame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1

    return frame, textLabel
end

local function tweenProperty(instance, property, goal, duration)
    local start = instance[property]
    local startTime = tick()
    local connection
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed > duration then
            instance[property] = goal
            connection:Disconnect()
        else
            local alpha = elapsed / duration
            instance[property] = start + (goal - start) * alpha
        end
    end)
end

-- Show a notification on screen
function NotificationSystem:Notify(message)
    local frame, textLabel = createNotification(message)
    table.insert(notifications, frame)

    -- Reposition notifications (stacking from top)
    for i, notif in ipairs(notifications) do
        notif:TweenPosition(
            UDim2.new(1, -NOTIF_PADDING, 0, NOTIF_PADDING + (i-1) * (NOTIF_HEIGHT + NOTIF_PADDING)),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end

    -- Fade in
    frame:TweenBackgroundTransparency(0.2, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, FADE_TIME, true)
    textLabel:TweenTextTransparency(0, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, FADE_TIME, true)

    -- After lifetime + fade, fade out and remove
    delay(NOTIF_LIFETIME, function()
        frame:TweenBackgroundTransparency(1, Enum.EasingDirection.In, Enum.EasingStyle.Quad, FADE_TIME, true)
        textLabel:TweenTextTransparency(1, Enum.EasingDirection.In, Enum.EasingStyle.Quad, FADE_TIME, true)

        delay(FADE_TIME, function()
            -- Remove from table
            for i, notif in ipairs(notifications) do
                if notif == frame then
                    table.remove(notifications, i)
                    break
                end
            end

            frame:Destroy()

            -- Reposition remaining notifications
            for i, notif in ipairs(notifications) do
                notif:TweenPosition(
                    UDim2.new(1, -NOTIF_PADDING, 0, NOTIF_PADDING + (i-1) * (NOTIF_HEIGHT + NOTIF_PADDING)),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.3,
                    true
                )
            end
        end)
    end)
end

return NotificationSystem