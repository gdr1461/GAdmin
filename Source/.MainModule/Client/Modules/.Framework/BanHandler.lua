local Client = script.Parent.Parent.Parent
local Modules = Client.Modules

local SharedModules = Client.SharedModules
local Signals = require(SharedModules.Signals)

local API = require(Modules.ClientAPI)
local UI = require(Modules.UI)
local Gui = UI:GetGui()

local BanHandler = {}
BanHandler.Frame = Gui.MainFrame.Frames.BanFrame
BanHandler.Times = {
	Year = 0,
	Month = 0,
	Day = 0,
	Hour = 0,
	Minute = 60
}

BanHandler.UserId = nil
BanHandler.Reason = "No Reason"
BanHandler.IPBan = false

function BanHandler.Start()
	BanHandler.Refresh()
	local UserBox = BanHandler.Frame.User.TextBox
	
	UserBox.FocusLost:Connect(function()
		local Text = UserBox.Text:gsub("%s", "")
		if Text == "" then
			return
		end
		
		Text = tonumber(Text, 10) or game.Players:GetUserIdFromNameAsync(Text)
		if not Text then
			return
		end
		
		BanHandler.UserId = Text
	end)
	
	local ReasonBox = BanHandler.Frame.Reason.TextBox
	ReasonBox.FocusLost:Connect(function()
		BanHandler.Reason = ReasonBox.Text
	end)

	API:CreateMarkdown(BanHandler.Frame.IPBan, function(State)
		BanHandler.IPBan = State
	end, "IP bans player.")
end

function BanHandler.Refresh()
	BanHandler.IPBan = false
	BanHandler.UserId = nil
	BanHandler.Reason = "No Reason"
	
	BanHandler.Frame.User.TextBox.Text = ""
	BanHandler.Frame.Reason.TextBox.Text = ""
	
	if API:GetMarkdown(BanHandler.Frame.IPBan) then
		API:GetMarkdown(BanHandler.Frame.IPBan):ChangeState(false)
	end
	
	for i, TextBox in ipairs(BanHandler.Frame.Time.TextBoxes:GetChildren()) do
		if not TextBox:IsA("TextBox") then
			continue
		end

		TextBox.Text = ""
	end
end

function BanHandler.CalculateTime()
	local Duration = 0
	for i, TextBox in ipairs(BanHandler.Frame.Time.TextBoxes:GetChildren()) do
		if not TextBox:IsA("TextBox") or not BanHandler.Times[TextBox.Name] or TextBox.Text:gsub("%s", "") == "" then
			continue
		end
		
		local Text = TextBox.Text:gsub("[%a%s]+", "")
		Duration += BanHandler.Times[TextBox.Name] * tonumber(Text, 10)
		--- ААААА ТЕКСТ IS NIL!
	end
	
	return Duration ~= 0 and Duration or nil
end

return BanHandler
