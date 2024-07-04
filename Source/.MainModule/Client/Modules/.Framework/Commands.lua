local Client = script.Parent.Parent.Parent
local Modules = Client.Modules

local SharedModules = Client.SharedModules
local GlobalAPI = require(SharedModules.GlobalAPI)

local Signals = require(SharedModules.Signals)
local Data = require(Modules.Data)

local UI = require(Modules.UI)
local Gui = UI:GetGui()

export type CommandsType = {
	Refresh: () -> (),
	Search: (Command: string) -> {string?},
	ShowOnly: (Table: {string}?) -> (),
	Create: (Rank: string, RankCommands: {any}) -> (),
}

local Sounds = require(SharedModules.Sounds)
local Commands: CommandsType = {}

Commands.Frame = Gui.MainFrame.Frames.CommandFrame
Commands.Templates = script.Commands

Commands.DefaultOrder = {}
Commands.Commands = {}
Commands.Info = script.Info
Commands.Offset = 1
Commands.AllCommands = nil

function Commands.Refresh()
	Commands.AllCommands = Commands.AllCommands or Signals:Fire("GetData", "GetCommands")
	for i, Frame in ipairs(Commands.Frame.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local CommandsCount = 0
	Commands.Commands = Signals:Fire("GetData", "GetRankCommands", Data.Rank.Id)
	
	--== RANKS ==--
	for i = 1, #Data.OrderedRanks do
		local Rank = Data.OrderedRanks[i]
		local RankCommands = Commands.Commands[Rank]
		
		CommandsCount += #RankCommands
		Commands.Create(Rank, RankCommands)
	end
end

function Commands.Search(Command, IgnoreFull, NoAlias)
	local Possibilites = {}
	for i, Setting in ipairs(Commands.AllCommands) do
		if IgnoreFull and Setting.Command:lower() == Command:lower() then
			continue
		end
		
		if Setting.Command:lower():sub(1, #Command) == Command:lower() then
			table.insert(Possibilites, Setting.Command)
			continue
		end
		
		if NoAlias then
			continue
		end
		
		for i, Alias in pairs(Setting.Alias) do
			if Alias:lower():sub(1, #Command) ~= Command:lower() then
				continue
			end
			
			table.insert(Possibilites, Setting.Command)
			break
		end
	end
	
	return Possibilites
end

function Commands.ShowOnly(Table)
	if not Table then
		for i, Frame in ipairs(Commands.Frame.List:GetChildren()) do
			if (not Frame:IsA("Frame") and not Frame:IsA("TextLabel")) or Frame.Name:split(" ")[2] == "Info" then
				continue
			end
			
			Frame.Visible = true
		end
		
		return
	end
	
	for i, Frame in ipairs(Commands.Frame.List:GetChildren()) do
		if not Frame:IsA("Frame") and not Frame:IsA("TextLabel") then
			continue
		end
		
		Frame.Visible = table.find(Table, Frame.Name)
	end
end

function Commands.Create(Rank, RankCommands)
	local Template = Commands.Templates.RankTemplate:Clone()
	Template.Name = Rank
	Template.LayoutOrder = #Commands.Frame.List:GetChildren() + Commands.Offset
	Template.Title.Text = Rank
	Template.Rank.Text = Data.Ranks[Rank].Rank
	Template.Parent = Commands.Frame.List
	
	if #RankCommands > 0 then
		local Gap = script.Parent.Gap:Clone()
		Gap.LayoutOrder = #Commands.Frame.List:GetChildren() + Commands.Offset + 1
		Gap.Parent = Commands.Frame.List
	end

	for i, Setting in ipairs(RankCommands) do
		Commands.Offset += 1

		local Aliases = table.concat(Setting.Alias, "; ")
		local RawArguments = Setting.References or Setting.Arguments

		for i, Argument in ipairs(RawArguments) do
			RawArguments[i] = `[{Argument:gsub("%p", "")}]`
		end

		local Arguments = table.concat(RawArguments, " ")
		local Template = Commands.Templates.CommandTemplate:Clone()

		Template.Name = Setting.Command
		Template.LayoutOrder = #Commands.Frame.List:GetChildren() + Commands.Offset
		Template.Title.Text = Setting.Command
		Template.Parent = Commands.Frame.List
		
		local InfoFrame = Commands.Info:Clone()
		InfoFrame.Name = `{Setting.Command} Info`
		InfoFrame.Aliases.Text = `Alias: {Aliases}`
		InfoFrame.Arguments.Text = Arguments == "" and "[None]" or Arguments
		InfoFrame.Rank.Text = `Rank: {Setting.Rank} ({GlobalAPI:FindValue(Data.Ranks, Setting.Rank) or "Default"})`
		InfoFrame.LayoutOrder = Template.LayoutOrder + 1
		InfoFrame.Parent = Commands.Frame.List
		
		if Setting.UnDo then
			InfoFrame.Size = UDim2.new(1, 0, .4, 0)
			for i, Label in ipairs(InfoFrame:GetChildren()) do
				if not Label:IsA("TextLabel") then
					continue
				end
				
				Label.Size = UDim2.new(1, 0, .2, 0)
			end
			
			local UnDo = InfoFrame.Aliases:Clone()
			UnDo.Parent = InfoFrame
			UnDo.LayoutOrder = 4
			UnDo.Text = `Undo: {Setting.UnDo}`
		end
		
		if not Setting.Alias or #Setting.Alias <= 0 then
			InfoFrame.Size = UDim2.new(1, 0, .3, 0)
			for i, Label in ipairs(InfoFrame:GetChildren()) do
				if not Label:IsA("TextLabel") then
					continue
				end

				Label.Size = UDim2.new(1, 0, .3, 0)
			end

			InfoFrame.Aliases:Destroy()
		end
		
		Template.Interact.Activated:Connect(function()
			Sounds:Play("Button", "Interact")
			InfoFrame.Visible = not InfoFrame.Visible
			Template.Arrow.Text = InfoFrame.Visible and "⬇" or "➡"
		end)
		
		local Gap = script.Parent.Gap:Clone()
		Gap.LayoutOrder = Template.LayoutOrder + 2
		Gap.Parent = Commands.Frame.List
	end

	if #RankCommands <= 0 then
		return
	end

	Commands.Offset += 1
	local BlankSpace = Commands.Templates.BlankTemplate:Clone()
	BlankSpace.LayoutOrder = #Commands.Frame.List:GetChildren() + Commands.Offset
	BlankSpace.Parent = Commands.Frame.List
end

return Commands
