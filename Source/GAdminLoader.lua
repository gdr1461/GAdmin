--________________________________________________________________________________________________________________________________________________________

--== GAdmin requires itself from AssetId for its being up-to-date in your game. ==--
--= GAdmin's main module: https://create.roblox.com/store/asset/18192645218/

--=== If you may want to edit GAdmin's main module, place it inside of GAdminLoader.
--=== It will stop automatic updates.

--________________________________________________________________________________________________________________________________________________________

local Object = script:FindFirstChild("MainModule") or 18192625081
local LoaderVersion = "v1.2.0"

local Settings = require(script.Settings)
local Addons = require(script.Addons)
local GAdmin = require(Object)

Addons:SeparateAll()
GAdmin:DistributeObjects(script.Addons:FindFirstChild("Objects"))
GAdmin:SetServerCommands(Addons:GetServerCommands())
GAdmin:SetClientCommands(Addons:GetClientCommands())

GAdmin:SetCalls(Addons:GetCalls())
GAdmin:SetTopBars(Addons:GetTopBars())

GAdmin:SetNewSettings(Settings)
GAdmin:Configure(LoaderVersion)

script.Addons:Destroy()
