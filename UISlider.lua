local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "UltraSliderUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Container
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 300, 0, 60)
container.Position = UDim2.new(0.5, -150, 0.5, -30)
container.BackgroundTransparency = 1
container.Parent = gui

-- Slider Track
local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "Track"
sliderTrack.Size = UDim2.new(1, -20, 0, 4)
sliderTrack.Position = UDim2.new(0, 10, 0.5, -2)
sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = container

-- Track Rounded Corners
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = sliderTrack

-- Fill Bar
local sliderFill = Instance.new("Frame")
sliderFill.Name = "Fill"
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

-- Fill Rounded Corners
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = sliderFill

-- Knob
local sliderKnob = Instance.new("ImageButton")
sliderKnob.Name = "Knob"
sliderKnob.Size = UDim2.new(0, 16, 0, 16)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.AutoButtonColor = false
sliderKnob.ZIndex = 2
sliderKnob.Parent = sliderTrack

-- Knob Rounded Corners
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

-- Knob Glow Effect
local knobGlow = Instance.new("ImageLabel")
knobGlow.Name = "Glow"
knobGlow.Size = UDim2.new(2, 0, 2, 0)
knobGlow.AnchorPoint = Vector2.new(0.5, 0.5)
knobGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
knobGlow.Image = "rbxassetid://5028857084"
knobGlow.ImageColor3 = Color3.fromRGB(0, 180, 255)
knobGlow.ImageTransparency = 0.8
knobGlow.ScaleType = Enum.ScaleType.Slice
knobGlow.SliceCenter = Rect.new(24, 24, 24, 24)
knobGlow.BackgroundTransparency = 1
knobGlow.Parent = sliderKnob

-- Value Display
local valueLabel = Instance.new("TextLabel")
valueLabel.Name = "ValueLabel"
valueLabel.Size = UDim2.new(0, 50, 0, 20)
valueLabel.AnchorPoint = Vector2.new(0.5, 0)
valueLabel.Position = UDim2.new(0.5, 0, -1.5, 0)
valueLabel.BackgroundTransparency = 1
valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
valueLabel.Text = ""
valueLabel.Font = Enum.Font.GothamMedium
valueLabel.TextSize = 14
valueLabel.ZIndex = 3
valueLabel.Visible = false
valueLabel.Parent = sliderKnob

-- Animation Settings
local tweenInfo = {
    quick = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    elastic = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
}

-- State Management
local isDragging = false
local currentValue = 0
local lastInputPosition = Vector2.new(0, 0)
local valueVisible = false
local valueHideDelay = 0

-- Show Value with Animation
local function showValue()
    if valueVisible then return end
    valueVisible = true
    valueLabel.Visible = true
    
    valueLabel.Position = UDim2.new(0.5, 0, -2, 0)
    valueLabel.TextTransparency = 1
    
    local slideIn = TweenService:Create(
        valueLabel,
        tweenInfo.smooth,
        {
            Position = UDim2.new(0.5, 0, -1.5, 0),
            TextTransparency = 0
        }
    )
    slideIn:Play()
end

-- Hide Value with Animation
local function hideValue()
    if not valueVisible then return end
    valueVisible = false
    
    local slideOut = TweenService:Create(
        valueLabel,
        tweenInfo.smooth,
        {
            Position = UDim2.new(0.5, 0, -2, 0),
            TextTransparency = 1
        }
    )
    
    slideOut.Completed:Connect(function()
        if not valueVisible then
            valueLabel.Visible = false
        end
    end)
    
    slideOut:Play()
end

-- Update Slider Position and Value
local function updateSlider(inputPosition)
    local absolutePosition = sliderTrack.AbsolutePosition
    local absoluteSize = sliderTrack.AbsoluteSize
    
    local relativeX = math.clamp(
        (inputPosition.X - absolutePosition.X) / absoluteSize.X,
        0,
        1
    )
    
    currentValue = math.floor(relativeX * 100)
    valueLabel.Text = currentValue .. "%"
    
    -- Update fill and knob position
    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
    sliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
    
    -- Show value when changing
    showValue()
    valueHideDelay = 0.5 -- Delay before hiding (in seconds)
end

-- Input Handlers
local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        lastInputPosition = input.Position
        
        -- Animate knob press
        local pressTween = TweenService:Create(
            sliderKnob,
            tweenInfo.quick,
            {Size = UDim2.new(0, 14, 0, 14)}
        )
        pressTween:Play()
        
        -- Show value immediately
        showValue()
        updateSlider(input.Position)
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        
        -- Animate knob release
        local releaseTween = TweenService:Create(
            sliderKnob,
            tweenInfo.elastic,
            {Size = UDim2.new(0, 16, 0, 16)}
        )
        releaseTween:Play()
        
        -- Start delay for hiding value
        valueHideDelay = 0.5
    end
end

local function onInputChanged(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                       input.UserInputType == Enum.UserInputType.Touch) then
        lastInputPosition = input.Position
        updateSlider(input.Position)
    end
end

-- Connect Events
sliderKnob.InputBegan:Connect(onInputBegan)
sliderTrack.InputBegan:Connect(onInputBegan)

UserInputService.InputEnded:Connect(onInputEnded)
UserInputService.InputChanged:Connect(onInputChanged)

-- Initialize
lastInputPosition = Vector2.new(
    sliderTrack.AbsolutePosition.X,
    sliderTrack.AbsolutePosition.Y
)
updateSlider(lastInputPosition)

-- Handle value hide delay
RunService.Heartbeat:Connect(function(deltaTime)
    if valueHideDelay > 0 and not isDragging then
        valueHideDelay = valueHideDelay - deltaTime
        if valueHideDelay <= 0 then
            hideValue()
        end
    end
end)