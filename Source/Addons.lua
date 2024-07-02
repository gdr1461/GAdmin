export type GAdminAddons = {
	__metatable: string,
	__type: string,
	
	GetServerCommands: (self: GAdminAddons, NonRequired: boolean?) -> ModuleScript,
	GetClientCommands: (self: GAdminAddons, NonRequired: boolean?) -> ModuleScript,
	GetCalls: (self: GAdminAddons) -> ModuleScript,
	GetTopBars: (self: GAdminAddons) -> ModuleScript,
}

local Proxy = newproxy(true)
local Addons: GAdminAddons = getmetatable(Proxy)

Addons.__metatable = "[GAdmin Addons]: Metatable methods are restricted."
Addons.__type = "GAdmin Addons"

function Addons:__tostring()
	return self.__type
end

function Addons:__index(Key)
	return Addons[Key]
end

function Addons:__newindex(Key, Value)
	Addons[Key] = Value
	return Value
end

function Addons:GetServerCommands()
	return script.ServerCommands
end

function Addons:GetClientCommands()
	return script.ClientCommands
end

function Addons:GetCalls()
	return script.Calls
end

function Addons:GetTopBars()
	return script.TopBars
end

return Proxy :: GAdminAddons
