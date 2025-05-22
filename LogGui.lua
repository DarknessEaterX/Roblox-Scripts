local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- Constants
local MAX_LOG_ENTRIES = 500
local FONT = Font.new("rbxasset://fonts/families/RobotoMono.json")
local COLORS = {
    Info = Color3.fromRGB(240, 240, 240),
    Warning = Color3.fromRGB(255, 220, 100),
    Error = Color3.fromRGB(255, 100, 100),
    Debug = Color3.fromRGB(100, 220, 255),
    System = Color3.fromRGB(180, 180, 255),
    Success = Color3.fromRGB(100, 255, 100),
    Critical = Color3.fromRGB(255, 50, 50),
    Verbose = Color3.fromRGB(180, 180, 180)
}

-- Log level severity
local LOG_LEVELS = {
    Verbose = 1,
    Debug = 2,
    Info = 3,
    Success = 4,
    Warning = 5,
    Error = 6,
    Critical = 7,
    System = 8
}

-- Animation settings
local ANIMATION_DURATION = 0.15
local EASE_STYLE = Enum.EasingStyle.Quad

local Logger = {}
Logger.__index = Logger

function Logger.new()
    local self = setmetatable({
        _logEntries = {},
        _listeners = {},
        _minLogLevel = LOG_LEVELS.Info,
        _enabled = true,
        _uiEnabled = true,
        _tags = {},
        _history = {},
        _config = {
            maxHistory = 1000,
            persistErrors = true,
            autoSaveThreshold = 50,
            timestampFormat = "%H:%M:%S",
            dateFormat = "%Y-%m-%d"
        }
    }, Logger)
    
    self:_initializeUI()
    self:_setupConnections()
    
    return self
end

function Logger:_initializeUI()
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "AdvancedLogUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.IgnoreGuiInset = true
    self.screenGui.DisplayOrder = 999
    self.screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Main container
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.mainFrame.Position = UDim2.new(0.5, 0, 0.7, 0)
    self.mainFrame.Size = UDim2.new(0.6, 0, 0.3, 0)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.mainFrame.BackgroundTransparency = 0.15
    self.mainFrame.Parent = self.screenGui

    Instance.new("UICorner", self.mainFrame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", self.mainFrame).Color = Color3.fromRGB(60, 60, 70)
    
    -- Header
    self.header = Instance.new("Frame")
    self.header.Name = "Header"
    self.header.Size = UDim2.new(1, 0, 0, 32)
    self.header.BackgroundTransparency = 1
    self.header.Parent = self.mainFrame

    self.title = Instance.new("TextLabel")
    self.title.Name = "Title"
    self.title.Size = UDim2.new(1, -100, 1, 0)
    self.title.Position = UDim2.new(0, 10, 0, 0)
    self.title.Text = "ADVANCED LOGGER"
    self.title.TextColor3 = Color3.fromRGB(220, 220, 220)
    self.title.FontFace = FONT
    self.title.TextSize = 14
    self.title.TextXAlignment = Enum.TextXAlignment.Left
    self.title.BackgroundTransparency = 1
    self.title.Parent = self.header

    -- Controls
    self.controls = Instance.new("Frame")
    self.controls.Name = "Controls"
    self.controls.Size = UDim2.new(0, 90, 1, 0)
    self.controls.Position = UDim2.new(1, -100, 0, 0)
    self.controls.BackgroundTransparency = 1
    self.controls.Parent = self.header

    self.closeButton = self:_createControlButton("×", 0, function() 
        self:toggleUI() 
    end)
    
    self.clearButton = self:_createControlButton("🗑️", 30, function() 
        self:clear() 
    end)
    
    self.saveButton = self:_createControlButton("💾", 60, function() 
        self:saveToFile() 
    end)

    -- Filter controls
    self.filterFrame = Instance.new("Frame")
    self.filterFrame.Name = "FilterFrame"
    self.filterFrame.Size = UDim2.new(1, -8, 0, 28)
    self.filterFrame.Position = UDim2.new(0, 4, 0, 32)
    self.filterFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    self.filterFrame.BackgroundTransparency = 0.2
    self.filterFrame.Parent = self.mainFrame

    Instance.new("UICorner", self.filterFrame).CornerRadius = UDim.new(0, 6)
    
    self.searchBox = Instance.new("TextBox")
    self.searchBox.Name = "SearchBox"
    self.searchBox.Size = UDim2.new(0.5, -4, 1, 0)
    self.searchBox.Position = UDim2.new(0, 4, 0, 0)
    self.searchBox.PlaceholderText = "Search logs..."
    self.searchBox.Text = ""
    self.searchBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    self.searchBox.FontFace = FONT
    self.searchBox.TextSize = 12
    self.searchBox.BackgroundTransparency = 1
    self.searchBox.Parent = self.filterFrame

    self.levelFilter = Instance.new("TextButton")
    self.levelFilter.Name = "LevelFilter"
    self.levelFilter.Size = UDim2.new(0.25, -4, 1, 0)
    self.levelFilter.Position = UDim2.new(0.5, 4, 0, 0)
    self.levelFilter.Text = "Level: ALL"
    self.levelFilter.TextColor3 = Color3.fromRGB(220, 220, 220)
    self.levelFilter.FontFace = FONT
    self.levelFilter.TextSize = 12
    self.levelFilter.BackgroundTransparency = 1
    self.levelFilter.Parent = self.filterFrame

    self.tagFilter = Instance.new("TextButton")
    self.tagFilter.Name = "TagFilter"
    self.tagFilter.Size = UDim2.new(0.25, -4, 1, 0)
    self.tagFilter.Position = UDim2.new(0.75, 4, 0, 0)
    self.tagFilter.Text = "Tags: ALL"
    self.tagFilter.TextColor3 = Color3.fromRGB(220, 220, 220)
    self.tagFilter.FontFace = FONT
    self.tagFilter.TextSize = 12
    self.tagFilter.BackgroundTransparency = 1
    self.tagFilter.Parent = self.filterFrame

    -- Log container
    self.logContainer = Instance.new("ScrollingFrame")
    self.logContainer.Name = "LogContainer"
    self.logContainer.Size = UDim2.new(1, -8, 1, -68)
    self.logContainer.Position = UDim2.new(0, 4, 0, 64)
    self.logContainer.BackgroundTransparency = 1
    self.logContainer.ScrollBarThickness = 6
    self.logContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    self.logContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.logContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    self.logContainer.Parent = self.mainFrame

    self.logLayout = Instance.new("UIListLayout")
    self.logLayout.Padding = UDim.new(0, 6)
    self.logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.logLayout.Parent = self.logContainer

    self.logPadding = Instance.new("UIPadding")
    self.logPadding.PaddingTop = UDim.new(0, 4)
    self.logPadding.PaddingBottom = UDim.new(0, 4)
    self.logPadding.PaddingLeft = UDim.new(0, 4)
    self.logPadding.PaddingRight = UDim.new(0, 4)
    self.logPadding.Parent = self.logContainer

    -- Setup draggable
    self:_setupDraggable()
    -- Setup filters
    self:_setupFilters()
end

function Logger:_createControlButton(symbol, xOffset, callback)
    local button = Instance.new("TextButton")
    button.Name = symbol .. "Button"
    button.Size = UDim2.new(0, 24, 0, 24)
    button.Position = UDim2.new(0, xOffset, 0.5, 0)
    button.AnchorPoint = Vector2.new(0, 0.5)
    button.Text = symbol
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.TextSize = symbol == "×" and 18 or 14
    button.FontFace = FONT
    button.BackgroundTransparency = 1
    button.Parent = self.controls
    
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function Logger:_setupDraggable()
    local dragging = false
    local dragStartPos, frameStartPos

    self.header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = self.mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPos
            self.mainFrame.Position = UDim2.new(
                frameStartPos.X.Scale,
                frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale,
                frameStartPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Logger:_setupFilters()
    -- Search functionality
    self.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:_applyFilters()
    end)

    -- Level filter
    local levelIndex = 0
    local levelNames = {"ALL", "VERBOSE", "DEBUG", "INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "SYSTEM"}
    
    self.levelFilter.MouseButton1Click:Connect(function()
        levelIndex = (levelIndex + 1) % #levelNames
        self.levelFilter.Text = "Level: " .. levelNames[levelIndex + 1]
        self:_applyFilters()
    end)

    -- Tag filter
    self.tagFilter.MouseButton1Click:Connect(function()
        -- In a real implementation, this would cycle through available tags
        self:_applyFilters()
    end)
end

function Logger:_applyFilters()
    local searchText = string.lower(self.searchBox.Text)
    local levelFilter = string.lower(self.levelFilter.Text:match(": (.*)"))
    
    for _, logFrame in pairs(self.logContainer:GetChildren()) do
        if logFrame:IsA("Frame") and logFrame.Name == "LogEntry" then
            local message = string.lower(logFrame:FindFirstChild("MessageLabel").Text)
            local level = string.lower(logFrame:FindFirstChild("LevelLabel").Text)
            local visible = true
            
            -- Apply search filter
            if searchText ~= "" and not string.find(message, searchText, 1, true) then
                visible = false
            end
            
            -- Apply level filter
            if levelFilter ~= "all" and level ~= levelFilter then
                visible = false
            end
            
            logFrame.Visible = visible
        end
    end
end

function Logger:_createLogEntry(message, level, tags, timestamp)
    timestamp = timestamp or os.time()
    
    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogEntry"
    logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    logFrame.BackgroundTransparency = 0.15
    logFrame.Size = UDim2.new(1, -8, 0, 0)
    logFrame.AutomaticSize = Enum.AutomaticSize.Y
    logFrame.LayoutOrder = timestamp
    logFrame.Parent = self.logContainer

    Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", logFrame).Color = Color3.fromRGB(70, 70, 80)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = logFrame

    -- Timestamp
    local timeText = Instance.new("TextLabel")
    timeText.Name = "TimeLabel"
    timeText.Size = UDim2.new(0, 70, 0, 16)
    timeText.Position = UDim2.new(0, 4, 0, 4)
    timeText.Text = os.date(self._config.timestampFormat, timestamp)
    timeText.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeText.FontFace = FONT
    timeText.TextSize = 12
    timeText.TextXAlignment = Enum.TextXAlignment.Left
    timeText.BackgroundTransparency = 1
    timeText.Parent = logFrame

    -- Level
    local levelText = Instance.new("TextLabel")
    levelText.Name = "LevelLabel"
    levelText.Size = UDim2.new(0, 80, 0, 16)
    levelText.Position = UDim2.new(0, 80, 0, 4)
    levelText.Text = string.upper(level)
    levelText.TextColor3 = COLORS[level] or COLORS.Info
    levelText.FontFace = FONT
    levelText.TextSize = 12
    levelText.TextXAlignment = Enum.TextXAlignment.Left
    levelText.BackgroundTransparency = 1
    levelText.Parent = logFrame

    -- Tags
    if tags and #tags > 0 then
        local tagText = Instance.new("TextLabel")
        tagText.Name = "TagLabel"
        tagText.Size = UDim2.new(0, 120, 0, 16)
        tagText.Position = UDim2.new(0, 170, 0, 4)
        tagText.Text = "["..table.concat(tags, ", ").."]"
        tagText.TextColor3 = Color3.fromRGB(180, 180, 180)
        tagText.FontFace = FONT
        tagText.TextSize = 10
        tagText.TextXAlignment = Enum.TextXAlignment.Left
        tagText.BackgroundTransparency = 1
        tagText.Parent = logFrame
    end

    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -12, 0, 0)
    messageLabel.Position = UDim2.new(0, 12, 0, 24)
    messageLabel.Text = message
    messageLabel.TextColor3 = COLORS[level] or COLORS.Info
    messageLabel.FontFace = FONT
    messageLabel.TextSize = 14
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.BackgroundTransparency = 1
    messageLabel.Parent = logFrame

    -- Add fade-in animation
    logFrame.BackgroundTransparency = 1
    messageLabel.TextTransparency = 1
    levelText.TextTransparency = 1
    timeText.TextTransparency = 1
    
    local tween = TweenService:Create(
        logFrame,
        TweenInfo.new(ANIMATION_DURATION, EASE_STYLE, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.15}
    )
    tween:Play()
    
    local textTween = TweenService:Create(
        messageLabel,
        TweenInfo.new(ANIMATION_DURATION, EASE_STYLE, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    textTween:Play()
    
    local levelTween = TweenService:Create(
        levelText,
        TweenInfo.new(ANIMATION_DURATION, EASE_STYLE, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    levelTween:Play()
    
    local timeTween = TweenService:Create(
        timeText,
        TweenInfo.new(ANIMATION_DURATION, EASE_STYLE, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    )
    timeTween:Play()

    -- Auto-scroll to bottom if near bottom
    if self.logContainer.CanvasPosition.Y >= self.logContainer.CanvasSize.Y.Offset - self.logContainer.AbsoluteSize.Y - 20 then
        RunService.Heartbeat:Wait()
        self.logContainer.CanvasPosition = Vector2.new(0, self.logContainer.CanvasSize.Y.Offset)
    end

    return logFrame
end

function Logger:_setupConnections()
    -- Connect to Roblox's built-in logs
    LogService.MessageOut:Connect(function(message, messageType)
        local level = "Info"
        if messageType == Enum.MessageType.MessageWarning then
            level = "Warning"
        elseif messageType == Enum.MessageType.MessageError then
            level = "Error"
        end
        
        if LOG_LEVELS[level] >= self._minLogLevel then
            self:add(message, level)
        end
    end)
end

-- Public API Methods

function Logger:add(message, level, tags)
    if not self._enabled then return end
    
    level = level or "Info"
    tags = tags or {}
    local timestamp = os.time()
    
    -- Validate level
    if not LOG_LEVELS[level] then
        level = "Info"
    end
    
    -- Only log if meets minimum level
    if LOG_LEVELS[level] >= self._minLogLevel then
        -- Create UI entry
        if self._uiEnabled then
            self:_createLogEntry(message, level, tags, timestamp)
        end
        
        -- Store in history
        local logEntry = {
            message = message,
            level = level,
            tags = tags,
            timestamp = timestamp,
            date = os.date(self._config.dateFormat, timestamp)
        }
        
        table.insert(self._history, logEntry)
        
        -- Trim history if needed
        while #self._history > self._config.maxHistory do
            table.remove(self._history, 1)
        end
        
        -- Notify listeners
        for _, listener in ipairs(self._listeners) do
            listener(logEntry)
        end
        
        -- Auto-save if error and persistErrors is true
        if self._config.persistErrors and (level == "Error" or level == "Critical") then
            if #self._history % self._config.autoSaveThreshold == 0 then
                self:saveToFile()
            end
        end
    end
    
    return self
end

function Logger:configure(options)
    for key, value in pairs(options) do
        if self._config[key] ~= nil then
            self._config[key] = value
        end
    end
    return self
end

function Logger:setMinLogLevel(level)
    if LOG_LEVELS[level] then
        self._minLogLevel = LOG_LEVELS[level]
    end
    return self
end

function Logger:enable()
    self._enabled = true
    return self
end

function Logger:disable()
    self._enabled = false
    return self
end

function Logger:toggleUI()
    self._uiEnabled = not self._uiEnabled
    self.screenGui.Enabled = self._uiEnabled
    return self
end

function Logger:clear()
    for _, child in ipairs(self.logContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    return self
end

function Logger:saveToFile(filename)
    filename = filename or "logs_"..os.date("%Y-%m-%d_%H-%M-%S")..".json"
    local data = {
        config = self._config,
        logs = self._history
    }
    local json = HttpService:JSONEncode(data)
    
    if RunService:IsStudio() then
        -- In Studio, we can write to a file
        local success, message = pcall(function()
            writefile(filename, json)
        end)
        
        if success then
            self:add("Logs saved to "..filename, "Success")
        else
            self:add("Failed to save logs: "..message, "Error")
        end
    else
        -- In game, we can only notify
        self:add("Logs ready to save (Studio only)", "Warning")
    end
    
    return self
end

function Logger:addListener(callback)
    table.insert(self._listeners, callback)
    return self
end

function Logger:removeListener(callback)
    for i, listener in ipairs(self._listeners) do
        if listener == callback then
            table.remove(self._listeners, i)
            break
        end
    end
    return self
end

-- Convenience methods
function Logger:verbose(message, tags) return self:add(message, "Verbose", tags) end
function Logger:debug(message, tags) return self:add(message, "Debug", tags) end
function Logger:info(message, tags) return self:add(message, "Info", tags) end
function Logger:success(message, tags) return self:add(message, "Success", tags) end
function Logger:warn(message, tags) return self:add(message, "Warning", tags) end
function Logger:error(message, tags) return self:add(message, "Error", tags) end
function Logger:critical(message, tags) return self:add(message, "Critical", tags) end
function Logger:system(message, tags) return self:add(message, "System", tags) end

-- Create and return a default logger instance
local DefaultLogger = Logger.new()

-- Export both the class and default instance
return {
    Logger = Logger,  -- The class for creating multiple loggers
    Log = DefaultLogger,  -- Default logger instance
    
    -- Shortcut functions to default logger
    add = function(...) return DefaultLogger:add(...) end,
    verbose = function(...) return DefaultLogger:verbose(...) end,
    debug = function(...) return DefaultLogger:debug(...) end,
    info = function(...) return DefaultLogger:info(...) end,
    success = function(...) return DefaultLogger:success(...) end,
    warn = function(...) return DefaultLogger:warn(...) end,
    error = function(...) return DefaultLogger:error(...) end,
    critical = function(...) return DefaultLogger:critical(...) end,
    system = function(...) return DefaultLogger:system(...) end,
    configure = function(...) return DefaultLogger:configure(...) end,
    clear = function() return DefaultLogger:clear() end,
    toggleUI = function() return DefaultLogger:toggleUI() end,
    saveToFile = function(...) return DefaultLogger:saveToFile(...) end
}