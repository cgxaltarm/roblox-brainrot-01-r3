-- init.server: entrypoint. Validates the catalogue, builds the world,
-- creates the remotes, wires every click and remote, and runs the
-- one-second game loop: income piles up, events tick, the pity clock
-- counts down, locks show their laser, loose drops expire, the Top-5
-- leaderboard refreshes, and every player gets a fresh state snapshot
-- for the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Economy = require(ServerScriptService.Server.Economy)
local Conveyor = require(ServerScriptService.Server.Conveyor)
local ConveyorDisplay = require(ServerScriptService.Server.ConveyorDisplay)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)
local World = require(ServerScriptService.Server.World)
local Base = require(ServerScriptService.Server.Base)
local Steal = require(ServerScriptService.Server.Steal)
local Events = require(ServerScriptService.Server.Events)
local Gear = require(ServerScriptService.Server.Gear)
local Save = require(ServerScriptService.Server.Save)

-- Catalogue sanity: rarity weights must sum to 100.
local weightTotal = 0
for _, rarity in ipairs(BrainrotData.RARITIES) do
	weightTotal = weightTotal + rarity.Weight
end
assert(weightTotal == 100, "rarity weights must sum to 100")
assert(#BrainrotData.CHARACTERS == 30, "the cast must hold 30 characters")

World.BuildWorld()
Conveyor.Fill()
ConveyorDisplay.Refresh()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes == nil then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local StateSync = makeRemote("StateSync")
local BuyBrainrot = makeRemote("BuyBrainrot")
local SellBrainrot = makeRemote("SellBrainrot")
local LockBase = makeRemote("LockBase")
local DoRebirth = makeRemote("DoRebirth")
local CollectCash = makeRemote("CollectCash")
local BuyGear = makeRemote("BuyGear")
local BuyUpgrade = makeRemote("BuyUpgrade")
local UseSlap = makeRemote("UseSlap")
local StealAttempt = makeRemote("StealAttempt")
local TakeLoose = makeRemote("TakeLoose")
local Fuse = makeRemote("Fuse")
local ClaimMission = makeRemote("ClaimMission")
local OpenGearShop = makeRemote("OpenGearShop")
local OpenFuse = makeRemote("OpenFuse")
local PlaySound = makeRemote("PlaySound")
local Toast = makeRemote("Toast")

-- Top 5 players by income per second, recomputed every few seconds.
local leaderboardCache = {}
local function computeLeaderboard()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local income = Economy.GetIncomePerSec(player, Events.IncomeMult())
		table.insert(rows, { Name = player.DisplayName, Income = income })
	end
	table.sort(rows, function(a, b)
		return a.Income > b.Income
	end)
	local top = {}
	for i = 1, math.min(Config.LeaderboardSize, #rows) do
		top[i] = rows[i]
	end
	return top
end

local function buildSnapshot(player)
	local state = Economy.Get(player)
	if state == nil then
		return {}
	end
	local placed = {}
	for slot, item in pairs(state.Placed) do
		table.insert(placed, { Slot = slot, CharId = item.CharId, Mutation = item.Mutation })
	end
	local owned = {}
	for charId, _ in pairs(state.Owned) do
		table.insert(owned, charId)
	end
	local carrying = nil
	if state.Carrying ~= nil then
		carrying = { CharId = state.Carrying.CharId, Mutation = state.Carrying.Mutation }
	end
	local canRebirth, _ = Economy.CanRebirth(player)
	local nextReq = Economy.RebirthRequirement(state.Rebirth + 1)
	local need = {}
	if nextReq ~= nil then
		need = nextReq.Need
	end
	return {
		Cash = state.Cash,
		Pending = state.Pending,
		Income = Economy.GetIncomePerSec(player, Events.IncomeMult()),
		Rebirth = state.Rebirth,
		Slots = Economy.SlotCount(player),
		Placed = placed,
		Owned = owned,
		Carrying = carrying,
		Conveyor = Conveyor.GetSlots(),
		PityEpic = Conveyor.NextEpicIn,
		PityLegendary = Conveyor.NextLegendaryIn,
		Event = Events.Current,
		EventTimeLeft = Events.TimeLeft(),
		LockLeft = Economy.LockTimeLeft(player),
		LockCooldown = math.max(0, state.LockCooldownUntil - os.time()),
		TutorialStep = state.TutorialStep,
		GearSlap = state.Gear.Slap,
		GearTraps = state.Gear.Traps,
		Upgrades = { Luck = state.Upgrades.Luck, Income = state.Upgrades.Income, Speed = state.Upgrades.Speed },
		CanRebirth = canRebirth,
		RebirthNeed = need,
		RebirthCost = nextReq ~= nil and nextReq.Cost or 0,
		Missions = Economy.MissionSnapshot(player),
		Leaderboard = leaderboardCache,
	}
end

local function syncPlayer(player)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	StateSync:FireClient(player, buildSnapshot(player))
end

local function syncAll()
	for _, player in ipairs(Players:GetPlayers()) do
		syncPlayer(player)
	end
end

local function showToast(player, text)
	Toast:FireClient(player, text)
end

local function doBuy(player, index)
	local slots = Conveyor.GetSlots()
	if index < 1 or index > #slots then
		return
	end
	local slot = slots[index]
	local ok, why = Economy.BuyBrainrot(player, slot)
	if not ok then
		showToast(player, "Cannot buy: " .. why)
		return
	end
	Conveyor.TakeSlot(index)
	ConveyorDisplay.Refresh()
	Steal.AttachCarried(player, slot.CharId, slot.Mutation)
	Economy.MarkBought(player)
	PlaySound:FireClient(player, "buy")
	showToast(player, "Bought " .. BrainrotData.FindCharacter(slot.CharId).Name .. " - carry it to your base!")
	syncAll()
end

BuyBrainrot.OnServerEvent:Connect(function(player, index)
	doBuy(player, index)
end)

SellBrainrot.OnServerEvent:Connect(function(player, slot)
	local ok, why = Economy.SellBrainrot(player, slot)
	if ok then
		Base.RemoveModel(player, slot)
		showToast(player, "Sold! You got a 50% refund.")
		syncPlayer(player)
	else
		showToast(player, "Cannot sell: " .. why)
	end
end)

LockBase.OnServerEvent:Connect(function(player)
	local ok, why = Economy.LockBase(player)
	if ok then
		showToast(player, "Base locked! Thieves cannot steal.")
	else
		showToast(player, "Cannot lock: " .. why)
	end
	syncPlayer(player)
end)

DoRebirth.OnServerEvent:Connect(function(player)
	local ok, why = Economy.DoRebirth(player)
	if ok then
		Base.ClearModels(player)
		PlaySound:FireClient(player, "rebirth")
		showToast(player, "REBIRTH! Income +50% forever, +1 base slot.")
	else
		showToast(player, "Cannot rebirth: " .. why)
	end
	syncAll()
end)

CollectCash.OnServerEvent:Connect(function(player)
	local amount = Economy.CollectCash(player)
	if amount > 0 then
		showToast(player, "Collected " .. Format.Money(amount) .. "!")
	end
	syncPlayer(player)
end)

BuyGear.OnServerEvent:Connect(function(player, gearId)
	local ok, why = Gear.BuyGear(player, gearId)
	if ok then
		showToast(player, "Gear bought: " .. gearId)
	else
		showToast(player, "Cannot buy gear: " .. why)
	end
	syncPlayer(player)
end)

BuyUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local ok, why = Economy.BuyUpgrade(player, upgradeId)
	if ok then
		local state = Economy.Get(player)
		local level = state ~= nil and state.Upgrades[upgradeId] or 0
		showToast(player, upgradeId .. " naik ke Lv" .. tostring(level) .. "!")
	else
		showToast(player, why)
	end
	syncPlayer(player)
end)

UseSlap.OnServerEvent:Connect(function(player)
	local victim = Gear.Slap(player)
	if victim ~= nil then
		-- The stolen brainrot drops to the ground, free for anyone.
		Steal.DropCarried(victim, false)
		PlaySound:FireClient(victim, "alarm")
		showToast(victim, "You were slapped! You dropped the brainrot.")
		showToast(player, "Slap landed! The thief dropped everything.")
	end
end)

StealAttempt.OnServerEvent:Connect(function(player, targetUserId, slot)
	local ok, why = Steal.TrySteal(player, targetUserId, slot)
	if ok then
		PlaySound:FireClient(player, "steal")
		local target = Players:GetPlayerByUserId(targetUserId)
		if target ~= nil then
			PlaySound:FireClient(target, "alarm")
			showToast(target, "YOUR BASE IS BEING ROBBED!")
		end
		showToast(player, "Stolen! Run home before someone tags you!")
	else
		showToast(player, "Cannot steal: " .. why)
	end
	syncAll()
end)

TakeLoose.OnServerEvent:Connect(function(player, looseId)
	local ok, why = Steal.TakeLoose(player, looseId)
	if ok then
		showToast(player, "Picked it up! Run it to your base!")
	else
		showToast(player, "Cannot pick up: " .. why)
	end
	syncAll()
end)

Fuse.OnServerEvent:Connect(function(player, slots)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	-- Snapshot the three slots first: Economy.Fuse clears them, and
	-- the models must be removed before the result is placed.
	local removed = {}
	if type(slots) == "table" then
		for _, slot in ipairs(slots) do
			table.insert(removed, slot)
		end
	end
	local ok, why, result = Economy.Fuse(player, slots)
	if ok and result ~= nil then
		for _, slot in ipairs(removed) do
			if slot ~= result.Slot then
				Base.RemoveModel(player, slot)
			end
		end
		Base.PlaceModel(player, result.Slot)
		PlaySound:FireClient(player, "buy")
		showToast(player, "FUSED! Got " .. result.Name .. "!")
	else
		showToast(player, "Cannot fuse: " .. tostring(why))
	end
	syncAll()
end)

ClaimMission.OnServerEvent:Connect(function(player, missionId)
	local ok, why = Economy.ClaimMission(player, missionId)
	if ok then
		local reward = 0
		for _, m in ipairs(BrainrotData.MISSIONS) do
			if m.Id == missionId then
				reward = m.Reward
			end
		end
		PlaySound:FireClient(player, "buy")
		showToast(player, "Mission complete! +" .. Format.Money(reward))
	else
		showToast(player, "Cannot claim: " .. tostring(why))
	end
	syncPlayer(player)
end)

Steal.OnSteal = function(thief, victim)
	showToast(victim, "YOUR BASE IS BEING ROBBED by " .. thief.DisplayName .. "!")
end

-- Pad clicks place a carried brainrot; collect pad clicks take the pile.
for _, base in ipairs(World.Bases) do
	for slot, pad in ipairs(base.Pads) do
		local click = pad:FindFirstChild("PadClick")
		if click ~= nil then
			click.MouseClick:Connect(function(player)
				local state = Economy.Get(player)
				if state == nil or state.BaseIndex == 0 then
					return
				end
				local myBase = World.Bases[state.BaseIndex]
				if myBase ~= base then
					return
				end
				if state.Carrying == nil then
					return
				end
				local ok, why = Economy.PlaceCarried(player, slot)
				if ok then
					Base.PlaceModel(player, slot)
					Steal.ClearCarriedModel(player)
					showToast(player, "Placed! It earns money every second.")
					syncPlayer(player)
				else
					showToast(player, "Cannot place: " .. why)
				end
			end)
		end
	end
	local collectClick = base.CollectPad:FindFirstChild("CollectClick")
	if collectClick ~= nil then
		collectClick.MouseClick:Connect(function(player)
			local state = Economy.Get(player)
			if state == nil then
				return
			end
			local myBase = World.Bases[state.BaseIndex]
			if myBase ~= base then
				return
			end
			local amount = Economy.CollectCash(player)
			if amount > 0 then
				showToast(player, "Collected " .. Format.Money(amount) .. "!")
			end
			syncPlayer(player)
		end)
	end
end

local gearStall = workspace:FindFirstChild("GearStall")
if gearStall ~= nil then
	local sign = gearStall:FindFirstChild("Sign")
	if sign ~= nil then
		local click = sign:FindFirstChild("GearClick")
		if click ~= nil then
			click.MouseClick:Connect(function(player)
				OpenGearShop:FireClient(player)
			end)
		end
	end
end

local fuseMachine = workspace:FindFirstChild("FuseMachine")
if fuseMachine ~= nil then
	local sign = fuseMachine:FindFirstChild("Sign")
	if sign ~= nil then
		local click = sign:FindFirstChild("FuseClick")
		if click ~= nil then
			click.MouseClick:Connect(function(player)
				OpenFuse:FireClient(player)
			end)
		end
	end
end

Events.OnStart = function(kind)
	if kind == "RushHour" then
		Steal.SpawnThief()
		syncAll()
	elseif kind == "Festival" then
		syncAll()
	end
end

local function onPlayerAdded(player)
	Save.LoadPlayer(player)
	Base.AssignBase(player)
	Base.RefreshModels(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		local state = Economy.Get(player)
		if state == nil then
			return
		end
		-- Dying while carrying used to soft-lock the player (the
		-- back model was gone but Carrying stayed set forever).
		-- Stolen goods go home; a conveyor purchase is lost.
		if state.Carrying ~= nil then
			Steal.DropCarried(player, true)
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid == nil then
			return
		end
		if state.Gear.CoilUntil > os.time() then
			humanoid.WalkSpeed = Economy.BaseWalkSpeed(player) * Config.CoilSpeedMult
		else
			humanoid.WalkSpeed = Economy.BaseWalkSpeed(player)
		end
	end)
	syncPlayer(player)
end

local function onPlayerRemoving(player)
	Save.SavePlayer(player)
	Base.FreeBase(player)
	Steal.DropCarried(player, true)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Conveyor rolls a new brainrot on its interval.
task.spawn(function()
	while true do
		task.wait(Events.ConveyorInterval())
		Conveyor.SpawnNext()
		ConveyorDisplay.Refresh()
		syncAll()
	end
end)

-- Leaderboard refreshes every few seconds, from live income data.
task.spawn(function()
	while true do
		task.wait(Config.LeaderboardInterval)
		leaderboardCache = computeLeaderboard()
		local lines = {}
		for i, row in ipairs(leaderboardCache) do
			lines[i] = tostring(i) .. ". " .. row.Name .. "  " .. Format.Money(row.Income) .. "/s"
		end
		World.SetLeaderboard(lines)
		syncAll()
	end
end)

-- One-second loop: income piles up, events tick, pity counts down.
task.spawn(function()
	local saveTimer = 0
	while true do
		task.wait(1)
		Events.Tick()
		Conveyor.UpdatePity()
		Economy.TickIncome(Events.IncomeMult())
		World.SetPityText("Legendary guaranteed in " .. Format.Seconds(Conveyor.NextLegendaryIn) .. "  |  Epic in " .. Format.Seconds(Conveyor.NextEpicIn))
		Steal.CheckTags()
		Steal.CheckLoose()
		Gear.CheckTraps(Steal)
		for _, player in ipairs(Players:GetPlayers()) do
			local state = Economy.Get(player)
			if state ~= nil then
				Base.UpdateCollectPad(player)
				if Economy.IsLocked(player) then
					Base.SetLaser(player, true, Economy.LockTimeLeft(player))
				else
					Base.SetLaser(player, false, 0)
				end
			end
		end
		saveTimer = saveTimer + 1
		if saveTimer >= Config.AutosaveSeconds then
			saveTimer = 0
			Save.SaveAll()
		end
		syncAll()
	end
end)

print("Brainrot Night Market ready: 30 characters, 4 kiosk bases, conveyor live, fuse machine live.")
