-- ModuleScript: Notif
local Notif = {}

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local Icons = {
	["Warning"] = "⚠︎",
	["Error"] = "⊘",
	["Info"] = "ⓘ",
	["Success"] = "✔"
}

local Colors = {
	["Warning"] = Color3.fromRGB(255, 191, 0),
	["Error"] = Color3.fromRGB(255, 77, 77),
	["Info"] = Color3.fromRGB(0, 162, 232),
	["Success"] = Color3.fromRGB(0, 200, 83)
}

function Notif:Send(type, message, duration)
	local screenGui = Instance.new("ScreenGui")
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Name = "DragnirNotif"
	screenGui.Parent = CoreGui

	local screenSize = Workspace.CurrentCamera.ViewportSize
	local frameWidth = math.clamp(screenSize.X * 0.4, 240, 400)
	local frameHeight = 50
	local padding = 20

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
	notifFrame.Position = UDim2.new(0, screenSize.X, 0, padding)
	notifFrame.BackgroundColor3 = Colors[type] or Color3.fromRGB(50, 50, 50)
	notifFrame.BackgroundTransparency = 0
	notifFrame.BorderSizePixel = 0
	notifFrame.ClipsDescendants = true
	notifFrame.AnchorPoint = Vector2.new(1, 0)
 notifFrame.BackgroundTransparency = 0.9
	notifFrame.Parent = screenGui

	local uiCorner = Instance.new("UICorner", notifFrame)
	uiCorner.CornerRadius = UDim.new(0, 8)

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 40, 1, 0)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.Text = Icons[type] or "?"
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 24
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.BackgroundTransparency = 1
	icon.Parent = notifFrame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, -50, 1, 0)
	text.Position = UDim2.new(0, 45, 0, 0)
	text.Text = message or "Notification"
	text.Font = Enum.Font.Gotham
	text.TextSize = 16
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.BackgroundTransparency = 1
	text.Parent = notifFrame

	local targetPos = UDim2.new(0, screenSize.X - padding, 0, padding)

	local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = targetPos
	})
	tweenIn:Play()

	task.delay(duration or 3, function()
		local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(0, screenSize.X, 0, padding)
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		screenGui:Destroy()
	end)
end

return Notif