local Client = script.Parent.Parent
local SoundFolder = Client.Sounds

export type Class = {[string]: Sound}
export type SoundsFramework = {
	__metatable: string,
	__type: string,
	
	__Sounds: {[string]: Class},
	Play: (self: SoundsFramework, Class: string, SoundName: string) -> Sound,
	
	GetRandom: (self: SoundsFramework, Class: string) -> Sounds,
	GetClass: (self: SoundsFramework, Class: string) -> Class,
}

local Proxy = newproxy(true)
local Sounds: SoundsFramework = getmetatable(Proxy)

Sounds.__metatable = "[GAdmin Sounds]: Metatable methods are restricted."
Sounds.__type = "GAdmin Sounds"
Sounds.__Sounds = {}

function Sounds:__tostring()
	return self.__type
end

function Sounds:__index(Key)
	return Sounds[Key]
end

function Sounds:__newindex(Key, Value)
	Sounds[Key] = Value
	return Value
end

function Sounds:Play(Class, SoundName)
	local ClassData = self.__Sounds[Class]
	if not ClassData then
		return
	end
	
	local Sound = ClassData[SoundName]
	if not Sound then
		return
	end
	
	local SoundClone = Sound:Clone()
	SoundClone.Parent = Client.Temp
	SoundClone:play()
	
	coroutine.wrap(function()
		SoundClone.Ended:Wait()
		SoundClone:Destroy()
	end)()
	
	return SoundClone
end

function Sounds:GetRandom(Class)
	local ClassFolder = SoundFolder:FindFirstChild(Class)
	if not ClassFolder then
		return
	end
	
	local Sound = ClassFolder[math.random(1, #ClassFolder)]
	return Sound
end

function Sounds:GetClass(Class)
	return self.__Sounds[Class]
end

for i, Sound in ipairs(SoundFolder:GetDescendants()) do
	if not Sound:IsA("Sound") then
		continue
	end
	
	local Class = Sound.Parent:IsA("Folder") and Sound.Parent.Name or "Default"
	Sounds.__Sounds[Class] = Sounds.__Sounds[Class] or {}
	Sounds.__Sounds[Class][Sound.Name] = Sound
end

return Proxy :: SoundsFramework
