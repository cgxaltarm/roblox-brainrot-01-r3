-- round 4
-- Conveyor: the five-slot belt that rolls new brainrots into the market.
-- A pity timer guarantees an Epic every few minutes and a Legendary
-- after a longer wait, so there is always a reason to stay and watch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ServerScriptService.Server.Economy)
local Events = require(ServerScriptService.Server.Events)

local Conveyor = {}
Conveyor.Slots = {}
Conveyor.LastEpicAt = 0
Conveyor.LastLegendaryAt = 0
Conveyor.StartedAt = os.time()
Conveyor.NextEpicIn = Config.PityEpicSeconds
Conveyor.NextLegendaryIn = Config.PityLegendarySeconds

-- The conveyor is shared by everyone in the server, so a roll uses
-- the highest Luck level among online players (in solo play that is
-- just your own level).
local function maxLuck()
	local best = 0
	for _, state in pairs(Economy.Players) do
		if state.Upgrades.Luck > best then
			best = state.Upgrades.Luck
		end
	end
	return best
end

function Conveyor.RollSlot(forceRarity, luckLevel)
	local rarity = forceRarity
	if rarity == nil then
		rarity = BrainrotData.RollRarity(luckLevel or 0)
	end
	local def = BrainrotData.RollCharacterOfRarity(rarity)
	local mutation = BrainrotData.RollMutation()
	local cost = def.Cost
	for _, mut in ipairs(BrainrotData.MUTATIONS) do
		if mut.Name == mutation then
			cost = math.floor(def.Cost * mut.CostMult)
		end
	end
	return { CharId = def.Id, Mutation = mutation, Cost = cost }
end

function Conveyor.SpawnNext()
	local now = os.time()
	local force = nil
	if now - Conveyor.LastLegendaryAt >= Config.PityLegendarySeconds then
		force = "Legendary"
		Conveyor.LastLegendaryAt = now
	elseif now - Conveyor.LastEpicAt >= Config.PityEpicSeconds then
		force = "Epic"
		Conveyor.LastEpicAt = now
	end
	local slot = Conveyor.RollSlot(force, maxLuck())
	if Events.Current == "GoldenHour" then
		slot.Mutation = "Golden"
		local def = BrainrotData.FindCharacter(slot.CharId)
		if def ~= nil then
			slot.Cost = math.floor(def.Cost * 1.5)
		end
	end
	if force == "Epic" then
		Conveyor.LastEpicAt = now
	end
	table.insert(Conveyor.Slots, 1, slot)
	while #Conveyor.Slots > Config.ConveyorSlots do
		table.remove(Conveyor.Slots)
	end
	Conveyor.EnsureCheapSlot()
	return slot
end

function Conveyor.Fill()
	Conveyor.LastEpicAt = os.time()
	Conveyor.LastLegendaryAt = os.time()
	for _ = 1, Config.ConveyorSlots do
		table.insert(Conveyor.Slots, Conveyor.RollSlot(nil, maxLuck()))
	end
	Conveyor.EnsureCheapSlot()
end

-- Play-test 19 Nov: with $100 starting cash, whole sets could roll
-- above $100 (only Tahu Gejrot $50 of the three Commons is cheap),
-- leaving a new player unable to buy anything for a full minute.
-- Guarantee at least one slot a fresh player can afford.
-- It replaces the OLDEST slot (about to roll off anyway), never the
-- newest one, so a pity Epic/Legendary spawn is never eaten.
function Conveyor.EnsureCheapSlot()
	for _, slot in ipairs(Conveyor.Slots) do
		if slot.Cost <= Config.StartCash then
			return
		end
	end
	if #Conveyor.Slots == 0 then
		return
	end
	for _ = 1, 10 do
		local slot = Conveyor.RollSlot("Common", maxLuck())
		if slot.Cost <= Config.StartCash then
			Conveyor.Slots[#Conveyor.Slots] = slot
			return
		end
	end
	-- Fallback: plain Tahu Gejrot, no mutation, $50 flat.
	local def = BrainrotData.FindCharacter("tahu-gejrot")
	Conveyor.Slots[#Conveyor.Slots] = { CharId = def.Id, Mutation = "", Cost = def.Cost }
end

function Conveyor.GetSlots()
	return Conveyor.Slots
end

function Conveyor.TakeSlot(index)
	if index < 1 or index > #Conveyor.Slots then
		return nil
	end
	local slot = Conveyor.Slots[index]
	table.remove(Conveyor.Slots, index)
	return slot
end

function Conveyor.UpdatePity()
	local now = os.time()
	Conveyor.NextEpicIn = math.max(0, Config.PityEpicSeconds - (now - Conveyor.LastEpicAt))
	Conveyor.NextLegendaryIn = math.max(0, Config.PityLegendarySeconds - (now - Conveyor.LastLegendaryAt))
end

return Conveyor
