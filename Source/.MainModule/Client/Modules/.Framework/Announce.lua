local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local PlayerGui = player.PlayerGui
local Gui = PlayerGui:WaitForChild("GAdminGlobal")

local Announce = {}
Announce.Playing = false
Announce.Order = {}
Announce.ToPlay = 0

Announce.First = true
Announce.Ticket = 0

function Announce.Create(Title, Message)
	Announce.Ticket += 1
	local Ticket = Announce.Ticket
	
	local Table = {Title, Message, Ticket}
	table.insert(Announce.Order, Table)
	
	if #Announce.Order - 1 > 0 then
		repeat
			task.wait()
		until not Announce.Playing and Announce.ToPlay == Ticket
	end
	
	Announce.New(Title, Message)
end

Gui.Announcement.Size = UDim2.new(0, 0, .07, 0)
function Announce.New(Title, Message)
	Announce.Playing = true
	
	Gui.Announcement.Visible = true
	Gui.Announcement.Expand.Size = UDim2.new(1, 0, 1, 0)
	
	Gui.Announcement.Title.Text = Title
	Gui.Announcement.Message.Text = Message
	
	local Tween = TweenService:Create(Gui.Announcement, TweenInfo.new(1), {Size = UDim2.new(1, 0, .07, 0)})
	Tween:Play()
	Tween.Completed:Wait()
	
	local Tween = TweenService:Create(Gui.Announcement.Expand, TweenInfo.new(.7), {Size = UDim2.new(0, 0, 1, 0)})
	Tween:Play()
	Tween.Completed:Wait()
	
	task.wait(8)
	
	local Tween = TweenService:Create(Gui.Announcement.Expand, TweenInfo.new(.4), {Size = UDim2.new(1, 0, 1, 0)})
	Tween:Play()
	Tween.Completed:Wait()
	
	if #Announce.Order - 1 > 0 then
		Announce.Playing = false
		Announce.Next()
		return
	end
	
	local Tween = TweenService:Create(Gui.Announcement, TweenInfo.new(.5), {Size = UDim2.new(0, 0, .07, 0)})
	Tween:Play()
	Tween.Completed:Wait()
	
	Gui.Announcement.Visible = false
	Announce.Playing = false
	Announce.Next()
end

function Announce.Next()
	Announce.ToPlay = Announce.Order[1][3] + 1
	table.remove(Announce.Order, 1)
end

return Announce
