local TweenService = game:GetService("TweenService")
local Info = TweenInfo.new(.5, Enum.EasingStyle.Back)

local Client = script.Parent.Parent.Parent
local SharedModules = Client.SharedModules
local Sounds = require(SharedModules.Sounds)

local Modules = script.Parent.Parent
local UI = require(Modules.UI)

local Gui = UI:GetGui()
local Notify = {}

Notify.__index = Notify
Notify.Notifications = {}
Notify.CurrentOrder = 0

function Notify.Create(Text, Time)
	Notify.CurrentOrder += 1
	local Frame = script.Template:Clone()

	Frame.Name = `{Notify.CurrentOrder}: {Text}`
	Frame.HolderFrame.Description.Description.Text = Text
	Frame.HolderFrame.Position = UDim2.new(1, 0, 0, 0)

	Frame.LayoutOrder = Notify.CurrentOrder
	Frame.Parent = Gui.Notifications

	local self = setmetatable({}, Notify)
	self.Frame = Frame
	self.Removed = false
	
	self.CurrentTween = TweenService:Create(self.Frame.HolderFrame, Info, {Position = UDim2.new(0, 0, 0, 0)})
	self.CurrentTween:Play()

	self.Highlighted = false
	self.Connections = {}
	
	self.Connections.CloseEnter = self.Frame.HolderFrame.Top.Close.MouseEnter:Connect(function()
		Sounds:Play("Button", "Hover")
	end)
	
	self.Connections.Close = self.Frame.HolderFrame.Top.Close.Activated:Once(function()
		Sounds:Play("Button", "Interact")
		self:Exit()
	end)

	Time = Time or 10
	coroutine.wrap(function()
		for i = Time, 1, -1 do
			if not self.Frame then
				break
			end

			self.Frame.HolderFrame.Top.Timer.Text = i
			task.wait(1)
		end
		
		if not self.Frame then
			return
		end

		self:Exit()
	end)()

	table.insert(Notify.Notifications, self)
	return self
end

function Notify.Clear()
	for i, Notify in pairs(Notify.Notifications) do
		Notify:Remove()
	end
end

function Notify:OnInteract(Function)
	if not Function or type(Function) ~= "function" or self.Connections.OnInteract then
		return
	end
	
	self.Frame.HolderFrame.Interact.Visible = true
	self.Connections.Hovered = self.Frame.HolderFrame.Interact.MouseEnter:Connect(function()
		Sounds:Play("Button", "Hover")
		self:Highlight(true)
	end)
	
	self.Connections.UnHovered = self.Frame.HolderFrame.Interact.MouseLeave:Connect(function()
		self:Highlight(false)
	end)
	
	self.Connections.OnInteract = self.Frame.HolderFrame.Interact.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self:Highlight(false)
		
		Function()
		self:Exit()
	end)
	
	return self
end

function Notify:Highlight(State)
	State = State ~= nil and State or not self.Highlighted
	self.Highlighted = State
	
	for i, TextObject in ipairs(self.Frame:GetDescendants()) do
		if not table.find({"TextLabel", "TextButton", "TextBox"}, TextObject.ClassName) then
			continue
		end
		
		TextObject.TextColor3 = self.Highlighted and UI:GetColor("Selected") or UI:GetColor("Text")
	end
	
	return self
end

function Notify:DisconnectAll()
	for i, Connection in pairs(self.Connections) do
		Connection:Disconnect()
	end
	
	self.Connections = {}
	return self
end

function Notify:Exit()
	if not self.Frame or self.Removed then
		return
	end
	
	self:DisconnectAll()
	if self.CurrentTween then self.CurrentTween:Pause() end
	
	self.CurrentTween = TweenService:Create(self.Frame.HolderFrame, Info, {Position = UDim2.new(1, 0, 0, 0)})
	self.CurrentTween:Play()
	
	self.CurrentTween.Completed:Wait()
	if not self.Frame or self.Removed then return end
	
	self:Remove()
end

function Notify:Remove()
	if not self.Frame or self.Removed then
		return
	end
	
	self.Removed = true
	self.Frame:Destroy()
	self:DisconnectAll()
	
	setmetatable(self, nil)
	table.clear(self)
end

return Notify
