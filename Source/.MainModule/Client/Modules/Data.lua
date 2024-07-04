local TextService = game:GetService("TextService")
local Client = script.Parent.Parent
local SharedModules = Client.SharedModules

local Signals = require(SharedModules.Signals)
local Data = {}

Data.MainFrames = {
	About = {
		Name = "About",
		Frame = "AboutFrame",
		Order = 1,
		Image = "rbxassetid://"
	},
	
	Commands = {
		Name = "Commands",
		Frame = "CommandFrame",
		Order = 2,
		Image = "rbxassetid://"
	},
	
	Admins = {
		Name = "Admins",
		Frame = "AdminFrame",
		Order = 3,
		Image = "rbxassetid://"
	},
	
	Settings = {
		Name = "Settings",
		Frame = "Settings",
		Order = 4,
		Image = "rbxassetid://"
	},
}

Data.CmdBar = nil
Data.CmdBarConnections = {}

Data.Loops = {}
Data.Device = "Computer"

Data.Banlist = {}
Data.ToUnBan = nil

Data.Ranks = {}
Data.OrderedRanks = {}
Data.AssetId = 18192645218

Data.Rank = {
	Name = "Default",
	Id = 0,
}

Data.NotifySettings = {}
Data.Access = {}

Data.Updates = {
	[1] = {
		Date = "2 July, 2024",
		Blocks = {
			"Added TopBarPlus. (Credits to ForeverHD.)",
			"Added .",
			"Fixed Parser."
		}
	},
	
	[2] = {
		Date = "29 June, 2024",
		Blocks = {
			"Added API Bans",
			"Added View command.",
			"Fixed Parser."
		}
	},
}

Data.Settings = {
	[1] = {
		Name = "Prefix",
		Type = "Text",
		
		Default = ";",
		Function = function(Prefix)
			if Prefix:gsub("%s", "") == "" then
				return
			end
			
			Signals:Fire("Settings", "Prefix", Prefix)
		end,
	},
	
	[2] = {
		Name = "Default Kick Message",
		Type = "Text",
		
		Default = "No Reason",
		Function = function(Message)
			if Message:gsub("%s", "") == "" then
				return
			end
			
			local FilteredMessage = ""
			local Success, ErrorMessage = pcall(function()
				Message = TextService:FilterStringAsync(Message, game.Players.LocalPlayer.UserId, Enum.TextFilterContext.PublicChat)
			end)
			
			Signals:Fire("Settings", "DefaultKickMesssage", FilteredMessage:GetNonChatStringForUserAsync())
		end,
	},
	
	[3] = {
		Name = "Default Ban Message",
		Type = "Text",
		
		Default = "No Reason",
		Function = function(Message)
			if Message:gsub("%s", "") == "" then
				return
			end

			local FilteredMessage = ""
			local Success, ErrorMessage = pcall(function()
				Message = TextService:FilterStringAsync(Message, game.Players.LocalPlayer.UserId, Enum.TextFilterContext.PublicChat)
			end)

			Signals:Fire("Settings", "DefaultBanMesssage", FilteredMessage)
		end,
	},
}

return Data
