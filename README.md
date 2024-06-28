# How to use?
- Download `zip` file.
- Unpack it.
- Place it into `ServerScriptService`.

# Requirements
This system uses `DataStoreService`, so it is recommended to set `Enable Studio Access to API Services` to `true`.

# Settings
Settings is located at: `GAdminLoader/Settings`.
Some of the settings can be outdated.

# Custom commands
You can make either `client` or `server` custom commands.
Read `GAdminLoader/Addons/ServerCommands/INFO` and `GAdminLoader/Addons/ClientCommands/INFO` first.

## Server command template:
```lua
{
	Command = "Explode",
	RequiredRank = 3,
	Alias = {"Explosion"},
	UppercaseMatters = false,
		
	Client = false,
	ClientOnly = false,
		
	Loop = false,

	Arguments = {"Player@"},
	References = {"Player"},
	ArgPermissions = {},

	Function = function(Caller, Arguments)
		local player = Arguments[1]
		local Explosion = Instance.new("Explosion")

		Explosion.Parent = player.Character.HumanoidRootPart
		Explosion.CFrame = player.Character:GetPivot9)
	end,
},
```

## Client command template:
### In `ServerCommands`:
```lua
{
	Command = "View",
	RequiredRank = 3,
	Alias = {"SeePlayer"},
	UppercaseMatters = false,
		
	Client = true,
	ClientOnly = true,
		
	Loop = false,

	Arguments = {"Player@"},
	References = {"Player"},
	ArgPermissions = {},
},
```

### In `ClientCommands`:
```lua
ClientCommands.View = function(Caller, Arguments)
	local Player = Arguments[1]
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
end
```
