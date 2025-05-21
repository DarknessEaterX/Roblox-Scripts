local LogServiceSpy = {}
LogServiceSpy.__index = LogServiceSpy

-- Notification presets for different device types
local DEVICE_PRESETS = {
    -- Mobile devices (phones)
    ["Mobile"] = {
        size = UDim2.new(0.7, 0, 0, 100),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 14
    },
    
    -- Tablets
    ["Tablet"] = {
        size = UDim2.new(0.6, 0, 0, 120),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 16
    },
    
    -- Desktop
    ["Desktop"] = {
        size = UDim2.new(0.4, 0, 0, 150),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 18
    },
    
    -- Console (Xbox, etc.)
    ["Console"] = {
        size = UDim2.new(0.5, 0, 0, 130),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 16
    },
    
    -- VR devices
    ["VR"] = {
        size = UDim2.new(0.5, 0, 0, 120),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 16
    },
    
    -- Default fallback
    ["Default"] = {
        size = UDim2.new(0.5, 0, 0, 120),
        position = UDim2.new(1, -10, 0, 10),
        textSize = 16
    }
}

-- Colors for different message types
local MESSAGE_COLORS = {
    Message = Color3.fromRGB(76, 175, 80),   -- Green
    Warning = Color3.fromRGB(255, 193, 7),   -- Amber
    Error = Color3.fromRGB(244, 67, 54),     -- Red
    Output = Color3.fromRGB(33, 150, 243)    -- Blue
}

-- Icons for different message types
local MESSAGE_ICONS = {
    Message = "🗒️",
    Warning = "⚠️",
    Error = "❌",
    Output = "ℹ️"
}

function LogServiceSpy.new()
    local self = setmetatable({}, LogServiceSpy)
    
    self._notificationQueue = {}
    self._currentNotifications = {}
    self._maxNotifications = 3
    self._notificationDuration = 5
    self._spacing = 10
    
    -- Create a ScreenGui to hold notifications
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "LogServiceNotifications"
    self._screenGui.DisplayOrder = 10
    self._screenGui.ResetOnSpawn = false
    self._screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Determine device type
    self:_detectDeviceType()
    
    -- Connect to LogService
    self:_hookLogService()
    
    return self
end

function LogServiceSpy:_detectDeviceType()
    local platform = game:GetService("UserInputService"):GetPlatform()
    
    if platform == Enum.Platform.Android or platform == Enum.Platform.IOS then
        -- Check screen size to differentiate between phones and tablets
        local viewport = game:GetService("Workspace").CurrentCamera.ViewportSize
        if math.min(viewport.X, viewport.Y) > 1000 then
            self._deviceType = "Tablet"
        else
            self._deviceType = "Mobile"
        end
    elseif platform == Enum.Platform.Windows or platform == Enum.Platform.OSX then
        self._deviceType = "Desktop"
    elseif platform == Enum.Platform.XBoxOne or platform == Enum.Platform.PS4 then
        self._deviceType = "Console"
    elseif platform == Enum.Platform.VR then
        self._deviceType = "VR"
    else
        self._deviceType = "Default"
    end
end

function LogServiceSpy:_hookLogService()
    local logService = game:GetService("LogService")
    
    -- Store original methods
    self._originalMessageOut = logService.MessageOut
    self._originalWarningOut = logService.WarnOut
    self._originalErrorOut = logService.ErrorOut
    
    -- Hook into message events
    logService.MessageOut:Connect(function(message, messageType)
        self:_handleLog(message, messageType)
        self._originalMessageOut:Fire(message, messageType)
    end)
    
    logService.WarnOut:Connect(function(message)
        self:_handleLog(message, Enum.MessageType.MessageWarning)
        self._originalWarningOut:Fire(message)
    end)
    
    logService.ErrorOut:Connect(function(message, stackTrace)
        self:_handleLog(message, Enum.MessageType.MessageError)
        self._originalErrorOut:Fire(message, stackTrace)
    end)
end

function LogServiceSpy:_handleLog(message, messageType)
    local notification = {
        message = tostring(message),
        type = messageType,
        timestamp = os.time()
    }
    
    table.insert(self._notificationQueue, notification)
    self:_processQueue()
end

function LogServiceSpy:_processQueue()
    if #self._currentNotifications >= self._maxNotifications then
        return
    end
    
    if #self._notificationQueue > 0 then
        local notification = table.remove(self._notificationQueue, 1)
        self:_showNotification(notification)
    end
end

function LogServiceSpy:_showNotification(notification)
    local preset = DEVICE_PRESETS[self._deviceType] or DEVICE_PRESETS["Default"]
    local messageType = notification.type.Name
    local color = MESSAGE_COLORS[messageType] or MESSAGE_COLORS["Output"]
    local icon = MESSAGE_ICONS[messageType] or MESSAGE_ICONS["Output"]
    
    -- Create notification frame
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.Size = preset.size
    frame.Position = preset.position
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 2
    
    -- Add corner rounding
    local uICorner = Instance.new("UICorner")
    uICorner.CornerRadius = UDim.new(0, 8)
    uICorner.Parent = frame
    
    -- Add stroke
    local uIStroke = Instance.new("UIStroke")
    uIStroke.Color = Color3.new(1, 1, 1)
    uIStroke.Thickness = 1
    uIStroke.Transparency = 0.5
    uIStroke.Parent = frame
    
    -- Add icon and message
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = frame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = preset.textSize + 4
    iconLabel.TextColor3 = Color3.new(1, 1, 1)
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -40, 1, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = notification.message
    messageLabel.TextSize = preset.textSize
    messageLabel.TextColor3 = Color3.new(1, 1, 1)
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.Parent = frame
    
    -- Position the notification (accounting for existing ones)
    self:_positionNotification(frame)
    
    -- Add to current notifications
    table.insert(self._currentNotifications, frame)
    frame.Parent = self._screenGui
    
    -- Animate in
    frame.Position = frame.Position + UDim2.new(0.2, 0, 0, 0)
    frame:TweenPosition(
        preset.position,
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    
    -- Auto-dismiss after duration
    delay(self._notificationDuration, function()
        self:_dismissNotification(frame)
    end)
end

function LogServiceSpy:_positionNotification(frame)
    local yOffset = 0
    for _, existingFrame in ipairs(self._currentNotifications) do
        yOffset = yOffset + existingFrame.AbsoluteSize.Y + self._spacing
    end
    frame.Position = frame.Position + UDim2.new(0, 0, 0, yOffset)
end

function LogServiceSpy:_dismissNotification(frame)
    -- Find and remove the frame from current notifications
    for i, existingFrame in ipairs(self._currentNotifications) do
        if existingFrame == frame then
            table.remove(self._currentNotifications, i)
            break
        end
    end
    
    -- Animate out
    frame:TweenPosition(
        frame.Position + UDim2.new(0.2, 0, 0, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Quad,
        0.3,
        true,
        function()
            frame:Destroy()
            self:_processQueue()
            self:_updatePositions()
        end
    )
end

function LogServiceSpy:_updatePositions()
    local preset = DEVICE_PRESETS[self._deviceType] or DEVICE_PRESETS["Default"]
    local yOffset = 0
    
    for _, frame in ipairs(self._currentNotifications) do
        frame:TweenPosition(
            preset.position + UDim2.new(0, 0, 0, yOffset),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        yOffset = yOffset + frame.AbsoluteSize.Y + self._spacing
    end
end

-- Destroy the spy and clean up
function LogServiceSpy:Destroy()
    -- Restore original LogService methods
    local logService = game:GetService("LogService")
    logService.MessageOut = self._originalMessageOut
    logService.WarnOut = self._originalWarningOut
    logService.ErrorOut = self._originalErrorOut
    
    -- Clean up notifications
    for _, frame in ipairs(self._currentNotifications) do
        frame:Destroy()
    end
    self._screenGui:Destroy()
end

return LogServiceSpy