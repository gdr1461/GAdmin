export type Colors = 
	"Default" | "Default2" |
	"Background" | "Text" |
	"TextBackground" | "Selected" |
	"Background2" | "Enabled" |
	"Disabled"
	
export type UIColorType = {
	Default: Color3,
	Default2: Color3,
	Background: Color3,
	Background2: Color3,
	Text: Color3,
	TextBackground: Color3,
	Selected: Color3,
	Enabled: Color3,
	Disabled: Color3
}

local UIColors = {}

UIColors.Default = Color3.new(0.180392, 0.168627, 0.247059)
UIColors.Default2 = Color3.new(0.247059, 0.231373, 0.329412)

UIColors.Background = Color3.new(0.133333, 0.121569, 0.180392)
UIColors.Background2 = Color3.new(0.235294, 0.227451, 0.282353)

UIColors.Text = Color3.new(0.560784, 0.552941, 0.603922)
UIColors.TextBackground = Color3.new(0.313725, 0.298039, 0.372549)
UIColors.Selected = Color3.new(1, 1, 1)

UIColors.Enabled = Color3.new(0.615686, 0.819608, 0.545098)
UIColors.Disabled = Color3.new(0.819608, 0.364706, 0.282353)

return UIColors :: UIColorType
