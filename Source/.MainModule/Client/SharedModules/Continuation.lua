export type ContinuationType = {
	__metatable: string,
	__type: string,
	__Connections: {any},
	
	Bind: (self: ContinuationType, Caller: Player, Name: string, Functioon: (Character: Model) -> ()) -> (),
	UnBind: (self: ContinuationType, Caller: Player, Name: string) -> (),
	Find: (self: ContinuationType, Caller: Player, Name: string) -> (),
}

local Proxy = newproxy(true)
local Continuation: ContinuationType = getmetatable(Proxy)

Continuation.__metatable = "[GAdmin Continuation]: Metatable methods are restricted."
Continuation.__type = "GAdmin Continuation"
Continuation.__Connections = {}

function Continuation:__tostring()
	return self.__type
end

function Continuation:__index(Key)
	return Continuation[Key]
end

function Continuation:__newindex(Key, Value)
	Continuation[Key] = Value
	return Value
end

function Continuation:Bind(Caller, Name, Function)
	self.__Connections[Caller.UserId] = self.__Connections[Caller.UserId] or {}
	table.insert(self.__Connections[Caller.UserId], {
		Name = Name,
		Connection = Caller.CharacterAdded:Connect(Function)
	})
end

function Continuation:UnBind(Caller, Name)
	if not self.__Connections[Caller.UserId] then
		return
	end
	
	for i, Setting in pairs(self.__Connections[Caller.UserId]) do
		if Setting.Name ~= Name then
			continue
		end
		
		Setting.Connection:Disconnect()
		self.__Connections[Caller.UserId][i] = nil
	end
end

function Continuation:Find(Caller, Name)
	if not self.__Connections[Caller.UserId] then
		return
	end
	
	for i, Setting in pairs(self.__Connections[Caller.UserId]) do
		if Setting.Name ~= Name then
			continue
		end

		return true
	end
end

return Proxy :: ContinuationType
