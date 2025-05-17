local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local NotifUI = Instance.new("ScreenGui")
NotifUI.Name = "NotifUI"
NotifUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
NotifUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Holder = Instance.new("ScrollingFrame")
Holder.Name = "Holder"
Holder.Parent = NotifUI
Holder.Active = true
Holder.AnchorPoint = Vector2.new(1, 0)
Holder.BackgroundTransparency = 1
Holder.Position = UDim2.new(1, -10, 0, 10)
Holder.Size = UDim2.new(0.25, 0, 1, -20)
Holder.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder.ScrollBarThickness = 4

local Sorter = Instance.new("UIListLayout")
Sorter.Parent = Holder
Sorter.HorizontalAlignment = Enum.HorizontalAlignment.Center
Sorter.VerticalAlignment = Enum.VerticalAlignment.Bottom
Sorter.SortOrder = Enum.SortOrder.LayoutOrder
Sorter.Padding = UDim.new(0, 10)

-- Utility
local function SetDefaults(userOptions, defaults)
	for k, v in pairs(defaults) do
		if userOptions[k] == nil then
			userOptions[k] = v
		end
	end
	return userOptions
end

-- Create Notification
local function CreateNotification(Options)
	Options = SetDefaults(Options, {
		Title = "Notification",
		Content = "No content provided.",
		Length = 5,
		NeverExpire = false,
		Buttons = {
			{ Title = "Dismiss", ClosesUI = true, Callback = function() end }
		}
	})

	local Notification = Instance.new("Frame")
	Notification.Parent = Holder
	Notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Notification.BackgroundTransparency = 0.1
	Notification.Size = UDim2.new(1, -20, 0, 150)

	local Corner = Instance.new("UICorner", Notification)
	Corner.CornerRadius = UDim.new(0, 8)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Parent = Notification
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	TitleLabel.Size = UDim2.new(0.9, 0, 0, 25)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = Options.Title
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextSize = 18
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local ContentLabel = Instance.new("TextLabel")
	ContentLabel.Parent = Notification
	ContentLabel.BackgroundTransparency = 1
	ContentLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
	ContentLabel.Size = UDim2.new(0.9, 0, 0, 60)
	ContentLabel.Font = Enum.Font.Gotham
	ContentLabel.Text = Options.Content
	ContentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	ContentLabel.TextSize = 14
	ContentLabel.TextWrapped = true
	ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
	ContentLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Buttons
	local buttonY = 0.75
	for _, btn in pairs(Options.Buttons) do
		local Btn = Instance.new("TextButton")
		Btn.Parent = Notification
		Btn.Position = UDim2.new(0.05, 0, buttonY, 0)
		Btn.Size = UDim2.new(0.9, 0, 0, 25)
		Btn.Text = btn.Title or "OK"
		Btn.Font = Enum.Font.GothamMedium
		Btn.TextSize = 14
		Btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		local BtnCorner = Instance.new("UICorner", Btn)
		BtnCorner.CornerRadius = UDim.new(0, 6)

		Btn.MouseButton1Click:Connect(function()
			task.spawn(btn.Callback or function() end)
			if btn.ClosesUI then
				Notification:Destroy()
			end
		end)

		buttonY += 0.15
	end

	Notification.Visible = true

	-- Auto destroy
	if not Options.NeverExpire then
		task.delay(Options.Length, function()
			if Notification and Notification.Parent then
				for _, obj in pairs(Notification:GetDescendants()) do
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then
						TweenService:Create(obj, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
					elseif obj:IsA("Frame") then
						TweenService:Create(obj, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
					end
				end
				task.wait(0.35)
				Notification:Destroy()
			end
		end)
	end
end

return CreateNotification