-- Notification2.lua
-- Roblox Studio-Style Code Editor with Full Lua Syntax Highlighting
-- Place in ReplicatedStorage or any ModuleScript location

local Players = game:GetService("Players")
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

-- Syntax patterns and lists
local LUA_KEYWORDS = {
	["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,["end"]=true,
	["false"]=true,["for"]=true,["function"]=true,["goto"]=true,["if"]=true,["in"]=true,
	["local"]=true,["nil"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,
	["then"]=true,["true"]=true,["until"]=true,["while"]=true,
}
local ROBLOX_CLASSES = {
	["Instance"]=true,["Part"]=true,["Model"]=true,["Folder"]=true,["Player"]=true,["Humanoid"]=true,
	["Camera"]=true,["Workspace"]=true,["GuiObject"]=true,["TweenService"]=true,["RunService"]=true,
	["ReplicatedStorage"]=true,
}
local ROBLOX_ENUMS = {
	["Enum"]=true,["Enum.Material"]=true,["Enum.KeyCode"]=true,["Enum.UserInputType"]=true,
	["Enum.Font"]=true,["Enum.ClassName"]=true,["Enum.SurfaceType"]=true,
}
local LUA_FUNCTIONS = {
	["print"]=true,["wait"]=true,["pairs"]=true,["ipairs"]=true,["next"]=true,["tonumber"]=true,["tostring"]=true,
	["typeof"]=true,["type"]=true,["select"]=true,["pcall"]=true,["spawn"]=true,["delay"]=true,["require"]=true,
	["setmetatable"]=true,["getmetatable"]=true,["table.insert"]=true,["table.remove"]=true,["math.random"]=true,
	["math.floor"]=true,["math.ceil"]=true,["math.sin"]=true,["math.cos"]=true,
}

-- Token patterns (ordered by priority)
local Patterns = {
	-- Comments
	{ pattern = "%-%-%[%[.-%]%]", color = Editor.ColorTheme.Comment, italic = true }, -- Multiline
	{ pattern = "%-%-.*",         color = Editor.ColorTheme.Comment, italic = true },
	-- Strings
	{ pattern = "%[%[.-%]%]",     color = Editor.ColorTheme.String },
	{ pattern = [["(.-)"]],       color = Editor.ColorTheme.String },
	{ pattern = [[\'(.-)\']],     color = Editor.ColorTheme.String },
	-- Numbers (avoid matching inside identifiers)
	{ pattern = "([^%w_%.])([%-%d%.]+)", color = Editor.ColorTheme.Number, isNumber = true },
}

-- Helper: escapes for font color tags
local function escapeRichText(str)
	str = string.gsub(str, "&", "&amp;")
	str = string.gsub(str, "<", "&lt;")
	str = string.gsub(str, ">", "&gt;")
	return str
end

-- Tokenizer and highlighter
function Editor.SyntaxHighlight(src)
	-- Stage 1: Comments, Strings, and Numbers
	local tokens = {}
	local lastEnd = 1
	local function addToken(startPos, endPos, color, italic, raw)
		table.insert(tokens, {
			start = startPos, finish = endPos, color = color, italic = italic, raw = raw
		})
	end

	local s = src
	for _, patt in ipairs(Patterns) do
		local searchStart = 1
		while true do
			local s1, e1, cap = string.find(s, patt.pattern, searchStart)
			if not s1 then break end
			addToken(s1, e1, patt.color, patt.italic, nil)
			-- Mask with spaces to avoid double-highlighting
			local mask = string.rep(" ", e1 - s1 + 1)
			s = s:sub(1, s1-1) .. mask .. s:sub(e1+1)
			searchStart = e1 + 1
		end
	end

	-- Stage 2: Tokenize identifiers (keywords, classes, enums, functions, booleans)
	for w, start in string.gmatch(s, "()([%a_][%w_%.]*)") do
		local color = nil
		local word = w
		if LUA_KEYWORDS[word] then
			color = Editor.ColorTheme.Keyword
		elseif ROBLOX_CLASSES[word] then
			color = Editor.ColorTheme.Class
		elseif ROBLOX_ENUMS[word] then
			color = Editor.ColorTheme.Enum
		elseif LUA_FUNCTIONS[word] then
			color = Editor.ColorTheme.Function
		elseif word == "true" or word == "false" or word == "nil" then
			color = Editor.ColorTheme.Boolean
		end
		if color then
			addToken(start, start + #word - 1, color, false, nil)
		end
	end

	-- Stage 3: Sort and re-assemble with font tags
	table.sort(tokens, function(a, b) return a.start < b.start end)
	local out, idx = {}, 1
	for _, tok in ipairs(tokens) do
		if idx < tok.start then
			table.insert(out, escapeRichText(src:sub(idx, tok.start-1)))
		end
		local chunk = escapeRichText(src:sub(tok.start, tok.finish))
		local open = ('<font color="%s">%s'):format(tok.color, tok.italic and '<i>' or '')
		local close = (tok.italic and '</i>' or '') .. '</font>'
		table.insert(out, open .. chunk .. close)
		idx = tok.finish + 1
	end
	if idx <= #src then
		table.insert(out, escapeRichText(src:sub(idx)))
	end
	return table.concat(out)
end

-- Draggable utility
local function makeDraggable(frame, dragHandle)
	local dragging, dragInput, startPos, startInput
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = frame.Position
			startInput = input.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			local delta = input.Position - startInput
			frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
		end
	end)
end

-- Main UI creation
function Editor.Create(parent)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CodeEditorGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = parent or Players.LocalPlayer.PlayerGui

	-- Drop Shadow
	local shadow = Instance.new("Frame")
	shadow.BackgroundColor3 = Editor.ColorTheme.Shadow
	shadow.BackgroundTransparency = 0.4
	shadow.Position = UDim2.new(0.5, -212, 0.5, -152)
	shadow.Size = UDim2.new(0, 424, 0, 304)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.ZIndex = 9
	shadow.Parent = screenGui

	-- Main Body
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundColor3 = Editor.ColorTheme.Background
	body.Position = UDim2.new(0.5, -200, 0.5, -140)
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

	-- Draggable
	makeDraggable(body, topbar)

	-- Close behavior
	close.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Live syntax highlighting
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

return Editor