local NotificationModule = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "NotificationGui"
gui.ResetOnSpawn = false

-- Settings
local Positions = {
    ["Top-Right"] = UDim2.new(1, -20, 0, 20),
    ["Bottom-Right"] = UDim2.new(1, -20, 1, -20),
    ["Top-Middle"] = UDim2.new(0.5, 0, 0, 20),
    ["Bottom-Middle"] = UDim2.new(0.5, 0, 1, -20),
}
local NotificationPadding = 10
local NotificationWidth = 350
local MaxNotifications = 5
local NotificationQueue = {}

-- Create Notification Frame
local function CreateNotification(title, message, duration, pinned, multiline)
    local container = Instance.new("Frame")
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    container.Size = UDim2.new(0, NotificationWidth, 0, 0)
    container.AnchorPoint = Vector2.new(1, 0)
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.Name = "Notification"
    container.BackgroundTransparency = 0
    container.Parent = gui

    local corner = Instance.new("UICorner", container)
    corner.CornerRadius = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 4)
    layout.Parent = container

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = title
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 24)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Text = message
    messageLabel.TextSize = 15
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, -20, 0, multiline and 60 or 20)
    messageLabel.TextWrapped = multiline
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Position = UDim2.new(0, 10, 0, 0)
    messageLabel.Parent = container

    -- Add close button if pinned
    if pinned then
        local closeButton = Instance.new("TextButton")
        closeButton.Text = "X"
        closeButton.Size = UDim2.new(0, 24, 0, 24)
        closeButton.Position = UDim2.new(1, -28, 0, 4)
        closeButton.AnchorPoint = Vector2.new(1, 0)
        closeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.Font = Enum.Font.GothamBold
        closeButton.TextSize = 14
        closeButton.Parent = container
        closeButton.MouseButton1Click:Connect(function()
            DismissNotification(container)
        end)
    end

    return container
end

-- Dismiss Logic
function DismissNotification(frame)
    local tween = TweenService:Create(frame, TweenInfo.new(0.25), {BackgroundTransparency = 1})
    tween:Play()
    tween.Completed:Wait()
    frame:Destroy()
end

-- Layout Update
local function UpdateLayout()
    local active = gui:GetChildren()
    local yOffset = 0
    for _, child in ipairs(active) do
        if child:IsA("Frame") and child.Name == "Notification" then
            child.Position = UDim2.new(1, -NotificationWidth - 20, 0, 20 + yOffset)
            yOffset += child.AbsoluteSize.Y + NotificationPadding
        end
    end
end

-- Main Notify Method
function NotificationModule.Notify(title, message, duration, pinned, multiline)
    local notification = CreateNotification(title, message, duration, pinned, multiline)

    -- Queue system
    table.insert(NotificationQueue, notification)
    if #NotificationQueue > MaxNotifications then
        local oldest = table.remove(NotificationQueue, 1)
        DismissNotification(oldest)
    end

    UpdateLayout()

    -- Auto-dismiss
    if not pinned then
        task.delay(duration, function()
            if notification and notification.Parent then
                DismissNotification(notification)
            end
        end)
    end
end

return NotificationModule