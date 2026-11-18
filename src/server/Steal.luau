-- Steal: one player grabs a brainrot from another player's unlocked
-- base, carries it home slowly, and drops it when anyone tags them or
-- slaps them. A dropped brainrot FALLS TO THE GROUND as a loose item
-- anyone can pick up (hold E on it) - it only returns to its owner's
-- base if nobody grabs it within 60 seconds, or if the carrier leaves.
-- During Rush Hour a thief NPC raids a random unlocked base.
-- A locked base cannot be stolen from: the laser is solid and
-- TrySteal refuses locked targets outright.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Economy)
local Base = require(ServerScriptService.Server.Base)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local Steal = {}
Steal.CarriedModels = {}
Steal.LooseItems = {}
Steal.NextLooseId = 1
Steal.Thief = nil
Steal.OnSteal = nil

-- Visual only: remove the model welded to the player's back and
-- restore walk speed. Never touches state.Carrying - AttachCarried
-- runs right after the server sets Carrying, and clearing it there
-- silently broke every steal and purchase (the r2 bug: buy/steal
-- looked fine on screen, but PlaceCarried then found nothing).
function Steal.ClearCarriedModel(player)
	local model = Steal.CarriedModels[player.UserId]
	if model ~= nil then
		model:Destroy()
		Steal.CarriedModels[player.UserId] = nil
	end
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.WalkSpeed = Economy.BaseWalkSpeed(player)
		end
	end
end

function Steal.AttachCarried(player, charId, mutation)
	Steal.ClearCarriedModel(player)
	local def = BrainrotData.FindCharacter(charId)
	if def == nil then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local model = CharacterModels.BuildModel(def, mutation, root.Position + Vector3.new(0, 4, 0))
	model.Parent = workspace
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = model.PrimaryPart
			weld.Part1 = part
			weld.Parent = model.PrimaryPart
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	Steal.CarriedModels[player.UserId] = model
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		humanoid.WalkSpeed = Economy.BaseWalkSpeed(player) * Config.CarrySpeedMult
	end
end

-- Drop what the player carries. returnHome = true sends a stolen
-- brainrot back to its owner's pad (carrier left / respawned);
-- returnHome = false drops it on the ground as a loose item anyone
-- can grab. Conveyor purchases never go home (OwnerId 0): they just
-- drop loose too, so a slap always costs the carrier something.
function Steal.DropCarried(player, returnHome)
	Steal.ClearCarriedModel(player)
	local state = Economy.Get(player)
	if state ~= nil and state.Carrying ~= nil then
		local carried = state.Carrying
		state.Carrying = nil
		if returnHome and carried.OwnerId > 0 then
			local owner = game.Players:GetPlayerByUserId(carried.OwnerId)
			if owner ~= nil then
				local ownerState = Economy.Get(owner)
				if ownerState ~= nil then
					local slot = carried.OwnerSlot
					if ownerState.Placed[slot] ~= nil then
						slot = Economy.FreeSlot(owner)
					end
					if slot ~= 0 then
						ownerState.Placed[slot] = {
							CharId = carried.CharId,
							Mutation = carried.Mutation,
						}
						Base.PlaceModel(owner, slot)
					end
					return
				end
			end
		end
		if not returnHome then
			Steal.DropLoose(player, carried)
		end
	end
end

-- Put the brainrot on the ground where the carrier stands, with an
-- AMBIL prompt. Whoever holds E on it carries it next.
function Steal.DropLoose(player, carried)
	local character = player.Character
	local dropPos = Vector3.new(0, 3, 0)
	if character ~= nil then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root ~= nil then
			dropPos = root.Position
		end
	end
	local def = BrainrotData.FindCharacter(carried.CharId)
	if def == nil then
		return
	end
	local model = CharacterModels.BuildModel(def, carried.Mutation, Vector3.new(dropPos.X, 1, dropPos.Z))
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	model.Parent = workspace
	local id = Steal.NextLooseId
	Steal.NextLooseId = Steal.NextLooseId + 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LoosePrompt"
	prompt.ActionText = "AMBIL"
	prompt.ObjectText = def.Name .. " (jatuh!)"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, -160)
	prompt:SetAttribute("LooseId", id)
	prompt.Parent = model.PrimaryPart
	Steal.LooseItems[id] = {
		Id = id,
		CharId = carried.CharId,
		Mutation = carried.Mutation,
		OwnerId = carried.OwnerId,
		OwnerSlot = carried.OwnerSlot,
		Model = model,
		ExpiresAt = os.time() + Config.LooseExpireSeconds,
	}
end

function Steal.TakeLoose(player, looseId)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying ~= nil then
		return false, "already carrying"
	end
	local item = Steal.LooseItems[looseId]
	if item == nil then
		return false, "already taken"
	end
	Steal.LooseItems[looseId] = nil
	if item.Model ~= nil then
		item.Model:Destroy()
	end
	state.Carrying = {
		CharId = item.CharId,
		Mutation = item.Mutation,
		FromConveyor = false,
		OwnerId = item.OwnerId,
		OwnerSlot = item.OwnerSlot,
	}
	Steal.AttachCarried(player, item.CharId, item.Mutation)
	return true, "picked up"
end

-- Unclaimed drops go back to their owner's pad after the timer.
function Steal.CheckLoose()
	local now = os.time()
	for id, item in pairs(Steal.LooseItems) do
		if now >= item.ExpiresAt then
			Steal.LooseItems[id] = nil
			if item.Model ~= nil then
				item.Model:Destroy()
			end
			if item.OwnerId > 0 then
				local owner = game.Players:GetPlayerByUserId(item.OwnerId)
				if owner ~= nil then
					local ownerState = Economy.Get(owner)
					if ownerState ~= nil then
						-- The old slot may be taken by now; fall back
						-- to any free slot, and drop the item entirely
						-- if the base is full.
						local slot = item.OwnerSlot
						if ownerState.Placed[slot] ~= nil then
							slot = Economy.FreeSlot(owner)
						end
						if slot ~= 0 then
							ownerState.Placed[slot] = {
								CharId = item.CharId,
								Mutation = item.Mutation,
							}
							Base.PlaceModel(owner, slot)
						end
					end
				end
			end
		end
	end
end

function Steal.TrySteal(player, targetUserId, slot)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	if state.Carrying ~= nil then
		return false, "already carrying"
	end
	if os.time() < state.StealCooldownUntil then
		return false, "steal cooling down"
	end
	if os.time() - state.JoinTime < Config.NewPlayerGrace then
		return false, "new player grace"
	end
	local target = game.Players:GetPlayerByUserId(targetUserId)
	if target == nil or target == player then
		return false, "bad target"
	end
	if Economy.IsLocked(target) then
		return false, "base locked"
	end
	local targetState = Economy.Get(target)
	if targetState == nil then
		return false, "no target state"
	end
	local placed = targetState.Placed[slot]
	if placed == nil then
		return false, "empty slot"
	end
	targetState.Placed[slot] = nil
	Base.RemoveModel(target, slot)
	state.Carrying = {
		CharId = placed.CharId,
		Mutation = placed.Mutation,
		FromConveyor = false,
		OwnerId = targetUserId,
		OwnerSlot = slot,
	}
	state.StealCooldownUntil = os.time() + Config.StealCooldown
	Economy.NoteStolen(player)
	Steal.AttachCarried(player, placed.CharId, placed.Mutation)
	if Steal.OnSteal ~= nil then
		Steal.OnSteal(player, target)
	end
	return true, "stolen"
end

-- A tag only drops STOLEN goods (conveyor purchases are safe to carry
-- home); the drop goes to the ground, not back to the owner.
function Steal.TagCarrier(tagger, carrier)
	local state = Economy.Get(carrier)
	if state == nil or state.Carrying == nil then
		return
	end
	if state.Carrying.FromConveyor then
		return
	end
	Steal.DropCarried(carrier, false)
end

function Steal.CheckTags()
	for _, carrier in ipairs(game.Players:GetPlayers()) do
		local state = Economy.Get(carrier)
		if state ~= nil and state.Carrying ~= nil and not state.Carrying.FromConveyor then
			local char = carrier.Character
			if char ~= nil then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root ~= nil then
					for _, other in ipairs(game.Players:GetPlayers()) do
						if other ~= carrier then
							local otherChar = other.Character
							if otherChar ~= nil then
								local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
								if otherRoot ~= nil and (otherRoot.Position - root.Position).Magnitude < 4 then
									Steal.TagCarrier(other, carrier)
									break
								end
							end
						end
					end
				end
			end
		end
	end
end

function Steal.SpawnThief()
	local players = game.Players:GetPlayers()
	local victims = {}
	for _, p in ipairs(players) do
		if not Economy.IsLocked(p) then
			local state = Economy.Get(p)
			if state ~= nil then
				for _, _ in pairs(state.Placed) do
					table.insert(victims, p)
					break
				end
			end
		end
	end
	if #victims == 0 then
		return
	end
	local victim = victims[math.random(1, #victims)]
	local state = Economy.Get(victim)
	local bestSlot = 0
	local bestIncome = -1
	for slot, placed in pairs(state.Placed) do
		local def = BrainrotData.FindCharacter(placed.CharId)
		if def ~= nil and def.Income > bestIncome then
			bestIncome = def.Income
			bestSlot = slot
		end
	end
	if bestSlot == 0 then
		return
	end
	local placed = state.Placed[bestSlot]
	state.Placed[bestSlot] = nil
	Base.RemoveModel(victim, bestSlot)
	local npc = Instance.new("Model")
	npc.Name = "Pencuri Keliling"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 3, 3)
	body.Color = Color3.new(0.15, 0.15, 0.15)
	body.Position = Vector3.new(0, 4, -44)
	body.Anchored = false
	body.Parent = npc
	npc.PrimaryPart = body
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = npc
	npc.Parent = workspace
	Steal.Thief = { Model = npc, CharId = placed.CharId, Mutation = placed.Mutation, Victim = victim, Slot = bestSlot }
	task.spawn(function()
		task.wait(1)
		humanoid:MoveTo(Vector3.new(0, 3, 44))
		task.wait(20)
		if Steal.Thief ~= nil and Steal.Thief.Model == npc then
			npc:Destroy()
			Steal.Thief = nil
		end
	end)
end

function Steal.ClearThief()
	if Steal.Thief ~= nil then
		Steal.Thief.Model:Destroy()
		Steal.Thief = nil
	end
end

return Steal
