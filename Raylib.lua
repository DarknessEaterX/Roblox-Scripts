local RayLib = {}
RayLib.__index = RayLib

-- Main dependencies
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Utility functions
local function Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

local function Tween(obj, properties, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Theme manager
local Theme = {
    Primary = Color3.fromRGB(40, 40, 40),
    Secondary = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(0, 170, 255),
    TextColor = Color3.fromRGB(255, 255, 255)
}

function RayLib:SetTheme(newTheme)
    Theme = newTheme
    -- Update all existing UI elements
end

-- Main window constructor
function RayLib:CreateWindow(options)
    local window = {}
    local options = options or {}
    
    -- Main container
    local MainFrame = Create("Frame", {
        Name = "RayLibWindow",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = Theme.Primary,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = options.Parent or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    })

    -- Mobile support
    if UserInputService.TouchEnabled then
        local aspectRatio = Create("UIAspectRatioConstraint", {
            AspectRatio = 1.78,
            DominantAxis = Enum.DominantAxis.Width,
            Parent = MainFrame
        })

        -- Mobile drag functionality
        local dragStartPos
        local dragStartTouch
        local dragInput
        
        MainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                dragStartTouch = input.Position
                dragStartPos = MainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragStartTouch = nil
                    end
                end)
            end
        end)

        MainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.TouchMovement then
                local delta = input.Position - dragStartTouch
                MainFrame.Position = UDim2.new(
                    dragStartPos.X.Scale,
                    dragStartPos.X.Offset + delta.X,
                    dragStartPos.Y.Scale,
                    dragStartPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Tab system
    function window:CreateTab(name)
        local tab = {}
        
        -- Tab button
        local TabButton = Create("TextButton", {
            Text = name,
            TextColor3 = Theme.TextColor,
            BackgroundColor3 = Theme.Secondary,
            Size = UDim2.new(0, 100, 0, 30)
        })

        -- Tab content
        local TabContent = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            Visible = false,
            Parent = MainFrame
        })

        function tab:CreateSection(title)
            local section = {}
            
            local SectionFrame = Create("Frame", {
                BackgroundColor3 = Theme.Secondary,
                Parent = TabContent
            })

            local SectionLabel = Create("TextLabel", {
                Text = "  " .. title,
                TextColor3 = Theme.TextColor,
                BackgroundColor3 = Theme.Accent,
                Size = UDim2.new(1, 0, 0, 25),
                Parent = SectionFrame
            })

            -- Elements container
            local ContentLayout = Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SectionFrame
            })

            function section:CreateLabel(text)
                local label = Create("TextLabel", {
                    Text = "  " .. text,
                    TextColor3 = Theme.TextColor,
                    BackgroundColor3 = Theme.Primary,
                    Size = UDim2.new(1, -10, 0, 25),
                    Parent = SectionFrame
                })

                local labelFunctions = {}
                
                function labelFunctions:Update(newText)
                    label.Text = "  " .. newText
                end

                return labelFunctions
            end

            function section:CreateButton(text, callback)
                local button = Create("TextButton", {
                    Text = "  " .. text,
                    TextColor3 = Theme.TextColor,
                    BackgroundColor3 = Theme.Primary,
                    Size = UDim2.new(1, -10, 0, 30),
                    Parent = SectionFrame
                })

                button.MouseButton1Click:Connect(callback)

                local buttonFunctions = {}
                
                function buttonFunctions:Update(newText)
                    button.Text = "  " .. newText
                end

                return buttonFunctions
            end

            return section
        end

        return tab
    end

    return window
end

return RayLib