local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create main screen GUI
local LogGUI = Instance.new("ScreenGui")
LogGUI.Name = "LogServiceGUI"
LogGUI.ResetOnSpawn = false
LogGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LogGUI.DisplayOrder = 100
LogGUI.Parent = playerGui

-- Main container
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.7, 0, 0.6, 0)
MainFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = LogGUI

-- Corner rounding
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Drop shadow
local UIStroke = Instance.new("UIStroke")
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(60, 60, 70)
UIStroke.LineJoinMode = Enum.LineJoinMode.Round
UIStroke.Thickness = 2
UIStroke.Transparency = 0.7
UIStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0.02, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Log Viewer"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamSemibold
Title.Parent = Header

-- Close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0.5, -15)
CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
CloseButton.AutoButtonColor = true
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(240, 240, 245)
CloseButton.TextSize = 20
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Header

UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = CloseButton

-- Tabs container
local Tabs = Instance.new("Frame")
Tabs.Name = "Tabs"
Tabs.Size = UDim2.new(1, 0, 0, 40)
Tabs.Position = UDim2.new(0, 0, 0, 40)
Tabs.BackgroundTransparency = 1
Tabs.Parent = MainFrame

local TabsListLayout = Instance.new("UIListLayout")
TabsListLayout.FillDirection = Enum.FillDirection.Horizontal
TabsListLayout.Padding = UDim.new(0, 5)
TabsListLayout.Parent = Tabs

-- Create tabs
local tabNames = {"All", "Errors", "Warnings", "Messages"}
local currentTab = "All"

local function createTab(name)
    local tab = Instance.new("TextButton")
    tab.Name = name
    tab.Size = UDim2.new(0, 100, 1, 0)
    tab.BackgroundColor3 = name == currentTab and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(50, 50, 60)
    tab.AutoButtonColor = true
    tab.Text = name
    tab.TextColor3 = Color3.fromRGB(240, 240, 245)
    tab.TextSize = 14
    tab.Font = Enum.Font.GothamMedium
    tab.Parent = Tabs
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tab
    
    tab.MouseButton1Click:Connect(function()
        currentTab = name
        for _, child in ipairs(Tabs:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = child.Name == currentTab and Color3.fromRGB(70, 70, 80) or Color3.fromRGB(50, 50, 60)
            end
        end
        -- Refresh log display
        updateLogDisplay()
    end)
    
    return tab
end

for _, name in ipairs(tabNames) do
    createTab(name)
end

-- Search bar
local SearchContainer = Instance.new("Frame")
SearchContainer.Name = "SearchContainer"
SearchContainer.Size = UDim2.new(1, -20, 0, 36)
SearchContainer.Position = UDim2.new(0, 10, 0, 85)
SearchContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
SearchContainer.Parent = MainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = SearchContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchBox"
SearchBox.Size = UDim2.new(1, -40, 1, 0)
SearchBox.Position = UDim2.new(0, 10, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.ClearTextOnFocus = false
SearchBox.PlaceholderText = "Search logs..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(240, 240, 245)
SearchBox.TextSize = 14
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Font = Enum.Font.Gotham
SearchBox.Parent = SearchContainer

local SearchIcon = Instance.new("ImageLabel")
SearchIcon.Name = "SearchIcon"
SearchIcon.Size = UDim2.new(0, 20, 0, 20)
SearchIcon.Position = UDim2.new(1, -30, 0.5, -10)
SearchIcon.AnchorPoint = Vector2.new(0.5, 0.5)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = "rbxassetid://3926305904"
SearchIcon.ImageColor3 = Color3.fromRGB(150, 150, 160)
SearchIcon.ImageRectOffset = Vector2.new(964, 324)
SearchIcon.ImageRectSize = Vector2.new(36, 36)
SearchIcon.Parent = SearchContainer

-- Clear search button (appears when there's text)
local ClearSearchButton = Instance.new("ImageButton")
ClearSearchButton.Name = "ClearSearchButton"
ClearSearchButton.Size = UDim2.new(0, 16, 0, 16)
ClearSearchButton.Position = UDim2.new(1, -35, 0.5, -8)
ClearSearchButton.AnchorPoint = Vector2.new(0.5, 0.5)
ClearSearchButton.BackgroundTransparency = 1
ClearSearchButton.Image = "rbxassetid://3926305904"
ClearSearchButton.ImageColor3 = Color3.fromRGB(150, 150, 160)
ClearSearchButton.ImageRectOffset = Vector2.new(284, 4)
ClearSearchButton.ImageRectSize = Vector2.new(24, 24)
ClearSearchButton.Visible = false
ClearSearchButton.Parent = SearchContainer

-- Logs container
local LogsContainer = Instance.new("ScrollingFrame")
LogsContainer.Name = "LogsContainer"
LogsContainer.Size = UDim2.new(1, -20, 1, -130)
LogsContainer.Position = UDim2.new(0, 10, 0, 125)
LogsContainer.BackgroundTransparency = 1
LogsContainer.BorderSizePixel = 0
LogsContainer.ScrollBarThickness = 6
LogsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
LogsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
LogsContainer.Parent = MainFrame

local LogsListLayout = Instance.new("UIListLayout")
LogsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogsListLayout.Padding = UDim.new(0, 5)
LogsListLayout.Parent = LogsContainer

-- Bottom bar with stats and actions
local BottomBar = Instance.new("Frame")
BottomBar.Name = "BottomBar"
BottomBar.Size = UDim2.new(1, 0, 0, 30)
BottomBar.Position = UDim2.new(0, 0, 1, -30)
BottomBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
BottomBar.BorderSizePixel = 0
BottomBar.Parent = MainFrame

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Name = "StatsLabel"
StatsLabel.Size = UDim2.new(0.5, 0, 1, 0)
StatsLabel.Position = UDim2.new(0, 10, 0, 0)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = "Total: 0 | Errors: 0 | Warnings: 0"
StatsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
StatsLabel.TextSize = 12
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.Parent = BottomBar

local ClearButton = Instance.new("TextButton")
ClearButton.Name = "ClearButton"
ClearButton.Size = UDim2.new(0, 80, 0, 24)
ClearButton.Position = UDim2.new(1, -90, 0.5, -12)
ClearButton.AnchorPoint = Vector2.new(0.5, 0.5)
ClearButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ClearButton.AutoButtonColor = true
ClearButton.Text = "Clear All"
ClearButton.TextColor3 = Color3.fromRGB(240, 240, 245)
ClearButton.TextSize = 12
ClearButton.Font = Enum.Font.GothamMedium
ClearButton.Parent = BottomBar

corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = ClearButton

-- Log entry template (created dynamically as needed)
local function createLogEntry(message, messageType, timestamp)
    local entry = Instance.new("Frame")
    entry.Name = "LogEntry"
    entry.Size = UDim2.new(1, 0, 0, 0) -- Height will be auto-set
    entry.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    entry.BackgroundTransparency = 0.5
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.LayoutOrder = -timestamp -- Newest first
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = entry
    
    -- Type indicator
    local typeIndicator = Instance.new("Frame")
    typeIndicator.Name = "TypeIndicator"
    typeIndicator.Size = UDim2.new(0, 4, 1, 0)
    typeIndicator.BackgroundColor3 = 
        messageType == Enum.MessageType.MessageError and Color3.fromRGB(255, 80, 80) or
        messageType == Enum.MessageType.MessageWarning and Color3.fromRGB(255, 180, 60) or
        Color3.fromRGB(100, 180, 255)
    typeIndicator.BorderSizePixel = 0
    typeIndicator.Parent = entry
    
    -- Timestamp
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 80, 0, 20)
    timeLabel.Position = UDim2.new(0, 10, 0, 5)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = string.format("%.2f", timestamp)
    timeLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    timeLabel.TextSize = 12
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Parent = entry
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    messageLabel.Size = UDim2.new(1, -100, 0, 0)
    messageLabel.Position = UDim2.new(0, 90, 0, 5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = 
        messageType == Enum.MessageType.MessageError and Color3.fromRGB(255, 120, 120) or
        messageType == Enum.MessageType.MessageWarning and Color3.fromRGB(255, 200, 120) or
        Color3.fromRGB(220, 220, 230)
    messageLabel.TextSize = 14
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Parent = entry
    
    -- Calculate height based on text
    local textSize = TextService:GetTextSize(
        message,
        14,
        messageLabel.Font,
        Vector2.new(messageLabel.AbsoluteSize.X, math.huge)
    messageLabel.Size = UDim2.new(1, -100, 0, textSize.Y)
    
    entry.Size = UDim2.new(1, 0, 0, textSize.Y + 10)
    
    return entry
end

-- Log storage
local allLogs = {}
local errorCount = 0
local warningCount = 0
local messageCount = 0

-- Update stats display
local function updateStats()
    StatsLabel.Text = string.format("Total: %d | Errors: %d | Warnings: %d | Messages: %d", 
        #allLogs, errorCount, warningCount, messageCount)
end

-- Filter and display logs based on current tab and search
local function updateLogDisplay()
    local searchText = string.lower(SearchBox.Text)
    
    -- Clear current display
    for _, child in ipairs(LogsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add filtered logs
    for _, log in ipairs(allLogs) do
        local matchesTab = 
            currentTab == "All" or
            (currentTab == "Errors" and log.type == Enum.MessageType.MessageError) or
            (currentTab == "Warnings" and log.type == Enum.MessageType.MessageWarning) or
            (currentTab == "Messages" and log.type == Enum.MessageType.MessageInfo)
            
        local matchesSearch = searchText == "" or 
            string.find(string.lower(log.message), searchText, 1, true) ~= nil
            
        if matchesTab and matchesSearch then
            local entry = createLogEntry(log.message, log.type, log.timestamp)
            entry.Parent = LogsContainer
        end
    end
end

-- Add a new log to storage and update display
local function addLog(message, messageType)
    local timestamp = os.clock()
    table.insert(allLogs, {
        message = message,
        type = messageType,
        timestamp = timestamp
    })
    
    -- Update counts
    if messageType == Enum.MessageType.MessageError then
        errorCount = errorCount + 1
    elseif messageType == Enum.MessageType.MessageWarning then
        warningCount = warningCount + 1
    else
        messageCount = messageCount + 1
    end
    
    updateStats()
    
    -- Check if this log should be displayed
    local searchText = string.lower(SearchBox.Text)
    local matchesTab = 
        currentTab == "All" or
        (currentTab == "Errors" and messageType == Enum.MessageType.MessageError) or
        (currentTab == "Warnings" and messageType == Enum.MessageType.MessageWarning) or
        (currentTab == "Messages" and messageType == Enum.MessageType.MessageInfo)
        
    local matchesSearch = searchText == "" or 
        string.find(string.lower(message), searchText, 1, true) ~= nil
        
    if matchesTab and matchesSearch then
        local entry = createLogEntry(message, messageType, timestamp)
        entry.Parent = LogsContainer
    end
end

-- Connect to LogService
LogService.MessageOut:Connect(function(message, messageType)
    addLog(message, messageType)
end)

-- UI Interactions
CloseButton.MouseButton1Click:Connect(function()
    local tween = TweenService:Create(
        MainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, 0, -0.5, 0)}
    )
    tween:Play()
    tween.Completed:Wait()
    LogGUI:Destroy()
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    ClearSearchButton.Visible = SearchBox.Text ~= ""
    updateLogDisplay()
end)

ClearSearchButton.MouseButton1Click:Connect(function()
    SearchBox.Text = ""
    ClearSearchButton.Visible = false
end)

ClearButton.MouseButton1Click:Connect(function()
    -- Clear all logs
    allLogs = {}
    errorCount = 0
    warningCount = 0
    messageCount = 0
    
    -- Clear display
    for _, child in ipairs(LogsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    updateStats()
end)

-- Initial stats update
updateStats()

-- Make the window draggable
local dragging
local dragInput
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Initial animation
MainFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
local tween = TweenService:Create(
    MainFrame,
    TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Position = UDim2.new(0.5, 0, 0.5, 0)}
)
tween:Play()