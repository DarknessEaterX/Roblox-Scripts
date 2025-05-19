-- GroupFieldUILibrary module script in ReplicatedStorage
local GroupFieldUILibrary = {}
GroupFieldUILibrary.__index = GroupFieldUILibrary

-- Default theme
local DEFAULT_THEME = {
    Background = Color3.fromRGB(45, 45, 45),
    Header = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    Button = Color3.fromRGB(60, 60, 60),
    ButtonHover = Color3.fromRGB(80, 80, 80),
    Accent = Color3.fromRGB(0, 120, 215),
    Error = Color3.fromRGB(220, 60, 60),
    Success = Color3.fromRGB(60, 220, 60)
}

function GroupFieldUILibrary.new(groupData, options)
    local self = setmetatable({}, GroupFieldUILibrary)
    
    -- Configuration
    self.groupData = groupData or {}
    self.theme = options and options.theme or DEFAULT_THEME
    self.title = options and options.title or "Group Field Manager"
    self.toggleKey = options and options.toggleKey or Enum.KeyCode.F5
    self.defaultPosition = options and options.defaultPosition or UDim2.new(0.5, 0, 0.5, 0)
    self.defaultSize = options and options.defaultSize or UDim2.new(0.3, 0, 0.4, 0)
    
    -- State
    self.isVisible = false
    self.currentGroup = nil
    
    -- Create UI
    self:createUI()
    
    -- Set up controls
    self:setupControls()
    
    return self
end

function GroupFieldUILibrary:createUI()
    -- Create main GUI
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "GroupFieldUILibrary"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = self.defaultSize
    self.mainFrame.Position = self.defaultPosition
    self.mainFrame.BackgroundColor3 = self.theme.Background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.ClipsDescendants = true
    self.mainFrame.Visible = false
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.mainFrame
    
    -- Drop shadow
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Parent = self.mainFrame
    
    -- Title bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0.08, 0)
    self.titleBar.BackgroundColor3 = self.theme.Header
    self.titleBar.BorderSizePixel = 0
    
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    self.titleLabel.Position = UDim2.new(0.15, 0, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.title
    self.titleLabel.TextColor3 = self.theme.Text
    self.titleLabel.Font = Enum.Font.GothamBold
    self.titleLabel.TextSize = 16
    
    -- Close button
    self.closeButton = Instance.new("TextButton")
    self.closeButton.Name = "CloseButton"
    self.closeButton.Size = UDim2.new(0.1, 0, 1, 0)
    self.closeButton.Position = UDim2.new(0.9, 0, 0, 0)
    self.closeButton.BackgroundColor3 = self.theme.Error
    self.closeButton.Text = "X"
    self.closeButton.TextColor3 = self.theme.Text
    self.closeButton.Font = Enum.Font.GothamBold
    
    -- Toggle button (for mobile)
    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.Name = "ToggleButton"
    self.toggleButton.Size = UDim2.new(0.15, 0, 0.06, 0)
    self.toggleButton.Position = UDim2.new(0.02, 0, 0.92, 0)
    self.toggleButton.BackgroundColor3 = self.theme.Button
    self.toggleButton.Text = "Toggle GUI"
    self.toggleButton.TextColor3 = self.theme.Text
    self.toggleButton.Font = Enum.Font.Gotham
    self.toggleButton.TextSize = 14
    self.toggleButton.Visible = false
    
    -- Content frame
    self.contentFrame = Instance.new("Frame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.Size = UDim2.new(1, 0, 0.92, 0)
    self.contentFrame.Position = UDim2.new(0, 0, 0.08, 0)
    self.contentFrame.BackgroundTransparency = 1
    
    -- Groups list
    self.groupsList = Instance.new("ScrollingFrame")
    self.groupsList.Name = "GroupsList"
    self.groupsList.Size = UDim2.new(0.3, 0, 1, 0)
    self.groupsList.BackgroundTransparency = 1
    self.groupsList.ScrollBarThickness = 4
    
    self.groupsListLayout = Instance.new("UIListLayout")
    self.groupsListLayout.Padding = UDim.new(0, 5)
    self.groupsListLayout.Parent = self.groupsList
    
    -- Group details
    self.groupDetails = Instance.new("Frame")
    self.groupDetails.Name = "GroupDetails"
    self.groupDetails.Size = UDim2.new(0.7, 0, 1, 0)
    self.groupDetails.Position = UDim2.new(0.3, 0, 0, 0)
    self.groupDetails.BackgroundTransparency = 1
    
    self.membersList = Instance.new("ScrollingFrame")
    self.membersList.Name = "MembersList"
    self.membersList.Size = UDim2.new(1, 0, 0.8, 0)
    self.membersList.BackgroundTransparency = 1
    self.membersList.ScrollBarThickness = 4
    
    self.membersListLayout = Instance.new("UIListLayout")
    self.membersListLayout.Padding = UDim.new(0, 5)
    self.membersListLayout.Parent = self.membersList
    
    self.groupActions = Instance.new("Frame")
    self.groupActions.Name = "GroupActions"
    self.groupActions.Size = UDim2.new(1, 0, 0.2, 0)
    self.groupActions.Position = UDim2.new(0, 0, 0.8, 0)
    self.groupActions.BackgroundTransparency = 1
    
    self.addButton = Instance.new("TextButton")
    self.addButton.Name = "AddButton"
    self.addButton.Size = UDim2.new(0.3, 0, 0.4, 0)
    self.addButton.Position = UDim2.new(0.05, 0, 0.3, 0)
    self.addButton.BackgroundColor3 = self.theme.Success
    self.addButton.Text = "Add Item"
    self.addButton.TextColor3 = self.theme.Text
    self.addButton.Font = Enum.Font.Gotham
    
    self.removeButton = Instance.new("TextButton")
    self.removeButton.Name = "RemoveButton"
    self.removeButton.Size = UDim2.new(0.3, 0, 0.4, 0)
    self.removeButton.Position = UDim2.new(0.4, 0, 0.3, 0)
    self.removeButton.BackgroundColor3 = self.theme.Error
    self.removeButton.Text = "Remove Item"
    self.removeButton.TextColor3 = self.theme.Text
    self.removeButton.Font = Enum.Font.Gotham
    
    self.newGroupButton = Instance.new("TextButton")
    self.newGroupButton.Name = "NewGroupButton"
    self.newGroupButton.Size = UDim2.new(0.3, 0, 0.4, 0)
    self.newGroupButton.Position = UDim2.new(0.75, 0, 0.3, 0)
    self.newGroupButton.BackgroundColor3 = self.theme.Accent
    self.newGroupButton.Text = "New Group"
    self.newGroupButton.TextColor3 = self.theme.Text
    self.newGroupButton.Font = Enum.Font.Gotham
    
    -- Add UIAspectRatioConstraint for mobile
    self.aspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
    self.aspectRatioConstraint.AspectRatio = 1.5
    self.aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
    self.aspectRatioConstraint.Parent = self.mainFrame
    
    -- Parent all elements
    self.groupActions.Parent = self.groupDetails
    self.addButton.Parent = self.groupActions
    self.removeButton.Parent = self.groupActions
    self.newGroupButton.Parent = self.groupActions
    self.membersList.Parent = self.groupDetails
    self.groupDetails.Parent = self.contentFrame
    self.groupsList.Parent = self.contentFrame
    self.contentFrame.Parent = self.mainFrame
    self.titleBar.Parent = self.mainFrame
    self.titleLabel.Parent = self.titleBar
    self.closeButton.Parent = self.titleBar
    self.toggleButton.Parent = self.screenGui
    self.mainFrame.Parent = self.screenGui
    
    -- Set up button hover effects
    self:setupButtonHoverEffects()
end

function GroupFieldUILibrary:setupButtonHoverEffects()
    local buttons = {
        self.closeButton,
        self.toggleButton,
        self.addButton,
        self.removeButton,
        self.newGroupButton
    }
    
    for _, button in ipairs(buttons) do
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = self.theme.ButtonHover
        end)
        
        button.MouseLeave:Connect(function()
            if button == self.closeButton then
                button.BackgroundColor3 = self.theme.Error
            elseif button == self.addButton then
                button.BackgroundColor3 = self.theme.Success
            elseif button == self.removeButton then
                button.BackgroundColor3 = self.theme.Error
            elseif button == self.newGroupButton then
                button.BackgroundColor3 = self.theme.Accent
            else
                button.BackgroundColor3 = self.theme.Button
            end
        end)
    end
end

function GroupFieldUILibrary:setupControls()
    local UserInputService = game:GetService("UserInputService")
    
    -- Make the GUI draggable
    local dragging
    local dragInput
    local dragStart
    local startPos
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        self.mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    self.titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateInput(input)
        end
    end)
    
    -- Toggle functionality
    self.closeButton.MouseButton1Click:Connect(function()
        self:toggle()
    end)
    
    self.toggleButton.MouseButton1Click:Connect(function()
        self:toggle()
    end)
    
    -- Keyboard toggle
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.toggleKey then
            self:toggle()
        end
    end)
    
    -- Show toggle button only on mobile
    if UserInputService.TouchEnabled then
        self.toggleButton.Visible = true
        -- Adjust GUI size for mobile
        self.mainFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
        self.mainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
    end
    
    -- Group management buttons
    self.newGroupButton.MouseButton1Click:Connect(function()
        self:showNewGroupDialog()
    end)
    
    self.addButton.MouseButton1Click:Connect(function()
        if self.currentGroup then
            self:showAddItemDialog(self.currentGroup)
        end
    end)
    
    self.removeButton.MouseButton1Click:Connect(function()
        if self.currentGroup then
            self:showRemoveItemDialog(self.currentGroup)
        end
    end)
    
    -- Initial refresh
    self:refreshGroups()
end

function GroupFieldUILibrary:createGroupButton(groupName)
    local button = Instance.new("TextButton")
    button.Name = groupName
    button.Size = UDim2.new(0.9, 0, 0, 30)
    button.Position = UDim2.new(0.05, 0, 0, 0)
    button.BackgroundColor3 = self.theme.Button
    button.Text = groupName
    button.TextColor3 = self.theme.Text
    button.Font = Enum.Font.Gotham
    
    button.MouseButton1Click:Connect(function()
        -- Clear previous selection
        for _, child in ipairs(self.groupsList:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = self.theme.Button
            end
        end
        
        -- Highlight selected
        button.BackgroundColor3 = self.theme.Accent
        self.currentGroup = groupName
        
        -- Show group details
        self:refreshMembersList(groupName)
    end)
    
    return button
end

function GroupFieldUILibrary:refreshGroups()
    self.groupsList:ClearAllChildren()
    
    for groupName, _ in pairs(self.groupData) do
        self:createGroupButton(groupName).Parent = self.groupsList
    end
end

function GroupFieldUILibrary:refreshMembersList(groupName)
    self.membersList:ClearAllChildren()
    
    local members = self.groupData[groupName]
    if members then
        for member, properties in pairs(members) do
            local memberFrame = Instance.new("Frame")
            memberFrame.Size = UDim2.new(0.9, 0, 0, 40)
            memberFrame.Position = UDim2.new(0.05, 0, 0, 0)
            memberFrame.BackgroundColor3 = self.theme.Button
            memberFrame.BorderSizePixel = 0
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = memberFrame
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
            nameLabel.Position = UDim2.new(0.05, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = tostring(member)
            nameLabel.TextColor3 = self.theme.Text
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local propsLabel = Instance.new("TextLabel")
            propsLabel.Size = UDim2.new(0.9, 0, 0.5, 0)
            propsLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
            propsLabel.BackgroundTransparency = 1
            propsLabel.Text = "Properties: " .. self:propertiesToString(properties)
            propsLabel.TextColor3 = self.theme.Text
            propsLabel.Font = Enum.Font.Gotham
            propsLabel.TextXAlignment = Enum.TextXAlignment.Left
            propsLabel.TextSize = 12
            
            nameLabel.Parent = memberFrame
            propsLabel.Parent = memberFrame
            memberFrame.Parent = self.membersList
        end
    end
end

function GroupFieldUILibrary:propertiesToString(properties)
    if not properties then return "None" end
    
    local parts = {}
    for k, v in pairs(properties) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    
    return table.concat(parts, ", ")
end

function GroupFieldUILibrary:showNewGroupDialog()
    local dialog = Instance.new("Frame")
    dialog.Name = "NewGroupDialog"
    dialog.Size = UDim2.new(0.6, 0, 0.3, 0)
    dialog.Position = UDim2.new(0.2, 0, 0.35, 0)
    dialog.BackgroundColor3 = self.theme.Background
    dialog.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dialog
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Parent = dialog
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.9, 0, 0.3, 0)
    title.Position = UDim2.new(0.05, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Text = "Create New Group"
    title.TextColor3 = self.theme.Text
    title.Font = Enum.Font.GothamBold
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.9, 0, 0.3, 0)
    textBox.Position = UDim2.new(0.05, 0, 0.4, 0)
    textBox.BackgroundColor3 = self.theme.Button
    textBox.TextColor3 = self.theme.Text
    textBox.PlaceholderText = "Enter group name"
    textBox.ClearTextOnFocus = false
    
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0.4, 0, 0.2, 0)
    submitButton.Position = UDim2.new(0.3, 0, 0.75, 0)
    submitButton.BackgroundColor3 = self.theme.Success
    submitButton.Text = "Create"
    submitButton.TextColor3 = self.theme.Text
    submitButton.Font = Enum.Font.Gotham
    
    title.Parent = dialog
    textBox.Parent = dialog
    submitButton.Parent = dialog
    dialog.Parent = self.mainFrame
    
    submitButton.MouseButton1Click:Connect(function()
        local groupName = textBox.Text
        if groupName and groupName ~= "" then
            if not self.groupData[groupName] then
                self.groupData[groupName] = {}
                self:refreshGroups()
            else
                warn("Group already exists!")
            end
        end
        dialog:Destroy()
    end)
end

function GroupFieldUILibrary:showAddItemDialog(groupName)
    local dialog = Instance.new("Frame")
    dialog.Name = "AddItemDialog"
    dialog.Size = UDim2.new(0.8, 0, 0.6, 0)
    dialog.Position = UDim2.new(0.1, 0, 0.2, 0)
    dialog.BackgroundColor3 = self.theme.Background
    dialog.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dialog
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Parent = dialog
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.9, 0, 0.1, 0)
    title.Position = UDim2.new(0.05, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Text = "Add Item to " .. groupName
    title.TextColor3 = self.theme.Text
    title.Font = Enum.Font.GothamBold
    
    local itemLabel = Instance.new("TextLabel")
    itemLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
    itemLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Text = "Item:"
    itemLabel.TextColor3 = self.theme.Text
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local itemBox = Instance.new("TextBox")
    itemBox.Size = UDim2.new(0.9, 0, 0.1, 0)
    itemBox.Position = UDim2.new(0.05, 0, 0.3, 0)
    itemBox.BackgroundColor3 = self.theme.Button
    itemBox.TextColor3 = self.theme.Text
    itemBox.PlaceholderText = "Enter item name or select from workspace"
    itemBox.ClearTextOnFocus = false
    
    local propsLabel = Instance.new("TextLabel")
    propsLabel.Size = UDim2.new(0.4, 0, 0.1, 0)
    propsLabel.Position = UDim2.new(0.05, 0, 0.45, 0)
    propsLabel.BackgroundTransparency = 1
    propsLabel.Text = "Properties (JSON):"
    propsLabel.TextColor3 = self.theme.Text
    propsLabel.Font = Enum.Font.Gotham
    propsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local propsBox = Instance.new("TextBox")
    propsBox.Size = UDim2.new(0.9, 0, 0.3, 0)
    propsBox.Position = UDim2.new(0.05, 0, 0.55, 0)
    propsBox.BackgroundColor3 = self.theme.Button
    propsBox.TextColor3 = self.theme.Text
    propsBox.PlaceholderText = '{"key":"value", "number":123}'
    propsBox.ClearTextOnFocus = false
    propsBox.MultiLine = true
    propsBox.TextWrapped = true
    
    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0.4, 0, 0.1, 0)
    submitButton.Position = UDim2.new(0.3, 0, 0.85, 0)
    submitButton.BackgroundColor3 = self.theme.Success
    submitButton.Text = "Add"
    submitButton.TextColor3 = self.theme.Text
    submitButton.Font = Enum.Font.Gotham
    
    title.Parent = dialog
    itemLabel.Parent = dialog
    itemBox.Parent = dialog
    propsLabel.Parent = dialog
    propsBox.Parent = dialog
    submitButton.Parent = dialog
    dialog.Parent = self.mainFrame
    
    submitButton.MouseButton1Click:Connect(function()
        local item = itemBox.Text
        if item and item ~= "" then
            local properties = {}
            if propsBox.Text ~= "" then
                local success, result = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(propsBox.Text)
                end)
                if success then
                    properties = result
                else
                    warn("Invalid JSON properties: " .. result)
                end
            end
            
            self.groupData[groupName][item] = properties
            self:refreshMembersList(groupName)
        end
        dialog:Destroy()
    end)
end

function GroupFieldUILibrary:showRemoveItemDialog(groupName)
    if not self.groupData[groupName] or not next(self.groupData[groupName]) then
        return
    end
    
    local dialog = Instance.new("Frame")
    dialog.Name = "RemoveItemDialog"
    dialog.Size = UDim2.new(0.8, 0, 0.6, 0)
    dialog.Position = UDim2.new(0.1, 0, 0.2, 0)
    dialog.BackgroundColor3 = self.theme.Background
    dialog.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = dialog
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Parent = dialog
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.9, 0, 0.1, 0)
    title.Position = UDim2.new(0.05, 0, 0.05, 0)
    title.BackgroundTransparency = 1
    title.Text = "Remove Item from " .. groupName
    title.TextColor3 = self.theme.Text
    title.Font = Enum.Font.GothamBold
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
    scrollFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scrollFrame
    
    -- Populate with items
    for item, _ in pairs(self.groupData[groupName]) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(0.9, 0, 0, 40)
        itemFrame.BackgroundColor3 = self.theme.Button
        itemFrame.BorderSizePixel = 0
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = itemFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = tostring(item)
        nameLabel.TextColor3 = self.theme.Text
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local removeButton = Instance.new("TextButton")
        removeButton.Size = UDim2.new(0.2, 0, 0.8, 0)
        removeButton.Position = UDim2.new(0.75, 0, 0.1, 0)
        removeButton.BackgroundColor3 = self.theme.Error
        removeButton.Text = "Remove"
        removeButton.TextColor3 = self.theme.Text
        removeButton.Font = Enum.Font.Gotham
        
        nameLabel.Parent = itemFrame
        removeButton.Parent = itemFrame
        itemFrame.Parent = scrollFrame
        
        removeButton.MouseButton1Click:Connect(function()
            self.groupData[groupName][item] = nil
            self:refreshMembersList(groupName)
            itemFrame:Destroy()
            
            -- Close dialog if no more items
            if not next(self.groupData[groupName]) then
                dialog:Destroy()
            end
        end)
    end
    
    title.Parent = dialog
    scrollFrame.Parent = dialog
    dialog.Parent = self.mainFrame
end

function GroupFieldUILibrary:toggle()
    self.isVisible = not self.isVisible
    self.mainFrame.Visible = self.isVisible
    self.toggleButton.Text = self.isVisible and "Hide GUI" or "Show GUI"
    
    if self.isVisible then
        self:refreshGroups()
    end
end

function GroupFieldUILibrary:open()
    if not self.isVisible then
        self:toggle()
    end
end

function GroupFieldUILibrary:close()
    if self.isVisible then
        self:toggle()
    end
end

function GroupFieldUILibrary:destroy()
    self.screenGui:Destroy()
end

return GroupFieldUILibrary