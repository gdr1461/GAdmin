local MessagingService = game:GetService("MessagingService")
local GroupService = game:GetService("GroupService")

local DataStoreLoader = require(script.Parent.DataStoreLoader)
local Settings = require(script.Parent.Settings)
local Data = require(script.Parent.Data)

local SharedModules = Data.ClientFolder.SharedModules
local Signals = require(SharedModules.Signals)

export type RankType = {Rank: number, Users: {number | string}}
export type MessageTopic = {
	Topic: string,
	Arguments: {any}
}

export type APIModule = {
	__metatable: string,
	__type: string,
	__ClientBlacklist: {string?},
	
	GetPlayer: (self: APIModule, Name: string) -> Player,
	GetPrefix: (self: APIModule, player: Player) -> string,
	
	GetOwner: (self: APIModule) -> number,
	GetRank: (self: APIModule, Data: string | number, AlwaysData: boolean?) -> RankType,
	GetRankUsers: (self: APIModule, Rank: string) -> {number?}?,
	
	CheckUserRank: (self: APIModule, player: Player) -> (),
	GetUserRank: (self: APIModule, player: Player) -> number,
	GetUserIdRank: (self: APIModule, UserId: number) -> number,
	GetUserSettings: (self: APIModule, player: Player) -> {[string]: any?},
	GetOrderedRanks: (self: APIModule, Ascending: boolean) -> {[number]: string}?,
	
	GetBanlist: (self: APIModule) -> {number},
	IsBanned: (self: APIModule, player: Player) -> boolean,
	
	Ban: (self: APIModule, Caller: Player, UserId: number, Reason: string, Time: number?) -> (string, string?),
	BanIP: (self: APIModule, Caller: Player, UserId: number, Reason: string, Time: number?) -> (string, string?),
	
	UnBan: (self: APIModule, UserId: number) -> (string, string?),
	PushMessage: (self: APIModule, Data: MessageTopic) -> (),
	
	GetSignals: (self: APIModule) -> {},
	ClientCall: (player: Player, Action: string, Variables: any?) -> any?,
	
	GetRanks: (self: APIModule) -> {[string]: RankType},
	GetServerRanks: (self: APIModule) -> {[number]: number},
	GetPlayerRanks: (self: APIModule) -> {[number]: {Global: number, Server: number}},
}

local Proxy = newproxy(true)
local API: APIModule = getmetatable(Proxy)

API.__metatable = "[GAdmin API]: Metatable methods are restricted."
API.__type = "GAdmin API"

API.__ClientBlacklist = {"Ban", "UnBan", "GetBanlist", "CheckUserRank", "PushMessage"}

function API:__tostring()
	return self.__type, self.__version
end

function API:__index(Key)
	return API[Key]
end

function API:__newindex(Key)
	warn(`[GAdmin API]: No access to set new value {Key}.`)
end

function API:GetPlayer(Name)
	local Player
	for i, player in ipairs(game.Players:GetPlayers()) do
		if Name:lower() ~= player.Name:lower():sub(1, #Name) and Name:lower() ~= player.DisplayName:lower():sub(1, #Name) then
			continue
		end

		Player = player
		break
	end

	return Player
end

function API:GetOwner()
	return game.CreatorType == Enum.CreatorType.Group and GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id or game.CreatorId
end

function API:GetRank(Data, AlwaysData)
	local Rank = {}
	
	for RankName, Setting in pairs(Settings.Ranks) do
		if Setting.Rank == Data then
			Rank = AlwaysData and Setting or RankName
			break
		end
		
		if RankName == Data then
			Rank = Setting
			break
		end
	end

	return Rank
end

function API:GetPrefix(player)
	return Data.SessionData[player.UserId] and Data.SessionData[player.UserId].Prefix or Settings.DefaultPrefix
end

function API:GetUserSettings(player)
	local PlayerData = Data.SessionData[player.UserId]
	local PlayerSettings = {
		Prefix = PlayerData.Prefix,
		DefaultKickMessage = PlayerData.DefaultKickMessage,
		DefaultBanMessage = PlayerData.DefaultBanMessage,
	}
	
	return PlayerSettings
end

function API:CheckUserRank(player)
	if not Data.SessionData[player.UserId] then
		return
	end
	
	--== DEFAULT RANK ==--
	Data.SessionData[player.UserId].ServerRank = Settings.DefaultRank
	
	--== PRIVATE SERVER RANK ==--
	if Settings.PrivateServerOwner then
		if game.PrivateServerOwnerId == player.UserId then
			Data.SessionData[player.UserId].ServerRank = self:GetRank(Settings.PrivateServerOwner, true).Rank
		end
	end

	--== OWNER RANK ==--
	if game.CreatorId == player.UserId or (game.CreatorType == Enum.CreatorType.Group and player:GetRankInGroup(game.CreatorId) >= 255) then
		Data.SessionData[player.UserId].ServerRank = self:GetRank(5, true).Rank
	end
	
	--=== DEFAULT RANKS ==--
	for RankName, Setting in pairs(Settings.Ranks) do
		if not Setting.Users or (not table.find(Setting.Users, player.UserId) and not table.find(Setting.Users, player.Name)) or self:GetUserRank(player) > Setting.Rank then
			continue
		end

		Data.SessionData[player.UserId].ServerRank = Setting.Rank
		break
	end
	
	--== GROUP RANKS ==--
	for GroupId, Ranks in pairs(Settings.GroupRanks) do
		GroupId = tonumber(GroupId, 10)
		local UserRole = player:GetRankInGroup(GroupId)
		
		if not UserRole or not Ranks[UserRole] then
			continue
		end
		
		Data.SessionData[player.UserId].ServerRank = self:GetRank(Ranks[UserRole], true).Rank
		break
	end
end

function API:GetRankUsers(Rank)
	local Setting = self:GetRank(Rank)
	if not Setting then
		return {}
	end
	
	local Users = {}
	for i, PermUser in ipairs(Setting.Users) do
		local UserId = type(PermUser) == "number" and PermUser or game.Players:GetUserIdFromNameAsync(PermUser)
		table.insert(Users, UserId)
	end
	
	return Users
end

function API:GetUserRank(player)
	if type(player) == "number" or tonumber(player, 10) then
		return API:GetUserIdRank(player)
	end
	
	if not Data.SessionData[player.UserId] then self:CheckUserRank(player) end
	return Data.SessionData[player.UserId] and Data.SessionData[player.UserId].ServerRank or 0
end

function API:GetUserIdRank(UserId)
	local Success, PlayerData = DataStoreLoader.Load(UserId, Settings.DataStores.PlayerData)
	PlayerData = PlayerData or Data.DefaultPlayerData
	
	--== OWNER RANK ==--
	if game.CreatorId == UserId or self:GetOwner() == UserId then
		PlayerData.ServerRank = self:GetRank(5, true).Rank
	end

	--=== DEFAULT RANKS ==--
	local UserName = game.Players:GetNameFromUserIdAsync(UserId)
	for RankName, Setting in pairs(Settings.Ranks) do
		if not Setting.Users or (not table.find(Setting.Users, UserId) and not table.find(Setting.Users, UserName)) or PlayerData.ServerRank > Setting.Rank then
			continue
		end

		PlayerData.ServerRank = Setting.Rank
		break
	end
	
	return PlayerData.ServerRank or PlayerData.Rank or 0
end

function API:GetRanks()
	return Settings.Ranks
end

function API:GetPlayerRanks()
	local SessionData = {}
	for UserId, Setting in pairs(Data.SessionData) do
		SessionData[UserId] = {
			Server = Setting.ServerRank,
			Global = Setting.Rank
		}
	end

	return SessionData
end

function API:GetServerRanks()
	local SessionData = {}
	for UserId, Setting in pairs(Data.SessionData) do
		SessionData[UserId] = Setting.ServerRank
	end
	
	return SessionData
end

function API:GetOrderedRanks(Ascending)
	return coroutine.wrap(function()
		local RawRanks = table.clone(Settings.Ranks)
		local RawOrderedRanks = {}
		
		for RankName, Setting in pairs(RawRanks) do
			table.insert(RawOrderedRanks, Setting.Rank)
		end
		
		table.sort(RawOrderedRanks, function(a, b)
			return Ascending and a > b or a < b
		end)
		
		local OrderedRanks = {}
		for i, RankId in pairs(RawOrderedRanks) do
			table.insert(OrderedRanks, self:GetRank(RankId))
		end

		return OrderedRanks
	end)()
end

function API:BanIP(Caller, UserId, Reason, Time)
	local Success, PlayerData = DataStoreLoader.Load(tonumber(UserId, 10), Settings.DataStores.PlayerData)
	if not Success then
		warn(`[GAdmin API]: Unable to get player data.`)
		return "ERROR", "Unable to get player data."
	end
	
	PlayerData = PlayerData or Data.DefaultPlayerData
	if PlayerData.Banned and DateTime.now().UnixTimestamp < tonumber(PlayerData.Banned.Time, 10) then
		return "ERROR", "Player is already banned."
	end
	
	if self:GetUserIdRank(UserId) >= Data.SessionData[Caller.UserId].ServerRank then
		return "ERROR", "Player has higher rank than you."
	end
	
	Time = Time or math.huge
	PlayerData.Banned = {
		Reason = Reason,
		Time = tostring(Time)
	}

	DataStoreLoader.Save(UserId, PlayerData, Settings.DataStores.PlayerData)
	local Success, Response = pcall(function()
		return game.Players:BanAsync({
			UserIds = {UserId},
			Duration = Time,
			DisplayReason = Reason,
			PrivateReason = `Banned thru GAdmin ({Reason})`,
			ExcludeAltAccounts = true,
			ApplyToUniversse = true,
		})
	end)
end

function API:Ban(Caller, UserId, Reason, Time)
	local Success, PlayerData = DataStoreLoader.Load(tonumber(UserId, 10), Settings.DataStores.PlayerData)
	if not Success then
		warn(`[GAdmin API]: Unable to get player data.`)
		return "ERROR", "Unable to get player data."
	end
	
	PlayerData = PlayerData or Data.DefaultPlayerData
	if PlayerData.Banned and DateTime.now().UnixTimestamp < tonumber(PlayerData.Banned.Time, 10) then
		return "ERROR", "Player is already banned."
	end
	
	if self:GetUserIdRank(UserId) >= Data.SessionData[Caller.UserId].ServerRank then
		return "ERROR", "Player has higher rank than you."
	end
	
	Time = Time or math.huge
	if tonumber(Time) then Time = DateTime.now().UnixTimestamp + Time end
	
	PlayerData.Banned = {
		Reason = Reason,
		Time = tostring(Time)
	}
	
	DataStoreLoader.Save(UserId, PlayerData, Settings.DataStores.PlayerData)
	self:PushMessage({
		Topic = "Ban",
		Arguments = {
			{
				UserId = UserId,
				Reason = Reason,
				Time = tostring(Time)
			}
		}
	})
end

function API:UnBan(UserId)
	local Success, PlayerData = DataStoreLoader.Load(tonumber(UserId, 10), Settings.DataStores.PlayerData)
	if not Success then
		warn(`[GAdmin API]: Unable to get player data.`)
		return "ERROR", "Unable to get player data."
	end
	
	if not PlayerData.Banned or type(PlayerData.Banned) ~= "table" or DateTime.now().UnixTimestamp >= tonumber(PlayerData.Banned.Time, 10) then
		return "ERROR", "Player is not banned."
	end
	
	if game.Players:GetBanHistoryAsync(UserId) then
		game.Players:UnbanAsync({
			UserIds = {UserId},
			ApplyToUniverse = true
		})
	end
	
	PlayerData.Banned = false
	DataStoreLoader.Save(UserId, PlayerData, Settings.DataStores.PlayerData)
end

function API:PushMessage(Data)
	MessagingService:PublishAsync(Settings.Topics.Global, Data)
end

function API:GetSignals()
	return Signals
end

function API:GetBanlist()
	local Bans = {}
	local Success, Keys = DataStoreLoader.ListKeys(Settings.DataStores.PlayerData)
	
	if not Success then
		warn(`[GAdmin API]: Unable to get user data.`)
		return
	end
	
	while task.wait() do
		local Items = Keys:GetCurrentPage()
		for i, RawData in ipairs(Items) do
			local UserId = RawData.KeyName:gsub("global/", "")
			local Success, PlayerData = DataStoreLoader.Load(UserId, Settings.DataStores.PlayerData)
			if not PlayerData or not PlayerData.Banned then
				continue
			end
			
			if type(PlayerData.Banned) ~= "table" or not PlayerData.Banned.Time or DateTime.now().UnixTimestamp >= tonumber(PlayerData.Banned.Time) then
				continue
			end
			
			Bans[UserId] = PlayerData.Banned
		end
		
		if Keys.IsFinished then
			break
		end
		
		Keys:AdvanceToNextPageAsync()
	end
	
	return Bans
end

function API:IsBanned(player)
	local Success, Response = DataStoreLoader.Load(player.UserId, Settings.DataStores.PlayerData)
	if not Success then
		warn(`[GAdmin API]: Unable to get user ban data.`)
		return
	end
	
	return Response.Banned
end

function API.ClientCall(player, Action, ...)
	if not API[Action] then
		return
	end
	
	if table.find(API.__ClientBlacklist, Action) then
		warn(`[GAdmin API]: User {player.Name} ({player.UserId}) called blacklisted action '{Action}'.`)
		return `[API Call'{Action}' is blacklisted.]`
	end
	
	return API[Action](API, ...)
end

return Proxy :: APIModule
