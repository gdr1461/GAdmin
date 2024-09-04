--== Module isn't finished yet.

local Client = script.Parent.Parent
local SharedModules = Client.SharedModules
local GlobalAPI = require(SharedModules.GlobalAPI)

export type Deprecation = {
	__type: string,
	__Deprecated: {
		[string]: {
			[string]: {
				[string]: string | boolean
			}
		}
	},
	
	Start: (self: Deprecation) -> (),
	Send: (self: Deprecation, ModuleName: string, Method: string, Replacement: string, UseNewMethod: boolean) -> (),
	
	IsDeprecated: (self: Deprecation, ModuleName: string, Method: string) -> boolean,
	Find: (self: Deprecation, ModuleName: string) -> ModuleScript,
}

local Proxy = newproxy(true)
local Deprecation: Deprecation = getmetatable(Proxy)

Deprecation.__type = "GAdmin Deprecation"
Deprecation.__metatable = "[GAdmin Deprecation]: Metatable methods are restricted."

Deprecation.__Deprecated = {
	API = {
		GetPlayer = {
			Replacement = "GlobalAPI:GetPlayer()"
		}
	},
	
	Parser = {
		ParseMessage = {
			Replacement = ":Parse()",
			UseNewMethod = true
		},

		CheckArgument = {
			Replacement = ":TransformArguments()"
		}
	}
}

function Deprecation:__tostring()
	return self.__type
end

function Deprecation:__index(Key)
	return Deprecation[Key]
end

function Deprecation:__newindex(Key, Value)
	warn("[GAdmin Deprecation]: Attempt to modify a read-only table.")
end

function Deprecation:Start()
	if true then
		return
	end
	
	for ModuleName, Deprecated in pairs(self.__Deprecated) do
		local Module = self:Find(ModuleName)
		if not Module then
			continue
		end
		
		local RequiredModule = require(Module)
		RequiredModule[`_GAdmin{ModuleName}BypassNewIndex____index`] = function(Table, Key)
			if Deprecated[Key] then
				if not Deprecated[Key].Warned then
					Deprecation:Send(ModuleName, Key, Deprecated[Key].Replacement, Deprecated[Key].UseNewMethod)
					if Deprecated[Key].UseNewMethod then
						print(RequiredModule()[Deprecated[Key].Replacement:gsub("%p", "")])
						return RequiredModule()[Deprecated[Key].Replacement:gsub("%p", "")]
					end
					
					return type(RequiredModule()[Key]) == "function" and function()
						return `Method '{Key}' is classified as deprecated.`
					end or nil
				end

				Deprecated[Key].Warned = true
				return Deprecated[Key].UseNewMethod and RequiredModule()[Deprecated[Key].Replacement:gsub("%p", "")] or nil
			end

			return RequiredModule()[Key]
		end
	end
end

function Deprecation:Send(ModuleName, Method, Replacement, UseNewMethod)
	warn(`[GAdmin {ModuleName}]: Method :{Method}() is deprecated, {UseNewMethod and "automaticly using" or "use"} {Replacement} instead.`)
end

function Deprecation:IsDeprecated(ModuleName, Method)
	return self.__Deprecated[ModuleName] and self.__Deprecated[ModuleName][Method] ~= nil or false
end

function Deprecation:Find(ModuleName)
	local IsServer = GlobalAPI:GetSide() == "Server"
	local Module
	
	if not IsServer then
		for i, Module in ipairs(Client:GetDescendants()) do
			if Module.Name ~= ModuleName or (not Module:IsDescendantOf(Client.Modules) and not Module:IsDescendantOf(Client.SharedModules)) then
				continue
			end
			
			return Module
		end
		
		return
	end
	
	return _G.GAdmin.Script:FindFirstChild(ModuleName)
end

return Proxy :: Deprecation
