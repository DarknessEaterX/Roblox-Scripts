local GroupField = {}
GroupField.__index = GroupField

-- Constructor
function GroupField.new(parentFrame, config)
    config = config or {}
    local self = setmetatable({}, GroupField)
    
    self.Container = Instance.new("Frame")
    self.Container.Name = "GroupField"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(1, 0, 0, 0)
    self.Container.AutomaticSize = Enum.AutomaticSize.Y
    self.Container.Parent = parentFrame
    
    self.Rows = {}
    self.Classes = {}
    
    -- Style configuration
    self.Settings = {
        RowPadding = config.RowPadding or 5,
        DividerThickness = config.DividerThickness or 1,
        DividerColor = config.DividerColor or Color3.fromRGB(60, 60, 60),
        RowBackgroundColor = config.RowBackgroundColor or Color3.fromRGB(30, 30, 30),
        RowBackgroundTransparency = config.RowBackgroundTransparency or 0.8
    }
    
    return self
end

-- Creates a new row
function GroupField:CreateRow(rowName)
    if self.Rows[rowName] then
        warn("Row '"..rowName.."' already exists!")
        return
    end
    
    local rowFrame = Instance.new("Frame")
    rowFrame.Name = rowName
    rowFrame.BackgroundColor3 = self.Settings.RowBackgroundColor
    rowFrame.BackgroundTransparency = self.Settings.RowBackgroundTransparency
    rowFrame.Size = UDim2.new(1, 0, 0, 0)
    rowFrame.AutomaticSize = Enum.AutomaticSize.Y
    rowFrame.LayoutOrder = #self.Container:GetChildren()
    rowFrame.Parent = self.Container
    
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingBottom = UDim.new(0, self.Settings.RowPadding)
    uiPadding.PaddingLeft = UDim.new(0, self.Settings.RowPadding)
    uiPadding.PaddingRight = UDim.new(0, self.Settings.RowPadding)
    uiPadding.PaddingTop = UDim.new(0, self.Settings.RowPadding)
    uiPadding.Parent = rowFrame
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, self.Settings.RowPadding)
    uiListLayout.Parent = rowFrame
    
    self.Rows[rowName] = {
        Frame = rowFrame,
        Classes = {}
    }
    
    return rowFrame
end

-- Adds a class (UI element) to a row
function GroupField:AddClasse(rowName, instance)
    if not self.Rows[rowName] then
        warn("Row '"..rowName.."' doesn't exist!")
        return
    end
    
    instance.LayoutOrder = #self.Rows[rowName].Frame:GetChildren()
    instance.Parent = self.Rows[rowName].Frame
    
    table.insert(self.Rows[rowName].Classes, instance)
    
    return instance
end

-- Removes a row
function GroupField:RemoveRow(rowName)
    if not self.Rows[rowName] then
        warn("Row '"..rowName.."' doesn't exist!")
        return false
    end
    
    self.Rows[rowName].Frame:Destroy()
    self.Rows[rowName] = nil
    
    -- Rebuild layout orders to maintain consistency
    for i, child in ipairs(self.Container:GetChildren()) do
        if child:IsA("Frame") then
            child.LayoutOrder = i
        end
    end
    
    return true
end

-- Adds a subclass (nested UI element)
function GroupField:SubClasse(rowName, instance)
    if not self.Rows[rowName] then
        warn("Row '"..rowName.."' doesn't exist!")
        return
    end
    
    -- Create a container for the subclass
    local subContainer = Instance.new("Frame")
    subContainer.Name = "SubClassContainer"
    subContainer.BackgroundTransparency = 1
    subContainer.Size = UDim2.new(1, 0, 0, 0)
    subContainer.AutomaticSize = Enum.AutomaticSize.Y
    subContainer.LayoutOrder = #self.Rows[rowName].Frame:GetChildren()
    subContainer.Parent = self.Rows[rowName].Frame
    
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingLeft = UDim.new(0, 15) -- Indent for visual hierarchy
    uiPadding.Parent = subContainer
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = subContainer
    
    -- Add the instance to the subclass container
    instance.Parent = subContainer
    
    return subContainer
end

-- Adds a visual divider between rows
function GroupField:AddDivider()
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.BackgroundColor3 = self.Settings.DividerColor
    divider.BorderSizePixel = 0
    divider.Size = UDim2.new(1, 0, 0, self.Settings.DividerThickness)
    divider.LayoutOrder = #self.Container:GetChildren()
    divider.Parent = self.Container
    
    return divider
end

return GroupField