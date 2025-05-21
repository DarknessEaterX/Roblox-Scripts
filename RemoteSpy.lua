local LogServiceSpy = {}
LogServiceSpy.__index = LogServiceSpy

-- Notification presets
local DEVICE_PRESETS = {
    ["Mobile"] = { size = UDim2.new(0.7, 0, 0, 80), textSize = 14 },
    ["Tablet"] = { size = UDim2.new(0.6, 0, 0, 100), textSize = 16 },
    ["Desktop"] = { size = UDim2.new(0.4, 0, 0, 120), textSize = 18 },
    ["Console"] = { size = UDim2.new(0.5, 0, 0, 100), textSize = 16 },
    ["VR"] = { size = UDim2.new(0.5, 0, 0, 100), textSize = 16 },
    ["Default"] = { size = UDim2.new(0.5, 0, 0, 100), textSize = 16 }
}

local MESSAGE_COLORS = {
    Message = Color3.fromRGB(76, 175, 80),   -- Green
    Warning = Color3.fromRGB(255, 193, 7),   -- Amber
    Error = Color3.fromRGB(244, 67, 54),     -- Red
    Output = Color3.fromRGB(33, 150, 243)    -- Blue
}

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
    self._maxOnScreen = 3
    self._duration = 5
    self._spacing = 10
    
    -- Create ScreenGui
    self._screenGui = Instance.new("ScreenGui")
    self._screenGui.Name = "LogNotifications"
    self._screenGui.ResetOnSpawn = false
    self._screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    self:_detectDevice()
    self:_hookLogService()
    
    return self
end

function LogServiceSpy:_detectDevice()
    local platform = game:GetService("UserInputService"):GetPlatform()
    
    if platform == Enum.Platform.Android or platform == Enum.Platform.IOS then
        local viewport = game:GetService("Workspace").CurrentCamera.ViewportSize
        self._deviceType = math.min(viewport.X, viewport.Y) > 1000 and "Tablet" or "Mobile"
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
    
    -- Corrected event connections
    logService.MessageOut:Connect(function(message, messageType)
        self:_handleMessage(message, messageType)
    end)
    
    logService.WarnOut:Connect(function(message)  -- Fixed to use WarnOut
        self:_handleMessage(message, Enum.MessageType.MessageWarning)
    end)
    
    logService.ErrorOut:Connect(function(message, stackTrace)
        self:_handleMessage(message, Enum.MessageType.MessageError)
    end)
end

function LogServiceSpy:_handleMessage(message, messageType)
    table.insert(self._notificationQueue, {
        text = tostring(message),
        type = messageType or Enum.MessageType.MessageOutput,
        time = os.time()
    })
    self:_processQueue()
end

function LogServiceSpy:_processQueue()
    while #self._currentNotifications < self._maxOnScreen and #self._notificationQueue > 0 do
        self:_showNotification(table.remove(self._notificationQueue, 1))
    end
end

function LogServiceSpy:_showNotification(data)
    local preset = DEVICE_PRESETS[self._deviceType]
    local msgType = data.type.Name
    local frame = Instance.new("Frame")
    
    frame.Size = preset.size
    frame.Position = UDim2.new(1, -10, 0, 10)
    frame.AnchorPoint = Vector2.new(1, 0)
    frame.BackgroundColor3 = MESSAGE_COLORS[msgType]
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.ZIndex = 2
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = frame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Text = MESSAGE_ICONS[msgType]
    icon.TextSize = preset.textSize + 4
    icon.BackgroundTransparency = 1
    icon.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Text = data.text
    label.TextSize = preset.textSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame
    
    -- Position notification
    local yOffset = 0
    for _, note in ipairs(self._currentNotifications) do
        yOffset += note.AbsoluteSize.Y + self._spacing
    end
    frame.Position += UDim2.new(0, 0, 0, yOffset)
    
    -- Animate in
    frame.Position += UDim2.new(0.2, 0, 0, 0)
    frame:TweenPosition(
        frame.Position - UDim2.new(0.2, 0, 0, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    
    table.insert(self._currentNotifications, frame)
    frame.Parent = self._screenGui
    
    -- Auto-dismiss
    task.delay(self._duration, function()
        self:_removeNotification(frame)
    end)
end

function LogServiceSpy:_removeNotification(frame)
    for i, note in ipairs(self._currentNotifications) do
        if note == frame then
            table.remove(self._currentNotifications, i)
            break
        end
    end
    
    frame:TweenPosition(
        frame.Position + UDim2.new(0.2, 0, 0, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Quad,
        0.3,
        true,
        function()
            frame:Destroy()
            self:_updatePositions()
            self:_processQueue()
        end
    )
end

function LogServiceSpy:_updatePositions()
    local yPos = 10
    for _, note in ipairs(self._currentNotifications) do
        note:TweenPosition(
            UDim2.new(1, -10, 0, yPos),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        yPos += note.AbsoluteSize.Y + self._spacing
    end
end

function LogServiceSpy:Destroy()
    for _, note in ipairs(self._currentNotifications) do
        note:Destroy()
    end
    self._screenGui:Destroy()
end

return LogServiceSpy