-- Notification.lua
local Notification = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Create holder only once
local screenGui = PlayerGui:FindFirstChild("DragnirNotif") or Instance.new("ScreenGui")
screenGui.Name = "DragnirNotif"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = PlayerGui

local notificationHolder = screenGui:FindFirstChild("NotifHolder") or Instance.new("Frame")
notificationHolder.Name = "NotifHolder"
notificationHolder.AnchorPoint = Vector2.new(1, 0)
notificationHolder.Position = UDim2.new(1, -10, 0, 10)
notificationHolder.Size = UDim2.new(0, 320, 1, -20)
notificationHolder.BackgroundTransparency = 1
notificationHolder.BorderSizePixel = 0
notificationHolder.ClipsDescendants = false
notificationHolder.Parent = screenGui

local layout = notificationHolder:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Parent = notificationHolder

-- Function to create a notification
function Notification.new(settings)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 100)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.LayoutOrder = os.clock()
	frame.Parent = notificationHolder

	local uicorner = Instance.new("UICorner", frame)
	uicorner.CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Text = settings.Title or "Notification"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.Parent = frame

	local content = Instance.new("TextLabel")
	content.Text = settings.Content or "Content here"
	content.Font = Enum.Font.Gotham
	content.TextSize = 15
	content.TextColor3 = Color3.fromRGB(200, 200, 200)
	content.BackgroundTransparency = 1
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.TextWrapped = true
	content.Size = UDim2.new(1, -20, 0, 40)
	content.Position = UDim2.new(0, 10, 0, 35)
	content.Parent = frame

	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, -20, 0, 25)
	buttonFrame.Position = UDim2.new(0, 10, 1, -35)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = frame

	local buttons = settings.Buttons or {}
	local btnWidth = (#buttons == 2 and 135) or 280
	local spacing = 10

	for i, button in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, btnWidth, 1, 0)
		btn.Position = UDim2.new(0, (i - 1) * (btnWidth + spacing), 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.Text = button.Title or "Button"
		btn.AutoButtonColor = true
		btn.Parent = buttonFrame

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		btn.MouseButton1Click:Connect(function()
			if button.Callback then
				pcall(button.Callback)
			end
			if button.ClosesUI then
				frame:Destroy()
			end
		end)
	end

	-- Slide in from the right
	local startPos = UDim2.new(1, 320, 0, 10 + (#notificationHolder:GetChildren() - 1) * 108)
	local targetPos = UDim2.new(0, 0, 0, 0)
	frame.Position = UDim2.new(1, 320, 0, 0)
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
	tweenIn:Play()

	-- Auto dismiss if specified
	if settings.AutoDismiss then
		task.delay(settings.AutoDismiss, function()
			if frame and frame.Parent then
				local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = UDim2.new(1, 320, 0, frame.Position.Y.Offset)
				})
				tweenOut:Play()
				tweenOut.Completed:Wait()
				frame:Destroy()
			end
		end)
	end

	return frame
end

return Notification