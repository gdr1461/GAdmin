# How to use?
- Download [zip](https://github.com/gdr1461/GAdmin/blob/main/GAdminLoader.zip) file.
- Unpack it.
- Place it into `ServerScriptService`.
- Read [wiki](https://github.com/gdr1461/GAdmin/wiki).

> [!NOTE]
> # Requirements
> - Usage `DataStoreService`, so it is recommended to set `Enable Studio Access to API Services` to `true`.
> - Optional usage of `HttpService` to let you know if your GAdmin needs an update.

# Settings
Settings is located at: `GAdminLoader/Settings`.
Some of the settings can be outdated.

# Customizability
With `GAdmin` you can:
- Change GAdmin's TopBar using `TopBar.Reference` of `Client/Modules/Framework/TopBar`;
- Create your own `Commands`;
- Make `Calls`;
- Use three of GAdmin's `APIs`.
- Much more.

# API Usage
`API` has many useful methods. As an example, `API:GetBanlist()`.

To get `API`, you first need to get `GAdmin MainModule`:
```lua
local GAdmin = require(_G.GAdmin)
```

And then, get the `API` from it:
```lua
local API = GAdmin:GetAPI()
```

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
		Explosion.CFrame = player.Character:GetPivot()
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
	CallerClient = true,
		
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
	workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
end
```
