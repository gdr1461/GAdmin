local RunService = game:GetService("RunService")
local Client = script.Parent.Parent
local Modules = Client.Modules
local SharedModules = Client.SharedModules

local Data = require(Modules.Data)
local GlobalAPI = require(SharedModules.GlobalAPI)

local ClientAPI = require(Modules.ClientAPI)
local ClientCommands = {}

--== SETTING ADDONS ==--
local Addons = Modules:FindFirstChild("AddonsCommands")
if Addons then
	local Commands = require(Addons)
	for i, ModuleObject in ipairs(Addons:GetChildren()) do
		if not ModuleObject:IsA("ModuleScript") or ModuleObject.Name == "INFO" then
			continue
		end
		
		local AddonCommands = require(ModuleObject)
		for Name, Function in ipairs(AddonCommands) do
			if ClientCommands[Name] then
				warn(`[GAdmin Client]: Unable to load {ModuleObject.Name} command '{Name}'. Reason: Duplicated command.`)
				continue
			end

			ClientCommands[Name] = Function
		end
	end
	
	for Name, Function in ipairs(Commands) do
		if ClientCommands[Name] then
			warn(`[GAdmin Client]: Unable to load client command '{Name}'. Reason: Duplicated command.`)
			continue
		end
		
		ClientCommands[Name] = Function
	end
end

--== DELOBJECT COMMAND ==--
ClientCommands.DelObject = function(Caller, Arguments)
	local Object = Arguments[2]
	if not Object or not workspace:FindFirstChild(Object.Name, true) then
		return
	end
	
	local ParentCache = Instance.new("ObjectValue")
	ParentCache.Name = "PastParent"
	ParentCache.Value = Object.Parent
	
	ParentCache.Parent = Object
	Object.Parent = game.ReplicatedStorage["GAdmin Bin"]
end

--== RESOBJECT COMMAND ==--
ClientCommands.ResObject = function(Caller, Arguments)
	local String = Arguments[2]
	local Object
	
	for i, Part in ipairs(game.ReplicatedStorage["GAdmin Bin"]:GetChildren()) do
		if Part.Name:sub(1, #String):lower() ~= String:lower() then
			continue
		end

		Object = Part
		break
	end
	
	if not Object then
		ClientAPI:Notify("Error", `Object '{String}' can't be restored.`)
		return
	end
	
	if Object.PastParent.Value.Parent == nil then
		Object:Destroy()
		return
	end
	
	Object.Parent = Object.PastParent.Value
	Object.PastParent:Destroy()
end

--== VIEW COMMAND ==--
ClientCommands.View = function(Caller, Arguments)
	local player = Arguments[1]
	workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
end

--== CMD COMMAND ==--
ClientCommands.CmdBar = function(Caller, Arguments)
	Data.CmdBar.Visible = true
end

ClientCommands.UnCmdBar = function(Caller, Arguments)
	if not Data.CmdBar then
		return
	end
	
	Data.CmdBar:Destroy()
end

--== FLY COMMAND ==--
ClientCommands.Fly = function(Caller, Arguments)
	ClientAPI:CloseWindow("Noclip")
	--GlobalAPI:SetModelCollision(Caller.Character, "GAdmin NonPlayers")

	local HumanoidRootPart = Caller.Character.HumanoidRootPart
	local Force = Instance.new("BodyPosition")
	
	Force.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	Force.Position = HumanoidRootPart.Position + Vector3.new(0, 4, 0)
	Force.Name = "GAdminForce"
	Force.Parent = HumanoidRootPart

	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.D = 50
	BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	BodyGyro.P = 200
	BodyGyro.Name = "GAdminGyro"
	BodyGyro.CFrame = HumanoidRootPart.CFrame
	BodyGyro.Parent = HumanoidRootPart
	Caller.Character.Humanoid.PlatformStand = true

	if Data.Loops.Flying then
		return
	end
	
	local Speed = 50
	local Keys = {}
	local Except = {Enum.KeyCode.A, Enum.KeyCode.W, Enum.KeyCode.D, Enum.KeyCode.S}

	local TiltMax = 25
	local TiltAmount = 0
	local TiltIncrement = 1
	local Static = 0
	
	local LastPosition = Caller.Character.HumanoidRootPart.Position
	local Window, WindowData

	local Connection = RunService.RenderStepped:Connect(function(DeltaTime)
		local HumanoidRootPart = Caller.Character.HumanoidRootPart
		local State = WindowData.GetState()
		
		BodyGyro.Parent = State and HumanoidRootPart or script
		Force.Parent = State and HumanoidRootPart or script
		
		if not WindowData or not State then
			Keys = {}
			return
		end

		local LookAt = (workspace.CurrentCamera.Focus.Position - workspace.CurrentCamera.CFrame.Position).Unit
		local Movement, Vector = WindowData.NextMovement(Keys, Speed * 25, DeltaTime)
		local Position = HumanoidRootPart.Position

		local Target = CFrame.new(Position, Position + LookAt) * Movement
		local D = 750 + (Speed * .2)

		if Movement.Position == Vector3.new() then
			Static = Static + 1
			TiltAmount = 1

			local MaxMagnitude = 6
			local Magnitude = (HumanoidRootPart.Position - LastPosition).Magnitude

			if Magnitude <= MaxMagnitude or Static < 4 then
				return
			end

			Force.Position = HumanoidRootPart.Position
		else
			Static = 0
			Force.D = D
			TiltAmount = math.min(TiltMax, math.abs(TiltAmount + TiltIncrement))
			Force.Position = Target.Position

			local TiltX = TiltAmount * Vector.X * -0.5
			local TiltZ = TiltAmount * Vector.Z

			BodyGyro.CFrame = Target * CFrame.Angles(math.rad(TiltZ), 0, 0)
		end

		LastPosition = HumanoidRootPart.Position
		Caller.Character.Humanoid.PlatformStand = true
	end)

	Window, WindowData = ClientAPI:CreateWindow("Fly", {
		Size = "Normal",
		Inputs = {
			{
				DefaultInput = "50",
				Name = "Speed:",
				OnChange = function(WindowData, NewSpeed)
					if not tonumber(NewSpeed, 10) then
						return
					end

					Speed = tonumber(NewSpeed, 10)
				end,
			}
		},

		UserInputService = {
			function(WindowData, Began, Key, State)
				if Key == Enum.KeyCode.Unknown then
					return
				end
				
				if not table.find(Except, Key) then
					Keys = {}
					return
				end

				if not Began then
					table.remove(Keys, table.find(Keys, Key))
					return
				end

				table.insert(Keys, Key)
			end,

			function(WindowData, Began, Key)
				if Began or Key ~= Enum.KeyCode.E then
					return
				end

				WindowData.ClickButton()
			end,
		},

		OnClicked = function(WindowData, State)
			local HumanoidRootPart = Caller.Character.HumanoidRootPart
			BodyGyro.Parent = State and HumanoidRootPart or script
			Force.Parent = State and HumanoidRootPart or script
			Caller.Character.Humanoid.PlatformStand = false
		end,

		OnRemove = function(WindowData)
			BodyGyro:Destroy()
			Force:Destroy()
			
			Caller.Character.Humanoid.PlatformStand = false
			Data.Loops.Flying = nil
		end,

		ButtonOn = "Flying: On",
		ButtonOff = "Flying: Off",

		Connections = {
			Connection
		}
	})
	
	Data.Loops.Flying = Window
end

ClientCommands.UnFly = function(Caller, Arguments)
	if not Data.Loops.Flying then
		return
	end
	
	Data.Loops.Flying:Destroy()
end

--== NOCLIP COMMANDS ==--
ClientCommands.Noclip = function(Caller, Arguments)
	if Data.Loops.Noclip then
		return
	end
	
	ClientAPI:CloseWindow("Fly")
	local Keys = {}
	local Except = {Enum.KeyCode.A, Enum.KeyCode.W, Enum.KeyCode.D, Enum.KeyCode.S}
	
	local Speed = 100
	local Window, WindowData
	local Noclip = true
	
	local Connection = RunService.RenderStepped:Connect(function(DeltaTime)
		task.wait()
		local HumanoidRootPart = Caller.Character.HumanoidRootPart
		if not Noclip or not WindowData then
			return
		end
		
		HumanoidRootPart.Anchored = true
		Caller.Character.Humanoid.PlatformStand = true
		
		local LookAt = (workspace.CurrentCamera.Focus.Position - workspace.CurrentCamera.CFrame.Position).Unit
		local Movement = WindowData.NextMovement(Keys, Speed, DeltaTime)
		
		local Position = HumanoidRootPart.Position
		HumanoidRootPart.CFrame = CFrame.new(Position, Position + LookAt) * Movement
	end)
	
	Window, WindowData = ClientAPI:CreateWindow("Noclip", {
		Size = "Normal",
		Inputs = {
			{
				DefaultInput = "100",
				Name = "Speed:",
				OnChange = function(WindowData, NewSpeed)
					if not tonumber(NewSpeed, 10) then
						return
					end

					Speed = tonumber(NewSpeed, 10)
				end,
			}
		},

		UserInputService = {
			function(WindowData, Began, Key, State)
				if Key == Enum.KeyCode.Unknown then
					return
				end
				
				if not table.find(Except, Key) then
					Keys = {}
					return
				end

				if not Began then
					table.remove(Keys, table.find(Keys, Key))
					return
				end

				table.insert(Keys, Key)
			end,

			function(WindowData, Began, Key)
				if Began or Key ~= Enum.KeyCode.E then
					return
				end

				WindowData.ClickButton()
			end,
		},

		OnClicked = function(WindowData, State)
			local HumanoidRootPart = Caller.Character.HumanoidRootPart
			HumanoidRootPart.Velocity = Vector3.new()
			Noclip = State
			
			Caller.Character.Humanoid.PlatformStand = State
			Data.Loops.Noclip = State

			HumanoidRootPart.Anchored = State
			Caller.Character.Humanoid.PlatformStand = State
		end,

		OnRemove = function(WindowData)
			local HumanoidRootPart = Caller.Character.HumanoidRootPart
			Noclip = false
			
			Caller.Character.Humanoid.PlatformStand = false
			Data.Loops.Noclip = nil
			
			HumanoidRootPart.Anchored = false
			HumanoidRootPart.Velocity = Vector3.new()
			Caller.Character.Humanoid.PlatformStand = false
		end,

		ButtonOn = "Noclip: On",
		ButtonOff = "Noclip: Off",

		Connections = {
			Connection
		}
	})
	
	Data.Loops.Noclip = Window
end

ClientCommands.Clip = function(Caller, Arguments)
	if not Data.Loops.Noclip then
		return
	end
	
	Data.Loops.Noclip:Destroy()
end

return ClientCommands
