local NotificationModule = {}

-- Create a function to initialize notifications
function NotificationModule.init(playerGui)
    -- Remove old GUI if exists
    local oldGui = playerGui:FindFirstChild("NotificationGui")
    if oldGui then oldGui:Destroy() end

    -- Create main GUI
    local notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "NotificationGui"
    notificationGui.IgnoreGuiInset = true
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.Parent = playerGui

    -- Create container for notifications
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = UDim2.new(0, 300, 1, -20)
    container.Position = UDim2.new(1, -310, 0, 10)
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = notificationGui

    -- Function to reorder notifications
    local function reorder()
        local children = {}
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                table.insert(children, child)
            end
        end
        table.sort(children, function(a, b)
            return a:GetAttribute("TimeStamp") > b:GetAttribute("TimeStamp")
        end)
        for i, child in ipairs(children) do
            child.Position = UDim2.new(0, 0, 0, (i - 1) * 36)
        end
    end

    -- Function to show single-line notification
    function NotificationModule.showNotification(message: string, duration: number?)
        duration = duration or 3

        local notif = Instance.new("TextLabel")
        notif.Name = "Notification"
        notif.Size = UDim2.new(1, 0, 0, 30)
        notif.Position = UDim2.new(0, 0, 0, 0)
        notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notif.BackgroundTransparency = 0.5
        notif.TextColor3 = Color3.new(1, 1, 1)
        notif.Font = Enum.Font.GothamSemibold
        notif.TextSize = 14
        notif.TextXAlignment = Enum.TextXAlignment.Left
        notif.Text = message
        notif.ZIndex = 10
        notif.Parent = container
        notif:SetAttribute("TimeStamp", tick())

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.Parent = notif

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = notif

        reorder()

        task.delay(duration, function()
            if notif and notif.Parent then
                notif:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quad", 0.25, true)
                task.wait(0.25)
                notif:Destroy()
                reorder()
            end
        end)
    end

    -- Function to show multi-line (paragraph) notification
    function NotificationModule.paragraphNotification(message: string, duration: number?)
    duration = duration or 5

    local notif = Instance.new("TextLabel")
    notif.Name = "ParagraphNotification"
    notif.AnchorPoint = Vector2.new(1, 0)
    notif.Position = UDim2.new(1, -10, 0, 0)
    notif.Size = UDim2.new(0, 320, 0, 0) -- Fixed width, auto-height
    notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notif.BackgroundTransparency = 0.5
    notif.TextColor3 = Color3.new(1, 1, 1)
    notif.Font = Enum.Font.GothamSemibold
    notif.TextSize = 14
    notif.TextWrapped = true
    notif.TextYAlignment = Enum.TextYAlignment.Top
    notif.TextXAlignment = Enum.TextXAlignment.Left
    notif.AutomaticSize = Enum.AutomaticSize.Y -- Only Y-axis auto-size
    notif.ClipsDescendants = true
    notif.ZIndex = 10
    notif.Text = message
    notif.Parent = container
    notif:SetAttribute("TimeStamp", tick())

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = notif

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notif

    reorder()

    task.delay(duration, function()
        if notif and notif.Parent then
            notif:TweenSize(UDim2.new(0, 320, 0, 0), "Out", "Quad", 0.25, true)
            task.wait(0.25)
            notif:Destroy()
            reorder()
        end
    end)
   end
end

return NotificationModule
