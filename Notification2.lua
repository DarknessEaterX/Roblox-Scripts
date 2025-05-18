-- Notification Module

local NotificationService = {}

-- Configuration
local animationDuration = 0.3 -- Seconds
local notificationLifetime = 5 -- Seconds
local notificationSpacing = 5 -- Pixels
local safeAreaOffset = 10 -- Pixels

-- UI Elements
local screenGui
local notificationContainer

-- Callbacks
local onDismissCallback

-- Helper Functions
local function Create(objectType, properties)
    local object = Instance.new(objectType)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

local function Animate(guiObject, property, startValue, endValue, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(guiObject, tweenInfo, {[property] = endValue})
    tween:Play()
    return tween
end

