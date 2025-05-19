-- GroupFieldUILibrary module script in ReplicatedStorage
local GroupFieldUILibrary = {}
GroupFieldUILibrary.__index = GroupFieldUILibrary

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Default theme with improved color scheme
local DEFAULT_THEME = {
    Background = Color3.fromRGB(40, 42, 45),
    Header = Color3.fromRGB(25, 27, 30),
    Text = Color3.fromRGB(240, 240, 240),
    Button = Color3.fromRGB(60, 62, 65),
    ButtonHover = Color3.fromRGB(80, 82, 85),
    Accent = Color3.fromRGB(0, 162, 255),
    Error = Color3.fromRGB(255, 85, 85),
    Success = Color3.fromRGB(85, 255, 85),
    Warning = Color3.fromRGB(255, 184, 77),
    Disabled = Color3.fromRGB(100, 100, 100)
}

function GroupFieldUILibrary.new(groupData, options)
    local self = setmetatable({}, GroupFieldUILibrary)
    
    -- Validate groupData
    if type(groupData) ~= "table" then
        groupData = {}
        warn("GroupFieldUILibrary: Invalid groupData provided, using empty table")
    end
    
    -- Configuration with defaults
    self.config = {
        theme = options and options.theme or DEFAULT_THEME,
        title = options and options.title or "Group Field Manager",
        toggleKey = options and options.toggleKey or Enum.KeyCode.F5,
        defaultPosition = options and options.defaultPosition or UDim2.new(0.05, 0, 0.3, 0),
        defaultSize = options and options.defaultSize or UDim2.new(0.3, 0, 0.4, 0),
        minSize = options and options.minSize or UDim2.new(0.2, 150, 0.2, 150),
        maxSize = options and options.maxSize or UDim2.new(0.8, 0, 0.8, 0),
        autoRefreshInterval = options and options.autoRefreshInterval or 5,
        enableSearch = options and options.enableSearch ~= false,
        enableSorting = options and options.enableSorting ~= false,
        enableMultiSelect = options and options.enableMultiSelect or false,
        enablePropertyEditing = options and options.enablePropertyEditing or false
    }
    
    -- State management
    self.state = {
        isVisible = false,
        currentGroup = nil,
        selectedItems = {},
        isDragging = false,
        dragStartPos = nil,
        originalSize = self.config.defaultSize,
        originalPosition = self.config.defaultPosition
    }
    
    -- Reference to group data
    self.groupData = groupData
    
    -- Create UI elements
    self:createUI()
    
    -- Set up event handlers
    self:setupEventHandlers()
    
    -- Initialize auto-refresh if enabled
    if self.config.autoRefreshInterval > 0 then
        self:startAutoRefresh()
    end
    
    return self
end

-- Improved UI creation with better organization
function GroupFieldUILibrary:createUI()
    -- Main ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "GroupFieldUILibrary"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.DisplayOrder = 10
    self.screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main container frame
    self.mainFrame = self:createFrame("MainFrame", {
        Size = self.config.defaultSize,
        Position = self.config.defaultPosition,
        BackgroundColor3 = self.config.theme.Background,
        ClipsDescendants = true,
        Visible = self.state.isVisible
    })
    
    -- Add rounded corners and shadow
    self:addUICorner(self.mainFrame, 8)
    self:addUIStroke(self.mainFrame, 2, Color3.fromRGB(80, 80, 80))
    
    -- Title bar with improved layout
    self.titleBar = self:createFrame("TitleBar", {
        Size = UDim2.new(1, 0, 0.08, 0),
        BackgroundColor3 = self.config.theme.Header
    })
    
    self.titleLabel = self:createLabel("TitleLabel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0.15, 0, 0, 0),
        Text = self.config.title,
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
    
    -- Improved close button with icon
    self.closeButton = self:createButton("CloseButton", {
        Size = UDim2.new(0.1, 0, 1, 0),
        Position = UDim2.new(0.9, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "×", -- Using multiplication symbol for better appearance
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18
    })
    
    -- Mobile toggle button
    self.toggleButton = self:createButton("ToggleButton", {
        Size = UDim2.new(0.15, 0, 0.06, 0),
        Position = UDim2.new(0.02, 0, 0.92, 0),
        BackgroundColor3 = self.config.theme.Button,
        Text = "Toggle GUI",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        Visible = false
    })
    
    -- Content area
    self.contentFrame = self:createFrame("ContentFrame", {
        Size = UDim2.new(1, 0, 0.92, 0),
        Position = UDim2.new(0, 0, 0.08, 0),
        BackgroundTransparency = 1
    })
    
    -- Groups panel with search functionality
    self.groupsPanel = self:createFrame("GroupsPanel", {
        Size = UDim2.new(0.3, 0, 1, 0),
        BackgroundTransparency = 1
    })
    
    if self.config.enableSearch then
        self.groupSearchBox = self:createTextBox("GroupSearchBox", {
            Size = UDim2.new(0.9, 0, 0.08, 0),
            Position = UDim2.new(0.05, 0, 0, 0),
            PlaceholderText = "Search groups...",
            ClearTextOnFocus = false
        })
    end
    
    self.groupsList = self:createScrollingFrame("GroupsList", {
        Size = UDim2.new(0.9, 0, self.config.enableSearch and 0.9 or 1, 0),
        Position = UDim2.new(0.05, 0, self.config.enableSearch and 0.1 or 0, 0),
        ScrollBarThickness = 6
    })
    
    -- Group details panel
    self.detailsPanel = self:createFrame("DetailsPanel", {
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0.3, 0, 0, 0),
        BackgroundTransparency = 1
    })
    
    self.membersHeader = self:createLabel("MembersHeader", {
        Size = UDim2.new(1, 0, 0.05, 0),
        Text = "Group Members",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold
    })
    
    if self.config.enableSearch then
        self.memberSearchBox = self:createTextBox("MemberSearchBox", {
            Size = UDim2.new(0.9, 0, 0.08, 0),
            Position = UDim2.new(0.05, 0, 0.05, 0),
            PlaceholderText = "Search members...",
            ClearTextOnFocus = false
        })
    end
    
    self.membersList = self:createScrollingFrame("MembersList", {
        Size = UDim2.new(0.9, 0, self.config.enableSearch and 0.75 or 0.8, 0),
        Position = UDim2.new(0.05, 0, self.config.enableSearch and 0.14 or 0.05, 0),
        ScrollBarThickness = 6
    })
    
    -- Action buttons with improved layout
    self.actionButtons = self:createFrame("ActionButtons", {
        Size = UDim2.new(0.9, 0, 0.15, 0),
        Position = UDim2.new(0.05, 0, 0.85, 0),
        BackgroundTransparency = 1
    })
    
    self.newGroupButton = self:createButton("NewGroupButton", {
        Size = UDim2.new(0.3, 0, 0.8, 0),
        Position = UDim2.new(0, 0, 0.1, 0),
        BackgroundColor3 = self.config.theme.Accent,
        Text = "New Group",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham
    })
    
    self.addButton = self:createButton("AddButton", {
        Size = UDim2.new(0.3, 0, 0.8, 0),
        Position = UDim2.new(0.35, 0, 0.1, 0),
        BackgroundColor3 = self.config.theme.Success,
        Text = "Add Item",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham
    })
    
    self.removeButton = self:createButton("RemoveButton", {
        Size = UDim2.new(0.3, 0, 0.8, 0),
        Position = UDim2.new(0.7, 0, 0.1, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Remove",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham
    })
    
    -- Add resize handle
    self.resizeHandle = self:createButton("ResizeHandle", {
        Size = UDim2.new(0.05, 0, 0.05, 0),
        Position = UDim2.new(0.95, 0, 0.95, 0),
        BackgroundColor3 = self.config.theme.Button,
        Text = "↘",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12
    })
    
    -- Add UIAspectRatioConstraint for mobile
    self.aspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
    self.aspectRatioConstraint.AspectRatio = 1.5
    self.aspectRatioConstraint.DominantAxis = Enum.DominantAxis.Width
    self.aspectRatioConstraint.Parent = self.mainFrame
    
    -- Parent all elements
    self.titleLabel.Parent = self.titleBar
    self.closeButton.Parent = self.titleBar
    self.titleBar.Parent = self.mainFrame
    
    if self.config.enableSearch then
        self.groupSearchBox.Parent = self.groupsPanel
    end
    self.groupsList.Parent = self.groupsPanel
    self.groupsPanel.Parent = self.contentFrame
    
    self.membersHeader.Parent = self.detailsPanel
    if self.config.enableSearch then
        self.memberSearchBox.Parent = self.detailsPanel
    end
    self.membersList.Parent = self.detailsPanel
    self.actionButtons.Parent = self.detailsPanel
    self.detailsPanel.Parent = self.contentFrame
    
    self.newGroupButton.Parent = self.actionButtons
    self.addButton.Parent = self.actionButtons
    self.removeButton.Parent = self.actionButtons
    
    self.contentFrame.Parent = self.mainFrame
    self.resizeHandle.Parent = self.mainFrame
    self.toggleButton.Parent = self.screenGui
    self.mainFrame.Parent = self.screenGui
    
    -- Set up button hover effects
    self:setupHoverEffects()
    
    -- Initialize search functionality if enabled
    if self.config.enableSearch then
        self:setupSearchFunctionality()
    end
end

-- Improved helper functions for UI creation
function GroupFieldUILibrary:createFrame(name, properties)
    local frame = Instance.new("Frame")
    frame.Name = name
    for prop, value in pairs(properties) do
        frame[prop] = value
    end
    return frame
end

function GroupFieldUILibrary:createLabel(name, properties)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    for prop, value in pairs(properties) do
        label[prop] = value
    end
    return label
end

function GroupFieldUILibrary:createButton(name, properties)
    local button = Instance.new("TextButton")
    button.Name = name
    button.AutoButtonColor = true
    button.BorderSizePixel = 0
    for prop, value in pairs(properties) do
        button[prop] = value
    end
    
    -- Add corner rounding
    self:addUICorner(button, 4)
    
    return button
end

function GroupFieldUILibrary:createTextBox(name, properties)
    local textBox = Instance.new("TextBox")
    textBox.Name = name
    textBox.BackgroundColor3 = self.config.theme.Button
    textBox.TextColor3 = self.config.theme.Text
    textBox.Font = Enum.Font.Gotham
    textBox.ClearTextOnFocus = false
    for prop, value in pairs(properties) do
        textBox[prop] = value
    end
    
    -- Add corner rounding
    self:addUICorner(textBox, 4)
    
    return textBox
end

function GroupFieldUILibrary:createScrollingFrame(name, properties)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name
    frame.BackgroundTransparency = 1
    frame.ScrollBarImageColor3 = self.config.theme.ButtonHover
    for prop, value in pairs(properties) do
        frame[prop] = value
    end
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = frame
    
    return frame
end

function GroupFieldUILibrary:addUICorner(instance, cornerRadius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or 4)
    corner.Parent = instance
end

function GroupFieldUILibrary:addUIStroke(instance, thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or Color3.fromRGB(80, 80, 80)
    stroke.Parent = instance
end

-- Improved event handling setup
function GroupFieldUILibrary:setupEventHandlers()
    -- Dragging functionality
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.state.isDragging = true
            self.state.dragStartPos = input.Position
            self.state.originalPosition = self.mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self.state.isDragging = false
                end
            end)
        end
    end)
    
    self.titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            self.state.dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.state.isDragging and input == self.state.dragInput then
            local delta = input.Position - self.state.dragStartPos
            self.mainFrame.Position = UDim2.new(
                self.state.originalPosition.X.Scale, 
                self.state.originalPosition.X.Offset + delta.X,
                self.state.originalPosition.Y.Scale, 
                self.state.originalPosition.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Resize functionality
    self.resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self.state.isResizing = true
            self.state.resizeStartPos = input.Position
            self.state.originalSize = self.mainFrame.Size
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self.state.isResizing = false
                end
            end)
        end
    end)
    
    self.resizeHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            self.state.resizeInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if self.state.isResizing and input == self.state.resizeInput then
            local delta = input.Position - self.state.resizeStartPos
            local newWidth = math.clamp(
                self.state.originalSize.X.Offset + delta.X,
                self.config.minSize.X.Offset,
                self.config.maxSize.X.Offset
            )
            local newHeight = math.clamp(
                self.state.originalSize.Y.Offset + delta.Y,
                self.config.minSize.Y.Offset,
                self.config.maxSize.Y.Offset
            )
            
            self.mainFrame.Size = UDim2.new(
                self.state.originalSize.X.Scale,
                newWidth,
                self.state.originalSize.Y.Scale,
                newHeight
            )
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
        if not processed and input.KeyCode == self.config.toggleKey then
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
        if self.state.currentGroup then
            self:showAddItemDialog(self.state.currentGroup)
        else
            self:showNotification("Please select a group first", self.config.theme.Warning)
        end
    end)
    
    self.removeButton.MouseButton1Click:Connect(function()
        if self.state.currentGroup then
            if self.config.enableMultiSelect and next(self.state.selectedItems) then
                self:showMultiRemoveConfirmation()
            else
                self:showRemoveItemDialog(self.state.currentGroup)
            end
        else
            self:showNotification("Please select a group first", self.config.theme.Warning)
        end
    end)
end

-- Improved hover effects with animation
function GroupFieldUILibrary:setupHoverEffects()
    local buttons = {
        self.closeButton,
        self.toggleButton,
        self.addButton,
        self.removeButton,
        self.newGroupButton,
        self.resizeHandle
    }
    
    for _, button in ipairs(buttons) do
        button.MouseEnter:Connect(function()
            if button == self.closeButton then
                button.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
            elseif button == self.addButton then
                button.BackgroundColor3 = Color3.fromRGB(120, 255, 120)
            elseif button == self.removeButton then
                button.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
            elseif button == self.newGroupButton then
                button.BackgroundColor3 = Color3.fromRGB(50, 180, 255)
            else
                button.BackgroundColor3 = self.config.theme.ButtonHover
            end
        end)
        
        button.MouseLeave:Connect(function()
            if button == self.closeButton then
                button.BackgroundColor3 = self.config.theme.Error
            elseif button == self.addButton then
                button.BackgroundColor3 = self.config.theme.Success
            elseif button == self.removeButton then
                button.BackgroundColor3 = self.config.theme.Error
            elseif button == self.newGroupButton then
                button.BackgroundColor3 = self.config.theme.Accent
            else
                button.BackgroundColor3 = self.config.theme.Button
            end
        end)
    end
end

-- Improved search functionality
function GroupFieldUILibrary:setupSearchFunctionality()
    self.groupSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self:filterGroups(self.groupSearchBox.Text)
    end)
    
    self.memberSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self.state.currentGroup then
            self:filterMembers(self.state.currentGroup, self.memberSearchBox.Text)
        end
    end)
end

-- Improved group creation with validation
function GroupFieldUILibrary:createGroupButton(groupName)
    local button = self:createButton(groupName, {
        Size = UDim2.new(0.9, 0, 0, 35),
        Position = UDim2.new(0.05, 0, 0, 0),
        Text = groupName,
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14
    })
    
    -- Add group count badge
    local memberCount = self:countGroupMembers(groupName)
    local countBadge = self:createLabel("CountBadge", {
        Size = UDim2.new(0.2, 0, 0.6, 0),
        Position = UDim2.new(0.75, 0, 0.2, 0),
        BackgroundColor3 = self.config.theme.Accent,
        Text = tostring(memberCount),
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12
    })
    self:addUICorner(countBadge, 8)
    countBadge.Parent = button
    
    button.MouseButton1Click:Connect(function()
        -- Clear previous selection
        for _, child in ipairs(self.groupsList:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = self.config.theme.Button
                child:FindFirstChild("CountBadge").BackgroundColor3 = self.config.theme.Accent
            end
        end
        
        -- Highlight selected
        button.BackgroundColor3 = self.config.theme.Accent
        countBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        countBadge.TextColor3 = self.config.theme.Accent
        
        self.state.currentGroup = groupName
        self.state.selectedItems = {} -- Clear selection when changing groups
        self:refreshMembersList(groupName)
    end)
    
    return button
end

-- Improved group filtering
function GroupFieldUILibrary:filterGroups(searchText)
    searchText = string.lower(searchText or "")
    
    for _, child in ipairs(self.groupsList:GetChildren()) do
        if child:IsA("TextButton") then
            local groupName = string.lower(child.Text)
            child.Visible = searchText == "" or string.find(groupName, searchText, 1, true) ~= nil
        end
    end
end

-- Improved member filtering
function GroupFieldUILibrary:filterMembers(groupName, searchText)
    searchText = string.lower(searchText or "")
    
    for _, child in ipairs(self.membersList:GetChildren()) do
        if child:IsA("Frame") then
            local memberName = string.lower(child.NameLabel.Text)
            child.Visible = searchText == "" or string.find(memberName, searchText, 1, true) ~= nil
        end
    end
end

-- Improved member list item creation
function GroupFieldUILibrary:createMemberListItem(member, properties)
    local memberFrame = self:createFrame(member, {
        Size = UDim2.new(0.9, 0, 0, 50),
        Position = UDim2.new(0.05, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Button,
        BorderSizePixel = 0
    })
    
    self:addUICorner(memberFrame, 6)
    
    local nameLabel = self:createLabel("NameLabel", {
        Size = UDim2.new(0.6, 0, 0.5, 0),
        Position = UDim2.new(0.05, 0, 0, 0),
        Text = tostring(member),
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local propsLabel = self:createLabel("PropsLabel", {
        Size = UDim2.new(0.9, 0, 0.5, 0),
        Position = UDim2.new(0.05, 0, 0.5, 0),
        Text = "Properties: " .. self:propertiesToString(properties),
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 12
    })
    
    -- Selection indicator
    local selectionIndicator = self:createFrame("SelectionIndicator", {
        Size = UDim2.new(0.02, 0, 0.8, 0),
        Position = UDim2.new(0.01, 0, 0.1, 0),
        BackgroundColor3 = self.config.theme.Accent,
        Visible = false
    })
    self:addUICorner(selectionIndicator, 2)
    
    -- Edit button if property editing is enabled
    if self.config.enablePropertyEditing then
        local editButton = self:createButton("EditButton", {
            Size = UDim2.new(0.15, 0, 0.6, 0),
            Position = UDim2.new(0.8, 0, 0.2, 0),
            BackgroundColor3 = self.config.theme.Accent,
            Text = "Edit",
            TextColor3 = self.config.theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12
        })
        
        editButton.MouseButton1Click:Connect(function()
            self:showEditPropertiesDialog(self.state.currentGroup, member, properties)
        end)
        
        editButton.Parent = memberFrame
    end
    
    -- Multi-select functionality
    if self.config.enableMultiSelect then
        memberFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local isSelected = not self.state.selectedItems[member]
                self.state.selectedItems[member] = isSelected or nil
                selectionIndicator.Visible = isSelected
                
                if isSelected then
                    memberFrame.BackgroundColor3 = Color3.fromRGB(
                        math.floor(self.config.theme.Button.R * 255 * 0.8),
                        math.floor(self.config.theme.Button.G * 255 * 0.8),
                        math.floor(self.config.theme.Button.B * 255 * 0.8)
                    )
                else
                    memberFrame.BackgroundColor3 = self.config.theme.Button
                end
            end
        end)
    end
    
    nameLabel.Parent = memberFrame
    propsLabel.Parent = memberFrame
    selectionIndicator.Parent = memberFrame
    
    return memberFrame
end

-- Improved group refresh with sorting
function GroupFieldUILibrary:refreshGroups()
    self.groupsList:ClearAllChildren()
    
    local groupNames = {}
    for groupName, _ in pairs(self.groupData) do
        table.insert(groupNames, groupName)
    end
    
    -- Sort groups if enabled
    if self.config.enableSorting then
        table.sort(groupNames, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
    end
    
    for _, groupName in ipairs(groupNames) do
        self:createGroupButton(groupName).Parent = self.groupsList
    end
end

-- Improved member list refresh with sorting
function GroupFieldUILibrary:refreshMembersList(groupName)
    self.membersList:ClearAllChildren()
    self.state.selectedItems = {} -- Clear selection
    
    local members = {}
    for member, properties in pairs(self.groupData[groupName] or {}) do
        table.insert(members, {member = member, properties = properties})
    end
    
    -- Sort members if enabled
    if self.config.enableSorting then
        table.sort(members, function(a, b)
            return string.lower(tostring(a.member)) < string.lower(tostring(b.member))
        end)
    end
    
    for _, data in ipairs(members) do
        self:createMemberListItem(data.member, data.properties).Parent = self.membersList
    end
end

-- Improved property string conversion
function GroupFieldUILibrary:propertiesToString(properties)
    if not properties or next(properties) == nil then
        return "None"
    end
    
    local parts = {}
    for k, v in pairs(properties) do
        if type(v) == "table" then
            table.insert(parts, string.format("%s={...}", tostring(k)))
        else
            table.insert(parts, string.format("%s=%s", tostring(k), tostring(v)))
        end
    end
    
    return table.concat(parts, ", ")
end

-- Improved notification system
function GroupFieldUILibrary:showNotification(message, color)
    local notification = self:createFrame("Notification", {
        Size = UDim2.new(0.8, 0, 0.1, 0),
        Position = UDim2.new(0.1, 0, 0.8, 0),
        BackgroundColor3 = color or self.config.theme.Accent,
        ZIndex = 20
    })
    
    self:addUICorner(notification, 6)
    self:addUIStroke(notification, 2, Color3.fromRGB(0, 0, 0))
    
    local label = self:createLabel("NotificationLabel", {
        Size = UDim2.new(0.9, 0, 0.8, 0),
        Position = UDim2.new(0.05, 0, 0.1, 0),
        Text = message,
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextWrapped = true,
        ZIndex = 21
    })
    
    label.Parent = notification
    notification.Parent = self.mainFrame
    
    -- Animate notification
    notification.BackgroundTransparency = 1
    label.TextTransparency = 1
    
    local fadeIn = game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.3),
        {BackgroundTransparency = 0}
    )
    
    local textFadeIn = game:GetService("TweenService"):Create(
        label,
        TweenInfo.new(0.3),
        {TextTransparency = 0}
    )
    
    fadeIn:Play()
    textFadeIn:Play()
    
    -- Auto-remove after delay
    task.delay(3, function()
        if notification and notification.Parent then
            local fadeOut = game:GetService("TweenService"):Create(
                notification,
                TweenInfo.new(0.5),
                {BackgroundTransparency = 1}
            )
            
            local textFadeOut = game:GetService("TweenService"):Create(
                label,
                TweenInfo.new(0.5),
                {TextTransparency = 1}
            )
            
            fadeOut:Play()
            textFadeOut:Play()
            
            fadeOut.Completed:Wait()
            notification:Destroy()
        end
    end)
end

-- Improved dialog management
function GroupFieldUILibrary:showNewGroupDialog()
    if self.mainFrame:FindFirstChild("NewGroupDialog") then
        return
    end
    
    local dialog = self:createFrame("NewGroupDialog", {
        Size = UDim2.new(0.6, 0, 0.3, 0),
        Position = UDim2.new(0.2, 0, 0.35, 0),
        BackgroundColor3 = self.config.theme.Background,
        ZIndex = 10
    })
    
    self:addUICorner(dialog, 8)
    self:addUIStroke(dialog, 2, Color3.fromRGB(80, 80, 80))
    
    local title = self:createLabel("DialogTitle", {
        Size = UDim2.new(0.9, 0, 0.3, 0),
        Position = UDim2.new(0.05, 0, 0.05, 0),
        Text = "Create New Group",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        ZIndex = 11
    })
    
    local textBox = self:createTextBox("GroupNameBox", {
        Size = UDim2.new(0.9, 0, 0.3, 0),
        Position = UDim2.new(0.05, 0, 0.4, 0),
        PlaceholderText = "Enter group name",
        ClearTextOnFocus = false,
        ZIndex = 11
    })
    
    local buttonFrame = self:createFrame("ButtonFrame", {
        Size = UDim2.new(0.9, 0, 0.2, 0),
        Position = UDim2.new(0.05, 0, 0.75, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    })
    
    local submitButton = self:createButton("SubmitButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Success,
        Text = "Create",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    local cancelButton = self:createButton("CancelButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Cancel",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    title.Parent = dialog
    textBox.Parent = dialog
    buttonFrame.Parent = dialog
    submitButton.Parent = buttonFrame
    cancelButton.Parent = buttonFrame
    dialog.Parent = self.mainFrame
    
    -- Focus text box automatically
    textBox:CaptureFocus()
    
    -- Submit handler
    submitButton.MouseButton1Click:Connect(function()
        local groupName = string.gsub(textBox.Text, "^%s*(.-)%s*$", "%1") -- Trim whitespace
        if groupName and groupName ~= "" then
            if not self.groupData[groupName] then
                self.groupData[groupName] = {}
                self:refreshGroups()
                self:showNotification("Group created: " .. groupName, self.config.theme.Success)
            else
                self:showNotification("Group already exists!", self.config.theme.Warning)
            end
        else
            self:showNotification("Please enter a group name", self.config.theme.Warning)
        end
        dialog:Destroy()
    end)
    
    -- Cancel handler
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
    
    -- Close dialog when clicking outside
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local dialogPos = dialog.AbsolutePosition
            local dialogSize = dialog.AbsoluteSize
            
            if not (mousePos.X >= dialogPos.X and mousePos.X <= dialogPos.X + dialogSize.X and
                   mousePos.Y >= dialogPos.Y and mousePos.Y <= dialogPos.Y + dialogSize.Y) then
                dialog:Destroy()
            end
        end
    end
    
    self.screenGui.InputBegan:Connect(onInputBegan)
    
    dialog.Destroying:Connect(function()
        self.screenGui.InputBegan:Disconnect(onInputBegan)
    end)
end

-- Improved add item dialog
function GroupFieldUILibrary:showAddItemDialog(groupName)
    if self.mainFrame:FindFirstChild("AddItemDialog") then
        return
    end
    
    local dialog = self:createFrame("AddItemDialog", {
        Size = UDim2.new(0.8, 0, 0.6, 0),
        Position = UDim2.new(0.1, 0, 0.2, 0),
        BackgroundColor3 = self.config.theme.Background,
        ZIndex = 10
    })
    
    self:addUICorner(dialog, 8)
    self:addUIStroke(dialog, 2, Color3.fromRGB(80, 80, 80))
    
    local title = self:createLabel("DialogTitle", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.05, 0),
        Text = "Add Item to " .. groupName,
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        ZIndex = 11
    })
    
    local itemLabel = self:createLabel("ItemLabel", {
        Size = UDim2.new(0.4, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.2, 0),
        Text = "Item:",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    })
    
    local itemBox = self:createTextBox("ItemBox", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.3, 0),
        PlaceholderText = "Enter item name or select from workspace",
        ClearTextOnFocus = false,
        ZIndex = 11
    })
    
    local propsLabel = self:createLabel("PropsLabel", {
        Size = UDim2.new(0.4, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.45, 0),
        Text = "Properties (JSON):",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11
    })
    
    local propsBox = self:createTextBox("PropsBox", {
        Size = UDim2.new(0.9, 0, 0.3, 0),
        Position = UDim2.new(0.05, 0, 0.55, 0),
        PlaceholderText = '{"key":"value", "number":123}',
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = true,
        ZIndex = 11
    })
    
    local buttonFrame = self:createFrame("ButtonFrame", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.9, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    })
    
    local submitButton = self:createButton("SubmitButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Success,
        Text = "Add",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    local cancelButton = self:createButton("CancelButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Cancel",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    title.Parent = dialog
    itemLabel.Parent = dialog
    itemBox.Parent = dialog
    propsLabel.Parent = dialog
    propsBox.Parent = dialog
    buttonFrame.Parent = dialog
    submitButton.Parent = buttonFrame
    cancelButton.Parent = buttonFrame
    dialog.Parent = self.mainFrame
    
    -- Focus item box automatically
    itemBox:CaptureFocus()
    
    -- Submit handler
    submitButton.MouseButton1Click:Connect(function()
        local item = string.gsub(itemBox.Text, "^%s*(.-)%s*$", "%1") -- Trim whitespace
        if item and item ~= "" then
            local properties = {}
            if propsBox.Text ~= "" then
                local success, result = pcall(function()
                    return HttpService:JSONDecode(propsBox.Text)
                end)
                if success then
                    properties = result
                else
                    self:showNotification("Invalid JSON: " .. result, self.config.theme.Warning)
                    return
                end
            end
            
            if self.groupData[groupName][item] then
                self:showNotification("Item already exists in group!", self.config.theme.Warning)
            else
                self.groupData[groupName][item] = properties
                self:refreshMembersList(groupName)
                self:refreshGroups() -- Update count badges
                self:showNotification("Item added to group", self.config.theme.Success)
                dialog:Destroy()
            end
        else
            self:showNotification("Please enter an item name", self.config.theme.Warning)
        end
    end)
    
    -- Cancel handler
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Improved remove item dialog
function GroupFieldUILibrary:showRemoveItemDialog(groupName)
    if not self.groupData[groupName] or not next(self.groupData[groupName]) then
        self:showNotification("Group is empty", self.config.theme.Warning)
        return
    end
    
    if self.mainFrame:FindFirstChild("RemoveItemDialog") then
        return
    end
    
    local dialog = self:createFrame("RemoveItemDialog", {
        Size = UDim2.new(0.8, 0, 0.6, 0),
        Position = UDim2.new(0.1, 0, 0.2, 0),
        BackgroundColor3 = self.config.theme.Background,
        ZIndex = 10
    })
    
    self:addUICorner(dialog, 8)
    self:addUIStroke(dialog, 2, Color3.fromRGB(80, 80, 80))
    
    local title = self:createLabel("DialogTitle", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.05, 0),
        Text = "Remove Items from " .. groupName,
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        ZIndex = 11
    })
    
    local scrollFrame = self:createScrollingFrame("ItemsList", {
        Size = UDim2.new(0.9, 0, 0.7, 0),
        Position = UDim2.new(0.05, 0, 0.2, 0),
        ScrollBarThickness = 6,
        ZIndex = 11
    })
    
    local buttonFrame = self:createFrame("ButtonFrame", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.9, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    })
    
    local removeButton = self:createButton("RemoveButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Remove Selected",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    local cancelButton = self:createButton("CancelButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Button,
        Text = "Cancel",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    -- Populate with items
    local selectedItems = {}
    for item, properties in pairs(self.groupData[groupName]) do
        local itemFrame = self:createFrame(item, {
            Size = UDim2.new(0.9, 0, 0, 40),
            BackgroundColor3 = self.config.theme.Button,
            ZIndex = 12
        })
        self:addUICorner(itemFrame, 4)
        
        local nameLabel = self:createLabel("NameLabel", {
            Size = UDim2.new(0.6, 0, 1, 0),
            Text = tostring(item),
            TextColor3 = self.config.theme.Text,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 13
        })
        
        local selectButton = self:createButton("SelectButton", {
            Size = UDim2.new(0.3, 0, 0.8, 0),
            Position = UDim2.new(0.65, 0, 0.1, 0),
            BackgroundColor3 = self.config.theme.Error,
            Text = "Select",
            TextColor3 = self.config.theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            ZIndex = 13
        })
        
        nameLabel.Parent = itemFrame
        selectButton.Parent = itemFrame
        itemFrame.Parent = scrollFrame
        
        selectButton.MouseButton1Click:Connect(function()
            selectedItems[item] = not selectedItems[item]
            if selectedItems[item] then
                itemFrame.BackgroundColor3 = Color3.fromRGB(
                    math.floor(self.config.theme.Button.R * 255 * 0.7),
                    math.floor(self.config.theme.Button.G * 255 * 0.7),
                    math.floor(self.config.theme.Button.B * 255 * 0.7)
                )
                selectButton.Text = "Selected"
            else
                itemFrame.BackgroundColor3 = self.config.theme.Button
                selectButton.Text = "Select"
            end
        end)
    end
    
    title.Parent = dialog
    scrollFrame.Parent = dialog
    buttonFrame.Parent = dialog
    removeButton.Parent = buttonFrame
    cancelButton.Parent = buttonFrame
    dialog.Parent = self.mainFrame
    
    -- Remove handler
    removeButton.MouseButton1Click:Connect(function()
        local removedCount = 0
        for item, _ in pairs(selectedItems) do
            if self.groupData[groupName][item] then
                self.groupData[groupName][item] = nil
                removedCount = removedCount + 1
            end
        end
        
        if removedCount > 0 then
            self:refreshMembersList(groupName)
            self:refreshGroups() -- Update count badges
            self:showNotification(string.format("Removed %d items", removedCount), self.config.theme.Success)
        else
            self:showNotification("No items selected", self.config.theme.Warning)
        end
        
        dialog:Destroy()
    end)
    
    -- Cancel handler
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Improved multi-select removal confirmation
function GroupFieldUILibrary:showMultiRemoveConfirmation()
    local count = 0
    for _ in pairs(self.state.selectedItems) do
        count = count + 1
    end
    
    if count == 0 then
        self:showNotification("No items selected", self.config.theme.Warning)
        return
    end
    
    local dialog = self:createFrame("ConfirmRemoveDialog", {
        Size = UDim2.new(0.6, 0, 0.25, 0),
        Position = UDim2.new(0.2, 0, 0.375, 0),
        BackgroundColor3 = self.config.theme.Background,
        ZIndex = 10
    })
    
    self:addUICorner(dialog, 8)
    self:addUIStroke(dialog, 2, Color3.fromRGB(80, 80, 80))
    
    local title = self:createLabel("DialogTitle", {
        Size = UDim2.new(0.9, 0, 0.4, 0),
        Position = UDim2.new(0.05, 0, 0.1, 0),
        Text = string.format("Remove %d selected items?", count),
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        ZIndex = 11
    })
    
    local buttonFrame = self:createFrame("ButtonFrame", {
        Size = UDim2.new(0.9, 0, 0.3, 0),
        Position = UDim2.new(0.05, 0, 0.6, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    })
    
    local confirmButton = self:createButton("ConfirmButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Confirm",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    local cancelButton = self:createButton("CancelButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Button,
        Text = "Cancel",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    title.Parent = dialog
    buttonFrame.Parent = dialog
    confirmButton.Parent = buttonFrame
    cancelButton.Parent = buttonFrame
    dialog.Parent = self.mainFrame
    
    -- Confirm handler
    confirmButton.MouseButton1Click:Connect(function()
        local removedCount = 0
        for item, _ in pairs(self.state.selectedItems) do
            if self.groupData[self.state.currentGroup][item] then
                self.groupData[self.state.currentGroup][item] = nil
                removedCount = removedCount + 1
            end
        end
        
        self.state.selectedItems = {}
        self:refreshMembersList(self.state.currentGroup)
        self:refreshGroups() -- Update count badges
        self:showNotification(string.format("Removed %d items", removedCount), self.config.theme.Success)
        dialog:Destroy()
    end)
    
    -- Cancel handler
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Improved property editing dialog
function GroupFieldUILibrary:showEditPropertiesDialog(groupName, item, properties)
    if self.mainFrame:FindFirstChild("EditPropertiesDialog") then
        return
    end
    
    local dialog = self:createFrame("EditPropertiesDialog", {
        Size = UDim2.new(0.8, 0, 0.6, 0),
        Position = UDim2.new(0.1, 0, 0.2, 0),
        BackgroundColor3 = self.config.theme.Background,
        ZIndex = 10
    })
    
    self:addUICorner(dialog, 8)
    self:addUIStroke(dialog, 2, Color3.fromRGB(80, 80, 80))
    
    local title = self:createLabel("DialogTitle", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.05, 0),
        Text = "Edit Properties: " .. tostring(item),
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.GothamBold,
        ZIndex = 11
    })
    
    local propsBox = self:createTextBox("PropsBox", {
        Size = UDim2.new(0.9, 0, 0.7, 0),
        Position = UDim2.new(0.05, 0, 0.2, 0),
        Text = HttpService:JSONEncode(properties),
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = true,
        ZIndex = 11
    })
    
    local buttonFrame = self:createFrame("ButtonFrame", {
        Size = UDim2.new(0.9, 0, 0.1, 0),
        Position = UDim2.new(0.05, 0, 0.9, 0),
        BackgroundTransparency = 1,
        ZIndex = 11
    })
    
    local saveButton = self:createButton("SaveButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Success,
        Text = "Save",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    local cancelButton = self:createButton("CancelButton", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0.55, 0, 0, 0),
        BackgroundColor3 = self.config.theme.Error,
        Text = "Cancel",
        TextColor3 = self.config.theme.Text,
        Font = Enum.Font.Gotham,
        ZIndex = 12
    })
    
    title.Parent = dialog
    propsBox.Parent = dialog
    buttonFrame.Parent = dialog
    saveButton.Parent = buttonFrame
    cancelButton.Parent = buttonFrame
    dialog.Parent = self.mainFrame
    
    -- Focus props box automatically
    propsBox:CaptureFocus()
    
    -- Save handler
    saveButton.MouseButton1Click:Connect(function()
        local success, result = pcall(function()
            return HttpService:JSONDecode(propsBox.Text)
        end)
        
        if success then
            self.groupData[groupName][item] = result
            self:refreshMembersList(groupName)
            self:showNotification("Properties updated", self.config.theme.Success)
            dialog:Destroy()
        else
            self:showNotification("Invalid JSON: " .. result, self.config.theme.Warning)
        end
    end)
    
    -- Cancel handler
    cancelButton.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- Improved auto-refresh functionality
function GroupFieldUILibrary:startAutoRefresh()
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
    end
    
    self.refreshConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if self.state.isVisible and tick() - (self.lastRefresh or 0) >= self.config.autoRefreshInterval then
            self:refreshGroups()
            if self.state.currentGroup then
                self:refreshMembersList(self.state.currentGroup)
            end
            self.lastRefresh = tick()
        end
    end)
end

-- Improved group member counting
function GroupFieldUILibrary:countGroupMembers(groupName)
    if not self.groupData[groupName] then
        return 0
    end
    
    local count = 0
    for _ in pairs(self.groupData[groupName]) do
        count = count + 1
    end
    
    return count
end

-- Public API methods
function GroupFieldUILibrary:toggle()
    self.state.isVisible = not self.state.isVisible
    self.mainFrame.Visible = self.state.isVisible
    self.toggleButton.Text = self.state.isVisible and "Hide GUI" or "Show GUI"
    
    if self.state.isVisible then
        self:refreshGroups()
    end
end

function GroupFieldUILibrary:open()
    if not self.state.isVisible then
        self:toggle()
    end
end

function GroupFieldUILibrary:close()
    if self.state.isVisible then
        self:toggle()
    end
end

function GroupFieldUILibrary:destroy()
    if self.refreshConnection then
        self.refreshConnection:Disconnect()
    end
    
    self.screenGui:Destroy()
    setmetatable(self, nil)
end

function GroupFieldUILibrary:updateGroupData(newData)
    if type(newData) == "table" then
        self.groupData = newData
        self:refreshGroups()
        if self.state.currentGroup then
            self:refreshMembersList(self.state.currentGroup)
        end
    else
        warn("GroupFieldUILibrary: Invalid group data provided")
    end
end

function GroupFieldUILibrary:setTheme(newTheme)
    for key, defaultColor in pairs(DEFAULT_THEME) do
        self.config.theme[key] = newTheme[key] or defaultColor
    end
    
    -- TODO: Implement theme refresh to update all UI elements
    self:refreshUITheme()
end

function GroupFieldUILibrary:refreshUITheme()
    -- Update all UI elements with the current theme
    -- This would iterate through all elements and update their colors
    -- Implementation omitted for brevity
end

return GroupFieldUILibrary