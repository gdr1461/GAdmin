local PhysicsService = game:GetService("PhysicsService")
PhysicsService:RegisterCollisionGroup("GAdmin Players")

PhysicsService:RegisterCollisionGroup("GAdmin NonPlayers")
PhysicsService:CollisionGroupSetCollidable("GAdmin Players", "GAdmin NonPlayers", false)

PhysicsService:RegisterCollisionGroup("GAdmin NonCollide")
PhysicsService:CollisionGroupSetCollidable("GAdmin NonCollide", "Default", false)
PhysicsService:CollisionGroupSetCollidable("GAdmin NonCollide", "GAdmin Players", false)

local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")

export type Connections = {RBXScriptConnection}
export type RankType = {
	Rank: number,
	Users: {any},
}

export type MainModule = {
	__metatable: string,
	__type: string,
	
	__version: string,
	__LoaderVersion: string,
	
	__Connections: {
		Listeners: {[number]: Connections}
	},
	
	GetDataActions: {[string]: (player: Player, Variables: any?) -> ()},
	__Topics: {[string]: (Data: {any}?) -> ()},
	
	Configure: (self: MainModule) -> (),
	GetAPI: (self: MainModule) -> API.APIModule,
	GetSignals: (self: MainModule) -> Signals.SignalManager,
	SetNewSettings: (self: MainModule, NewSettings: {any}) -> (),
	
	Listen: (self: MainModule, player: Player) -> Connections,
	DistributeCommands: (self: MainModule) -> {any},
	ClearConnections: (self: MainModule, Type: string?, Name: string?) -> (),
	
	SetServerCommands: (self: MainModule, ServerCommands: {any}) -> (),
	SetClientCommands: (self: MainModule, Module: ModuleScript) -> (),
	DistributeObjects: (self: MainModule, Folder: Folder) -> (),
}

_G.GAdmin = script
local Settings = require(script.Settings)
local API = require(script.API)

local Data = require(script.Data)
local Signals = require(Data.ClientFolder.SharedModules.Signals)

local Commands = require(script.Commands)
local Parser = require(script.Parser)
local DataStoreLoader = require(script.DataStoreLoader)

local Proxy = newproxy(true)
local GAdmin: MainModule = getmetatable(Proxy)

GAdmin.__metatable = "[GAdmin]: Metatable methods are restricted."
GAdmin.__type = "GAdmin Main"

GAdmin.__version = "v0.9.8"
GAdmin.__LoaderVersion = "v1.0.0"

GAdmin.__Connections = {
	Listeners = {}
}

GAdmin.GetDataActions = {
	ClientCommands = function(player)
		return Data.ClientCommandsList
	end,

	API = function(player, ...)
		return API.ClientCall(player, ...)
	end,
	
	Ranks = function(player)
		return Settings.Ranks
	end,
	
	GetCommands = function(player)
		return Commands
	end,
	
	GetRankCommands = function(player)
		local Rank = Data.SessionData[player.UserId].ServerRank
		local Info = {}
		
		for i, Setting in pairs(Commands) do
			if Setting.RequiredRank > Rank or Setting.Debug then
				continue
			end
			
			local RankName = API:GetRank(Setting.RequiredRank)
			Info[RankName] = Info[RankName] or {}
			
			local NewData = {
				Command = Setting.Command,
				Alias = Setting.Alias,
				Arguments = Setting.Arguments,
				References = Setting.References or Setting.Arguments,
				Rank = Setting.RequiredRank,
				UnDo = Setting.UnDo and `Un{Setting.Command}`
			}
			
			table.insert(Info[RankName], NewData)
		end
		
		for Rank, Setting in pairs(Settings.Ranks) do
			if Info[Rank] then
				continue
			end
			
			Info[Rank] = {}
		end

		return Info
	end,
	
	Ban = function(Caller, UserId, Reason, Duration, IpBan)
		if Caller.UserId == UserId then
			return "Error", "No permission to ban yourself."
		end
		
		local Name, CommandData = Parser:GetCommand("Ban")
		if Data.SessionData[Caller.UserId].ServerRank < CommandData.RequiredRank then
			return "Error", "Your rank is lower than required."
		end
		
		if IpBan and Settings.APIBanAccess and Settings.APIBanAccess > API:GetUserRank(Caller) then
			return "Error", `Your rank is lower than required for ip ban.`
		end
		
		if IpBan then
			local Reject, Error = API:BanIP(Caller, UserId, Reason, Duration)
			if Reject then
				return "Error", Error
			end
			
			return "Notify", `{Players:GetNameFromUserIdAsync(UserId)} succefully banned.`
		end
		
		local Reject, Error = API:Ban(Caller, UserId, Reason, Duration)
		if Reject then
			return "Error", Error
		end
		
		return "Notify", `{Players:GetNameFromUserIdAsync(UserId)} succefully banned.`
	end,
	
	UnBan = function(Caller, UserId)
		local Name, CommandData = Parser:GetCommand("UnBan")
		if Data.SessionData[Caller.UserId].ServerRank < CommandData.RequiredRank then
			return "Error", "Your rank is lower than required."
		end
		
		local Reject, Error = API:UnBan(Caller, UserId)
		if Reject then
			return "Error", Error
		end

		return "Notify", `{Players:GetNameFromUserIdAsync(UserId)} succefully banned.`
	end,
	
	GetBanlist = function(Caller)
		local Name, CommandData = Parser:GetCommand("Ban")
		Settings.BanlistAccess = Settings.BanlistAccess or CommandData.RequiredRank
		
		if not Data.SessionData[Caller.UserId] then
			repeat
				task.wait()
			until Data.SessionData[Caller.UserId]
		end
		
		if Data.SessionData[Caller.UserId].ServerRank < Settings.BanlistAccess then
			return
		end
		
		return API:GetBanlist()
	end,
	
	Logs = function(Caller)
		local Logs = {}
		for i, Log in ipairs(Data.Logs) do
			table.insert(Logs, {
				User = Log.User.Name,
				Time = Log.Time,
				Command = Log.Command,
				Arguments = Log.Arguments,
				ArgumentsString = Log.ArgumentsString,
			})
		end
		
		return Logs
	end,
	
	ChatLogs = function(Caller)
		local Logs = {}
		for i, Log in ipairs(Data.ChatLogs) do
			table.insert(Logs, {
				User = Log.User.Name,
				Time = Log.Time,
				Chat = Log.Chat
			})
		end

		return Logs
	end,
	
	NotifyRank = function(Caller)
		return Settings.RankNoticeAccess or 0
	end,
}

GAdmin.__Topics = {
	Ban = function(Caller, MessageData)
		for i, player in ipairs(Players:GetPlayers()) do
			if player.UserId ~= tonumber(MessageData.UserId, 10) then
				continue
			end
			
			local FormattedTime = DateTime.fromUnixTimestamp(tonumber(MessageData.Time)):FormatLocalTime("DD MMM YYYY", "en-us")
			Data.SessionData[player.UserId].Banned = {
				Reason = MessageData.Reason,
				Time = MessageData.Time
			}
			
			player:Kick(`You were banned for {FormattedTime}. Reason: {MessageData.Reason}`)
			break
		end
	end,
	
	RankUpdate = function(Caller, UserId, Rank)
		for i, player in ipairs(Players:GetPlayers()) do
			if player.UserId ~= tonumber(UserId, 10) then
				continue
			end
			
			Data.SessionData[player.UserId].Rank = Rank
			Data.SessionData[player.UserId].ServerRank = Rank

			Signals:Fire("Framework", player, "Notify", "Notify", `Your rank now is '{API:GetRank(Rank)}'.`)
			Signals:Fire("RankUpdate", player, Rank)
			
			break
		end
	end,
	
	GlobalMessage = function(Caller, Title, Message)
		Signals:FireAll("Framework", "Announce", Title, Message)
	end,
}

--== METATABLE METHODS ==--
function GAdmin:__tostring()
	return self.__type, self.__version
end

function GAdmin:__index(Key)
	return GAdmin[Key]
end

function GAdmin:__newindex(Key, Value)
	GAdmin[Key] = Value
	return Value
end

--== MAIN METHOD ==--
function GAdmin:Configure(LoaderVersion)
	print(`--== GAdmin {self.__version}`)
	print(`[GAdmin]: Configuring..`)
	
	Data.BinFolder.Name = "GAdmin Bin"
	Data.BinFolder.Parent = game.ReplicatedStorage
	
	local GlobalAPI = require(Data.ClientFolder.SharedModules.GlobalAPI)
	local function ConfigurePlayer(player)
		if table.find(Settings.Banned, player.UserId) or table.find(Settings.Banned, player.Name) then
			player:Kick(`You were blacklisted from playing this game.`)
			return
		end
		
		player.CharacterAdded:Connect(function(Character)
			GlobalAPI:SetModelCollision(Character, "GAdmin Players")
			Data.TempData[player.UserId] = {
				Health = Character.Humanoid.Health,
				MaxHealth = Character.Humanoid.MaxHealth,
				Speed = Character.Humanoid.WalkSpeed,
				JumpPower = Character.Humanoid.UseJumpPower and Character.Humanoid.JumpPower or Character.Humanoid.JumpHeight,
			}

			Character.Humanoid.Changed:Connect(function(Property)
				if not Data.TempData[player.UserId][Property] or Character.Humanoid[Property] == math.huge then
					return
				end

				Data.TempData[player.UserId][Property] = Character.Humanoid[Property]
			end)
		end)

		local Success, PlayerData = DataStoreLoader.Load(player.UserId, Settings.DataStores.PlayerData)
		if not Success then
			warn(`[GAdmin]: Unable to load data for player {player.Name} ({player.UserId})`)
			return
		end

		PlayerData = PlayerData or Data.DefaultPlayerData
		for i, v in pairs(Data.DefaultPlayerData) do
			if PlayerData[i] then
				continue
			end

			PlayerData[i] = v
		end

		if PlayerData.Banned and PlayerData.Banned.Time and DateTime.now().UnixTimestamp < tonumber(PlayerData.Banned.Time, 10) then
			local FormattedTime = DateTime.fromUnixTimestamp(tonumber(PlayerData.Banned.Time, 10)):FormatLocalTime("DD MMM YYYY", "en-us")
			player:Kick(`You were banned for {FormattedTime}. Reason: {PlayerData.Banned.Reason}`)
			return
		end

		PlayerData.Banned = false
		PlayerData.ServerRank = PlayerData.Rank

		Data.SessionData[player.UserId] = PlayerData
		API:CheckUserRank(player)

		if Data.ServerRankAccess and Data.ServerRankAccess > API:GetUserRank(player) then
			player:Kick(`Server is locked for ranks below '{API:GetRank(Data.ServerRankAccess)}'.`)
			return
		end

		if Settings.AdminAccess and Settings.AdminAccess > API:GetUserRank(player) then
			return
		end

		self:Listen(player)
	end
	
	--== CONFIGURING ALREADY EXISTING PLAYERS ==--
	for i, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(ConfigurePlayer)(player)
	end
	
	--== COLLECTING TOOLS INTO TABLE ==--
	for i, Tool in ipairs(game.ReplicatedStorage:GetDescendants()) do
		if not Tool:IsA("Tool") then
			continue
		end
		
		table.insert(Data.Tools, Tool)
	end
	
	for i, Tool in ipairs(game.ServerStorage:GetDescendants()) do
		if not Tool:IsA("Tool") then
			continue
		end

		table.insert(Data.Tools, Tool)
	end
	
	for i, Tool in ipairs(game.ServerScriptService:GetDescendants()) do
		if not Tool:IsA("Tool") then
			continue
		end

		table.insert(Data.Tools, Tool)
	end
	
	--== DISTRIBUTING CLIENT COMMANDS ==--
	self:DistributeCommands()
	
	--== REPOSITIONING CLIENT TO REPLICATEDSTORAGE ==--
	Signals:Set(Data.ClientFolder.Events)
	Data.ClientFolder.Parent = game.ReplicatedStorage
	
	Signals:Connect("FireCommand", function(player, Message)
		local FilteredMessage = "[Unable to filter message]"
		local Success, ErrorMessage = pcall(function()
			FilteredMessage = TextService:FilterStringAsync(Message, player.UserId, Enum.TextFilterContext.PublicChat)
		end)

		table.insert(Data.ChatLogs, {
			User = player,
			Time = tostring(DateTime.now().UnixTimestamp),
			Chat = FilteredMessage:GetNonChatStringForBroadcastAsync()
		})
		
		local MessageData = Parser:ParseMessage(player, Message, true)
		Parser:TriggerCommands(player, MessageData)
	end)
	
	if LoaderVersion ~= self.__LoaderVersion then
		Data.ClientFolder.StarterGui.GAdminGui.MainFrame.OldVersion.Visible = true
	end
	
	for i, Object in ipairs(Data.ClientFolder.StarterGui:GetChildren()) do
		local Clone = Object:Clone()
		Clone.Parent = game.StarterGui
		if Clone:IsA("LocalScript") then
			Clone.Enabled = true
		end
	end
	
	--== SETTING GADMIN ON PLAYER ==--
	Players.PlayerAdded:Connect(ConfigurePlayer)
	Players.PlayerRemoving:Connect(function(player)
		self:ClearConnections("Listeners", player.UserId)
		if Data.SessionData[player.UserId] then
			Data.SessionData[player.UserId].ServerRank = Data.SessionData[player.UserId].Rank
			local Success = DataStoreLoader.Save(player.UserId, Data.SessionData[player.UserId], Settings.DataStores.PlayerData)
			
			if Success then
				return
			end
			
			warn(`[GAdmin]: Unable to save data for player {player.Name} ({player.UserId})`)
		end
	end)
	
	--== SETTING OWNER RANK USER ==--
	for Rank, Setting in pairs(Settings.Ranks) do
		if Setting.Rank ~= 5 then
			continue
		end

		Settings.Ranks[Rank].Users = {API:GetOwner()}
		break
	end
	
	--== RETURNING DATA TO CLIENT ==--
	Signals:Connect("GetData", function(player, Action, ...)
		if not GAdmin.GetDataActions[Action] then
			return
		end
		
		return GAdmin.GetDataActions[Action](player, ...)
	end)
	
	--== RECIEVING SETTINGS FROM CLIENT ==--
	Signals:Connect("Settings", function(player, Setting, Value)
		if not Data.SessionData[player.UserId][Setting] or not table.find(Data.EditablePlayerData, Setting) or type(Data.SessionData[player.UserId][Setting]) ~= type(Value) then
			return
		end
		
		Data.SessionData[player.UserId][Setting] = Value
	end)
	
	MessagingService:SubscribeAsync(Settings.Topics.Global, function(Data)
		if not self.__Topics[Data.Data.Topic] then
			return
		end
		
		self.__Topics[Data.Data.Topic](Data.Sent, unpack(Data.Data.Arguments))
	end)
	
	print(`[GAdmin]: Game configured to run GAdmin.`)
	print("--==")
end

--== ADDONS ==--
function GAdmin:GetAPI()
	return API
end

function GAdmin:GetSignals()
	return Signals
end

function GAdmin:SetNewSettings(NewSettings)
	for Key, Value in pairs(Settings) do
		if not NewSettings[Key] then
			Settings[Key] = nil
			continue
		end
		
		Settings[Key] = NewSettings[Key]
	end
end

function GAdmin:SetServerCommands(Module)
	Module.Parent = script.Commands
	Module.Name = "AddonsCommands"
	
	local ServerCommands = require(Module)
	for i, Setting in ipairs(ServerCommands) do
		if Parser:GetCommand(Setting.Name) then
			warn(`[GAdmin Main]: Unable to load server command '{Setting.Command}'. Reason: Duplicated command.`)
			continue
		end
		
		for i, Alias in ipairs(Setting.Alias) do
			if not Parser:GetCommand(Alias) then
				continue
			end
			
			warn(`[GAdmin Main]: Removed Alias '{Alias}' of server command '{Setting.Command}'. Reason: Duplicated command.`)
			Setting.Alias[i] = nil
		end
		
		table.insert(Commands, Setting)
	end
end

function GAdmin:SetClientCommands(Module)
	Module:ClearAllChildren()
	Module.Name = "AddonsCommands"
	Module.Parent = Data.ClientFolder.Modules
end

function GAdmin:DistributeObjects(Folder)
	if not Folder then
		return
	end
	
	for i, Object in ipairs(Folder:GetChildren()) do
		if script.Objects:FindFirstChild(Object.Name) then
			warn(`[GAdmin Main]: Unable to load object '{Object.Name}'. Reason: Duplicated object.`)
			continue
		end
		
		Object.Parent = script.Objects
	end
end

--== COMMANDS EXECUTION ON CHATTED ==--
function GAdmin:Listen(player)
	if self.__Connections.Listeners[player.UserId] then
		self:ClearConnections("Listeners", player.UserId)
	end
	
	self.__Connections.Listeners[player.UserId] = {}
	self.__Connections.Listeners[player.UserId].ChatPrompt = player.Chatted:Connect(function(Message, Recipient)
		local FilteredMessage = "[Unable to filter message]"
		local Success, ErrorMessage = pcall(function()
			FilteredMessage = TextService:FilterStringAsync(Message, player.UserId, Enum.TextFilterContext.PublicChat)
		end)
		
		table.insert(Data.ChatLogs, {
			User = player,
			Time = tostring(DateTime.now().UnixTimestamp),
			Chat = FilteredMessage:GetNonChatStringForBroadcastAsync()
		})
		
		local MessageData = Parser:ParseMessage(player, Message)
		Parser:TriggerCommands(player, MessageData)
	end)
end

--== DISTRIBUTING CLIENT COMMANDS ==--
function GAdmin:DistributeCommands()
	Data.ClientCommandsList = {}
	for i, Setting in pairs(Commands) do
		if not Setting.Client then
			continue
		end
		
		Data.ClientCommandsList[Setting.Command] = Setting
	end

	return Data.ClientCommandsList
end

--== CLEAR EXISTING CONNECTIONS ==--
function GAdmin:ClearConnections(Type, Name)
	if not Type then
		for Type, Data in pairs(self.__Connections) do
			for i, Connection in pairs(Data) do
				Connection:Disconnect()
			end
			
			self.__Connections[Type] = {}
		end
		
		return
	end
	
	if not self.__Connections[Type] or (Name and not self.__Connections[Type][Name]) then
		return
	end
	
	if Name then
		
		for i, Connection in pairs(self.__Connections[Type][Name]) do
			Connection:Disconnect()
		end
		
		self.__Connections[Type][Name] = nil
		return
	end
	
	for Name, Data in pairs(self.__Connections[Type]) do
		for i, Connection in pairs(Data) do
			Connection:Disconnect()
		end
	end
	
	self.__Connections[Type] = {}
end

return Proxy :: MainModule
