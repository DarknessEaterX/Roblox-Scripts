local Nova = {}

local tween = game:GetService("TweenService")
local tweeninfo = TweenInfo.new
local input = game:GetService("UserInputService")
local run = game:GetService("RunService")
local players = game:GetService("Players")

local Utility = {}
local Objects = {}

-- Enhanced dragging functionality with mobile support
function Nova:DraggingEnabled(frame, parent)
    parent = parent or frame
    
    local dragging = false
    local dragInput, mousePos, framePos, touchStartPos, touchStartTime

    -- Function to handle both mouse and touch input
    local function handleInput(inputObj, isTouch)
        if (isTouch and inputObj.UserInputType == Enum.UserInputType.Touch) or 
           (not isTouch and inputObj.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = true
            mousePos = inputObj.Position
            framePos = parent.Position
            touchStartPos = inputObj.Position
            touchStartTime = os.clock()
            
            inputObj.Changed:Connect(function()
                if inputObj.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- Check for tap (quick touch release)
                    if isTouch and os.clock() - touchStartTime < 0.3 and 
                       (inputObj.Position - touchStartPos).Magnitude < 10 then
                        -- Treat as a tap
                    end
                end
            end)
        end
    end

    -- Mouse input
    frame.InputBegan:Connect(function(input)
        handleInput(input, false)
    end)

    -- Touch input
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            handleInput(input, true)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    input.InputChanged:Connect(function(input)
        if (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta
            if input.UserInputType == Enum.UserInputType.Touch then
                delta = input.Delta
            else
                delta = input.Position - mousePos
            end
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

-- Create the main library window with mobile responsiveness
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
    
    -- Detect mobile device
    local isMobile = input.TouchEnabled and not input.MouseEnabled
    local isTablet = false
    
    -- Check screen size for tablet detection
    if isMobile then
        local viewportSize = workspace.CurrentCamera.ViewportSize
        isTablet = math.min(viewportSize.X, viewportSize.Y) > 700
    end
    
    -- Main window frame with responsive sizing
    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Parent = screenGui
    mainWindow.BackgroundColor3 = theme.Background
    mainWindow.Position = UDim2.new(0.3, 0, 0.3, 0)
    mainWindow.Size = isMobile and (isTablet and UDim2.new(0, 450, 0, 500) or UDim2.new(0, 350, 0, 400)) 
                     or UDim2.new(0, 500, 0, 350)
    mainWindow.ClipsDescendants = true
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 6)
    mainCorner.Parent = mainWindow
    
    -- Window header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = mainWindow
    header.BackgroundColor3 = theme.Header
    header.Size = UDim2.new(1, 0, 0, isMobile and 40 or 30)
    
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
    title.TextSize = isMobile and 18 or 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close button
    local closeBtn = Instance.new(isMobile and "TextButton" or "ImageButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Parent = header
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(0.92, 0, isMobile and 0.2 or 0.15, 0)
    closeBtn.Size = UDim2.new(0, isMobile and 25 or 20, 0, isMobile and 25 or 20)
    
    if isMobile then
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "X"
        closeBtn.TextColor3 = theme.TextColor
        closeBtn.TextSize = 18
    else
        closeBtn.Image = "rbxassetid://3926305904"
        closeBtn.ImageRectOffset = Vector2.new(284, 4)
        closeBtn.ImageRectSize = Vector2.new(24, 24)
        closeBtn.ImageColor3 = theme.TextColor
    end
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Sidebar for tabs
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Parent = mainWindow
    sidebar.BackgroundColor3 = theme.Header
    sidebar.Position = UDim2.new(0, 0, 0, isMobile and 40 or 30)
    sidebar.Size = isMobile and UDim2.new(0, 120, 0, isTablet and 460 or 360) 
                  or UDim2.new(0, 150, 0, 320)
    
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
    contentArea.Position = isMobile and UDim2.new(0, 125, 0, 45) or UDim2.new(0, 155, 0, 35)
    contentArea.Size = isMobile and UDim2.new(0, isTablet and 320 or 220, 0, isTablet and 450 or 350) 
                      or UDim2.new(0, 340, 0, 310)
    
    local pagesFolder = Instance.new("Folder")
    pagesFolder.Name = "Pages"
    pagesFolder.Parent = contentArea
    
    -- Enable enhanced dragging with mobile support
    Nova:DraggingEnabled(header, mainWindow)
    
    -- Theme updating coroutine
    coroutine.wrap(function()
        while wait() do
            mainWindow.BackgroundColor3 = theme.Background
            header.BackgroundColor3 = theme.Header
            sidebar.BackgroundColor3 = theme.Header
            title.TextColor3 = theme.TextColor
            if not isMobile then
                closeBtn.ImageColor3 = theme.TextColor
            else
                closeBtn.TextColor3 = theme.TextColor
            end
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
        tabButton.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
        tabButton.AutoButtonColor = false
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = tabName
        tabButton.TextColor3 = theme.TextColor
        tabButton.TextSize = isMobile and 16 or 14
        
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
        tabPage.ScrollBarThickness = isMobile and 8 or 5
        tabPage.ScrollBarImageColor3 = theme.SchemeColor
        
        local pageListLayout = Instance.new("UIListLayout")
        pageListLayout.Parent = tabPage
        pageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageListLayout.Padding = UDim.new(0, isMobile and 10 or 8)
        
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
            sectionLayout.Padding = UDim.new(0, isMobile and 8 or 5)
            
            -- Section header
            local sectionHeader = Instance.new("Frame")
            sectionHeader.Name = "Header"
            sectionHeader.Parent = sectionFrame
            sectionHeader.BackgroundColor3 = theme.SchemeColor
            sectionHeader.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
            
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
            sectionTitle.TextSize = isMobile and 16 or 14
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
            contentLayout.Padding = UDim.new(0, isMobile and 8 or 5)
            
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
                button.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                button.AutoButtonColor = false
                button.Font = Enum.Font.Gotham
                button.Text = btnName
                button.TextColor3 = theme.TextColor
                button.TextSize = isMobile and 16 or 14
                
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
                
                -- Touch support for mobile
                if isMobile then
                    local touchStartTime = 0
                    
                    button.TouchLongPress:Connect(function()
                        -- Handle long press if needed
                    end)
                    
                    button.TouchTap:Connect(function()
                        if os.clock() - touchStartTime < 0.5 then
                            callback()
                        end
                    end)
                    
                    button.TouchStarted:Connect(function()
                        touchStartTime = os.clock()
                        Utility:TweenObject(button, {BackgroundColor3 = Color3.fromRGB(
                            theme.SchemeColor.r * 255 + 20,
                            theme.SchemeColor.g * 255 + 20,
                            theme.SchemeColor.b * 255 + 20
                        )}, 0.1)
                    end)
                    
                    button.TouchEnded:Connect(function()
                        Utility:TweenObject(button, {BackgroundColor3 = theme.SchemeColor}, 0.1)
                    end)
                end
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        button.BackgroundColor3 = theme.SchemeColor
                        button.TextColor3 = theme.TextColor
                    end
                end)()
                
                local buttonFunctions = {}
                
                function buttonFunctions:UpdateText(newText)
                    button.Text = newText
                end
                
                function buttonFunctions:UpdateCallback(newCallback)
                    callback = newCallback
                end
                
                return buttonFunctions
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
                toggleFrame.Size = UDim2.new(1, 0, 0, isMobile and 30 or 25)
                
                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Name = "Label"
                toggleLabel.Parent = toggleFrame
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Position = UDim2.new(0, 0, 0, 0)
                toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                toggleLabel.Font = Enum.Font.Gotham
                toggleLabel.Text = toggleName
                toggleLabel.TextColor3 = theme.TextColor
                toggleLabel.TextSize = isMobile and 16 or 14
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
                
                local function updateToggle()
                    Utility:TweenObject(toggleButton, {
                        BackgroundColor3 = toggleState and theme.SchemeColor or theme.ElementColor
                    }, 0.2)
                    callback(toggleState)
                end
                
                toggleButton.MouseButton1Click:Connect(function()
                    toggleState = not toggleState
                    updateToggle()
                end)
                
                -- Touch support for mobile
                if isMobile then
                    toggleButton.TouchTap:Connect(function()
                        toggleState = not toggleState
                        updateToggle()
                    end)
                end
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        toggleLabel.TextColor3 = theme.TextColor
                        toggleButton.BackgroundColor3 = toggleState and theme.SchemeColor or theme.ElementColor
                    end
                end)()
                
                local toggleFunctions = {}
                
                function toggleFunctions:SetState(state)
                    toggleState = state
                    updateToggle()
                end
                
                function toggleFunctions:GetState()
                    return toggleState
                end
                
                return toggleFunctions
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
                sliderFrame.Size = UDim2.new(1, 0, 0, isMobile and 50 or 40)
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "Label"
                sliderLabel.Parent = sliderFrame
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Size = UDim2.new(1, 0, 0, isMobile and 20 or 15)
                sliderLabel.Font = Enum.Font.Gotham
                sliderLabel.Text = sliderName..": "..default
                sliderLabel.TextColor3 = theme.TextColor
                sliderLabel.TextSize = isMobile and 16 or 14
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local sliderTrack = Instance.new("Frame")
                sliderTrack.Name = "Track"
                sliderTrack.Parent = sliderFrame
                sliderTrack.BackgroundColor3 = theme.ElementColor
                sliderTrack.Position = UDim2.new(0, 0, 0, isMobile and 25 or 20)
                sliderTrack.Size = UDim2.new(1, 0, 0, isMobile and 8 or 5)
                
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
                sliderButton.Position = UDim2.new(1, -8, 0, isMobile and -6 or -5)
                sliderButton.Size = UDim2.new(0, isMobile and 16 or 10, 0, isMobile and 20 or 15)
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
                
                -- Mouse input
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
                
                -- Touch input for mobile
                if isMobile then
                    sliderButton.TouchStarted:Connect(function(touch)
                        dragging = true
                    end)
                    
                    sliderButton.TouchEnded:Connect(function(touch)
                        dragging = false
                    end)
                    
                    input.TouchMoved:Connect(function(touch, gameProcessed)
                        if dragging and not gameProcessed then
                            local xPos = math.clamp(
                                (touch.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X,
                                0, 1
                            )
                            updateSlider(min + (max - min) * xPos)
                        end
                    end)
                end
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        sliderLabel.TextColor3 = theme.TextColor
                        sliderTrack.BackgroundColor3 = theme.ElementColor
                        sliderFill.BackgroundColor3 = theme.SchemeColor
                    end
                end)()
                
                local sliderFunctions = {}
                
                function sliderFunctions:SetValue(value)
                    updateSlider(value)
                end
                
                function sliderFunctions:GetValue()
                    return currentValue
                end
                
                return sliderFunctions
            end
            
            -- Label element
            function Elements:NewLabel(labelText)
                labelText = labelText or "Label"
                
                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.Parent = contentFrame
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, 0, 0, isMobile and 25 or 20)
                label.Font = Enum.Font.Gotham
                label.Text = labelText
                label.TextColor3 = theme.TextColor
                label.TextSize = isMobile and 16 or 14
                label.TextXAlignment = Enum.TextXAlignment.Left
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        label.TextColor3 = theme.TextColor
                    end
                end)()
                
                local labelFunctions = {}
                
                function labelFunctions:UpdateText(newText)
                    label.Text = newText
                end
                
                return labelFunctions
            end
            
            -- Dropdown element
            function Elements:NewDropdown(dropdownName, options, defaultOption, callback)
                dropdownName = dropdownName or "Dropdown"
                options = options or {"Option 1", "Option 2"}
                defaultOption = defaultOption or options[1]
                callback = callback or function() end
                
                local dropdownFrame = Instance.new("Frame")
                dropdownFrame.Name = dropdownName.."Dropdown"
                dropdownFrame.Parent = contentFrame
                dropdownFrame.BackgroundColor3 = theme.ElementColor
                dropdownFrame.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                dropdownFrame.ClipsDescendants = true
                
                local dropdownCorner = Instance.new("UICorner")
                dropdownCorner.CornerRadius = UDim.new(0, 4)
                dropdownCorner.Parent = dropdownFrame
                
                local dropdownButton = Instance.new("TextButton")
                dropdownButton.Name = "Button"
                dropdownButton.Parent = dropdownFrame
                dropdownButton.BackgroundTransparency = 1
                dropdownButton.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                dropdownButton.AutoButtonColor = false
                dropdownButton.Font = Enum.Font.Gotham
                dropdownButton.Text = dropdownName..": "..defaultOption
                dropdownButton.TextColor3 = theme.TextColor
                dropdownButton.TextSize = isMobile and 16 or 14
                dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
                
                local dropdownIcon = Instance.new("ImageLabel")
                dropdownIcon.Name = "Icon"
                dropdownIcon.Parent = dropdownButton
                dropdownIcon.BackgroundTransparency = 1
                dropdownIcon.Position = UDim2.new(0.95, -20, 0.5, -10)
                dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
                dropdownIcon.Image = "rbxassetid://3926305904"
                dropdownIcon.ImageRectOffset = Vector2.new(364, 284)
                dropdownIcon.ImageRectSize = Vector2.new(36, 36)
                dropdownIcon.ImageColor3 = theme.TextColor
                
                local optionsFrame = Instance.new("Frame")
                optionsFrame.Name = "Options"
                optionsFrame.Parent = dropdownFrame
                optionsFrame.BackgroundColor3 = theme.ElementColor
                optionsFrame.Position = UDim2.new(0, 0, 0, isMobile and 35 or 30)
                optionsFrame.Size = UDim2.new(1, 0, 0, 0)
                optionsFrame.Visible = false
                
                local optionsLayout = Instance.new("UIListLayout")
                optionsLayout.Parent = optionsFrame
                optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                
                local optionsCorner = Instance.new("UICorner")
                optionsCorner.CornerRadius = UDim.new(0, 4)
                optionsCorner.Parent = optionsFrame
                
                local isOpen = false
                local selectedOption = defaultOption
                
                local function updateDropdown()
                    dropdownButton.Text = dropdownName..": "..selectedOption
                    callback(selectedOption)
                end
                
                local function toggleDropdown()
                    isOpen = not isOpen
                    
                    if isOpen then
                        -- Close other open dropdowns
                        for _, child in pairs(contentFrame:GetChildren()) do
                            if child:IsA("Frame") and child.Name:find("Dropdown") and child ~= dropdownFrame then
                                local options = child:FindFirstChild("Options")
                                if options and options.Visible then
                                    Utility:TweenObject(options, {
                                        Size = UDim2.new(1, 0, 0, 0)
                                    }, 0.2)
                                    wait(0.2)
                                    options.Visible = false
                                end
                            end
                        end
                        
                        -- Create option buttons
                        optionsFrame:ClearAllChildren()
                        optionsLayout.Parent = optionsFrame
                        optionsCorner.Parent = optionsFrame
                        
                        for _, option in pairs(options) do
                            local optionButton = Instance.new("TextButton")
                            optionButton.Name = option.."Option"
                            optionButton.Parent = optionsFrame
                            optionButton.BackgroundColor3 = option == selectedOption and theme.SchemeColor or theme.ElementColor
                            optionButton.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                            optionButton.AutoButtonColor = false
                            optionButton.Font = Enum.Font.Gotham
                            optionButton.Text = option
                            optionButton.TextColor3 = theme.TextColor
                            optionButton.TextSize = isMobile and 16 or 14
                            
                            local optionCorner = Instance.new("UICorner")
                            optionCorner.CornerRadius = UDim.new(0, 4)
                            optionCorner.Parent = optionButton
                            
                            optionButton.MouseButton1Click:Connect(function()
                                selectedOption = option
                                updateDropdown()
                                toggleDropdown()
                            end)
                            
                            -- Touch support for mobile
                            if isMobile then
                                optionButton.TouchTap:Connect(function()
                                    selectedOption = option
                                    updateDropdown()
                                    toggleDropdown()
                                end)
                            end
                            
                            -- Theme updating
                            coroutine.wrap(function()
                                while wait() do
                                    optionButton.BackgroundColor3 = option == selectedOption and theme.SchemeColor or theme.ElementColor
                                    optionButton.TextColor3 = theme.TextColor
                                end
                            end)()
                        end
                        
                        -- Calculate total height of options
                        local totalHeight = #options * (isMobile and 35 or 30)
                        optionsFrame.Visible = true
                        Utility:TweenObject(optionsFrame, {
                            Size = UDim2.new(1, 0, 0, totalHeight)
                        }, 0.2)
                    else
                        Utility:TweenObject(optionsFrame, {
                            Size = UDim2.new(1, 0, 0, 0)
                        }, 0.2)
                        wait(0.2)
                        optionsFrame.Visible = false
                    end
                    
                    -- Rotate icon
                    Utility:TweenObject(dropdownIcon, {
                        Rotation = isOpen and 180 or 0
                    }, 0.2)
                end
                
                dropdownButton.MouseButton1Click:Connect(toggleDropdown)
                
                -- Touch support for mobile
                if isMobile then
                    dropdownButton.TouchTap:Connect(toggleDropdown)
                end
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        dropdownFrame.BackgroundColor3 = theme.ElementColor
                        dropdownButton.TextColor3 = theme.TextColor
                        dropdownIcon.ImageColor3 = theme.TextColor
                        optionsFrame.BackgroundColor3 = theme.ElementColor
                    end
                end)()
                
                local dropdownFunctions = {}
                
                function dropdownFunctions:SetOptions(newOptions)
                    options = newOptions
                    if not table.find(options, selectedOption) then
                        selectedOption = options[1] or ""
                        updateDropdown()
                    end
                end
                
                function dropdownFunctions:SetSelected(option)
                    if table.find(options, option) then
                        selectedOption = option
                        updateDropdown()
                    end
                end
                
                function dropdownFunctions:GetSelected()
                    return selectedOption
                end
                
                return dropdownFunctions
            end
            
            -- Color picker element
            function Elements:NewColorPicker(pickerName, defaultColor, callback)
                pickerName = pickerName or "Color Picker"
                defaultColor = defaultColor or Color3.fromRGB(255, 0, 0)
                callback = callback or function() end
                
                local colorPickerFrame = Instance.new("Frame")
                colorPickerFrame.Name = pickerName.."ColorPicker"
                colorPickerFrame.Parent = contentFrame
                colorPickerFrame.BackgroundColor3 = theme.ElementColor
                colorPickerFrame.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                colorPickerFrame.ClipsDescendants = true
                
                local colorPickerCorner = Instance.new("UICorner")
                colorPickerCorner.CornerRadius = UDim.new(0, 4)
                colorPickerCorner.Parent = colorPickerFrame
                
                local colorPickerButton = Instance.new("TextButton")
                colorPickerButton.Name = "Button"
                colorPickerButton.Parent = colorPickerFrame
                colorPickerButton.BackgroundTransparency = 1
                colorPickerButton.Size = UDim2.new(1, 0, 0, isMobile and 35 or 30)
                colorPickerButton.AutoButtonColor = false
                colorPickerButton.Font = Enum.Font.Gotham
                colorPickerButton.Text = pickerName
                colorPickerButton.TextColor3 = theme.TextColor
                colorPickerButton.TextSize = isMobile and 16 or 14
                colorPickerButton.TextXAlignment = Enum.TextXAlignment.Left
                
                local colorPreview = Instance.new("Frame")
                colorPreview.Name = "Preview"
                colorPreview.Parent = colorPickerButton
                colorPreview.BackgroundColor3 = defaultColor
                colorPreview.Position = UDim2.new(0.9, -25, 0.5, -10)
                colorPreview.Size = UDim2.new(0, 20, 0, 20)
                
                local previewCorner = Instance.new("UICorner")
                previewCorner.CornerRadius = UDim.new(0, 4)
                previewCorner.Parent = colorPreview
                
                local colorPickerWindow = Instance.new("Frame")
                colorPickerWindow.Name = "PickerWindow"
                colorPickerWindow.Parent = colorPickerFrame
                colorPickerWindow.BackgroundColor3 = theme.ElementColor
                colorPickerWindow.Position = UDim2.new(0, 0, 0, isMobile and 35 or 30)
                colorPickerWindow.Size = UDim2.new(1, 0, 0, 0)
                colorPickerWindow.Visible = false
                colorPickerWindow.ZIndex = 2
                
                local windowCorner = Instance.new("UICorner")
                windowCorner.CornerRadius = UDim.new(0, 4)
                windowCorner.Parent = colorPickerWindow
                
                local colorCanvas = Instance.new("ImageLabel")
                colorCanvas.Name = "ColorCanvas"
                colorCanvas.Parent = colorPickerWindow
                colorCanvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                colorCanvas.Position = UDim2.new(0.05, 0, 0.05, 0)
                colorCanvas.Size = UDim2.new(0.6, 0, 0.6, 0)
                colorCanvas.Image = "rbxassetid://2615689005"
                
                local canvasCorner = Instance.new("UICorner")
                canvasCorner.CornerRadius = UDim.new(0, 4)
                canvasCorner.Parent = colorCanvas
                
                local hueSlider = Instance.new("ImageLabel")
                hueSlider.Name = "HueSlider"
                hueSlider.Parent = colorPickerWindow
                hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueSlider.Position = UDim2.new(0.7, 0, 0.05, 0)
                hueSlider.Size = UDim2.new(0.2, 0, 0.6, 0)
                hueSlider.Image = "rbxassetid://2615692420"
                
                local sliderCorner = Instance.new("UICorner")
                sliderCorner.CornerRadius = UDim.new(0, 4)
                sliderCorner.Parent = hueSlider
                
                local currentColor = defaultColor
                local currentHue = 0
                local currentSat = 1
                local currentVal = 1
                
                local function updateColor(h, s, v)
                    currentHue = h
                    currentSat = s
                    currentVal = v
                    currentColor = Color3.fromHSV(h, s, v)
                    colorPreview.BackgroundColor3 = currentColor
                    callback(currentColor)
                end
                
                local function rgbToHsv(color)
                    local r, g, b = color.r, color.g, color.b
                    local max, min = math.max(r, g, b), math.min(r, g, b)
                    local h, s, v
                    
                    v = max
                    
                    local d = max - min
                    if max == 0 then
                        s = 0
                    else
                        s = d / max
                    end
                    
                    if max == min then
                        h = 0
                    else
                        if max == r then
                            h = (g - b) / d
                            if g < b then
                                h = h + 6
                            end
                        elseif max == g then
                            h = (b - r) / d + 2
                        elseif max == b then
                            h = (r - g) / d + 4
                        end
                        h = h / 6
                    end
                    
                    return h, s, v
                end
                
                -- Initialize with default color
                local h, s, v = rgbToHsv(defaultColor)
                updateColor(h, s, v)
                
                local isOpen = false
                local colorDragging = false
                local hueDragging = false
                
                local function togglePicker()
                    isOpen = not isOpen
                    
                    if isOpen then
                        -- Close other open pickers
                        for _, child in pairs(contentFrame:GetChildren()) do
                            if child:IsA("Frame") and child.Name:find("ColorPicker") and child ~= colorPickerFrame then
                                local pickerWindow = child:FindFirstChild("PickerWindow")
                                if pickerWindow and pickerWindow.Visible then
                                    Utility:TweenObject(pickerWindow, {
                                        Size = UDim2.new(1, 0, 0, 0)
                                    }, 0.2)
                                    wait(0.2)
                                    pickerWindow.Visible = false
                                end
                            end
                        end
                        
                        colorPickerWindow.Visible = true
                        Utility:TweenObject(colorPickerWindow, {
                            Size = UDim2.new(1, 0, 0, isMobile and 200 or 150)
                        }, 0.2)
                    else
                        Utility:TweenObject(colorPickerWindow, {
                            Size = UDim2.new(1, 0, 0, 0)
                        }, 0.2)
                        wait(0.2)
                        colorPickerWindow.Visible = false
                    end
                end
                
                colorPickerButton.MouseButton1Click:Connect(togglePicker)
                
                -- Touch support for mobile
                if isMobile then
                    colorPickerButton.TouchTap:Connect(togglePicker)
                end
                
                -- Color canvas interaction
                colorCanvas.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        colorDragging = true
                        local x = (input.Position.X - colorCanvas.AbsolutePosition.X) / colorCanvas.AbsoluteSize.X
                        local y = (input.Position.Y - colorCanvas.AbsolutePosition.Y) / colorCanvas.AbsoluteSize.Y
                        x = math.clamp(x, 0, 1)
                        y = math.clamp(y, 0, 1)
                        updateColor(currentHue, x, 1 - y)
                    end
                end)
                
                colorCanvas.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        colorDragging = false
                    end
                end)
                
                colorCanvas.InputChanged:Connect(function(input)
                    if colorDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                       input.UserInputType == Enum.UserInputType.Touch) then
                        local x = (input.Position.X - colorCanvas.AbsolutePosition.X) / colorCanvas.AbsoluteSize.X
                        local y = (input.Position.Y - colorCanvas.AbsolutePosition.Y) / colorCanvas.AbsoluteSize.Y
                        x = math.clamp(x, 0, 1)
                        y = math.clamp(y, 0, 1)
                        updateColor(currentHue, x, 1 - y)
                    end
                end)
                
                -- Hue slider interaction
                hueSlider.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = true
                        local y = (input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y
                        y = math.clamp(y, 0, 1)
                        updateColor(1 - y, currentSat, currentVal)
                    end
                end)
                
                hueSlider.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                       input.UserInputType == Enum.UserInputType.Touch then
                        hueDragging = false
                    end
                end)
                
                hueSlider.InputChanged:Connect(function(input)
                    if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                       input.UserInputType == Enum.UserInputType.Touch) then
                        local y = (input.Position.Y - hueSlider.AbsolutePosition.Y) / hueSlider.AbsoluteSize.Y
                        y = math.clamp(y, 0, 1)
                        updateColor(1 - y, currentSat, currentVal)
                    end
                end)
                
                -- Theme updating
                coroutine.wrap(function()
                    while wait() do
                        colorPickerFrame.BackgroundColor3 = theme.ElementColor
                        colorPickerButton.TextColor3 = theme.TextColor
                        colorPickerWindow.BackgroundColor3 = theme.ElementColor
                    end
                end)()
                
                local colorPickerFunctions = {}
                
                function colorPickerFunctions:SetColor(color)
                    local h, s, v = rgbToHsv(color)
                    updateColor(h, s, v)
                end
                
                function colorPickerFunctions:GetColor()
                    return currentColor
                end
                
                return colorPickerFunctions
            end
            
            return Elements
        end
        
        return Sections
    end
    
    return Tabs
end

return Nova