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
local NotificationPadding = 10
local MaxNotifications = 5
local ActiveNotifications = {}

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
	container.BackgroundTransparency = 1
	container.Position = UDim2.new(1, NotificationWidth + 20, 0, 20) -- Start offscreen
	container.Parent = gui
	container.ZIndex = 10

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
		closeButton.ZIndex = 11
		closeButton.Parent = container
		closeButton.MouseButton1Click:Connect(function()
			NotificationModule._Dismiss(container)
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
	tween:Play()
	tween.Completed:Wait()
	frame:Destroy()
	NotificationModule._UpdateLayout()
end

-- Main API
function NotificationModule.Notify(title, message, duration, pinned, multiline)
	local notif = CreateNotification(title, message, duration, pinned, multiline)
	table.insert(ActiveNotifications, notif)

	-- Slide-in animation
	local targetPos = UDim2.new(1, -20, 0, 0)
	TweenService:Create(notif, TweenInfo.new(0.3), {
		Position = UDim2.new(1, -20, 0, 9999), -- temp
		BackgroundTransparency = 0
	}):Play()

	NotificationModule._UpdateLayout()

	-- Auto dismiss
	if not pinned then
		task.delay(duration, function()
			if notif and notif.Parent then
				NotificationModule._Dismiss(notif)
			end
		end)
	end
end

return NotificationModule