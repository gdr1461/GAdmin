local Client = script.Parent.Parent.Parent
local Modules = Client.Modules
local SharedModules = Client.SharedModules

local Signals = require(SharedModules.Signals)
local GlobalAPI = require(SharedModules.GlobalAPI)

local Sounds = require(SharedModules.Sounds)
local Data = require(Modules.Data)

local Commands = require(Modules.Framework.Commands)
local BanHandler = require(Modules.Framework.BanHandler)

local SendHandler = require(Modules.Framework.SendHandler)
local Refresh = {}

Refresh.AdminFrame = {
	[1] = function(Frame)
		local OrderedRanks = table.clone(Data.OrderedRanks)
		local Ranks = Data.Ranks
		
		local TempTable = table.clone(OrderedRanks)
		table.sort(OrderedRanks, function(a, b)
			return table.find(TempTable, a) > table.find(TempTable, b)
		end)
		
		for i, Frame in ipairs(Frame.List:GetChildren()) do
			if not Frame:IsA("Frame") then
				continue
			end

			Frame:Destroy()
		end
		
		local Offset = 0
		for i, Rank in ipairs(OrderedRanks) do
			local Setting = Ranks[Rank]
			local Template = script.Ranks.RankTemplate:Clone()
			
			Template.Name = Rank
			Template.Rank.Text = Setting.Rank
			Template.LayoutOrder = #Frame.List:GetChildren() + Offset
			Template.Title.Text = Rank
			Template.Parent = Frame.List
			
			Setting.Users = Setting.Users or {}
			for i, User in ipairs(Setting.Users) do
				User = tonumber(User)
				Offset += 1
				
				local Success, UserName = pcall(function()
					return game.Players:GetNameFromUserIdAsync(User)
				end)
				
				UserName = Success and UserName or "[Unknown User]"
				local UserTemplate = script.Ranks.UserRankTemplate:Clone()
				UserTemplate.Title.Text = UserName
				UserTemplate.Avatar.Image = GlobalAPI:HeadShot(User)
				UserTemplate.LayoutOrder = #Frame.List:GetChildren() + Offset
				UserTemplate.Parent = Frame.List
				
				Offset += 1
				local Gap = script.Parent.Gap:Clone()
				Gap.LayoutOrder = #Frame.List:GetChildren() + Offset
				Gap.Parent = Frame.List
				
				local Clicked = false
				UserTemplate.Interact.Activated:Connect(function()
					Sounds:Play("Button", "Interact")
					Clicked = not Clicked

					UserTemplate.Title.Text = Clicked and `UserId: {User}` or UserName
				end)
			end
			
			Offset += 1
			local Space = script.Ranks.RankBlankSpace:Clone()
			
			Space.Parent = Frame.List
			Space.LayoutOrder = #Frame.List:GetChildren() + Offset
		end
	end,
	
	[2] = function(Frame)
		local ServerRanks = Signals:Fire("GetData", "API", "GetPlayerRanks")
		for i, Frame in ipairs(Frame.List:GetChildren()) do
			if not Frame:IsA("Frame") then
				continue
			end
			
			Frame:Destroy()
		end
		
		for UserId, Setting in pairs(ServerRanks) do
			UserId = tonumber(UserId, 10)
			local RankName = GlobalAPI:FindValue(Data.Ranks, Setting.Server)
			local GlobalRankName = GlobalAPI:FindValue(Data.Ranks, Setting.Global)
			
			if not RankName then
				warn(`[GAdmin Framework]: Unable to find rank '{Setting.Server}'`)
				continue
			end
			
			local Success, UserName = pcall(function()
				return game.Players:GetNameFromUserIdAsync(UserId)
			end)

			UserName = Success and UserName or "[Unknown User]"
			local Template = script.ServerRankTemplate:Clone()
			local StandardRankText = `[{Setting.Server}]: {RankName}`
			
			Template.Name = UserId
			Template.Title.Text = UserName
			Template.Avatar.Image = GlobalAPI:HeadShot(UserId)
			Template.Rank.Text = StandardRankText
			Template.LayoutOrder = Setting.Server
			Template.Parent = Frame.List
			
			local Gap = script.Parent.Gap:Clone()
			Gap.LayoutOrder = Setting.Server
			Gap.Parent = Frame.List
			
			local Clicked = false
			Template.Interact.Activated:Connect(function()
				Sounds:Play("Button", "Interact")
				Clicked = not Clicked
				
				Template.Title.Text = Clicked and `UserId: {UserId}` or UserName
				Template.Rank.Text = Clicked and `[SERVER]: {RankName} [GLOBAL]: {GlobalRankName}` or StandardRankText
			end)
		end
	end,
	
	[3] = function(Frame)
		Frame.Confirmation.Visible = false
		for i, Frame in ipairs(Frame.List:GetChildren()) do
			if not Frame:IsA("Frame") then
				continue
			end

			Frame:Destroy()
		end
		
		if type(Data.Banlist) ~= "table" then
			local Template = script.BanUserTemplate:Clone()
			Template.Name = "Restricted"
			
			Template.Title.Text = "You have no access to banlist."
			Template.Title.Size = UDim2.new(1, 0, 1, 0)
			Template.Title.TextXAlignment = Enum.TextXAlignment.Center
			
			Template.Size = UDim2.new(1, 0, .1, 0)
			Template.Title.Position = UDim2.new(0)
			
			Template.Avatar:Destroy()
			Template.UnBan:Destroy()
			Template.Interact:Destroy()
			Template.Parent = Frame.List
			return
		end
		
		for UserId, Setting in pairs(Data.Banlist) do
			UserId = tonumber(UserId, 10)
			local Success, UserName = pcall(function()
				return game.Players:GetNameFromUserIdAsync(UserId)
			end)
			
			UserName = Success and UserName or "[Unknown User]"
			local Template = script.BanUserTemplate:Clone()

			Template.Name = UserId
			Template.Title.Text = UserName
			Template.Avatar.Image = GlobalAPI:HeadShot(UserId)
			Template.Parent = Frame.List
			
			local Gap = script.Parent.Gap:Clone()
			Gap.Parent = Frame.List

			local Clicked = false
			Template.Interact.Activated:Connect(function()
				Sounds:Play("Button", "Interact")
				Clicked = not Clicked

				Template.Title.Text = Clicked and `UserId: {UserId}` or UserName
			end)
			
			if Data.Rank.Id < 3 then
				Template.UnBan:Destroy()
				continue
			end
			
			Template.UnBan.Activated:Connect(function()
				Sounds:Play("Button", "Interact")
				Data.ToUnBan = UserId
				Frame.Confirmation.MainFrame.Avatar.Image = GlobalAPI:HeadShot(UserId)
				Frame.Confirmation.MainFrame.Reason.Text = `Reason: {Setting.Reason}`
				Frame.Confirmation.MainFrame.Title.Text = `Are you sure to unban {UserName}?`
				Frame.Confirmation.Visible = true
			end)
		end
	end,
}

Refresh.AboutFrame = {
	[1] = function(Frame)
		Frame.Rank.Text = `Rank: {Data.Rank.Name}`
	end,
}

Refresh.BanFrame = function(Frame)
	BanHandler.Refresh()
end

Refresh.SendFrame = function(Frame)
	SendHandler.Refresh()
end

Refresh.CommandFrame = function(Frame)
	Frame.Search.Text = ""
	Commands.ShowOnly()
end

Refresh.Logs = function(Frame)
	for i, Frame in ipairs(Frame.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end
		
		Frame:Destroy()
	end
	
	local Logs = Signals:Fire("GetData", "Logs")
	local TempTable = table.clone(Logs)
	
	table.sort(Logs, function(a, b)
		return table.find(TempTable, a) > table.find(TempTable, b)
	end)
	
	local Offset = 0
	for i, Log in ipairs(Logs) do
		local Template = script.LogTemplate:Clone()
		Template.Time.Text = DateTime.fromUnixTimestamp(tonumber(Log.Time)):FormatLocalTime("HH:mm", "en-us")
		
		local Arguments = table.concat(Log.ArgumentsString, " ")
		Template.Log.Text = `{Log.User}: {Log.Command} {Arguments}`
		
		Template.LayoutOrder = i + Offset
		Template.Parent = Frame.List
		
		local Gap = script.Parent.Gap:Clone()
		Gap.LayoutOrder = i + Offset + 1
		Gap.Parent = Frame.List
		
		Offset += 2
	end
end

Refresh.ChatLogs = function(Frame)
	for i, Frame in ipairs(Frame.List:GetChildren()) do
		if not Frame:IsA("Frame") then
			continue
		end

		Frame:Destroy()
	end

	local Logs = Signals:Fire("GetData", "ChatLogs")
	local TempTable = table.clone(Logs)

	table.sort(Logs, function(a, b)
		return table.find(TempTable, a) > table.find(TempTable, b)
	end)

	local Offset = 0
	for i, Log in ipairs(Logs) do
		local Template = script.LogTemplate:Clone()
		Template.Time.Text = DateTime.fromUnixTimestamp(tonumber(Log.Time)):FormatLocalTime("HH:mm", "en-us")
		Template.Log.Text = `{Log.User}: {Log.Chat}`

		Template.LayoutOrder = i + Offset
		Template.Parent = Frame.List

		local Gap = script.Parent.Gap:Clone()
		Gap.LayoutOrder = i + Offset + 1
		Gap.Parent = Frame.List

		Offset += 2
	end
end

return Refresh
