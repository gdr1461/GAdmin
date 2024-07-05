export type GAdminAddons = {
	__metatable: string,
	__type: string,
	__PackSystem: {[string]: ModuleScript},
	
	SeparateAll: (self: GAdminAddons) -> (),
	Separate: (self: GAdminAddons, Pack: Folder) -> (),
	
	GetServerCommands: (self: GAdminAddons, NonRequired: boolean?) -> ModuleScript,
	GetClientCommands: (self: GAdminAddons, NonRequired: boolean?) -> ModuleScript,
	GetCalls: (self: GAdminAddons) -> ModuleScript,
	GetTopBars: (self: GAdminAddons) -> ModuleScript,
}

local Proxy = newproxy(true)
local Addons: GAdminAddons = getmetatable(Proxy)

Addons.__metatable = "[GAdmin Addons]: Metatable methods are restricted."
Addons.__type = "GAdmin Addons"

Addons.__PackSystem = {
	ServerCommands = script.ServerCommands,
	ClientCommands = script.ClientCommands,
	Calls = script.Calls,
	TopBars = script.TopBars
}

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

function Addons:SeparateAll()
	for i, Package in ipairs(script.Packs:GetChildren()) do
		self:Separate(Package)
	end
end

function Addons:Separate(Pack)
	for System, Parent in pairs(self.__PackSystem) do
		local ModuleObject = Pack:FindFirstChild(System)
		if not ModuleObject then
			continue
		end
		
		ModuleObject.Name = `[{Pack.Name}] {System}`
		ModuleObject.Parent = Parent
	end
	
	Pack:Destroy()
end

return Proxy :: GAdminAddons
