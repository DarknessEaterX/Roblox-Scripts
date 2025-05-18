local RayfieldDropdown = {}
RayfieldDropdown.__index = RayfieldDropdown

local openDropdown
local DROPDOWN_HEIGHT = 46
local DROPDOWN_WIDTH = 260
local DROPDOWN_SPACING = 16
local DROPDOWN_STACK_OFFSET = 60 -- Each next dropdown moves down by this many px

local dropdownCount = 0

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

local function getGui()
    local name = "RayfieldDropdownModuleGui"
    local cg = game:GetService("CoreGui")
    local gui = cg:FindFirstChild(name)
    if gui then return gui end
    gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = cg
    return gui
end

function RayfieldDropdown.Dropdown(title, options, def, callback)
    dropdownCount = dropdownCount + 1
    local self = setmetatable({}, RayfieldDropdown)

    self.Title = title or "Dropdown"
    self.Options = options or {}
    self.Callback = callback
    self.Selected = def or (options and options[1]) or ""
    self.IsOpen = false

    -- Main frame
    self.Frame = Instance.new("Frame")
    self.Frame.Name = "RayfieldDropdownFrame"
    self.Frame.AnchorPoint = Vector2.new(0.5, 0)
    self.Frame.Size = UDim2.new(0, DROPDOWN_WIDTH, 0, DROPDOWN_HEIGHT)
    self.Frame.Position = UDim2.new(0.5, 0, 0.4, (dropdownCount-1)*DROPDOWN_STACK_OFFSET)
    self.Frame.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    self.Frame.BorderSizePixel = 0
    self.Frame.Parent = getGui()
    Instance.new("UICorner", self.Frame).CornerRadius = UDim.new(0, 8)

    -- Drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 16, 1, 16)
    shadow.Position = UDim2.new(0, -8, 0, -8)
    shadow.ImageColor3 = Color3.fromRGB(0,0,0)
    shadow.ImageTransparency = 0.65
    shadow.ZIndex = 0
    shadow.Parent = self.Frame

    -- Label
    local label = Instance.new("TextLabel")
    label.Name = "DropdownLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Text = self.Title
    label.TextColor3 = Color3.fromRGB(180, 180, 210)
    label.Font = Enum.Font.Gotham
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 2
    label.Parent = self.Frame

    -- Main button (shows current value)
    self.Button = Instance.new("TextButton")
    self.Button.Name = "DropdownButton"
    self.Button.Size = UDim2.new(1, 0, 1, 0)
    self.Button.BackgroundTransparency = 1
    self.Button.BorderSizePixel = 0
    self.Button.Text = ""
    self.Button.ZIndex = 3
    self.Button.Parent = self.Frame

    -- Current value
    self.ValueLabel = Instance.new("TextLabel")
    self.ValueLabel.Text = self.Selected
    self.ValueLabel.Name = "CurrentValue"
    self.ValueLabel.BackgroundTransparency = 1
    self.ValueLabel.Size = UDim2.new(0, 120, 1, 0)
    self.ValueLabel.Position = UDim2.new(1, -150, 0, 0)
    self.ValueLabel.TextColor3 = Color3.fromRGB(225, 225, 255)
    self.ValueLabel.Font = Enum.Font.GothamSemibold
    self.ValueLabel.TextSize = 15
    self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.ValueLabel.TextYAlignment = Enum.TextYAlignment.Center
    self.ValueLabel.ZIndex = 4
    self.ValueLabel.Parent = self.Frame

    -- Arrow
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(85, 170, 255)
    arrow.TextSize = 18
    arrow.Font = Enum.Font.Gotham
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -32, 0, 0)
    arrow.ZIndex = 4
    arrow.Parent = self.Frame

    -- Dropdown list
    self.ListFrame = Instance.new("ScrollingFrame")
    self.ListFrame.Size = UDim2.new(1, 0, 0, 0)
    self.ListFrame.Position = UDim2.new(0, 0, 1, 0)
    self.ListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
    self.ListFrame.BorderSizePixel = 0
    self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.ListFrame.ScrollBarThickness = 8
    self.ListFrame.Parent = self.Frame
    self.ListFrame.ClipsDescendants = true
    self.ListFrame.Visible = false
    self.ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.ListFrame.ZIndex = 5
    Instance.new("UICorner", self.ListFrame).CornerRadius = UDim.new(0, 8)

    local padding = Instance.new("UIPadding", self.ListFrame)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    local uiList = Instance.new("UIListLayout", self.ListFrame)
    uiList.FillDirection = Enum.FillDirection.Vertical
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Padding = UDim.new(0, 4)

    -- Draw options
    function self:Refresh()
        for _, c in ipairs(self.ListFrame:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, option in ipairs(self.Options) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 34)
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
            btn.Text = tostring(option)
            btn.TextColor3 = Color3.fromRGB(220,220,255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 15
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.AutoButtonColor = false
            btn.ZIndex = 6
            btn.Parent = self.ListFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(40,80,150)
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(32, 32, 50)
            end)
            btn.MouseButton1Click:Connect(function()
                self:SetSelected(option)
                self:Close()
            end)
            btn.TouchTap:Connect(function()
                self:SetSelected(option)
                self:Close()
            end)
        end
        local fullHeight = #self.Options * (34 + uiList.Padding.Offset) + 8
        self.FullHeight = math.min(fullHeight, 180)
        self.ListFrame.CanvasSize = UDim2.new(0, 0, 0, fullHeight)
    end

    function self:SetSelected(val)
        self.Selected = val
        self.ValueLabel.Text = val
        SafeCallback(self.Callback, val)
    end

    function self:Open()
        if openDropdown and openDropdown ~= self then openDropdown:Close() end
        openDropdown = self
        self.IsOpen = true
        self.ListFrame.Visible = true
        self.ListFrame:TweenSize(UDim2.new(1, 0, 0, self.FullHeight), "Out", "Quad", 0.22, true)
    end

    function self:Close()
        if not self.IsOpen then return end
        self.IsOpen = false
        openDropdown = nil
        self.ListFrame:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quad", 0.16, true)
        task.delay(0.16, function() if not self.IsOpen then self.ListFrame.Visible = false end end)
    end

    function self:Toggle()
        if self.IsOpen then self:Close() else self:Open() end
    end

    function self:SetOptions(newOptions)
        self.Options = newOptions or {}
        self:Refresh()
    end

    function self:GetSelected()
        return self.Selected
    end

    -- Events
    self.Button.MouseButton1Click:Connect(function() self:Toggle() end)
    self.Button.TouchTap:Connect(function() self:Toggle() end)

    -- Click/tap outside to close
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

    -- Initial UI
    self:Refresh()
    self:SetSelected(self.Selected)

    -- API:
    return setmetatable({
        SetSelected = function(_, v) self:SetSelected(v) end,
        GetSelected = function(_) return self:GetSelected() end,
        SetOptions = function(_, opts) self:SetOptions(opts) end,
        Destroy = function(_)
            if self._InputConn then self._InputConn:Disconnect() end
            if self.Frame then self.Frame:Destroy() end
            dropdownCount = dropdownCount - 1
        end,
        Frame = self.Frame, -- for advanced users
    }, {__index = self})
end

return RayfieldDropdown