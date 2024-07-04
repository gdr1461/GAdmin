local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PlayerGui = player.PlayerGui
local Gui = PlayerGui:WaitForChild("GAdminGui")

local UIColors = require(script.Colors)
export type UIFramework = {
	__metatable: string,
	__type: string,
	
	__Connections: {[GuiObject]: {RBXScriptConnection}},
	GetGui: (self: UIFramework) -> ScreenGui,
	
	Bind: (self: UIFramework, Object: GuiObject, Event: string, Function: () -> ()) -> {RBXScriptConnection}?,
	UnBind: (self: UIFramework, Object: GuiObject) -> (),
	
	UnBindClass: (self: UIFramework, Class: GuiObject) -> (),
	IsInClass: (self: UIFramework, Class: GuiObject, Object: GuiObject) -> boolean?,
	
	GetColor: (self: UIFramework, Color: UIColors.Colors) -> Color3,
	GetColors: (self: UIFramework) -> UIColors.UIColorType,
}

local Proxy = newproxy(true)
local UI: UIFramework = getmetatable(Proxy)

UI.__metatable = "[GAdmin UI]: Metatable methods are restricted."
UI.__type = "GAdmin UI"

UI.__Connections = {}
UI.__OnDisconnect = {}

function UI:__tostring()
	return self.__type
end

function UI:__index(Key)
	return UI[Key]
end

function UI:__newindex(Key)
	warn(`[GAdmin UI]: No access to set new value {Key}.`)
end

function UI:GetGui()
	return Gui
end

function UI:Bind(Object, Event, Function)
	if Event == "Disconnect" then
		self.__OnDisconnect[Object] = self.__OnDisconnect[Object] or {}
		table.insert(self.__OnDisconnect[Object], Function)
		
		return self.__OnDisconnect[Object]
	end
	
	if not Object[Event] then
		return
	end
	
	self.__Connections[Object] = self.__Connections[Object] or {}
	table.insert(self.__Connections[Object], Object[Event]:Connect(function()
		Function(Object)
	end))
	
	return self.__Connections[Object]
end

function UI:UnBind(Object)
	if not self.__Connections[Object] then
		return
	end
	
	self.__OnDisconnect[Object] = self.__OnDisconnect[Object] or {}
	for i, Disconnect in ipairs(self.__OnDisconnect[Object]) do
		coroutine.wrap(Disconnect)(Object)
	end
	
	for i, Connection in ipairs(self.__Connections[Object]) do
		Connection:Disconnect()
	end
	
	self.__Connections[Object] = {}
	self.__OnDisconnect[Object] = {}
end

function UI:UnBindClass(Class)
	for Object, Connections in pairs(self.__Connections) do
		if not self:IsInClass(Class, Object) then
			continue
		end
		
		self:UnBind(Object)
	end
end

function UI:IsInClass(Class, Object)
	if Object.Parent ~= Class then
		return not Object.Parent:IsA("ScreenGui") and self:IsInClass(Class, Object.Parent)
	end
	
	return true
end

function UI:GetColor(Name)
	return UIColors[Name]
end

function UI:GetColors()
	return UIColors
end

return Proxy :: UIFramework
