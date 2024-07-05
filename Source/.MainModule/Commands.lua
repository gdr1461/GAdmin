local Data = require(script.Parent.Data)
local DataStoreLoader = require(script.Parent.DataStoreLoader)
local Settings = require(script.Parent.Settings)

local API = require(script.Parent.API)
local Signals = API:GetSignals()

--[[
Arguments:
 [Player]: Returns player instance. Default: Caller himself.
 [Tool]: Returns tool instance. Default: nil.
 [Rank]: Returns rank id. Default: nil.
 [Object]: Returns descendant of workspace.
 [Stat]: Returns name of statistic in player's leaderstats.
 [number]: Returns number. Default: 0.
 [string]: Returns string. Default: "".
]]

--[[
Argument signs:
 [;]: Default argument;
 [!]: Player must be online;
 [?]: Optional argument;
 [@]: Optional player must be online;
 [#]: If string, filter;
 [+]: Rank cannot be higher or equal to player's rank;
]]

--[[
{
	Command: name, -- Name of the command.
	RequiredRank: number, -- Required rank to use command.
	Alias: {"OtherName"},  -- Other names of the command.
	
	UppercaseMatters: boolean, -- Will uppercase matter when typing out the command or not.
	Loop: boolean, -- Determines if command will be re-runned after player's death.
	
	Client: boolean, -- Returns command to the client.
	ClientOnly: boolean -- Command will run on the client. Use module ClientCommands for client commands.
	CallerClient: boolean -- Command will run on the client of caller.

	Arguments: {"Player;", "string;", "number;"}, -- Arguments of the command.
	References: {"Player", "Reason", "Time"}, -- Name of the arguments in the gui Commands section.
	ArgPermissions = {3, 2, 1} -- Required rank to actually use arguments of the command. (Place in the same order as your arguments.)
	
	UnDo: (Caller: Player, Argumentss: {any}) -> any, -- Undo function of command. Leave as 'true' for ClientOnly commands. All arguments are optional.
	Function: (Caller: Player, Arguments: {any}) -> any, -- Main function of command.
	PreFunction: (Caller: Player, Arguments: {any}) -> any, -- Runs before the main function of the command.
}
]]

local Commands = {
	--== DEFAULT ==--
	{
		Command = "About",
		RequiredRank = 0,
		Alias = {"Info"},
		UppercaseMatters = false,
		Client = true,
		
		Arguments = {},
		References = {},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "AboutFrame")
		end,
	},
	
	{
		Command = "Help",
		RequiredRank = 0,
		Alias = {"h"},
		UppercaseMatters = false,
		Client = true,
		
		Arguments = {},
		References = {},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "ResetMainFrame")
		end,
	},
	
	{
		Command = "Commands",
		RequiredRank = 0,
		Alias = {"cmds", "cmd", "command"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {},
		References = {},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "CommandFrame")
		end,
	},
	
	{
		Command = "SeeRank",
		RequiredRank = 0,
		Alias = {"PlayerRank"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Rank = API:GetUserRank(player)
			local RaknName = API:GetRank(Rank)

			local Name = tonumber(player) and game.Players:GetNameFromUserIdAsync(player) or player.Name
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{Name}'s rank is '{RaknName}'.`)
		end,
	},
	
	{
		Command = "Ranks",
		RequiredRank = 0,
		Alias = {"AllRanks"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {},
		References = {},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "AdminFrame", 1)
		end,
	},
	
	{
		Command = "ServerRanks",
		RequiredRank = 0,
		Alias = {"Server", "ServerRank"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {},
		References = {},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "AdminFrame", 2)
		end,
	},
	
	{
		Command = "Banlist",
		RequiredRank = 0,
		Alias = {"bans", "list", "banland"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {},
		References = {},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "AdminFrame", 3)
		end,
	},
	
	{
		Command = "Settings",
		RequiredRank = 0,
		Alias = {"Setting"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {},
		References = {},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "Settings")
		end,
	},
	
	--== TRUSTED ==--
	{
		Command = "Refresh",
		RequiredRank = 1,
		Alias = {"R", "Re", "Ref", "Reset"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {2},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Position = player.Character:GetPivot()
			
			player:LoadCharacter()
			player.Character:PivotTo(Position)
		end,
	},
	
	{
		Command = "Respawn",
		RequiredRank = 1,
		Alias = {"Res"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {2},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			player:LoadCharacter()
		end,
	},
	
	{
		Command = "Invisible",
		RequiredRank = 1,
		Alias = {"Invis"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {2},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Character = player.Character or player.CharacterAdded:Wait()
			
			for i, Part in ipairs(Character:GetDescendants()) do
				if not Part:IsA("BasePart") then
					continue
				end
				
				Part.Transparency = 1
			end
		end,
	},
	
	{
		Command = "Visible",
		RequiredRank = 1,
		Alias = {"Vis"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {2},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Character = player.Character or player.CharacterAdded:Wait()

			for i, Part in ipairs(Character:GetDescendants()) do
				if not Part:IsA("BasePart") or Part.Name == "HumanoidRootPart" then
					continue
				end

				Part.Transparency = 1
			end
		end,
	},
	
	{
		Command = "Transparency",
		RequiredRank = 1,
		Alias = {"Trans"},
		UppercaseMatters = false,
		Client = true,

		Arguments = {"Player@", "number?"},
		References = {"Player", "Number"},
		ArgPermissions = {2, 1},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Transparency = Arguments[2]
			local Character = player.Character or player.CharacterAdded:Wait()

			for i, Part in ipairs(Character:GetDescendants()) do
				if not Part:IsA("BasePart") or Part.Name == "HumanoidRootPart" then
					continue
				end

				Part.Transparency = Transparency
			end
		end,
	},
	
	--== MODERATOR ==--
	{
		Command = "Logs",
		RequiredRank = 2,
		Alias = {"Log"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Signals:Fire("Framework", player, "OpenFrame", "Logs")
		end,
	},
	
	{
		Command = "ChatLogs",
		RequiredRank = 2,
		Alias = {"ChatLog", "CLogs", "CLog"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Signals:Fire("Framework", player, "OpenFrame", "ChatLogs")
		end,
	},
	
	{
		Command = "God",
		RequiredRank = 2,
		Alias = {},
		UppercaseMatters = false,
		
		Client = true,
		ClientOnly = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {2},
		
		UnDo = function(Caller, Arguments)
			local player = Arguments[1]
			if not Data.TempData[player.UserId].God then
				return
			end
			
			Data.TempData[player.UserId].God = false
			Caller.Character.Humanoid.MaxHealth = Data.TempData[player.UserId].MaxHealth
			Caller.Character.Humanoid.Health = Caller.Character.Humanoid.MaxHealth
		end,
		
		Function = function(Caller, Arguments)
			local player = Arguments[1]
			if Data.TempData[player.UserId].God then
				return
			end
			
			Data.TempData[player.UserId].God = true
			Caller.Character.Humanoid.MaxHealth = math.huge
			Caller.Character.Humanoid.Health = math.huge
		end,
	},
	
	{
		Command = "Speed",
		RequiredRank = 2,
		Alias = {"WalkSpeed", "Spd"},
		UppercaseMatters = false,

		Client = true,
		ClientOnly = false,

		Arguments = {"Player@", "number;"},
		References = {"Player", "Speed"},
		ArgPermissions = {2, 2},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Speed = Arguments[2]
			
			Caller.Character.Humanoid.WalkSpeed = Speed
		end,
	},
	
	{
		Command = "Fly",
		RequiredRank = 2,
		Alias = {"Flight"},
		UppercaseMatters = false,

		Client = true,
		ClientOnly = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},
		UnDo = true
	},
	
	{
		Command = "Noclip",
		RequiredRank = 2,
		Alias = {"Noclippable"},
		UppercaseMatters = false,

		Client = true,
		ClientOnly = true,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},
		UnDo = true
	},
	
	{
		Command = "Health",
		RequiredRank = 2,
		Alias = {"SetHealth"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "number;"},
		References = {"Player", "Amount"},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local NewHealth = Arguments[2]
			
			player.Character.Humanoid.MaxHealth = NewHealth
			player.Character.Humanoid.Health = NewHealth
		end,
	},
	
	{
		Command = "Kick",
		RequiredRank = 2,
		Alias = {"kickplayer"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@", "string?"},
		References = {"Player", "Reason"},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Reason = Arguments[2] or Data.SessionData[Caller.UserId].DefaultKickMessage

			player:Kick(`You were kicked. Reason: {Reason}`)
		end,
	},
	
	{
		Command = "Heal",
		RequiredRank = 2,
		Alias = {"SetHealth"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
		end,
	},
	
	{
		Command = "Kill",
		RequiredRank = 2,
		Alias = {"DoNotLive", "NoLife", "Nah"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			player.Character.Humanoid.Health = 0
		end,
	},
	
	{
		Command = "Damage",
		RequiredRank = 2,
		Alias = {"Dmg"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "number;"},
		References = {"Player", "Amount"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Damage = Arguments[2]
			
			player.Character.Humanoid.Health -= Damage
		end,
	},
	
	{
		Command = "Teleport",
		RequiredRank = 2,
		Alias = {"Tp"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "Player;"},
		References = {"Player", "Player2"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local ToPlayer = Arguments[2]

			player.Character:PivotTo(ToPlayer.Character:GetPivot() * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
		end,
	},
	
	{
		Command = "To",
		RequiredRank = 2,
		Alias = {"Goto"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Caller.Character:PivotTo(player.Character:GetPivot() * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
		end,
	},
	
	{
		Command = "Bring",
		RequiredRank = 2,
		Alias = {"Br"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			player.Character:PivotTo(Caller.Character:GetPivot() * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
		end,
	},
	
	{
		Command = "Move",
		RequiredRank = 2,
		Alias = {"Push"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "number;"},
		References = {"Player", "Studs"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Studs = Arguments[2]
			
			player.Character:PivotTo(player.Character:GetPivot() * CFrame.new(0, 0, -Studs))
		end,
	},
	
	--== ADMIN ==--
	{
		Command = "Give",
		RequiredRank = 3,
		Alias = {"Tool"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "Tool;"},
		References = {"Player", "Tool"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Tool = Arguments[2]
			
			Tool:Clone().Parent = player.Backpack
		end,
	},
	
	{
		Command = "PermGive",
		RequiredRank = 3,
		Alias = {"PermTool"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player@", "Tool;"},
		References = {"Player", "Tool"},
		
		ArgPermissions = {},
		Loop = true,
		
		UnDo = function(Caller, Arguments)
			local player = Arguments[1]
		end,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Tool = Arguments[2]

			Tool:Clone().Parent = player.Backpack
		end,
	},
	
	{
		Command = "ServerMessage",
		RequiredRank = 3,
		Alias = {"SM", "SMessage"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"string#"},
		References = {"Message"},

		ArgPermissions = {},
		Function = function(Caller, Arguments)
			local Message = Arguments[1]
			Signals:FireAll("Framework", "Announce", `[Server] {Caller.Name}:`, Message)
		end,
	},
	
	{
		Command = "TempRank",
		RequiredRank = 3,
		Alias = {"TR", "TRank", "SeverRank"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player!", "Rank+"},
		References = {"Player", "Rank"},

		ArgPermissions = {},
		Loop = true,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Rank = Arguments[2]
			
			if Caller == player then
				Signals:Fire("Framework", Caller, "Notify", "Error", "No permission to give yourself a rank.")
				return
			end
			
			Data.SessionData[player.UserId].ServerRank = Rank
			Data.SessionData[player.UserId].ServerRank = Rank
			
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{player.Name} is now '{API:GetRank(Rank)}'.`)
			Signals:Fire("Framework", player, "Notify", "Notify", `Your rank now is '{API:GetRank(Rank)}'.`)
			Signals:Fire("RankUpdate", player, Rank)
		end,
	},
	
	{
		Command = "View",
		RequiredRank = 3,
		Alias = {"SeePlayer"},
		UppercaseMatters = false,
		
		Client = true,
		ClientOnly = true,
		CallerClient = true,

		Arguments = {"Player!"},
		References = {"Player"},
		ArgPermissions = {},
	},
	
	{
		Command = "Ban",
		RequiredRank = 3,
		Alias = {"banplayer"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {},
		References = {},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "OpenFrame", "BanFrame")
		end,
	},
	
	{
		Command = "Ban2",
		RequiredRank = 3,
		Alias = {"banplayer2"},
		UppercaseMatters = false,
		Client = false,
		
		Arguments = {"Player;", "number?", "string?"},
		References = {"Player", "Seconds", "Reason"},
		ArgPermissions = {},
		
		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Time = Arguments[2]
			local Reason = Arguments[3] or Data.SessionData[Caller.UserId].DefaultBanMessage
			
			if typeof(player) == "Instance" then
				player = player.UserId
			end
			
			if Caller.UserId == player then
				Signals:Fire("Framework", Caller, "Notify", "Error", "No permission to ban yourself.")
				return
			end
			
			local Status, Error = API:Ban(Caller, player, Reason, Time)
			if not Error then
				return
			end
			
			Signals:Fire("Framework", Caller, "Notify", "Error", Error)
		end,
	},
	
	{
		Command = "Change",
		RequiredRank = 3,
		Alias = {},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@", "Stat;", "number;"},
		References = {"Player", "Stat", "Value"},
		ArgPermissions = {4, 3, 3},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Value = Arguments[3]
			
			local StatName = Arguments[2]
			local Statistic = player:FindFirstChild(StatName, true)
			
			if Value ~= Value then
				Signals:Fire("Framework", Caller, "Notify", "Error", "Value cannot be NaN.")
				return
			end
			
			Statistic.Value = Value
		end,
	},
	
	{
		Command = "Add",
		RequiredRank = 3,
		Alias = {},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@", "Stat;", "number;"},
		References = {"Player", "Stat", "Value"},
		ArgPermissions = {4, 3, 3},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Value = Arguments[3]

			local StatName = Arguments[2]
			local Statistic = player:FindFirstChild(StatName, true)

			if Value ~= Value then
				Signals:Fire("Framework", Caller, "Notify", "Error", "Value cannot be NaN.")
				return
			end

			Statistic.Value += Value
		end,
	},
	
	{
		Command = "Sub",
		RequiredRank = 3,
		Alias = {"Substract"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@", "Stat;", "number;"},
		References = {"Player", "Stat", "Value"},
		ArgPermissions = {4, 3, 3},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Value = Arguments[3]

			local StatName = Arguments[2]
			local Statistic = player:FindFirstChild(StatName, true)

			if Value ~= Value then
				Signals:Fire("Framework", Caller, "Notify", "Error", "Value cannot be NaN.")
				return
			end

			Statistic.Value -= Value
		end,
	},
	
	{
		Command = "Mute",
		RequiredRank = 3,
		Alias = {},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		UnDo = function(Caller, Arguments)
			local player = Arguments[1]
			Signals:Fire("Framework", player, "Muted", false)
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{player.Name} is unmuted.`)
		end,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Signals:Fire("Framework", player, "Muted", true)
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{player.Name} is muted.`)
		end,
	},
	
	{
		Command = "CmdBar",
		RequiredRank = 3,
		Alias = {"CommandBar"},
		UppercaseMatters = false,
		
		Client = true,
		ClientOnly = true,

		Arguments = {"Player@"},
		References = {"Player"},
		
		ArgPermissions = {4},
		UnDo = true
	},
	
	--== CHIEF ADMIN ==--
	{
		Command = "Rank",
		RequiredRank = 4,
		Alias = {"PermRank"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player;", "Rank+"},
		References = {"Player", "Rank"},

		ArgPermissions = {},
		Loop = true,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Rank = Arguments[2]
			
			local UserId = typeof(player) == "Instance" and player.UserId or tonumber(player, 10)
			local Name = typeof(player) == "Instance" and player.Name or game.Players:GetNameFromUserIdAsync(UserId)

			if Caller == player then
				Signals:Fire("Framework", Caller, "Notify", "Error", "No permission to give yourself a rank.")
				return
			end
			
			if typeof(player) == "Instance" then
				if Data.SessionData[player.UserId].Rank == Rank then
					Signals:Fire("Framework", Caller, "Notify", "Error", "User already has this rank.")
					return
				end
				
				Data.SessionData[player.UserId].Rank = Rank
				Data.SessionData[player.UserId].ServerRank = Rank
				
				Signals:Fire("Framework", Caller, "Notify", "Notify", `{Name} is now '{API:GetRank(Rank)}'.`)
				Signals:Fire("Framework", player, "Notify", "Notify", `Your rank now is '{API:GetRank(Rank)}'.`)
				Signals:Fire("RankUpdate", player, Rank)
				return
			end
			
			local Success, PlayerData = DataStoreLoader.Load(UserId, Settings.DataStores.PlayerData)
			PlayerData = PlayerData or Data.DefaultPlayerData
			
			if not Success or PlayerData.Rank == Rank then
				Signals:Fire("Framework", Caller, "Notify", "Error", "User already has this rank.")
				return
			end
			
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{Name} is now '{API:GetRank(Rank)}'.`)
			PlayerData.Rank = Rank
			DataStoreLoader.Save(UserId, PlayerData, Settings.DataStores.PlayerData)
			
			API:PushMessage({
				Topic = "RankUpdate",
				Arguments = {
					UserId,
					Rank
				}
			})
		end,
	},
	
	{
		Command = "UnRank",
		RequiredRank = 4,
		Alias = {"ResetRank"},
		UppercaseMatters = false,

		Client = false,
		ClientOnly = false,

		Arguments = {"Player;"},
		References = {"Player"},

		ArgPermissions = {},
		Loop = true,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Rank = 0

			local UserId = typeof(player) == "Instance" and player.UserId or tonumber(player, 10)
			local Name = typeof(player) == "Instance" and player.Name or game.Players:GetNameFromUserIdAsync(UserId)

			if Caller == player then
				Signals:Fire("Framework", Caller, "Notify", "Error", "No permission to reset your rank.")
				return
			end

			if typeof(player) == "Instance" then
				Data.SessionData[player.UserId].Rank = 0
				Data.SessionData[player.UserId].ServerRank = 0

				Signals:Fire("Framework", Caller, "Notify", "Notify", `{Name} is now '{API:GetRank(Rank)}'.`)
				Signals:Fire("Framework", player, "Notify", "Notify", `Your rank now is '{API:GetRank(Rank)}'.`)
				Signals:Fire("RankUpdate", player, Rank)
				return
			end

			local Success, PlayerData = DataStoreLoader.Load(UserId, Settings.DataStores.PlayerData)
			PlayerData = PlayerData or Data.DefaultPlayerData
			
			Signals:Fire("Framework", Caller, "Notify", "Notify", `{Name} is now '{API:GetRank(Rank)}'.`)
			PlayerData.Rank = Rank
			
			DataStoreLoader.Save(UserId, PlayerData, Settings.DataStores.PlayerData)
			API:PushMessage({
				Topic = "RankUpdate",
				Arguments = {
					UserId,
					Rank
				}
			})
		end,
	},
	
	{
		Command = "ResetValues",
		RequiredRank = 4,
		Alias = {"ResetStats", "ResetLeaderstats"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			for i, Object in ipairs(player:GetDescendants()) do
				if not Object:IsA("NumberValue") and not Object:IsA("IntValue") then
					continue
				end
				
				Object.Value = 0
			end
		end,
	},
	
	{
		Command = "Lock",
		RequiredRank = 4,
		Alias = {"LockPlayer"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Data.TempData[player.UserId].Locked = not Data.TempData[player.UserId].Locked
			
			for i, Object in ipairs(player.Character:GetDescendants()) do
				if not Object:IsA("BasePart") or Object.Name == "HumanoidRootPart" then
					continue
				end

				Object.Anchored = Data.TempData[player.UserId].Locked
			end
		end,
	},
	
	{
		Command = "BTools",
		RequiredRank = 4,
		Alias = {"BuildingTools"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@"},
		References = {"Player"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			Data.ServerFolder.Objects["Building Tools"]:Clone().Parent = player.Backpack
		end,
	},
	
	{
		Command = "ServerLock",
		RequiredRank = 4,
		Alias = {"SLock", "SL"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Rank+"},
		References = {"Rank"},
		ArgPermissions = {},

		UnDo = function(Caller, Arguments)
			Signals:Fire("Framework", Caller, "Notify", "Warn", `Server has been unlocked for everyone.`)
		end,

		Function = function(Caller, Arguments)
			local Rank = Arguments[1]
			if Data.ServerRankAccess == Rank then
				Signals:Fire("Framework", Caller, "Notify", "Warn", `Server is already locked for ranks below {API:GetRank(Rank)}.`)
				return
			end
			
			Data.ServerRankAccess = Rank
			for i, player in ipairs(game.Players:GetPlayers()) do
				if API:GetUserRank(player) > Rank then
					continue
				end
				
				player:Kick(`Server is locked for ranks below '{API:GetRank(Data.ServerRankAccess)}'.`)
			end
			
			Signals:Fire("Framework", Caller, "Notify", "Warn", `Server has been locked for ranks below {API:GetRank(Rank)}.`)
		end,
	},
	
	{
		Command = "Time",
		RequiredRank = 4,
		Alias = {"ClockTime", "DayTime"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"number;"},
		References = {"Hour"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local RawTime = Arguments[1]
			local Time = RawTime % 24
			
			game.Lighting.ClockTime = Time
		end,
	},
	
	{
		Command = "Shutdown",
		RequiredRank = 4,
		Alias = {"ServerShutdown", "SS"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {},
		References = {},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			for i, player in ipairs(game.Players:GetPlayers()) do
				player:Kick(`{API:GetRank(API:GetUserRank(Caller))} {Caller.Name} shutdowned the server.`)
			end
		end,
	},
	
	{
		Command = "GlobalMessage",
		RequiredRank = 4,
		Alias = {"GM", "GMessage"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"string#"},
		References = {"Message"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local Message = Arguments[1]
			print("works")
			API:PushMessage({
				Topic = "GlobalMessage",
				Arguments = {
					`[Global]: {Caller.Name}`,
					Message
				}
			})
		end,
	},
	
	--== OWNER ==--
	{
		Command = "Notice",
		RequiredRank = 5,
		Alias = {"Notify"},
		UppercaseMatters = false,
		Client = false,

		Arguments = {"Player@", "string#"},
		References = {"Player", "Message"},
		ArgPermissions = {},

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local Message = Arguments[2]
			
			Signals:Fire("Framework", player, "Notify", "Notify", Message)
		end,
	},
	
	{
		Command = "DelObject",
		RequiredRank = 5,
		Alias = {"RemObject", "DeleteObject"},
		UppercaseMatters = false,
		
		Client = true,
		ClientOnly = true,

		Arguments = {"Player@", "Object;"},
		References = {"Player", "ObjectName"},
		ArgPermissions = {},
	},
	
	{
		Command = "ResObject",
		RequiredRank = 5,
		Alias = {"RestoreObject", "FixObject"},
		UppercaseMatters = false,

		Client = true,
		ClientOnly = true,

		Arguments = {"Player@", "string;"},
		References = {"Player", "ObjectName"},
		ArgPermissions = {},
	},
}

return Commands
