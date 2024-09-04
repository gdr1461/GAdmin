local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Client = script.Parent.Parent

local Modules = Client.Modules
local SharedModules = Client.SharedModules

local UI = require(Modules.UI)
local Draggable = require(Modules.Draggable)
local Sounds = require(SharedModules.Sounds)

local Data = require(Modules.Data)
local Notify = require(Modules.Framework.Notify)
local TopBar = require(Modules.Framework.TopBar)
local Icon = require(Modules.Framework.TopBar.Icon)

export type WindowControls = {
	Frame: Frame,
	Remove: () -> (),
	ChangeState: (Boolean: boolean?) -> (),
	GetState: () -> boolean,
	NextMovement: (Keys: {Enum.KeyCode}, Speed: number, DeltaTime: number) -> (CFrame, number),
	ClickButton: () -> (),
}

export type InputWindowControls = {
	Frame: Frame,
	Remove: () -> (),
	NextMovement: (Keys: {Enum.KeyCode}, Speed: number, DeltaTime: number) -> (CFrame, number),
	ClickButton: () -> (),
}

export type WindowData = {
	Size: "Small" | "Normal" | "Big" | "Giant",
	
	Inputs: {
		{
			DefaultInput: string?,
			Name: string,
			OnChange: (WindowControls: WindowControls, Input: string) -> ()
		}
	},
	
	UserInputService: {(WindowControls: WindowControls, Began: boolean, InputKey: Enum.KeyCode, InputType: Enum.UserInputType) -> ()},
	Connections: {RBXScriptConnection},
	
	OnClicked: (WindowControls: WindowControls, State: boolean) -> (),
	OnRemove: (WindowControls: WindowControls) -> (),
	
	ButtonOn: string,
	ButtonOff: string,
}

export type InputWindowData = {
	Size: "Normal" | "Big",

	Input: {
		DefaultInput: string?,
		OnChange: (WindowControls: InputWindowControls, Input: string) -> ()
	},

	Connections: {RBXScriptConnection},
	OnClicked: (WindowControls: InputWindowControls) -> (),
	OnRemove: (WindowControls: InputWindowControls) -> (),
}

export type MarkdownData = {
	Button: TextButton,
	State: boolean,
	ChangeState: (self: MarkdownData, Boolean: boolean) -> ()
}

export type HoverData = {
	Gui: ScreenGui,
	Info: string,
	Object: GuiObject,
}

export type APIModule = {
	__metatable: string,
	__type: string,
	
	__WindowSizes: {
		Small: UDim2,
		Normal: UDim2,
		Big: UDim2,
		Giant: UDim2,
	},
	
	__InputWindowSizes: {
		Small: UDim2,
		Normal: UDim2,
	},
	
	GetTopBarPlus: (self: APIModule) -> Icon.ModuleType,
	GetTopBar: (self: APIModule) -> Icon.IconType,
	TopBarEnabled: (self: APIModule, Enabled: boolean) -> (),
	
	ConvertUDim: (self: APIModule, Mode: "Scale" | "Offset", Udim: UDim2) -> UDim2,
	GetFrameMousePosition: (self: APIModule, Gui: ScreenGui, Frame: GuiObject, Offset: {X: number, Y: number}) -> UDim2,
	Notify: (self: APIModule, Type: "Notify" | "Error" | "Warn", Text: string, Timer: number?, OnInteract: () -> ()?) -> {any},
	
	CreateHoverInfo: (self: APIModule, Object: GuiObject, Info: string) -> HoverData,
	GetMarkdown: (self: APIModule, Button: TextButton) -> MarkdownData,
	CreateMarkdown: (self: APIModule, Button: TextButton, OnActivated: (State: boolean) -> (), Info: string?) -> MarkdownData,
	
	CreateWindow: (self: APIModule, Title: string, Data: WindowData) -> Frame,
	CreateInputWindow: (self: APIModule, Title: string, Data: InputWindowData) -> Frame,
	
	CloseWindow: (self: APIModule, Title: string) -> (),
	Clear: (self: APIModule) -> (),
}

local Proxy = newproxy(true)
local ClientAPI: APIModule = getmetatable(Proxy)

ClientAPI.__metatable = "[GAdmin ClientAPI]: Metatable methods are restricted."
ClientAPI.__type = "GAdmin ClientAPI"

ClientAPI.__WindowSizes = {
	Small = UDim2.new(.2, 0, .2, 0),
	Normal = UDim2.new(.25, 0, .25, 0),
	Big = UDim2.new(.3, 0, .3, 0),
	Giant = UDim2.new(.35, 0, .35, 0)
}

ClientAPI.__InputWindowSizes = {
	Small = UDim2.new(.15, 0, 0.2, 0),
	Normal = UDim2.new(.2, 0, .2, 0)
}

ClientAPI.__Markdowns = {}
ClientAPI.__Hovers = {}

ClientAPI.__HoverInstance = UI:GetGui().Info
ClientAPI.__CurrentHover = nil

RunService.RenderStepped:Connect(function()
	if not ClientAPI.__HoverInstance then
		return
	end
	
	local HoverData = ClientAPI.__Hovers[ClientAPI.__CurrentHover]
	ClientAPI.__HoverInstance.Visible = HoverData ~= nil
	
	if not HoverData then
		return
	end
	
	ClientAPI.__HoverInstance.Text = HoverData.Info
	local Position = ClientAPI:GetFrameMousePosition(HoverData.Gui, ClientAPI.__HoverInstance, {
		X = 7,
		Y = 75
	})
	
	ClientAPI.__HoverInstance.Position = ClientAPI:ConvertUDim("Scale", Position)
	ClientAPI.__HoverInstance.Visible = ClientAPI.__CurrentHover ~= nil
end)

function ClientAPI:__tostring()
	return self.__type
end

function ClientAPI:__index(Key)
	return ClientAPI[Key]
end

function ClientAPI:__newindex(Key, Value)
	if table.find({"__CurrentHover"}, Key) then
		ClientAPI[Key] = Value
		return
	end
	
	warn(`[GAdmin ClientAPI]: No access to set new value {Key}.`)
end

function ClientAPI:ConvertUDim(Mode, Udim)
	if Mode == "Scale" then
		local ViewPortSize = workspace.Camera.ViewportSize
		return UDim2.new(Udim.X.Offset / ViewPortSize.X, 0, Udim.Y.Offset / ViewPortSize.Y, 0)
	end
	
	local ViewPortSize = workspace.Camera.ViewportSize
	return UDim2.new(0, Udim.X.Scale * ViewPortSize.X, 0, Udim.Y.Scale * ViewPortSize.Y)
end

function ClientAPI:GetFrameMousePosition(Gui, Frame, Offset)
	Offset = Offset or {}
	Offset.X = Offset.X or 0
	Offset.Y = Offset.Y or 0
	
	local Mouse = game.Players.LocalPlayer:GetMouse()
	return UDim2.fromOffset(Mouse.X + Offset.X, Mouse.Y + Offset.Y)
end

function ClientAPI:GetTopBarPlus()
	return TopBar.TopBarPlus
end

function ClientAPI:GetTopBar()
	repeat task.wait() until TopBar.Reference
	return TopBar.Reference
end

function ClientAPI:TopBarEnabled(Enabled)
	TopBar.Reference:setEnabled(Enabled)
end

function ClientAPI:Notify(Type, Text, Timer, OnInteract)
	if (Type == "Notify" and not Data.NotifySettings.Default) or (Type == "Warn" and not Data.NotifySettings.Warn) or (Type == "Error" and not Data.NotifySettings.Error) then
		return
	end
	
	Sounds:Play("Notify", Type)
	local Notification = Notify.Create(Text, Timer)
	
	Notification:OnInteract(OnInteract)
	return Notification
end

function ClientAPI:CreateHoverInfo(Object, Text)
	self.__Hovers[Object] = {
		Gui = Object:FindFirstAncestorWhichIsA("ScreenGui"),
		Info = Text,
		Object = Object
	}
	
	Object.MouseEnter:Connect(function()
		self.__CurrentHover = Object
	end)
	
	Object.MouseLeave:Connect(function()
		if self.__CurrentHover ~= Object then
			return
		end
		
		self.__CurrentHover = nil
	end)
	
	Object.Destroying:Connect(function()
		self.__Hovers[Object] = nil
		if self.__CurrentHover == Object then
			self.__CurrentHover = nil
		end
	end)
	
	local Connection
	Connection = Object:GetPropertyChangedSignal("Parent"):Connect(function()
		if Object.Parent then
			return
		end
		
		self.__Hovers[Object] = nil
		Connection:Disconnect()
		
		if self.__CurrentHover == Object then
			self.__CurrentHover = nil
		end
	end)
	
	return self.__Hovers[Object]
end

function ClientAPI:GetMarkdown(Button)
	return self.__Markdowns[Button]
end

function ClientAPI:CreateMarkdown(Button, OnActivated, Info)
	self.__Markdowns[Button] = {
		Button = Button,
		
		State = true,
		ChangeState = function(self, Boolean)
			if Boolean == nil then
				Boolean = not self.State
			end
			
			self.State = Boolean
			Button.Text = self.State and "X" or ""
		end,
	}
	
	Button.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		self.__Markdowns[Button]:ChangeState()
		OnActivated(self.__Markdowns[Button].State)
	end)
	
	if Info then
		self:CreateHoverInfo(Button, Info)
	end
	
	return self.__Markdowns[Button]
end

function ClientAPI:CreateWindow(Title, Data)
	Data.Size = Data.Size or "Normal"
	local Window = script.Window.WindowTemplate:Clone()
	
	local Activated = true
	Window.State.Text = Data.ButtonOn
	
	local Directions = {
		[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
		[Enum.KeyCode.Left] = Vector3.new(-1, 0, 0),
		
		[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
		[Enum.KeyCode.Right] = Vector3.new(1, 0, 0),
		
		[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
		[Enum.KeyCode.Up] = Vector3.new(0, 0, -1),
		
		[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
		[Enum.KeyCode.Down] = Vector3.new(0, 0, 1),
		
		[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
		[Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
	}
	
	local WindowData = {
		Frame = Window,
		Remove = function()
			Window:Destroy()
		end,
		
		GetState = function()
			return Activated
		end,
		
		ChangeState = function(Boolean)
			Activated = (Boolean ~= nil and Boolean) or Activated
		end,
		
		NextMovement = function(Keys, Speed, DeltaTime)
			local NextMove = Vector3.new()
			for i, Key in pairs(Keys) do
				local Vector = Directions[Key]
				if not Vector then
					continue
				end
				
				NextMove = NextMove + Vector
			end
			
			return CFrame.new(NextMove * DeltaTime * Speed), NextMove
		end,
	}
	
	WindowData.ClickButton = function()
		Sounds:Play("Button", "Interact")
		Activated = not Activated

		Window.Interact.Text = Activated and "Disable" or "Enable"
		Window.State.Text = Activated and Data.ButtonOn or Data.ButtonOff
		Data.OnClicked(WindowData, Activated)
	end
	
	Window.Size = self.__WindowSizes[Data.Size]
	Window.Top.Title.Text = Title
	
	local DraggableConnections = Draggable(Window.Top)
	local Hidden = false
	
	if not Data.OnClicked then
		Window.Interact:Destroy()
		Window.State:Destroy()
		return
	end
	
	Data.Inputs = Data.Inputs or {}
	Data.UserInputService = Data.UserInputService or {}
	Data.Connections = Data.Connections or {}
	
	for i, Setting in ipairs(Data.Inputs) do
		local NewInput = script.Window.InputTemplate:Clone()
		NewInput.Title.Text = Setting.Name
		NewInput.TextBox.Text = Setting.DefaultInput or ""
		NewInput.TextBox.FocusLost:Connect(function()
			if NewInput.TextBox.Text:gsub("%s", "") == "" then
				return
			end
			
			Setting.OnChange(WindowData, NewInput.TextBox.Text)
		end)
		
		NewInput.Parent = Window.Inputs
	end
	
	DraggableConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(InputKey, GameProcessedEvent)
		if GameProcessedEvent then
			return
		end

		for i, Function in ipairs(Data.UserInputService) do
			coroutine.wrap(Function)(WindowData, true, InputKey.KeyCode, InputKey.UserInputType)
		end
	end)
	
	DraggableConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(InputKey, GameProcessedEvent)
		if GameProcessedEvent then
			return
		end
		
		if not Window or Window.Parent == nil then
			WindowData.Remove()
			return
		end

		for i, Function in ipairs(Data.UserInputService) do
			coroutine.wrap(Function)(WindowData, false, InputKey.KeyCode, InputKey.UserInputType)
		end
	end)
	
	Window.Top.Close.Activated:Once(function()
		Sounds:Play("Button", "Interact")
		WindowData.Remove()
	end)
	
	Window.Top.Hide.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		Hidden = not Hidden
		
		for i, Object in ipairs(Window:GetChildren()) do
			if not Object:IsA("GuiObject") or Object.Name == "Top" then
				continue
			end
			
			Object.Visible = not Hidden
		end
		
		Window.BackgroundTransparency = Hidden and 1 or 0
		Window.Active = not Hidden
	end)
	
	Window.Interact.Activated:Connect(WindowData.ClickButton)
	Window.Destroying:Connect(function()
		if Data.OnRemove then
			Data.OnRemove(WindowData)
		end
		
		for i, Connection in ipairs(DraggableConnections) do
			Connection:Disconnect()
		end
		
		for i, Connection in pairs(Data.Connections) do
			Connection:Disconnect()
		end
	end)
	
	Window.Name = Title
	Window.Parent = UI:GetGui().Windows
	return Window, WindowData
end

function ClientAPI:CreateInputWindow(Title, Data)
	Title = Title or "Input Window"
	Data.Size = Data.Size or "Normal"
	
	local Window = script.Window.WindowInputTemplate:Clone()
	local Directions = {
		[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
		[Enum.KeyCode.Left] = Vector3.new(-1, 0, 0),

		[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
		[Enum.KeyCode.Right] = Vector3.new(1, 0, 0),

		[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
		[Enum.KeyCode.Up] = Vector3.new(0, 0, -1),

		[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
		[Enum.KeyCode.Down] = Vector3.new(0, 0, 1),

		[Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
		[Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
	}

	local WindowData = {
		Frame = Window,
		Remove = function()
			Window:Destroy()
		end,

		NextMovement = function(Keys, Speed, DeltaTime)
			local NextMove = Vector3.new()
			for i, Key in pairs(Keys) do
				local Vector = Directions[Key]
				if not Vector then
					continue
				end

				NextMove = NextMove + Vector
			end

			return CFrame.new(NextMove * DeltaTime * Speed), NextMove
		end,
	}

	WindowData.ClickButton = function()
		Sounds:Play("Button", "Interact")
		Data.OnClicked(WindowData)
	end

	Window.Size = self.__InputWindowSizes[Data.Size]
	Window.Top.Title.Text = Title

	local DraggableConnections = Draggable(Window.Top)
	local Hidden = false

	if not Data.OnClicked then
		Window.Interact:Destroy()
		return
	end

	Data.Input = Data.Input or {}
	Data.Connections = Data.Connections or {}

	Window.TextBox.Text = Data.Input.DefaultInput or ""
	Window.TextBox.FocusLost:Connect(function()
		if Window.TextBox.Text:gsub("%s", "") == "" or not Data.Input.OnChange then
			return
		end

		Data.Input.OnChange(WindowData, Window.TextBox.Text)
	end)

	Window.Top.Close.Activated:Once(function()
		Sounds:Play("Button", "Interact")
		WindowData.Remove()
	end)

	Window.Top.Hide.Activated:Connect(function()
		Sounds:Play("Button", "Interact")
		Hidden = not Hidden

		for i, Object in ipairs(Window:GetChildren()) do
			if not Object:IsA("GuiObject") or Object.Name == "Top" then
				continue
			end

			Object.Visible = not Hidden
		end

		Window.BackgroundTransparency = Hidden and 1 or 0
		Window.Active = not Hidden
	end)

	Window.Interact.Activated:Connect(WindowData.ClickButton)
	Window.Destroying:Connect(function()
		if Data.OnRemove then
			Data.OnRemove(WindowData)
		end

		for i, Connection in ipairs(DraggableConnections) do
			Connection:Disconnect()
		end

		for i, Connection in pairs(Data.Connections) do
			Connection:Disconnect()
		end
	end)

	Window.Parent = UI:GetGui().Windows
	return Window, WindowData
end

function ClientAPI:CloseWindow(Title)
	for i, Window in ipairs(UI:GetGui().Windows:GetChildren()) do
		if Window.Name ~= Title then
			continue
		end
		
		Window:Destroy()
	end
end

function ClientAPI:Clear()
	UI:GetGui().Windows:ClearAllChildren()
end

return Proxy :: APIModule
