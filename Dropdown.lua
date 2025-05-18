local Dropdown = {}
Dropdown.__index = Dropdown

local openDropdown

local function SafeCallback(callback, ...)
    if type(callback) == "function" then
        local ok, res = pcall(callback, ...)
        if not ok then
            warn("[Dropdown Error]: " .. tostring(res))
            if typeof(setclipboard) == "function" then pcall(setclipboard, tostring(res)) end
        end
        return res
    end
end

function Dropdown.new(options, parent, position, settings)
    local self = setmetatable({}, Dropdown)

    settings = settings or {}
    self.ItemHeight = settings.ItemHeight or 38
    self.MaxListHeight = settings.MaxHeight or 180 -- taller for mobile
    self.Width = settings.Width or 200

    self.Options = options or {}
    self.Selected = nil
    self.Items = {}
    self.IsOpen = false
    self.OnSelect = nil

    self.Frame = Instance.new("Frame")
    self.Frame.Name = "DropdownFrame"
    self.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Frame.Size = UDim2.new(0, self.Width, 0, 44)
    self.Frame.Position = position or UDim2.new(0.5, 0, 0.5, 0)
    self.Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.Frame.BorderSizePixel = 0
    self.Frame.Parent = parent

    local corner = Instance.new("UICorner", self.Frame)
    corner.CornerRadius = UDim.new(0, 8)

    self.Button = Instance.new("TextButton")
    self.Button.Size = UDim2.new(1, 0, 1, 0)
    self.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    self.Button.BorderSizePixel = 0
    self.Button.Text = "Select..."
    self.Button.TextColor3 = Color3.fromRGB(255,255,255)
    self.Button.Font = Enum.Font.Gotham
    self.Button.TextSize = 18
    self.Button.AutoButtonColor = false
    self.Button.Parent = self.Frame
    Instance.new("UICorner", self.Button).CornerRadius = UDim.new(0, 8)

    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(180,180,180)
    arrow.TextSize = 18
    arrow.Font = Enum.Font.Gotham
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.Parent = self.Button

    self.ListFrame = Instance.new("ScrollingFrame")
    self.ListFrame.Size = UDim2.new(1, 0, 0, 0)
    self.ListFrame.Position = UDim2.new(0, 0, 1, 0)
    self.ListFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    self.ListFrame.BorderSizePixel = 0
    self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ListFrame.ScrollBarThickness = 10
    self.ListFrame.Parent = self.Frame
    self.ListFrame.ClipsDescendants = true
    self.ListFrame.Visible = false
    self.ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", self.ListFrame).CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", self.ListFrame)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)

    local uiList = Instance.new("UIListLayout", self.ListFrame)
    uiList.FillDirection = Enum.FillDirection.Vertical
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Padding = UDim.new(0, 4)

    -- Populate items
    function self:Refresh()
        for _, btn in ipairs(self.Items) do
            btn:Destroy()
        end
        self.Items = {}
        for i, option in ipairs(self.Options) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, self.ItemHeight)
            btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            btn.Text = tostring(option)
            btn.TextColor3 = Color3.fromRGB(250,250,250)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 17
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.AutoButtonColor = false
            btn.Parent = self.ListFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(95,160,220)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end)
            btn.MouseButton1Click:Connect(function()
                self:SetSelected(option)
                self:Close()
            end)
            btn.TouchTap:Connect(function()
                self:SetSelected(option)
                self:Close()
            end)

            table.insert(self.Items, btn)
        end
        -- Adjust list height
        local fullHeight = #self.Options * (self.ItemHeight + uiList.Padding.Offset) + 8
        self.FullHeight = math.min(fullHeight, self.MaxListHeight)
        self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, fullHeight)
    end

    function self:SetOptions(newOptions)
        self.Options = newOptions or {}
        self:Refresh()
    end

    function self:SetSelected(val)
        self.Selected = val
        self.Button.Text = tostring(val)
        SafeCallback(self.OnSelect, val)
    end

    function self:GetSelected()
        return self.Selected
    end

    function self:Open()
        if openDropdown and openDropdown ~= self then
            openDropdown:Close()
        end
        openDropdown = self
        self.IsOpen = true
        self.ListFrame.Visible = true
        self.ListFrame:TweenSize(UDim2.new(1, 0, 0, self.FullHeight), "Out", "Quad", 0.22, true)
    end

    function self:Close()
        if not self.IsOpen then return end
        self.IsOpen = false
        openDropdown = nil
        self.ListFrame:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.15, true)
        task.delay(0.16, function() if not self.IsOpen then self.ListFrame.Visible = false end end)
    end

    function self:Toggle()
        if self.IsOpen then
            self:Close()
        else
            self:Open()
        end
    end

    function self:SetCallback(func)
        self.OnSelect = func
    end

    -- Button events (Mouse and Touch)
    self.Button.MouseButton1Click:Connect(function() self:Toggle() end)
    self.Button.TouchTap:Connect(function() self:Toggle() end)

    -- Close if tap/click outside (also works on mobile)
    local uis = game:GetService("UserInputService")
    self._InputConn = uis.InputBegan:Connect(function(input, gp)
        if self.IsOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            local mouse = uis:GetMouseLocation()
            local abs = self.Frame.AbsolutePosition
            local size = self.Frame.AbsoluteSize
            if not (mouse.X >= abs.X and mouse.X <= abs.X+size.X and mouse.Y >= abs.Y and mouse.Y <= abs.Y+size.Y+self.FullHeight) then
                self:Close()
            end
        end
    end)

    -- auto refresh
    self:Refresh()
    return self
end

function Dropdown:Destroy()
    if self._InputConn then self._InputConn:Disconnect() end
    if self.Frame then self.Frame:Destroy() end
end

return Dropdown