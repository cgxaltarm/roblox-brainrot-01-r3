-- round 4
-- Economy: the single server store for player money, placed brainrots,
-- rebirths, locks, missions and the collect pile. Every other server
-- module reads and writes through these functions; the client never
-- touches money.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local Economy = {}
Economy.Players = {}

function Economy.NewPlayer(player)
	Economy.Players[player.UserId] = {
		Player = player,
		Cash = Config.StartCash,
		Pending = 0,
		Rebirth = 0,
		Placed = {},
		Owned = {},
		Carrying = nil,
		BaseIndex = 0,
		LockUntil = 0,
		LockCooldownUntil = 0,
		StealCooldownUntil = 0,
		JoinTime = os.time(),
		Gear = { Slap = false, CoilUntil = 0, Traps = 0 },
		Upgrades = { Luck = 0, Income = 0, Speed = 0 },
		TutorialStep = 0,
		Missions = {
			Bought = 0,
			CollectedTotal = 0,
			Stolen = 0,
			GearBought = 0,
			Rebirths = 0,
			Claimed = {},
		},
	}
	return Economy.Players[player.UserId]
end

function Economy.Get(player)
	return Economy.Players[player.UserId]
end

function Economy.RemovePlayer(player)
	Economy.Players[player.UserId] = nil
end

function Economy.AddCash(player, amount)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	state.Cash = state.Cash + amount
end

function Economy.GetCash(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	return state.Cash
end

function Economy.GetIncomePerSec(player, eventMult)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	local total = 0
	for _, placed in pairs(state.Placed) do
		local def = BrainrotData.FindCharacter(placed.CharId)
		if def ~= nil then
			-- IncomeFor applies the mutation multiplier (Golden x2,
			-- Rainbow x5, Diamond x10) and the rebirth bonus.
			total = total + BrainrotData.IncomeFor(def, placed.Mutation, state.Rebirth, eventMult)
		end
	end
	-- Buff Shop: each Income level adds +20%.
	return math.floor(total * (1 + 0.2 * state.Upgrades.Income))
end

-- Base walk speed: 16, +2 per Speed upgrade level (max 26 at Lv 5).
-- Coil and carry multipliers always apply on top of this number.
function Economy.BaseWalkSpeed(player)
	local state = Economy.Get(player)
	local level = 0
	if state ~= nil then
		level = state.Upgrades.Speed
	end
	return 16 + 2 * level
end

function Economy.BuyUpgrade(player, upgradeId)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local def = nil
	for _, u in ipairs(BrainrotData.UPGRADES) do
		if u.Id == upgradeId then
			def = u
		end
	end
	if def == nil then
		return false, "unknown upgrade"
	end
	local level = state.Upgrades[upgradeId] or 0
	if level >= BrainrotData.UPGRADE_MAX then
		return false, "Sudah max"
	end
	local cost = def.Prices[level + 1]
	if state.Cash < cost then
		return false, "Uang tidak cukup"
	end
	state.Cash = state.Cash - cost
	state.Upgrades[upgradeId] = level + 1
	if upgradeId == "Speed" then
		-- Apply at once so the player feels it without respawning.
		local character = player.Character
		if character ~= nil then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				local speed = Economy.BaseWalkSpeed(player)
				if state.Gear.CoilUntil > os.time() then
					speed = speed * Config.CoilSpeedMult
				elseif state.Carrying ~= nil then
					speed = speed * Config.CarrySpeedMult
				end
				humanoid.WalkSpeed = speed
			end
		end
	end
	return true, "upgraded"
end

function Economy.TickIncome(eventMult)
	for _, state in pairs(Economy.Players) do
		local income = Economy.GetIncomePerSec(state.Player, eventMult)
		if income > 0 then
			state.Pending = state.Pending + income
		end
	end
end

function Economy.CollectCash(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	local amount = math.floor(state.Pending)
	state.Pending = state.Pending - amount
	state.Cash = state.Cash + amount
	if amount > 0 then
		state.Missions.CollectedTotal = state.Missions.CollectedTotal + amount
	end
	return amount
end

function Economy.SlotCount(player)
	local state = Economy.Get(player)
	if state == nil then
		return Config.BaseSlots
	end
	return math.min(Config.MaxSlots, Config.BaseSlots + state.Rebirth * Config.RebirthSlotsBonus)
end

function Economy.FreeSlot(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	for slot = 1, Economy.SlotCount(player) do
		if state.Placed[slot] == nil then
			return slot
		end
	end
	return 0
end

function Economy.HasCharacter(player, charId)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	for _, placed in pairs(state.Placed) do
		if placed.CharId == charId then
			return true
		end
	end
	return false
end

function Economy.BuyBrainrot(player, slotDef)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying ~= nil then
		return false, "already carrying"
	end
	if state.Cash < slotDef.Cost then
		return false, "not enough cash"
	end
	state.Cash = state.Cash - slotDef.Cost
	state.Carrying = {
		CharId = slotDef.CharId,
		Mutation = slotDef.Mutation,
		FromConveyor = true,
		OwnerId = 0,
		OwnerSlot = 0,
	}
	state.Owned[slotDef.CharId] = true
	state.Missions.Bought = state.Missions.Bought + 1
	return true, "bought"
end

function Economy.PlaceCarried(player, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying == nil then
		return false, "not carrying"
	end
	if slot < 1 or slot > Economy.SlotCount(player) then
		return false, "bad slot"
	end
	if state.Placed[slot] ~= nil then
		return false, "slot taken"
	end
	local carried = state.Carrying
	state.Placed[slot] = { CharId = carried.CharId, Mutation = carried.Mutation }
	state.Owned[carried.CharId] = true
	state.Carrying = nil
	if state.TutorialStep < 2 then
		state.TutorialStep = 2
	end
	return true, "placed"
end

function Economy.SellBrainrot(player, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local placed = state.Placed[slot]
	if placed == nil then
		return false, "empty slot"
	end
	local def = BrainrotData.FindCharacter(placed.CharId)
	if def == nil then
		return false, "unknown character"
	end
	local refund = math.floor(def.Cost * Config.SellRefund)
	state.Cash = state.Cash + refund
	state.Placed[slot] = nil
	return true, "sold"
end

-- Fuse: three placed brainrots of the SAME rarity become one random
-- brainrot one tier higher, placed in the first freed slot.
-- Returns ok, result-or-reason. The caller rebuilds the 3D models.
function Economy.Fuse(player, slots)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state", nil
	end
	if type(slots) ~= "table" or #slots ~= 3 then
		return false, "pilih 3 brainrot", nil
	end
	if slots[1] == slots[2] or slots[1] == slots[3] or slots[2] == slots[3] then
		return false, "slot harus berbeda", nil
	end
	local rarity = nil
	for _, slot in ipairs(slots) do
		local placed = state.Placed[slot]
		if placed == nil then
			return false, "slot kosong", nil
		end
		local def = BrainrotData.FindCharacter(placed.CharId)
		if def == nil then
			return false, "unknown character", nil
		end
		if rarity == nil then
			rarity = def.Rarity
		elseif def.Rarity ~= rarity then
			return false, "raritas harus sama", nil
		end
	end
	local nextRarity = BrainrotData.NextRarity(rarity)
	if nextRarity == nil then
		return false, "raritas ini tidak bisa di-fuse", nil
	end
	local result = BrainrotData.RollCharacterOfRarity(nextRarity)
	local mutation = BrainrotData.RollMutation()
	for _, slot in ipairs(slots) do
		state.Placed[slot] = nil
	end
	local targetSlot = slots[1]
	state.Placed[targetSlot] = { CharId = result.Id, Mutation = mutation }
	state.Owned[result.Id] = true
	return true, "fused", { CharId = result.Id, Mutation = mutation, Slot = targetSlot, Name = result.Name }
end

-- Missions: progress is counted where the action happens (buy, collect,
-- steal, gear, rebirth). Claiming pays the reward once.
function Economy.MissionDone(state, mission)
	local progress = state.Missions[mission.Key] or 0
	return progress >= mission.Goal
end

function Economy.MissionSnapshot(player)
	local state = Economy.Get(player)
	if state == nil then
		return {}
	end
	local list = {}
	for _, mission in ipairs(BrainrotData.MISSIONS) do
		table.insert(list, {
			Id = mission.Id,
			Text = mission.Text,
			Reward = mission.Reward,
			Progress = state.Missions[mission.Key] or 0,
			Goal = mission.Goal,
			Done = Economy.MissionDone(state, mission),
			Claimed = state.Missions.Claimed[mission.Id] == true,
		})
	end
	return list
end

function Economy.ClaimMission(player, missionId)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local mission = nil
	for _, m in ipairs(BrainrotData.MISSIONS) do
		if m.Id == missionId then
			mission = m
		end
	end
	if mission == nil then
		return false, "unknown mission"
	end
	if state.Missions.Claimed[missionId] == true then
		return false, "sudah diklaim"
	end
	if not Economy.MissionDone(state, mission) then
		return false, "misi belum selesai"
	end
	state.Missions.Claimed[missionId] = true
	state.Cash = state.Cash + mission.Reward
	return true, "claimed"
end

function Economy.NoteStolen(player)
	local state = Economy.Get(player)
	if state ~= nil then
		state.Missions.Stolen = state.Missions.Stolen + 1
	end
end

function Economy.NoteGearBought(player)
	local state = Economy.Get(player)
	if state ~= nil then
		state.Missions.GearBought = state.Missions.GearBought + 1
	end
end

function Economy.NoteRebirth(player)
	local state = Economy.Get(player)
	if state ~= nil then
		state.Missions.Rebirths = state.Missions.Rebirths + 1
	end
end

function Economy.RebirthRequirement(level)
	for _, req in ipairs(BrainrotData.REBIRTHS) do
		if req.Level == level then
			return req
		end
	end
	return nil
end

function Economy.CanRebirth(player)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local nextLevel = state.Rebirth + 1
	local req = Economy.RebirthRequirement(nextLevel)
	if req == nil then
		return false, "max rebirth reached"
	end
	if state.Cash < req.Cost then
		return false, "need cash"
	end
	for _, charId in ipairs(req.Need) do
		if not Economy.HasCharacter(player, charId) then
			return false, "need named character"
		end
	end
	return true, "ready"
end

function Economy.DoRebirth(player)
	local ok, why = Economy.CanRebirth(player)
	if not ok then
		return false, why
	end
	local state = Economy.Get(player)
	local nextLevel = state.Rebirth + 1
	local req = Economy.RebirthRequirement(nextLevel)
	state.Cash = state.Cash - req.Cost
	state.Placed = {}
	state.Pending = 0
	state.Carrying = nil
	state.Rebirth = nextLevel
	Economy.NoteRebirth(player)
	return true, "rebirthed"
end

function Economy.IsLocked(player)
	local state = Economy.Get(player)
	if state == nil then
		return false
	end
	return os.time() < state.LockUntil
end

function Economy.LockTimeLeft(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	return math.max(0, state.LockUntil - os.time())
end

function Economy.LockBase(player)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if os.time() < state.LockCooldownUntil then
		return false, "lock cooling down"
	end
	if state.Cash < Config.LockCost then
		return false, "not enough cash"
	end
	state.Cash = state.Cash - Config.LockCost
	local duration = Config.LockDuration + state.Rebirth * Config.LockBonusPerRebirth
	state.LockUntil = os.time() + duration
	state.LockCooldownUntil = state.LockUntil + Config.LockCooldown
	if state.TutorialStep < 3 then
		state.TutorialStep = 3
	end
	return true, "locked"
end

function Economy.MarkBought(player)
	local state = Economy.Get(player)
	if state ~= nil and state.TutorialStep < 1 then
		state.TutorialStep = 1
	end
end

return Economy
