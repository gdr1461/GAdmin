export type GAdminAddons = {
	__metatable: string,
	__type: string,
	
	GetServerCommands: (self: GAdminAddons, NonRequired: boolean?) -> {any},
	GetClientCommands: (self: GAdminAddons, NonRequired: boolean?) -> {}
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

function Addons:GetServerCommands(NonRequired)
	return script.ServerCommands
end

function Addons:GetClientCommands(NonRequired)
	return script.ClientCommands
end

return Proxy :: GAdminAddons
