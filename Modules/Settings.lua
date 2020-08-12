local Settings = {}
local StudioWidgets = script.Parent.Parent.StudioWidgets
local plugin

local CollapsibleTitledSection = require(StudioWidgets.CollapsibleTitledSection)
local LabeledCheckbox = require(StudioWidgets.LabeledCheckbox)

local WInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	300,
	250,
	250,
	150
)

-- roblox please let modulescripts use plugin so i dont have to do something
-- dumb like this
function Settings.run(pluginRef)
	plugin = pluginRef
	return run()
end

function run()
	local Settings = {
		["Show Deprecated Properties"] = plugin:GetSetting("Show Deprecated Properties") or false
	}
	
	local Widget = plugin:CreateDockWidgetPluginGui("Settings", WInfo)
	Widget.Title = "Properties2 - Settings"
	
	local Container = Instance.new("ScrollingFrame")
	Container.Size = UDim2.new(1, 0, 1, 0)
	Container.Parent = Widget
	require(script.Parent.ThemeService):AddItem(Container, "BackgroundColor3", Enum.StudioStyleGuideColor.MainBackground, Enum.StudioStyleGuideModifier.Default)
	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = Container
	
	local SettingsCategory = CollapsibleTitledSection.new(
		"Settings",
		"Settings",
		true,
		true,
		false
	)
	SettingsCategory:GetSectionFrame().Parent = Container
	
	for Setting, Value in pairs(Settings) do
		
		local SettingUI = LabeledCheckbox.new(
			"SettingCheckbox",
			Setting,
			Value,
			false,
			true
		)
		SettingUI:GetFrame().Parent = SettingsCategory:GetContentsFrame()
		
		SettingUI:SetValueChangedFunction(function(newValue)
			plugin:SetSetting(Setting, newValue)
		end)
	end
	
	return Settings, Widget
end

return Settings
