local Notification = {}
Notification.__index = Notification

-- Default configuration
local config = {
    Position = UDim2.new(1, -10, 1, -10), -- Bottom right with 10px padding
    Size = UDim2.new(0, 300, 0, 120), -- Increased height to accommodate content
    BackgroundColor = Color3.fromRGB(30, 30, 30),
    TextColor = Color3.fromRGB(255, 255, 255),
    TitleFont = Enum.Font.SourceSansBold,
    ContentFont = Enum.Font.SourceSans,
    TitleSize = 18,
    ContentSize = 16,
    AutoDismiss = 5, -- Seconds (set to false to disable)
    AnimationSpeed = 0.25, -- Seconds
    Spacing = 10 -- Space between notifications
}

-- Store active notifications to manage stacking
local activeNotifications = {}

function Notification.new(options)
    local self = setmetatable({}, Notification)
    
    -- Merge defaults with options
    self.settings = {}
    for k, v in pairs(config) do
        self.settings[k] = options[k] or v
    end
    
    self.title = options.Title or "Notification"
    self.content = options.Content or ""
    self.buttons = options.Buttons or {}
    
    self:createUI()
    self:show()
    
    return self
end

function Notification:createUI()
    -- Create main frame
    self.frame = Instance.new("Frame")
    self.frame.BackgroundColor3 = self.settings.BackgroundColor
    self.frame.Size = self.settings.Size
    self.frame.Position = UDim2.new(1, 0, 1, 0) -- Start offscreen
    self.frame.AnchorPoint = Vector2.new(1, 1)
    self.frame.BorderSizePixel = 0
    self.frame.ZIndex = 100
    
    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.frame
    
    -- Add drop shadow
    local shadow = Instance.new("UIStroke")
    shadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Transparency = 0.7
    shadow.Thickness = 2
    shadow.Parent = self.frame
    
    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = self.title
    titleLabel.Font = self.settings.TitleFont
    titleLabel.TextSize = self.settings.TitleSize
    titleLabel.TextColor3 = self.settings.TextColor
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, self.settings.TitleSize + 5)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = self.frame
    
    -- Content label
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Text = self.content
    contentLabel.Font = self.settings.ContentFont
    contentLabel.TextSize = self.settings.ContentSize
    contentLabel.TextColor3 = self.settings.TextColor
    contentLabel.BackgroundTransparency = 1
    contentLabel.Size = UDim2.new(1, -20, 1, -titleLabel.Size.Y.Offset - 40) -- Adjusted for buttons
    contentLabel.Position = UDim2.new(0, 10, 0, titleLabel.Size.Y.Offset + 15)
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.Parent = self.frame
    
    -- Button container
    if #self.buttons > 0 then
        local buttonContainer = Instance.new("Frame")
        buttonContainer.BackgroundTransparency = 1
        buttonContainer.Size = UDim2.new(1, -10, 0, 30)
        buttonContainer.Position = UDim2.new(0, 5, 1, -35)
        buttonContainer.Parent = self.frame
        
        for i, btnData in ipairs(self.buttons) do
            local button = Instance.new("TextButton")
            button.Text = btnData.Title
            button.Font = self.settings.ContentFont
            button.TextSize = self.settings.ContentSize
            button.TextColor3 = self.settings.TextColor
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            button.AutoButtonColor = true
            button.Size = UDim2.new((0.9/#self.buttons), -5, 0, 30)
            button.Position = UDim2.new((i-1) * (0.9/#self.buttons), 5, 0, 0)
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = button
            
            button.MouseButton1Click:Connect(function()
                if btnData.Callback then
                    btnData.Callback()
                end
                if btnData.ClosesUI then
                    self:dismiss()
                end
            end)
            
            button.Parent = buttonContainer
        end
    end
    
    -- Add to ScreenGui
    if not Notification.screenGui or not Notification.screenGui.Parent then
        Notification.screenGui = Instance.new("ScreenGui")
        Notification.screenGui.DisplayOrder = 100
        Notification.screenGui.ResetOnSpawn = false
        Notification.screenGui.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self.frame.Parent = Notification.screenGui
end

function Notification:show()
    -- Calculate position based on existing notifications
    local yOffset = 0
    for _, notif in ipairs(activeNotifications) do
        yOffset = yOffset + notif.frame.AbsoluteSize.Y + self.settings.Spacing
    end
    
    -- Adjust position for this notification
    local targetPos = UDim2.new(
        self.settings.Position.X.Scale, 
        self.settings.Position.X.Offset,
        self.settings.Position.Y.Scale,
        self.settings.Position.Y.Offset - yOffset
    )
    
    -- Animate in
    self.frame:TweenPosition(
        targetPos,
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        self.settings.AnimationSpeed,
        true
    )
    
    table.insert(activeNotifications, self)
    
    -- Auto dismiss if enabled
    if self.settings.AutoDismiss then
        task.delay(self.settings.AutoDismiss, function()
            self:dismiss()
        end)
    end
end

function Notification:dismiss()
    -- Find and remove from active notifications
    for i, notif in ipairs(activeNotifications) do
        if notif == self then
            table.remove(activeNotifications, i)
            break
        end
    end
    
    -- Animate out
    self.frame:TweenPosition(
        UDim2.new(1, 0, 1, 0),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Quad,
        self.settings.AnimationSpeed,
        true,
        function()
            self.frame:Destroy()
            self:updatePositions()
        end
    )
end

function Notification:updatePositions()
    -- Update positions of remaining notifications
    local yOffset = 0
    for _, notif in ipairs(activeNotifications) do
        local targetPos = UDim2.new(
            notif.settings.Position.X.Scale,
            notif.settings.Position.X.Offset,
            notif.settings.Position.Y.Scale,
            notif.settings.Position.Y.Offset - yOffset
        )
        
        notif.frame:TweenPosition(
            targetPos,
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            notif.settings.AnimationSpeed,
            true
        )
        
        yOffset = yOffset + notif.frame.AbsoluteSize.Y + notif.settings.Spacing
    end
end

return Notification