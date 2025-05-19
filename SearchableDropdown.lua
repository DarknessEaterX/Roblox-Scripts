local SearchableDropdown = {}
SearchableDropdown.__index = SearchableDropdown

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Default colors
local DEFAULT_COLORS = {
    Background = Color3.fromRGB(35, 35, 40),
    Item = Color3.fromRGB(45, 45, 50),
    ItemHover = Color3.fromRGB(65, 65, 70),
    Highlight = Color3.fromRGB(100, 150, 255),
    Text = Color3.new(1, 1, 1),
    Placeholder = Color3.fromRGB(180, 180, 180),
    Selected = Color3.fromRGB(80, 120, 200)
}

function SearchableDropdown.AddSearchableDropdown(config)
    local self = setmetatable({}, SearchableDropdown)
    
    -- Validate and set configuration
    self.name = config.Name or "Searchable Dropdown"
    self.options = config.Options or {}
    self.currentOption = config.CurrentOption or (config.MultipleOptions and {} or nil)
    self.multipleOptions = config.MultipleOptions or false
    self.callback = config.Callback or function() end
    self.parent = config.Parent or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- UI configuration
    self.position = config.Position or UDim2.new(0.5, -150, 0.2, 0)
    self.size = config.Size or UDim2.new(0, 300, 0, 40)
    self.listSize = config.ListSize or UDim2.new(0, 300, 0, 150)
    self.colors = config.Colors or DEFAULT_COLORS
    self.placeholder = config.Placeholder or "Search options..."
    self.animationSpeed = config.AnimationSpeed or 0.2
    
    -- State
    self.isListOpen = false
    self.selectedItems = {}
    
    -- Initialize selected items
    self:InitializeSelectedItems()
    
    -- Create UI
    self:CreateUI()
    
    return self
end

function SearchableDropdown:InitializeSelectedItems()
    if self.multipleOptions and type(self.currentOption) == "table" then
        for _, option in pairs(self.currentOption) do
            if table.find(self.options, option) then
                table.insert(self.selectedItems, option)
            end
        end
    elseif not self.multipleOptions and self.currentOption then
        if table.find(self.options, self.currentOption) then
            table.insert(self.selectedItems, self.currentOption)
        end
    end
end

function SearchableDropdown:CreateUI()
    -- ScreenGui container
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = self.name .. "UI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = self.parent
    
    -- Main dropdown frame
    self.dropdownFrame = Instance.new("Frame")
    self.dropdownFrame.Size = self.size
    self.dropdownFrame.Position = self.position
    self.dropdownFrame.BackgroundColor3 = self.colors.Background
    self.dropdownFrame.BorderSizePixel = 0
    self.dropdownFrame.Name = "DropdownFrame"
    self.dropdownFrame.ClipsDescendants = true
    self.dropdownFrame.Parent = self.screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = self.dropdownFrame
    
    -- Search box
    self.searchBox = Instance.new("TextBox")
    self.searchBox.Size = UDim2.new(1, -40, 1, 0)
    self.searchBox.Position = UDim2.new(0, 10, 0, 0)
    self.searchBox.PlaceholderText = self.placeholder
    self.searchBox.PlaceholderColor3 = self.colors.Placeholder
    self.searchBox.BackgroundTransparency = 1
    self.searchBox.TextColor3 = self.colors.Text
    self.searchBox.TextSize = 14
    self.searchBox.Font = Enum.Font.Gotham
    self.searchBox.ClearTextOnFocus = false
    self.searchBox.TextXAlignment = Enum.TextXAlignment.Left
    self.searchBox.TextEditable = true
    self.searchBox.Parent = self.dropdownFrame
    
    -- Set initial text
    self:UpdateSearchBoxText()
    
    -- Dropdown icon
    self.dropdownIcon = Instance.new("ImageLabel")
    self.dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
    self.dropdownIcon.Position = UDim2.new(1, -30, 0.5, -10)
    self.dropdownIcon.BackgroundTransparency = 1
    self.dropdownIcon.Image = "rbxassetid://3926305904"
    self.dropdownIcon.ImageRectOffset = Vector2.new(284, 4)
    self.dropdownIcon.ImageRectSize = Vector2.new(24, 24)
    self.dropdownIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    self.dropdownIcon.Parent = self.dropdownFrame
    
    -- Dropdown list frame
    self.listFrame = Instance.new("ScrollingFrame")
    self.listFrame.Size = UDim2.new(0, self.size.X.Offset, 0, 0) -- Start collapsed
    self.listFrame.Position = UDim2.new(0, 0, 1, 5)
    self.listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    self.listFrame.BorderSizePixel = 0
    self.listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.listFrame.ScrollBarThickness = 4
    self.listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    self.listFrame.Visible = false
    self.listFrame.Name = "ListFrame"
    self.listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.listFrame.Parent = self.dropdownFrame
    
    -- Rounded corners for list
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = self.listFrame
    
    -- Add padding
    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingLeft = UDim.new(0, 5)
    listPadding.PaddingRight = UDim.new(0, 5)
    listPadding.PaddingTop = UDim.new(0, 5)
    listPadding.PaddingBottom = UDim.new(0, 5)
    listPadding.Parent = self.listFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = self.listFrame
    
    -- Connect events
    self:SetupEvents()
    
    -- Initial refresh
    self:RefreshList("")
end

function SearchableDropdown:UpdateSearchBoxText()
    if not self.multipleOptions and #self.selectedItems > 0 then
        self.searchBox.Text = self.selectedItems[1]
    elseif self.multipleOptions and #self.selectedItems > 0 then
        self.searchBox.Text = #self.selectedItems .. " selected"
    else
        self.searchBox.Text = ""
    end
end

function SearchableDropdown:SetupEvents()
    -- Text changed event
    self.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:RefreshList(self.searchBox.Text)
        self:ToggleDropdown(true)
    end)
    
    -- Focus events
    self.searchBox.Focused:Connect(function()
        self:ToggleDropdown(true)
        self:RefreshList(self.searchBox.Text)
    end)
    
    self.searchBox.FocusLost:Connect(function()
        task.delay(0.2, function() -- Slightly longer delay to allow for click events
            if not self.searchBox:IsFocused() and not self.isMouseInList() then
                self:ToggleDropdown(false)
            end
        end)
    end)
    
    -- Close dropdown when clicking outside
    self.clickOutsideConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not self:isMouseInDropdown() and not self:isMouseInList() and self.isListOpen then
                self:ToggleDropdown(false)
            end
        end
    end)
end

function SearchableDropdown:isMouseInDropdown()
    local mousePos = UserInputService:GetMouseLocation()
    local absPos = self.dropdownFrame.AbsolutePosition
    local absSize = self.dropdownFrame.AbsoluteSize
    return (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
            mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y)
end

function SearchableDropdown:isMouseInList()
    if not self.listFrame.Visible then return false end
    local mousePos = UserInputService:GetMouseLocation()
    local absPos = self.listFrame.AbsolutePosition
    local absSize = self.listFrame.AbsoluteSize
    return (mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
            mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y)
end

function SearchableDropdown:ToggleDropdown(show)
    if self.isListOpen == show then return end
    self.isListOpen = show
    
    -- Rotate dropdown icon
    local iconRotation = show and 180 or 0
    local tweenIcon = TweenService:Create(
        self.dropdownIcon,
        TweenInfo.new(self.animationSpeed, Enum.EasingStyle.Quad),
        {Rotation = iconRotation}
    )
    tweenIcon:Play()
    
    if show then
        self.listFrame.Visible = true
        local tween = TweenService:Create(
            self.listFrame,
            TweenInfo.new(self.animationSpeed, Enum.EasingStyle.Quad),
            {Size = self.listSize}
        )
        tween:Play()
    else
        local tween = TweenService:Create(
            self.listFrame,
            TweenInfo.new(self.animationSpeed, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.size.X.Offset, 0, 0)}
        )
        tween.Completed:Connect(function()
            if not self.isListOpen then -- Only hide if still closed
                self.listFrame.Visible = false
            end
        end)
        tween:Play()
    end
end

function SearchableDropdown:RefreshList(filter)
    -- Clear existing items
    for _, child in ipairs(self.listFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local hasMatches = false
    local firstMatch = nil

    for _, option in ipairs(self.options) do
        if filter == "" or string.find(string.lower(option), string.lower(filter)) then
            hasMatches = true
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 30)
            button.BackgroundColor3 = self.colors.Item
            button.TextColor3 = self.colors.Text
            button.Text = option
            button.Font = Enum.Font.Gotham
            button.TextSize = 14
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.Parent = self.listFrame
            
            -- Add padding
            local btnPadding = Instance.new("UIPadding", button)
            btnPadding.PaddingLeft = UDim.new(0, 10)
            
            -- Add rounded corners
            local btnCorner = Instance.new("UICorner", button)
            btnCorner.CornerRadius = UDim.new(0, 4)
            
            -- Highlight if selected
            if table.find(self.selectedItems, option) then
                button.BackgroundColor3 = self.colors.Selected
            end
            
            -- Hover effect
            button.MouseEnter:Connect(function()
                if not table.find(self.selectedItems, option) then
                    button.BackgroundColor3 = self.colors.ItemHover
                end
            end)
            
            button.MouseLeave:Connect(function()
                if not table.find(self.selectedItems, option) then
                    button.BackgroundColor3 = self.colors.Item
                else
                    button.BackgroundColor3 = self.colors.Selected
                end
            end)
            
            -- Click handler
            button.MouseButton1Click:Connect(function()
                if self.multipleOptions then
                    -- Toggle selection
                    local index = table.find(self.selectedItems, option)
                    if index then
                        table.remove(self.selectedItems, index)
                        button.BackgroundColor3 = self.colors.Item
                    else
                        table.insert(self.selectedItems, option)
                        button.BackgroundColor3 = self.colors.Selected
                    end
                    self:UpdateSearchBoxText()
                else
                    -- Single selection
                    self.selectedItems = {option}
                    self.searchBox.Text = option
                    self:ToggleDropdown(false)
                    
                    -- Reset all buttons to default color
                    for _, btn in ipairs(self.listFrame:GetChildren()) do
                        if btn:IsA("TextButton") then
                            btn.BackgroundColor3 = self.colors.Item
                        end
                    end
                    
                    -- Highlight the selected button
                    button.BackgroundColor3 = self.colors.Selected
                end
                
                -- Fire callback
                self.callback(self.multipleOptions and self.selectedItems or option)
            end)

            -- Highlight the first match
            if not firstMatch and string.sub(string.lower(option), 1, #filter) == string.lower(filter) and filter ~= "" then
                firstMatch = button
                if not table.find(self.selectedItems, option) then
                    button.BackgroundColor3 = self.colors.Highlight
                end
            end
        end
    end

    -- Show "No results" message if no matches
    if not hasMatches and filter ~= "" then
        local noResults = Instance.new("TextLabel", self.listFrame)
        noResults.Size = UDim2.new(1, -10, 0, 30)
        noResults.BackgroundTransparency = 1
        noResults.Text = "No results found"
        noResults.TextColor3 = self.colors.Placeholder
        noResults.Font = Enum.Font.Gotham
        noResults.TextSize = 14
    end
end

-- Public method to update options
function SearchableDropdown:UpdateOptions(newOptions)
    self.options = newOptions or {}
    self:RefreshList(self.searchBox.Text)
end

-- Public method to set current selection
function SearchableDropdown:SetSelection(selection)
    if self.multipleOptions then
        self.selectedItems = {}
        if type(selection) == "table" then
            for _, option in pairs(selection) do
                if table.find(self.options, option) then
                    table.insert(self.selectedItems, option)
                end
            end
        end
    else
        self.selectedItems = {}
        if selection and table.find(self.options, selection) then
            table.insert(self.selectedItems, selection)
        end
    end
    self:UpdateSearchBoxText()
    self:RefreshList("")
end

-- Public method to destroy the dropdown
function SearchableDropdown:Destroy()
    if self.clickOutsideConn then
        self.clickOutsideConn:Disconnect()
    end
    self.screenGui:Destroy()
end

return SearchableDropdown