export type ParserModule = {
	__metatable: string,
	__type: string,
	
	__Deprecated: {
		[string]: {
			Replacement: string,
			UseNewMethod: boolean,
			Warned: boolean,
		}
	},
	
	SetChatCommand: (self: ParserModule, Name: string, AutoComplete: boolean?) -> TextChatCommand,
	FromMessage: (self: ParserModule, Message: string, Caller: Player?) -> (),
	
	Parse: (self: ParserModule, Caller: Player, Message: string, IgnoreCustomPrefix: boolean, IgnoreAllPrefixes: boolean) -> {any},
	ParseData: (self: ParserModule, Caller: Player, MessageData: {any}) -> {any},
	
	ParseMessage: (self: ParserModule, Caller: Player, Message: string, IgnorePrefix: boolean?) -> {any},
	GetCommand: (self: ParserModule, "Deprecated"--[[Command: string]]) -> (string, {any}),
	
	TriggerCommand: (self: ParserModule, Caller: Player, Command: string, Arguments: {any}) -> (any, any)?,
	TriggerCommands: (self: ParserModule, Caller: Player, MessageData: {any}) -> ({[string]: {any}})?,
	
	TransformArguments: (self: ParserModule, Caller: Player, Command: string, Arguments:{any}) -> {any},
	ParseArguments: (self: ParserModule, Caller: Player, Command: string, Arguments: {any}) -> (),
}

local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

local Commands = require(script.Parent.Commands)
local API = require(script.Parent.API)

local Settings = require(script.Parent.Settings)
local Data = require(script.Parent.Data)

local GlobalAPI = require(Data.ClientFolder.SharedModules.GlobalAPI)
local Signals = require(Data.ClientFolder.SharedModules.Signals)
local Continuation = require(Data.ClientFolder.SharedModules.Continuation)

local Proxy = newproxy(true)
local Parser: ParserModule = getmetatable(Proxy)

Parser.__metatable = "[GAdmin Parser]: Metatable methods are restricted."
Parser.__type = "GAdmin Parser"

Parser.__SpecialKey = "_GAdminParserBypassNewIndex"
Parser.__Deprecated = {
	ParseMessage = {
		Replacement = "Parse",
		UseNewMethod = true
	}
}

function Parser:__call()
	return Parser
end

function Parser:__tostring()
	return self.__type
end

function Parser:__index(Key)
	if Parser.__Deprecated[Key] then
		if not Parser.__Deprecated[Key].Warned then
			warn(`[{self.__type}]: Method :{Key}() is deprecated, {Parser.__Deprecated[Key].UseNewMethod and "automaticly using" or "use"} {Parser.__Deprecated[Key].OtherModule or ""}:{Parser.__Deprecated[Key].Replacement}() instead.`)
		end
		
		Parser.__Deprecated[Key].Warned = true
		return Parser.__Deprecated[Key].UseNewMethod and Parser[Parser.__Deprecated[Key].Replacement] or Parser[Key]
	end
	
	return Parser[Key]
end

function Parser:__newindex(Key, Value)
	--local Split = Key:split("__")
	--if #Split >= 2 and Split[1] == self.__SpecialKey then
	--	table.remove(Split, 1)
	--	Parser[table.concat(Split, "__")] = Value
	--	return
	--end
	
	warn(`[GAdmin Parser]: No access to set new value {Key}.`)
end

function Parser:SetChatCommand(Name, AutoComplete)
	if AutoComplete == nil then
		AutoComplete = true
	end
	
	local CommandName, Command = self:GetCommand(Name)
	if not Command or Command.DisableChat then
		return
	end
	
	local ChatCommand = Instance.new("TextChatCommand")
	ChatCommand.Name = Command.Command
	
	ChatCommand.AutocompleteVisible = AutoComplete
	ChatCommand.PrimaryAlias = `/{Command.Command:lower()}`
	
	Command.Revoke = (Command.UnDo and Command.Revoke) and Command.Revoke or {`Un{Command.Command}`}
	if not table.find(Command.Revoke, `Un{Command.Command}`) then
		table.insert(Command.Revoke, `Un{Command.Command}`)
	end
	
	ChatCommand.SecondaryAlias = Command.UnDo and `/{Command.Revoke[1]:lower()}` or ""

	ChatCommand.Triggered:Connect(function(Source, Message)
		local player = game.Players:GetPlayerByUserId(Source.UserId)
		Message = Data.SessionData[player.UserId].Prefix..Message:sub(2, #Message)
		
		local MessageData = self:Parse(player, Message)
		self:TriggerCommands(player, MessageData)
	end)

	ChatCommand.Enabled = true
	ChatCommand.Parent = Data.ChatCommandFolder
	
	return ChatCommand
end

function Parser:FromMessage(Message, Caller)
	local MessageData = self:Parse(Caller, Message)
	return self:TriggerCommands(Caller, MessageData)
end

function Parser:TriggerCommand(Caller, Command, Arguments, ArgumentsString)
	Settings.CommandsPerMinute = Settings.CommandsPerMinute or 5
	if Caller then Data.TempData[Caller.UserId].Commands += 1 end
	
	if Caller and Settings.CommandDebounce and Data.TempData[Caller.UserId].Commands >= Settings.CommandsPerMinute then
		Signals:Fire("Framework", Caller, "Notify", "Error", "Command per minute limit exceeded.")
		return
	end
	
	local Name, Setting = self:GetCommand(Command)
	local PlayerAllIndex = table.find(Arguments, "PlayerAll")
	
	table.insert(Data.Logs, {
		User = Caller or "[Server]",
		Time = tostring(DateTime.now().UnixTimestamp),
		Command = `{Caller and API:GetPrefix(Caller) or ";"}{Name}`,
		ArgumentsString = ArgumentsString or "[Server Call]",
		Arguments = Arguments,
	})
	
	local function Run()
		if PlayerAllIndex then
			if Setting.ClientOnly then
				Signals:FireAll("FireCommand", Name, Arguments)
				return
			end

			for i, player in ipairs(game.Players:GetPlayers()) do
				coroutine.wrap(function()
					Arguments[PlayerAllIndex] = player
					if Name:lower() == `un{Setting.Command:lower()}` then
						Setting.UnDo(Caller, Arguments)
						return
					end
					
					if Setting.PreFunction then Setting.PreFunction(Caller, Arguments) end
					Setting.Function(Caller, Arguments)
				end)()
			end

			return
		end

		if Setting.ClientOnly then
			Setting.CallerClient = Setting.CallerClient ~= nil and Setting.CallerClient or false
			local player = (typeof(Arguments[1]) == "Instance" and not Setting.CallerClient) and Arguments[1] or Caller
			Signals:Fire("FireCommand", player, Name, Arguments)
			return
		end

		if Name == `Un{Setting.Command}` then
			if Setting.Loop then
				Continuation:UnBind(Caller, Setting.Command)
			end
			
			Setting.UnDo(Caller, Arguments)
			return
		end

		if Setting.PreFunction then Setting.PreFunction(Caller, Arguments) end
		Setting.Function(Caller, Arguments)
	end
	
	if not Setting.Loop then
		Run()
		return
	end
	
	if Continuation:Find(Caller, Setting.Command) then
		return
	end
	
	Run()
	Continuation:Bind(Caller, Setting.Command, Run)
end

function Parser:TriggerCommands(Caller, MessageData)
	--== Getting rid of message ==--
	table.remove(MessageData, 1)
	
	local Returns = {}
	MessageData = MessageData or {}
	
	for i, Setting in pairs(MessageData) do
		local Command = Setting[1]
		local Arguments = Setting[2]
		local ArgumentsString = Setting[3]
		
		Returns[i] = {Settings.CommandInLineDebounce and self:TriggerCommand(Caller, Command, Arguments, ArgumentsString) or coroutine.wrap(self.TriggerCommand)(self, Caller, Command, Arguments, ArgumentsString)}
	end
	
	return Returns
end

--== New way of parsing commands.
--== Better than :ParseMessage() because is splitting commands by prefix
--== Worser than :ParseMessage() because prefix is needed.

function Parser:Parse(Caller, Message, IgnoreCustomPrefix, IgnoreAllPrefixes)
	local CustomPrefix = Caller and API:GetPrefix(Caller) or ";"
	local Prefix = IgnoreCustomPrefix and Settings.DefaultPrefix or CustomPrefix
	
	if IgnoreAllPrefixes then
		local RawData = Message:split(" ")
		local MessageData = {}
		
		local Command
		local LastIndex
		
		for i, Word in ipairs(RawData) do
			if Word:gsub("%s", "") == "" then
				continue
			end
			
			local WordCommand = Word:gsub(CustomPrefix, ""):gsub(Settings.DefaultPrefix, "")
			local Name, TempCommand = self:GetCommand(WordCommand)
			local Offset = #MessageData
			
			if not TempCommand and not Command and not Settings.IncorrectCommandNotify then
				if not Caller then
					warn(`[GAdmin Parser]: Command '{WordCommand}' is not valid.`)
					break
				end

				Signals:Fire("Framework", Caller, "Notify", "Error", `Command '{WordCommand}' is not valid.`)
				break
			end
			
			if not TempCommand then
				table.insert(MessageData[Offset][2], Word)
				continue
			end
			
			Command = WordCommand
			local TableData = {Command, {}}
			
			table.insert(MessageData, TableData)
			LastIndex = table.find(MessageData, TableData)
		end
		
		local BakedData = self:ParseData(Caller, MessageData)
		return {"This whole table needs to be put into :TriggerCommands() method.", BakedData and unpack(BakedData)}
	end
	
	local RawData = Message:gsub(CustomPrefix, Prefix):split(Prefix)
	local MessageData = {}
	
	for i, Batch in ipairs(RawData) do
		if i == 1 or Batch:gsub("%s", "") == "" then
			continue
		end
		
		local Command
		local LastIndex
		
		for i, String in ipairs(Batch:split(" ")) do
			local IsCommand = i == 1
			local Offset = #MessageData
			
			if String:gsub("%s", "") == "" then
				continue
			end
			
			if not self:GetCommand(String) and IsCommand and Settings.IncorrectCommandNotify then
				if not Caller then
					warn(`[GAdmin Parser]: Command '{String}' is not valid.`)
					break
				end
				
				Signals:Fire("Framework", Caller, "Notify", "Error", `Command '{String}' is not valid.`)
				break
			end
			
			if Command then
				table.insert(MessageData[Offset][2], String)
				continue
			end

			Command = String
			local TableData = {Command, {}}
			
			table.insert(MessageData, TableData)
			LastIndex = table.find(MessageData, TableData)
		end
	end
	
	local BakedData = self:ParseData(Caller, MessageData)
	return {"This whole table needs to be put into :TriggerCommands() method.", BakedData and unpack(BakedData)}
end

function Parser:ParseData(Caller, MessageData)
	for i, Setting in pairs(MessageData) do
		local Command = Setting[1]
		local Arguments = Setting[2]

		local Name, Setting = self:GetCommand(Command)
		if Setting.RequiredRank > (Caller and API:GetUserRank(Caller) or 6) then
			Signals:Fire("Framework", Caller, "Notify", "Error", `Your rank must be '{API:GetRank(Setting.RequiredRank)}'' or higher.`)
			return
		end

		if Caller and GlobalAPI:GetServerType() == "Private" and table.find(Settings.PrivateServerBlacklist, Command) and API:GetOwner() ~= Caller.UserId then
			Signals:Fire("Framework", Caller, "Notify", "Error", `No permission to use command '{Name}' in private servers.`)
			return
		end

		local TransformerArguments, Error = self:TransformArguments(Caller, Command, Arguments)
		if Error then
			if not Caller then
				warn(`[GAdmin Parser]: {Error}`)
				return
			end
			
			Signals:Fire("Framework", Caller, "Notify", "Error", Error)
			return
		end

		MessageData[i][2] = TransformerArguments
		MessageData[i][3] = Arguments
	end
	
	return MessageData
end

--== Old way of parsing commands.
--== Is here because might we might reverse back to it.

function Parser:ParseMessage(Caller, Message, IgnorePrefix)
	local RawData = Message:split(" ")
	local MessageData = {}
	
	local Command
	local LastIndex
	
	for i, String in ipairs(RawData) do
		local FormattedString = String:gsub(API:GetPrefix(Caller), "")
		local NoPrefix = (not IgnorePrefix and not Command and String:sub(1, 1) ~= API:GetPrefix(Caller))

		if FormattedString:gsub("%s", "") == "" or not FormattedString or NoPrefix then
			continue
		end
		
		if not self:GetCommand(FormattedString) and not NoPrefix and Settings.IncorrectCommandNotify then
			Signals:Fire("Framework", Caller, "Notify", "Error", `Command '{FormattedString}' is not valid.`)
			continue
		end
		
		if not self:GetCommand(FormattedString) then
			if Command then
				table.insert(MessageData[LastIndex][2], String)
			end
			
			continue
		end
		
		Command = FormattedString
		local TableData = {Command, {}}
		
		table.insert(MessageData, TableData)
		LastIndex = table.find(MessageData, TableData)
	end
	
	for i, Setting in pairs(MessageData) do
		local Command = Setting[1]
		local Arguments = Setting[2]
		
		local Name, Setting = self:GetCommand(Command)
		if Setting.RequiredRank > API:GetUserRank(Caller) then
			Signals:Fire("Framework", Caller, "Notify", "Error", `Your rank must be '{API:GetRank(Setting.RequiredRank)}'' or higher.`)
			return
		end
		
		if GlobalAPI:GetServerType() == "Private" and table.find(Settings.PrivateServerBlacklist, Command) and API:GetOwner() ~= Caller.UserId then
			Signals:Fire("Framework", Caller, "Notify", "Error", `No permission to use command '{Name}' in private servers.`)
			return
		end
		
		local TransformerArguments, Error = self:TransformArguments(Caller, Command, Arguments)
		if Error then
			Signals:Fire("Framework", Caller, "Notify", "Error", Error)
			return
		end
		
		MessageData[i][2] = TransformerArguments
		MessageData[i][3] = Arguments
	end
	
	return MessageData
end

function Parser:GetCommand(Command)
	return GlobalAPI:GetCommand(Commands, Command)
end

function Parser:TransformArguments(Caller, Command, Arguments)
	local Name, Setting = self:GetCommand(Command)
	local CommandArguments = Setting.Arguments
	local ParsedArguments = {}

	local Offset = 0
	local LastArgument = 1
	
	for i, Argument in ipairs(Arguments) do
		if i > #CommandArguments then
			ParsedArguments[LastArgument] = `{ParsedArguments[LastArgument]} {Argument}`
			continue
		end

		local RawData = CommandArguments[i + Offset]
		local CommandArgumentRaw = RawData:split(Data.CommandArgumentsSigns.MultiType)[1]
		local CommandArgument = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[1]:sub(1, #CommandArgumentRaw - 1)
		local Sign = CommandArgumentRaw:sub(#CommandArgumentRaw, #CommandArgumentRaw)
		local Class = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[2]

		local NextArgumentRaw = CommandArguments[i + Offset + 1] and CommandArguments[i + Offset + 1]:split(Data.CommandArgumentsSigns.MultiType)[1]
		local NextArgument = NextArgumentRaw and NextArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[1]:sub(1, #NextArgumentRaw - 1) or nil
		local NextSign = NextArgumentRaw and NextArgumentRaw:sub(#CommandArgumentRaw, #CommandArgumentRaw)
		local NextClass = NextArgumentRaw and NextArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[2]

		local RequiredRank = Setting.ArgPermissions[i] or 0
		local Name = Setting.References[i] or CommandArgument
		
		local RealArgument, Error = Data.ArgumentsTransform[CommandArgument](Caller, Argument, Sign, Class)
		if Error then
			return "ERROR", Error
		end

		if not RealArgument and NextArgument then
			RealArgument = Data.DefaultArguments[CommandArgument](Caller)
			LastArgument = i

			ParsedArguments[i] = RealArgument
			ParsedArguments[i + 1], Error = Data.ArgumentsTransform[NextArgument](Caller, Argument, NextSign, NextClass)
			
			if Error then
				return "ERROR", Error
			end

			Offset += 1
			continue
		end

		if (Caller and Data.SessionData[Caller.UserId].ServerRank or 6) < RequiredRank then
			return "ERROR", `You need to be '{API:GetRank(RequiredRank)}' to use argument '{Name}'.`
		end

		ParsedArguments[i + Offset] = RealArgument
		LastArgument = i + Offset
	end
	
	return self:ParseArguments(Caller, Command, ParsedArguments)
end

function Parser:ParseArguments(Caller, Command, Arguments)
	local Name, Setting = self:GetCommand(Command)
	local CommandArguments = Setting.Arguments
	
	local ParsedArguments = {}
	local ToSkip = false
	
	for i, Argument in ipairs(Arguments) do
		if ToSkip then
			ToSkip = false
			continue
		end
		
		local RawData = CommandArguments[i]
		local MultiType = RawData:split(Data.CommandArgumentsSigns.MultiType)
		
		local IsMultiType = #MultiType > 1
		local Found = false
		
		for i, CommandArgumentRaw in ipairs(MultiType) do
			local CommandArgument = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[1]:sub(1, #CommandArgumentRaw - 1)
			
			local Sign = CommandArgumentRaw:sub(#CommandArgumentRaw, #CommandArgumentRaw)
			local Class = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[2]
			
			local Optional = Sign == Data.CommandArgumentsSigns.Optional or Sign == Data.CommandArgumentsSigns.OptionalInGame
			local InGame = Sign == Data.CommandArgumentsSigns.InGame or Sign == Data.CommandArgumentsSigns.OptionalInGame
			local EqualRank = Sign == Data.CommandArgumentsSigns.EqualRank
			
			if CommandArgument == "Player" and InGame and type(Argument) == "number" then
				return "ERROR", `Player must be on server.`
			end
			
			if CommandArgument == "Rank" and EqualRank and Argument >= API:GetUserRank(Caller) then
				return "ERROR", "Rank needs to be lower than yours."
			end
			
			local NextArgument = CommandArguments[i + 1]
			local NextCommandArgumentRaw = NextArgument and NextArgument:split(Data.CommandArgumentsSigns.MultiType)[1]
			local NextCommandArgument = NextCommandArgumentRaw and NextCommandArgumentRaw:sub(1, #CommandArgumentRaw - 1)
			
			if CommandArgument == "Player" and NextCommandArgument == "Player" and Optional then
				ParsedArguments[i + 1] = Argument
				continue
			end
			
			if not table.find(Data.IgnoreClasses, CommandArgument) and (typeof(Argument) == "Instance" and not Argument:IsA(CommandArgument)) and typeof(Argument) ~= CommandArgument then
				if typeof(Argument) == CommandArgument then
					ToSkip = true
					ParsedArguments[i + 1] = Argument
				end
				
				continue
			end
			
			table.insert(ParsedArguments, Argument)
			Found = true
			break
		end
		
		if not Found then
			local CommandArgumentRaw = CommandArguments[i]:split(Data.CommandArgumentsSigns.MultiType)[1]
			local CommandArgument = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[1]:sub(1, #CommandArgumentRaw - 1)
			local Class = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[2]
			
			local Sign = CommandArgumentRaw:sub(#CommandArgumentRaw, #CommandArgumentRaw)
			local Optional = Sign == Data.CommandArgumentsSigns.Optional or Sign == Data.CommandArgumentsSigns.OptionalInGame
			
			if not Class and not Optional and (not Setting.UnDo or Name ~= `Un{Setting.Command}`) then
				local Name = Setting.References[i] or CommandArgument
				return "ERROR", `Argument {Name} is not optional.`
			end
			
			ParsedArguments[i] = Data.DefaultArguments[CommandArgument](Caller)
		end
	end
	
	if #CommandArguments > #ParsedArguments then
		for i = #ParsedArguments + 1, #CommandArguments do
			local CommandArgumentRaw = CommandArguments[i]:split(Data.CommandArgumentsSigns.MultiType)[1]
			local CommandArgument = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[1]:sub(1, #CommandArgumentRaw - 1)
			local Class = CommandArgumentRaw:split(Data.CommandArgumentsSigns.ClassName)[2]
			
			local Sign = CommandArguments[i]:sub(#CommandArgumentRaw, #CommandArgumentRaw)
			local Optional = Sign == Data.CommandArgumentsSigns.Optional or Sign == Data.CommandArgumentsSigns.OptionalInGame
			
			if not Class and not Optional and (not Setting.UnDo or Name ~= `Un{Setting.Command}`) then
				local Name = Setting.References[i] or CommandArgument
				return "ERROR", `Argument {Name} is not optional.`
			end
			
			ParsedArguments[i] = Data.DefaultArguments[CommandArgument](Caller)
		end
	end
	
	return ParsedArguments
end

function Parser:CheckArgument(Command, Argument, Index, Optional)
	local Name, Setting = self:GetCommand(Command)
	local CommandArguments = Setting.Arguments
	local CommandArgument = CommandArguments[Index]
	local RealArgument = Argument
	
	return RealArgument
end

return Proxy :: ParserModule
