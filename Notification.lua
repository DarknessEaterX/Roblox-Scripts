local NotificationModule = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "NotificationGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Constants
local NotificationWidth = 350
local NotificationHeight = 120  -- Default height for single-line notifications
local NotificationPadding = 15
local MaxNotifications = 5
local ActiveNotifications = {}

-- Colors
local BackgroundColor = Color3.fromRGB(25, 25, 30)
local TitleColor = Color3.fromRGB(255, 255, 255)
local MessageColor = Color3.fromRGB(200, 200, 210)
local AccentColor = Color3.fromRGB(0, 170, 255)
local CloseButtonColor = Color3.fromRGB(70, 70, 80)

-- Create Notification Frame
local function CreateNotification(title, message, duration, pinned, multiline)
    local container = Instance.new("Frame")
    container.BackgroundColor3 = BackgroundColor
    container.Size = UDim2.new(0, NotificationWidth, 0, multiline and NotificationHeight + 40 or NotificationHeight)
    container.AnchorPoint = Vector2.new(1, 0)
    container.BorderSizePixel = 0
    container.Position = UDim2.new(1, NotificationWidth + 20, 0, 20) -- Start offscreen
    container.Parent = gui
    container.ZIndex = 10
    
    -- Shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundTransparency = 1
    shadow.ZIndex = 9
    shadow.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    -- Top accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = AccentColor
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 11
    accentBar.Parent = container
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 8)
    accentCorner.Parent = accentBar

    -- Content padding
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = container

    -- Title label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = string.upper(title)
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = TitleColor
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    titleLabel.ZIndex = 11

    -- Message label
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = MessageColor
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, 0, 0, multiline and 60 or 20)
    messageLabel.TextWrapped = multiline
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Position = UDim2.new(0, 0, 0, 25)
    messageLabel.Parent = container
    messageLabel.ZIndex = 11

    -- Close button (for pinned notifications)
    if pinned then
        local closeButton = Instance.new("ImageButton")
        closeButton.Name = "CloseButton"
        closeButton.Image = "rbxassetid://3926305904"
        closeButton.ImageRectOffset = Vector2.new(284, 4)
        closeButton.ImageRectSize = Vector2.new(24, 24)
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -24, 0, 12)
        closeButton.AnchorPoint = Vector2.new(1, 0)
        closeButton.BackgroundColor3 = CloseButtonColor
        closeButton.BackgroundTransparency = 0.5
        closeButton.ZIndex = 12
        closeButton.Parent = container
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 4)
        closeCorner.Parent = closeButton
        
        closeButton.MouseButton1Click:Connect(function()
            NotificationModule._Dismiss(container)
        end)
        
        -- Hover effects
        closeButton.MouseEnter:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.1), {
                BackgroundTransparency = 0
            }):Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            TweenService:Create(closeButton, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.5
            }):Play()
        end)
    end

    return container
end

-- Rearrange all notifications top-right
function NotificationModule._UpdateLayout()
    local yOffset = 20
    for i, notif in ipairs(ActiveNotifications) do
        local targetPos = UDim2.new(1, -20, 0, yOffset)
        TweenService:Create(notif, TweenInfo.new(0.25), {Position = targetPos}):Play()
        yOffset += notif.AbsoluteSize.Y + NotificationPadding
        
        -- Ensure we don't go off-screen
        if yOffset + notif.AbsoluteSize.Y > gui.AbsoluteSize.Y then
            NotificationModule._Dismiss(notif)
        end
    end
end

-- Remove & cleanup
function NotificationModule._Dismiss(frame)
    for i, notif in ipairs(ActiveNotifications) do
        if notif == frame then
            table.remove(ActiveNotifications, i)
            break
        end
    end
    
    local tween = TweenService:Create(frame, TweenInfo.new(0.25), {
        Position = UDim2.new(1, NotificationWidth + 20, frame.Position.Y.Scale, frame.Position.Y.Offset),
        BackgroundTransparency = 1
    })
    
    -- Also fade out the shadow
    local shadow = frame:FindFirstChild("Shadow")
    if shadow then
        TweenService:Create(shadow, TweenInfo.new(0.25), {
            ImageTransparency = 1
        }):Play()
    end
    
    tween:Play()
    tween.Completed:Wait()
    frame:Destroy()
    NotificationModule._UpdateLayout()
end

-- Main API
function NotificationModule.Notify(title, message, duration, pinned, multiline)
    -- Limit number of notifications
    if #ActiveNotifications >= MaxNotifications then
        NotificationModule._Dismiss(ActiveNotifications[1])
    end
    
    local notif = CreateNotification(title, message, duration or 5, pinned, multiline)
    table.insert(ActiveNotifications, notif)

    -- Slide-in animation
    TweenService:Create(notif, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -20, 0, 9999), -- temp position for height calculation
        BackgroundTransparency = 0
    }):Play()

    NotificationModule._UpdateLayout()

    -- Auto dismiss
    if not pinned then
        task.delay(duration or 5, function()
            if notif and notif.Parent then
                NotificationModule._Dismiss(notif)
            end
        end)
    end
    
    return notif
end

return NotificationModule