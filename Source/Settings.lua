local Settings = {}

Settings.Ranks = { -- In Users you can put either userid or username.
	Owner = {
		Rank = 5,
	},

	ChiefAdmin = {
		Rank = 4,
		Users = {}
	},

	Admin = {
		Rank = 3,
		Users = {}
	},

	Mod = {
		Rank = 2,
		Users = {}
	},

	Trusted = {
		Rank = 1,
		Users = {}
	},

	Default = {
		Rank = 0
	}
}

Settings.AdminAccess = 1 -- Required rank for Gui to work for player. Make nil for free access.
Settings.RankNoticeAccess = 1 -- Required rank for notice to appear saying player's rank. Make nil for all ranks.
Settings.BToolsAccess = 4 -- Required rank to give yourself Building Tools.

Settings.EveryoneAccess = 3 -- rank requirments to use All as a player.
Settings.BanlistAccess = 3 -- Player access to banlist from provided rank and higher. (Leave blank for autofill.)

Settings.DefaultKickMessage = "No Reason" -- The kick message if caller didn't put any reason themselfes.
Settings.DefaultBanMessage = "No Reason" -- The ban message if caller didn't put any reason themselfes.

Settings.CommandInLineDebounce = false -- Will the commands wait for current command to complete in the batch or not. (Batch example: ;rank ;cmds ;fly)
Settings.DefaultPrefix = ";"  -- Default prefix.
Settings.PrivateServerOwner = 1 -- Default private server owner rank.
Settings.DefaultRank = 0  -- Default rank.
Settings.Banned = {}

Settings.GroupRanks = { -- Ranks from groups.
	[0] = { -- Group Id
		-- Ranks
		[255] = "Owner",
		[254] = "ChiefAdmin",
		[1] = "Vip"
	}
}

Settings.DataStores = { -- DataStore names.
	GlobalData = "GAdmin GlobalData",
	PlayerData = "GAdmin PlayerData",
}

Settings.Topics = { -- Topics for MessagingService.
	Global = "GAdmin Callback"
}

return Settings
