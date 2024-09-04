local MarketPlaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Client = script.Parent.Parent
local Modules = Client.Modules
local SharedModules = Client.SharedModules

local Data = require(Modules.Data)
local UI = require(Modules.UI)

local Draggable = require(Modules.Draggable)
local ClientCommands = require(Modules.ClientCommands)
local Settings = require(Modules.Settings)

local ClientAPI = require(Modules.ClientAPI)
local GlobalAPI = require(SharedModules.GlobalAPI)
local TextBounds = require(SharedModules.TextBounds)

local RefreshModule = require(script.Refresh)
local Notify = require(script.Notify)

local Commands = require(script.Commands)
local BanHandler = require(script.BanHandler)
local SendHandler = require(script.SendHandler)

local Announce = require(script.Announce)
local TopBar = require(script.TopBar)

local Signals = require(SharedModules.Signals)
local Sounds = require(SharedModules.Sounds)

export type NotifyTypes = "Notify" | "Error" | "Warn"
export type MainFramework = {
	__metatable: string,
	__type: string,
	
	__Pages: {any?},
	__CurrentPage: number,
	
	__Current: string?,
	__HasSearch: boolean,
	__Devices: {[string]: () -> boolean},
	
	Configure: (self: MainFramework) -> (),
	Notify: (self: MainFramework, Type: NotifyTypes, Text: string, Timer: number?, OnInteract: () -> ()?) -> {any}?,
	
	GetAPI: (self: MainFramework) -> ClientAPI.APIModule,
	GetUI: (self: MainFramework) -> UI.UIFramework,
	
	Announce: (self: MainFramework, Title: string, Message: string) -> (),
	GetCommands: (self: MainFramework) -> Commands.CommandsType,
	
	ResetMainFrame: (self: MainFramework) -> (),
	CurrentFrame: (self: MainFramework, NoOpening: boolean?) -> (),
	
	Muted: (self: MainFramework, Boolean: boolean) -> (),
	CurrentPage: (self: MainFramework) -> (),
	ChangePage: (self: MainFramework, Index: number?) -> (),
	
	Refresh: (self: MainFramework) -> (),
	OpenFrame: (self: MainFramework, Frame: GuiObject | string, Page: number?) -> (),
	
	NewCmdBar: (self: MainFramework) -> (),
	CreateCmdBar: (self: MainFramework, InputFrame: string, OnActivated: (WindowData: ClientAPI.WindowData, Message: string) -> ()) -> Frame,
	
	GetGui: (self: MainFramework) -> ScreenGui,
	CloseAll: (self: MainFramework, Class: GuiObject) -> (),
}

_G.GFramework = script
local Proxy = newproxy(true)
local Framework: MainFramework = getmetatable(Proxy)

Framework.__metatable = "[GAdmin Framework]: Metatable methods are restricted."
Framework.__type = "GAdmin Framework"

Framework.__Pages = {}
Framework.__CurrentPage = 0

Framework.__Current = "Main"
Framework.__Devices = {
	Console = function()
		return game.GuiService:IsTenFootInterface()
	end,
	
	Mobile = function()
		return UserInputService.TouchEnabled and not UserInputService.MouseEnabled and UI:GetGui().AbsoluteSize.Y < 650
	end,
	
	Tablet = function()
		return UserInputService.TouchEnabled and not UserInputService.MouseEnabled and UI:GetGui().AbsoluteSize.Y >= 650
	end,
}

function Framework:__tostring()
	return self.__type
end

function Framework:__call()
	return Framework
end

function Framework:__index(Key)
	return Framework[Key]
end

function Framework:__newindex(Key, Value)
	Framework[Key] = Value
end

function Framework:Configure()
	UI:GetGui().MainFrame.Visible = false
	Signals:Set(Client.Events)
	self:CurrentFrame(true)
	
	--== GETTING USER'S DEVICE ==--
	for Device, Function in ipairs(self.__Devices) do
		if not Function() then
			continue
		end
		
		Data.Device = Device
		break
	end
	
	--== REFRESHING BANLIST ==--
	coroutine.wrap(function()
		Data.Banlist = Signals:Fire("GetData", "API", "GetBanlist")
		
		while task.wait(120) do
			Data.Banlist = Signals:Fire("GetData", "API", "GetBanlist")
		end
	end)()
	
	--== SETTING UP OTHER THINGS ==--
	Data.NotifySettings = Signals:Fire("GetData", "GetNotifySettings")
	Data.OrderedRanks = Signals:Fire("GetData", "API", "GetOrderedRanks")
	Data.Ranks = Signals:Fire("GetData", "API", "GetRanks")
	
	Signals:Connect("Framework", function(Action, ...)
		if not self[Action] then
			return
		end
		
		self[Action](self, ...)
	end)
	
	Signals:Connect("FireCommand", function(Name, Arguments)
		if not ClientCommands[Name] then
			return
		end
		
		
		ClientCommands[Name](player, Arguments)
	end)
	
	self:NewCmdBar()
	--== SETTING UP TOPBAR PLUS ==--
	
	local Icon = TopBar:Create()
	
	--== SETTING UP USER RANK UPDATE ==--
	Signals:Connect("RankUpdate", function(Rank)
		Data.Rank = {
			Name = Signals:Fire("GetData", "API", "GetRank", Rank),
			Id = Rank
		}
		
		Commands.Refresh()
		ClientAPI:TopBarEnabled(Data.Access.Admin <= Data.Rank.Id)
	end)
	
	local Rank = Signals:Fire("GetData", "API", "GetUserRank", player)
	local RankName = Signals:Fire("GetData", "API", "GetRank", Rank)

	Data.Rank = {
		Name = RankName,
		Id = Rank
	}

	Commands.Refresh()
	Data.Access = Signals:Fire("GetData", "Access")
	
	ClientAPI:TopBarEnabled(Data.Access.Admin <= Data.Rank.Id)
	if Data.Access.Notify <= Data.Rank.Id then
		self:Notify("Notify", `Your rank is '{RankName}'! Click to see more.`, 10, function()
			self:OpenFrame("CommandFrame")
		end)
	end
	
	--== SETTING UP TOPBAR OF GUI ==--
	local Gui = UI:GetGui()
	Draggable(Gui.MainFrame.Top)
	
	Gui.MainFrame.Top.Back.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self:Back()
	end)
	
	local Hidden = false
	Gui.MainFrame.Top.Hide.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		Hidden = not Hidden
		Gui.MainFrame.PageFrame.Visible = not Hidden
		
		if Hidden then self:CloseAll(Gui.MainFrame.Frames) return end
		self:CurrentFrame()
	end)
	
	Gui.MainFrame.Top.Close.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self.__CurrentPage = "Main"
		self:CurrentFrame()
		
		self:CloseAll(Gui.MainFrame.Frames)
		TopBar.Reference:deselect()
	end)
	
	Gui.MainFrame.PageFrame.Back.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self:ChangePage(-1)
	end)
	
	Gui.MainFrame.PageFrame.Next.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self:ChangePage(1)
	end)
	
	local SearchBox = Gui.MainFrame.Frames.CommandFrame.Search
	SearchBox.FocusLost:Connect(function()
		local Text = SearchBox.Text
		if Text:gsub("%s", "") == "" then
			Commands.ShowOnly()
			return
		end
		
		Commands.ShowOnly(Commands.Search(Text))
	end)
	
	--== SETTING UP MAINFRAME ==--
	local Main = Gui.MainFrame.Frames.Main
	for ID, Setting in pairs(Data.MainFrames) do
		local Template = script.MainTemplate:Clone()
		Template.Name = ID
		Template.Title.Text = Setting.Name
		Template.LayoutOrder = Setting.Order
		Template.Parent = Main.List
		
		local Frame = Gui.MainFrame.Frames:FindFirstChild(Setting.Frame)
		if not Frame then
			warn(`[GAdmin Framework]: Unable to find frame '{Setting.Frame}' for Main button {ID}.`)
			continue
		end
		
		Template.Interact.Activated:Connect(function()
			Sounds:Play("Button", "Interact")
			self:OpenFrame(Frame)
		end)
		-- TODO: Images
	end
	
	--== SETTINGS ==--
	local GetUserSettings = Signals:Fire("GetData", "API", "GetUserSettings", player)
	for i, Setting in pairs(Data.Settings) do
		Setting.Default = GetUserSettings[Setting.Name:gsub(" ", "")] or Setting.Default
		Settings:Create(Setting.Type, Setting.Name, Setting.Default, Setting.Function)
	end
	
	--== ABOUT SECION ==--
	local UpdateOffset = 0
	local AboutFrame = Gui.MainFrame.Frames.AboutFrame
	
	local InfoFrame = AboutFrame.Pages["1"]
	local UpdatesFrame = AboutFrame.Pages["2"]
	
	--= UPDATES ==--
	for i, Setting in ipairs(Data.Updates) do
		local Date = Setting.Date
		local Blocks = Setting.Blocks
		
		local DateTemplate = script.Updates.DateTemplate:Clone()
		DateTemplate.Name = Date
		DateTemplate.Text = Date or "[Unknown Date]"
		DateTemplate.LayoutOrder = #UpdatesFrame.List:GetChildren() + UpdateOffset
		DateTemplate.Parent = UpdatesFrame.List
		
		for i, Block in ipairs(Blocks) do
			UpdateOffset += 1
			local Template = script.Updates.BlockTemplate:Clone()
			Template.Name = i
			Template.LayoutOrder = #UpdatesFrame.List:GetChildren() + UpdateOffset
			Template.Text = `- {Block}`
			Template.Parent = UpdatesFrame.List
			Template.Size = UDim2.new(1, 0, 0, TextBounds(Template).Y)
			
			local Gap = script.Gap:Clone()
			Gap.LayoutOrder = #UpdatesFrame.List:GetChildren() + UpdateOffset
			Gap.Parent = Gui.MainFrame.Frames.Settings.List
		end
		
		UpdateOffset += 1
		local BlankSpace = script.Updates.BlankTemplate:Clone()
		
		BlankSpace.LayoutOrder = #UpdatesFrame.List:GetChildren() + UpdateOffset
		BlankSpace.Parent = UpdatesFrame.List
	end
	
	--== SEND SECTION ==--
	SendHandler.Start()
	SendHandler.Frame.Submit.Activated:Connect(function()
		if not SendHandler.UserId and not SendHandler.GameWide then
			return
		end
		
		self:Notify(Signals:Fire("GetData", "SendTo", SendHandler.UserId, SendHandler.Text, SendHandler.GameWide, SendHandler.FromPlayer))
		self.__Current = "Main"
		self:CurrentFrame()
	end)
	
	--== BAN SECTION ==--
	BanHandler.Start()
	BanHandler.Frame.Submit.Activated:Connect(function()
		if not BanHandler.UserId then
			return
		end

		local Duration = BanHandler.CalculateTime()
		self:Notify(Signals:Fire("GetData", "Ban", BanHandler.UserId, BanHandler.Reason, Duration, BanHandler.IPBan))
		
		self.__Current = "Main"
		self:CurrentFrame()
	end)
	
	--== UNBAN CONFIRMATION ==--
	local BanlistFrame = Gui.MainFrame.Frames.AdminFrame.Pages["3"]
	local Confirmation = BanlistFrame.Confirmation
	
	Confirmation.MainFrame.Confirm.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self:Notify(Signals:Fire("GetData", "UnBan", Data.ToUnBan))
		
		Data.Banlist = Signals:Fire("GetData", "API", "GetBanlist")
		Data.ToUnBan = nil
		
		Confirmation.Visible = false
		self:Refresh()
	end)
	
	Confirmation.MainFrame.Close.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		Data.ToUnBan = nil
		Confirmation.Visible = false
	end)
	
	--= CONSTANTS
	InfoFrame.Avatar.Image = GlobalAPI:HeadShot(player.UserId)
	InfoFrame.Title.Text = player.Name
end

function Framework:Refresh()
	local CurrentFrame = UI:GetGui().MainFrame.Frames:FindFirstChild(self.__Current)
	local RefreshData = RefreshModule[self.__Current]
	
	if not RefreshData then
		return
	end
	
	if type(RefreshData) ~= "table" and #self.__Pages <= 0 then
		RefreshData(CurrentFrame)
		return
	end
	
	if type(RefreshData) ~= "table" and #self.__Pages > 0 then
		warn(`[GData Framework]: Unable to refresh frame because RefreshModule.{self.__Current} is pageless.`)
		return
	end
	
	if not RefreshData[self.__CurrentPage] then
		return
	end
	
	local CurrentPage = self.__Pages[self.__CurrentPage]
	RefreshData[self.__CurrentPage](CurrentPage)
end

function Framework:ResetMainFrame()
	local Gui = UI:GetGui()
	Gui.MainFrame.Position = UDim2.new(.5, 0, .5, 0)
	
	self.__Current = "Main"
	self:CurrentFrame()
end

function Framework:CurrentFrame(NoOpening)
	local Gui = UI:GetGui()
	local CurrentFrame = Gui.MainFrame.Frames:FindFirstChild(self.__Current)
	
	if not CurrentFrame then
		return
	end
	
	self:CloseAll(CurrentFrame.Parent)
	if not NoOpening then TopBar.Reference:select() end
	
	if CurrentFrame:FindFirstChild("Pages") then
		for i = 1, #CurrentFrame.Pages:GetChildren() do
			local PageFrame = CurrentFrame.Pages:FindFirstChild(tostring(i))
			if not PageFrame then
				continue
			end

			table.insert(self.__Pages, PageFrame)
		end
	end
	
	Gui.MainFrame.Top.Back.Visible = CurrentFrame:GetAttribute("Back")
	CurrentFrame.Visible = true
	self:CurrentPage()
	
	local Offset = 0
	if #self.__Pages > 0 then Offset += .1 end
	
	local Size = UDim2.new(1, 0, .9 - Offset, 0)
	CurrentFrame.Size = Size
	CurrentFrame.Position = UDim2.new(.5, 0, .1 + Offset, 0)
end

function Framework:CurrentPage()
	local CurrentFrame = UI:GetGui().MainFrame.Frames:FindFirstChild(self.__Current)
	local HasPages = CurrentFrame:FindFirstChild("Pages")
	
	local Gui = UI:GetGui()
	Gui.MainFrame.PageFrame.Visible = HasPages
	
	if not HasPages or #self.__Pages <= 0 then
		self.__Pages = {}
		self.__CurrentPage = 0
		
		self:Refresh()
		return
	end
	
	self:CloseAll(CurrentFrame.Pages)
	self.__CurrentPage = self.__CurrentPage == 0 and 1 or self.__CurrentPage
	
	if not self.__Pages[self.__CurrentPage] then
		return
	end
	
	self.__Pages[self.__CurrentPage].Visible = true
	Gui.MainFrame.PageFrame.Page.Text = self.__Pages[self.__CurrentPage]:GetAttribute("Name")
	self:Refresh()
end

function Framework:ChangePage(Index)
	Index = Index or 1
	
	self.__CurrentPage += Index
	self.__CurrentPage = self.__CurrentPage > #self.__Pages and 1 or (self.__CurrentPage <= 0 and #self.__Pages or self.__CurrentPage)
	self:CurrentPage()
end

function Framework:Back()
	local CurrentFrame = UI:GetGui().MainFrame.Frames:FindFirstChild(self.__Current)
	if not CurrentFrame then
		return
	end
	
	local GoBack = CurrentFrame:GetAttribute("Back")
	UI:GetGui().MainFrame.Top.Back.Visible = GoBack
	
	if not GoBack then
		return
	end
	
	self.__Current = GoBack
	self:CurrentFrame()
end

function Framework:NewCmdBar()
	if Data.CmdBar then
		Data.CmdBar:Destroy()
		for i, Connection in ipairs(Data.CmdBarConnections) do
			Connection:Disconnect()
		end
		
		Data.CmdBarConnections = {}
	end
	
	Data.CmdBar, Data.CmdBarConnections = self:CreateCmdBar("CmdBar", function(WindowData, Message)
		Signals:Fire("FireCommand", Message)
	end)
end

function Framework:CreateCmdBar(InputWindow, OnClicked)
	local Message = ""
	local CmdBarConnections = {}
	local CmdBar = ClientAPI:CreateInputWindow(InputWindow, {
		Size = "Normal",
		Input = {
			DefaultInput = "",
			OnChange = function(WindowData, Text)
				Message = Text
			end,
		},

		OnClicked = function(WindowData)
			OnClicked(WindowData, Message)
		end,

		OnRemove = function()
			self:NewCmdBar()
		end,
	})

	local LastFill
	local LastPosition = 1

	local FillIndex = 1
	local LastIndex = FillIndex

	local FinalIndex = FillIndex
	local LatestText
	local AutoFills = {}

	local KeyCodes = {
		[Enum.KeyCode.Return] = function()
			local Words = CmdBar.TextBox.Text:sub(1, CmdBar.TextBox.CursorPosition - 1):split(" ")
			local Text

			local Index
			if #Words > 0 then
				for i = #Words, 1, -1 do
					if Words[i]:gsub("%s", "") == "" then
						continue
					end

					Index = #Words
					Text = Words[Index]
					break
				end
			end

			if not Text then
				Text = CmdBar.TextBox.Text
			end

			local Frame = AutoFills[FinalIndex]
			LastFill = tick()
			Words[Index] = Frame.Name:lower()

			AutoFills = {}
			local Replacement = `{table.concat(Words, " ")} `
			CmdBar.TextBox.Text = `{Replacement}{CmdBar.TextBox.Text:sub(LastPosition + 1, #CmdBar.TextBox.Text)}`

			LatestText = CmdBar.TextBox.Text
			CmdBar.AutoFill:Destroy()
			
			CmdBar.TextBox.CursorPosition = #Replacement
			Message = CmdBar.TextBox.Text
		end,

		[Enum.KeyCode.Up] = function()
			LastIndex = FillIndex
			FillIndex = math.max(FillIndex - 1, 1)

			local OldFrame = AutoFills[LastIndex]
			OldFrame.Interact.BackgroundColor3 = Color3.new(0.133333, 0.121569, 0.180392)

			local Frame = AutoFills[FillIndex]
			Frame.Interact.BackgroundColor3 = Color3.new(0.313725, 0.298039, 0.372549)
		end,

		[Enum.KeyCode.Down] = function()
			LastIndex = FillIndex
			FillIndex = math.min(FillIndex + 1, #AutoFills)

			local OldFrame = AutoFills[LastIndex]
			OldFrame.Interact.BackgroundColor3 = Color3.new(0.133333, 0.121569, 0.180392)

			local Frame = AutoFills[FillIndex]
			Frame.Interact.BackgroundColor3 = Color3.new(0.313725, 0.298039, 0.372549)
		end,
	}

	local function AutoFill()
		if LastFill and tick() - LastFill <= .1 then
			return
		end

		if CmdBar.TextBox.Text:gsub("%s", "") == "" or #CmdBar.TextBox.Text < 1 then
			if CmdBar:FindFirstChild("AutoFill") then CmdBar.AutoFill:Destroy() end
			return
		end

		local Words = CmdBar.TextBox.Text:sub(1, CmdBar.TextBox.CursorPosition - 1):split(" ")
		local Text

		local Index
		if #Words > 0 then
			for i = #Words, 1, -1 do
				if Words[i]:gsub("%s", "") == "" then
					continue
				end

				Index = #Words
				Text = Words[Index]
				break
			end
		end
		
		if not Index then
			return
		end

		if not Text then
			Text = CmdBar.TextBox.Text
		end

		if CmdBar:FindFirstChild("AutoFill") then CmdBar.AutoFill:Destroy() end
		if Text:gsub("%s", "") == "" or #Text < 1 then
			return
		end

		AutoFills = {}

		local Similar = Commands.Search(Text:gsub("%p", ""), true, true)
		local Players = {}

		for i, player in ipairs(game.Players:GetPlayers()) do
			if player.Name:sub(1, #Text):lower() ~= Text:lower() then
				continue
			end

			table.insert(Players, player.Name)
		end

		if #Similar <= 0 then
			return
		end

		FinalIndex = FillIndex
		FillIndex = #Similar + (Index % 2 == 0 and #Players or 0)

		local AutoFill = script.AutoFill.AutoFill:Clone()
		AutoFill.Parent = CmdBar
		
		for i, Command in ipairs(Similar) do
			local Name, CommandSettings = GlobalAPI:GetCommand(Commands.AllCommands, Command)
			CommandSettings = CommandSettings or {
				Arguments = {},
				References = {}
			}

			local RawArguments = CommandSettings.References or CommandSettings.Arguments
			for i, Argument in ipairs(RawArguments) do
				RawArguments[i] = `[{Argument:gsub("%p", "")}]`
			end

			local Arguments = table.concat(RawArguments, " ")
			local Template = script.AutoFill.Fill:Clone()

			Template.Name = Command
			local Info = `{Command}{Arguments ~= "" and ` {Arguments}` or ""}`
			
			Template.Title.Text = Info
			Template.Parent = AutoFill

			AutoFills[i] = Template
			ClientAPI:CreateHoverInfo(Template.Interact, Info)
			
			Template.Interact.Activated:Connect(function()
				LastFill = tick()
				Words[Index] = Command:lower()

				AutoFills = {}
				CmdBar.TextBox.Text = `{table.concat(Words, " ")} {CmdBar.TextBox.Text:sub(LastPosition + 1, #CmdBar.TextBox.Text)}`
				
				Message = CmdBar.TextBox.Text
				CmdBar.AutoFill:Destroy()
			end)
			
			Template.Interact.MouseEnter:Connect(function()
				LastIndex = FillIndex
				FillIndex = math.max(i, 1)

				local OldFrame = AutoFills[LastIndex]
				OldFrame.Interact.BackgroundColor3 = Color3.new(0.133333, 0.121569, 0.180392)

				local Frame = AutoFills[i]
				Frame.Interact.BackgroundColor3 = Color3.new(0.313725, 0.298039, 0.372549)
			end)
		end

		if Index % 2 == 0 then
			for i, Player in ipairs(Players) do
				local Template = script.AutoFill.Fill:Clone()
				Template.Name = Player

				Template.Title.Text = Player
				Template.Parent = AutoFill

				AutoFills[i + #Similar] = Template
				Template.Interact.Activated:Connect(function()
					LastFill = tick()
					Words[Index] = Player:lower()

					AutoFills = {}
					CmdBar.TextBox.Text = `{table.concat(Words, " ")} {CmdBar.TextBox.Text:sub(LastPosition + 1, #CmdBar.TextBox.Text)}`
					CmdBar.AutoFill:Destroy()
				end)
			end
		end

		local Frame = AutoFills[FillIndex]
		Frame.Interact.BackgroundColor3 = Color3.new(0.313725, 0.298039, 0.372549)
	end

	local LastCount = #CmdBar.TextBox.Text
	CmdBar.Visible = false

	CmdBar.TextBox.FocusLost:Connect(function(EnterPressed)
		if not EnterPressed then
			return
		end

		local CursorPosition = LastPosition
		CmdBar.TextBox:CaptureFocus()
		CmdBar.TextBox.CursorPosition = CursorPosition
	end)

	CmdBar.TextBox:GetPropertyChangedSignal("Text"):Connect(AutoFill)
	CmdBar.TextBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		if CmdBar.TextBox.CursorPosition <= 0 then
			return
		end

		LastPosition = CmdBar.TextBox.CursorPosition
		AutoFill()
	end)

	CmdBarConnections.Began = UserInputService.InputBegan:Connect(function(InputKey)
		if not KeyCodes[InputKey.KeyCode] or #AutoFills <= 0 then
			return
		end

		KeyCodes[InputKey.KeyCode]()
	end)

	CmdBarConnections.Ended = UserInputService.InputEnded:Connect(function(InputKey)
		if InputKey.KeyCode ~= Enum.KeyCode.Return or not LatestText then
			return
		end

		CmdBar.TextBox.Text = LatestText
		Message = CmdBar.TextBox.Text
		LatestText = nil
	end)
	
	return CmdBar, CmdBarConnections
end

function Framework:OpenFrame(Frame, Page)
	if typeof(Frame) == "Instance" then
		self.__Current = Frame.Name
		self:CurrentFrame()
		return
	end
	
	Frame = UI:GetGui().MainFrame.Frames:FindFirstChild(Frame)
	if not Frame then
		return
	end
	
	self.__Current = Frame.Name
	local Pages = Frame:FindFirstChild("Pages")
	
	Page = Page or 1
	if Pages and Page then
		self.__CurrentPage = Page
		Pages[tostring(Page, 10)].Visible = true
	end
	
	self:CurrentFrame()
end

function Framework:CloseAll(Class)
	for i, Frame in ipairs(Class:GetChildren()) do
		if not Frame:IsA("GuiObject") or Frame:GetAttribute("NoClose") then
			continue
		end
		
		Frame.Visible = false
	end
end

function Framework:Muted(Boolean)
	player.PlayerGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, Boolean)
end

function Framework:Announce(Title, Message)
	coroutine.wrap(Announce.Create)(Title, Message)
end

function Framework:GetUI()
	return UI
end

function Framework:GetCommands()
	return Commands
end

function Framework:GetAPI()
	return ClientAPI
end

function Framework:GetGui()
	return UI:GetGui()
end

function Framework:Notify(...)
	return ClientAPI:Notify(...)
end

return Proxy :: MainFramework
