local Main = {}
-- v:1.1
local plugin

function Main.init(pluginRef)
	plugin = pluginRef
	run()
end

function run()
	local PluginFolder = script.Parent
	local StudioWidgets = PluginFolder.StudioWidgets
	local Modules = PluginFolder.Modules
	local ThemeService = require(Modules.ThemeService)
	local Selection = game:GetService("Selection")
	local APIDump = require(Modules.Dump)
	local HTTP = game:GetService("HttpService")
	local Dump = HTTP:JSONDecode(APIDump.Dump)
	local DontShow = require(Modules.DontShow)
	local CategoryOrder = require(Modules.CategoryOrder)
	local Connections = {}
	local Settings = require(Modules.Settings)
	local ChangeHistoryService = game:GetService("ChangeHistoryService")

	local SettingsTable, SettingsWidget = Settings.run(plugin)

	function CanShow(property)
		for _, prop in pairs(DontShow.DontShow) do
			if prop == property then
				return false
			end
		end
		return true
	end

	local Classes = {}
	for _, ClassTable in pairs(Dump.Classes) do
		Classes[ClassTable.Name] = ClassTable
	end

	-- configuration
	local PLUGIN_NAME = "Properties2"

	-- Define widgets for use in UI
	local CollapsibleTitledSection = require(StudioWidgets.CollapsibleTitledSection)
	local LabeledTextInput = require(StudioWidgets.LabeledTextInput)
	local LabeledCheckbox = require(StudioWidgets.LabeledCheckbox)
	local CustomTextButton = require(StudioWidgets.CustomTextButton)
	local LabeledColorInput = require(StudioWidgets.LabeledColorInput)

	-- Define + create widget (window) & toolbar button
	local Toolbar = plugin:CreateToolbar("Properties2")
	local ToolbarButton = Toolbar:CreateButton("Open", "Open Properties2", "rbxassetid://5554565291", "Open Properties2")
	ToolbarButton.ClickableWhenViewportHidden = true
	
	local WInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,
		false,
		true,
		200,
		300,
		175,
		200
	)
	local Widget = plugin:CreateDockWidgetPluginGui("Main", WInfo)
	Widget.Title = PLUGIN_NAME
	
	ToolbarButton.Click:Connect(function()
		Widget.Enabled = not Widget.Enabled
	end)
	
	-- important code below
	local SettingsButton = Instance.new("ImageButton")
	SettingsButton.Image = "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png"
	SettingsButton.Size = UDim2.new(0, 20, 0, 20)
	SettingsButton.AnchorPoint = Vector2.new(1, 1)
	SettingsButton.Position = UDim2.new(1, -5, 1, -5)
	SettingsButton.BackgroundTransparency = 1
	SettingsButton.ZIndex = 2
	SettingsButton.Parent = Widget
	SettingsButton.MouseButton1Click:Connect(function()
		local Visibility = not SettingsWidget.Enabled
		SettingsWidget.Enabled = Visibility
	end)

	local Container = Instance.new("ScrollingFrame")
	Container.Size = UDim2.new(1, 0, 1, 0)
	Container.BorderSizePixel = 0
	Container.Parent = Widget
	Container.ScrollBarImageTransparency = 1
	Container.ScrollBarThickness = 0
	Container.CanvasSize = UDim2.new(0, 0, 0, 99999999)

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = Container

	ThemeService:AddItem(Container, "BackgroundColor3", Enum.StudioStyleGuideColor.MainBackground, Enum.StudioStyleGuideModifier.Default)

	Selection.SelectionChanged:Connect(function()
		local selected = Selection:Get()

		if #selected == 1 then
			Widget.Title = string.format("%s \"%s\"", selected[1].ClassName, selected[1].Name)
			RenderProperties(selected[1])
		elseif #selected == 0 then
			Widget.Title = PLUGIN_NAME
			Clear()
		end
	end)

	-- functions
	function round(num, numDecimalPlaces)
		return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
	end

	function StringTo3NumberThingy(str)
		local n1, n2, n3 = string.match(str, "(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)%s*,%s*(%-?%d+%.?%d*)")
		return tonumber(n1), tonumber(n2), tonumber(n3)
	end

	function Clear()
		-- clear all connections
		for index, connection in ipairs(Connections) do
			if connection then
				connection:Disconnect()
			end
			table.remove(Connections, index)
		end
		for _, Child in pairs(Container:GetChildren()) do
			if Child ~= UIListLayout then
				Child:Destroy()
			end
		end
	end

	-- the most important function
	function RenderProperties(item)
		Clear()

		local RenderQueue = {
			Categories = {},
			Properties = {}
		}

		local Categories = {}
		local Properties = {}

		local CurrentClass = item.ClassName
		while CurrentClass ~= "<<<ROOT>>>" do
			local Class = Classes[CurrentClass]
			for _, Member in pairs(Class.Members) do
				if Member.MemberType == "Property" and CanShow(Member.Name) then
					if not RenderQueue.Categories[Member.Category] then
						RenderQueue.Categories[Member.Category] = 0
					end
					RenderQueue.Properties[Member.Name] = Member
					table.insert(Properties, 1, Member.Name)
				end
			end
			CurrentClass = Class.Superclass
		end

		for _, C in ipairs(CategoryOrder.Order) do
			local Category = RenderQueue.Categories[C]
			if Category then
				local CategoryUI = CollapsibleTitledSection.new(
					"PropertyCategory",
					C,
					true,
					true,
					false
				)
				CategoryUI:GetSectionFrame().Parent = Container

				Categories[C] = CategoryUI
			end
		end
		--[[for Category in pairs(RenderQueue.Categories) do
			local CategoryUI = CollapsibleTitledSection.new(
				"PropertyCategory",
				Category,
				true,
				true,
				false
			)
			CategoryUI:GetSectionFrame().Parent = Container

			Categories[Category] = CategoryUI
		end]]

		table.sort(Properties)

		for _, PropertyName in ipairs(Properties) do
			local Property = RenderQueue.Properties[PropertyName]
			local s, e = pcall(function()

				if Property.Tags and (table.find(Property.Tags, "Deprecated") and not plugin:GetSetting("Show Deprecated Properties")) then
					return
				end

				local IsReadOnly = Property.Tags and table.find(Property.Tags, "ReadOnly")
				local Value = item[Property.Name]
				local Input -- used for detecting changes to properties from properties2 window

				if Property.Tags and table.find(Property.Tags, "Deprecated") and plugin:GetSetting("Show Deprecated Properties") then
					Input = LabeledTextInput.new(
						"DeprecatedProperty",
						Property.Name,
						tostring(Value),
						true,
						true
					)
					Input:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				elseif Property.ValueType.Name == "bool" then
					Input = LabeledCheckbox.new(
						"BoolProperty",
						Property.Name,
						Value,
						IsReadOnly
					)
					Input:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				elseif Property.Name == "Source" then
					local ButtonInput = CustomTextButton.new(
						"SourceButton",
						"Edit source"
					)
					local TextInput = LabeledTextInput.new(
						"StringProperty",
						Property.Name,
						tostring(Value)
					)
					TextInput:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
					ButtonInput:GetButton().Size = UDim2.new(0, 75, 0, 23)
					ButtonInput:GetButton().Parent = TextInput:GetFrame()
					ButtonInput:GetButton().AnchorPoint = Vector2.new(0, .5)
					ButtonInput:GetButton().Position = TextInput:GetFrame().Wrapper.Position
					TextInput:GetFrame().Wrapper:Destroy()
					local Connection = ButtonInput:GetButton().MouseButton1Click:Connect(function()
						plugin:OpenScript(item)
					end)
					table.insert(Connections, 1, Connection)
				elseif Property.ValueType.Name == "Color3" or Property.ValueType.Name == "BrickColor" then
					Input = LabeledColorInput.new(
						"ColorProperty",
						Property.Name,
						Value
					)
					Input:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				elseif Property.ValueType.Name == "string" or Property.ValueType.Name == "float" or Property.ValueType.Name == "double" then
					if Property.ValueType.Name == "float" or Property.ValueType.Name == "double" then
						Value = round(Value, 3)
					end
					Input = LabeledTextInput.new(
						"TextProperty",
						Property.Name,
						tostring(Value),
						IsReadOnly
					)
					Input:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				elseif Property.ValueType.Name == "Vector3" then
					Input = LabeledTextInput.new(
						"Vector3Property",
						Property.Name,
						string.format("%s, %s, %s", round(Value.X), round(Value.Y), round(Value.Z)),
						IsReadOnly
					)
					Input:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				else
					local TextInput = LabeledTextInput.new(
						"UnknownProperty",
						Property.Name,
						tostring(Value),
						true
					)
					TextInput:GetFrame().Parent = Categories[Property.Category]:GetContentsFrame()
				end

				-- function that fires when a property is changed from properties2 window,
				-- and applies the change to the actual property
				Input:SetValueChangedFunction(function(newValue)
					if Input:GetFrame():FindFirstChild("Wrapper") and not Input:GetFrame().Wrapper.TextBox:IsFocused() then
						return
					end
					if Property.ValueType.Name == "Vector3" or Property.ValueType.Name == "Color3" then
						local n1, n2, n3 = StringTo3NumberThingy(newValue)
						if not n1 then n1 = 0 end
						if not n2 then n2 = 0 end
						if not n3 then n3 = 0 end
						if Property.ValueType.Name == "Vector3" then
							item[PropertyName] = Vector3.new(n1, n2, n3)
						elseif Property.ValueType.Name == "Color3" then
							item[PropertyName] = Color3.new(n1 * 255, n2 * 255, n3 * 255)
							Input:GetFrame().ColorDisplay.BackgroundColor3 = item[PropertyName]
						end
					elseif Property.ValueType.Name == "number" then
						item[PropertyName] = tonumber(newValue)
					else
						item[PropertyName] = newValue
					end
					ChangeHistoryService:SetWaypoint("Property change")
				end)

				local Connection = item:GetPropertyChangedSignal(PropertyName):Connect(function()
					if Input:GetFrame():FindFirstChild("Wrapper") and not Input:GetFrame().Wrapper.TextBox:IsFocused() then
						local newValue = item[PropertyName]
						if Property.ValueType.Name == "Vector3" then
							Input:SetValue(string.format("%s, %s, %s", tostring(round(newValue.X, 1)), tostring(round(newValue.Y, 1)), tostring(round(newValue.Z, 1))))
						else
							Input:SetValue(tostring(newValue))
						end
					elseif not string.match(Input:GetFrame().Name, "TextInput") then
						local newValue = item[PropertyName]
						Input:SetValue(newValue)
					end
				end)
			end)
		end
	end
end

return Main
