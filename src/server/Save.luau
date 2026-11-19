-- round 4
-- Save: persist cash, rebirth level, placed brainrots, the owned
-- index, buff upgrades and mission progress in a DataStore, with an
-- autosave every two minutes and a save when the player leaves.
-- A failed save never blocks the game.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Economy)
local Config = require(ReplicatedStorage.Shared.Config)

local Save = {}
local store = nil

local function getStore()
	if store ~= nil then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	end
	return store
end

function Save.LoadPlayer(player)
	local state = Economy.NewPlayer(player)
	local ds = getStore()
	if ds == nil then
		return state
	end
	local ok, data = pcall(function()
		return ds:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not ok or type(data) ~= "table" then
		return state
	end
	if type(data.Cash) == "number" then
		state.Cash = data.Cash
	end
	if type(data.Rebirth) == "number" then
		state.Rebirth = data.Rebirth
	end
	if type(data.Placed) == "table" then
		state.Placed = data.Placed
	end
	if type(data.Owned) == "table" then
		state.Owned = data.Owned
	end
	if type(data.Upgrades) == "table" then
		for _, id in ipairs({ "Luck", "Income", "Speed" }) do
			if type(data.Upgrades[id]) == "number" then
				state.Upgrades[id] = math.clamp(math.floor(data.Upgrades[id]), 0, 5)
			end
		end
	end
	if type(data.Missions) == "table" then
		for _, key in ipairs({ "Bought", "CollectedTotal", "Stolen", "GearBought", "Rebirths" }) do
			if type(data.Missions[key]) == "number" then
				state.Missions[key] = math.max(0, math.floor(data.Missions[key]))
			end
		end
		if type(data.Missions.Claimed) == "table" then
			state.Missions.Claimed = data.Missions.Claimed
		end
	end
	return state
end

function Save.SavePlayer(player)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	local ds = getStore()
	if ds == nil then
		return false
	end
	local data = {
		Cash = state.Cash,
		Rebirth = state.Rebirth,
		Placed = state.Placed,
		Owned = state.Owned,
		Upgrades = state.Upgrades,
		Missions = state.Missions,
	}
	local ok, _ = pcall(function()
		ds:SetAsync("player_" .. tostring(player.UserId), data)
	end)
	return ok
end

function Save.SaveAll()
	for _, player in ipairs(game.Players:GetPlayers()) do
		Save.SavePlayer(player)
	end
end

return Save
