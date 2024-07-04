local TextService = game:GetService("TextService")
local Settings = require(script.Parent.Settings)
local Data = {}

Data.ClientConfigured = false
Data.SessionData = {}
Data.TempData = {}

Data.ChatLogs = {}
Data.Session = {
	Bans = {},
	Ranks = {}
}

Data.ServerRankAccess = 0
Data.Loops = {}
Data.DefaultPlayerData = {
	Rank = 0,
	ServerRank = 0,
	RankExpiresIn = nil,
	Prefix = Settings.DefaultPrefix,
	DefaultKickMessage = Settings.DefaultKickMessage,
	DefaultBanMessage = Settings.DefaultBanMessage,
	Banned = false,
}

Data.EditablePlayerData = {"Prefix", "DefaultKickMessage", "DefaultBanMessage"}
Data.Tools = {}

Data.Logs = {}
Data.CommandArgumentsSigns = {
	Optional = "?",
	MultiType = "|",
	InGame = "!",
	OptionalInGame = "@",
	FilterString = "#",
	EqualRank = "+",
}

Data.DefaultArguments = {
	Player = function(Caller)
		return Caller
	end,
	
	Object = function(Caller)
		return
	end,
	
	Tool = function(Caller)
		return
	end,
	
	Rank = function(Caller)
		return
	end,
	
	Stat = function(Caller)
		return
	end,
	
	number = function(Caller)
		return 0
	end,
	
	string = function(Caller)
		return "None"
	end,
}

Data.ArgumentsTransform = {
	Player = function(Caller, String, Sign)
		local InGame = Sign == Data.CommandArgumentsSigns.InGame or Sign == Data.CommandArgumentsSigns.OptionalInGame
		local Player
		
		if tonumber(String, 10) then
			local UserId = tonumber(String, 10)
			return UserId
		end
		
		if String:lower() == "me" then
			return Caller
		end
		
		if String:lower() == "random" then
			local Players = game.Players:GetPlayers()
			return Players[math.random(1, #Players)]
		end
		
		if table.find({"all", "everyone"}, String:lower()) then
			if Data.SessionData[Caller.UserId].ServerRank < Settings.EveryoneAccess then
				return "ERROR", `No permission to use 'All' as a player.`
			end
			
			return "PlayerAll"
		end
		
		for i, player in ipairs(game.Players:GetPlayers()) do
			if String:lower() ~= player.Name:lower():sub(1, #String) and String:lower() ~= player.DisplayName:lower():sub(1, #String) then
				continue
			end

			Player = player
		end
		
		if not Player and not InGame then
			local Success, Response = pcall(function()
				return game.Players:GetUserIdFromNameAsync(String)
			end)
			
			return Success and Response or nil
		end
		
		return Player
	end,
	
	Object = function(Caller, String)
		for i, Part in ipairs(workspace:GetDescendants()) do
			if Part.Name:sub(1, #String):lower() ~= String:lower() then
				continue
			end
			
			return Part
		end
	end,
	
	Tool = function(Caller, String)
		for i, Tool in ipairs(Data.Tools) do
			local SecondName = Tool:GetAttribute("SecondName")
			if Tool.Name:lower():sub(1, #String) ~= String:lower() and (SecondName and SecondName:lower() ~= String:lower()) then
				continue
			end
			
			if Tool.Name == "Building Tools" and Settings.BToolsAccess > Data.SessionData[Caller.UserId].ServerRank then
				continue
			end
			
			return Tool
		end
	end,
	
	Rank = function(Caller, String)
		local Rank
		for RankName, Setting in pairs(Settings.Ranks) do
			if Setting.Rank ~= tonumber(String, 10) and RankName:lower():sub(1, #String) ~= String:lower() then
				continue
			end

			Rank = Setting.Rank
			break
		end

		return Rank
	end,
	
	Stat = function(Caller, String)
		local Object
		for i, Part in ipairs(Caller:GetDescendants()) do
			if not Part:IsA("NumberValue") and not Part:IsA("IntValue") and Part.Name:sub(1, #String):lower() ~= String:lower() then
				continue
			end
			
			Object = Part.Name
			break
		end
		
		return Object
	end,
	
	number = function(Caller, String)
		return tonumber(String, 10)
	end,
	
	string = function(Caller, String, Sign)
		if Sign == Data.CommandArgumentsSigns.FilterString then
			local Success, Object = pcall(function()
				return TextService:FilterStringAsync(String, Caller.UserId, Enum.TextFilterContext.PublicChat)
			end)
			
			if not Success then
				return "[Unable to filter]"
			end
			
			String = Object:GetNonChatStringForBroadcastAsync()
		end
		
		return String
	end,
}

Data.IgnoreClasses = {"Object"}

Data.ClientCommandsList = {}
Data.ClientFolder = script.Parent.Client

Data.BinFolder = Instance.new("Folder")
return Data
