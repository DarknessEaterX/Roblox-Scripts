--[[
    Advanced Roblox UI Library
    Version: 1.0
    Author: Your Name
    
    Features:
    - Fully responsive design for PC and mobile
    - Dynamic scaling based on viewport size
    - Modular component system with clean API
    - No external asset dependencies
    - Performance optimized
    - Comprehensive theming system
]]

local UILibrary = {}
UILibrary.__index = UILibrary

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

-- Constants
local TOUCH_THRESHOLD = 12 -- Minimum spacing between touch elements
local DEFAULT_THEME = {
    Background = Color3.fromRGB(30, 30, 30),
    Foreground = Color3.fromRGB(45, 45, 45),
    Accent = Color3.fromRGB(0, 120, 215),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Error = Color3.fromRGB(255, 50, 50),
    Success = Color3.fromRGB(50, 255, 50),
    Warning = Color3.fromRGB(255, 150, 50)
}

local DEFAULT_FONT = Enum.Font.SourceSans
local DEFAULT_TEXT_SIZE = 14
local DEFAULT_ANIMATION_SPEED = 0.15
local DEFAULT_SCALE = 1

-- Utility functions
local function create(class, props)
    local instance = Instance.new(class)
    for prop, value in pairs(props) do
        if prop == "Parent" then
            instance.Parent = value
        else
            instance[prop] = value
        end
    end
    return instance
end

local function tween(instance, props, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or DEFAULT_ANIMATION_SPEED,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, props)
    tween:Play()
    return tween
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

-- Main UI Library Class
function UILibrary.new(parentGui)
    local self = setmetatable({}, UILibrary)
    
    -- Initialize properties
    self._theme = DEFAULT_THEME
    self._font = DEFAULT_FONT
    self._textSize = DEFAULT_TEXT_SIZE
    self._textSizeMultiplier = 1
    self._animationSpeed = DEFAULT_ANIMATION_SPEED
    self._scale = DEFAULT_SCALE
    self._windows = {}
    self._notifications = {}
    self._components = {}
    self._activeTweens = {}
    
    -- Create main screen gui
    self._screenGui = create("ScreenGui", {
        Name = "UILibrary",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = parentGui or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    })
    
    -- Create notification holder
    self._notificationHolder = create("Frame", {
        Name = "NotificationHolder",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self._screenGui
    })
    
    -- Set up viewport scaling
    self:SetupViewportScaling()
    
    return self
end

function UILibrary:SetupViewportScaling()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    
    -- Main scale calculation
    local function updateScale()
        local baseSize = 1920 -- Base resolution width
        local minScale = 0.5
        local maxScale = 2
        
        -- Calculate scale based on viewport width
        local calculatedScale = (viewportSize.X / baseSize) * self._scale
        calculatedScale = math.clamp(calculatedScale, minScale, maxScale)
        
        -- Apply to all windows
        for _, window in pairs(self._windows) do
            if window and window._uiScale then
                window._uiScale.Scale = calculatedScale
            end
        end
    end
    
    -- Initial setup
    updateScale()
    
    -- Connect to viewport changes
    self._viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        viewportSize = workspace.CurrentCamera.ViewportSize
        updateScale()
    end)
end

function UILibrary:CreateWindow(title, size, position, aspectRatio)
    local window = setmetatable({}, self)
    window._title = title or "Window"
    window._size = size or UDim2.new(0, 400, 0, 500)
    window._position = position or UDim2.new(0.5, 0, 0.5, 0)
    window._aspectRatio = aspectRatio or (size and size.X.Scale == 0 and size.Y.Scale == 0 and size.X.Offset / size.Y.Offset) or nil
    window._draggable = true
    window._isOpen = true
    window._tabs = {}
    window._activeTab = nil
    window._components = {}

    -- Create main window frame
    window._mainFrame = Instance.new("Frame")
    window._mainFrame.Name = "Window"
    window._mainFrame.BackgroundColor3 = self._theme.Background
    window._mainFrame.BorderSizePixel = 0
    window._mainFrame.Size = window._size
    window._mainFrame.Position = window._position
    window._mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    window._mainFrame.Parent = self._screenGui

    -- Add aspect ratio constraint if specified
    if window._aspectRatio then
        local aspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
        aspectRatioConstraint.AspectRatio = window._aspectRatio
        aspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize
        aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
        aspectRatioConstraint.Parent = window._mainFrame
    end

    -- Add UI scale
    window._uiScale = Instance.new("UIScale")
    window._uiScale.Scale = self._scale
    window._uiScale.Parent = window._mainFrame

    -- Add corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = window._mainFrame

    -- Create title bar
    window._titleBar = Instance.new("Frame")
    window._titleBar.Name = "TitleBar"
    window._titleBar.BackgroundColor3 = self._theme.Foreground
    window._titleBar.Size = UDim2.new(1, 0, 0, 32)
    window._titleBar.Parent = window._mainFrame

    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 8)
    titleBarCorner.Parent = window._titleBar

    local titleBarStroke = Instance.new("UIStroke")
    titleBarStroke.Name = "TitleBarStroke"
    titleBarStroke.Color = self._theme.Accent
    titleBarStroke.Thickness = 1
    titleBarStroke.Parent = window._titleBar

    -- Title text
    window._titleLabel = Instance.new("TextLabel")
    window._titleLabel.Name = "Title"
    window._titleLabel.BackgroundTransparency = 1
    window._titleLabel.Position = UDim2.new(0, 12, 0, 0)
    window._titleLabel.Size = UDim2.new(1, -24, 1, 0)
    window._titleLabel.Font = self._font
    window._titleLabel.Text = window._title
    window._titleLabel.TextColor3 = self._theme.Text
    window._titleLabel.TextSize = self._textSize * self._textSizeMultiplier
    window._titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    window._titleLabel.Parent = window._titleBar

    -- Close button
    window._closeButton = Instance.new("TextButton")
    window._closeButton.Name = "CloseButton"
    window._closeButton.BackgroundTransparency = 1
    window._closeButton.Position = UDim2.new(1, -32, 0, 0)
    window._closeButton.Size = UDim2.new(0, 32, 1, 0)
    window._closeButton.Font = self._font
    window._closeButton.Text = "×"
    window._closeButton.TextColor3 = self._theme.Text
    window._closeButton.TextSize = self._textSize * self._textSizeMultiplier * 1.5
    window._closeButton.Parent = window._titleBar

    -- Tab container
    window._tabContainer = Instance.new("Frame")
    window._tabContainer.Name = "TabContainer"
    window._tabContainer.BackgroundColor3 = self._theme.Foreground
    window._tabContainer.Position = UDim2.new(0, 0, 0, 32)
    window._tabContainer.Size = UDim2.new(1, 0, 0, 32)
    window._tabContainer.Parent = window._mainFrame

    local tabContainerStroke = Instance.new("UIStroke")
    tabContainerStroke.Color = self._theme.Accent
    tabContainerStroke.Thickness = 1
    tabContainerStroke.Parent = window._tabContainer

    -- Content frame
    window._contentFrame = Instance.new("Frame")
    window._contentFrame.Name = "Content"
    window._contentFrame.BackgroundColor3 = self._theme.Background
    window._contentFrame.Position = UDim2.new(0, 0, 0, 64)
    window._contentFrame.Size = UDim2.new(1, 0, 1, -64)
    window._contentFrame.ClipsDescendants = true
    window._contentFrame.Parent = window._mainFrame

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = window._contentFrame

    -- Tab list layout
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Name = "TabListLayout"
    tabListLayout.FillDirection = Enum.FillDirection.Horizontal
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 0)
    tabListLayout.Parent = window._tabContainer

    -- Window methods
    function window:Close()
        if not self._isOpen then return end
        
        self._isOpen = false
        TweenService:Create(self._mainFrame, TweenInfo.new(self._animationSpeed), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        
        delay(self._animationSpeed + 0.1, function()
            if self._mainFrame then
                self._mainFrame:Destroy()
            end
        end)
    end

    function window:Open()
        if self._isOpen then return end
        
        self._isOpen = true
        self._mainFrame.Size = UDim2.new(0, 0, 0, 0)
        self._mainFrame.Visible = true
        TweenService:Create(self._mainFrame, TweenInfo.new(self._animationSpeed), {Size = self._size}):Play()
    end

    function window:Toggle()
        if self._isOpen then
            self:Close()
        else
            self:Open()
        end
    end

    function window:SetDraggable(draggable)
        self._draggable = draggable
    end

    -- Setup drag functionality
    local dragStartPos
    local frameStartPos
    local dragging = false
    
    local function updatePosition(input)
        if not window._draggable then return end
        
        local delta = input.Position - dragStartPos
        local newPosition = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
        
        -- Keep window within screen bounds
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = window._mainFrame.AbsoluteSize
        local absPos = window._mainFrame.AbsolutePosition
        
        -- Calculate min/max positions
        local minX = -absPos.X + 20
        local maxX = viewportSize.X - (absPos.X + frameSize.X) - 20
        local minY = -absPos.Y + 20
        local maxY = viewportSize.Y - (absPos.Y + frameSize.Y) - 20
        
        -- Apply constraints
        newPosition = UDim2.new(
            newPosition.X.Scale,
            math.clamp(newPosition.X.Offset, minX, maxX),
            newPosition.Y.Scale,
            math.clamp(newPosition.Y.Offset, minY, maxY)
        )
        
        window._mainFrame.Position = newPosition
    end
    
    window._titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = window._mainFrame.Position
            
            -- Visual feedback
            TweenService:Create(window._titleBar, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    TweenService:Create(window._titleBar, TweenInfo.new(0.1), {BackgroundColor3 = self._theme.Foreground}):Play()
                end
            end)
        end
    end)
    
    window._titleBar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updatePosition(input)
        end
    end)
    
    UserInputService.TouchMoved:Connect(function(touchPos, gameProcessed)
        if not gameProcessed and dragging then
            updatePosition({Position = touchPos, UserInputType = Enum.UserInputType.Touch})
        end
    end)

    -- Close button event
    window._closeButton.MouseButton1Click:Connect(function()
        window:Close()
    end)

    -- Add to windows table
    table.insert(self._windows, window)
    
    return window
end
function UILibrary:SetDraggable(draggable)
    self._draggable = draggable
end

function UILibrary:Close()
    if not self._isOpen then return end
    
    self._isOpen = false
    tween(self._mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, self._animationSpeed):Play()
    
    -- Delay destruction to allow tween to complete
    delay(self._animationSpeed + 0.1, function()
        if self._mainFrame then
            self._mainFrame:Destroy()
        end
    end)
end

function UILibrary:Open()
    if self._isOpen then return end
    
    self._isOpen = true
    self._mainFrame.Size = UDim2.new(0, 0, 0, 0)
    self._mainFrame.Visible = true
    tween(self._mainFrame, {Size = self._size}, self._animationSpeed)
end

function UILibrary:Toggle()
    if self._isOpen then
        self:Close()
    else
        self:Open()
    end
end

function UILibrary:AddTab(name)
    local tab = {
        Name = name or "Tab " .. (#self._tabs + 1),
        Sections = {},
        _container = nil,
        _button = nil
    }
    
    -- Create tab button
    tab._button = create("TextButton", {
        Name = "TabButton",
        BackgroundColor3 = self._theme.Foreground,
        Size = UDim2.new(0, 100, 1, 0),
        Font = self._font,
        Text = tab.Name,
        TextColor3 = self._theme.TextSecondary,
        TextSize = self._textSize * self._textSizeMultiplier,
        Parent = self._tabContainer
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = tab._button
    })
    
    -- Create tab content container
    tab._container = create("ScrollingFrame", {
        Name = "TabContent",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(1, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self._theme.Accent,
        Parent = self._contentFrame,
        Visible = false
    })
    
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = tab._container
    })
    
    create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = tab._container
    })
    
    -- Tab button events
    tab._button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    -- Add hover effects
    tab._button.MouseEnter:Connect(function()
        if tab ~= self._activeTab then
            tween(tab._button, {TextColor3 = self._theme.Text}, 0.1)
        end
    end)
    
    tab._button.MouseLeave:Connect(function()
        if tab ~= self._activeTab then
            tween(tab._button, {TextColor3 = self._theme.TextSecondary}, 0.1)
        end
    end)
    
    -- Add to tabs table
    table.insert(self._tabs, tab)
    
    -- Select first tab by default
    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    
    return tab
end

function UILibrary:SelectTab(tab)
    -- Deselect current tab
    if self._activeTab then
        tween(self._activeTab._button, {
            BackgroundColor3 = self._theme.Foreground,
            TextColor3 = self._theme.TextSecondary
        }, 0.1)
        
        self._activeTab._container.Visible = false
    end
    
    -- Select new tab
    self._activeTab = tab
    
    tween(tab._button, {
        BackgroundColor3 = self._theme.Accent,
        TextColor3 = self._theme.Text
    }, 0.1)
    
    tab._container.Visible = true
end

function UILibrary:AddSection(tab, title)
    local section = {
        Title = title or "Section",
        _frame = nil,
        _content = nil
    }
    
    -- Create section frame
    section._frame = create("Frame", {
        Name = "Section",
        BackgroundColor3 = self._theme.Foreground,
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab._container
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = section._frame
    })
    
    create("UIStroke", {
        Color = self._theme.Accent,
        Thickness = 1,
        Parent = section._frame
    })
    
    -- Section title
    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, self._textSize * self._textSizeMultiplier),
        Font = self._font,
        Text = section.Title,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section._frame
    })
    
    -- Section content
    section._content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, titleLabel.Size.Y.Offset + 16),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = section._frame
    })
    
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = section._content
    })
    
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        Parent = section._content
    })
    
    -- Add to tab's sections
    table.insert(tab.Sections, section)
    
    return section
end

-- Component: Button
function UILibrary:AddButton(section, text, callback)
    local button = {
        Text = text or "Button",
        Callback = callback or function() end,
        _button = nil
    }
    
    -- Create button
    button._button = create("TextButton", {
        Name = "Button",
        BackgroundColor3 = self._theme.Accent,
        Size = UDim2.new(1, 0, 0, 32),
        Font = self._font,
        Text = button.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        Parent = section._content
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = button._button
    })
    
    -- Button events
    button._button.MouseButton1Click:Connect(function()
        button.Callback()
        
        -- Visual feedback
        tween(button._button, {Size = UDim2.new(1, -4, 0, 28)}, 0.05)
        tween(button._button, {Size = UDim2.new(1, 0, 0, 32)}, 0.05, nil, nil, 0.05)
    end)
    
    -- Hover effects
    button._button.MouseEnter:Connect(function()
        tween(button._button, {BackgroundColor3 = Color3.new(
            math.min(self._theme.Accent.R * 1.2, 1),
            math.min(self._theme.Accent.G * 1.2, 1),
            math.min(self._theme.Accent.B * 1.2, 1)
        )}, 0.1)
    end)
    
    button._button.MouseLeave:Connect(function()
        tween(button._button, {BackgroundColor3 = self._theme.Accent}, 0.1)
    end)
    
    -- Touch feedback for mobile
    if isMobile() then
        button._button.TouchTap:Connect(function()
            tween(button._button, {BackgroundColor3 = Color3.new(
                math.min(self._theme.Accent.R * 1.3, 1),
                math.min(self._theme.Accent.G * 1.3, 1),
                math.min(self._theme.Accent.B * 1.3, 1)
            )}, 0.1)
            tween(button._button, {BackgroundColor3 = self._theme.Accent}, 0.1, nil, nil, 0.1)
        end)
    end
    
    return button
end

-- Component: Toggle
function UILibrary:AddToggle(section, text, defaultValue, callback)
    local toggle = {
        Text = text or "Toggle",
        Value = defaultValue or false,
        Callback = callback or function() end,
        _frame = nil,
        _button = nil,
        _indicator = nil
    }
    
    -- Create toggle container
    toggle._frame = create("Frame", {
        Name = "Toggle",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = section._content
    })
    
    -- Toggle label
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -48, 1, 0),
        Font = self._font,
        Text = toggle.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggle._frame
    })
    
    -- Toggle button
    toggle._button = create("TextButton", {
        Name = "ToggleButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Parent = toggle._frame
    })
    
    -- Toggle background
    local bg = create("Frame", {
        Name = "Background",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(0, 0, 0.5, -10),
        Size = UDim2.new(1, 0, 0, 20),
        AnchorPoint = Vector2.new(0, 0.5),
        Parent = toggle._button
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = bg
    })
    
    -- Toggle indicator
    toggle._indicator = create("Frame", {
        Name = "Indicator",
        BackgroundColor3 = self._theme.TextSecondary,
        Position = UDim2.new(0, 2, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0, 0.5),
        Parent = bg
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = toggle._indicator
    })
    
    -- Update visual state
    local function updateState()
        if toggle.Value then
            tween(toggle._indicator, {
                Position = UDim2.new(1, -18, 0.5, -8),
                BackgroundColor3 = self._theme.Accent
            }, 0.1)
            tween(bg, {BackgroundColor3 = Color3.new(
                self._theme.Accent.R * 0.3,
                self._theme.Accent.G * 0.3,
                self._theme.Accent.B * 0.3
            )}, 0.1)
        else
            tween(toggle._indicator, {
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = self._theme.TextSecondary
            }, 0.1)
            tween(bg, {BackgroundColor3 = self._theme.Foreground}, 0.1)
        end
    end
    
    -- Initial state
    updateState()
    
    -- Toggle click event
    toggle._button.MouseButton1Click:Connect(function()
        toggle.Value = not toggle.Value
        toggle.Callback(toggle.Value)
        updateState()
        
        -- Visual feedback
        tween(toggle._indicator, {Size = UDim2.new(0, 12, 0, 12)}, 0.05)
        tween(toggle._indicator, {Size = UDim2.new(0, 16, 0, 16)}, 0.05, nil, nil, 0.05)
    end)
    
    -- Hover effects
    toggle._button.MouseEnter:Connect(function()
        tween(toggle._indicator, {Size = UDim2.new(0, 18, 0, 18)}, 0.1)
    end)
    
    toggle._button.MouseLeave:Connect(function()
        tween(toggle._indicator, {Size = UDim2.new(0, 16, 0, 16)}, 0.1)
    end)
    
    return toggle
end

-- Component: Slider
function UILibrary:AddSlider(section, text, minValue, maxValue, defaultValue, callback, decimalPlaces)
    local slider = {
        Text = text or "Slider",
        Min = minValue or 0,
        Max = maxValue or 100,
        Value = defaultValue or minValue or 0,
        Callback = callback or function() end,
        DecimalPlaces = decimalPlaces or 0,
        _frame = nil,
        _track = nil,
        _fill = nil,
        _handle = nil,
        _dragging = false
    }
    
    -- Create slider container
    slider._frame = create("Frame", {
        Name = "Slider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = section._content
    })
    
    -- Slider label
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = self._font,
        Text = slider.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = slider._frame
    })
    
    -- Value display
    local valueLabel = create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -80, 0, 0),
        Size = UDim2.new(0, 80, 0, 20),
        Font = self._font,
        Text = tostring(slider.Value),
        TextColor3 = self._theme.TextSecondary,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = slider._frame
    })
    
    -- Slider track
    slider._track = create("Frame", {
        Name = "Track",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 0, 4),
        Parent = slider._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = slider._track
    })
    
    -- Slider fill
    slider._fill = create("Frame", {
        Name = "Fill",
        BackgroundColor3 = self._theme.Accent,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        Parent = slider._track
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = slider._fill
    })
    
    -- Slider handle
    slider._handle = create("Frame", {
        Name = "Handle",
        BackgroundColor3 = self._theme.Text,
        Position = UDim2.new(0, -8, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = slider._track
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = slider._handle
    })
    
    -- Update slider position based on value
    local function updateSlider()
        local percent = (slider.Value - slider.Min) / (slider.Max - slider.Min)
        local fillWidth = math.clamp(percent, 0, 1) * slider._track.AbsoluteSize.X
        
        slider._fill.Size = UDim2.new(0, fillWidth, 1, 0)
        slider._handle.Position = UDim2.new(0, fillWidth, 0.5, 0)
        
        -- Update value display
        valueLabel.Text = tostring(round(slider.Value, slider.DecimalPlaces))
    end
    
    -- Set value programmatically
    function slider:SetValue(value, noCallback)
        self.Value = math.clamp(round(value, self.DecimalPlaces), self.Min, self.Max)
        updateSlider()
        
        if not noCallback then
            self.Callback(self.Value)
        end
    end
    
    -- Initial update
    updateSlider()
    
    -- Slider interaction
    local function getSliderValue(xPosition)
        local relativeX = xPosition - slider._track.AbsolutePosition.X
        local percent = math.clamp(relativeX / slider._track.AbsoluteSize.X, 0, 1)
        local value = slider.Min + (slider.Max - slider.Min) * percent
        return round(value, slider.DecimalPlaces)
    end
    
    slider._track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            slider._dragging = true
            slider:SetValue(getSliderValue(input.Position.X))
            
            -- Visual feedback
            tween(slider._handle, {Size = UDim2.new(0, 20, 0, 20)}, 0.1)
        end
    end)
    
    slider._track.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and slider._dragging then
            slider._dragging = false
            tween(slider._handle, {Size = UDim2.new(0, 16, 0, 16)}, 0.1)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if slider._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            slider:SetValue(getSliderValue(input.Position.X))
        end
    end)
    
    return slider
end

-- Component: Dropdown
function UILibrary:AddDropdown(section, text, options, defaultOption, callback)
    local dropdown = {
        Text = text or "Dropdown",
        Options = options or {"Option 1", "Option 2", "Option 3"},
        Selected = defaultOption or options[1],
        Callback = callback or function() end,
        _frame = nil,
        _button = nil,
        _list = nil,
        _isOpen = false
    }
    
    -- Create dropdown container
    dropdown._frame = create("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = section._content
    })
    
    -- Dropdown button
    dropdown._button = create("TextButton", {
        Name = "DropdownButton",
        BackgroundColor3 = self._theme.Foreground,
        Size = UDim2.new(1, 0, 0, 32),
        Font = self._font,
        Text = dropdown.Text .. ": " .. dropdown.Selected,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdown._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = dropdown._button
    })
    
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = dropdown._button
    })
    
    -- Dropdown arrow
    local arrow = create("TextLabel", {
        Name = "Arrow",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Enum.Font.SourceSansBold,
        Text = "▼",
        TextColor3 = self._theme.TextSecondary,
        TextSize = self._textSize * self._textSizeMultiplier,
        Parent = dropdown._button
    })
    
    -- Dropdown list
    dropdown._list = create("ScrollingFrame", {
        Name = "DropdownList",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self._theme.Accent,
        Visible = false,
        Parent = dropdown._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = dropdown._list
    })
    
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = dropdown._list
    })
    
    -- Create option buttons
    local function createOptions()
        -- Clear existing options
        for _, child in ipairs(dropdown._list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Create new options
        local totalHeight = 0
        for i, option in ipairs(dropdown.Options) do
            local optionButton = create("TextButton", {
                Name = "Option",
                BackgroundColor3 = self._theme.Foreground,
                Size = UDim2.new(1, 0, 0, 32),
                Font = self._font,
                Text = option,
                TextColor3 = self._theme.Text,
                TextSize = self._textSize * self._textSizeMultiplier,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i,
                Parent = dropdown._list
            })
            
            create("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                Parent = optionButton
            })
            
            -- Highlight if selected
            if option == dropdown.Selected then
                optionButton.BackgroundColor3 = Color3.new(
                    self._theme.Accent.R * 0.2,
                    self._theme.Accent.G * 0.2,
                    self._theme.Accent.B * 0.2
                )
            end
            
            -- Option click event
            optionButton.MouseButton1Click:Connect(function()
                dropdown.Selected = option
                dropdown.Callback(option)
                dropdown._button.Text = dropdown.Text .. ": " .. option
                dropdown:Toggle()
                
                -- Update all option highlights
                for _, child in ipairs(dropdown._list:GetChildren()) do
                    if child:IsA("TextButton") then
                        if child.Text == option then
                            tween(child, {
                                BackgroundColor3 = Color3.new(
                                    self._theme.Accent.R * 0.2,
                                    self._theme.Accent.G * 0.2,
                                    self._theme.Accent.B * 0.2
                                )
                            }, 0.1)
                        else
                            tween(child, {
                                BackgroundColor3 = self._theme.Foreground
                            }, 0.1)
                        end
                    end
                end
            end)
            
            -- Hover effects
            optionButton.MouseEnter:Connect(function()
                if option ~= dropdown.Selected then
                    tween(optionButton, {
                        BackgroundColor3 = Color3.new(
                            self._theme.Foreground.R * 1.1,
                            self._theme.Foreground.G * 1.1,
                            self._theme.Foreground.B * 1.1
                        )
                    }, 0.1)
                end
            end)
            
            optionButton.MouseLeave:Connect(function()
                if option ~= dropdown.Selected then
                    tween(optionButton, {
                        BackgroundColor3 = option == dropdown.Selected and 
                            Color3.new(
                                self._theme.Accent.R * 0.2,
                                self._theme.Accent.G * 0.2,
                                self._theme.Accent.B * 0.2
                            ) or self._theme.Foreground
                    }, 0.1)
                end
            end)
            
            totalHeight = totalHeight + 32
        end
        
        -- Set list size
        local maxHeight = math.min(totalHeight, 160) -- Cap at 5 options
        dropdown._list.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        dropdown._list.Size = UDim2.new(1, 0, 0, maxHeight)
    end
    
    -- Create initial options
    createOptions()
    
    -- Toggle dropdown
    function dropdown:Toggle()
        self._isOpen = not self._isOpen
        
        if self._isOpen then
            self._list.Visible = true
            tween(arrow, {Rotation = 180}, 0.1)
            tween(self._list, {Size = UDim2.new(1, 0, 0, math.min(#self.Options * 32, 160))}, 0.1)
        else
            tween(arrow, {Rotation = 0}, 0.1)
            tween(self._list, {Size = UDim2.new(1, 0, 0, 0)}, 0.1, nil, nil, function()
                self._list.Visible = false
            end)
        end
    end
    
    -- Button click event
    dropdown._button.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    -- Close dropdown when clicking outside
    local function onInputBegan(input)
        if dropdown._isOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local buttonPos = dropdown._button.AbsolutePosition
            local buttonSize = dropdown._button.AbsoluteSize
            local listPos = dropdown._list.AbsolutePosition
            local listSize = dropdown._list.AbsoluteSize
            
            local mousePos = input.Position
            local inButton = mousePos.X >= buttonPos.X and mousePos.X <= buttonPos.X + buttonSize.X and
                            mousePos.Y >= buttonPos.Y and mousePos.Y <= buttonPos.Y + buttonSize.Y
            local inList = mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
                          mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y
            
            if not inButton and not inList then
                dropdown:Toggle()
            end
        end
    end
    
    UserInputService.InputBegan:Connect(onInputBegan)
    
    -- Update options
    function dropdown:SetOptions(newOptions, newDefault)
        self.Options = newOptions or self.Options
        self.Selected = newDefault or self.Options[1]
        self._button.Text = self.Text .. ": " .. self.Selected
        createOptions()
    end
    
    return dropdown
end

-- Component: Textbox
function UILibrary:AddTextbox(section, text, placeholder, callback, isPassword)
    local textbox = {
        Text = text or "Textbox",
        Placeholder = placeholder or "Enter text...",
        Value = "",
        Callback = callback or function() end,
        IsPassword = isPassword or false,
        _frame = nil,
        _input = nil
    }
    
    -- Create textbox container
    textbox._frame = create("Frame", {
        Name = "Textbox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = section._content
    })
    
    -- Textbox label
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        Font = self._font,
        Text = textbox.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = textbox._frame
    })
    
    -- Input frame
    local inputFrame = create("Frame", {
        Name = "InputFrame",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 24),
        Parent = textbox._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = inputFrame
    })
    
    -- Actual text input
    textbox._input = create("TextBox", {
        Name = "Input",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = self._font,
        PlaceholderText = textbox.Placeholder,
        PlaceholderColor3 = self._theme.TextSecondary,
        Text = "",
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputFrame
    })
    
    -- Password masking
    if textbox.IsPassword then
        textbox._input.TextTransparency = 1
        local maskedText = create("TextLabel", {
            Name = "MaskedText",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Font = self._font,
            Text = "",
            TextColor3 = self._theme.Text,
            TextSize = self._textSize * self._textSizeMultiplier,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = inputFrame
        })
        
        textbox._input:GetPropertyChangedSignal("Text"):Connect(function()
            textbox.Value = textbox._input.Text
            maskedText.Text = string.rep("•", #textbox._input.Text)
            textbox.Callback(textbox.Value)
        end)
    else
        textbox._input:GetPropertyChangedSignal("Text"):Connect(function()
            textbox.Value = textbox._input.Text
            textbox.Callback(textbox.Value)
        end)
    end
    
    -- Focus effects
    textbox._input.Focused:Connect(function()
        tween(inputFrame, {
            BackgroundColor3 = Color3.new(
                self._theme.Foreground.R * 1.1,
                self._theme.Foreground.G * 1.1,
                self._theme.Foreground.B * 1.1
            )
        }, 0.1)
    end)
    
    textbox._input.FocusLost:Connect(function()
        tween(inputFrame, {BackgroundColor3 = self._theme.Foreground}, 0.1)
    end)
    
    -- Set value programmatically
    function textbox:SetValue(value, noCallback)
        self.Value = value or ""
        self._input.Text = self.Value
        
        if not noCallback then
            self.Callback(self.Value)
        end
    end
    
    return textbox
end

-- Component: Label
function UILibrary:AddLabel(section, text, isDivider)
    local label = {
        Text = text or "Label",
        IsDivider = isDivider or false,
        _label = nil
    }
    
    if label.IsDivider then
        -- Divider label
        label._frame = create("Frame", {
            Name = "Divider",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            Parent = section._content
        })
        
        -- Divider line
        local line = create("Frame", {
            Name = "Line",
            BackgroundColor3 = self._theme.TextSecondary,
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            AnchorPoint = Vector2.new(0, 0.5),
            Parent = label._frame
        })
        
        -- Divider text
        label._label = create("TextLabel", {
            Name = "Label",
            BackgroundColor3 = self._theme.Background,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Font = self._font,
            Text = label.Text,
            TextColor3 = self._theme.Text,
            TextSize = self._textSize * self._textSizeMultiplier,
            Parent = label._frame
        })
        
        -- Auto-size the text
        local textSize = TextService:GetTextSize(label.Text, label._label.TextSize, label._label.Font, Vector2.new(1000, 20))
        label._label.Size = UDim2.new(0, textSize.X + 12, 0, 20)
    else
        -- Regular label
        label._label = create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = self._font,
            Text = label.Text,
            TextColor3 = self._theme.Text,
            TextSize = self._textSize * self._textSizeMultiplier,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section._content
        })
    end
    
    -- Update text
    function label:SetText(newText)
        self.Text = newText or self.Text
        self._label.Text = self.Text
        
        if self.IsDivider then
            local textSize = TextService:GetTextSize(self.Text, self._label.TextSize, self._label.Font, Vector2.new(1000, 20))
            self._label.Size = UDim2.new(0, textSize.X + 12, 0, 20)
        end
    end
    
    return label
end

-- Component: Keybind
function UILibrary:AddKeybind(section, text, defaultKey, callback)
    local keybind = {
        Text = text or "Keybind",
        Key = defaultKey or Enum.KeyCode.Unknown,
        Callback = callback or function() end,
        _frame = nil,
        _button = nil,
        _listening = false
    }
    
    -- Create keybind container
    keybind._frame = create("Frame", {
        Name = "Keybind",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = section._content
    })
    
    -- Keybind label
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -80, 1, 0),
        Font = self._font,
        Text = keybind.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = keybind._frame
    })
    
    -- Keybind button
    keybind._button = create("TextButton", {
        Name = "KeybindButton",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(1, -80, 0, 0),
        Size = UDim2.new(0, 80, 1, 0),
        Font = self._font,
        Text = tostring(keybind.Key):gsub("Enum.KeyCode.", ""),
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        Parent = keybind._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = keybind._button
    })
    
    -- Button click event
    keybind._button.MouseButton1Click:Connect(function()
        keybind._listening = true
        keybind._button.Text = "..."
        keybind._button.BackgroundColor3 = Color3.new(
            self._theme.Accent.R * 0.3,
            self._theme.Accent.G * 0.3,
            self._theme.Accent.B * 0.3
        )
    end)
    
    -- Key input listener
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not keybind._listening or gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            keybind.Key = input.KeyCode
            keybind._button.Text = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            keybind._listening = false
            keybind._button.BackgroundColor3 = self._theme.Foreground
            keybind.Callback(keybind.Key)
            connection:Disconnect()
        end
    end)
    
    -- Set key programmatically
    function keybind:SetKey(key, noCallback)
        self.Key = key or self.Key
        self._button.Text = tostring(self.Key):gsub("Enum.KeyCode.", "")
        
        if not noCallback then
            self.Callback(self.Key)
        end
    end
    
    return keybind
end

-- Component: Color Picker
function UILibrary:AddColorPicker(section, text, defaultColor, callback, showAlpha)
    local colorPicker = {
        Text = text or "Color",
        Color = defaultColor or Color3.fromRGB(255, 255, 255),
        Alpha = showAlpha and 1 or nil,
        Callback = callback or function() end,
        _frame = nil,
        _preview = nil,
        _pickerFrame = nil,
        _isOpen = false
    }
    
    -- Create color picker container
    colorPicker._frame = create("Frame", {
        Name = "ColorPicker",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = section._content
    })
    
    -- Color picker label
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -48, 1, 0),
        Font = self._font,
        Text = colorPicker.Text,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = colorPicker._frame
    })
    
    -- Color preview
    colorPicker._preview = create("TextButton", {
        Name = "Preview",
        BackgroundColor3 = colorPicker.Color,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Text = "",
        Parent = colorPicker._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorPicker._preview
    })
    
    create("UIStroke", {
        Color = self._theme.TextSecondary,
        Thickness = 1,
        Parent = colorPicker._preview
    })
    
    -- Color picker frame
    colorPicker._pickerFrame = create("Frame", {
        Name = "ColorPickerFrame",
        BackgroundColor3 = self._theme.Background,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, showAlpha and 200 or 170),
        Visible = false,
        Parent = colorPicker._frame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = colorPicker._pickerFrame
    })
    
    create("UIStroke", {
        Color = self._theme.Accent,
        Thickness = 1,
        Parent = colorPicker._pickerFrame
    })
    
    -- Color spectrum
    local spectrum = create("ImageLabel", {
        Name = "Spectrum",
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 120),
        Parent = colorPicker._pickerFrame
    })
    
    -- Create gradient for spectrum
    local uigradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }),
        Rotation = 90,
        Parent = spectrum
    })
    
    local uigradient2 = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }),
        Parent = spectrum
    })
    
    -- Brightness slider
    local brightnessSlider = create("Frame", {
        Name = "BrightnessSlider",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 8, 0, 136),
        Size = UDim2.new(1, -16, 0, 10),
        Parent = colorPicker._pickerFrame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = brightnessSlider
    })
    
    local brightnessGradient = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        }),
        Parent = brightnessSlider
    })
    
    local brightnessHandle = create("Frame", {
        Name = "Handle",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0.5, -6, 0, -3),
        Size = UDim2.new(0, 12, 0, 16),
        Parent = brightnessSlider
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = brightnessHandle
    })
    
    create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Parent = brightnessHandle
    })
    
    -- Alpha slider (if enabled)
    local alphaSlider, alphaHandle
    if showAlpha then
        alphaSlider = create("Frame", {
            Name = "AlphaSlider",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(0, 8, 0, 154),
            Size = UDim2.new(1, -16, 0, 10),
            Parent = colorPicker._pickerFrame
        })
        
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = alphaSlider
        })
        
        -- Create checkerboard pattern for alpha
        local patternSize = 4
        local pattern = create("Frame", {
            Name = "Pattern",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = alphaSlider
        })
        
        for i = 0, math.ceil(alphaSlider.AbsoluteSize.X / patternSize) do
            for j = 0, math.ceil(alphaSlider.AbsoluteSize.Y / patternSize) do
                if (i + j) % 2 == 0 then
                    create("Frame", {
                        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                        Position = UDim2.new(0, i * patternSize, 0, j * patternSize),
                        Size = UDim2.new(0, patternSize, 0, patternSize),
                        Parent = pattern
                    })
                end
            end
        end
        
        local alphaGradient = create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            }),
            Parent = alphaSlider
        })
        
        alphaHandle = create("Frame", {
            Name = "Handle",
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new(colorPicker.Alpha or 1, -6, 0, -3),
            Size = UDim2.new(0, 12, 0, 16),
            Parent = alphaSlider
        })
        
        create("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = alphaHandle
        })
        
        create("UIStroke", {
            Color = Color3.fromRGB(0, 0, 0),
            Thickness = 1,
            Parent = alphaHandle
        })
    end
    
    -- Hex input
    local hexInput = create("TextBox", {
        Name = "HexInput",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(0, 8, 0, showAlpha and 172 or 154),
        Size = UDim2.new(1, -16, 0, 20),
        Font = self._font,
        PlaceholderText = "Hex Color",
        PlaceholderColor3 = self._theme.TextSecondary,
        Text = Color3.toHex(colorPicker.Color),
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        Parent = colorPicker._pickerFrame
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = hexInput
    })
    
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = hexInput
    })
    
    -- Current color values
    local h, s, v = colorPicker.Color:ToHSV()
    local brightness = v
    
    -- Update color function
    local function updateColor(newH, newS, newV, newAlpha)
        h = newH or h
        s = newS or s
        v = newV or v
        brightness = v
        
        local newColor = Color3.fromHSV(h, s, v)
        colorPicker.Color = newColor
        
        if newAlpha then
            colorPicker.Alpha = newAlpha
        end
        
        -- Update preview
        colorPicker._preview.BackgroundColor3 = newColor
        
        -- Update hex input
        hexInput.Text = Color3.toHex(newColor)
        
        -- Call callback
        if showAlpha then
            colorPicker.Callback(newColor, colorPicker.Alpha)
        else
            colorPicker.Callback(newColor)
        end
    end
    
    -- Spectrum interaction
    local spectrumDragging = false
    spectrum.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            spectrumDragging = true
            
            local relativeX = (input.Position.X - spectrum.AbsolutePosition.X) / spectrum.AbsoluteSize.X
            local relativeY = (input.Position.Y - spectrum.AbsolutePosition.Y) / spectrum.AbsoluteSize.Y
            
            h = math.clamp(relativeX, 0, 1)
            s = 1 - math.clamp(relativeY, 0, 1)
            updateColor()
        end
    end)
    
    spectrum.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            spectrumDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if spectrumDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = (input.Position.X - spectrum.AbsolutePosition.X) / spectrum.AbsoluteSize.X
            local relativeY = (input.Position.Y - spectrum.AbsolutePosition.Y) / spectrum.AbsoluteSize.Y
            
            h = math.clamp(relativeX, 0, 1)
            s = 1 - math.clamp(relativeY, 0, 1)
            updateColor()
        end
    end)
    
    -- Brightness slider interaction
    local brightnessDragging = false
    brightnessSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            brightnessDragging = true
            
            local relativeX = (input.Position.X - brightnessSlider.AbsolutePosition.X) / brightnessSlider.AbsoluteSize.X
            v = math.clamp(relativeX, 0, 1)
            brightnessHandle.Position = UDim2.new(v, -6, 0, -3)
            updateColor(nil, nil, v)
        end
    end)
    
    brightnessSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            brightnessDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if brightnessDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local relativeX = (input.Position.X - brightnessSlider.AbsolutePosition.X) / brightnessSlider.AbsoluteSize.X
            v = math.clamp(relativeX, 0, 1)
            brightnessHandle.Position = UDim2.new(v, -6, 0, -3)
            updateColor(nil, nil, v)
        end
    end)
    
    -- Alpha slider interaction (if enabled)
    if showAlpha then
        local alphaDragging = false
        alphaSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                alphaDragging = true
                
                local relativeX = (input.Position.X - alphaSlider.AbsolutePosition.X) / alphaSlider.AbsoluteSize.X
                local alpha = math.clamp(relativeX, 0, 1)
                alphaHandle.Position = UDim2.new(alpha, -6, 0, -3)
                updateColor(nil, nil, nil, alpha)
            end
        end)
        
        alphaSlider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                alphaDragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if alphaDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local relativeX = (input.Position.X - alphaSlider.AbsolutePosition.X) / alphaSlider.AbsoluteSize.X
                local alpha = math.clamp(relativeX, 0, 1)
                alphaHandle.Position = UDim2.new(alpha, -6, 0, -3)
                updateColor(nil, nil, nil, alpha)
            end
        end)
    end
    
    -- Hex input handler
    hexInput.FocusLost:Connect(function()
        local text = hexInput.Text
        if string.match(text, "^#?[0-9a-fA-F]+$") then
            text = text:gsub("#", "")
            if #text == 3 then
                -- Expand shorthand hex (e.g. #FFF -> #FFFFFF)
                text = text:gsub("(.)(.)(.)", "%1%1%2%2%3%3")
            end
            
            if #text == 6 then
                local r = tonumber(text:sub(1, 2), 16) / 255
                local g = tonumber(text:sub(3, 4), 16) / 255
                local b = tonumber(text:sub(5, 6), 16) / 255
                
                local newColor = Color3.new(r, g, b)
                h, s, v = newColor:ToHSV()
                updateColor(h, s, v)
                
                -- Update brightness slider
                brightnessHandle.Position = UDim2.new(v, -6, 0, -3)
            end
        else
            hexInput.Text = Color3.toHex(colorPicker.Color)
        end
    end)
    
    -- Toggle color picker
    function colorPicker:Toggle()
        self._isOpen = not self._isOpen
        self._pickerFrame.Visible = self._isOpen
        
        -- Update section size
        section._frame.Size = UDim2.new(1, -16, 0, self._isOpen and (showAlpha and 240 or 220) or 32)
    end
    
    -- Preview click event
    colorPicker._preview.MouseButton1Click:Connect(function()
        colorPicker:Toggle()
    end)
    
    -- Set color programmatically
    function colorPicker:SetColor(color, alpha, noCallback)
        if not color then return end
        
        h, s, v = color:ToHSV()
        self.Color = color
        self._preview.BackgroundColor3 = color
        
        -- Update brightness slider
        brightnessHandle.Position = UDim2.new(v, -6, 0, -3)
        
        -- Update alpha slider if enabled
        if showAlpha and alpha then
            self.Alpha = alpha
            if alphaHandle then
                alphaHandle.Position = UDim2.new(alpha, -6, 0, -3)
            end
        end
        
        -- Update hex input
        hexInput.Text = Color3.toHex(color)
        
        if not noCallback then
            if showAlpha then
                self.Callback(color, self.Alpha)
            else
                self.Callback(color)
            end
        end
    end
    
    return colorPicker
end

-- Component: Notification
function UILibrary:Notify(title, message, duration, callback)
    local notification = {
        Title = title or "Notification",
        Message = message or "",
        Duration = duration or 5,
        Callback = callback or function() end,
        _frame = nil
    }
    
    -- Create notification frame
    notification._frame = create("Frame", {
        Name = "Notification",
        BackgroundColor3 = self._theme.Foreground,
        Position = UDim2.new(1, 10, 1, -10),
        Size = UDim2.new(0, 300, 0, 0),
        AnchorPoint = Vector2.new(1, 1),
        Parent = self._notificationHolder
    })
    
    create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = notification._frame
    })
    
    create("UIStroke", {
        Color = self._theme.Accent,
        Thickness = 1,
        Parent = notification._frame
    })
    
    -- Title label
    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 20),
        Font = self._font,
        Text = notification.Title,
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notification._frame
    })
    
    -- Message label
    local messageLabel = create("TextLabel", {
        Name = "Message",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 32),
        Size = UDim2.new(1, -24, 1, -40),
        Font = self._font,
        Text = notification.Message,
        TextColor3 = self._theme.TextSecondary,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = notification._frame
    })
    
    -- Calculate required height
    local textSize = TextService:GetTextSize(
        notification.Message,
        messageLabel.TextSize,
        messageLabel.Font,
        Vector2.new(messageLabel.AbsoluteSize.X, 1000)
    )
    
    local height = math.min(textSize.Y + 48, 200) -- Cap at 200 pixels
    notification._frame.Size = UDim2.new(0, 300, 0, height)
    
    -- Animate in
    notification._frame.Position = UDim2.new(1, 10, 1, height + 10)
    tween(notification._frame, {Position = UDim2.new(1, 10, 1, -10)}, 0.2)
    
    -- Close button
    local closeButton = create("TextButton", {
        Name = "CloseButton",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -32, 0, 0),
        Size = UDim2.new(0, 32, 0, 32),
        Font = Enum.Font.SourceSansBold,
        Text = "×",
        TextColor3 = self._theme.Text,
        TextSize = self._textSize * self._textSizeMultiplier * 1.5,
        Parent = notification._frame
    })
    
    -- Close function
    local function close()
        tween(notification._frame, {
            Position = UDim2.new(1, 10, 1, notification._frame.AbsoluteSize.Y + 10),
            Size = UDim2.new(0, 300, 0, 0)
        }, 0.2, nil, nil, function()
            notification._frame:Destroy()
        end)
        
        notification.Callback()
    end
    
    -- Close button event
    closeButton.MouseButton1Click:Connect(close)
    
    -- Notification click event
    notification._frame.MouseButton1Click:Connect(function()
        if notification.Callback then
            notification.Callback()
        end
        close()
    end)
    
    -- Auto-close after duration
    if notification.Duration > 0 then
        delay(notification.Duration, function()
            if notification._frame and notification._frame.Parent then
                close()
            end
        end)
    end
    
    -- Add to notifications table
    table.insert(self._notifications, notification)
    
    return notification
end

-- Component: Paragraph
function UILibrary:AddParagraph(section, title, text)
    local paragraph = {
        Title = title or "",
        Text = text or "",
        _frame = nil
    }
    
    -- Create paragraph container
    paragraph._frame = create("Frame", {
        Name = "Paragraph",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = section._content
    })
    
    -- Title label
    if paragraph.Title ~= "" then
        local titleLabel = create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Font = self._font,
            Text = paragraph.Title,
            TextColor3 = self._theme.Text,
            TextSize = self._textSize * self._textSizeMultiplier,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = paragraph._frame
        })
    end
    
    -- Text label
    local textLabel = create("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, paragraph.Title ~= "" and 24 or 0),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = self._font,
        Text = paragraph.Text,
        TextColor3 = self._theme.TextSecondary,
        TextSize = self._textSize * self._textSizeMultiplier,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = paragraph._frame
    })
    
    -- Update text
    function paragraph:SetText(newTitle, newText)
        self.Title = newTitle or self.Title
        self.Text = newText or self.Text
        
        if self.Title ~= "" then
            paragraph._frame:FindFirstChild("Title").Text = self.Title
        end
        
        textLabel.Text = self.Text
        textLabel.Position = UDim2.new(0, 0, 0, self.Title ~= "" and 24 or 0)
    end
    
    return paragraph
end

-- Library theming and settings
function UILibrary:SetTheme(theme)
    self._theme = setmetatable(theme or {}, {__index = self._theme})
    
    -- Update all windows and components
    for _, window in pairs(self._windows) do
        if window and window._mainFrame then
            -- Update window colors
            window._mainFrame.BackgroundColor3 = self._theme.Background
            window._titleBar.BackgroundColor3 = self._theme.Foreground
            window._titleLabel.TextColor3 = self._theme.Text
            window._closeButton.TextColor3 = self._theme.Text
            window._tabContainer.BackgroundColor3 = self._theme.Foreground
            window._contentFrame.BackgroundColor3 = self._theme.Background
            
            -- Update title bar stroke
            if window._titleBar:FindFirstChild("TitleBarStroke") then
                window._titleBar.TitleBarStroke.Color = self._theme.Accent
            end
            
            -- Update tab container stroke
            if window._tabContainer:FindFirstChild("UIStroke") then
                window._tabContainer.UIStroke.Color = self._theme.Accent
            end
            
            -- Update all tabs
            for _, tab in pairs(window._tabs) do
                if tab._button then
                    if tab == window._activeTab then
                        tab._button.BackgroundColor3 = self._theme.Accent
                        tab._button.TextColor3 = self._theme.Text
                    else
                        tab._button.BackgroundColor3 = self._theme.Foreground
                        tab._button.TextColor3 = self._theme.TextSecondary
                    end
                end
                
                -- Update all sections in tab
                for _, section in pairs(tab.Sections) do
                    if section._frame then
                        section._frame.BackgroundColor3 = self._theme.Foreground
                        
                        if section._frame:FindFirstChild("Title") then
                            section._frame.Title.TextColor3 = self._theme.Text
                        end
                        
                        if section._frame:FindFirstChild("UIStroke") then
                            section._frame.UIStroke.Color = self._theme.Accent
                        end
                        
                        -- Update all components in section
                        for _, component in pairs(section._content:GetChildren()) do
                            if component:IsA("TextButton") then
                                if component.Name == "Button" then
                                    component.BackgroundColor3 = self._theme.Accent
                                    component.TextColor3 = self._theme.Text
                                elseif component.Name == "Option" then
                                    if component.Text == window._activeTab.Selected then
                                        component.BackgroundColor3 = Color3.new(
                                            self._theme.Accent.R * 0.2,
                                            self._theme.Accent.G * 0.2,
                                            self._theme.Accent.B * 0.2
                                        )
                                    else
                                        component.BackgroundColor3 = self._theme.Foreground
                                    end
                                    component.TextColor3 = self._theme.Text
                                end
                            elseif component:IsA("TextBox") then
                                component.TextColor3 = self._theme.Text
                                component.PlaceholderColor3 = self._theme.TextSecondary
                            elseif component:IsA("TextLabel") then
                                component.TextColor3 = component.Name == "Label" and self._theme.Text or self._theme.TextSecondary
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Update all notifications
    for _, notification in pairs(self._notifications) do
        if notification._frame then
            notification._frame.BackgroundColor3 = self._theme.Foreground
            notification._frame.UIStroke.Color = self._theme.Accent
            
            if notification._frame:FindFirstChild("Title") then
                notification._frame.Title.TextColor3 = self._theme.Text
            end
            
            if notification._frame:FindFirstChild("Message") then
                notification._frame.Message.TextColor3 = self._theme.TextSecondary
            end
            
            if notification._frame:FindFirstChild("CloseButton") then
                notification._frame.CloseButton.TextColor3 = self._theme.Text
            end
        end
    end
end

function UILibrary:SetFont(font)
    self._font = font or DEFAULT_FONT
    
    -- Update all text elements
    for _, window in pairs(self._windows) do
        if window and window._mainFrame then
            window._titleLabel.Font = self._font
            window._closeButton.Font = self._font
            
            for _, tab in pairs(window._tabs) do
                if tab._button then
                    tab._button.Font = self._font
                end
                
                for _, section in pairs(tab.Sections) do
                    if section._frame then
                        if section._frame:FindFirstChild("Title") then
                            section._frame.Title.Font = self._font
                        end
                        
                        for _, component in pairs(section._content:GetChildren()) do
                            if component:IsA("TextButton") or component:IsA("TextBox") or component:IsA("TextLabel") then
                                component.Font = self._font
                            end
                        end
                    end
                end
            end
        end
    end
end

function UILibrary:SetTextSize(size)
    self._textSize = size or DEFAULT_TEXT_SIZE
    
    -- Update all text elements
    for _, window in pairs(self._windows) do
        if window and window._mainFrame then
            window._titleLabel.TextSize = self._textSize * self._textSizeMultiplier
            window._closeButton.TextSize = self._textSize * self._textSizeMultiplier * 1.5
            
            for _, tab in pairs(window._tabs) do
                if tab._button then
                    tab._button.TextSize = self._textSize * self._textSizeMultiplier
                end
                
                for _, section in pairs(tab.Sections) do
                    if section._frame then
                        if section._frame:FindFirstChild("Title") then
                            section._frame.Title.TextSize = self._textSize * self._textSizeMultiplier
                        end
                        
                        for _, component in pairs(section._content:GetChildren()) do
                            if component:IsA("TextButton") or component:IsA("TextBox") or component:IsA("TextLabel") then
                                if component.Name == "Arrow" then
                                    component.TextSize = self._textSize * self._textSizeMultiplier
                                else
                                    component.TextSize = self._textSize * self._textSizeMultiplier
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function UILibrary:SetTextSizeMultiplier(multiplier)
    self._textSizeMultiplier = multiplier or 1
    self:SetTextSize(self._textSize) -- Trigger text size update
end

function UILibrary:SetAnimationSpeed(speed)
    self._animationSpeed = speed or DEFAULT_ANIMATION_SPEED
end

function UILibrary:SetScale(scale)
    self._scale = scale or DEFAULT_SCALE
    self:SetupViewportScaling() -- Recalculate scaling
end

function UILibrary:Destroy()
    -- Disconnect all events
    if self._viewportConnection then
        self._viewportConnection:Disconnect()
    end
    
    -- Destroy all windows
    for _, window in pairs(self._windows) do
        if window and window._mainFrame then
            window._mainFrame:Destroy()
        end
    end
    
    -- Destroy notification holder
    if self._notificationHolder then
        self._notificationHolder:Destroy()
    end
    
    -- Destroy screen gui
    if self._screenGui then
        self._screenGui:Destroy()
    end
    
    -- Clear tables
    self._windows = {}
    self._notifications = {}
    self._components = {}
end

-- Demo function
function UILibrary:Demo()
    -- Create a window
    local window = self:CreateWindow("UI Library Demo", UDim2.new(0, 500, 0, 600))
    
    -- Add tabs
    local mainTab = window:AddTab("Main")
    local settingsTab = window:AddTab("Settings")
    local infoTab = window:AddTab("Info")
    
    -- Main tab content
    local mainSection = window:AddSection(mainTab, "Controls")
    
    -- Add a button
    window:AddButton(mainSection, "Click Me", function()
        self:Notify("Button Clicked", "You clicked the button!", 3)
    end)
    
    -- Add a toggle
    local toggle = window:AddToggle(mainSection, "Enable Feature", false, function(value)
        self:Notify("Toggle", value and "Feature enabled" or "Feature disabled", 2)
    end)
    
    -- Add a slider
    window:AddSlider(mainSection, "Volume", 0, 100, 50, function(value)
        print("Volume set to:", value)
    end)
    
    -- Add a dropdown
    local dropdown = window:AddDropdown(mainSection, "Options", {"Option 1", "Option 2", "Option 3"}, "Option 1", function(option)
        self:Notify("Dropdown", "Selected: " .. option, 2)
    end)
    
    -- Add a keybind
    window:AddKeybind(mainSection, "Toggle UI", Enum.KeyCode.RightShift, function(key)
        window:Toggle()
        self:Notify("Keybind", "UI toggled with " .. tostring(key):gsub("Enum.KeyCode.", ""), 2)
    end)
    
    -- Settings tab content
    local themeSection = window:AddSection(settingsTab, "Theme")
    
    -- Theme color pickers
    window:AddColorPicker(themeSection, "Accent Color", self._theme.Accent, function(color)
        local newTheme = table.clone(self._theme)
        newTheme.Accent = color
        self:SetTheme(newTheme)
    end)
    
    window:AddColorPicker(themeSection, "Background Color", self._theme.Background, function(color)
        local newTheme = table.clone(self._theme)
        newTheme.Background = color
        self:SetTheme(newTheme)
    end)
    
    window:AddColorPicker(themeSection, "Text Color", self._theme.Text, function(color)
        local newTheme = table.clone(self._theme)
        newTheme.Text = color
        self:SetTheme(newTheme)
    end)
    
    -- UI settings
    local uiSection = window:AddSection(settingsTab, "UI Settings")
    
    -- Font selector
    window:AddDropdown(uiSection, "Font", {"SourceSans", "Gotham", "Ubuntu"}, "SourceSans", function(font)
        local fontEnum
        if font == "SourceSans" then
            fontEnum = Enum.Font.SourceSans
        elseif font == "Gotham" then
            fontEnum = Enum.Font.Gotham
        elseif font == "Ubuntu" then
            fontEnum = Enum.Font.Ubuntu
        end
        
        self:SetFont(fontEnum)
    end)
    
    -- Text size multiplier
    window:AddSlider(uiSection, "Text Size Multiplier", 0.5, 2, 1, function(value)
        self:SetTextSizeMultiplier(value)
    end, 1)
    
    -- UI Scale
    window:AddSlider(uiSection, "UI Scale", 0.5, 2, 1, function(value)
        self:SetScale(value)
    end, 1)
    
    -- Info tab content
    local infoSection = window:AddSection(infoTab, "About")
    
    -- Add a paragraph
    window:AddParagraph(infoSection, "UI Library", "This is a comprehensive UI library for Roblox with support for multiple components, theming, and responsive design.")
    
    -- Add a divider
    window:AddLabel(infoSection, "Credits", true)
    
    -- Add another paragraph
    window:AddParagraph(infoSection, "", "Created by [Your Name]\nVersion 1.0\nBuilt with Roblox Studio")
    
    -- Add a button to show notification
    window:AddButton(infoSection, "Show Notification", function()
        self:Notify("Notification", "This is a sample notification with a message that can be clicked.", 5, function()
            print("Notification clicked!")
        end)
    end)
end

return UILibrary