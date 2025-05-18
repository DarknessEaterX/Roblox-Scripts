local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(options, parent, position)
    local self = setmetatable({}, Dropdown)

    self.Frame = Instance.new("Frame")
    self.Frame.Name = "DropdownFrame"
    self.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Frame.Size = UDim2.new(0, 200, 0, 40)
    self.Frame.Position = position or UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.Frame.BorderSizePixel = 0
    self.Frame.Parent = parent

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 5 
    aspect.DominantAxis = Enum.DominantAxis.Width
    aspect.Parent = self.Frame

    self.Button = Instance.new("TextButton")
    self.Button.Size = UDim2.new(1, 0, 1, 0)
    self.Button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    self.Button.BorderSizePixel = 0
    self.Button.Text = "Select..."
    self.Button.TextColor3 = Color3.new(1,1,1)
    self.Button.Font = Enum.Font.SourceSans
    self.Button.TextSize = 18
    self.Button.Parent = self.Frame

    self.ListFrame = Instance.new("Frame")
    self.ListFrame.Size = UDim2.new(1, 0, 0, 0) 
    self.ListFrame.Position = UDim2.new(0, 0, 1, 5)
    self.ListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.ListFrame.BorderSizePixel = 0
    self.ListFrame.ClipsDescendants = true
    self.ListFrame.Parent = self.Frame

    local listAspect = Instance.new("UIAspectRatioConstraint")
    listAspect.AspectRatio = 5
    listAspect.DominantAxis = Enum.DominantAxis.Width
    listAspect.Parent = self.ListFrame

    self.Options = options or {}
    self.Items = {}

    self.IsOpen = false
    self.Selected = nil

    self:CreateItems()

    self.Button.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    return self
end

function Dropdown:CreateItems()
    local itemHeight = 30
    local padding = 2

    for i, option in ipairs(self.Options) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -padding*2, 0, itemHeight)
        btn.Position = UDim2.new(0, padding, 0, (i-1) * (itemHeight + padding))
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btn.BorderSizePixel = 0
        btn.Text = option
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.Parent = self.ListFrame

        btn.MouseButton1Click:Connect(function()
            self.Selected = option
            self.Button.Text = option
            self:Close()
            if self.OnSelect then
                self.OnSelect(option)
            end
        end)

        table.insert(self.Items, btn)
    end

    self.FullHeight = (#self.Options) * (itemHeight + padding) + padding
end

function Dropdown:Open()
    if self.IsOpen then return end
    self.IsOpen = true

    self.ListFrame:TweenSize(UDim2.new(1, 0, 0, self.FullHeight), "Out", "Quad", 0.2, true)
end

function Dropdown:Close()
    if not self.IsOpen then return end
    self.IsOpen = false

    self.ListFrame:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.2, true)
end

function Dropdown:Toggle()
    if self.IsOpen then
        self:Close()
    else
        self:Open()
    end
end

function Dropdown:SetCallback(func)
    self.OnSelect = func
end

return Dropdown