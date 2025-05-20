local Nova = {}

local tween = game:GetService("TweenService")
local tweeninfo = TweenInfo.new
local input = game:GetService("UserInputService")
local run = game:GetService("RunService")

local Utility = {}
local Objects = {}

-- Dragging functionality
function Nova:DraggingEnabled(frame, parent)
    parent = parent or frame
    
    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = parent.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    input.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            parent.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Tween utility
function Utility:TweenObject(obj, properties, duration, ...)
    tween:Create(obj, tweeninfo(duration, ...), properties):Play()
end

-- Default themes
local themes = {
    SchemeColor = Color3.fromRGB(100, 150, 200),
    Background = Color3.fromRGB(30, 32, 40),
    Header = Color3.fromRGB(25, 27, 35),
    TextColor = Color3.fromRGB(240, 240, 240),
    ElementColor = Color3.fromRGB(35, 37, 45),
    BorderColor = Color3.fromRGB(50, 52, 60)
}

local themeStyles = {
    Dark = {
        SchemeColor = Color3.fromRGB(70, 70, 70),
        Background = Color3.fromRGB(20, 20, 20),
        Header = Color3.fromRGB(15, 15, 15),
        TextColor = Color3.fromRGB(240, 240, 240),
        ElementColor = Color3.fromRGB(25, 25, 25),
        BorderColor = Color3.fromRGB(40, 40, 40)
    },
    Light = {
        SchemeColor = Color3.fromRGB(200, 200, 200),
        Background = Color3.fromRGB(240, 240, 240),
        Header = Color3.fromRGB(220, 220, 220),
        TextColor = Color3.fromRGB(30, 30, 30),
        ElementColor = Color3.fromRGB(230, 230, 230),
        BorderColor = Color3.fromRGB(210, 210, 210)
    },
    Ocean = {
        SchemeColor = Color3.fromRGB(0, 150, 200),
        Background = Color3.fromRGB(10, 30, 50),
        Header = Color3.fromRGB(5, 25, 45),
        TextColor = Color3.fromRGB(220, 240, 255),
        ElementColor = Color3.fromRGB(15, 35, 55),
        BorderColor = Color3.fromRGB(0, 100, 150)
    },
    Neon = {
        SchemeColor = Color3.fromRGB(150, 0, 255),
        Background = Color3.fromRGB(10, 10, 20),
        Header = Color3.fromRGB(15, 5, 25),
        TextColor = Color3.fromRGB(255, 255, 255),
        ElementColor = Color3.fromRGB(20, 10, 30),
        BorderColor = Color3.fromRGB(100, 0, 200)
    }
}

-- Create the main library window
function Nova.CreateWindow(windowName, theme)
    windowName = windowName or "Nova UI"
    theme = theme or themes
    
    -- Handle theme presets
    if type(theme) == "string" then
        theme = themeStyles[theme] or themes
    end
    
    -- Ensure all theme properties exist
    for k, v in pairs(themes) do
        if theme[k] == nil then
            theme[k] = v
        end
    end
    
    -- Create unique identifier
    local libId = "Nova_"..tostring(math.random(1, 1000))..tostring(math.random(1, 1000))
    
    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = libId
    screenGui.Parent = game.CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Main window frame
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Parent = screenGui
    mainWindow.BackgroundColor3 = theme.Background
    mainWindow.Position = UDim2.new(0.3, 0, 0.3, 0)
    mainWindow.Size = UDim2.new(0, 500, 0, 350)
    mainWindow.ClipsDescendants = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 6)
    mainCorner.Parent = mainWindow
    
    -- Window header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = mainWindow
    header.BackgroundColor3 = theme.Header
    header.Size = UDim2.new(1, 0, 0, 30)
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 6)
    headerCorner.Parent = header
    
    -- Title label
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0.02, 0, 0, 0)
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Font = Enum.Font.GothamSemibold
    title.Text = windowName
    title.TextColor3 = theme.TextColor
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Parent = header
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(0.92, 0, 0.15, 0)
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Image = "rbxassetid://3926305904"
    closeBtn.ImageRectOffset = Vector2.new(284, 4)
    closeBtn.ImageRectSize = Vector2.new(24, 24)
    closeBtn.ImageColor3 = theme.TextColor
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Sidebar for tabs
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = mainWindow
    sidebar.BackgroundColor3 = theme.Header
    sidebar.Position = UDim2.new(0, 0, 0, 30)
    sidebar.Size = UDim2.new(0, 150, 0, 320)
    
    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 6)
    sidebarCorner.Parent = sidebar
    
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = sidebar
    tabContainer.BackgroundTransparency = 1
    tabContainer.Position = UDim2.new(0.05, 0, 0.02, 0)
    tabContainer.Size = UDim2.new(0.9, 0, 0.96, 0)
    
    local tabListLayout = Instance.new("UIListLayout")
    tabListLayout.Parent = tabContainer
    tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabListLayout.Padding = UDim.new(0, 5)
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = mainWindow
    contentArea.BackgroundTransparency = 1
    contentArea.Position = UDim2.new(0, 155, 0, 35)
    contentArea.Size = UDim2.new(0, 340, 0, 310)
    
    local pagesFolder = Instance.new("Folder")
    pagesFolder.Name = "Pages"
    pagesFolder.Parent = contentArea
    
    -- Enable dragging
    Nova:DraggingEnabled(header, mainWindow)
    
    -- Theme updating coroutine
    coroutine.wrap(function()
        while wait() do
            mainWindow.BackgroundColor3 = theme.Background
            header.BackgroundColor3 = theme.Header
            sidebar.BackgroundColor3 = theme.Header
            title.TextColor3 = theme.TextColor
            closeBtn.ImageColor3 = theme.TextColor
        end
    end)()
    
    -- Toggle UI function
    function Nova:ToggleUI()
        screenGui.Enabled = not screenGui.Enabled
    end
    
    -- Change theme function
    function Nova:ChangeTheme(newTheme)
        if type(newTheme) == "string" then
            newTheme = themeStyles[newTheme] or themes
        end
        
        for k, v in pairs(newTheme) do
            theme[k] = v
        end
    end
    
    -- Tab functions
    local Tabs = {}
    local firstTab = true
    
    function Tabs:NewTab(tabName)
        tabName = tabName or "Tab"
        
        -- Tab button
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName.."Tab"
        tabButton.Parent = tabContainer
        tabButton.BackgroundColor3 = theme.SchemeColor
        tabButton.Size = UDim2.new(1, 0, 0, 30)
        tabButton.AutoButtonColor = false
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = tabName
        tabButton.TextColor3 = theme.TextColor
        tabButton.TextSize = 14
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 4)
        tabCorner.Parent = tabButton
        
        -- Tab page
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = tabName.."Page"
        tabPage.Parent = pagesFolder
        tabPage.BackgroundTransparency = 1
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.Visible = false
        tabPage.ScrollBarThickness = 5
        tabPage.ScrollBarImageColor3 = theme.SchemeColor
        
        local pageListLayout = Instance.new("UIListLayout")
        pageListLayout.Parent = tabPage
        pageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageListLayout.Padding = UDim.new(0, 8)
        
        -- Update page size function
        local function UpdatePageSize()
            local contentSize = pageListLayout.AbsoluteContentSize
            tabPage.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 10)
        end
        
        pageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdatePageSize)
        
        -- Set first tab as active
        if firstTab then
            firstTab = false
            tabButton.BackgroundTransparency = 0
            tabPage.Visible = true
        else
            tabButton.BackgroundTransparency = 1
        end
        
        -- Tab button click event
        tabButton.MouseButton1Click:Connect(function()
            -- Hide all pages
            for _, page in pairs(pagesFolder:GetChildren()) do
                if page:IsA("ScrollingFrame") then
                    page.Visible = false
                end
            end
            
            -- Reset all tab buttons
            for _, btn in pairs(tabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Utility:TweenObject(btn, {BackgroundTransparency = 1}, 0.2)
                end
            end
            
            -- Show selected page and highlight button
            tabPage.Visible = true
            Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
        end)
        
        -- Theme updating for tab
        coroutine.wrap(function()
            while wait() do
                tabButton.BackgroundColor3 = theme.SchemeColor
                tabButton.TextColor3 = theme.TextColor
                tabPage.ScrollBarImageColor3 = theme.SchemeColor
            end
        end)()
        
        -- Section functions
        local Sections = {}
        
        function Sections:NewSection(sectionName)
            sectionName = sectionName or "Section"
            
            -- Section container
            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = sectionName.."Section"
            sectionFrame.Parent = tabPage
            sectionFrame.BackgroundColor3 = theme.ElementColor
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            
            local sectionCorner = Instance.new("UICorner")
            sectionCorner.CornerRadius = UDim.new(0, 4)
            sectionCorner.Parent = sectionFrame
            
            local sectionLayout = Instance.new("UIListLayout")
            sectionLayout.Parent = sectionFrame
            sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            sectionLayout.Padding = UDim.new(0, 5)
            
            -- Section header
            local sectionHeader = Instance.new("Frame")
            sectionHeader.Name = "Header"
            sectionHeader.Parent = sectionFrame
            sectionHeader.BackgroundColor3 = theme.SchemeColor
            sectionHeader.Size = UDim2.new(1, 0, 0, 30)
            
            local headerCorner = Instance.new("UICorner")
            headerCorner.CornerRadius = UDim.new(0, 4)
            headerCorner.Parent = sectionHeader
            
            local sectionTitle = Instance.new("TextLabel")
            sectionTitle.Name = "Title"
            sectionTitle.Parent = sectionHeader
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Position = UDim2.new(0.02, 0, 0, 0)
            sectionTitle.Size = UDim2.new(0.96, 0, 1, 0)
            sectionTitle.Font = Enum.Font.Gotham
            sectionTitle.Text = sectionName
            sectionTitle.TextColor3 = theme.TextColor
            sectionTitle.TextSize = 14
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Content frame
            local contentFrame = Instance.new("Frame")
            contentFrame.Name = "Content"
            contentFrame.Parent = sectionFrame
            contentFrame.BackgroundTransparency = 1
            contentFrame.Size = UDim2.new(1, 0, 0, 0)
            contentFrame.AutomaticSize = Enum.AutomaticSize.Y
            
            local contentLayout = Instance.new("UIListLayout")
            contentLayout.Parent = contentFrame
            contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            contentLayout.Padding = UDim.new(0, 5)
            
            -- Theme updating for section
            coroutine.wrap(function()
                while wait() do
                    sectionFrame.BackgroundColor3 = theme.ElementColor
                    sectionHeader.BackgroundColor3 = theme.SchemeColor
                    sectionTitle.TextColor3 = theme.TextColor
                end
            end)()
            
            -- UI elements
            local Elements = {}
            
            -- Button element
            function Elements:NewButton(btnName, callback)
                btnName = btnName or "Button"
                callback = callback or function() end
                
                local button = Instance.new("TextButton")
                button.Name = btnName.."Button"
                button.Parent = contentFrame
                button.BackgroundColor3 = theme.SchemeColor
                button.Size = UDim2.new(1, 0, 0, 30)
                button.AutoButtonColor = false
                button.Font = Enum.Font.Gotham
                button.Text = btnName
                button.TextColor3 = theme.TextColor
                button.TextSize = 14
                
                local buttonCorner = Instance.new("UICorner")
                buttonCorner.CornerRadius = UDim.new(0, 4)
                buttonCorner.Parent = button
                
                -- Button effects
                button.MouseEnter:Connect(function()
                    Utility:TweenObject(button, {BackgroundColor3 = Color3.fromRGB(
                        theme.SchemeColor.r * 255 + 20,
                        theme.SchemeColor.g * 255 + 20,
                        theme.SchemeColor.b * 255 + 20
                    )}, 0.1)
                end)
                
                button.MouseLeave:Connect(function()
                    Utility:TweenObject(button, {BackgroundColor3 = theme.SchemeColor}, 0.1)
                end)
                
                button.MouseButton1Click:Connect(function()
                    callback()
                end)
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        button.BackgroundColor3 = theme.SchemeColor
                        button.TextColor3 = theme.TextColor
                    end
                end)()
            end
            
            -- Toggle element
            function Elements:NewToggle(toggleName, default, callback)
                toggleName = toggleName or "Toggle"
                default = default or false
                callback = callback or function() end
                
                local toggleFrame = Instance.new("Frame")
                toggleFrame.Name = toggleName.."Toggle"
                toggleFrame.Parent = contentFrame
                toggleFrame.BackgroundTransparency = 1
                toggleFrame.Size = UDim2.new(1, 0, 0, 25)
                
                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Name = "Label"
                toggleLabel.Parent = toggleFrame
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Position = UDim2.new(0, 0, 0, 0)
                toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                toggleLabel.Font = Enum.Font.Gotham
                toggleLabel.Text = toggleName
                toggleLabel.TextColor3 = theme.TextColor
                toggleLabel.TextSize = 14
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local toggleButton = Instance.new("TextButton")
                toggleButton.Name = "Toggle"
                toggleButton.Parent = toggleFrame
                toggleButton.BackgroundColor3 = default and theme.SchemeColor or theme.ElementColor
                toggleButton.Position = UDim2.new(0.8, 0, 0.1, 0)
                toggleButton.Size = UDim2.new(0.2, 0, 0.8, 0)
                toggleButton.AutoButtonColor = false
                toggleButton.Text = ""
                
                local toggleCorner = Instance.new("UICorner")
                toggleCorner.CornerRadius = UDim.new(0, 4)
                toggleCorner.Parent = toggleButton
                
                local toggleState = default
                
                toggleButton.MouseButton1Click:Connect(function()
                    toggleState = not toggleState
                    Utility:TweenObject(toggleButton, {
                        BackgroundColor3 = toggleState and theme.SchemeColor or theme.ElementColor
                    }, 0.2)
                    callback(toggleState)
                end)
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        toggleLabel.TextColor3 = theme.TextColor
                        toggleButton.BackgroundColor3 = toggleState and theme.SchemeColor or theme.ElementColor
                    end
                end)()
            end
            
            -- Slider element
            function Elements:NewSlider(sliderName, min, max, default, callback)
                sliderName = sliderName or "Slider"
                min = min or 0
                max = max or 100
                default = default or min
                callback = callback or function() end
                
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Name = sliderName.."Slider"
                sliderFrame.Parent = contentFrame
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Size = UDim2.new(1, 0, 0, 40)
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "Label"
                sliderLabel.Parent = sliderFrame
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Size = UDim2.new(1, 0, 0, 15)
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.Text = sliderName..": "..default
                sliderLabel.TextColor3 = theme.TextColor
                sliderLabel.TextSize = 14
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local sliderTrack = Instance.new("Frame")
                sliderTrack.Name = "Track"
                sliderTrack.Parent = sliderFrame
                sliderTrack.BackgroundColor3 = theme.ElementColor
                sliderTrack.Position = UDim2.new(0, 0, 0, 20)
                sliderTrack.Size = UDim2.new(1, 0, 0, 5)
                
                local trackCorner = Instance.new("UICorner")
                trackCorner.CornerRadius = UDim.new(1, 0)
                trackCorner.Parent = sliderTrack
                
                local sliderFill = Instance.new("Frame")
                sliderFill.Name = "Fill"
                sliderFill.Parent = sliderTrack
                sliderFill.BackgroundColor3 = theme.SchemeColor
                sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                
                local fillCorner = Instance.new("UICorner")
                fillCorner.CornerRadius = UDim.new(1, 0)
                fillCorner.Parent = sliderFill
                
                local sliderButton = Instance.new("TextButton")
                sliderButton.Name = "Button"
                sliderButton.Parent = sliderTrack
                sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                sliderButton.Position = UDim2.new(1, -5, 0, -5)
                sliderButton.Size = UDim2.new(0, 10, 0, 15)
                sliderButton.AutoButtonColor = false
                sliderButton.Text = ""
                
                local buttonCorner = Instance.new("UICorner")
                buttonCorner.CornerRadius = UDim.new(1, 0)
                buttonCorner.Parent = sliderButton
                
                local dragging = false
                local currentValue = default
                
                local function updateSlider(value)
                    value = math.clamp(value, min, max)
                    currentValue = value
                    sliderLabel.Text = sliderName..": "..math.floor(value)
                    sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    callback(value)
                end
                
                sliderButton.MouseButton1Down:Connect(function()
                    dragging = true
                end)
                
                input.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                
                input.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local xPos = math.clamp(
                            (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X,
                            0, 1
                        )
                        updateSlider(min + (max - min) * xPos)
                    end
                end)
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        sliderLabel.TextColor3 = theme.TextColor
                        sliderTrack.BackgroundColor3 = theme.ElementColor
                        sliderFill.BackgroundColor3 = theme.SchemeColor
                    end
                end)()
            end
            
            -- Label element
            function Elements:NewLabel(labelText)
                labelText = labelText or "Label"
                
                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.Parent = contentFrame
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, 0, 0, 20)
                label.Font = Enum.Font.Gotham
                label.Text = labelText
                label.TextColor3 = theme.TextColor
                label.TextSize = 14
                label.TextXAlignment = Enum.TextXAlignment.Left
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        label.TextColor3 = theme.TextColor
                    end
                end)()
            end
            
            return Elements
        end
        
        return Sections
    end
    
    return Tabs
end

return Nova