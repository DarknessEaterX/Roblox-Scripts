local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if game:GetService("Players").LocalPlayer.PlayerGui["RayfieldNotifications"] then

game:GetService("Players").LocalPlayer.PlayerGui["RayfieldNotifications"]:Destroy()
end

local NotificationLibrary = {}

-- Create ScreenGui once
local Gui = Instance.new("ScreenGui")
Gui.Name = "RayfieldNotifications"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

-- Container for notifications
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(0.3, 0, 1, 0)
Container.Position = UDim2.new(0.7, 0, 0, 0)
Container.BackgroundTransparency = 1
Container.ClipsDescendants = false
Container.Parent = Gui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Parent = Container

function NotificationLibrary:Notify(opts)
	-- opts is a table: {Title = "", Content = "", Duration = number (optional)}

	local title = opts.Title or "Notification"
	local content = opts.Content or ""
	local duration = opts.Duration or 4.5

	local Notification = Instance.new("Frame")
	Notification.Name = "Notification"
	Notification.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Notification.BackgroundTransparency = 0
	Notification.Size = UDim2.new(1, -10, 0, 75)
	Notification.Position = UDim2.new(1.2, 0, 1, 0)
	Notification.AnchorPoint = Vector2.new(1, 1)
	Notification.BorderSizePixel = 0
	Notification.ClipsDescendants = true
	Notification.AutomaticSize = Enum.AutomaticSize.Y
	Notification.Parent = Container

	local UICorner = Instance.new("UICorner", Notification)
	UICorner.CornerRadius = UDim.new(0, 8)

	local Stroke = Instance.new("UIStroke", Notification)
	Stroke.Thickness = 1
	Stroke.Transparency = 0.8
	Stroke.Color = Color3.fromRGB(100, 100, 100)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Parent = Notification
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(1, -20, 0, 20)
	TitleLabel.Position = UDim2.new(0, 10, 0, 10)
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Font = Enum.Font.GothamMedium
	TitleLabel.TextSize = 16
	TitleLabel.Text = title

	local BodyLabel = Instance.new("TextLabel")
	BodyLabel.Name = "Body"
	BodyLabel.Parent = Notification
	BodyLabel.BackgroundTransparency = 1
	BodyLabel.Size = UDim2.new(1, -20, 0, 40)
	BodyLabel.Position = UDim2.new(0, 10, 0, 30)
	BodyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	BodyLabel.TextWrapped = true
	BodyLabel.TextYAlignment = Enum.TextYAlignment.Top
	BodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	BodyLabel.Font = Enum.Font.Gotham
	BodyLabel.TextSize = 14
	BodyLabel.Text = content

	-- Blur Effect
	local blur
	if not getgenv().SecureMode then
		blur = Instance.new("BlurEffect")
		blur.Size = 12
		blur.Name = "RayfieldBlur"
		blur.Parent = Lighting
	end

	-- Animate In
	Notification.BackgroundTransparency = 1
	Stroke.Transparency = 1
	TitleLabel.TextTransparency = 1
	BodyLabel.TextTransparency = 1

	local tweenInPos = TweenService:Create(Notification, TweenInfo.new(0.3), {Position = UDim2.new(1, 0, 1, 0)})
	local tweenInBG = TweenService:Create(Notification, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	local tweenInStroke = TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0.5})
	local tweenInTitle = TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 0})
	local tweenInBody = TweenService:Create(BodyLabel, TweenInfo.new(0.3), {TextTransparency = 0.1})

	tweenInPos:Play()
	tweenInBG:Play()
	tweenInStroke:Play()
	tweenInTitle:Play()
	tweenInBody:Play()

	-- Animate Out after duration
	task.delay(duration, function()
		local tweenOutBG = TweenService:Create(Notification, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		local tweenOutStroke = TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 1})
		local tweenOutTitle = TweenService:Create(TitleLabel, TweenInfo.new(0.3), {TextTransparency = 1})
		local tweenOutBody = TweenService:Create(BodyLabel, TweenInfo.new(0.3), {TextTransparency = 1})
		local tweenOutPos = TweenService:Create(Notification, TweenInfo.new(0.3), {Position = UDim2.new(1.2, 0, 1, 0)})

		tweenOutBG:Play()
		tweenOutStroke:Play()
		tweenOutTitle:Play()
		tweenOutBody:Play()
		tweenOutPos:Play()

		tweenOutPos.Completed:Wait()

		if blur then blur:Destroy() end
		Notification:Destroy()
	end)
end

return NotificationLibrary