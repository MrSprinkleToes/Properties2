--Behaviour:
--	Add item to registry for it to be updated
--	Items are automatically cleaned up upon deletion
--	All items are updated on settings().Studio.ThemeChanged
--	Should automatically work for newer released themes

local ThemeService = {}
local studioSettings = settings().Studio
local entries = {}

--Creates an entry and overwrites if already existant with the new values
function ThemeService:AddItem(element,property,guide,modifier)
	if entries[element] == nil then--Create new data if non existant
		entries[element] = {} 
		local ancestryChanged
		ancestryChanged = element.AncestryChanged:Connect(function()--Cleanup entries on deletion
			if element.Parent then return false end
			local _, result = pcall(function() element.Parent = element end)
			local isLocked = result:match("locked") and true or false
			if isLocked then
				--print("Object removed so associated variables were garbage collected")
				entries[element] = nil
				ancestryChanged:Disconnect()
			end
		end)
	end
	if entries[element][property] ~= nil then entries[element][property] = nil end--Clear property data on selected item
	entries[element][property] = {}
	entries[element][property].Guide = guide
	entries[element][property].Modifier = modifier
	ThemeService:UpdateItem(element,property)
end

--Updates the colour of the element
function ThemeService:UpdateItem(element,property)
	local elementData = entries[element][property]
	local guide = elementData.Guide
	local modifier = elementData.Modifier
	element[property] = studioSettings.Theme:GetColor(guide,modifier)
end

studioSettings.ThemeChanged:Connect(function()
	for element, propertiesArray in next, entries do
		for property, elementData in next, propertiesArray do
			local guide = elementData.Guide
			local modifier = elementData.Modifier
			element[property] = studioSettings.Theme:GetColor(guide,modifier)
		end
	end
end)

return ThemeService
