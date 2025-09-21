local TweenService = game:GetService("TweenService");
local Mouse = game.Players.LocalPlayer:GetMouse();
local PlayerGui = game.Players.LocalPlayer.PlayerGui;
local InputService = game:GetService("UserInputService");




local function Observable(initialValue)
    local subscribers = {}
    local value = type(initialValue) == "table" and {} or initialValue
    local proxyCache = setmetatable({}, {__mode = "v"})
    local updateDepth = 0 


    local function createProxy(tbl, path)
        if type(tbl) ~= "table" then return tbl end
        if proxyCache[tbl] then return proxyCache[tbl] end

        local proxy = {}
        proxyCache[tbl] = proxy

        setmetatable(proxy, {
            __index = function(_, k)
                if k == "_isObservable" then return true end
                return createProxy(tbl[k], path.."."..k)
            end,
            __newindex = function(_, k, v)
                if updateDepth > 0 then
                    rawset(tbl, k, v)
                    return
                end

                local old = rawget(tbl, k)
                if old ~= v then
                    updateDepth = updateDepth + 1
                    
                    tbl[k] = createProxy(v, path.."."..k)
                    

                    for _, callback in ipairs(subscribers) do
                        task.spawn(callback, path.."."..k, v, old)
                    end
                    
                    updateDepth = updateDepth - 1
                end
            end
        })

        return proxy
    end


    if type(initialValue) == "table" then
        for k, v in pairs(initialValue) do
            value[k] = v
        end
    end
    value = createProxy(value, "")

    local public = value
    public.subscribe = function(callback)
        table.insert(subscribers, callback)
        return function()
            for i = #subscribers, 1, -1 do
                if subscribers[i] == callback then
                    table.remove(subscribers, i)
                end
            end
        end
    end

    public.set = function(newValue)
        updateDepth = updateDepth + 1
        

        for k in pairs(value) do
            if k ~= "subscribe" and k ~= "set" and k ~= "_isObservable" then
                value[k] = nil
            end
        end
        

        if type(newValue) == "table" then
            for k, v in pairs(newValue) do
                value[k] = v
            end
        end
        

        for _, callback in ipairs(subscribers) do
            task.spawn(callback, "", value, value)
        end
        
        updateDepth = updateDepth - 1
    end

    public.get = function() return value end

    return public
end


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

function Tween(instance, time, properties,EasingStyle,EasingDirection)
	local tw = TweenService:Create(instance, TweenInfo.new(time, EasingStyle and Enum.EasingStyle[EasingStyle] or Enum.EasingStyle.Quad,EasingDirection and Enum.EasingDirection[EasingDirection] or Enum.EasingDirection.Out), properties)
	task.delay(0, function()
		tw:Play()
	end)
	return tw
end




UI = {
    Themes = {
        Dark = {
            -- Основные цвета
            Primary = {
                Background = Color3.fromRGB(25, 25, 25),     -- Основной фон
                Secondary = Color3.fromRGB(35, 35, 35),      -- Color3.fromRGB(35, 38, 46)
                Accent = Color3.fromRGB(71, 131, 199),        -- Акцентный цвет (кнопки, выделение)
                Hover = Color3.fromRGB(55, 55, 55),        -- Акцент при наведении
                AccentHover = Color3.fromRGB(111, 171, 239)
            },
        
            -- Текст
            Text = {
                Primary = Color3.fromRGB(245, 245, 245),     -- Основной текст (белый)
                Secondary = Color3.fromRGB(170, 170, 170),   -- Второстепенный текст (серый)
                Disabled = Color3.fromRGB(100, 100, 100),
                Font = Font.fromId(12187365364)    -- Неактивный текст
            },
    
            -- Границы и разделители
            Border = {        -- Светлая граница (для контраста)
                Dark = Color3.fromRGB(75, 75, 75),           -- Тёмная граница
            },
        
        },
        White = {
            -- Основные цвета
            Primary = {
                Background = Color3.fromRGB(191, 192, 209),     -- Основной фон
                Secondary = Color3.fromRGB(181, 182, 199),      -- Второстепенный фон (карточки, элементы)
                Accent = Color3.fromRGB(126, 104, 214),        -- Акцентный цвет (кнопки, выделение)
                Hover = Color3.fromRGB(171, 172, 189),
                AccentHover = Color3.fromRGB(146, 124, 234)        -- Акцент при наведении
            },
        
            -- Текст
            Text = {
                Primary = Color3.fromRGB(30, 32, 46),     -- Основной текст (белый)
                Secondary = Color3.fromRGB(49, 50, 62),   -- Второстепенный текст (серый)
                Disabled = Color3.fromRGB(160, 160, 160),
                Font = Font.fromId(12187365364)    -- Неактивный текст
            },
    
            -- Границы и разделители
            Border = {       -- Светлая граница (для контраста)
                Dark = Color3.fromRGB(131, 132, 149),        -- Тёмная граница
            },
        },
    },
    Utility = {
        Success = Color3.fromRGB(76, 175, 80),       -- Успех (зелёный)
        Warning = Color3.fromRGB(255, 193, 7),       -- Предупреждение (жёлтый)
        Error = Color3.fromRGB(244, 67, 54),
        Info = Color3.fromRGB(98, 70, 234),
        Icons = {
            Success = "rbxassetid://75103318493680",
            Error = "rbxassetid://74378626537641",
            Warning = "rbxassetid://127151777763770",
            Info = "rbxassetid://103749959447140"
        }
    },
    ModalActive = false,
    Theme = {},
	Elements = {},
    Chart = nil,
	Instances = {},
	Opened = true,
    ActiveNofitications = {},
    SliderActive = false,
    BackgroundDarken = false,
    Docked = true,
    KeybindWidgetParameters = {
        Enabled = true,
    },
    Keybinds = {},
    BackgroundEnabled = false,
};

UI.ActiveTransparency = 0

UI.Theme = UI.Themes['Dark']


UI.Chart = loadstring(game:HttpGet("https://github.com/slf0Dev/UI_LIBRARY/raw/refs/heads/main/Chart.lua")().Chart
UI.KeybindsWidget = loadstring(game:HttpGet("https://github.com/slf0Dev/UI_LIBRARY/raw/refs/heads/main/KeybindsWidget.lua")()



if game.CoreGui:FindFirstChild("Library_UI") then
	game.CoreGui.Library_UI:Destroy()
end

local SG = Create("ScreenGui",{
	Parent = game.CoreGui,
	Name = "Library_UI",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.None
})

local ScreenRes = SG.AbsoluteSize

UI.Tween = Tween

UI.ChangeTheme = function(theme: table)
    for instance,properties in next,UI.Instances do
        for property,value in next,properties do
            for Category,ThemeProperties in next,UI.Theme do
                for ThemePropety,ThemeValue in next,ThemeProperties do
                    if value == ThemeValue and property ~= "FontFace" and not instance:IsA("UIGradient") then
                        Tween(instance,0.1,{[property] = theme[Category][ThemePropety]})
                        properties[property] = theme[Category][ThemePropety]
                    elseif instance:IsA("UIGradient") and instance.Name == "KeybindsGradient" and tostring(property) == "Color" then
                        local oldKeypoints = properties[property].Keypoints
                        local newKeypoints = {}
                        
                        for _, keypoint in ipairs(oldKeypoints) do
                            if keypoint.Value == ThemeValue then
                                table.insert(newKeypoints, ColorSequenceKeypoint.new(keypoint.Time, theme[Category][ThemePropety]))
                            else
                                table.insert(newKeypoints, keypoint)
                            end
                        end
                        
                        -- Убеждаемся, что точек достаточно (минимум 2)
                        if #newKeypoints >= 2 then
                            instance[property] = ColorSequence.new(newKeypoints)
                            properties[property] = instance[property]  -- Обновляем кеш
                        end
                    end
                end
            end
        end
    end
    UI.Utility.Info = theme.Primary.Accent
    UI.Theme = theme
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


UI.ToolTip = function(parameters)
    local tip = {}

    tip.Active = false
    local ToolTip = Create("CanvasGroup",{
        Parent = SG,
        Name = "ToolTip",
        AnchorPoint = Vector2.new(0.5,0),
        Size = UDim2.new(0,200,0,30),
        Position = UDim2.new(0,Mouse.X,0,Mouse.Y + 25),
        BackgroundColor3 = UI.Theme.Primary.Background,
        BackgroundTransparency = 0,
        Visible = true,
        GroupTransparency = 1,
        ZIndex = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        CornerRadius = UDim.new(0,8),
        Stroke = {
            Thickness = 1,
            Color = UI.Theme.Border.Dark,
            Transparency = 1
        }
    })





    InputService.InputChanged:Connect(function(property)
        if tip.Active then
            Tween(ToolTip,0.05,{Position = UDim2.new(0,Mouse.X,0,(Mouse.Y - ToolTip.AbsoluteSize.Y) + 45)})
        end
    end)

    tip = {
        parameters,
        Show = function()
            if UI.DropdownOpened then return end
            tip.Active = true
            Tween(ToolTip.Stroke,0.3,{Transparency = 0})
            Tween(ToolTip,0.3,{GroupTransparency = 0.1;})
        end,
        Hide = function()
            tip.Active = false
            Tween(ToolTip.Stroke,0.3,{Transparency = 1})
            Tween(ToolTip,0.3,{GroupTransparency = 1})
        end,
    }

    parameters.Parent.MouseEnter:Connect(function()
        if ToolTip then
            tip.Show()
        end
    end)

    parameters.Parent.MouseLeave:Connect(function()
        if ToolTip then
            tip.Hide()
        end
    end)

    local padding = Create("UIPadding",{
        Parent = ToolTip,
        PaddingLeft = UDim.new(0,8),
        PaddingRight = UDim.new(0,8),
        PaddingTop = UDim.new(0,4),
        PaddingBottom = UDim.new(0,4)
    })

    local Line = Create("Frame",{
        Parent = ToolTip,
        Position = UDim2.new(0,0,1,0),
        Size = UDim2.new(1,0,0,2),
        BackgroundColor3 = UI.Theme.Primary.Accent
    })

    local Label = Create("TextLabel",{
        Parent = ToolTip,
        Name = "Label",
        Text = parameters.Text or "ToolTip",
        TextColor3 = UI.Theme.Text.Primary,
        FontFace = UI.Theme.Text.Font,
        TextSize = 16,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.XY,
        RichText = true,
        TextWrapped = true,
    })

    return tip;
end

local Scaler
UI.Init = function(Title : string, Description : string)
	local Background = Create("CanvasGroup",{
		Parent = SG,
		Name = "UI",
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = UI.Theme.Primary.Background,
		GroupTransparency = 1,
		BackgroundTransparency = (UI.BackgroundDarken and 0.5 or 1),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0)
	})

    UI.KeybindsWidget.Create()

    local Videoframe = UI.Docked and Create("VideoFrame",{
        Parent = SG,
        Name = "BackgroundVideo",
        Size = UDim2.new(0,800,0,600),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0.5,0,0.5,0),
        BackgroundTransparency = 1,
        Video = getcustomasset("UILibrary/Backgrounds/1.mp4"),
        Looped = true,
        Playing = true,
        Volume = 0,
        ZIndex = 0,
        CornerRadius = UDim.new(0,16),
    }) or nil



    local VideoGradient = UI.Docked and Create("UIGradient",{
        Parent = Videoframe,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0),
            NumberSequenceKeypoint.new(1,0)
        }),
        Rotation = 0
    }) or nil

    if UI.BackgroundEnabled == false and UI.Docked then
        VideoGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,1),
            NumberSequenceKeypoint.new(1,1)
        })
    end


    UI.Background = UI.Docked and Videoframe or nil


    local Types = {
        Docked = {
            Parent = Videoframe,
            Name = "Windows",
            AnchorPoint = Vector2.new(0.5,0.5),
            Size = UDim2.new(0,800,0,600),
            Position = UDim2.new(0.5,0,0.5,0),
            BackgroundColor3 = UI.Theme.Primary.Background,
            CornerRadius = UDim.new(0,16),
            BackgroundTransparency = 0
        },
        NotDocked = {
            Parent = SG,
            Name = "Windows",
            AnchorPoint = Vector2.new(0.5,0),
            Size = UDim2.new(1,0,1,0),
            Position = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1
        }
    }


    local Windows = Create("CanvasGroup",Types[UI.Docked and "Docked" or "NotDocked"])


    UI.KeybindWidgetParameters.AddKeybind({
        Name = "UI Toggle",
        Key = "Semicolon",
        Value = true,
        Cb = function(value)
            print(value)
            if value == false then
                Tween(Background, 0.1, {GroupTransparency = 1},"Linear")
                if UI.Docked then
                    Videoframe.UIGradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,1),
                        NumberSequenceKeypoint.new(1,1)
                    })
                    task.delay(0.1,function()
                        Videoframe.Visible = false
                    end)
                end
                Tween(Windows, 0.1, {GroupTransparency = 1},"Linear")
            else
                if UI.Docked then
                    Videoframe.Visible = true
                    Videoframe.UIGradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0,UI.BackgroundEnabled and 0 or 1),
                        NumberSequenceKeypoint.new(1,UI.BackgroundEnabled and 0 or 1)
                    })
                end
                Tween(Background, 0.1, {GroupTransparency = 0},"Linear")
                Tween(Windows, 0.1, {GroupTransparency = UI.ActiveTransparency},"Linear")
            end
        end
    })


    Background.Destroying:Connect(function()
        openclose:Disconnect()
    end)

    Scaler = Create("UIScale",{
        Parent = SG,
        Scale = 1
    })

    local BackgroundDarken = Create("TextButton",{
		Parent = SG,
		Name = "Darken",
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = UI.Theme.Primary.Background,
		BackgroundTransparency = 1,
        ZIndex = 99,
        Text = "",
        Visible = false
	})


    if UI.Docked then
        ApplyDragging(Videoframe)
    end


    local NavigationBar,
        NavigationBarLayout,
        Pages,
        PagesLayout,
        Indicator,
        Topbar,
        TitleLabel,
        DescriptionLabel


    if UI.Docked then
        Topbar = Create("Frame",{
            Parent = Windows,
            Name = "Topbar",
            Size = UDim2.new(1,-16,0,50),
            Position = UDim2.new(0,8,0,8),
            BackgroundColor3 = UI.Theme.Primary.Secondary,
            CornerRadius = UDim.new(0,8),
            BackgroundTransparency = 1,
            ZIndex = 2
        })

        TitleLabel = Create("TextLabel",{
            Parent = Topbar,
            Name = "Title",
            Text = Title or "UI Library",
            TextColor3 = UI.Theme.Text.Primary,
            FontFace = UI.Theme.Text.Font,
            TextSize = 24,
            Size = UDim2.new(0,0,0,30),
            Position = UDim2.new(0,8,0,0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.X
        })

        DescriptionLabel = Create("TextLabel",{
            Parent = Topbar,
            Name = "Description",
            Text = Description or "",
            TextColor3 = UI.Theme.Text.Secondary,
            FontFace = UI.Theme.Text.Font,
            TextSize = 16,
            Size = UDim2.new(0,0,0,20),
            Position = UDim2.new(0,8,0,26),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutomaticSize = Enum.AutomaticSize.X
        })
    
        NavigationBar = Create("Frame",{
            Parent = Windows,
            Name = "NavigationBar",
            Size = UDim2.new(0.3,-8,1,-66),
            Position = UDim2.new(0,8,0,58),
            BackgroundColor3 = UI.Theme.Primary.Background,
            CornerRadius = UDim.new(0,16),
            BackgroundTransparency = 1,
            ZIndex = 2
        })

        Indicator = UI.Docked and Create("Frame",{
            Parent = Windows,
            Name = "Indicator",
            AnchorPoint = Vector2.new(0,0),
            Size = UDim2.new(0,4,0,16),
            Position = UDim2.new(0,0,0,0),
            BackgroundColor3 = UI.Theme.Primary.Accent,
            BackgroundTransparency = 0,
            CornerRadius = UDim.new(0,4),
            ZIndex = 4
        }) or nil

        local NavPadding = Create("UIPadding",{
            Parent = NavigationBar,
            PaddingLeft = UDim.new(0,0),
            PaddingRight = UDim.new(0,0),
            PaddingTop = UDim.new(0,8),
            PaddingBottom = UDim.new(0,8)
        })

        NavigationBarLayout = Create("UIListLayout",{
            Parent = NavigationBar,
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            Padding = UDim.new(0,8),
            SortOrder = Enum.SortOrder.LayoutOrder
        })

        Pages = Create("Frame",{
            Parent = Windows,
            Name = "Pages",
            Size = UDim2.new(0.7,-16,1,-74),
            Position = UDim2.new(0.3,8,0,66),
            BackgroundTransparency = 1,
            ZIndex = 1,
            ClipsDescendants = true
        })

        PagesLayout = Create("UIPageLayout",{
            Parent = Pages,
            Name = "UIPage",
            Padding = UDim.new(0,15),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Animated = false,
            ScrollWheelInputEnabled = false,
        })
    end

	local WindowsData = {}
	local firstWindow;

    local HighlightObject = Create("Frame",{
        Parent = Windows,
        Name = "Highlight",
        Size = UDim2.new(0,50,0,50),
        BackgroundColor3 = UI.Theme.Primary.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,0),
        ZIndex = 999,
        CornerRadius = UDim.new(0,8),
        Stroke = {
            Thickness = 1,
            Color = UI.Theme.Primary.Accent,
            Transparency = 1
        }
    })

    local HighlightActive = false
    local Brightened = false
    local Highlightfunc = function(ElementToHighlight : instance)
        Tween(HighlightObject,0.3,{Position = UDim2.new(0,ElementToHighlight.AbsolutePosition.X - 16,0,ElementToHighlight.AbsolutePosition.Y - 23)})
        Tween(HighlightObject,0.3,{BackgroundTransparency = 0.7})
        Tween(HighlightObject.Stroke,0.3,{Transparency = 0})
        Tween(HighlightObject,0.3,{Size = UDim2.new(0,ElementToHighlight.AbsoluteSize.X,0,ElementToHighlight.AbsoluteSize.Y)})
        Tween(HighlightObject.Corner,0.3,{CornerRadius = ElementToHighlight.Corner.CornerRadius})
    end
    task.spawn(function()
        while true do task.wait(1)
            if HighlightActive then
                Tween(HighlightObject.Stroke,1,{Color = (Brightened and UI.Theme.Primary.Background or UI.Theme.Primary.Accent)})
                Brightened = not Brightened
            end
        end
    end)

    local IndicatorPos
    local TB;

	local Elements = {
        Frame = Windows,
        Highlight = Highlightfunc,
		Window = function(Label : string,Icon)
            local Window = Create("ScrollingFrame", {
                Parent = UI.Docked and Pages or Windows,
                Name = Label or "topbar" .. "_Topbar",
                Position = UDim2.new(0.5, 0, 0, 15),
                Size = not UI.Docked and UDim2.new(0,340,0,0) or UDim2.new(1,0,1,0),
                BackgroundColor3 = UI.Theme.Primary.Background,
                CornerRadius = UDim.new(0, 16),
                AutomaticSize = not UI.Docked and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                CanvasSize = UDim2.new(0,0,0,0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = UI.Theme.Primary.Accent,
                AutomaticCanvasSize = UI.Docked and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            })

            
            local NavigationButton = UI.Docked and Create("TextButton",{
                Parent = NavigationBar,
                Name = Label,
                Text = "",
                AnchorPoint = Vector2.new(0,0.5),
                Position = UDim2.new(0,8,0.5,0),
                Size = UDim2.new(1,0,0,42),
                BackgroundColor3 = UI.Theme.Primary.Secondary,
                BackgroundTransparency = 1,
                CornerRadius = UDim.new(0,8),
            }) or nil

            local NavigationButtonLabel = UI.Docked and Create("TextLabel",{
                Parent = NavigationButton,
                Name = "NavigationButtonLabel",
                Text = Label or "Window",
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = UI.Theme.Text.Primary,
                FontFace = UI.Theme.Text.Font,
                TextSize = 22,
                Size = UDim2.new(1,-16,1,0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0,0.5),
                Position = UDim2.new(0,16,0.5,0),
            })  or nil


            if Indicator ~= nil then
                if PagesLayout.CurrentPage == Window then
                    Indicator.BackgroundTransparency = 0
                    NavigationButton.BackgroundTransparency = 0
                    IndicatorPos = UDim2.new(0,NavigationButton.AbsolutePosition.X - Windows.AbsolutePosition.X + 4,0,NavigationButton.AbsolutePosition.Y - Windows.AbsolutePosition.Y + NavigationButton.AbsoluteSize.Y/2 - Indicator.AbsoluteSize.Y/2)
                    Indicator.Position = IndicatorPos
                end


                NavigationButton.MouseEnter:Connect(function()
                    Tween(NavigationButton,0.2,{BackgroundTransparency = 0})
                end)

                NavigationButton.MouseLeave:Connect(function()
                    if PagesLayout.CurrentPage == Window then
                        Tween(NavigationButton,0.2,{BackgroundTransparency = 0})
                    else
                        Tween(NavigationButton,0.2,{BackgroundTransparency = 1})
                    end
                end)

                NavigationButton.MouseButton1Click:Connect(function()
                    IndicatorPos = UDim2.new(0,NavigationButton.AbsolutePosition.X - Windows.AbsolutePosition.X + 4,0,NavigationButton.AbsolutePosition.Y - Windows.AbsolutePosition.Y + NavigationButton.AbsoluteSize.Y/2 - Indicator.AbsoluteSize.Y/2)
                    Tween(Indicator,0.3,{Position = IndicatorPos})
                    Tween(Indicator,0.15,{Size = UDim2.new(0,4,0,24)})
                    task.delay(0.15,function()
                        Tween(Indicator,0.15,{Size = UDim2.new(0,4,0,16)})
                    end)
                    Tween(NavigationButton,0.3,{BackgroundTransparency = 0})
                    PagesLayout:JumpTo(Window)

                    for i,v in next,NavigationBar:GetChildren() do
                        if v:IsA("TextButton") and v ~= NavigationButton then
                            Tween(v,0.3,{BackgroundTransparency = 1})
                        end
                    end
                end)
            end

            local point = Create("Frame",{
                Parent = Window,
                Size = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5,0),
                Position = UDim2.new(0.5,0,0,8)
            })

            if not UI.Docked then
                ApplyDragging(Window)
            end

            local WindowContents = Create("Frame",{
                Parent = Window,
                Name = "Contents",
                Size = UDim2.new(1,-24,0,0),
                AnchorPoint = Vector2.new(0.5,0),
                Position = UDim2.new(0.5,0,0,((Icon or Label ~= nil) and 45 or 8)),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            })

            local ContentsSpacer = Create("Frame",{
                Parent = WindowContents,
                Name = "Contents",
                Size = UDim2.new(0,0,0,8),
                BackgroundTransparency = 1,
                LayoutOrder = 9999
            })

            local ContentsLayout = Create("UIListLayout",{
                Parent = WindowContents,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0,8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            
            if Icon then
                local WindowIcon = Create("ImageLabel",{
                    Parent = Window,
                    Name = Label,
                    Size = UDim2.new(0,20,0,20),
                    Position = UDim2.new(0,8,0,8),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CornerRadius = UDim.new(0,5),
                    Image = Icon.Image,
                    ImageColor3 = UI.Theme.Text.Primary,
                    ImageRectSize = Icon.RectSize or Vector2.new(0,0),
                    ImageRectOffset = Icon.RectOffset or Vector2.new(0,0)
                })
            end

            if Label ~= nil then
                local WindowTitle = Create("TextLabel",{
                    Parent = Window,
                    Name = Label,
                    Text = ' <font weight="700">' .. Label .. "</font> ",
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextColor3 = UI.Theme.Text.Primary,
                    FontFace = UI.Theme.Text.Font,
                    TextSize = 22,
                    Size = UDim2.new(0,0,0,20),
                    Position = (Icon and UDim2.new(0,30,0,8) or UDim2.new(0,8,0,8)),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CornerRadius = UDim.new(0,5),
                    AutomaticSize = Enum.AutomaticSize.X,
                    RichText = true
                })

                UI.Elements[Label] = Window
            end

            local WindowData = {}
            local padding = 16
            local columnWidth = Window.AbsoluteSize.X + padding
            local maxWindowHeight = Windows.AbsoluteSize.Y - 48
            local maxWindowWidth = Windows.AbsoluteSize.X
            if not UI.Docked then
                task.delay(0,function()
                    if #WindowsData == 0 then
                        Window.Position = UDim2.new(0, padding, 0, padding)
                    else
                        local bestColumn = { x = padding, y = padding }
                        local columns = {}
                
                        for _, data in ipairs(WindowsData) do
                            local window = data.Instance
                            local x = window.Position.X.Offset
                            columns[x] = math.max(columns[x] or 0, window.Position.Y.Offset + window.AbsoluteSize.Y + padding)
                        end
                
                        for x, y in pairs(columns) do
                            if y + Window.AbsoluteSize.Y <= maxWindowHeight then
                                if y < bestColumn.y or bestColumn.y == padding then
                                    bestColumn = { x = x, y = y }
                                end
                            end
                        end
                
                        if bestColumn.y == padding then
                            local lastX = padding
                            for x in pairs(columns) do
                                lastX = math.max(lastX, x)
                            end
                            bestColumn.x = lastX + columnWidth
                            bestColumn.y = padding
                
                            if bestColumn.x + Window.AbsoluteSize.X > maxWindowWidth then
                                bestColumn.x = padding
                                bestColumn.y = padding
                            end
                        end
                
                        Window.Position = UDim2.new(0, bestColumn.x, 0, bestColumn.y)
                    end
                
                    WindowData = {
                        Instance = Window,
                        AbsolutePosition = Window.Position,
                        AbsoluteSize = Window.AbsoluteSize
                    }
                
                    table.insert(WindowsData, WindowData)
                end)
            end
        
            if not firstWindow then
                firstWindow = Window
            end


        
            return {
                Contents = WindowContents,
                Element = function(parameters : table)
                    if parameters.Type == "GroupedButtons" then
                        local Group = Create("Frame",{
                            Parent = WindowContents,
                            Size = UDim2.new(1,0,0,46),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                        })

                        local GroupList = Create("UIListLayout",{
                            Parent = Group,
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0,0),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })

                        local ind = 0
                        for c, f in pairs(parameters.Buttons) do
                            if ind > 0 and ind ~= #parameters.Buttons then 
                                local Spacer = Create("Frame",{
                                    Parent = Group,
                                    Name = "Spacer_" .. ind,
                                    Size = UDim2.new(0,1,1,0),
                                    BackgroundTransparency = 0,
                                    BackgroundColor3 = UI.Theme.Border.Dark,
                                    BorderSizePixel = 0,
                                })
                            end
                            ind +=1
                            local Button = Create("TextButton",{
                                Parent = Group,
                                Name = f.Name .. "_Button",
                                Size = UDim2.new((1/2),-2,0,46),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = UI.Theme.Primary.Secondary,
                                BorderSizePixel = 0,
                                Text = "",
                                TextXAlignment = Enum.TextXAlignment.Left,
                                FontFace = UI.Theme.Text.Font,
                                TextColor3 = UI.Theme.Text.Primary,
                                TextSize = 18,
                                ClipsDescendants = true,
                                CornerRadius = UDim.new(0,8),
                            })
                            local Label = Create("TextLabel",{
                                Parent = Button,
                                Name = f.Name,
                                Text = f.Name,
                                TextSize = 18,
                                RichText = true,
                                FontFace = UI.Theme.Text.Font,
                                TextColor3 = UI.Theme.Text.Primary,
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1,0,1,0),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                Position = UDim2.new(0,0,0,0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 2
                            })
                            

                            Button.MouseEnter:Connect(function()
                                Tween(Button,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                            end)

                            Button.MouseLeave:Connect(function()
                                Tween(Button,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                            end)

                            Button.MouseButton1Click:Connect(function()
                                if f.Callback then
                                    task.spawn(function()
                                        f.Callback()
                                    end)
                                end

                                local Ripple = Create("Frame",{
                                    Parent = Button,
                                    Name = "",
                                    Size = UDim2.new(0,0,0,0),
                                    Position = UDim2.new(0,(Mouse.X-Button.AbsolutePosition.X),0,(Mouse.Y-Button.AbsolutePosition.Y)),
                                    BackgroundTransparency = 0.5,
                                    BorderSizePixel = 0,
                                    AnchorPoint = Vector2.new(0.5,0.5),
                                    CornerRadius = UDim.new(1,0),
                                    BackgroundColor3 = UI.Theme.Primary.Accent,
                                    ZIndex = 10
                                })
                                Tween(Ripple,1,{Size = UDim2.new(0,Button.AbsoluteSize.X *1.2,0,Button.AbsoluteSize.X*1.2); Position = UDim2.new(0.5,0,0.5,0)},"Quad")
                                Tween(Ripple,0.5,{BackgroundTransparency = 1})
                            end)
                            
                            UI.Elements[f.Name] = Button
                        end
                    end
                    if parameters.Type == "Button" then
                        local Button = Create("TextButton",{
                            Parent = WindowContents,
                            Name = parameters.Name .. "_Button",
                            Size = UDim2.new(1,0,0,46),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            Text = "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 18,
                            ClipsDescendants = false,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 1
                            }
                        })

                        local ButtonBackground = Create("Frame",{
                            Parent = Button,
                            Name = "Background",
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,1,0),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 2,
                            ClipsDescendants = true
                        })


                        local Label = Create("TextLabel",{
                            Parent= Button,
                            Name = parameters.Name,
                            Text = parameters.Name,
                            TextSize = 18,
                            RichText = true,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,-16,1,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Position = UDim2.new(0,16,0,0),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 2
                        })
    
    
                        UI.Elements[parameters.Name] = Button
    
    
                        local ButtonIcon = Create("ImageLabel",{
                            Parent = Button,
                            Name = parameters.Name,
                            Size = UDim2.new(0,22,0,22),
                            Position = UDim2.new(1,-30,0.5,0),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0,0.5),
                            CornerRadius = UDim.new(0,5),
                            Image = "rbxassetid://86864076642969",
                            ImageColor3 = UI.Theme.Border.Dark,
                            ZIndex = 2
                        })
                        
    
    
                        Button.MouseButton1Click:Connect(function()
                            if parameters.Callback then
                                task.spawn(function()
                                    parameters.Callback()
                                end)
                            end
    
    
                            local Ripple = Create("Frame",{
                                Parent = ButtonBackground,
                                Name = "",
                                Size = UDim2.new(0,0,0,0),
                                Position = UDim2.new(0,(Mouse.X-Button.AbsolutePosition.X),0,(Mouse.Y-Button.AbsolutePosition.Y)),
                                BackgroundTransparency = 0.5,
                                BorderSizePixel = 0,
                                AnchorPoint = Vector2.new(0.5,0.5),
                                CornerRadius = UDim.new(1,0),
                                BackgroundColor3 = UI.Theme.Primary.Accent,
                                ZIndex = 10
                            })
                            Tween(Ripple,1,{Size = UDim2.new(0,Button.AbsoluteSize.X *1.2,0,Button.AbsoluteSize.X*1.2); Position = UDim2.new(0.5,0,0.5,0)},"Quad")
                            Tween(Ripple,0.5,{BackgroundTransparency = 1})
                        end)


                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = Button,
                            })
                        end
    
                        Button.MouseEnter:Connect(function()
                            Tween(ButtonIcon,0.3,{ImageColor3 = UI.Theme.Primary.Accent})
                            Tween(Button.Shadow,0.3,{ImageTransparency = 0.29})
                            Tween(Button,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                        end)
    
                        Button.MouseLeave:Connect(function()
                            Tween(ButtonIcon,0.3,{ImageColor3 = UI.Theme.Border.Dark})
                            Tween(Button.Shadow,0.3,{ImageTransparency = 1})
                            Tween(Button,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                        end)
                    elseif parameters.Type == "Card" then
                        local Par = Create("Frame",{
                            Parent = WindowContents,
                            Name = parameters.Title,
                            Size = UDim2.new(1,0,0,0),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            Stroke = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark
                            }
                        })
                        
                        
                        UI.Elements[parameters.Title .. "-" .. parameters.Content] = Par
                        local ParTitle = Create("TextLabel",{
                            Parent = Par,
                            Name = parameters.Title or "",
                            Text = parameters.Title or "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 22,
                            Size = UDim2.new(1,-10,0,16),
                            Position = UDim2.new(0,12,0,12),
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            RichText = true,
                            Visible = parameters.Content ~= nil and true or false
                        })
    
    
                        local ParCont = Create("TextLabel",{
                            Parent = Par,
                            Name = parameters.Content or "",
                            Text = parameters.Content or "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Secondary,
                            TextSize = 18,
                            Size = UDim2.new(1,-16,0,0),
                            Position = UDim2.new(0,12,0,26),
                            BackgroundTransparency = 1,
                            CornerRadius = UDim.new(0,5),
                            BorderSizePixel = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            TextWrapped = true,
                            RichText = true,
                            Visible = parameters.Content ~= nil and true or false
                        })

                        local ParSpacer = Create("TextLabel",{
                            Parent = ParCont,
                            Name = "Spacer",
                            Text = "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextSize = 18,
                            Size = UDim2.new(0,0,0,16),
                            Position = UDim2.new(0,0,1,0),
                            BackgroundTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                        })

                        parameters = Observable(parameters)


                        parameters.subscribe(function(path,newVal,oldVal)
                            if path == ".Content" then 
                                ParCont.Text = newVal
                            elseif path == ".Title" then
                                ParTitle.Text = newVal
                            end
                        end)

                        return parameters;
                    elseif parameters.Type == "TextBox" then
                        parameters = Observable(parameters)
                        local TextBox = Create("Frame",{
                            Parent = WindowContents,
                            Name = parameters.Name .. "_TextBox",
                            Size = UDim2.new(1,0,0,70),
                            BackgroundTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                        })



                        local InputBoxCanvas = Create("Frame",{
                            Parent = TextBox,
                            CornerRadius = UDim.new(0,8),
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,0,42),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0,0,0,28),
                            ZIndex = 0,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Primary.Accent,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 1
                            }
                        })


                        local InputBoxBackground = Create("Frame",{
                            Parent = InputBoxCanvas,
                            Name = "Background",
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,1,0),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 2,
                            ClipsDescendants = true
                        })

                        local PromptIcon = Create("ImageLabel",{
                            Parent = InputBoxCanvas,
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(0,8,0.5,0),
                            Size = UDim2.new(0,20,0,20),
                            Image = parameters.Prompt or "",
                            ImageColor3 = UI.Theme.Text.Secondary,
                            BackgroundTransparency = 1,
                            ZIndex = 2
                        })


                        local InputBox = Create("TextBox",{
                            Parent = InputBoxCanvas,
                            Name = "TextBox",
                            Size = (parameters.Prompt and UDim2.new(1,-36,0,42) or UDim2.new(1,-8,0,42)),
                            AnchorPoint = Vector2.new(0,0),
                            BackgroundTransparency = 1,
                            Position = (parameters.Prompt and UDim2.new(0,36,0,0) or UDim2.new(0,8,0,0)),
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,5),
                            Text = parameters.Value ~= nil and parameters.Value or "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 20,
                            ClearTextOnFocus = false,
                            PlaceholderText = parameters.PlaceholderText or "Type something",
                            PlaceholderColor3 = UI.Theme.Text.Secondary,
                            ZIndex = 2
                        })



                        local BoxName = Create("TextLabel",{
                            Parent = TextBox,
                            Name = "BoxLabel",
                            Size = UDim2.new(0,0,0,20),
                            AnchorPoint = Vector2.new(0,0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0,0,0,0),
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,5),
                            Text = parameters.Name or "Label",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 18
                        })

                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = BoxName,
                            })
                        end

                        InputBoxCanvas.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                InputBox:CaptureFocus()
                            end
                        end)


                        InputBox.Focused:Connect(function()
                            Tween(InputBoxCanvas.Shadow,0.3,{ImageTransparency = 0.29})
                            if parameters.Prompt then
                                Tween(PromptIcon,0.3,{ImageColor3 = UI.Theme.Primary.Accent})
                            end
                        end)

                        InputBox.FocusLost:Connect(function()
                            if parameters.Prompt then
                                Tween(PromptIcon,0.3,{ImageColor3 = UI.Theme.Text.Secondary})
                            end
                            Tween(InputBoxCanvas.Shadow,0.3,{ImageTransparency = 1})
                            task.spawn(parameters.Callback,InputBox.Text)
                        end)


                        parameters.subscribe(function(path,newVal,oldVal)
                            if path == ".Value" then
                                InputBox.Text = newVal
                                task.spawn(parameters.Callback, newVal)
                            end
                        end)

                        UI.Elements[parameters.Name] = TextBox
                        return parameters
                    elseif parameters.Type == "Toggle" then
                        parameters.Value = parameters.Value or false
                        parameters = Observable(parameters)

                        local Checkbox = Create("TextButton",{
                            Parent = WindowContents,
                            Name = parameters.Name .. "_Checkbox",
                            Size = UDim2.new(1,0,0,46),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            Text = "",
                            TextXAlignment = Enum.TextXAlignment.Left,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 18,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 1
                            },
                            ClipsDescendants = false
                        })



                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = Checkbox,
                            })
                        end

                        local CheckboxBackground = Create("Frame",{
                            Parent = Checkbox,
                            Name = "Background",
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,1,0),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 2,
                            ClipsDescendants = true
                        })


                        local Label = Create("TextLabel",{
                            Parent = Checkbox,
                            Name = parameters.Name,
                            Text = parameters.Name,
                            TextSize = 18,
                            RichText = true,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,-16,1,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Position = UDim2.new(0,16,0,0),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 2
                        })

                        Checkbox.MouseEnter:Connect(function()
                            Tween(Checkbox,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                            Tween(Checkbox.Shadow,0.3,{ImageTransparency = 0.29})
                        end)
    
                        Checkbox.MouseLeave:Connect(function()
                            Tween(Checkbox,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                            Tween(Checkbox.Shadow,0.3,{ImageTransparency = 1})
                        end)
    
                        UI.Elements[parameters.Name] = Checkbox

                        local OuterCircle = Create("Frame",{
                            Parent = Checkbox,
                            Size = UDim2.new(0,50,0,26),
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(1,-58,0.5,0),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Background,
                            CornerRadius = UDim.new(1,0),
                            ZIndex = 2,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Primary.Accent,
                                Padding = {0,0},
                                Size = {8,10},
                            },
                        })



                        local InnerCircle = Create("Frame",{
                            Parent = OuterCircle,
                            Size = UDim2.new(0,26,0,26),
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(0,8,0.5,0),
                            BackgroundTransparency = 0,
                            CornerRadius = UDim.new(1,0),
                            BackgroundColor3 = UI.Theme.Border.Dark,
                            Stroke = {
                                Thickness = 1,
                                Color = UI.Theme.Border.Dark,
                                Transparency = 1
                            },
                            ZIndex = 2
                        })
                        local AgreementWindow;
                        local function Agreement()
                            UI.AgreementModalActive = true
                            AgreementWindow = Create("CanvasGroup", {
                                Parent = SG,
                                Name = parameters.Agreement.Title or "Agreement",
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                Size = UDim2.new(0.18,0,0,110),
                                BackgroundColor3 = UI.Theme.Primary.Background,
                                CornerRadius = UDim.new(0, 8),
                                AnchorPoint = Vector2.new(0.5,0.5),
                                GroupTransparency = 1,
                                Visible = false,
                                ZIndex = 100
                            })
                        
                            AgreementWindow.Visible = true
                            BackgroundDarken.Visible = true
                            Tween(BackgroundDarken,0.3,{BackgroundTransparency = 0.5})
                            Tween(AgreementWindow,0.3,{Size = UDim2.new(0.20,0,0,120); GroupTransparency = 0})

                            local AgreementTitle = Create("TextLabel",{
                                Parent = AgreementWindow,
                                Name = parameters.Agreement.Title,
                                Text =  parameters.Agreement.Title,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextColor3 = UI.Theme.Text.Primary,
                                FontFace = UI.Theme.Text.Font,
                                TextSize = 16,
                                Size = UDim2.new(1,0,0,20),
                                Position = UDim2.new(0,0,0,8),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                AnchorPoint = Vector2.new(0,0),
                                CornerRadius = UDim.new(0,5),
                                RichText = true,
                                ZIndex = 100
                            })


                            local AgreementDescription = Create("TextLabel",{
                                Parent = AgreementWindow,
                                Name = parameters.Agreement.Description,
                                Text = parameters.Agreement.Description,
                                TextXAlignment = Enum.TextXAlignment.Center,
                                TextColor3 = UI.Theme.Text.Secondary,
                                FontFace = UI.Theme.Text.Font,
                                TextSize = 16,
                                Size = UDim2.new(1,0,0,20),
                                Position = UDim2.new(0,8,0,38),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                AnchorPoint = Vector2.new(0,0),
                                CornerRadius = UDim.new(0,5),
                                AutomaticSize = Enum.AutomaticSize.X,
                                RichText = true,
                                ZIndex = 100
                            })
                        
                        
                            local AcceptButton = Create("TextButton",{
                                Parent = AgreementWindow,
                                Name = "AcceptBtn",
                                Size = UDim2.new(0.4,0,0,30),
                                Position = UDim2.new(0,8,1,-38),
                                Text = "Yes",
                                FontFace = UI.Theme.Text.Font,
                                TextSize = 20,
                                TextColor3 = UI.Theme.Text.Primary,
                                CornerRadius = UDim.new(0,8),
                                BackgroundColor3 = UI.Theme.Primary.Accent,
                                BackgroundTransparency = 0.5,
                                Stroke = {
                                    Thickness = 1,
                                    Transparency = 1,
                                    Color = UI.Theme.Primary.Accent
                                },
                                ZIndex = 100
                            })

                            local DeclineButton = Create("TextButton",{
                                Parent = AgreementWindow,
                                Name = "AcceptBtn",
                                Size = UDim2.new(0.4,0,0,30),
                                Position = UDim2.new(0.6,-8,1,-38),
                                Text = "No",
                                FontFace = UI.Theme.Text.Font,
                                TextSize = 20,
                                TextColor3 = UI.Theme.Primary.Accent,
                                CornerRadius = UDim.new(0,8),
                                BackgroundColor3 = UI.Theme.Primary.Secondary,
                                Stroke = {
                                    Thickness = 1,
                                    Transparency = 1,
                                    Color = UI.Theme.Border.Dark
                                },
                                ZIndex = 100
                            })

                            local State = nil


                            AcceptButton.MouseButton1Click:Connect(function()
                                State = true
                            end)

                            AcceptButton.MouseEnter:Connect(function()
                                Tween(AcceptButton.Stroke,0.3,{Transparency = 0;Thickness = 1; Color = UI.Theme.Primary.Accent})
                            end)

                            AcceptButton.MouseLeave:Connect(function()
                                Tween(AcceptButton.Stroke,0.3,{Transparency = 1;Thickness = 1; Color = UI.Theme.Primary.Accent})
                            end)

                            DeclineButton.MouseButton1Click:Connect(function()
                                State = false
                            end)

                            DeclineButton.MouseEnter:Connect(function()
                                Tween(DeclineButton,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                                Tween(DeclineButton.Stroke,0.3,{Transparency = 0;Thickness = 1; Color = UI.Theme.Border.Dark})
                            end)

                            DeclineButton.MouseLeave:Connect(function()
                                Tween(DeclineButton,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                                Tween(DeclineButton.Stroke,0.3,{Transparency = 1;Thickness = 1; Color = UI.Theme.Border.Dark})
                            end)

                            repeat task.wait()
                            until State ~= nil
                            Tween(AgreementWindow,0.3,{Size = UDim2.new(0.18,0,0,110); GroupTransparency = 1})
                            Tween(BackgroundDarken,0.3,{BackgroundTransparency = 1})
                            task.delay(0.3,function()
                                BackgroundDarken.Visible = false
                                UI.AgreementModalActive = false
                                AgreementWindow:Destroy()
                            end)
                            return State
                        end


                        if parameters.Keybind then
                            parameters.Keybind = UI.KeybindWidgetParameters.AddKeybind({
                                Name = parameters.Name,
                                Key = parameters.Keybind,
                                Value = parameters.Value,
                                Cb = function(value)
                                    parameters.Value = value
                                end
                            })
                        end

                        local function UpdateVisual(boolean)
                            if parameters.Keybind then
                                parameters.Keybind.Value = boolean
                                parameters.Keybind.UpdateVisual(boolean)
                            end
                            UI.Instances[OuterCircle]["BackgroundColor3"] = (boolean and UI.Theme.Primary.Accent or UI.Theme.Primary.Background)
                            UI.Instances[InnerCircle]['BackgroundColor3'] = (boolean and UI.Theme.Primary.Background or UI.Theme.Border.Dark)
                            Tween(InnerCircle,0.3,{Position = (boolean and UDim2.new(1,-24,0.5,0) or UDim2.new(0,4,0.5,0)) ; BackgroundColor3 = (boolean and UI.Theme.Primary.Background or UI.Theme.Border.Dark)},"Back")
                            Tween(InnerCircle,0.3,{Size = (boolean and UDim2.new(0,20,0,10) or UDim2.new(0,26,0,6))})
                            Tween(OuterCircle,0.3,{BackgroundColor3 = (boolean and UI.Theme.Primary.Accent or UI.Theme.Primary.Background)})
                            Tween(OuterCircle.Shadow,0.3,{ImageTransparency = (boolean and 0.29 or 1)})
                            task.delay(0.1,function()
                                Tween(InnerCircle,0.3,{Size =(boolean and UDim2.new(0,20,0,20) or UDim2.new(0,18,0,18))})
                            end)
                        end




                        UpdateVisual(parameters.Value)
                        local can
                        local needAgreement = false
                        Checkbox.MouseButton1Click:Connect(function()
                            local newValue = not parameters.Value
                            
                            if parameters.Agreement and newValue == true then
                                -- Для включения требуется подтверждение
                                task.spawn(function()
                                    local confirmed = Agreement()
                                    if confirmed then
                                        parameters.Value = true -- Единоразовое изменение
                                    end
                                end)
                            else
                                -- Для выключения или без Agreement - сразу меняем
                                parameters.Value = newValue -- Единоразовое изменение
                            end
                        end)



                        parameters.subscribe(function(path,newVal,oldVal)
                            if path == ".Value" then
                                UpdateVisual(parameters.Value)
                                task.spawn(parameters.Callback, newVal)
                            elseif path == ".Name" then
                                Label.Text = newVal
                            elseif path == ".Keybind" then
                                parameters.Keybind.ChangeKey(newVal)
                            end
                        end)


                    return parameters;
                    elseif parameters.Type == "Filter" then

                        local Filter = Create("Frame",{
                            Parent = WindowContents,
                            Name = parameters.Name.. "_Filter",
                            Stroke = {
                                Thickness = 1,
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark
                            },
                            BackgroundTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,0,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,5),
                        })

                        UI.Elements[parameters.Name] = Filter

                        local Label = Create("TextLabel",{
                            Parent= Filter,
                            Name = parameters.Name,
                            Text = '<font weight="500">' .. parameters.Name .. "</font>",
                            TextSize = 20,
                            RichText = true,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,-16,0,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Position = UDim2.new(0,16,0,4),
                            TextXAlignment = Enum.TextXAlignment.Left
                        })

                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = Label,
                            })
                        end


                        local FilterContents = Create("Frame",{
                            Parent = Filter,
                            Position = UDim2.new(0,8,0,35),
                            Size = UDim2.new(1,-16,0,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1
                        })

                        local Spacer = Create("Frame",{
                            Parent = Filter,
                            Position = UDim2.new(0,0,1,-4),
                            Size = UDim2.new(1,0,0,8),
                            BackgroundTransparency = 1
                        })

                        local FiltersLayout = Create("UIListLayout",{
                            Parent = FilterContents,
                            FillDirection = Enum.FillDirection.Horizontal,
                            HorizontalAlignment = Enum.HorizontalAlignment.Left,
                            VerticalAlignment = Enum.VerticalAlignment.Center,
                            Padding = UDim.new(0,8),
                            SortOrder = Enum.SortOrder.LayoutOrder,
                            Wraps = true
                        })

                        for i,v in pairs(parameters.Filters) do
                            local FilterButton = Create("TextButton",{
                                Parent = FilterContents,
                                Name = i,
                                Size = UDim2.new(0,0,0,30),
                                BackgroundColor3 = UI.Theme.Primary.Secondary,
                                BackgroundTransparency = 0.6,
                                Stroke = {
                                    Thickness = 1,
                                    Color = UI.Theme.Border.Dark
                                },
                                Text = "",
                                CornerRadius = UDim.new(1,0)
                            })


                            local filterCheckedIcon = Create("ImageLabel",{
                                Parent = FilterButton,
                                Size = UDim2.new(0,22,0,22),
                                AnchorPoint = Vector2.new(0,0.5),
                                Position = UDim2.new(0,8,0.5,0),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://76272566481022",
                                ImageTransparency = 1,
                                ImageColor3 = UI.Theme.Text.Secondary
                            })

                            local IntimidateIcon = Create("ImageLabel",{
                                Parent = FilterButton,
                                Size = UDim2.new(0,22,0,22),
                                AnchorPoint = Vector2.new(0,0.5),
                                Position = UDim2.new(0,8,0.5,0),
                                BackgroundTransparency = 1,
                                Image = "rbxassetid://114175928274992",
                                ImageTransparency = 1,
                                ImageColor3 = UI.Theme.Text.Secondary
                            })
                            

                            local FilterText = Create("TextLabel",{
                                Parent = FilterButton,
                                BackgroundTransparency = 1,
                                Text = i,
                                FontFace = UI.Theme.Text.Font,
                                TextSize = 16,
                                TextColor3 = UI.Theme.Text.Secondary,
                                Position = UDim2.new(0,8,0,8),
                                Size = UDim2.new(1,-16,1,-16)
                            })


                            FilterButton.Size = UDim2.new(0,FilterText.TextBounds.X + 16,0,30)

                            UI.Instances[FilterButton.Stroke]['Color'] = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Border.Dark)
                            UI.Instances[FilterButton]["BackgroundColor3"] = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Primary.Secondary)
                            
                            Tween(IntimidateIcon,0.3,{ImageTransparency = parameters.Filters[i] and 1 or 0})
                            Tween(filterCheckedIcon,0.3,{ImageTransparency = (parameters.Filters[i] and 0 or 1); Position = UDim2.new(0,8,0.5,0); Size = (parameters.Filters[i] and UDim2.new(0,22,0,22) or UDim2.new(0,22,0,0))})
                            Tween(FilterText,0.3,{Position = UDim2.new(0, 22,0,8 )})
                            Tween(FilterButton,0.3,{Size = UDim2.new(0,FilterText.TextBounds.X + 50,0,30); BackgroundColor3 = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Primary.Secondary)})
                            Tween(FilterButton.Stroke,0.3,{Color = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Border.Dark)})

                            FilterButton.MouseButton1Click:Connect(function()
                                parameters.Filters[i] = not parameters.Filters[i]
                                task.spawn(parameters.Callback,parameters.Filters)
                                UI.Instances[FilterButton.Stroke]['Color'] = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Border.Dark)
                                UI.Instances[FilterButton]["BackgroundColor3"] = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Primary.Secondary)
                                
                                Tween(IntimidateIcon,0.3,{ImageTransparency = parameters.Filters[i] and 1 or 0})
                                Tween(filterCheckedIcon,0.3,{ImageTransparency = (parameters.Filters[i] and 0 or 1); Size = (parameters.Filters[i] and UDim2.new(0,22,0,22) or UDim2.new(0,22,0,0))},"Back")
                                Tween(FilterButton,0.3,{BackgroundColor3 = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Primary.Secondary)},"Back")
                                Tween(FilterButton.Stroke,0.3,{Color = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Border.Dark)})
                            end)


                            FilterButton.MouseEnter:Connect(function()
                                Tween(FilterButton,0.3,{BackgroundColor3 = (parameters.Filters[i] and UI.Theme.Primary.AccentHover or UI.Theme.Primary.Hover)})
                            end)

                            FilterButton.MouseLeave:Connect(function()
                                Tween(FilterButton,0.3,{BackgroundColor3 = (parameters.Filters[i] and UI.Theme.Primary.Accent or UI.Theme.Primary.Secondary)})
                            end)
                        end
                    


                    return {Parameters = parameters};

                    elseif parameters.Type == "ColorPicker" then
                        local DefH,DefS,DefV = parameters.DefaultColor:ToHSV()
                        local ColorPicker = Create("TextButton",{
                            Parent = WindowContents,
                            Name = parameters.Name.. "_ColorPicker",
                            BackgroundTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,0,46),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            Text = "",
                            ZIndex = 1,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 1
                            }
                        })

                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = ColorPicker,
                            })
                        end


                        local ColorPickerBackground = Create("Frame",{
                            Parent = ColorPicker,
                            Name = "Background",
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,1,0),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 2
                        })


                        ColorPicker.MouseEnter:Connect(function()
                            Tween(ColorPicker,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                            Tween(ColorPicker.Shadow,0.3,{ImageTransparency = 0.29})
                        end)
    
                        ColorPicker.MouseLeave:Connect(function()
                            Tween(ColorPicker,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                            Tween(ColorPicker.Shadow,0.3,{ImageTransparency = 1})
                        end)

                        UI.Elements[parameters.Name] = ColorPicker

                        local Label = Create("TextLabel",{
                            Parent= ColorPicker,
                            Name = parameters.Name,
                            Text = parameters.Name,
                            TextSize = 18,
                            RichText = true,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,-16,1,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Position = UDim2.new(0,16,0,0),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 2
                        })


                        local ColorDisplay = Create("Frame",{
                            Parent = ColorPicker,
                            Size = UDim2.new(0,22,0,22),
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(1,-30,0.5,0),
                            CornerRadius = UDim.new(0,8),
                            BackgroundColor3 = parameters.DefaultColor or Color3.fromHSV(0,0,1),
                            ZIndex = 2
                        })


                        local ColorPickerModal = Create("Frame",{
                            Parent = SG,
                            Size = UDim2.new(0,340-106,0,295),
                            Position = UDim2.new(0,ColorPicker.AbsolutePosition.X,0,ColorPicker.AbsolutePosition.Y - 20),
                            BackgroundTransparency = 1,
                            CornerRadius = UDim.new(0,8),
                            Visible = false,
                            ZIndex = 101,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 100
                            }
                        })

                        local ColorPickerModalBackground = Create("CanvasGroup",{
                            Parent = ColorPickerModal,
                            Size = UDim2.new(1,0,1,0),
                            GroupTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Background,
                            BackgroundTransparency = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 101
                        })

                        BackgroundDarken.Active = false

                        local SatAndVibCanvas = Create("CanvasGroup",{
                            Parent = ColorPickerModalBackground,
                            Position = UDim2.new(0.5,0,0,8),
                            AnchorPoint = Vector2.new(0.5,0),
                            Size = UDim2.new(1,-16,0,280),
                            CornerRadius = UDim.new(0,8),
                            BackgroundColor3 = Color3.fromHSV(0,0,1),
                            ZIndex = 102
                        })

                        SatAndVibCanvas.Size = UDim2.new(1,-16,0,SatAndVibCanvas.AbsoluteSize.X)
                        
                        local Gradient = Create("UIGradient",{
                            Parent = SatAndVibCanvas,
                            Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromHSV(0,0,1)),ColorSequenceKeypoint.new(1,Color3.fromHSV(0,0,0))}),
                            Rotation = 90
                        })


                        local SaturationImage = Create("ImageLabel",{
                            Parent = SatAndVibCanvas,
                            Size = UDim2.new(2,0,2,4),
                            AnchorPoint = Vector2.new(0.5,0.5),
                            Position = UDim2.new(0.5,0,0.5,0),
                            BackgroundTransparency = 1,
                            BackgroundColor3 = Color3.fromHSV(0.6,1,1),
                            Image ="http://www.roblox.com/asset/?id=15416050966",
                            ZIndex = 102,
                            CornerRadius = UDim.new(1,0)
                        })

                        local HueSequence = {}

                        for hue = 0,1,0.1 do
                            table.insert(HueSequence,ColorSequenceKeypoint.new(hue,Color3.fromHSV(hue,1,1)))
                        end

                        local HueSlider = Create("Frame",{
                            Parent = ColorPickerModalBackground,
                            AnchorPoint = Vector2.new(0,0),
                            Size = UDim2.new(0,SatAndVibCanvas.AbsoluteSize.X - 36,0,26),
                            Position = UDim2.new(0,8,1,-64),
                            BackgroundColor3 = Color3.fromRGB(255,255,255),
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 102
                        })

                        local GradientHue = Create("UIGradient",{
                            Parent = HueSlider,
                            Color = ColorSequence.new(HueSequence)
                        })

                        local HuePointerBox = Create("Frame",{
                            Parent = ColorPickerModalBackground,
                            AnchorPoint = Vector2.new(0,0),
                            Size = UDim2.new(0,HueSlider.AbsoluteSize.X - 24,0,HueSlider.AbsoluteSize.Y),
                            Position = UDim2.new(0,20,HueSlider.Position.Y.Scale,HueSlider.Position.Y.Offset),
                            BackgroundColor3 = Color3.fromRGB(255,255,255),
                            BackgroundTransparency = 1,
                            ZIndex = 102
                        })

                        local HuePointer = Create("Frame",{
                            Parent = HuePointerBox,
                            AnchorPoint = Vector2.new(0.5,0.5),
                            Position = UDim2.new(0,0,0,0),
                            Size = UDim2.new(0,14,0,14),
                            CornerRadius = UDim.new(1,0),
                            Stroke = {
                                Thickness = 2,
                                Color = Color3.fromRGB(255,255,255)
                            },
                            ZIndex = 102
                        })


                        local VibSatPointerBox = Create("Frame",{
                            Parent = ColorPickerModalBackground,
                            AnchorPoint = Vector2.new(0.5,0),
                            Size = UDim2.new(0,SatAndVibCanvas.AbsoluteSize.X - 20,0,SatAndVibCanvas.AbsoluteSize.Y-20),
                            Position = UDim2.new(0.5,0,0,18),
                            BackgroundColor3 = Color3.fromRGB(255,255,255),
                            BackgroundTransparency = 1,
                            ZIndex = 102
                        })

                        local VibSatPointer = Create("Frame",{
                            Parent = VibSatPointerBox,
                            AnchorPoint = Vector2.new(0.5,0.5),
                            Position = UDim2.new(0,0,0,0),
                            Size = UDim2.new(0,8,0,8),
                            CornerRadius = UDim.new(1,0),
                            Stroke = {
                                Thickness = 4,
                                Color = Color3.fromRGB(255,255,255)
                            },
                            ZIndex = 102
                        })

                        local DisplayFinalColor = Create("Frame",{
                            Parent = ColorPickerModalBackground,
                            AnchorPoint = Vector2.new(0,0),
                            Size = UDim2.new(0,26,0,26),
                            Position = UDim2.new(1,-34,1,-64),
                            BackgroundColor3 = Color3.fromRGB(255,255,255),
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 102
                        })
                        

                        local AA = Create("TextButton",{
                            Parent = ColorPickerModalBackground,
                            Size = UDim2.new(1,0,1,0),
                            Position = UDim2.new(0,0,0,0),
                            BackgroundTransparency = 1,
                            Text = "",
                            ZIndex = 100
                        })
                        
                        local ApplyButton = Create("TextButton",{
                            Parent = ColorPickerModalBackground,
                            Size = UDim2.new(0,60,0,22),
                            Position = UDim2.new(1,-68,1,-30),
                            BackgroundTransparency = 1,
                            Text = "Apply",
                            FontFace = UI.Theme.Text.Font,
                            TextSize = 18,
                            TextColor3 = UI.Theme.Primary.Accent,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            CornerRadius = UDim.new(0,5),
                            ZIndex = 102
                        })

                        local ResetButton = Create("TextButton",{
                            Parent = ColorPickerModalBackground,
                            Size = UDim2.new(0,60,0,22),
                            Position = UDim2.new(1,-128,1,-30),
                            BackgroundTransparency = 1,
                            Text = "Reset",
                            FontFace = UI.Theme.Text.Font,
                            TextSize = 18,
                            TextColor3 = UI.Theme.Primary.Accent,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            CornerRadius = UDim.new(0,5),
                            ZIndex = 102
                        })


                        local SatMin
                        local SatMax
                        local SatX = DefS or 1

                        local VibMin
                        local VibMax
                        local VibY = 1-DefV or 1


                        local HueMin
                        local HueMax
                        local HueX = DefH or 0

                        local FinalColor = parameters.DefaultValue
                        local SaveColor = {
                            H = HueX,
                            S = SatX,
                            V = VibY
                        }


                        local function hsvToRgb(h, s, v)
                            local r, g, b
                        
                            local i = math.floor(h * 6)
                            local f = h * 6 - i
                            local p = v * (1 - s)
                            local q = v * (1 - f * s)
                            local t = v * (1 - (1 - f) * s)
                        
                            i = i % 6
                        
                            if i == 0 then r, g, b = v, t, p
                            elseif i == 1 then r, g, b = q, v, p
                            elseif i == 2 then r, g, b = p, v, t
                            elseif i == 3 then r, g, b = p, q, v
                            elseif i == 4 then r, g, b = t, p, v
                            elseif i == 5 then r, g, b = v, p, q
                            end
                            
                            return Color3.fromRGB(r * 255, g * 255, b * 255)
                        end


                        HuePointer.Position = UDim2.new(HueX,0,0.5,0)
                        local SaturationAndVibChanging = SatAndVibCanvas.InputBegan:Connect(function(key)
                            if key.UserInputType == Enum.UserInputType.MouseButton1 then
                                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                    SatMin = SatAndVibCanvas.AbsolutePosition.X
                                    SatMax = SatMin + SatAndVibCanvas.AbsoluteSize.X
                                    SatX = ((math.clamp(Mouse.X,SatMin,SatMax) - SatMin) / (SatMax - SatMin))
                                    

                                    VibMin = SatAndVibCanvas.AbsolutePosition.Y
                                    VibMax = VibMin + SatAndVibCanvas.AbsoluteSize.Y
                                    VibY = ((math.clamp(Mouse.Y,VibMin,VibMax) - VibMin) / (VibMax - VibMin))


                                    Tween(ColorDisplay,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                                    Tween(VibSatPointer,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                                    FinalColor = hsvToRgb(HueX,SatX,1-VibY)
                                    Tween(DisplayFinalColor,0.1,{BackgroundColor3 = FinalColor})
                                    Tween(VibSatPointer,0.1,{Position = UDim2.new(SatX,0,VibY,0)})
                                    task.wait()
                                end
                            end
                        end)


                        ApplyButton.MouseButton1Click:Connect(function()
                            SaveColor = {
                                H = HueX,
                                S = SatX,
                                V = VibY
                            }
                            FinalColor = {HueX,SatX,1-VibY}
                            task.spawn(parameters.Callback,FinalColor)
                            Tween(ColorDisplay,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                            Tween(VibSatPointer,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                            Tween(VibSatPointer,0.1,{Position = UDim2.new(SatX,0,VibY,0)})
                            Tween(SaturationImage,0.1,{ImageColor3 = Color3.fromHSV(HueX,1,1)})
                            Tween(HuePointer,0.1,{Position = UDim2.new(HueX,0,0.5,0);BackgroundColor3 = Color3.fromHSV(HueX,1,1)})
                            Tween(DisplayFinalColor,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                        end)

                        ResetButton.MouseButton1Click:Connect(function()
                            HueX = SaveColor.H
                            SatX = SaveColor.S
                            VibY = SaveColor.V
                            Tween(ColorDisplay,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                            Tween(VibSatPointer,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                            Tween(VibSatPointer,0.1,{Position = UDim2.new(SatX,0,VibY,0)})
                            Tween(SaturationImage,0.1,{ImageColor3 = Color3.fromHSV(HueX,1,1)})
                            Tween(HuePointer,0.1,{Position = UDim2.new(HueX,0,0.5,0);BackgroundColor3 = Color3.fromHSV(HueX,1,1)})
                            Tween(DisplayFinalColor,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                            FinalColor = {HueX,SatX,1-VibY}
                            task.spawn(parameters.Callback,FinalColor)
                        end)


                        ApplyButton.MouseEnter:Connect(function()
                            Tween(ApplyButton,0.3,{BackgroundTransparency = 0})
                        end)

                        ApplyButton.MouseLeave:Connect(function()
                            Tween(ApplyButton,0.3,{BackgroundTransparency = 1})
                        end)

                        ResetButton.MouseEnter:Connect(function()
                            Tween(ResetButton,0.3,{BackgroundTransparency = 0})
                        end)

                        ResetButton.MouseLeave:Connect(function()
                            Tween(ResetButton,0.3,{BackgroundTransparency = 1})
                        end)

                        local HueSliding = HueSlider.InputBegan:Connect(function(key)
                            if key.UserInputType == Enum.UserInputType.MouseButton1 then
                                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                                    HueMin = HueSlider.AbsolutePosition.X
                                    HueMax = HueMin + HueSlider.AbsoluteSize.X
                                    HueX = ((math.clamp(Mouse.X,HueMin,HueMax) - HueMin) / (HueMax - HueMin))

                                    Tween(SaturationImage,0.1,{ImageColor3 = Color3.fromHSV(HueX,1,1)})
                                    Tween(ColorDisplay,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                                    Tween(VibSatPointer,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                                    Tween(HuePointer,0.1,{Position = UDim2.new(HueX,0,0.5,0);BackgroundColor3 = Color3.fromHSV(HueX,1,1)})
                                    FinalColor = hsvToRgb(HueX,SatX,1-VibY)
                                    Tween(DisplayFinalColor,0.1,{BackgroundColor3 = FinalColor})
                                    task.wait()
                                end
                            end
                        end)

                        Tween(ColorDisplay,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                        Tween(VibSatPointer,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})
                        Tween(VibSatPointer,0.1,{Position = UDim2.new(SatX,0,VibY,0)})
                        Tween(SaturationImage,0.1,{ImageColor3 = Color3.fromHSV(HueX,1,1)})
                        Tween(HuePointer,0.1,{Position = UDim2.new(HueX,0,0.5,0);BackgroundColor3 = Color3.fromHSV(HueX,1,1)})
                        Tween(DisplayFinalColor,0.1,{BackgroundColor3 = Color3.fromHSV(HueX,SatX,1-VibY)})

                        task.delay(1,function()
                            ColorPickerModal.Position = UDim2.new(0,ColorDisplay.AbsolutePosition.X + 50,0,ColorPicker.AbsolutePosition.Y)
                        end)

                        BackgroundDarken.MouseButton1Click:Connect(function(input)
                            if not UI.AgreementModalActive then    
                                ColorPickerModal.Position = UDim2.new(0,ColorDisplay.AbsolutePosition.X + 50,0,ColorPicker.AbsolutePosition.Y)
                                task.delay(0.3,function()
                                    ColorPickerModal.Visible = false
                                    BackgroundDarken.Visible = false
                                end)
                                Tween(BackgroundDarken,0.3,{BackgroundTransparency = 1})
                                Tween(ColorPickerModalBackground,0.3,{GroupTransparency = 1})
                                Tween(ColorPickerModal.Shadow,0.3,{ImageTransparency = 1})
                            end
                        end)



                        ColorPicker.MouseButton1Click:Connect(function()
                            SaveColor = {
                                H = HueX,
                                S = SatX,
                                V = VibY
                            }
                            ColorPickerModal.Position = UDim2.new(0,ColorDisplay.AbsolutePosition.X + 50,0,ColorPicker.AbsolutePosition.Y)
                            ColorPickerModal.Visible = true
                            BackgroundDarken.Visible = true
                            Tween(BackgroundDarken,0.3,{BackgroundTransparency = 0.5})
                            Tween(ColorPickerModalBackground,0.3,{GroupTransparency = 0})
                            Tween(ColorPickerModal.Shadow,0.3,{ImageTransparency = 0.29})
                        end)

                        return setmetatable(parameters,
                    {
                        __index = function(self,key)
                            if key == "Color" then
                                return Color3.fromHSV(HueX,SatX,1-VibY)
                            end
                        end
                    })
                    elseif parameters.Type == "Slider" then

                            -- Создание контейнера
                    local SliderFrame = Create("Frame", {
                        Parent = WindowContents,
                        Size = UDim2.new(1, 0, 0, 58),
                        BackgroundColor3 = UI.Theme.Primary.Secondary,
                        CornerRadius = UDim.new(0, 8)
                    })

                    local Label = Create("TextLabel",{
                        Parent= SliderFrame,
                        Name = parameters.Name,
                        Text = parameters.Name,
                        TextSize = 18,
                        RichText = true,
                        FontFace = UI.Theme.Text.Font,
                        TextColor3 = UI.Theme.Text.Primary,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0,0,0,18),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Position = UDim2.new(0,8,0,4),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4
                    })

                    if parameters.ToolTip then
                        UI.ToolTip({
                            Text = parameters.ToolTip,
                            Parent = SliderFrame,
                        })
                    end


                    local ValueLabel = Create("TextLabel",{
                        Parent= SliderFrame,
                        Name = 'ValueLabel',
                        Text = parameters.Value,
                        TextSize = 16,
                        RichText = true,
                        FontFace = UI.Theme.Text.Font,
                        TextColor3 = UI.Theme.Text.Primary,
                        BackgroundTransparency = 0,
                        BackgroundColor3 = UI.Theme.Primary.Background,
                        Size = UDim2.new(0,38,0,18),
                        Position = UDim2.new(1,-44,0,4),
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 4,
                        CornerRadius = UDim.new(0,5)
                    })


                    local ValuaPadding = Create("UIPadding",{
                        Parent = ValueLabel,
                        Name = "Padding",
                        PaddingTop = UDim.new(0,8),
                        PaddingBottom = UDim.new(0,8),
                        PaddingLeft = UDim.new(0,8),
                        PaddingRight = UDim.new(0,8)
                    })


                    local MinMaxLabel = Create("TextLabel",{
                        Parent= SliderFrame,
                        Name = "MinMaxLabel",
                        Text = parameters.Min .. " - " .. parameters.Max,
                        TextSize = 16,
                        RichText = true,
                        FontFace = UI.Theme.Text.Font,
                        TextColor3 = UI.Theme.Text.Secondary,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0,50,0,18),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        Position = UDim2.new(0,8,0,22),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4
                    })

                    local ProgressBackground = Create("Frame",{
                        Parent = SliderFrame,
                        Size = UDim2.new(1,-16,0,4),
                        AnchorPoint = Vector2.new(0.5,0),
                        Position = UDim2.new(0.5,0,1,-12),
                        BackgroundColor3 = UI.Theme.Border.Dark,
                        CornerRadius = UDim.new(1,0)
                    })

                    -- Индикатор прогресса
                    local ProgressBar = Create("Frame", {
                        Parent = ProgressBackground,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundColor3 = UI.Theme.Primary.Accent,
                        CornerRadius = UDim.new(1, 0)
                    })

                    local ProgressCircle = Create("Frame", {
                        Parent = ProgressBar,
                        Size = UDim2.new(0, 8, 0, 8),
                        AnchorPoint = Vector2.new(0,0.5),
                        Position = UDim2.new(1,-4,0.5,0),
                        BackgroundColor3 = UI.Theme.Primary.Background,
                        CornerRadius = UDim.new(1, 0),
                        Stroke = {
                            Thickness = 2,
                            Color = UI.Theme.Border.Dark
                        }
                    })


                    SliderFrame.MouseEnter:Connect(function()
                        Tween(ProgressCircle.Stroke,0.3,{Color = UI.Theme.Primary.Accent})
                        Tween(ProgressBackground,0.3,{BackgroundColor3 = UI.Theme.Border.Dark})
                    end)

                    SliderFrame.MouseLeave:Connect(function()
                        Tween(ProgressBackground,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                        Tween(ProgressCircle.Stroke,0.3,{Color = UI.Theme.Border.Dark})
                    end)

                    parameters.UpdateSlider = function(val)
                        local percent = (Mouse.X - ProgressBar.AbsolutePosition.X) / ProgressBar.AbsoluteSize.X

                        if val then
                            percent = (val - parameters.Min) / (parameters.Max - parameters.Min)
                        end

                        percent = math.clamp(percent, 0, 1)

                        ProgressBar:TweenSize(UDim2.new(percent, 0, 1, 0),"Out","Sine",0.1,true)
                        parameters.Value = val
                        ValueLabel.Text = (parameters.Prompt and parameters.Value .. parameters.Prompt) or parameters.Value
				    end


                    parameters.UpdateSlider(parameters.Value)

                    local IsSliding,Dragging = false
                    local RealValue = parameters.Value
                    local value
                    local function move(Pressed)
                        IsSliding = true;
                        local pos = UDim2.new(math.clamp((Pressed.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1), 0, 1, 0)
                        local size = UDim2.new(math.clamp((Pressed.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1), 0, 1, 0)
                        ProgressBar:TweenSize(size, "Out", "Quint", 0.1,true);
                        RealValue = (((pos.X.Scale * parameters.Max) / parameters.Max) * (parameters.Max - parameters.Min) + parameters.Min)
                        parameters.Value = tonumber((parameters.float and string.format("%.2f", tostring(RealValue))) or (math.floor(RealValue)))
                        ValueLabel.Text = (parameters.Prompt and parameters.Value .. parameters.Prompt) or parameters.Value
                        task.spawn(parameters.Callback,parameters.Value)
                    end



                    SliderFrame.InputBegan:Connect(function(Pressed)
                        if Pressed.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = true
                            IsSliding = false
                            move(Pressed)
                            UI.SliderActive = true
                        end
                    end)

                    SliderFrame.InputEnded:Connect(function(Pressed)
                        if Pressed.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = false
                            IsSliding = false
                            move(Pressed)
                            UI.SliderActive = false
                        end
                    end)

                    game:GetService("UserInputService").InputChanged:Connect(function(Pressed)
                        if Dragging and Pressed.UserInputType == Enum.UserInputType.MouseMovement then
                            move(Pressed)
                        end
                    end)

                    elseif parameters.Type == "Dropdown" then
                        local DropdownOpened = false
                        UI.DropdownOpened = false
                        parameters.Active = parameters.Active or true
                        parameters.Selected = parameters.Selected or nil
                        local Dropdown = Create("Frame",{
                            Parent = WindowContents,
                            Name = parameters.Name.. "_Dropdown",
                            BackgroundTransparency = 1,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,0,46),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            ZIndex = 3,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10},
                                ZIndex = 1
                            }
                        })



                        UI.Elements[parameters.Name] = Dropdown

                        local Label = Create("TextLabel",{
                            Parent= Dropdown,
                            Name = parameters.Name,
                            Text = parameters.Name,
                            TextSize = 18,
                            RichText = true,
                            FontFace = UI.Theme.Text.Font,
                            TextColor3 = UI.Theme.Text.Primary,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1,-16,1,0),
                            AutomaticSize = Enum.AutomaticSize.Y,
                            Position = UDim2.new(0,16,0,0),
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 4
                        })

                        if parameters.ToolTip then
                            UI.ToolTip({
                                Text = parameters.ToolTip,
                                Parent = Dropdown,
                            })
                        end

                        local DropdownButton = Create("TextButton",{
                            Parent = Dropdown,
                            Name = parameters.Name.. "_Dropdown",
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            Size = UDim2.new(1,0,0,46),
                            BorderSizePixel = 0,
                            CornerRadius = UDim.new(0,8),
                            Text = "",
                            ZIndex = 3,
                        })

                        



                        local Arrow_Icon = Create("ImageLabel",{
                            Parent = DropdownButton,
                            Size = UDim2.new(0,28,0,28),
                            AnchorPoint = Vector2.new(0,0.5),
                            Position = UDim2.new(1,-36,0.5,0),
                            BackgroundTransparency = 1,
                            Image = "rbxassetid://88354548118486",
                            ImageColor3 = UI.Theme.Border.Dark,
                            Rotation = 0
                        })


                        Dropdown.MouseEnter:Connect(function()
                            Tween(DropdownButton,0.3,{BackgroundColor3 = (DropdownOpened and UI.Theme.Primary.Secondary or UI.Theme.Primary.Secondary)})
                            Tween(Dropdown.Shadow,0.3,{ImageTransparency = (DropdownOpened and 1 or 0.29)})
                        end)
    
                        Dropdown.MouseLeave:Connect(function()
                            Tween(DropdownButton,0.3,{BackgroundColor3 = (DropdownOpened and UI.Theme.Primary.Secondary or UI.Theme.Primary.Secondary)})
                            Tween(Dropdown.Shadow,0.3,{ImageTransparency = (DropdownOpened and 1 or 1)})
                        end)

                        local DropdownModal = Create("CanvasGroup",{
                            Parent = SG,
                            AnchorPoint = Vector2.new(0,0),
                            Position = UDim2.new(0,Dropdown.AbsolutePosition.X,0,Dropdown.AbsolutePosition.Y + Dropdown.AbsoluteSize.Y - (Dropdown.AbsoluteSize.Y / 2)),
                            Size = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 16,264),
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            GroupTransparency = 1,
                            CornerRadius = UDim.new(0,8),
                            Stroke = {
                                Thickness = 1,
                                Color = UI.Theme.Border.Dark,
                                Transparency = 1
                            },
                            ZIndex = 2,
                            Visible = false,
                        })


                        local ModalBackground = Create("TextButton",{
                            Parent = SG,
                            AnchorPoint = Vector2.new(0,0),
                            Position = UDim2.new(0,0,0,-4),
                            Size = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,54),
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            BackgroundTransparency = 1,
                            CornerRadius = UDim.new(0,8),
                            Stroke = {
                                Thickness = 1,
                                Color = UI.Theme.Border.Dark,
                                Transparency = 1
                            },
                            ZIndex = 1,
                            BoxShadow = {
                                Transparency = 1,
                                Color = UI.Theme.Border.Dark,
                                Padding = {0,0},
                                Size = {10,10}
                            },
                            Text = ""
                        })

                        local ListSearchBox = Create("TextBox",{
                            Parent = DropdownModal,
                            BackgroundTransparency = 1,
                            FontFace = UI.Theme.Text.Font,
                            Text = "",
                            Position = UDim2.new(0,8,0,8),
                            Size = UDim2.new(1,-16,0,34),
                            ZIndex = 2,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextColor3 = UI.Theme.Text.Primary,
                            TextSize = 20,
                            ClearTextOnFocus = true,
                            PlaceholderText = "Search",
                            PlaceholderColor3 = UI.Theme.Text.Secondary,
                        })


                        local Divider = Create("Frame",{
                            Parent = DropdownModal,
                            Size = UDim2.new(1,-16,0,1),
                            Position = UDim2.new(0,8,0,50),
                            AnchorPoint = Vector2.new(0,0),
                            BackgroundColor3 = UI.Theme.Border.Dark
                        })


                        local DropdownContents = Create("ScrollingFrame",{
                            Parent = DropdownModal,
                            AnchorPoint = Vector2.new(0.5,0),
                            Position = UDim2.new(0.5,0,0,56),
                            Size = UDim2.new(1,0,1,-64),
                            BackgroundTransparency = 1,
                            ZIndex = 4,
                            ScrollBarThickness = 2,
                            ScrollBarImageColor3 = UI.Theme.Primary.Hover,
                            CanvasSize = UDim2.new(0,0,0,0),
                            AutomaticCanvasSize = Enum.AutomaticSize.Y
                        })

                        ListSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                            for i,v in next,DropdownContents:GetChildren() do 
                                if v:IsA("TextButton") and string.find(string.upper(v.Name),string.upper(ListSearchBox.Text)) then 
                                    v.Visible = true
                                elseif not string.find(string.upper(v.Name), string.upper(ListSearchBox.Text)) and v:IsA("TextButton") then
                                    v.Visible = false
                                end
                            end
                        end)

                        if parameters.Switchable then
                            local OuterCircle = Create("TextButton",{
                                Parent = DropdownButton,
                                Size = UDim2.new(0,40,0,20),
                                AnchorPoint = Vector2.new(0,0.5),
                                Position = UDim2.new(1,-90,0.5,0),
                                BackgroundTransparency = 0,
                                BackgroundColor3 = UI.Theme.Primary.Background,
                                CornerRadius = UDim.new(1,0),
                                Text = "",
                                ZIndex = 2,
                                BoxShadow = {
                                    Transparency = 1,
                                    Color = UI.Theme.Primary.Accent,
                                    Padding = {0,0},
                                    Size = {8,10},
                                },
                            })
                        
                        
                            local InnerCircle = Create("Frame",{
                                Parent = OuterCircle,
                                Size = UDim2.new(0,14,0,14),
                                AnchorPoint = Vector2.new(0,0.5),
                                Position = UDim2.new(0,8,0.5,0),
                                BackgroundTransparency = 0,
                                CornerRadius = UDim.new(1,0),
                                BackgroundColor3 = UI.Theme.Border.Dark,
                                Stroke = {
                                    Thickness = 1,
                                    Color = UI.Theme.Border.Dark,
                                    Transparency = 1
                                },
                                ZIndex = 2
                            })
                            local function UpdateVisual(boolean)
                                UI.Instances[OuterCircle]["BackgroundColor3"] = (boolean and UI.Theme.Primary.Accent or UI.Theme.Primary.Background)
                                UI.Instances[InnerCircle]['BackgroundColor3'] = (boolean and UI.Theme.Primary.Background or UI.Theme.Border.Dark)
                                Tween(InnerCircle,0.3,{Position = (boolean and UDim2.new(1,-20,0.5,0) or UDim2.new(0,4,0.5,0)) ; BackgroundColor3 = (boolean and UI.Theme.Primary.Background or UI.Theme.Border.Dark)},"Back")
                                Tween(InnerCircle,0.3,{Size = (boolean and UDim2.new(0,20,0,10) or UDim2.new(0,26,0,6))})
                                Tween(OuterCircle,0.3,{BackgroundColor3 = (boolean and UI.Theme.Primary.Accent or UI.Theme.Primary.Background)})
                                Tween(OuterCircle.Shadow,0.3,{ImageTransparency = (boolean and 0.29 or 1)})
                                task.delay(0.1,function()
                                    Tween(InnerCircle,0.3,{Size =(boolean and UDim2.new(0,16,0,16) or UDim2.new(0,14,0,14))})
                                end)
                            end

                            UpdateVisual(parameters.Active)
                        
                        
                            OuterCircle.MouseButton1Click:Connect(function()
                                parameters.Active = not parameters.Active
                                UpdateVisual(parameters.Active)
                                if DropdownOpened then
                                    DropdownOpened = false
                                    task.delay(0.3,function()
                                        if DropdownOpened == false then
                                            DropdownModal.Visible = false
                                        end
                                    end)
                                end
                                task.delay(0.3,function()
                                    if DropdownOpened == false then
                                        DropdownModal.Visible = false
                                    end
                                end)
                                Tween(Dropdown.Shadow,0.3,{ImageTransparency = 0.29})
                                Tween(Arrow_Icon,0.3,{Rotation = 0})
                                Tween(DropdownButton,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                                Tween(DropdownModal,0.5,{GroupTransparency = 1})
                                Tween(DropdownModal,0.3,{Size = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,54)},"Back")
                                Tween(ModalBackground.Shadow,0.5,{ImageTransparency = 1})
                                Tween(ModalBackground,0.3,{Size = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,54)},"Back")
                            end)
                        end


                        for i = 1,2 do
                            Create('Frame',{
                                Parent = DropdownContents,
                                Size = UDim2.new(0,0,0,4),
                                BackgroundTransparency = 1,
                                LayoutOrder = (i == 1 and -999 or 999)
                            })
                        end

                        local DropdownOptionsLayout = Create("UIListLayout",{
                            Parent = DropdownContents,
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            Padding = UDim.new(0,8),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })

                        local ModalSize = UDim2.new(0,Dropdown.AbsoluteSize.X + 8,54,0)
                        for i,v in next,parameters.Options do
                            ModalSize += UDim2.new(0,0,0,54)
                        end

                        if ModalSize.Y.Offset < 224 then
                            ModalSize = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,264)
                        elseif ModalSize.Y.Offset > 224 then
                            ModalSize = UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,304)
                        end


                        local ToolsModal = Create("CanvasGroup",{
                            Parent = SG,
                            Name = "ToolsModal",
                            Size = UDim2.new(0,150,0,80),
                            BackgroundColor3 = UI.Theme.Primary.Background,
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0,Mouse.X,0,Mouse.Y),
                            GroupTransparency = 1,
                            ZIndex = 100,
                        })



                        local ToolsContents = Create("CanvasGroup",{
                            Parent = ToolsModal,
                            Size = UDim2.new(1,-8,0,0),
                            AnchorPoint = Vector2.new(0.5,0.5),
                            Position = UDim2.new(0.5,0,0.5,0),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = UI.Theme.Primary.Secondary,
                            ZIndex = 100,
                            CornerRadius = UDim.new(0,18),
                            Stroke = {
                                Color = UI.Theme.Primary.Accent,
                                Thickness = 1,
                            },
                            AutomaticSize = Enum.AutomaticSize.Y
                        })


                        local ToolsList = Create("UIListLayout",{
                            Parent = ToolsContents,
                            FillDirection = Enum.FillDirection.Vertical,
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            VerticalAlignment = Enum.VerticalAlignment.Top,
                            Padding = UDim.new(0,0),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })


                        local Tools = {
                            ['Select all'] = Create("TextButton",{
                                Parent = ToolsContents,
                                Name = "Copy",
                                Text = "Select All",
                                TextSize = 16,
                                RichText = true,
                                FontFace = UI.Theme.Text.Font,
                                TextColor3 = UI.Theme.Text.Primary,
                                BackgroundTransparency = 1, 
                                BackgroundColor3 = UI.Theme.Primary.Hover,
                                Size = UDim2.new(1,0,0,36),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                Position = UDim2.new(0,8,0,0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 6,
                                Visible = (parameters.Multiple and true or false),
                                LayoutOrder = 1
                            }),
                            Divider = Create("Frame",{
                                Parent = ToolsContents,
                                Size = UDim2.new(1,0,0,1),
                                BackgroundColor3 = UI.Theme.Border.Dark,
                                BorderSizePixel = 0,
                                LayoutOrder = 2,
                                Visible = Multiple and true or false
                            }),
                            ['Deselect all'] = Create("TextButton",{
                                Parent = ToolsContents,
                                Name = "Paste",
                                Text = "Deselect All",
                                TextSize = 16,
                                RichText = true,
                                FontFace = UI.Theme.Text.Font,
                                TextColor3 = UI.Utility.Error,
                                BackgroundTransparency = 1, 
                                BackgroundColor3 = UI.Theme.Primary.Hover,
                                Size = UDim2.new(1,0,0,36),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                Position = UDim2.new(0,8,0,0),
                                TextXAlignment = Enum.TextXAlignment.Center,
                                ZIndex = 6,
                                Visible = true,
                                LayoutOrder = 3
                            }),
                        }


                        local function UpdateVisual(instan,val)
                            if val then
                                UI.Instances[instan['Toggle']].BackgroundColor3 = UI.Theme.Primary.Accent
                                Tween(instan,0.3,{TextColor3 = UI.Theme.Text.Primary})
                                Tween(instan,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                                Tween(instan.Toggle.ToggleIcon,0.3,{ImageTransparency = 0; Size = UDim2.new(1,-4,1,-4)})
                                Tween(instan.Toggle,0.3,{BackgroundColor3 = UI.Theme.Primary.Accent})
                                Tween(instan.Toggle.Shadow,0.3,{ImageTransparency = 0.29})
                            else
                                UI.Instances[instan['Toggle']].BackgroundColor3 = UI.Theme.Primary.Background
                                Tween(instan,0.3,{TextColor3 = UI.Theme.Text.Secondary})
                                Tween(instan,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                                Tween(instan.Toggle.ToggleIcon,0.3,{ImageTransparency = 1; Size = UDim2.new(1,-12,1,-4)})
                                Tween(instan.Toggle,0.3,{BackgroundColor3 = UI.Theme.Primary.Background})
                                Tween(instan.Toggle.Shadow,0.3,{ImageTransparency = 1})
                            end
                        end
                        

                        Tools['Select all'].MouseEnter:Connect(function()
                            Tween(Tools['Select all'],0.3,{BackgroundTransparency = 0})
                        end)

                        
                        Tools['Select all'].MouseLeave:Connect(function()
                            Tween(Tools['Select all'],0.3,{BackgroundTransparency = 1})
                        end)

                        Tools['Deselect all'].MouseEnter:Connect(function()
                            Tween(Tools['Deselect all'],0.3,{BackgroundTransparency = 0})
                        end)

                        Tools['Deselect all'].MouseLeave:Connect(function()
                            Tween(Tools['Deselect all'],0.3,{BackgroundTransparency = 1})
                        end)

                        Tools['Select all'].MouseButton1Click:Connect(function()
                            for i,v in next, parameters.Options do
                                parameters.Options[i] = true

                                UpdateVisual(DropdownContents:FindFirstChild(i),true)
                            end
                            task.wait()
                            task.spawn(parameters.Callback,parameters.Options)
                        end)


                        Tools['Deselect all'].MouseButton1Click:Connect(function()
                            for i,v in next, parameters.Options do
                                parameters.Options[i] = false
                                UpdateVisual(DropdownContents:FindFirstChild(i),false)
                            end
                        end)


                        ToolsModal.MouseLeave:Connect(function()
                            Tween(ToolsModal,0.3,{GroupTransparency = 1})
                            task.delay(0.3,function()
                                ToolsModal.Visible = false
                            end)
                        end)


                        DropdownButton.MouseButton2Click:Connect(function()
                            ToolsModal.Visible = true
                            Tween(ToolsModal,0.2,{
                                Position = UDim2.new(0,Mouse.X - (ToolsModal.AbsoluteSize.X / 2) , 0,Mouse.Y),
                                GroupTransparency = 0
                            })
                        end)
                        Window:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
                            ModalBackground.Position = UDim2.new(0,Dropdown.AbsolutePosition.X - ((DropdownModal.AbsoluteSize.X - Dropdown.AbsoluteSize.X) / 4), 0, Dropdown.AbsolutePosition.Y + (Dropdown.AbsoluteSize.Y * 2) + 18)
                            DropdownModal.Position = UDim2.new(0,Dropdown.AbsolutePosition.X - ((DropdownModal.AbsoluteSize.X - Dropdown.AbsoluteSize.X) / 4), 0, Dropdown.AbsolutePosition.Y + (Dropdown.AbsoluteSize.Y * 2) + 18)
                        end)

                        DropdownModal.Visible = false
                        ModalBackground.Visible = false
                        ModalBackground.Active = false
                        ModalBackground.Modal = true

                        DropdownButton.MouseButton1Click:Connect(function()
                            if not parameters.Active then
                                Tween(Dropdown.Shadow,0.3,{ImageColor3 = UI.Utility.Error; ImageTransparency = 0.19})
                                task.delay(0.6,function()
                                    Tween(Dropdown.Shadow,0.3,{ImageColor3 = UI.Theme.Border.Dark; ImageTransparency = 0.29})
                                end)
                            return end
                            ModalBackground.Position = UDim2.new(0,Dropdown.AbsolutePosition.X - ((DropdownModal.AbsoluteSize.X - Dropdown.AbsoluteSize.X) / 4), 0, Dropdown.AbsolutePosition.Y + (Dropdown.AbsoluteSize.Y * 2) + 18)
                            DropdownModal.Position = UDim2.new(0,Dropdown.AbsolutePosition.X - ((DropdownModal.AbsoluteSize.X - Dropdown.AbsoluteSize.X) / 4), 0, Dropdown.AbsolutePosition.Y + (Dropdown.AbsoluteSize.Y * 2) + 18)
                            DropdownOpened = not DropdownOpened
                            UI.DropdownOpened = DropdownOpened
                            if DropdownOpened then
                                DropdownModal.Visible = true
                                ModalBackground.Visible = true
                                ModalBackground.Active = true
                            else
                                task.delay(0.15,function()
                                    DropdownModal.Visible = false
                                    ModalBackground.Visible = false
                                    ModalBackground.Active = false
                                end)
                            end
                            task.delay((DropdownOpened and 0 or 0.3),function()
                                Dropdown.ZIndex = (DropdownOpened and 4 or 3)
                                Window.ZIndex = DropdownOpened and 4 or 1
                            end)
                            Tween(Dropdown.Shadow,0.3,{ImageTransparency = (DropdownOpened and 1 or 0.29)})
                            Tween(Arrow_Icon,0.3,{Rotation = (DropdownOpened and 90 or 0)})
                            Tween(DropdownButton,0.3,{BackgroundColor3 = (DropdownOpened and UI.Theme.Primary.Secondary or UI.Theme.Primary.Secondary)})
                            Tween(DropdownModal,0.3,{GroupTransparency = (DropdownOpened and 0 or 1)})
                            Tween(DropdownModal,0.3,{Size = (DropdownOpened and UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,ModalSize.Y.Offset) or UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,54))},"Back")
                            Tween(ModalBackground.Shadow,0.3,{ImageTransparency = (DropdownOpened and 0.2 or 1)})
                            Tween(ModalBackground,0.3,{Size = (DropdownOpened and UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,ModalSize.Y.Offset) or UDim2.fromOffset(Dropdown.AbsoluteSize.X + 8,54))},"Back")
                        end)


                        local OptionsKeys = {}

                        for key,value in next,parameters.Options do
                            table.insert(OptionsKeys,key)
                            if value == true and not parameters.Multiple then
                                parameters.Selected = key
                            end
                        end

                        local function GetIndex(array,key)
                            for index,key in next,OptionsKeys do
                                if key == key then
                                    return index
                                end
                            end
                        end

                        parameters.UpdateOptions = function(opts)
                            for i,v in next,DropdownContents:GetChildren() do
                                if v:IsA("TextButton") then
                                    v:Destroy()
                                end
                            end
                            parameters.Options = opts
                            for i,v in pairs(parameters.Options) do
                                local Option = Create("TextButton",{
                                    Parent= DropdownContents,
                                    Name = i,
                                    Text = "  " .. i,
                                    TextSize = 18,
                                    RichText = false,
                                    FontFace = UI.Theme.Text.Font,
                                    TextColor3 = UI.Theme.Text.Secondary,
                                    BackgroundTransparency = 0.5, 
                                    BackgroundColor3 = UI.Theme.Primary.Secondary,
                                    Size = UDim2.new(1,-16,0,46),
                                    AutomaticSize = Enum.AutomaticSize.Y,
                                    Position = UDim2.new(0,16,0,0),
                                    TextXAlignment = Enum.TextXAlignment.Left,
                                    ZIndex = 6,
                                    CornerRadius = UDim.new(0,8),
                                })
                                local index = GetIndex(OptionsKeys,i)

                                local Toggle = Create("Frame",{
                                    Parent = Option,
                                    Name = "Toggle",
                                    Size = UDim2.new(0,24,0,24),
                                    Position = UDim2.new(1,-36,0.5,0),
                                    AnchorPoint = Vector2.new(0,0.5),
                                    BackgroundColor3 = UI.Theme.Primary.Background,
                                    CornerRadius = UDim.new(0,8),
                                    BoxShadow = {
                                        Transparency = 1,
                                        Color = UI.Theme.Primary.Accent,
                                        Padding = {0,0},
                                        Size = {10,10}
                                    }
                                })

                                local ToggleIcon = Create("ImageLabel",{
                                    Parent = Toggle,
                                    Size = UDim2.new(1,-4,1,-4),
                                    Name = "ToggleIcon",
                                    AnchorPoint = Vector2.new(0.5,0.5),
                                    Position = UDim2.new(0.5,0,0.5,0),
                                    Image = "rbxassetid://76272566481022",
                                    ImageColor3 = UI.Theme.Primary.Background,
                                    BackgroundTransparency = 1,
                                    ImageTransparency = 1
                                })


                                Option.MouseEnter:Connect(function()
                                    Tween(Option,0.3,{BackgroundColor3 = UI.Theme.Primary.Hover})
                                end)

                                Option.MouseLeave:Connect(function()
                                    Tween(Option,0.3,{BackgroundColor3 = UI.Theme.Primary.Secondary})
                                end)

                                if parameters.Options[i] == true then
                                    UpdateVisual(Option,parameters.Options[i])
                                else
                                    parameters.Options[i] = false
                                    UpdateVisual(Option,false)
                                end
                                local defaultLabel = parameters.Name
                                Option.MouseButton1Click:Connect(function()
                                    if parameters.Multiple then
                                        parameters.Options[i] = not parameters.Options[i]
                                        if parameters.Callback then
                                            task.spawn(parameters.Callback,parameters.Options)
                                        end
                                        UpdateVisual(Option, parameters.Options[i])
                                    else
                                        for c,x in next,parameters.Options do
                                            if c ~= i then
                                                parameters.Options[c] = false
                                                local Option = DropdownContents:FindFirstChild(c)
                                                if Option then
                                                    UpdateVisual(Option, parameters.Options[c])
                                                end
                                            else
                                                parameters.Selected = i
                                                parameters.Options[i] = not parameters.Options[i]
                                                Label.Text = parameters.Options[c] and c or parameters.Name
                                                UpdateVisual(Option, parameters.Options[i])
                                                if parameters.Callback then
                                                    task.spawn(parameters.Callback,parameters.Options,parameters.Selected)
                                                end
                                            end
                                        end
                                    end
                                end)

                            end
                        end
                        parameters.UpdateOptions(parameters.Options)
                        return parameters
                    end
                end,
            }
        end
	}


UI.ActiveNotifications = {}

UI.Notification = function(parameters)
    -- Создаем контейнер для уведомлений, если его еще нет
    if not UI.NotificationContainer then
        UI.NotificationContainer = Create("Frame", {
            Parent = SG,
            Name = "NotificationContainer",
            Size = UDim2.new(0, 500, 1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0)
        })
    end

    local NotificationFrame = Create("CanvasGroup", {
        Parent = UI.NotificationContainer,
        Name = "Notification_" .. (parameters.Title or parameters.Content),
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = UI.Theme.Primary.Background,
        Stroke = {
            Thickness = 1,
            Color = UI.Theme.Border.Dark,
            Transparency = 1
        },
        GroupTransparency = 1,
        CornerRadius = UDim.new(0, 16),
        AutomaticSize = Enum.AutomaticSize.Y
    })

    local NotificationTitle = Create("TextLabel", {
        Parent = NotificationFrame,
        FontFace = UI.Theme.Text.Font,
        TextSize = 24,
        TextColor3 = UI.Theme.Text.Primary,
        Text = parameters.Title,
        Size = UDim2.new(1, -40, 0, 24),
        Position = UDim2.new(0, 58, 0, 4),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local NotificationContent = Create("TextLabel", {
        Parent = NotificationFrame,
        FontFace = UI.Theme.Text.Font,
        TextSize = 20,
        TextColor3 = UI.Theme.Text.Secondary,
        Text = parameters.Content,
        Size = UDim2.new(1, -66, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 58, 0, 28),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })


    local ImageCanvas = Create("Frame", {
        Parent = NotificationFrame,
        Size = UDim2.new(0, 38, 0, 38),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = UI.Theme.Primary.Secondary,
        CornerRadius = UDim.new(0, 8),
        BackgroundTransparency = 1,
        Stroke = {
            Thickness = 1,
            Color = UI.Theme.Border.Dark,
            Transparency = 1
        }
    })

    local NotificationIcon = Create("ImageLabel", {
        Parent = ImageCanvas,
        Size = UDim2.new(1, -8, 1, -8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Image = UI.Utility.Icons[parameters.Type or "Info"],
        ImageColor3 = UI.Utility[parameters.Type or "Info"],
        BackgroundTransparency = 1,
        ZIndex = 2
    })

    local Spacer = Create("Frame",{
        Parent = NotificationFrame,
        Size = UDim2.new(1,0,0,8),
        Position = UDim2.new(0,0,1,0),
        BackgroundTransparency = 1
    })

    local DurationProgressBar = Create("Frame",{
        Parent = NotificationFrame,
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = UI.Theme.Primary.Accent,
        CornerRadius = UDim.new(0, 2),
        ZIndex = 3
    })
    
    Tween(DurationProgressBar, parameters.Delay or 5, {
        Size = UDim2.new(0, 0, 0, 4)
    }, "Linear", "In")

    local IconGlow = Create("ImageLabel", {
        Parent = NotificationIcon,
        Size = UDim2.new(2.5, 0, 2.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Image = "rbxassetid://106069805139851",
        ImageColor3 = UI.Utility[parameters.Type or "Info"],
        BackgroundTransparency = 1,
        ImageTransparency = 0.6,
        ZIndex = 1
    })

    task.delay(0,function()
        -- Добавляем уведомление в список активных
        table.insert(UI.ActiveNotifications, NotificationFrame)
        
        -- Функция для обновления позиций всех уведомлений
        local function updateNotificationsPositions()
            local totalHeight = 0
            local spacing = 8
            
            -- Проходим по всем уведомлениям снизу вверх
            for i = #UI.ActiveNotifications, 1, -1 do
                local notification = UI.ActiveNotifications[i]
                if notification and notification.Parent then
                    local targetPosition = UDim2.new(0, 0, 0.9, -totalHeight)
                    
                    -- Анимируем только если позиция изменилась
                    if notification.Position ~= targetPosition then
                        Tween(notification, 0.3, {
                            Position = targetPosition
                        }, "Quint", "Out")
                    end
                    -- Учитываем высоту текущего уведомления и отступ
                    totalHeight = (totalHeight + notification.AbsoluteSize.Y + spacing)
                else
                    -- Удаляем несуществующие уведомления
                    table.remove(UI.ActiveNotifications, i)
                end
            end
        end
        
        -- Анимация появления
        NotificationFrame.Position = UDim2.new(0, 0, 0.9, -NotificationFrame.AbsoluteSize.Y)
        Tween(NotificationFrame, 0.6, {
            GroupTransparency = 0,
            Position = UDim2.new(0, 0,0.9, 0)
        }, "Quint", "Out")
        Tween(NotificationFrame.Stroke, 0.6, {Transparency = 0})
        
        -- Обновляем позиции всех уведомлений
        updateNotificationsPositions()
        
        -- Устанавливаем таймер исчезновения
        task.delay(parameters.Delay or 5, function()
            if NotificationFrame and NotificationFrame.Parent then
                -- Анимация исчезновения
                Tween(NotificationFrame, 0.6, {
                    GroupTransparency = 1,
                    Position = UDim2.new(0, 0, 0.9, -NotificationFrame.AbsoluteSize.Y)
                }, "Quint", "Out")
                Tween(NotificationFrame.Stroke, 0.6, {Transparency = 1})
                
                -- Удаляем после анимации
                task.delay(0.6, function()
                    if NotificationFrame and NotificationFrame.Parent then
                        NotificationFrame:Destroy()
                        
                        -- Удаляем из списка активных
                        for i, notif in ipairs(UI.ActiveNotifications) do
                            if notif == NotificationFrame then
                                table.remove(UI.ActiveNotifications, i)
                                break
                            end
                        end
                        
                        -- Обновляем позиции оставшихся уведомлений
                        updateNotificationsPositions()
                    end
                end)
            end
        end)
    end)
    
    return parameters;
end
	
	local function GetWindowDestPos(wind)
		local destX = (wind.AbsolutePosition.X>ScreenRes.X/2 and 1 or -0.3)
		local destY = (wind.AbsolutePosition.Y>ScreenRes.Y/2 and 1 or -0.3)
		return {destX, destY};
	end


    task.spawn(function()
        task.wait(0.1)
        Tween(Windows, 0.5, {GroupTransparency = UI.ActiveTransparency},"Linear")
        Tween(Background, 0.5, {GroupTransparency = 0},"Linear")
        for _,wind in pairs(WindowsData) do task.wait()
            local dest = (not UI.Opened and UDim2.new(GetWindowDestPos(wind.Instance)[1],0,GetWindowDestPos(wind.Instance)[2],0) or wind.AbsolutePosition)
            wind.Instance.Position = UDim2.new(GetWindowDestPos(wind.Instance)[1],0,GetWindowDestPos(wind.Instance)[2],0)
            Tween(wind.Instance,0,{Position = dest},"Quint","Out")
        end
    end)

	return Elements
end



return UI;
