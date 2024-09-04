--________________________________________________________________________________________________________________________________________________________


--====== SystemTypes is every type of GAdmin's module.
--=== You'll need them for autofill in your addons.

--________________________________________________________________________________________________________________________________________________________

-- << OTHER >>

local TopBarPlusTypes = require(script.TopBarPlus)
export type UserId = {}
export type Banned = {
	Reason: string,
	Time: string
}

export type DefaultPlayerData = {
	Rank: string,
	ServerRank: number,
	RankExpiresIn: any,
	Prefix: string,
	DefaultKickMessage: string,
	DefaultBanMessage: string,
	Banned: false | Banned,
}

export type ArgumentsSigns = {
	Optional: string,
	MultiType: string,
	InGame: string,
	OptionalInGame: string,
	FilterString: string,
	EqualRank: string,
}

export type RankType = {Rank: number, Users: {number | string}}
export type CollisionGroups = "Default" | "GAdmin Players" | "GAdmin NonPlayers" | "GAdmin NonCollide"

export type MessageTopic = {
	Topic: string,
	Arguments: {any}
}

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

export type MarkdownData = {
	Button: TextButton,
	State: boolean,
	ChangeState: (self: MarkdownData, Boolean: boolean) -> ()
}

export type HoverData = {
	Gui: ScreenGui,
	Info: string,
	Object: GuiObject,
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


--________________________________________________________________________________________________________________________________________________________

-- << SERVER >>

export type ServerData = {
	ClientConfigured: boolean,
	SessionData: DefaultPlayerData,
	
	TempData: {
		[UserId]: {
			Health: number,
			MaxHealth: number,
			Speed: number,
			JumpPower: number,
		}
	},
	
	Logs: {},
	ChatLogs: {},
	
	ServerRankAccess: number,
	Loops: {},
	DefaultPlayerData: DefaultPlayerData,
	EditablePlayerData: {},
	Tools: {},
	
	CommandArgumentsSigns: ArgumentsSigns,
	DefaultArguments: {},
	ArgumentsTransform: {},
	ClientCommandsList: {},
	ClientFolder: Folder
}

export type ServerDataStoreLoader = {
	Loaded: {},
	Load: (Key: string, DataStore: string, Ordered: boolean?) -> (boolean, any),
	Save: (Key: string, Value: any, DataStore: string, Ordered: boolean?) -> boolean,
	
	ListKeys: (DataStore: string) -> (boolean, any),
	Order: (DataStore: string, Ascending: boolean, PageSize: number) -> DataStorePages
}

export type ServerSettings = {
	Ranks: {any},
	AdminAccess: number,
	RankNoticeAccess: number,
	BToolsAccess: number,

	EveryoneAccess: number,
	BanlistAccess: number,

	DefaultKickMessage: string,
	DefaultBanMessage: string,

	CommandInLineDebounce: boolean,
	DefaultPrefix: string,
	PrivateServerOwner: number,
	DefaultRank: number,
	Banned: {},
}

export type ServerAPI = {
	__metatable: string,
	__type: string,
	__ClientBlacklist: {string?},

	SetPlayerServerRank: (self: ServerAPI, player: Player, Rank: number) -> (),
	GetPlayer: (self: ServerAPI, Name: string) -> Player,
	GetPrefix: (self: ServerAPI, player: Player) -> string,

	GetOwner: (self: ServerAPI) -> number,
	GetRank: (self: ServerAPI, Data: string | number, AlwaysData: boolean?) -> RankType,
	GetRankUsers: (self: ServerAPI, Rank: string) -> {number?}?,

	CheckUserRank: (self: ServerAPI, player: Player) -> (),
	GetUserRank: (self: ServerAPI, player: Player) -> number,
	GetUserIdRank: (self: ServerAPI, UserId: number) -> number,
	GetUserSettings: (self: ServerAPI, player: Player) -> {[string]: any?},
	GetOrderedRanks: (self: ServerAPI, Ascending: boolean) -> {[number]: string}?,

	GetBanlist: (self: ServerAPI) -> {number},
	GetStat: (self: ServerAPI, player: Player, Name: string) -> NumberValue | IntValue,
	IsBanned: (self: ServerAPI, player: Player) -> boolean,

	Ban: (self: ServerAPI, Caller: Player, UserId: number, Reason: string, Time: number?) -> (string, string?),
	BanIP: (self: ServerAPI, Caller: Player, UserId: number, Reason: string, Time: number?) -> (string, string?),

	UnBan: (self: ServerAPI, UserId: number) -> (string, string?),
	PushMessage: (self: ServerAPI, Data: MessageTopic) -> (),

	GetSignals: (self: ServerAPI) -> {},
	ClientCall: (player: Player, Action: string, Variables: any?) -> any?,

	GetRanks: (self: ServerAPI) -> {[string]: RankType},
	GetServerRanks: (self: ServerAPI) -> {[number]: number},
	GetPlayerRanks: (self: ServerAPI) -> {[number]: {Global: number, Server: number}},
}

--________________________________________________________________________________________________________________________________________________________

-- << SHARED >>

export type SharedSignals = {
	__metatable: string,
	__type: string,
	__Events: {[string]: {Signal: RemoteEvent | RemoteFunction, Action: string}},

	__Side: string,
	__OtherSide: string,
	__Connections: {RBXScriptConnection},

	Set: (self: SharedSignals, Folder: Folder) -> (),
	Fire: (self: SharedSignals, Event: string, Variables: any) -> any,

	FireAll: (self: SharedSignals, Event: string, Variables: any) -> (),
	Connect: (self: SharedSignals, Event: string, Function: () -> ()) -> RBXScriptConnection?,
	DisconnectAll: (self: SharedSignals) -> ()
}

export type SharedAPI = {
	__metatable: string,
	__type: string,

	GetSimilarity: (self: SharedAPI, String1: string, String2: string, Mode: "Percent" | "Symbols", Value: number) -> boolean,
	FindValue: (self: SharedAPI, Data: Dictionary, Value: any) -> Key,

	FindValueParent: (self: SharedAPI, Data: Dictionary, Value: any) -> Dictionary,
	FindKey: (self: SharedAPI, Data: Table, Key: Key) -> Value,

	GetServerType: (self: SharedAPI) -> "Global" | "Reserved" | "Private",
	HeadShot: (self: SharedAPI, UserId: number) -> (string, boolean),

	SetModelCollision: (self: SharedAPI, Model: Model | Folder, CollisionGroup: CollisionGroups) -> (),
	GetPlayer: (self: SharedAPI, Method: "Name" | "UserId", Variables: any) -> Player,

	GetCommand: (self: SharedAPI, Commands: Commands, Command: string) -> (string, CommandData),
	GetSide: (self: SharedAPI) -> "Server" | "Client",
}

--________________________________________________________________________________________________________________________________________________________

-- << CLIENT >>

export type ClientData = {
	MainFrames: {},
	Loops: {},
	Device: string,
	Banlist: {},
	ToUnBan: number,
	
	Ranks: {},
	OrderedRanks: {},
	AssetId: number,
	
	Rank: {
		Name: string,
		Id: number,
	},
	
	Updates: {},
	Settings: {},
}

export type ClientAPI = {
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

	GetTopBarPlus: (self: ClientAPI) -> Icon.ModuleType,
	GetTopBar: (self: ClientAPI) -> Icon.IconType,
	TopBarEnabled: (self: ClientAPI, Enabled: boolean) -> (),

	ConvertUDim: (self: ClientAPI, Mode: "Scale" | "Offset", Udim: UDim2) -> UDim2,
	GetFrameMousePosition: (self: ClientAPI, Gui: ScreenGui, Frame: GuiObject, Offset: {X: number, Y: number}) -> UDim2,
	Notify: (self: ClientAPI, Type: "Notify" | "Error" | "Warn", Text: string, Timer: number?, OnInteract: () -> ()?) -> {any},

	CreateHoverInfo: (self: ClientAPI, Object: GuiObject, Info: string) -> HoverData,
	GetMarkdown: (self: ClientAPI, Button: TextButton) -> MarkdownData,
	CreateMarkdown: (self: ClientAPI, Button: TextButton, OnActivated: (State: boolean) -> (), Info: string?) -> MarkdownData,

	CreateWindow: (self: ClientAPI, Title: string, Data: WindowData) -> Frame,
	CreateInputWindow: (self: ClientAPI, Title: string, Data: InputWindowData) -> Frame,

	CloseWindow: (self: ClientAPI, Title: string) -> (),
	Clear: (self: ClientAPI) -> (),
}

local SystemTypes = {}

return SystemTypes
