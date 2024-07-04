local PhysicsService = game:GetService("PhysicsService")
type Dictionary = {}
type Key = {}

export type CollisionGroups = "Default" | "GAdmin Players" | "GAdmin NonPlayers" | "GAdmin NonCollide"
export type APIModule = {
	__metatable: string,
	__type: string,
	
	GetServerType: (self: APIModule) -> "Global" | "Reserved" | "Private",
	HeadShot: (self: APIModule, UserId: number) -> (string, boolean),
	FindValue: (self: APIModule, Data: Dictionary, Value: any) -> Key,
	SetModelCollision: (self: APIModule, Model: Model | Folder, CollisionGroup: CollisionGroups) -> (),
}

local Proxy = newproxy(true)
local GlobalAPI: APIModule = getmetatable(Proxy)

GlobalAPI.__metatable = "[GAdmin GlobalAPI]: Metatable methods are restricted."
GlobalAPI.__type = "GAdmin GlobalAPI"

function GlobalAPI:__tostring()
	return self.__type
end

function GlobalAPI:__index(Key)
	return GlobalAPI[Key]
end

function GlobalAPI:__newindex(Key)
	warn(`[GAdmin GlobalAPI]: No access to set new value {Key}.`)
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

function GlobalAPI:FindValue(Data, Value)
	for Index, Setting in pairs(Data) do
		for Key, KeyValue in pairs(Setting) do
			if Value ~= KeyValue then
				continue
			end

			return Index
		end
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

return Proxy :: APIModule
