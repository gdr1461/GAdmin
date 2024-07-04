local Client = script.Parent.Parent.Parent
local Modules = Client.Modules
local UI = require(Modules.UI)

local Icon = require(script.Icon)
local TypeIcon: Icon.ModuleType = Icon

export type TopBarModule = {
	Reference: Icon.IconType,
	TopBarPlus: Icon.ModuleType,
	
	Create: (self: TopBarModule) -> {any},
	CallBind: (self: TopBarModule, Function: (Icon: {any}, State: boolean) -> ()) -> number,
	CallUnBind: (self: TopBarModule, Index: number?) -> (),
}

local TopBar = {}
TopBar.TopBarPlus = TypeIcon

TopBar.Reference = nil
TopBar.Binds = {}

function TopBar:Create()
	--== ADDON SETUP ==--

	local Addons = script.Icon:FindFirstChild("TopBars")
	if Addons then
		local TopBars = require(Addons)
		for ID, Function in pairs(TopBars) do
			coroutine.wrap(Function)()
		end
	end

	--==             ==--
	
	self.Reference = TypeIcon.new()
	self.Reference:setName("GAdmin")
		:setImage(18301407260)
		:setImageScale(.8, "deselected")
		:setImageScale(.7, "selected")
		:bindToggleItem(UI:GetGui().MainFrame)
		:setCaption("GAdmin")
		:setOrder(0)
		:autoDeselect(false)
	
	self.Reference.selected:Connect(function()
		for i, Function in ipairs(TopBar.Binds) do
			coroutine.wrap(Function)(self.Reference, true)
		end
	end)
	
	self.Reference.deselected:Connect(function()
		for i, Function in ipairs(TopBar.Binds) do
			coroutine.wrap(Function)(self.Reference, false)
		end
	end)

	return self.Reference
end

function TopBar:Bind(Function)
	if type(Function) ~= "function" then
		warn(`[GAdmin TopBar]: Function of type '{type(Function)}' is not valid.`)
		return
	end
	
	table.insert(TopBar.Binds, Function)
end

function TopBar:UnBind(Index)
	if not Index then
		TopBar.Binds = {}
		return
	end
	
	local Valid = table.find(TopBar.Binds, Index)
	if not Valid then
		warn(`[GAdmin TopBar]: Bind '{Index}' is not valid.`)
		return
	end
	
	table.remove(TopBar.Binds, Valid)
end

return TopBar
