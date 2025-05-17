-- UI Module for Roblox
local UIModule = {}

-- Helper function to create Roblox UI instances
local function createInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

-- Checkbox with TextLabel
function UIModule.createCheckbox(parent, labelText, isChecked, callback)
    local frame = createInstance("Frame", {
        Name = "Checkbox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = parent
    })

    local checkbox = createInstance("ImageButton", {
        Name = "CheckboxButton",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        Parent = frame
    })

    local checkmark = createInstance("ImageLabel", {
        Name = "Checkmark",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.8, 0, 0.8, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3570695787",
        Visible = isChecked,
        Parent = checkbox
    })

    local label = createInstance("TextLabel", {
        Name = "Label",
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    checkbox.MouseButton1Click:Connect(function()
        checkmark.Visible = not checkmark.Visible
        if callback then callback(checkmark.Visible) end
    end)

    return {
        frame = frame,
        setChecked = function(self, checked)
            checkmark.Visible = checked
        end,
        isChecked = function(self)
            return checkmark.Visible
        end
    }
end

-- RadioButton Group
function UIModule.createRadioGroup(parent, options, defaultIndex)
    local group = {
        options = {},
        selectedIndex = defaultIndex or 1
    }

    local container = createInstance("Frame", {
        Name = "RadioGroup",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, #options * 30),
        Parent = parent
    })

    for i, optionText in ipairs(options) do
        local optionFrame = createInstance("Frame", {
            Name = "Option_"..i,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, (i-1)*30),
            Parent = container
        })

        local radioButton = createInstance("ImageButton", {
            Name = "RadioButton",
            Position = UDim2.new(0, 0, 0, 5),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            AutoButtonColor = false,
            Parent = optionFrame
        })

        local radioDot = createInstance("ImageLabel", {
            Name = "RadioDot",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0.6, 0, 0.6, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://3570695787",
            Visible = (i == group.selectedIndex),
            Parent = radioButton
        })

        local label = createInstance("TextLabel", {
            Name = "Label",
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -30, 1, 0),
            BackgroundTransparency = 1,
            Text = optionText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = optionFrame
        })

        radioButton.MouseButton1Click:Connect(function()
            for _, option in ipairs(group.options) do
                option.radioDot.Visible = false
            end
            radioDot.Visible = true
            group.selectedIndex = i
        end)

        table.insert(group.options, {
            frame = optionFrame,
            radioDot = radioDot
        })
    end

    function group:getSelected()
        return self.selectedIndex
    end

    return group
end

-- Text Input with Masking
function UIModule.createMaskedInput(parent, placeholder, maskPattern)
    local textBox = createInstance("TextBox", {
        Name = "MaskedInput",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        TextColor3 = Color3.fromRGB(0, 0, 0),
        PlaceholderText = placeholder or "",
        ClearTextOnFocus = false,
        Parent = parent
    })

    if maskPattern then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = textBox.Text
            if not string.match(text, maskPattern) then
                textBox.Text = string.sub(text, 1, -2)
            end
        end)
    end

    return textBox
end

-- Slider
function UIModule.createSlider(parent, min, max, step, defaultValue)
    local slider = {
        min = min or 0,
        max = max or 100,
        step = step or 1,
        value = defaultValue or min
    }

    local frame = createInstance("Frame", {
        Name = "Slider",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent
    })

    local track = createInstance("Frame", {
        Name = "Track",
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        Parent = frame
    })

    local fill = createInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 150, 255),
        BorderSizePixel = 0,
        Parent = track
    })

    local thumb = createInstance("ImageButton", {
        Name = "Thumb",
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        Parent = track
    })

    local valueLabel = createInstance("TextLabel", {
        Name = "ValueLabel",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = tostring(slider.value),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = frame
    })

    local function updateSlider(value)
        slider.value = math.clamp(value, slider.min, slider.max)
        local ratio = (slider.value - slider.min) / (slider.max - slider.min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLabel.Text = tostring(slider.value)
    end

    thumb.MouseButton1Down:Connect(function()
        local connection
        connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = game:GetService("Players").LocalPlayer:GetMouse()
                local absolutePos = mousePos.X - track.AbsolutePosition.X
                local ratio = math.clamp(absolutePos / track.AbsoluteSize.X, 0, 1)
                local value = slider.min + ratio * (slider.max - slider.min)
                value = math.floor(value / slider.step + 0.5) * slider.step
                updateSlider(value)
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)

    updateSlider(slider.value)

    return slider
end

-- Dropdown List
function UIModule.createDropdown(parent, options, defaultIndex)
    local dropdown = {
        options = options or {},
        selectedIndex = defaultIndex or 1,
        isOpen = false
    }

    local frame = createInstance("Frame", {
        Name = "Dropdown",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        Parent = parent
    })

    local selectedLabel = createInstance("TextLabel", {
        Name = "SelectedLabel",
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Text = options[dropdown.selectedIndex] or "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local arrow = createInstance("ImageLabel", {
        Name = "Arrow",
        Position = UDim2.new(1, -25, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://9607705595", -- Down arrow icon
        Parent = frame
    })

    local optionsFrame = createInstance("Frame", {
        Name = "OptionsFrame",
        Position = UDim2.new(0, 0, 1, 5),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        ClipsDescendants = true,
        Visible = false,
        Parent = frame
    })

    local listLayout = createInstance("UIListLayout", {
        Name = "ListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = optionsFrame
    })

    local function toggleDropdown()
        dropdown.isOpen = not dropdown.isOpen
        optionsFrame.Visible = dropdown.isOpen
        arrow.Image = dropdown.isOpen and "rbxassetid://9607705276" or "rbxassetid://9607705595" -- Up/down arrows
        
        if dropdown.isOpen then
            optionsFrame.Size = UDim2.new(1, 0, 0, #dropdown.options * 30)
        else
            optionsFrame.Size = UDim2.new(1, 0, 0, 0)
        end
    end

    frame.MouseButton1Click:Connect(toggleDropdown)

    for i, option in ipairs(dropdown.options) do
        local optionButton = createInstance("TextButton", {
            Name = "Option_"..i,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = Color3.fromRGB(70, 70, 70),
            Text = option,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            LayoutOrder = i,
            Parent = optionsFrame
        })

        optionButton.MouseButton1Click:Connect(function()
            dropdown.selectedIndex = i
            selectedLabel.Text = option
            toggleDropdown()
        end)
    end

    function dropdown:getSelected()
        return self.selectedIndex, self.options[self.selectedIndex]
    end

    return dropdown
end

-- Scrolling List
function UIModule.createScrollList(parent, items, visibleCount, itemHeight)
    local scrollList = {
        items = items or {},
        visibleCount = visibleCount or 5,
        scrollPosition = 1,
        itemHeight = itemHeight or 30
    }

    local frame = createInstance("Frame", {
        Name = "ScrollList",
        Size = UDim2.new(1, 0, 0, scrollList.visibleCount * scrollList.itemHeight),
        BackgroundTransparency = 1,
        Parent = parent
    })

    local scrollFrame = createInstance("ScrollingFrame", {
        Name = "ScrollFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, #scrollList.items * scrollList.itemHeight),
        Parent = frame
    })

    local listLayout = createInstance("UIListLayout", {
        Name = "ListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scrollFrame
    })

    local upButton = createInstance("TextButton", {
        Name = "UpButton",
        Position = UDim2.new(1, -20, 0, 0),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Text = "↑",
        Parent = frame
    })

    local downButton = createInstance("TextButton", {
        Name = "DownButton",
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Text = "↓",
        Parent = frame
    })

    local function updateList()
        scrollFrame.CanvasPosition = Vector2.new(0, (scrollList.scrollPosition - 1) * scrollList.itemHeight)
    end

    upButton.MouseButton1Click:Connect(function()
        if scrollList.scrollPosition > 1 then
            scrollList.scrollPosition = scrollList.scrollPosition - 1
            updateList()
        end
    end)

    downButton.MouseButton1Click:Connect(function()
        if scrollList.scrollPosition < #scrollList.items - scrollList.visibleCount + 1 then
            scrollList.scrollPosition = scrollList.scrollPosition + 1
            updateList()
        end
    end)

    for i, item in ipairs(scrollList.items) do
        local itemFrame = createInstance("TextLabel", {
            Name = "Item_"..i,
            Size = UDim2.new(1, -25, 0, scrollList.itemHeight),
            BackgroundTransparency = 1,
            Text = item,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i,
            Parent = scrollFrame
        })
    end

    function scrollList:updateItems(newItems)
        self.items = newItems or {}
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #self.items * self.itemHeight)
        
        -- Clear existing items
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextLabel") and child.Name:match("Item_") then
                child:Destroy()
            end
        end
        
        -- Add new items
        for i, item in ipairs(self.items) do
            local itemFrame = createInstance("TextLabel", {
                Name = "Item_"..i,
                Size = UDim2.new(1, -25, 0, self.itemHeight),
                BackgroundTransparency = 1,
                Text = item,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = i,
                Parent = scrollFrame
            })
        end
    end

    return scrollList
end

-- Radial Menu
function UIModule.createRadialMenu(parent, options, centerPosition, radius)
    local radialMenu = {
        options = options or {},
        centerPosition = centerPosition or Vector2.new(0.5, 0.5),
        radius = radius or 100,
        isOpen = false
    }

    local screenGui = createInstance("ScreenGui", {
        Name = "RadialMenu",
        Parent = parent
    })

    local background = createInstance("Frame", {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.7,
        Visible = false,
        Parent = screenGui
    })

    local menuItems = {}

    local function calculatePosition(angle, distance)
        return UDim2.new(
            0.5, distance * math.cos(angle),
            0.5, distance * math.sin(angle)
        )
    end

    local function toggleMenu()
        radialMenu.isOpen = not radialMenu.isOpen
        background.Visible = radialMenu.isOpen
        
        for _, item in ipairs(menuItems) do
            item.button.Visible = radialMenu.isOpen
        end
    end

    for i, option in ipairs(radialMenu.options) do
        local angle = math.rad((i-1) * (360/#radialMenu.options) - 90)
        local position = calculatePosition(angle, radialMenu.radius)
        
        local button = createInstance("ImageButton", {
            Name = "Option_"..i,
            Size = UDim2.new(0, 60, 0, 60),
            Position = position,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Image = option.icon or "",
            Visible = false,
            Parent = screenGui
        })

        local label = createInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 1, 5),
            BackgroundTransparency = 1,
            Text = option.text or "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Parent = button
        })

        button.MouseButton1Click:Connect(function()
            if option.callback then option.callback() end
            toggleMenu()
        end)

        table.insert(menuItems, {
            button = button,
            label = label
        })
    end

    -- Close menu when clicking background
    background.MouseButton1Click:Connect(toggleMenu)

    -- Return methods to control the menu
    return {
        toggle = toggleMenu,
        isOpen = function() return radialMenu.isOpen end
    }
end

return UIModule