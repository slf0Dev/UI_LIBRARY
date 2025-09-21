local TweenService = game:GetService("TweenService");
local Mouse = game.Players.LocalPlayer:GetMouse();
local PlayerGui = game.Players.LocalPlayer.PlayerGui;
local InputService = game:GetService("UserInputService");



local HasProperty = function(instance, property) -- Currently not so reliable. Tests if instance has a certain property
    local successful = pcall(function()
        return instance[property]
    end)
    return successful and not instance:FindFirstChild(property) -- Fails if instance DOES have a child named a property, will fix soon
end


function Create(instance : string,properties : table)
    local Corner,Stroke
    local CreatedInstance = Instance.new(instance)
    local StrokeProperties
    local Stroke
    if instance == "TextButton" or instance == "ImageButton" then
        CreatedInstance.AutoButtonColor = false
    end

    if HasProperty(CreatedInstance,"BorderSizePixel") then
        CreatedInstance.BorderSizePixel = 0
    end

    for property,value in next,properties do
        if tostring(property) ~= "CornerRadius" and tostring(property) ~= "Stroke" and tostring(property) ~= "BoxShadow" then
            CreatedInstance[property] = value
        elseif tostring(property) == "Stroke" then
            StrokeProperties = {
                Color = value['Color'],
                Thickness = value['Thickness'],
                Transparency = value['Transparency'] or 0
            }
            Stroke = Instance.new("UIStroke",CreatedInstance)
            Stroke.Name = "Stroke"
            Stroke.Color = value["Color"] or Color3.fromRGB(255,255,255)
            Stroke.Thickness = value["Thickness"] or 1
            Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            Stroke.Transparency = value["Transparency"] or 0
            Stroke.LineJoinMode = Enum.LineJoinMode.Round
            UI['Instances'][Stroke] = StrokeProperties

        elseif tostring(property) == "CornerRadius" then
            Corner = Instance.new("UICorner",CreatedInstance)
            Corner.Name = "Corner"
            Corner.CornerRadius = value
        elseif tostring(property) == "BoxShadow" then
            local BoxShadow = Instance.new("ImageLabel",CreatedInstance)
            BoxShadow.Size = UDim2.new(1,value['Size'][1],1,value['Size'][2])
            BoxShadow.AnchorPoint = Vector2.new(0.5,0.5)
            BoxShadow.Position = UDim2.new(0.5,value['Padding'][1],0.5,value['Padding'][2])
            BoxShadow.Image = "rbxassetid://1316045217"
            BoxShadow.BackgroundTransparency = 1
            BoxShadow.ImageTransparency = value['Transparency']
            BoxShadow.ScaleType = Enum.ScaleType.Slice
            BoxShadow.SliceCenter = Rect.new(10,10,118,118)
            BoxShadow.ImageColor3 = value['Color']
            BoxShadow.ZIndex = value['ZIndex'] or 1
            BoxShadow.Name = "Shadow"
            UI['Instances'][BoxShadow] = {ImageColor3 = value['Color']}
        end
    end
    UI['Instances'][CreatedInstance] = properties

    return CreatedInstance;
end

local function ApplyDragging(Window)
    local dragging
    local dragInput
    local dragStart
    local startPos
    local off = Vector3.new(0,0,0)
    local speed = 2.5
    local k = 0.04
    local windowSize

    local function update(input)
        local delta = input.Position - dragStart
        pcall(function()
            Window:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y),"Out","Quad",0.1,true,nil)
        end)
        local position = Vector2.new(Mouse.X,Mouse.Y)
        local force = position - Window.AbsolutePosition
        local mag = force.Magnitude - 1
        force = force.Unit
        force *= 1 * k * mag
        local formula = speed * force --* delta
        --Tween(Window,0.3,{Rotation = formula.X},"Back")
    end
    
    local c = Window.InputBegan:Connect(function(input)
        if not UI.SliderActive then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                windowSize = Window.AbsoluteSize
                dragStart = input.Position
                startPos = Window.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        --Tween(Window,0.3,{Rotation = 0},"Back")
                    end
                end)
            end
        end
    end)

    local b = Window.InputChanged:Connect(function(input)
        if not UI.SliderActive then
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input

            end
        end
    end)

    local a = InputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function Tween(instance, time, properties,EasingStyle,EasingDirection)
    local tw = TweenService:Create(instance, TweenInfo.new(time, EasingStyle and Enum.EasingStyle[EasingStyle] or Enum.EasingStyle.Quad,EasingDirection and Enum.EasingDirection[EasingDirection] or Enum.EasingDirection.Out), properties)
    task.delay(0, function()
        tw:Play()
    end)
    return tw
end


local KeybindsWidget = {}


KeybindsWidget.Create = function()
    local Window = Create("CanvasGroup",{
        Name = "KeybindsWidget",
        Parent = game.CoreGui:FindFirstChild("Library_UI"),
        Size = UDim2.new(0, 300, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 16, 0, 106),
        BackgroundColor3 = UI.Theme.Primary.Background,
        BackgroundTransparency = 0,
        ZIndex = 10,
        CornerRadius = UDim.new(0, 16),
        GroupTransparency = 1
    })

    Tween(Window,0.3,{GroupTransparency = 0})

    local BG = Create("Frame",{
        Parent = Window,
        Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
    })

    local Gradient = Create("UIGradient",{
        Parent = BG,
        Name = "KeybindsGradient",
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0,UI.Theme.Primary.Background),ColorSequenceKeypoint.new(0.7,UI.Theme.Primary.Background),ColorSequenceKeypoint.new(1,UI.Theme.Primary.Accent)}),
        Rotation = 80,
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.7,0.5),NumberSequenceKeypoint.new(1,0.7)})
    })


    local WidgetTitle = Create("TextLabel",{
        Name = "Title",
        Parent = BG,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Text = "Keybinds",
        TextColor3 = UI.Theme.Text.Primary,
        FontFace = UI.Theme.Text.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 22,
        CornerRadius = UDim.new(0, 8),
    })


    local WindowList = Create("UIListLayout",{
        Name = "WindowList",
        Parent = BG,
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 10),
    })

    local WindowPadding = Create("UIPadding",{
        Name = "WindowPadding",
        Parent = BG,
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })

    ApplyDragging(Window)

    local Widget = {
        parameters,
        AddKeybind = function(properties)
            properties.Active = properties.Active or false
            local KeybindButton = Create("CanvasGroup",{
                Name = properties.Name,
                Parent = BG,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = UI.Theme.Primary.Secondary,
                CornerRadius = UDim.new(0, 8),
            })
            
            local KeybindLabel = Create("TextLabel",{
                Name = "Label",
                Parent = KeybindButton,
                Position = UDim2.new(0,8,0,0),
                Size = UDim2.new(1, -8, 0, 30),
                BackgroundTransparency = 1,
                Text = properties.Name,
                TextColor3 = UI.Theme.Text.Primary,
                FontFace = UI.Theme.Text.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 18,
                CornerRadius = UDim.new(0, 8),
                ZIndex = 2
            })

            local KeybindFiller = Create("Frame",{
                Parent = KeybindButton,
                Size = UDim2.new(0,0,0,0),
                AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(0,0,0.5,0),
                CornerRadius = UDim.new(1,0),
                BackgroundColor3 = UI.Theme.Primary.Accent
            })


            local KeyLabel = Create("TextButton",{
                Name = properties.Key,
                Parent = KeybindButton,
                Size = UDim2.new(0, 0, 0, 20),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(1, -20, 0.5, 0),
                BackgroundTransparency = 1,
                Text = properties.Key,
                TextColor3 = UI.Theme.Text.Primary,
                FontFace = UI.Theme.Text.Font,
                TextSize = 18,
                AutomaticSize = Enum.AutomaticSize.X,
                CornerRadius = UDim.new(0, 5),
            })

            local pddadding = Create("UIPadding",{
                Parent = KeyLabel,
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
            })
            
            KeyLabel.Position = UDim2.new(1,-KeyLabel.AbsoluteSize.X - 10,0.5,0)

            local kbind = {
                Value = properties.Value or false,
                Event = nil,
                Busy = false,
                ChangeKey = function(keyname)
                    properties.Key = keyname
                end
            }

            kbind.UpdateVisual = function(value)
                UI.Instances[KeybindLabel]['TextColor3'] = value and UI.Theme.Primary.Background or UI.Theme.Text.Primary
                UI.Instances[KeyLabel]['TextColor3'] = value and UI.Theme.Primary.Background or UI.Theme.Text.Primary
                Tween(KeyLabel, 0.1, {TextColor3 = value and UI.Theme.Primary.Background or UI.Theme.Text.Primary}, "Quad", "Out")
                if value then 
                   KeybindFiller.Position = UDim2.new(0,0,1.5,0) 
                end
                Tween(KeybindFiller, 0.3, {
                    Size = UDim2.new(value and 1 or 0,4,0, value and KeybindButton.AbsoluteSize.X/2 or 0);
                    Position = value and UDim2.new(0.5,0,0.5,0) or UDim2.new(1.2,0,1.5,0);
                    BackgroundTransparency = value and 0 or 1
                })
                Tween(KeybindLabel, 0.1, {TextColor3 = value and UI.Theme.Primary.Background or UI.Theme.Text.Primary}, "Quad", "Out")
            end

            kbind.UpdateVisual(kbind.Value)


            KeyLabel.MouseButton1Click:Connect(function()
                KeyLabel.Text = "Press a key..."
                kbind.busy = true
                Tween(KeyLabel,0.1,{Position = UDim2.new(1,-KeyLabel.AbsoluteSize.X - 10,0.5,0); TextTransparency = 0.3})
                local inputConnection
                inputConnection = InputService.InputBegan:Connect(function(input, gameProcessedEvent)
                    if not gameProcessed and kbind.busy then
                        properties.Key = input.KeyCode.Name
                        KeyLabel.Text = input.KeyCode.Name
                        Tween(KeyLabel,0.1,{Position = UDim2.new(1,-KeyLabel.AbsoluteSize.X - 10,0.5,0); TextTransparency = 0})
                        inputConnection:Disconnect()
                        task.delay(0.1, function()
                            kbind.busy = false
                        end)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and kbind.busy then
                        KeyLabel.Text = properties.Key -- Reset to original key if mouse click
                        kbind.busy = false
                        inputConnection:Disconnect()
                    end
                end)
            end)

            kbind.Event = InputService.InputBegan:Connect(function(input, gameProcessedEvent)
                if input.KeyCode == Enum.KeyCode[properties.Key] and not kbind.busy and not gameProcessedEvent then
                    kbind.Value = not kbind.Value
                    kbind.UpdateVisual(kbind.Value)
                    task.spawn(properties.Cb, kbind.Value)
                end
            end)
            KeybindButton.Destroying:Connect(function()
                if kbind.Event then
                    kbind.Event:Disconnect()
                end
            end)

            return kbind;
        end,
        RemoveKeybind = function(keybindName)
            local KeybindButton = BG:FindFirstChild(keybindName)
            if KeybindButton then
                KeybindButton:Destroy()
            end
        end,
    }

    UI.KeybindWidgetParameters = Widget
    
    return Widget;
end

return KeybindsWidget;