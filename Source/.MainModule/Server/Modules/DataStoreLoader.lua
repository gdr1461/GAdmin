export type DataStoreModule = {
	Load: (Key: string | number, DataStore: number, Ordered: boolean?) -> any,
	Save: (Key: string | number, Value: any, DataStore: number, Ordered: boolean?) -> boolean,
}

local DataStoreService = game:GetService("DataStoreService")
local DataStoreLoader = {}
DataStoreLoader.Loaded = {}

local Options = Instance.new("DataStoreOptions")
Options.AllScopes = true

function DataStoreLoader.Load(Key, DataStore, Ordered)
	local Success
	local Response
	local Attemps = 0
	
	DataStoreLoader.Loaded[DataStore] = DataStoreLoader.Loaded[DataStore] or (Ordered and DataStoreService:GetOrderedDataStore(DataStore) or DataStoreService:GetDataStore(DataStore))
	repeat
		Success, Response = pcall(function()
			return DataStoreLoader.Loaded[DataStore]:GetAsync(Key)
		end)
		
		if not Success then
			Attemps += 1
			warn(Response)
			task.wait(3)
		end
	until Success or Attemps >= 3
	
	return Success, Response
end

function DataStoreLoader.ListKeys(DataStore)
	local Success
	local Response
	local Attemps = 0

	local DataStore = DataStoreService:GetDataStore(DataStore, "", Options)
	repeat
		Success, Response = pcall(function()
			return DataStore:ListKeysAsync()
		end)

		if not Success then
			Attemps += 1
			warn(Response)
			task.wait(3)
		end
	until Success or Attemps >= 3
	
	return Success, Response
end

function DataStoreLoader.Save(Key, Value, DataStore, Ordered)
	local Success
	local Response
	local Attemps = 0

	DataStoreLoader.Loaded[DataStore] = DataStoreLoader.Loaded[DataStore] or (Ordered and DataStoreService:GetOrderedDataStore(DataStore) or DataStoreService:GetDataStore(DataStore))
	repeat
		Success, Response = pcall(function()
			DataStoreLoader.Loaded[DataStore]:SetAsync(Key, Value)
		end)

		if not Success then
			Attemps += 1
			warn(Response)
			task.wait(3)
		end
	until Success or Attemps >= 3

	return Success
end

function DataStoreLoader.Order(DataStore, Ascending, PageSize)
	Ascending = Ascending ~= nil and Ascending or false
	PageSize = PageSize or 10
	
	DataStoreLoader.Loaded[DataStore] = DataStoreLoader.Loaded[DataStore] or DataStoreService:GetOrderedDataStore(DataStore)
	return DataStoreLoader.Loaded[DataStore]:GetSortedAsync(Ascending, PageSize)
end

return DataStoreLoader
