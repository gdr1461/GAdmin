# How to use?
- Download `zip` file.
- Unpack it.
- Place it into `ServerScriptService`.

# Requirements
This system uses `DataStoreService`, so it is recommended to set `Enable Studio Access to API Services` to `true`.

# Settings
To set system to yourself, open `GAdminLoader/Settings`.
Some of the settings can be outdated.

# Custom commands
You can make either `client` or `server` custom commands.
Read `GAdminLoader/Addons/ServerCommands/INFO` first.

## Server command template:
```lua
{
		Command = "TestPlayerDamage",
		RequiredRank = 0,
		Alias = {"TestDamage"},
		UppercaseMatters = false,
		
		Debug = true, -- Command won't work anywhere.
		
		Client = false,
		ClientOnly = false,
		
		Loop = false,

		Arguments = {"Player@", "number;"},
		References = {"Player", "Damage"},
		ArgPermissions = {3},

		-- UnDo = function(Caller, Arguments)
		--	
		-- end,

		Function = function(Caller, Arguments)
			local player = Arguments[1]
			local DamageAmount = Arguments[2]

			player.Character.Humanoid:TakeDamage(DamageAmount)
		end,

		-- PreFunction = function(Caller, Arguments)
		--
		-- end,
	},
```
