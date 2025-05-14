-- Notification2.lua
-- Roblox Studio-Style Code Editor UI with Syntax Highlighting
-- Fully Color3-based. Always centered. Robust.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Editor = {}

-- === COLOR THEME (ALL Color3 VALUES, NO HEX) ===
Editor.ColorTheme = {
    Background        = Color3.fromRGB(24, 24, 32),
    CodeBoxBackground = Color3.fromRGB(36, 36, 50),
    CodeBoxText       = Color3.fromRGB(240, 240, 255),
    TopBar            = Color3.fromRGB(32, 32, 48),
    Title             = Color3.fromRGB(240, 240, 255),
    CloseButton       = Color3.fromRGB(200, 80, 80),
    Shadow            = Color3.fromRGB(0,0,0),
    -- Syntax highlights (all Color3)
    Keyword    = Color3.fromRGB(71, 177, 255),
    Function   = Color3.fromRGB(0, 207, 255),
    Class      = Color3.fromRGB(255, 179, 71),
    Enum       = Color3.fromRGB(168, 130, 255),
    String     = Color3.fromRGB(141, 247, 141),
    Number     = Color3.fromRGB(255, 102, 102),
    Boolean    = Color3.fromRGB(255, 127, 156),
    Comment    = Color3.fromRGB(136, 136, 136),
    Identifier = Color3.fromRGB(255,255,255),
}

-- === SYNTAX HIGHLIGHTING TABLES ===
local LUA_KEYWORDS = { ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,["end"]=true,["false"]=true,["for"]=true,["function"]=true,["goto"]=true,["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,["while"]=true }
local ROBLOX_CLASSES = { ["Instance"]=true,["Part"]=true,["Model"]=true,["Folder"]=true,["Player"]=true,["Humanoid"]=true,["Camera"]=true,["Workspace"]=true,["GuiObject"]=true,["TweenService"]=true,["RunService"]=true,["ReplicatedStorage"]=true }
local ROBLOX_ENUMS = { ["Enum"]=true,["Enum.Material"]=true,["Enum.KeyCode"]=true,["Enum.UserInputType"]=true,["Enum.Font"]=true,["Enum.ClassName"]=true,["Enum.SurfaceType"]=true }
local LUA_FUNCTIONS = { ["print"]=true,["wait"]=true,["pairs"]=true,["ipairs"]=true,["next"]=true,["tonumber"]=true,["tostring"]=true,["typeof"]=true,["type"]=true,["select"]=true,["pcall"]=true,["spawn"]=true,["delay"]=true,["require"]=true,["setmetatable"]=true,["getmetatable"]=true,["table.insert"]=true,["table.remove"]=true,["math.random"]=true,["math.floor"]=true,["math.ceil"]=true,["math.sin"]=true,["math.cos"]=true }

-- Patterns for tokens (ordered)
local Patterns = {
    -- Comments
    { pattern = "%-%-%[%[.-%]%]", color = "Comment", italic = true }, -- Multiline
    { pattern = "%-%-.*",         color = "Comment", italic = true },
    -- Strings
    { pattern = "%[%[.-%]%]",     color = "String" },
    { pattern = [["(.-)"]],       color = "String" },
    { pattern = [[\'(.-)\']],     color = "String" },
    -- Numbers (avoid matching inside identifiers)
    { pattern = "([^%w_%.])([%-%d%.]+)", color = "Number", isNumber = true },
}

-- === Color3 to HEX (for RichText tags) ===
local function color3ToHex(color)
    local r = math.floor(color.r * 255)
    local g = math.floor(color.g * 255)
    local b = math.floor(color.b * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- === RichText Escaping ===
local function escapeRichText(str)
    str = string.gsub(str, "&", "&amp;")
    str = string.gsub(str, "<", "&lt;")
    str = string.gsub(str, ">", "&gt;")
    return str
end

-- === SYNTAX HIGHLIGHTER ===
function Editor.SyntaxHighlight(src)
    -- Stage 1: Comments, Strings, and Numbers
    local tokens = {}
    local s = src
    for _, patt in ipairs(Patterns) do
        local searchStart = 1
        while true do
            local s1, e1 = string.find(s, patt.pattern, searchStart)
            if not s1 then break end
            table.insert(tokens, {
                start = s1, finish = e1, color = patt.color, italic = patt.italic
            })
            -- Mask with spaces to avoid double-highlighting
            local mask = string.rep(" ", e1 - s1 + 1)
            s = s:sub(1, s1-1) .. mask .. s:sub(e1+1)
            searchStart = e1 + 1
        end
    end
    -- Stage 2: Tokenize identifiers (keywords, classes, enums, functions, booleans)
    for w, start in string.gmatch(s, "()([%a_][%w_%.]*)") do
        local color
        if LUA_KEYWORDS[w] then
            color = "Keyword"
        elseif ROBLOX_CLASSES[w] then
            color = "Class"
        elseif ROBLOX_ENUMS[w] then
            color = "Enum"
        elseif LUA_FUNCTIONS[w] then
            color = "Function"
        elseif w == "true" or w == "false" or w == "nil" then
            color = "Boolean"
        end
        if color then
            table.insert(tokens, { start = start, finish = start + #w - 1, color = color })
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
        local colorHex = color3ToHex(Editor.ColorTheme[tok.color] or Editor.ColorTheme.Identifier)
        local open = ('<font color="%s">%s'):format(colorHex, tok.italic and '<i>' or '')
        local close = (tok.italic and '</i>' or '') .. '</font>'
        table.insert(out, open .. chunk .. close)
        idx = tok.finish + 1
    end
    if idx <= #src then
        table.insert(out, escapeRichText(src:sub(idx)))
    end
    return table.concat(out)
end

-- === Drag Utility (robust, mouse/touch) ===
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos
    local lastInputConn, lastEndConn
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            if lastInputConn then lastInputConn:Disconnect() end
            lastInputConn = UserInputService.InputChanged:Connect(function(moveInput)
                if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
                    local delta = moveInput.Position - dragStart
                    frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
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

-- === Center Utility (responsive to viewport changes) ===
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
    frame.Destroying:Connect(function()
        if resizeConn then resizeConn:Disconnect() end
    end)
end

-- === No stacking: destroy previous editors ===
local function destroyExistingEditor(parent)
    for _, gui in ipairs(parent:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name == "CodeEditorGui" then
            gui:Destroy()
        end
    end
end

-- === MAIN CREATION FUNCTION ===
function Editor.Create(parent)
    parent = parent or (Players.LocalPlayer and Players.LocalPlayer.PlayerGui)
    assert(parent, "No valid parent for editor UI!")
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

    -- Make draggable (mouse & touch)
    makeDraggable(body, topbar)
    makeDraggable(shadow, topbar)

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