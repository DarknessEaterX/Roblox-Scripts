return (function()
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "Notification"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui
    
    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Parent = gui
    container.Size = UDim2.new(0, 380, 1, -40)
    container.AnchorPoint = Vector2.new(1, 0)
    container.Position = UDim2.new(1, -20, 0, 20)
    container.BackgroundTransparency = 1
    
    local activeNotifications = {}
    
    local function Notification(title, description, duration, soundId)
        duration = duration or 5
        local spacing = 6
        local notifHeight = 60
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 380, 0, notifHeight)
        
        -- Calculate vertical offset based on number of active notifications
        local yOffset = #activeNotifications * (notifHeight + spacing)
        
        -- Position off-screen to the right, stacked vertically without overlap
        notif.Position = UDim2.new(1, 40, 0, yOffset)
        
        notif.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        notif.BackgroundTransparency = 1
        notif.BorderSizePixel = 0
        notif.ClipsDescendants = true
        notif.Parent = container
        
        table.insert(activeNotifications, notif)
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = notif
        titleLabel.Text = title
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 16
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, -20, 0, 20)
        titleLabel.Position = UDim2.new(0, 10, 0, 6)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Parent = notif
        descLabel.Text = description
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 14
        descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        descLabel.BackgroundTransparency = 1
        descLabel.Size = UDim2.new(1, -20, 0, 20)
        descLabel.Position = UDim2.new(0, 10, 0, 28)
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        
        local bar = Instance.new("Frame")
        bar.Parent = notif
        bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        bar.BorderSizePixel = 0
        bar.Size = UDim2.new(1, 0, 0, 2)
        bar.Position = UDim2.new(0, 0, 1, -2)
        
        local barCorner = Instance.new("UICorner", bar)
        barCorner.CornerRadius = UDim.new(1, 0)
        
        if soundId then
            local sound = Instance.new("Sound")
            sound.Parent = notif
            sound.SoundId = "rbxassetid://" .. tostring(soundId)
            sound.Volume = 1
            sound:Play()
        end
        
        local tweenIn = TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, yOffset),
            BackgroundTransparency = 0.3
        })
        tweenIn:Play()
        
        local shrinkBar = TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 0, 2)
        })
        shrinkBar:Play()
        
        task.delay(duration, function()
            local tweenOut = TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 40, 0, notif.Position.Y.Offset)
            })
            tweenOut:Play()
            tweenOut.Completed:Wait()
            
            -- Remove notification from activeNotifications
            for i, n in ipairs(activeNotifications) do
                if n == notif then
                    table.remove(activeNotifications, i)
                    break
                end
            end
            
            notif:Destroy()
            
            -- Re-stack remaining notifications smoothly
            for i, n in ipairs(activeNotifications) do
                local targetY = (i - 1) * (notifHeight + spacing)
                TweenService:Create(n, TweenInfo.new(0.25), {
                    Position = UDim2.new(0, 0, 0, targetY)
                }):Play()
            end
        end)
    end
    
    return Notification
end)()