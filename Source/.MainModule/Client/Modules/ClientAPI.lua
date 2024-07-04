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
	
	Notify: (self: APIModule, Type: "Notify" | "Error" | "Warn", Text: string, Timer: number?, OnInteract: () -> ()?) -> {any},
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

function ClientAPI:__tostring()
	return self.__type
end

function ClientAPI:__index(Key)
	return ClientAPI[Key]
end

function ClientAPI:__newindex(Key)
	warn(`[GAdmin ClientAPI]: No access to set new value {Key}.`)
end

function ClientAPI:GetTopBarPlus()
	return TopBar.TopBarPlus
end

function ClientAPI:GetTopBar()
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