local Settings = {}

--== << RANKS >> ==--
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

--== << NOTIFIES >> ==--
Settings.NoNotifies = false -- User won't get notifies.
Settings.NoWarns = false -- User won't get warning notifies.
Settings.NoErrors = false -- User won't get error notifies.
Settings.IncorrectCommandNotify = true -- Warn user about trying to call non existing command.

--== << ACCESS >> ==--
Settings.AutoCompleteChatCommands = true -- Slash commands will be auto completed.
Settings.AdminAccess = 1 -- Required rank for Gui to work for player. Make nil for free access.
Settings.IPBanAccess = 4 -- Required  rank for IP bans.

Settings.RankNoticeAccess = 1 -- Required rank for notice to appear saying player's rank. Make nil for all ranks.
Settings.BToolsAccess = 4 -- Required rank to give yourself Building Tools.

Settings.EveryoneAccess = 3 -- rank requirments to use All as a player.
Settings.BanlistAccess = 3 -- Player access to banlist from provided rank and higher. (Leave blank for autofill.)

--== << DEFAULT VALUES >> ==--
Settings.DefaultKickMessage = "No Reason" -- The kick message if caller didn't put any reason themselfes.
Settings.DefaultBanMessage = "No Reason" -- The ban message if caller didn't put any reason themselfes.

Settings.DefaultRank = 0  -- Default rank.
Settings.DefaultPrefix = ";"  -- Default prefix.

--== << PRIVATE SERVER >> ==--
Settings.PrivateServerOwner = 1 -- Default private server owner rank.
Settings.PrivateServerBlacklist = {"Rank", "UnRank", "GlobalMessage", "Ban", "Ban2", "UnBan"} -- Blacklist of commands that private server owner can't do.

--== << COMMANDS >> ==--
Settings.CommandInLineDebounce = false -- Will the commands wait for current command to complete in the batch or not. (Batch example: ;rank ;cmds ;fly)
Settings.CommandsPerMinute = 3 -- Will set commands per minute debounce. (if *Command Debounce* setting is on.)
Settings.CommandDebounce = false -- If true, user wont able to call any other commands after *CommandPerMinute* setting limit.

--== << GROUP RANKS >> ==--
Settings.GroupRanks = { -- Ranks from groups.
	[0] = { -- Group Id
		-- Ranks
		[255] = "Owner",
		[254] = "ChiefAdmin",
		[1] = "Vip"
	}
}

--== << CONSTANT VALUES >> ==--
Settings.Banned = {} -- Banlist.

Settings.DataStores = { -- DataStore names.
	GlobalData = "GAdmin GlobalData",
	PlayerData = "GAdmin PlayerData",
}

return Settings
