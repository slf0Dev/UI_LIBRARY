local ChartLua = {}

local TweenService = game:GetService("TweenService");
local Mouse = game.Players.LocalPlayer:GetMouse();
local PlayerGui = game.Players.LocalPlayer.PlayerGui;
local InputService = game:GetService("UserInputService");

local StrokeProperties = {
	"Color","Thickness","Transparency"
}


local function Create(instance : string,properties : table)
	local Corner,Stroke
	local CreatedInstance = Instance.new(instance)

	if instance == "TextButton" or instance == "ImageButton" then
		CreatedInstance.AutoButtonColor = false
	end
	for property,value in next,properties do
		if tostring(property) ~= "CornerRadius" and tostring(property) ~= "Stroke" then
			CreatedInstance[property] = value
		elseif tostring(property) == "Stroke" then
			local StrokeProperties = {
				Color = value['Color'],
				Thickness = value['Thickness'],
				Transparency = value['Transparency'] or 0
			}
			Stroke = Instance.new("UIStroke",CreatedInstance)
			Stroke.Name = "Stroke"
			Stroke.Color = value["Color"]
			Stroke.Thickness = value["Thickness"]
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			Stroke.Transparency = value["Transparency"]
			Stroke.LineJoinMode = Enum.LineJoinMode.Round
			local Props = {}
			for i,v in next,StrokeProperties do
				Props[i] = v
			end
			task.delay(0,function()
				UI['Instances'][Stroke] = Props
			end)
		elseif tostring(property) == "CornerRadius" then
			Corner = Instance.new("UICorner",CreatedInstance)
			Corner.Name = "Corner"
			Corner.CornerRadius = value
		end
		UI['Instances'][CreatedInstance] = properties
	end


	return CreatedInstance;
end
local Pindex = 0


local tangents = {}

local ltg = UDim2.new(0,-30,0,0)
local rtg = UDim2.new(0,30,0,0)


function AddPoint(Point,ind,Par)
	Par:InsertControlPoint(ind,Path2DControlPoint.new(Point,ltg,rtg))
end


local function Tween(instance, time, properties,EasingStyle,EasingDirection)
	local tw = TweenService:Create(instance, TweenInfo.new(time, EasingStyle and Enum.EasingStyle[EasingStyle] or Enum.EasingStyle.Quad,EasingDirection and Enum.EasingDirection[EasingDirection] or Enum.EasingDirection.Out), properties)
	task.delay(0, function()
		tw:Play()
	end)
	return tw
end


ChartLua.Chart = function(parameters : table)
    local Chart = Create("Frame",{
        Parent = parameters.Parent,
        Name = parameters.Name.. "_Chart",
        Stroke = {
			Thickness = 1,
			Color = UI.Theme.Border.Dark,
			Transparency = 1
		},
		BackgroundTransparency = 0,
		BackgroundColor3 = UI.Theme.Primary.Secondary,
        Size = parameters.Size,
		BorderSizePixel = 0,
		CornerRadius = UDim.new(0,8),
    })

	UI.Elements[parameters.Name] = Chart

	local Label = Create("TextLabel",{
		Parent= Chart,
		Name = parameters.Name,
		Text = '<font weight="500">' .. parameters.Name .. "</font>",
		TextSize = 20,
		RichText = true,
		FontFace = UI.Theme.Text.Font,
		TextColor3 = UI.Theme.Text.Primary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1,-16,0,0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0,10,0,8),
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local GraphContents = Create("Frame", {
		Parent = Chart,
		Name = "Contents",
		Size = UDim2.new(1,-28,1,-48),
		Position = UDim2.new(0,14,0,38),
		BackgroundTransparency = 1
	})

	local Graph = Create("Path2D",{
		Parent = GraphContents,
		Name = "Chart_Graph",
		Thickness = 2,
		Color3 = UI.Theme.Primary.Accent,
		ZIndex = 1
	})


	local ToolTip = Create("Frame",{
		Parent = GraphContents,
		Size = UDim2.new(0,0,0,0),
		BackgroundColor3 = UI.Theme.Primary.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5,0.5),
		CornerRadius = UDim.new(0,5),
		ZIndex = 3,
	})

	local ToolTipLabel = Create("TextLabel", {
		Parent = ToolTip,
		Name = "ddd",
		Text = "0",
		TextSize = 12,
		FontFace = UI.Theme.Text.Font,
		BackgroundColor3 = UI.Theme.Primary.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(0.5,0.5),
		CornerRadius = UDim.new(0,5),
		Position = UDim2.new(0.5,0,0.5,0),
		ZIndex = 4,
		TextColor3 = UI.Theme.Primary.Background,
		TextTransparency = 1
	})

	local points = {}
	local ToolTips = {}
	local realpoints = {}

	local minVal = math.min(table.unpack(parameters.Dataset))
	local maxVal = math.max(table.unpack(parameters.Dataset))


	local function NewTooltip(i,val,pos,x,y)
		local created = {}
		if parameters.PointsEnabled then
			local RealPoint = Create("Frame",{
				Parent= GraphContents,
				Name = i.. "_Point",
				BackgroundTransparency = 0,
				BackgroundColor3 = UI.Theme.Primary.Accent,
				Size = UDim2.new(0,6,0,6),
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(x,i==1 and 15 or 0,y,0),
				CornerRadius = UDim.new(1,0)
			})
			table.insert(created,RealPoint)
		end

		if parameters.ToolTip then
			local VirtualPoint = Create("Frame",{
				Parent= GraphContents,
				Name = i .. "_VirtualPoint",
				BackgroundTransparency = 1,
				BackgroundColor3 = UI.Theme.Primary.Accent,
				Size = UDim2.new(0,24,0,24),
				AnchorPoint = Vector2.new(0.5,0.5),
				Position = UDim2.new(x,i==1 and 15 or 0,y,0),
				ZIndex = 2
			})


			local PointLabel = Create("TextLabel",{
				Parent= GraphContents,
				Name = i .. "_PointLabel",
				Text = val,
				TextSize = 12,
				FontFace = UI.Theme.Text.Font,
				BackgroundColor3 = UI.Theme.Primary.Background,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0.5,0.5),
				CornerRadius = UDim.new(0,5),
				Position = UDim2.new(x,i==1 and 15 or 0,y,-10),
				ZIndex = 4,
				TextColor3 = UI.Theme.Text.Primary,
				TextTransparency = 1
			})

			table.insert(created,PointLabel)
			table.insert(created,VirtualPoint)
			VirtualPoint.MouseEnter:Connect(function()
				ToolTipLabel.Text = PointLabel.Text
				Tween(ToolTip,0.2,{BackgroundTransparency = 0; Position = PointLabel.Position ; Size = UDim2.new(0,PointLabel.TextBounds.X,0,PointLabel.TextBounds.Y) + UDim2.new(0,12,0,8)})
				Tween(ToolTipLabel,0.3,{TextTransparency = 0})
			end)

			VirtualPoint.MouseLeave:Connect(function()
				Tween(ToolTip,0.2,{BackgroundTransparency = 1; Position = PointLabel.Position})
				Tween(ToolTipLabel,0.3,{TextTransparency = 1;BackgroundTransparency = 1})
			end)
		end
		return created;
	end
	if parameters.Type == "Line" then
		for i,v in next,parameters.Dataset do
			local NormalVal = 1 - (v - minVal) / (maxVal - minVal)
			local PointDataX = (i-1) / (#parameters.Dataset - 1)
			local PointDataY = NormalVal

			local Higher = UDim2.new(0,0,0,0)
			local Lower = UDim2.new(0,0,0,0)

			if i-1 >= 1 then
				Lower = (parameters.Dataset[i] > parameters.Dataset[i-1] and UDim2.new(0,0,0,-10) or UDim2.new(0,0,0,10))
			elseif i+1 <= #parameters.Dataset then
				Higher = (parameters.Dataset[i] > parameters.Dataset[i+1] and UDim2.new(0,0,0,10) or UDim2.new(0,0,0,-10))
			end
			
			points[i] = UDim2.new(PointDataX,i==1 and 15 or 0,PointDataY,0)
			realpoints[i] = Path2DControlPoint.new(UDim2.new(PointDataX,0,PointDataY,0),Lower,Higher)
			Graph:InsertControlPoint(i,Path2DControlPoint.new(UDim2.new(PointDataX,i==1 and 15 or 0,PointDataY,0),ltg,rtg))

			ToolTips[i] = NewTooltip(i,v,points[i],points[i].X.Scale,points[i].Y.Scale)
			
		end
	elseif parameters.Type == "Bars" then
		for i,v in next,parameters.Dataset do
			local NormalVal = 1 - (v - minVal) / (maxVal - minVal)
			local PointDataX = (i-1) / (#parameters.Dataset - 1)
			local PointDataY = NormalVal

			points[i] = UDim2.new(PointDataX,i==1 and 15 or 0,PointDataY,0)

			local Bar = Create("Frame",{
				Parent= GraphContents,
				Name = i.. "_Bar",
				BackgroundColor3 = UI.Theme.Primary.Accent,
				Size = UDim2.new(0,20,-PointDataY,0),
				AnchorPoint = Vector2.new(0,0),
				Position = UDim2.new(PointDataX,i==1 and 15 or 0,1,0),
				ZIndex = 2
			})

			--ToolTips[i] = NewTooltip(i,v,points[i],points[i].X.Scale,points[i].Y.Scale)
		end
	else
		error("Invalid Chart Type")
	end

	local LabelNull = Create("TextLabel",{
		Parent= GraphContents,
		Name = "Num_0",
		Text = 0,
		TextSize = 10,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,6,0,6),
		FontFace = UI.Theme.Text.Font,
		AnchorPoint = Vector2.new(0,0.5),
		Position = UDim2.new(0, 0, 1,0),
		TextColor3 = UI.Theme.Text.Secondary,
	})

	local LabelMax = Create("TextLabel",{
		Parent= GraphContents,
		Name = "Num_0",
		Text = maxVal,
		TextSize = 10,
		BackgroundTransparency = 1,
		Size = UDim2.new(0,6,0,6),
		FontFace = UI.Theme.Text.Font,
		AnchorPoint = Vector2.new(0,0.5),
		Position = UDim2.new(0, 0, 0,0),
		TextColor3 = UI.Theme.Text.Secondary,
	})


	return {
		Dataset = points,
		Update = function(data)
			points = {}
			realpoints = {}
			for i,v in next,data do
				minVal = math.min(table.unpack(data))
				maxVal = math.max(table.unpack(data))
				local DataX = (i-1) / (#data - 1)
				LabelMax.Text = maxVal
				local DataY = 1 - (data[i] - minVal) / (maxVal - minVal)
				--local XVal = GraphContents[i.."_Point"].X
				--local YVal = GraphContents[i.."_Point"].Y
				realpoints[i] = Path2DControlPoint.new(UDim2.new(DataX,i==1 and 15 or 0,DataY,0),ltg,rtg)
				points[i] = UDim2.new(DataX,i==1 and 15 or 0,DataY,0)
			end
			task.wait()
			for i,v in next,ToolTips do
				for _,c in next,v do
					c:Destroy()
				end
			end
			for i,v in next,data do
				ToolTips[i] = NewTooltip(i,v,points[i],points[i].X.Scale,points[i].Y.Scale)
			end
			Graph:SetControlPoints(realpoints)
		end
	}
end


return ChartLua