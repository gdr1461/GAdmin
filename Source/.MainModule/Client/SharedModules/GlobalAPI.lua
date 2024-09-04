local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

type Dictionary = {}
type Table = {}

type Key = {}
type Value = {}

type Commands = {}
type CommandData = {}

export type CollisionGroups = "Default" | "GAdmin Players" | "GAdmin NonPlayers" | "GAdmin NonCollide"
export type APIModule = {
	__metatable: string,
	__type: string,
	
	GetSimilarity: (self: APIModule, String1: string, String2: string, Mode: "Percent" | "Symbols", Value: number) -> boolean,
	FindValue: (self: APIModule, Data: Dictionary, Value: any) -> Key,
	
	FindValueParent: (self: APIModule, Data: Dictionary, Value: any) -> Dictionary,
	FindKey: (self: APIModule, Data: Table, Key: Key) -> Value,
	
	GetServerType: (self: APIModule) -> "Global" | "Reserved" | "Private",
	HeadShot: (self: APIModule, UserId: number) -> (string, boolean),
	
	SetModelCollision: (self: APIModule, Model: Model | Folder, CollisionGroup: CollisionGroups) -> (),
	GetPlayer: (self: APIModule, Method: "Name" | "UserId", Variables: any) -> Player,
	
	GetCommand: (self: APIModule, Commands: Commands, Command: string) -> (string, CommandData),
	GetSide: (self: APIModule) -> "Server" | "Client",
}

local Proxy = newproxy(true)
local GlobalAPI: APIModule = getmetatable(Proxy)

GlobalAPI.__metatable = "[GAdmin GlobalAPI]: Metatable methods are restricted."
GlobalAPI.__type = "GAdmin GlobalAPI"

GlobalAPI.__GetPlayerMethods = {
	Name = function(String, Specific)
		for i, player in ipairs(Players:GetPlayers()) do
			if player.Name ~= String and player.DisplayName ~= String and not Specific then
				continue
			end
			
			if Specific and player.Name:sub(1, #String):lower() ~= String:lower() and player.DisplayName:sub(1, #String):lower() ~= String:lower() then
				continue
			end
			
			return player
		end
	end,
	
	UserId = function(Number)
		Number = tonumber(Number, 10)
		return Players:GetPlayerByUserId(Number)
	end,
}

function GlobalAPI:__tostring()
	return self.__type
end

function GlobalAPI:__index(Key)
	return GlobalAPI[Key]
end

function GlobalAPI:__newindex(Key)
	warn(`[GAdmin GlobalAPI]: No access to set new value {Key}.`)
end

function GlobalAPI:GetSimilarity(String1, String2, Mode, Value)
	if Mode == "Percent" then
		Value = Value or 100
		local Start, End = String1:find(String2, nil, true)
		
		if not Start then
			return false
		end

		local Total = End - (Start - 1)
		local Similarity = Total / #String1 * 100
		
		return Similarity >= Value
	end
	
	if Mode == "Symbols" then
		Value = Value or #String1
		local Start, End = String1:find(String2, nil, true)
		
		if not Start then
			return false
		end
		
		local Total = End - (Start - 1)
		return Total >= Value
	end
end

function GlobalAPI:GetCommand(Commands, Command)
	if not Commands or not Command then
		return
	end
	
	for i, Setting in pairs(Commands) do
		if Setting.Debug then
			continue
		end
		
		local CommandName = not Setting.UppercaseMatters and Setting.Command:lower() or Setting.Command
		Command = not Setting.UppercaseMatters and Command:lower() or Command

		if CommandName == Command then
			return Setting.Command, Setting
		end

		Setting.Alias = Setting.Alias or {}
		for i, Alias in ipairs(Setting.Alias) do
			local Alias = not Setting.UppercaseMatters and Alias:lower() or Alias
			if Alias == Command then
				return Setting.Command, Setting
			end

			if Alias ~= Command then
				continue
			end

			return Setting.Command, Setting
		end

		--== COMMAND UNDOS ==--
		if Setting.UnDo then
			Setting.Revoke = Setting.Revoke or {`Un{Setting.Command}`}
			if not table.find(Setting.Revoke, `Un{Setting.Command}`) then
				table.insert(Setting.Revoke, `Un{Setting.Command}`)
			end

			for i, Alias in ipairs(Setting.Revoke) do
				local UnDoName = not Setting.UppercaseMatters and Alias:lower() or Alias
				if Command ~= UnDoName then
					continue
				end

				return `Un{Setting.Command}`, Setting
			end
		end
	end
end

function GlobalAPI:GetServerType()
	local Type = "Global"
	Type = game.PrivateServerId ~= "" and "Reserved" or Type
	Type = game.PrivateServerOwnerId ~= 0 and "Private" or Type
	
	return Type
end

function GlobalAPI:HeadShot(UserId)
	local Image, Ready = game.Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	return Image, Ready
end

function GlobalAPI:FindValue(Data, Value, Recursive)
	for Index, Setting in pairs(Data) do
		for Key, KeyValue in pairs(Setting) do
			if Value ~= KeyValue then
				continue
			end

			return Index
		end
	end
end

function GlobalAPI:FindKey(Data, Key)
	for Index, Value in pairs(Data) do
		if type(Value) == "table" then
			local Found = self:FindKey(Value, Key)
			if Found then
				return Found
			end
			
			continue
		end
		
		if Index ~= Key then
			continue
		end
		
		return Value
	end
end

function GlobalAPI:FindValueParent(Data, Value)
	for Key, KeyValue in pairs(Data) do
		if type(KeyValue) == "table" then
			local Found = self:FindValueParent(KeyValue, Value)
			
			if Found then
				return Found
			end
			
			continue
		end

		if Value ~= KeyValue then
			continue
		end
		
		return Data
	end
end

function GlobalAPI:SetModelCollision(Model, CollisionGroup)
	for i, Part in ipairs(Model:GetDescendants()) do
		if not Part:IsA("BasePart") then
			continue
		end
		
		Part.CollisionGroup = CollisionGroup
	end
end

function GlobalAPI:GetPlayer(Method, ...)
	return self.__GetPlayerMethods[Method](...)
end

function GlobalAPI:GetSide()
	return Players.LocalPlayer == nil and "Server" or "Client"
end

return Proxy :: APIModule
