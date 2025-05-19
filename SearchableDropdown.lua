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
    Placeholder = Color3.fromRGB(180, 180, 180)
}

function SearchableDropdown.new(config)
    local self = setmetatable({}, SearchableDropdown)
    
    -- Configuration with defaults
    self.items = config.items or {}
    self.position = config.position or UDim2.new(0.5, -150, 0.2, 0)
    self.size = config.size or UDim2.new(0, 300, 0, 40)
    self.listSize = config.listSize or UDim2.new(0, 300, 0, 150)
    self.colors = config.colors or DEFAULT_COLORS
    self.placeholder = config.placeholder or "Search items..."
    self.parent = config.parent or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    self.animationSpeed = config.animationSpeed or 0.2
    
    -- State
    self.isListOpen = false
    self.selectedItem = nil
    
    -- Create UI
    self:CreateUI()
    
    return self
end

function SearchableDropdown:CreateUI()
    -- ScreenGui container
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "SearchableDropdownUI"
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
    
    -- Search icon
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.new(0, 20, 0, 20)
    searchIcon.Position = UDim2.new(1, -30, 0.5, -10)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://3926305904"
    searchIcon.ImageRectOffset = Vector2.new(964, 324)
    searchIcon.ImageRectSize = Vector2.new(36, 36)
    searchIcon.ImageColor3 = Color3.fromRGB(200, 200, 200)
    searchIcon.Parent = self.dropdownFrame
    
    -- Dropdown list frame
    self.listFrame = Instance.new("ScrollingFrame")
    self.listFrame.Size = UDim2.new(0, 300, 0, 0) -- Start collapsed
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
end

function SearchableDropdown:SetupEvents()
    -- Text changed event
    self.searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:RefreshList(self.searchBox.Text)
        self:ToggleDropdown(true)
    end)
    
    -- Focus events
    self.searchBox.Focused:Connect(function()
        self:RefreshList(self.searchBox.Text)
        self:ToggleDropdown(true)
    end)
    
    self.searchBox.FocusLost:Connect(function()
        task.delay(0.1, function()
            if not self.searchBox:IsFocused() then
                self:ToggleDropdown(false)
            end
        end)
    end)
    
    -- Close dropdown when clicking outside
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local dropdownAbsPos = self.dropdownFrame.AbsolutePosition
            local dropdownSize = self.dropdownFrame.AbsoluteSize
            local listAbsPos = self.listFrame.AbsolutePosition
            local listSize = self.listFrame.AbsoluteSize
            
            local isInDropdown = (mousePos.X >= dropdownAbsPos.X and mousePos.X <= dropdownAbsPos.X + dropdownSize.X and
                                 mousePos.Y >= dropdownAbsPos.Y and mousePos.Y <= dropdownAbsPos.Y + dropdownSize.Y)
                                 
            local isInList = (mousePos.X >= listAbsPos.X and mousePos.X <= listAbsPos.X + listSize.X and
                             mousePos.Y >= listAbsPos.Y and mousePos.Y <= listAbsPos.Y + listSize.Y)
                             
            if not isInDropdown and not isInList and self.isListOpen then
                self:ToggleDropdown(false)
            end
        end
    end)
end

function SearchableDropdown:ToggleDropdown(show)
    if self.isListOpen == show then return end
    self.isListOpen = show
    
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
            {Size = UDim2.new(0, 300, 0, 0)}
        )
        tween.Completed:Connect(function()
            self.listFrame.Visible = false
        end)
        tween:Play()
    end
end

function SearchableDropdown:RefreshList(filter)
    -- Clear existing items
    for _, child in ipairs(self.listFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local hasMatches = false
    local firstMatch = nil

    for _, itemName in ipairs(self.items) do
        if filter == "" or string.find(string.lower(itemName), string.lower(filter)) then
            hasMatches = true
            
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 30)
            button.BackgroundColor3 = self.colors.Item
            button.TextColor3 = self.colors.Text
            button.Text = itemName
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
            
            -- Hover effect
            button.MouseEnter:Connect(function()
                if button.BackgroundColor3 ~= self.colors.Highlight then
                    button.BackgroundColor3 = self.colors.ItemHover
                end
            end)
            
            button.MouseLeave:Connect(function()
                if button.BackgroundColor3 ~= self.colors.Highlight then
                    button.BackgroundColor3 = self.colors.Item
                end
            end)
            
            -- Click handler
            button.MouseButton1Click:Connect(function()
                self.searchBox.Text = itemName
                self.searchBox:ReleaseFocus()
                self.selectedItem = itemName
                
                -- Highlight the selected item briefly
                button.BackgroundColor3 = self.colors.Highlight
                task.delay(0.5, function()
                    if button then
                        button.BackgroundColor3 = self.colors.Item
                    end
                end)
                
                -- Fire selection changed event
                if self.onItemSelected then
                    self.onItemSelected(itemName)
                end
            end)

            -- Highlight the first match (but don't auto-complete)
            if not firstMatch and string.sub(string.lower(itemName), 1, #filter) == string.lower(filter) and filter ~= "" then
                firstMatch = button
                button.BackgroundColor3 = self.colors.Highlight
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

-- Public method to update items
function SearchableDropdown:UpdateItems(newItems)
    self.items = newItems or {}
    self:RefreshList(self.searchBox.Text)
end

-- Public method to set selection callback
function SearchableDropdown:SetSelectionCallback(callback)
    self.onItemSelected = callback
end

-- Public method to get currently selected item
function SearchableDropdown:GetSelectedItem()
    return self.selectedItem
end

-- Public method to destroy the dropdown
function SearchableDropdown:Destroy()
    self.screenGui:Destroy()
end

return SearchableDropdown