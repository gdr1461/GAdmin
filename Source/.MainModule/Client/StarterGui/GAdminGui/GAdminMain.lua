local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = ReplicatedStorage:WaitForChild("Client")
local Framework = require(Client.Modules.Framework)
local Signals = require(Client.SharedModules.Signals)

Framework:Configure()
local API = Framework:GetAPI()
