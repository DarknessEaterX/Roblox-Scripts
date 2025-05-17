local UILibrary = {
    Version = "1.0",
    Themes = {},
    CurrentTheme = "Default",
    Components = {},
    ActiveWindows = {},
    Notifications = {}
}

-- Main container that will hold all UI elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UILibrary"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.DisplayOrder = 10
screenGui.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

function UILibrary.CreateWindow(title)
    local window = {}
    window.Title = title or "UI Window"
    
    -- Main frame
    window.MainFrame = Instance.new("Frame")
    window.MainFrame.Name = "Window"
    window.MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    window.MainFrame.BorderSizePixel = 0
    window.MainFrame.Size = UDim2.new(0, 400, 0, 500)
    window.MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    window.MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    window.MainFrame.ClipsDescendants = true
    
    -- Aspect ratio constraint for mobile scaling
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 0.8
    aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
    aspectRatio.DominantAxis = Enum.DominantAxis.Width
    aspectRatio.Parent = window.MainFrame
    
    -- Title bar
    window.TitleBar = Instance.new("Frame")
    window.TitleBar.Name = "TitleBar"
    window.TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    window.TitleBar.BorderSizePixel = 0
    window.TitleBar.Size = UDim2.new(1, 0, 0, 30)
    window.TitleBar.Parent = window.MainFrame
    
    -- Title text
    window.TitleLabel = Instance.new("TextLabel")
    window.TitleLabel.Name = "Title"
    window.TitleLabel.Text = window.Title
    window.TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    window.TitleLabel.TextSize = 14
    window.TitleLabel.Font = Enum.Font.Gotham
    window.TitleLabel.BackgroundTransparency = 1
    window.TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    window.TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    window.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    window.TitleLabel.Parent = window.TitleBar
    
    -- Drag functionality
    local dragStart, startPos
    window.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = window.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)
    
    window.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragStart then
                local delta = input.Position - dragStart
                window.MainFrame.Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    
    -- Close button
    window.CloseButton = Instance.new("TextButton")
    window.CloseButton.Name = "CloseButton"
    window.CloseButton.Text = "X"
    window.CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    window.CloseButton.TextSize = 14
    window.CloseButton.Font = Enum.Font.Gotham
    window.CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    window.CloseButton.BorderSizePixel = 0
    window.CloseButton.Size = UDim2.new(0, 30, 1, 0)
    window.CloseButton.Position = UDim2.new(1, -30, 0, 0)
    window.CloseButton.Parent = window.TitleBar
    
    window.CloseButton.MouseButton1Click:Connect(function()
        window.MainFrame:Destroy()
        UILibrary.ActiveWindows[window] = nil
    end)
    
    -- Tab container
    window.TabContainer = Instance.new("Frame")
    window.TabContainer.Name = "TabContainer"
    window.TabContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    window.TabContainer.BorderSizePixel = 0
    window.TabContainer.Size = UDim2.new(1, 0, 0, 30)
    window.TabContainer.Position = UDim2.new(0, 0, 0, 30)
    window.TabContainer.Parent = window.MainFrame
    
    -- Content container
    window.ContentContainer = Instance.new("Frame")
    window.ContentContainer.Name = "Content"
    window.ContentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    window.ContentContainer.BorderSizePixel = 0
    window.ContentContainer.Size = UDim2.new(1, 0, 1, -60)
    window.ContentContainer.Position = UDim2.new(0, 0, 0, 60)
    window.ContentContainer.Parent = window.MainFrame
    
    -- Layout for tabs
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 0)
    tabLayout.Parent = window.TabContainer
    
    -- Layout for content
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.Padding = UDim.new(0, 5)
    contentLayout.Parent = window.ContentContainer
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 10)
    contentPadding.PaddingRight = UDim.new(0, 10)
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = window.ContentContainer
    
    window.Tabs = {}
    window.ActiveTab = nil
    
    -- Add to active windows
    UILibrary.ActiveWindows[window] = true
    window.MainFrame.Parent = screenGui
    
    return window
end

function UILibrary.Window:AddTab(name)
    local tab = {}
    tab.Name = name or "Tab"
    tab.Window = self
    
    -- Tab button
    tab.Button = Instance.new("TextButton")
    tab.Button.Name = name
    tab.Button.Text = name
    tab.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
    tab.Button.TextSize = 14
    tab.Button.Font = Enum.Font.Gotham
    tab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tab.Button.BorderSizePixel = 0
    tab.Button.Size = UDim2.new(0, 80, 1, 0)
    tab.Button.Parent = self.TabContainer
    
    -- Tab content
    tab.Content = Instance.new("Frame")
    tab.Content.Name = name
    tab.Content.BackgroundTransparency = 1
    tab.Content.Size = UDim2.new(1, 0, 1, 0)
    tab.Content.Visible = false
    tab.Content.Parent = self.ContentContainer
    
    -- Tab content layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 10)
    layout.Parent = tab.Content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = tab.Content
    
    tab.Sections = {}
    
    -- Tab selection logic
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    -- Select this tab if it's the first one
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    
    table.insert(self.Tabs, tab)
    return tab
end

function UILibrary.Window:SelectTab(tab)
    if self.ActiveTab then
        self.ActiveTab.Content.Visible = false
        self.ActiveTab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
    
    self.ActiveTab = tab
    tab.Content.Visible = true
    tab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end

function UILibrary.Tab:AddSection(title)
    local section = {}
    section.Title = title or "Section"
    section.Tab = self
    
    -- Section frame
    section.Frame = Instance.new("Frame")
    section.Frame.Name = title
    section.Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    section.Frame.BorderSizePixel = 0
    section.Frame.Size = UDim2.new(1, 0, 0, 0) -- Height will be auto-adjusted
    section.Frame.AutomaticSize = Enum.AutomaticSize.Y
    section.Frame.Parent = self.Content
    
    -- Section title
    section.TitleLabel = Instance.new("TextLabel")
    section.TitleLabel.Name = "Title"
    section.TitleLabel.Text = " " .. section.Title .. " "
    section.TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    section.TitleLabel.TextSize = 14
    section.TitleLabel.Font = Enum.Font.GothamBold
    section.TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    section.TitleLabel.BorderSizePixel = 0
    section.TitleLabel.Size = UDim2.new(0, 0, 0, 20)
    section.TitleLabel.Position = UDim2.new(0, 10, 0, 5)
    section.TitleLabel.AutomaticSize = Enum.AutomaticSize.X
    section.TitleLabel.Parent = section.Frame
    
    -- Section content
    section.Content = Instance.new("Frame")
    section.Content.Name = "Content"
    section.Content.BackgroundTransparency = 1
    section.Content.Size = UDim2.new(1, 0, 0, 0)
    section.Content.Position = UDim2.new(0, 0, 0, 30)
    section.Content.AutomaticSize = Enum.AutomaticSize.Y
    section.Content.Parent = section.Frame
    
    -- Section content layout
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 5)
    layout.Parent = section.Content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = section.Content
    
    section.Elements = {}
    
    table.insert(self.Sections, section)
    return section
end

function UILibrary.Section:AddButton(text, callback)
    local button = {}
    button.Text = text or "Button"
    button.Callback = callback or function() end
    
    -- Button frame
    button.Frame = Instance.new("Frame")
    button.Frame.Name = "Button"
    button.Frame.BackgroundTransparency = 1
    button.Frame.Size = UDim2.new(1, 0, 0, 30)
    button.Frame.Parent = self.Content
    
    -- Button element
    button.Button = Instance.new("TextButton")
    button.Button.Name = "Button"
    button.Button.Text = button.Text
    button.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Button.TextSize = 14
    button.Button.Font = Enum.Font.Gotham
    button.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Button.BorderSizePixel = 0
    button.Button.Size = UDim2.new(1, 0, 1, 0)
    button.Button.Parent = button.Frame
    
    -- Button effects
    button.Button.MouseEnter:Connect(function()
        button.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    button.Button.MouseLeave:Connect(function()
        button.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
    
    button.Button.MouseButton1Down:Connect(function()
        button.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end)
    
    button.Button.MouseButton1Up:Connect(function()
        button.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.Callback()
    end)
    
    -- Touch support
    button.Button.TouchLongPress:Connect(function()
        button.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        task.wait(0.1)
        button.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.Callback()
    end)
    
    table.insert(self.Elements, button)
    return button
end

function UILibrary.Section:AddToggle(text, default, callback)
    local toggle = {}
    toggle.Text = text or "Toggle"
    toggle.Value = default or false
    toggle.Callback = callback or function() end
    
    -- Toggle frame
    toggle.Frame = Instance.new("Frame")
    toggle.Frame.Name = "Toggle"
    toggle.Frame.BackgroundTransparency = 1
    toggle.Frame.Size = UDim2.new(1, 0, 0, 30)
    toggle.Frame.Parent = self.Content
    
    -- Toggle label
    toggle.Label = Instance.new("TextLabel")
    toggle.Label.Name = "Label"
    toggle.Label.Text = toggle.Text
    toggle.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Label.TextSize = 14
    toggle.Label.Font = Enum.Font.Gotham
    toggle.Label.BackgroundTransparency = 1
    toggle.Label.Size = UDim2.new(0.7, 0, 1, 0)
    toggle.Label.TextXAlignment = Enum.TextXAlignment.Left
    toggle.Label.Parent = toggle.Frame
    
    -- Toggle switch
    toggle.Switch = Instance.new("Frame")
    toggle.Switch.Name = "Switch"
    toggle.Switch.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    toggle.Switch.BorderSizePixel = 0
    toggle.Switch.Size = UDim2.new(0.3, 0, 0.6, 0)
    toggle.Switch.Position = UDim2.new(0.7, 0, 0.2, 0)
    toggle.Switch.Parent = toggle.Frame
    
    -- Toggle indicator
    toggle.Indicator = Instance.new("Frame")
    toggle.Indicator.Name = "Indicator"
    toggle.Indicator.BackgroundColor3 = toggle.Value and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 80, 80)
    toggle.Indicator.BorderSizePixel = 0
    toggle.Indicator.Size = UDim2.new(0.5, 0, 1, 0)
    toggle.Indicator.Position = toggle.Value and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    toggle.Indicator.Parent = toggle.Switch
    
    -- Toggle function
    function toggle:SetValue(value)
        self.Value = value
        self.Indicator.BackgroundColor3 = value and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 80, 80)
        self.Indicator.Position = value and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
        self.Callback(value)
    end
    
    -- Toggle click
    toggle.Switch.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)
    
    -- Touch support
    toggle.Switch.TouchTap:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)
    
    table.insert(self.Elements, toggle)
    return toggle
end

function UILibrary.Section:AddSlider(text, min, max, default, callback, decimal)
    local slider = {}
    slider.Text = text or "Slider"
    slider.Min = min or 0
    slider.Max = max or 100
    slider.Value = default or min
    slider.Decimal = decimal or 0
    slider.Callback = callback or function() end
    
    -- Slider frame
    slider.Frame = Instance.new("Frame")
    slider.Frame.Name = "Slider"
    slider.Frame.BackgroundTransparency = 1
    slider.Frame.Size = UDim2.new(1, 0, 0, 50)
    slider.Frame.Parent = self.Content
    
    -- Slider label
    slider.Label = Instance.new("TextLabel")
    slider.Label.Name = "Label"
    slider.Label.Text = slider.Text
    slider.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Label.TextSize = 14
    slider.Label.Font = Enum.Font.Gotham
    slider.Label.BackgroundTransparency = 1
    slider.Label.Size = UDim2.new(1, 0, 0, 20)
    slider.Label.TextXAlignment = Enum.TextXAlignment.Left
    slider.Label.Parent = slider.Frame
    
    -- Slider value display
    slider.ValueLabel = Instance.new("TextLabel")
    slider.ValueLabel.Name = "Value"
    slider.ValueLabel.Text = tostring(slider.Value)
    slider.ValueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    slider.ValueLabel.TextSize = 14
    slider.ValueLabel.Font = Enum.Font.Gotham
    slider.ValueLabel.BackgroundTransparency = 1
    slider.ValueLabel.Size = UDim2.new(1, 0, 0, 20)
    slider.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    slider.ValueLabel.Parent = slider.Frame
    
    -- Slider track
    slider.Track = Instance.new("Frame")
    slider.Track.Name = "Track"
    slider.Track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slider.Track.BorderSizePixel = 0
    slider.Track.Size = UDim2.new(1, 0, 0, 5)
    slider.Track.Position = UDim2.new(0, 0, 0, 40)
    slider.Track.Parent = slider.Frame
    
    -- Slider fill
    slider.Fill = Instance.new("Frame")
    slider.Fill.Name = "Fill"
    slider.Fill.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    slider.Fill.BorderSizePixel = 0
    slider.Fill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
    slider.Fill.Parent = slider.Track
    
    -- Slider thumb
    slider.Thumb = Instance.new("Frame")
    slider.Thumb.Name = "Thumb"
    slider.Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    slider.Thumb.BorderSizePixel = 0
    slider.Thumb.Size = UDim2.new(0, 10, 0, 15)
    slider.Thumb.Position = UDim2.new(slider.Fill.Size.X.Scale, -5, -0.5, 0)
    slider.Thumb.Parent = slider.Track
    
    -- Slider function
    function slider:SetValue(value)
        value = math.clamp(value, self.Min, self.Max)
        if self.Decimal == 0 then
            value = math.floor(value)
        else
            value = math.floor(value * (10 ^ self.Decimal)) / (10 ^ self.Decimal)
        end
        
        self.Value = value
        self.ValueLabel.Text = tostring(value)
        self.Fill.Size = UDim2.new((value - self.Min) / (self.Max - self.Min), 0, 1, 0)
        self.Thumb.Position = UDim2.new(self.Fill.Size.X.Scale, -5, -0.5, 0)
        self.Callback(value)
    end
    
    -- Slider dragging
    local dragging = false
    
    local function updateSlider(input)
        local relativeX = (input.Position.X - slider.Track.AbsolutePosition.X) / slider.Track.AbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        local value = slider.Min + (slider.Max - slider.Min) * relativeX
        slider:SetValue(value)
    end
    
    slider.Thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    
    slider.Thumb.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    -- Click on track to jump
    slider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
        end
    end)
    
    table.insert(self.Elements, slider)
    return slider
end

function UILibrary.Section:AddDropdown(text, options, default, callback)
    local dropdown = {}
    dropdown.Text = text or "Dropdown"
    dropdown.Options = options or {}
    dropdown.Value = default or (options and options[1]) or nil
    dropdown.Callback = callback or function() end
    dropdown.Open = false
    
    -- Dropdown frame
    dropdown.Frame = Instance.new("Frame")
    dropdown.Frame.Name = "Dropdown"
    dropdown.Frame.BackgroundTransparency = 1
    dropdown.Frame.Size = UDim2.new(1, 0, 0, 30)
    dropdown.Frame.AutomaticSize = Enum.AutomaticSize.Y
    dropdown.Frame.Parent = self.Content
    
    -- Dropdown label
    dropdown.Label = Instance.new("TextLabel")
    dropdown.Label.Name = "Label"
    dropdown.Label.Text = dropdown.Text
    dropdown.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Label.TextSize = 14
    dropdown.Label.Font = Enum.Font.Gotham
    dropdown.Label.BackgroundTransparency = 1
    dropdown.Label.Size = UDim2.new(1, 0, 0, 20)
    dropdown.Label.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.Label.Parent = dropdown.Frame
    
    -- Dropdown button
    dropdown.Button = Instance.new("TextButton")
    dropdown.Button.Name = "Button"
    dropdown.Button.Text = dropdown.Value or "Select..."
    dropdown.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Button.TextSize = 14
    dropdown.Button.Font = Enum.Font.Gotham
    dropdown.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    dropdown.Button.BorderSizePixel = 0
    dropdown.Button.Size = UDim2.new(1, 0, 0, 30)
    dropdown.Button.Position = UDim2.new(0, 0, 0, 25)
    dropdown.Button.Parent = dropdown.Frame
    
    -- Dropdown options frame
    dropdown.OptionsFrame = Instance.new("Frame")
    dropdown.OptionsFrame.Name = "Options"
    dropdown.OptionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    dropdown.OptionsFrame.BorderSizePixel = 0
    dropdown.OptionsFrame.Size = UDim2.new(1, 0, 0, 0)
    dropdown.OptionsFrame.Position = UDim2.new(0, 0, 0, 60)
    dropdown.OptionsFrame.Visible = false
    dropdown.OptionsFrame.AutomaticSize = Enum.AutomaticSize.Y
    dropdown.OptionsFrame.Parent = dropdown.Frame
    
    -- Options layout
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.FillDirection = Enum.FillDirection.Vertical
    optionsLayout.Padding = UDim.new(0, 1)
    optionsLayout.Parent = dropdown.OptionsFrame
    
    -- Dropdown function
    function dropdown:SetOptions(newOptions)
        self.Options = newOptions or {}
        self:RefreshOptions()
    end
    
    function dropdown:SetValue(value)
        if table.find(self.Options, value) then
            self.Value = value
            self.Button.Text = value
            self.Callback(value)
        end
    end
    
    function dropdown:RefreshOptions()
        -- Clear existing options
        for _, child in ipairs(dropdown.OptionsFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add new options
        for _, option in ipairs(self.Options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = option
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.TextSize = 14
            optionButton.Font = Enum.Font.Gotham
            optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            optionButton.BorderSizePixel = 0
            optionButton.Size = UDim2.new(1, 0, 0, 30)
            optionButton.Parent = dropdown.OptionsFrame
            
            optionButton.MouseButton1Click:Connect(function()
                dropdown:SetValue(option)
                dropdown:Toggle()
            end)
            
            optionButton.TouchTap:Connect(function()
                dropdown:SetValue(option)
                dropdown:Toggle()
            end)
        end
    end
    
    function dropdown:Toggle()
        self.Open = not self.Open
        self.OptionsFrame.Visible = self.Open
        dropdown.Frame.Size = UDim2.new(1, 0, 0, self.Open and (60 + #self.Options * 31) or 60)
    end
    
    -- Initialize options
    dropdown:RefreshOptions()
    
    -- Toggle dropdown
    dropdown.Button.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    dropdown.Button.TouchTap:Connect(function()
        dropdown:Toggle()
    end)
    
    table.insert(self.Elements, dropdown)
    return dropdown
end

function UILibrary.Notify(title, message, duration)
    duration = duration or 5
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notification.BorderSizePixel = 0
    notification.Size = UDim2.new(0, 300, 0, 0)
    notification.Position = UDim2.new(1, -310, 1, -10)
    notification.AnchorPoint = Vector2.new(1, 1)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = notification
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0, 5)
    layout.Parent = notification
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, 0, 0, 0)
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = notification
    
    -- Animate in
    notification.Size = UDim2.new(0, 300, 0, 0)
    notification.AutomaticSize = Enum.AutomaticSize.Y
    notification.Position = UDim2.new(1, -310, 1, 10)
    
    local tweenIn = game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -310, 1, -10)}
    )
    tweenIn:Play()
    
    -- Close after duration
    task.spawn(function()
        task.wait(duration)
        
        local tweenOut = game:GetService("TweenService"):Create(
            notification,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(1, -310, 1, 10)}
        )
        
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notification:Destroy()
    end)
    
    -- Manual close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "Close"
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.BackgroundTransparency = 1
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.Parent = notification
    
    closeButton.MouseButton1Click:Connect(function()
        notification:Destroy()
    end)
    
    closeButton.TouchTap:Connect(function()
        notification:Destroy()
    end)
    
    return notification
end

return UILibrary