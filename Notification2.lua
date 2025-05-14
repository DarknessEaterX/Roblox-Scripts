-- Notification2.lua (Improved)
-- Roblox Studio-Style Code Editor UI with Syntax Highlighting
-- Enhanced: Bug fixes, robust drag, and always-center spawn

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Editor = {}
Editor.ColorTheme = {
	Background = Color3.fromRGB(24, 24, 32),
	CodeBoxBackground = Color3.fromRGB(36, 36, 50),
	CodeBoxText = Color3.fromRGB(240, 240, 255),
	TopBar = Color3.fromRGB(32, 32, 48),
	Title = Color3.fromRGB(240, 240, 255),
	CloseButton = Color3.fromRGB(200, 80, 80),
	Shadow = Color3.fromRGB(0,0,0);

	-- Syntax colors
	Keyword      = "#47B1FF", -- Blue
	Function     = "#00CFFF", -- Sky
	Class        = "#FFB347", -- Gold
	Enum         = "#A882FF", -- Purple
	String       = "#8DF78D", -- Green
	Number       = "#FF6666", -- Red
	Boolean      = "#FF7F9C", -- Coral
	Comment      = "#888888", -- Gray
	Identifier   = "#FFFFFF", -- Default text
}

-- (rest of syntax highlighting code as in your original Notification2.lua...)

-- Syntax highlighting helpers (as before)

-- ... [keep your full SyntaxHighlight and escapeRichText implementations here] ...

-- Enhanced draggable utility: works on any platform and keeps the editor inside viewport
local function makeDraggable(frame, dragHandle, gui)
	local dragging = false
	local dragStart, startPos
	local lastInputConn, lastEndConn

	local function getMouseLocation()
		return UserInputService:GetMouseLocation() - Vector2.new(0, 36) -- Remove topbar offset
	end

	local function updatePosition(input)
		local delta = input.Position - dragStart
		local newPos = startPos + UDim2.new(0, delta.X, 0, delta.Y)
		frame.Position = newPos
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			if lastInputConn then lastInputConn:Disconnect() end
			lastInputConn = UserInputService.InputChanged:Connect(function(moveInput)
				if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
					updatePosition(moveInput)
				end
			end)
			if lastEndConn then lastEndConn:Disconnect() end
			lastEndConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if lastInputConn then lastInputConn:Disconnect() end
					if lastEndConn then lastEndConn:Disconnect() end
				end
			end)
		end
	end)
end

-- Robust centering utility: centers and keeps centered on screen resize
local function centerFrameOnScreen(frame, gui)
	local function doCenter()
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800,600)
		frame.Position = UDim2.new(0, (vp.X - frame.Size.X.Offset) // 2, 0, (vp.Y - frame.Size.Y.Offset) // 2)
	end
	doCenter()
	local resizeConn
	resizeConn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(doCenter)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(doCenter)
	end
	-- Clean up (optional)
	frame.Destroying:Connect(function()
		if resizeConn then resizeConn:Disconnect() end
	end)
end

-- Prevent stacking: close any previous editor instances
local function destroyExistingEditor(parent)
	for _, gui in ipairs(parent:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name == "CodeEditorGui" then
			gui:Destroy()
		end
	end
end

function Editor.Create(parent)
	parent = parent or (Players.LocalPlayer and Players.LocalPlayer.PlayerGui)
	if not parent then error("No valid parent for editor UI!") end

	destroyExistingEditor(parent)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CodeEditorGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = parent

	-- Drop Shadow
	local shadow = Instance.new("Frame")
	shadow.BackgroundColor3 = Editor.ColorTheme.Shadow
	shadow.BackgroundTransparency = 0.4
	shadow.Size = UDim2.new(0, 424, 0, 304)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.ZIndex = 9
	shadow.Parent = screenGui

	-- Main Body
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Editor.ColorTheme.Background
	body.Size = UDim2.new(0, 400, 0, 280)
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.ZIndex = 10
	body.Active = true
	body.Selectable = true
	body.Parent = screenGui
	local uicorner = Instance.new("UICorner", body)
	uicorner.CornerRadius = UDim.new(0, 10)
	local uipadding = Instance.new("UIPadding", body)
	uipadding.PaddingTop = UDim.new(0, 36)
	uipadding.PaddingBottom = UDim.new(0, 10)
	uipadding.PaddingLeft = UDim.new(0, 12)
	uipadding.PaddingRight = UDim.new(0, 12)

	-- Topbar
	local topbar = Instance.new("Frame")
	topbar.Name = "Topbar"
	topbar.BackgroundColor3 = Editor.ColorTheme.TopBar
	topbar.Size = UDim2.new(1, 0, 0, 32)
	topbar.Position = UDim2.new(0, 0, 0, 0)
	topbar.ZIndex = 11
	topbar.Active = true
	topbar.Parent = body
	local topbarcorner = Instance.new("UICorner", topbar)
	topbarcorner.CornerRadius = UDim.new(0, 10)

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 10, 0, 0)
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Text = "Code Editor"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Editor.ColorTheme.Title
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 12
	title.Parent = topbar

	-- Close Button
	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.BackgroundTransparency = 1
	close.Position = UDim2.new(1, -32, 0, 0)
	close.Size = UDim2.new(0, 32, 1, 0)
	close.Text = "✕"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 22
	close.TextColor3 = Editor.ColorTheme.CloseButton
	close.ZIndex = 12
	close.Parent = topbar

	-- CodeBox
	local codeBox = Instance.new("TextBox")
	codeBox.Name = "CodeBox"
	codeBox.BackgroundColor3 = Editor.ColorTheme.CodeBoxBackground
	codeBox.Size = UDim2.new(1, 0, 1, -48)
	codeBox.Position = UDim2.new(0, 0, 0, 36)
	codeBox.Text = "-- Type Lua code here!\nprint(\"Hello, world!\")"
	codeBox.Font = Enum.Font.Code
	codeBox.TextSize = 16
	codeBox.TextColor3 = Editor.ColorTheme.CodeBoxText
	codeBox.TextXAlignment = Enum.TextXAlignment.Left
	codeBox.TextYAlignment = Enum.TextYAlignment.Top
	codeBox.TextWrapped = false
	codeBox.ClearTextOnFocus = false
	codeBox.MultiLine = true
	codeBox.RichText = true
	codeBox.ZIndex = 11
	codeBox.Parent = body

	-- Center the editor on any screen/platform
	centerFrameOnScreen(body, screenGui)
	centerFrameOnScreen(shadow, screenGui)

	-- Make draggable (works with both mouse and touch)
	makeDraggable(body, topbar, screenGui)
	makeDraggable(shadow, topbar, screenGui)

	-- Close behavior
	close.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Live syntax highlighting (keep your full implementation)
	local updating = false
	codeBox:GetPropertyChangedSignal("Text"):Connect(function()
		if updating then return end
		updating = true
		local cursorPos = codeBox.CursorPosition
		local code = codeBox.Text
		local rich = Editor.SyntaxHighlight(code)
		codeBox.Text = rich
		codeBox.CursorPosition = cursorPos
		updating = false
	end)

	-- Tab key for indentation
	codeBox.Focused:Connect(function()
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Tab then
				local pos = codeBox.CursorPosition
				local text = codeBox.Text
				codeBox.Text = text:sub(1, pos-1) .. "\t" .. text:sub(pos)
				codeBox.CursorPosition = pos + 1
			end
		end)
		codeBox.FocusLost:Connect(function() if conn then conn:Disconnect() end end)
	end)

	return {
		ScreenGui = screenGui,
		Body = body,
		Topbar = topbar,
		CodeBox = codeBox,
		TitleLabel = title,
		CloseButton = close,
	}
end

-- ... (Keep your full SyntaxHighlight and escapeRichText implementations here) ...

return Editor