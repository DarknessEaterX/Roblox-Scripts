-- ModuleScript (NotificationModule)
local Notification = {}

function Notification.new(settings)
	local player = game.Players.LocalPlayer
	local gui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CustomNotification"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = gui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 150)
	frame.Position = UDim2.new(0.5, -150, 0.3, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Parent = screenGui

	local uicorner = Instance.new("UICorner", frame)
	uicorner.CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.Text = settings.Title or "Notification"
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(1, -20, 0, 50)
	content.Position = UDim2.new(0, 10, 0, 45)
	content.Text = settings.Content or "Content goes here."
	content.TextSize = 16
	content.Font = Enum.Font.Gotham
	content.TextColor3 = Color3.new(1, 1, 1)
	content.BackgroundTransparency = 1
	content.TextWrapped = true
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.Parent = frame

	-- Buttons
	local buttonFrame = Instance.new("Frame")
	buttonFrame.Size = UDim2.new(1, -20, 0, 30)
	buttonFrame.Position = UDim2.new(0, 10, 1, -40)
	buttonFrame.BackgroundTransparency = 1
	buttonFrame.Parent = frame

	local buttonCount = #settings.Buttons or 0
	local buttonWidth = 100

	for i, button in ipairs(settings.Buttons or {}) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, buttonWidth, 1, 0)
		btn.Position = UDim2.new(0, (i - 1) * (buttonWidth + 10), 0, 0)
		btn.Text = button.Title or "Button"
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Parent = buttonFrame

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		btn.MouseButton1Click:Connect(function()
			if button.Callback then
				pcall(button.Callback)
			end
			if button.ClosesUI then
				screenGui:Destroy()
			end
		end)
	end

	if settings.AutoDismiss then
		task.delay(settings.AutoDismiss, function()
			if screenGui and screenGui.Parent then
				screenGui:Destroy()
			end
		end)
	end

	return screenGui
end

return Notification