local NotifUI = Instance.new("ScreenGui")
local Holder = Instance.new("ScrollingFrame")
local Sorter = Instance.new("UIListLayout")

-- UI Setup
NotifUI.Name = "NotifUI"
NotifUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
NotifUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Holder.Name = "Holder"
Holder.Parent = NotifUI
Holder.Active = true
Holder.AnchorPoint = Vector2.new(1, 0)
Holder.BackgroundTransparency = 1
Holder.BorderSizePixel = 0
Holder.Position = UDim2.new(1, 0, 0, 0)
Holder.Size = UDim2.new(0.25, 0, 1, 0)
Holder.CanvasSize = UDim2.new(0, 0, 0, 0)

Sorter.Name = "Sorter"
Sorter.Parent = Holder
Sorter.HorizontalAlignment = Enum.HorizontalAlignment.Center
Sorter.SortOrder = Enum.SortOrder.LayoutOrder
Sorter.VerticalAlignment = Enum.VerticalAlignment.Bottom
Sorter.Padding = UDim.new(0, 10)

-- Merges default values
local function MergeDefaults(custom, defaults)
	custom = custom or {}
	local result = {}
	for key, val in pairs(defaults) do
		result[key] = custom[key] ~= nil and custom[key] or val
	end
	return result
end

-- Notification Creator
local function CreateNotification(options)
	local defaults = {
		Buttons = {
			[1] = {
				Title = 'Dismiss',
				ClosesUI = true,
				Callback = function() end
			}
		},
		Title = 'Notification Title',
		Content = 'Placeholder notification content',
		Length = 5,
		NeverExpire = false
	}
	options = MergeDefaults(options, defaults)

	local Dismiss = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local TitleLabel = Instance.new("TextLabel")
	local ContentLabel = Instance.new("TextLabel")
	local ActionButton = Instance.new("TextButton")
	local ButtonCorner = Instance.new("UICorner")

	Dismiss.Name = "Notification"
	Dismiss.Parent = Holder
	Dismiss.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Dismiss.BackgroundTransparency = 0.3
	Dismiss.Size = UDim2.new(0, 262, 0, 132)
	Dismiss.Visible = false

	UICorner.Parent = Dismiss

	TitleLabel.Parent = Dismiss
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0.057, 0, 0.05, 0)
	TitleLabel.Size = UDim2.new(0, 194, 0, 29)
	TitleLabel.Font = Enum.Font.GothamMedium
	TitleLabel.Text = options.Title
	TitleLabel.TextColor3 = Color3.new(1, 1, 1)
	TitleLabel.TextSize = 16
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

	ContentLabel.Parent = Dismiss
	ContentLabel.BackgroundTransparency = 1
	ContentLabel.Position = UDim2.new(0.057, 0, 0.30, 0)
	ContentLabel.Size = UDim2.new(0, 233, 0, 52)
	ContentLabel.Font = Enum.Font.Gotham
	ContentLabel.Text = options.Content
	ContentLabel.TextColor3 = Color3.fromRGB(234, 234, 234)
	ContentLabel.TextSize = 14
	ContentLabel.TextWrapped = true
	ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
	ContentLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Button Handling
	if options.Buttons[1] then
		ActionButton.Parent = Dismiss
		ActionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ActionButton.Position = UDim2.new(0.057, 0, 0.697, 0)
		ActionButton.Size = UDim2.new(0, 233, 0, 29)
		ActionButton.Font = Enum.Font.GothamMedium
		ActionButton.Text = options.Buttons[1].Title
		ActionButton.TextColor3 = Color3.new(0, 0, 0)
		ActionButton.TextSize = 16
		ButtonCorner.CornerRadius = UDim.new(0, 6)
		ButtonCorner.Parent = ActionButton

		ActionButton.MouseButton1Click:Connect(function()
			if typeof(options.Buttons[1].Callback) == "function" then
				task.spawn(options.Buttons[1].Callback)
			end
			if options.Buttons[1].ClosesUI then
				Dismiss:Destroy()
			end
		end)
	end

	Dismiss.Visible = true

	if not options.NeverExpire then
		task.delay(options.Length, function()
			if not Dismiss or not Dismiss.Parent then return end
			for _, v in pairs(Dismiss:GetDescendants()) do
				if v:IsA("TextLabel") or v:IsA("TextButton") then
					game.TweenService:Create(v, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
				elseif v:IsA("Frame") then
					game.TweenService:Create(v, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
				end
			end
			task.wait(0.4)
			Dismiss:Destroy()
		end)
	end
end

return CreateNotification

