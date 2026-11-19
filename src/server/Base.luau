-- round 4
-- Base: assign a kiosk to each player, place and remove brainrots on
-- its pads, show the lock laser and timer, and keep the collect pad
-- and its coin pile in step with the pending pile.
-- r3: every placed brainrot carries a CURI ProximityPrompt so any other
-- player can try to steal it (the server still checks the lock); the
-- laser is solid while locked, so a locked base cannot be entered.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Economy)
local World = require(ServerScriptService.Server.World)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Format = require(ReplicatedStorage.Shared.Format)

local Base = {}
Base.Models = {}

function Base.AssignBase(player)
	local state = Economy.Get(player)
	if state == nil then
		return 0
	end
	for i, base in ipairs(World.Bases) do
		if base.OwnerId == 0 then
			base.OwnerId = player.UserId
			state.BaseIndex = i
			local gui = base.Board:FindFirstChild("OwnerLabel")
			if gui ~= nil then
				local label = gui:FindFirstChild("Text")
				if label ~= nil then
					-- Name only (play-test 19 Nov: "Name - YOUR BASE"
					-- was wide enough to pile onto the next base's
					-- board label). Your own board is lime, others white.
					label.Text = player.DisplayName
					label.TextColor3 = Color3.new(0.64, 0.90, 0.21)
				end
			end
			return i
		end
	end
	state.BaseIndex = 1
	return 1
end

function Base.GetBase(player)
	local state = Economy.Get(player)
	if state == nil then
		return nil
	end
	return World.Bases[state.BaseIndex]
end

function Base.PadPosition(player, slot)
	local base = Base.GetBase(player)
	if base == nil then
		return Vector3.new(0, 3, 0)
	end
	local pad = base.Pads[slot]
	if pad == nil then
		return Vector3.new(0, 3, 0)
	end
	return pad.Position + Vector3.new(0, 0.25, 0)
end

function Base.PlaceModel(player, slot)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	local placed = state.Placed[slot]
	if placed == nil then
		return
	end
	local def = BrainrotData.FindCharacter(placed.CharId)
	if def == nil then
		return
	end
	Base.RemoveModel(player, slot)
	local pos = Base.PadPosition(player, slot)
	local base = Base.GetBase(player)
	if base ~= nil and base.Pads[slot] ~= nil then
		base.Pads[slot].Color = Color3.new(0.35, 0.38, 0.42)
		base.Pads[slot].Material = Enum.Material.SmoothPlastic
	end
	local model = CharacterModels.BuildModel(def, placed.Mutation, pos)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	model.Parent = workspace
	-- Steal prompt: hold E on a rival's brainrot to grab it. The
	-- server validates the lock, the cooldown and the slot, so the
	-- prompt on your own brainrots just gets a "base kamu" toast.
	-- UIOffset lifts the bubble above the conveyor cards, same as
	-- the buy prompt (play-test 19 Nov).
	local promptAnchor = Instance.new("Attachment")
	promptAnchor.Name = "StealPromptAnchor"
	promptAnchor.Position = Vector3.new(0, 3, 0)
	promptAnchor.Parent = model.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "CURI"
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerId", player.UserId)
	prompt:SetAttribute("Slot", slot)
	prompt.Parent = promptAnchor
	Base.Models[player.UserId .. "_" .. tostring(slot)] = model
end

function Base.RemoveModel(player, slot)
	local key = player.UserId .. "_" .. tostring(slot)
	local model = Base.Models[key]
	if model ~= nil then
		model:Destroy()
		Base.Models[key] = nil
	end
end

function Base.RefreshModels(player)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	for slot, _ in pairs(state.Placed) do
		Base.PlaceModel(player, slot)
	end
end

function Base.ClearModels(player)
	for slot = 1, 12 do
		Base.RemoveModel(player, slot)
	end
end

function Base.SetLaser(player, visible, secondsLeft)
	local base = Base.GetBase(player)
	if base == nil then
		return
	end
	base.Laser.Transparency = visible and 0.4 or 1
	-- Solid while locked: the laser IS the door. Transparency hides
	-- it, CanCollide blocks entry - never use .Visible on a Part.
	base.Laser.CanCollide = visible
	local gui = base.Board:FindFirstChild("OwnerLabel")
	if gui ~= nil then
		local label = gui:FindFirstChild("Text")
		if label ~= nil then
			if visible then
				label.Text = "LOCKED  " .. Format.Seconds(secondsLeft)
			else
				label.Text = player.DisplayName
			end
		end
	end
end

function Base.UpdateCollectPad(player)
	local state = Economy.Get(player)
	local base = Base.GetBase(player)
	if state == nil or base == nil then
		return
	end
	-- Keep empty pads bright, occupied pads subdued, and only show
	-- the click hint on this player's empty unlocked slots while carrying.
	local slots = Economy.SlotCount(player)
	for slot, pad in ipairs(base.Pads) do
		local occupied = state.Placed[slot] ~= nil
		local unlocked = slot <= slots
		if occupied then
			pad.Color = Color3.new(0.35, 0.38, 0.42)
			pad.Material = Enum.Material.SmoothPlastic
		elseif unlocked then
			pad.Color = Color3.new(0.15, 0.75, 1.0)
			pad.Material = Enum.Material.Neon
		else
			pad.Color = Color3.new(0.25, 0.25, 0.3)
			pad.Material = Enum.Material.SmoothPlastic
		end
		local hint = pad:FindFirstChild("PadHint")
		if hint ~= nil then
			hint.Enabled = state.Carrying ~= nil and unlocked and not occupied
		end
	end
	-- The green collect pad and coin pile show pending income.
	local shown = 0
	if state.Pending > 0 then
		shown = math.min(8, 1 + math.floor(state.Pending / 500))
	end
	for i, coin in ipairs(base.Coins) do
		coin.Transparency = (i <= shown) and 0 or 1
	end
end

function Base.FreeBase(player)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	local base = World.Bases[state.BaseIndex]
	if base ~= nil and base.OwnerId == player.UserId then
		base.OwnerId = 0
	end
	Base.ClearModels(player)
end

return Base
