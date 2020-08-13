# Properties2
![mit](https://img.shields.io/github/license/MrSprinkleToes/Properties2?color=b) ![pull requests](https://img.shields.io/github/issues-pr/MrSprinkleToes/Properties2) ![contributors](https://img.shields.io/github/contributors/MrSprinkleToes/Properties2) ![language](https://img.shields.io/github/languages/top/MrSprinkleToes/Properties2)

Lua-ified properties window for Roblox.
___
# Using the plugin
There are two ways of obtaining the plugin:
- [From Roblox](#from-roblox) - *Do this if you want the plugin to stay updated automatically*
- [Manually build the plugin](#manually-build-the-plugin) - *Do this if you don't want the plugin to stay updated automatically*
## From Roblox
Choosing this option of obtaining the plugin means the plugin will automatically update for you. Just press install and you're done!
In order to obtain the plugin from Roblox, simply [visit this website](https://www.roblox.com/library/5553966117/Properties2) and press `Install`!
<details>
  <summary>But I'm afraid that if I let the plugin update automatically, my work could be stolen!</summary>
  I completely understand this concern. The source code of the plugin will always be available at this repository, so feel free to check back here any time there's an update and check out what changes were made!
</details>

## Manually build the plugin
When you build the plugin yourself you get the latest version of the plugin. **It will not update automatically.**
<details>
  <summary>To build the plugin, simply copy and paste this into the command line:</summary>
  <p>
    
```lua
print("Building Properties2...")

local HTTP = game:GetService("HttpService")
local Request
local success = pcall(function()
	Request = HTTP:GetAsync("https://api.github.com/repos/MrSprinkleToes/Properties2/contents/")
end)
local Returned = HTTP:JSONDecode(Request)

if not success then
	warn("There was an issue getting the repository.")
end

local Properties2 = Instance.new("Folder")
Properties2.Name = "Properties2"
Properties2.Parent = workspace

function Iterate(Table, Destination)
	for _, File in pairs(Table) do
		if File.type == "dir" then
			local Folder = Instance.new("Folder")
			Folder.Name = File.name
			Folder.Parent = Destination
			local Request = HTTP:GetAsync("https://api.github.com/repos/MrSprinkleToes/Properties2/contents/"..File.name)
			local Returned = HTTP:JSONDecode(Request)
			Iterate(Returned, Folder)
		elseif File.name ~= "LICENSE" and File.name ~= "README.md" then
			local Script = Instance.new("ModuleScript")
			Script.Name = string.sub(File.name, 1, #File.name - 4)
			Script.Source = HTTP:GetAsync(File.download_url)
			Script.Parent = Destination
		end
	end
end

Iterate(Returned, Properties2)

local Runner = Instance.new("Script")
Runner.Name = "Runner"
Runner.Source = "require(script.Parent.Main).init(plugin)"
Runner.Parent = Properties2

print("Properties2 has been built! Right click the folder in the Workspace and click \"Save as Local Plugin...\"")
```
  </p>
</details>

Once you've run the code, right click the new folder that has appeared in Workspace titled `Properties2` and press `Save as Local Plugin...`.
___
# Credits
- GammaSource - ThemeService
- StudioWidgets contributors - [StudioWidgets](https://github.com/Roblox/StudioWidgets)
- [zeuxcg](https://twitter.com/zeuxcg) (Arseny Kapoulkine) - Helped me figure out how Roblox Studio displays properties
- starmaq - Introduced me to StudioWidgets
