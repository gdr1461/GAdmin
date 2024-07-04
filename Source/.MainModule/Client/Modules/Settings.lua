local Client = script.Parent.Parent
local Modules = Client.Modules
local UI = require(Modules.UI)

export type Types = "Button" | "Text"
export type SettingsType = {
	__metatable: string,
	__type: string,
	
	__Default: {[string]: boolean | string},
	Create: (self: SettingsType, Type: Types, Name: string, DefaultSetting: boolean | string, Function: (Input: string | boolean) -> ()) -> Frame,
}

local Gui = UI:GetGui()
local Proxy = newproxy(true)
local Settings: SettingsType = getmetatable(Proxy)

Settings.__metatable = "[GAdmin Settings]: Metatable methods are restricted."
Settings.__type = "GAdmin Settings"
Settings.__Default = {}

function Settings:__tostring()
	return self.__type
end

function Settings:__index(Key)
	return Settings[Key]
end

function Settings:__newindex(Key, Value)
	Settings[Key] = Value
	return Value
end

function Settings:Create(Type, Name, DefaultSetting, Function)
	local Input = script.Inputs:FindFirstChild(Type)
	if not Input then
		warn(`[GAdmin Settings]: Type '{Type}' is not valid.`)
		return
	end
	
	local Template = script.SettingTemplate:Clone()
	Template.Name = Name
	Template.Title.Text = Name
	Template.Parent = Gui.MainFrame.Frames.Settings.List
	
	local Gap = Modules.Framework.Gap:Clone()
	Gap.Parent = Gui.MainFrame.Frames.Settings.List
	
	Input = Input:Clone()
	Input.Parent = Template
	
	if Type == "Button" then
		local Enabled = DefaultSetting ~= nil and DefaultSetting or true
		Input.Text = Enabled and "ON" or "OFF"
		Input.TextColor3 = Enabled and Color3.new(0.615686, 0.819608, 0.545098) or Color3.new(0.819608, 0.364706, 0.282353)
		
		Input.Activated:Connect(function()
			Enabled = not Enabled
			Input.Text = Enabled and "ON" or "OFF"
			Input.TextColor3 = Enabled and Color3.new(0.615686, 0.819608, 0.545098) or Color3.new(0.819608, 0.364706, 0.282353)
			Function(Enabled)
		end)
		
		return
	end
	
	Input.Text = DefaultSetting
	Input.FocusLost:Connect(function()
		Function(Input.Text)
	end)
end

return Proxy :: SettingsType
