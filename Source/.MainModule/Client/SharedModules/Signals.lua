export type SignalManager = {
	__metatable: string,
	__type: string,
	__Events: {[string]: {Signal: RemoteEvent | RemoteFunction, Action: string}},
	
	__Side: string,
	__OtherSide: string,
	__Connections: {RBXScriptConnection},
	
	Set: (self: SignalManager, Folder: Folder) -> (),
	Fire: (self: SignalManager, Event: string, Variables: any) -> any,
	
	FireAll: (self: SignalManager, Event: string, Variables: any) -> (),
	Connect: (self: SignalManager, Event: string, Function: () -> ()) -> RBXScriptConnection?,
	DisconnectAll: (self: SignalManager) -> ()
}

local Proxy = newproxy(true)
local Signals: SignalManager = getmetatable(Proxy)

Signals.__metatable = "[GAdmin Signals]: Metatable methods are restricted."
Signals.__type = "GAdmin Signals"

Signals.__Side = game.Players.LocalPlayer and "Client" or "Server"
Signals.__OtherSide = game.Players.LocalPlayer and "Server" or "Client"

Signals.__Events = {}
Signals.__Connections = {}

function Signals:__tostring()
	return self.__type
end

function Signals:__index(Key)
	return Signals[Key]
end

function Signals:__newindex(Key, Value)
	Signals[Key] = Value
end

function Signals:Set(Folder)
	for i, Remote in ipairs(Folder:GetChildren()) do
		self.__Events[Remote.Name] = {
			Signal = Remote,
			Action = not Remote:IsA("RemoteFunction") and `Fire{self.__OtherSide}` or `Invoke{self.__OtherSide}`,
			Connection = not Remote:IsA("RemoteFunction") and `On{self.__Side}Event` or `On{self.__Side}Invoke`,
			FireAll = (not Remote:IsA("RemoteFunction") and self.__OtherSide == "Client") and "FireAllClients",
		}
	end
end

function Signals:Fire(Event, ...)
	if not self.__Events[Event] then
		warn(`[GAdmin Signals]: {Event} doesn't exist.`)
		return
	end
	
	local Data = self.__Events[Event]
	return Data.Signal[Data.Action](Data.Signal, ...)
end

function Signals:FireAll(Event, ...)
	if self.__Side == "Client" then
		warn(`[GAdmin Signals]: FireAll method is avaible only on server.`)
		return
	end
	
	if not self.__Events[Event] then
		warn(`[GAdmin Signals]: {Event} doesn't exists.`)
		return
	end

	local Data = self.__Events[Event]
	if Data.FireAll then
		Data.Signal[Data.FireAll](Data.Signal, ...)
		return
	end
	
	for i, player in ipairs(game.Players:GetPlayers()) do
		Data.Signal[Data.Action](Data.Signal, player, ...)
	end
end

function Signals:Connect(Event, Function)
	if not self.__Events[Event] then
		warn(`[GAdmin Signals]: {Event} doesn't exists.`)
		return
	end
	
	local Data = self.__Events[Event]
	if Data.Signal:IsA("RemoteFunction") then
		Data.Signal[Data.Connection] = Function
		return
	end
	
	local Connection = Data.Signal[Data.Connection]:Connect(Function)
	table.insert(self.__Connections, Connection)
	return Connection
end

function Signals:Disconnect()
	for i, Connection in ipairs(self.__Connections) do
		Connection:Disconnect()
	end
	
	self.__Connections = {}
end

return Proxy :: SignalManager
