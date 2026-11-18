-- Gear: the Coins Shop tools. Cash buys a Slap tool, a Speed Coil
-- boost, or a Trap that freezes a thief who steps on it. Gear gives
-- money a second purpose and stealing a real counterplay.
-- r3: Slap only knocks down carriers of STOLEN goods (a player
-- carrying a fresh conveyor purchase is safe on the way home).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Economy = require(ServerScriptService.Server.Economy)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)

local Gear = {}
Gear.Traps = {}

-- Walk speed after a freeze/slap ends: coil and carry multipliers
-- still apply on top of the upgraded base speed.
local function restoreSpeed(player)
	local state = Economy.Get(player)
	if state == nil then
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Parent == nil then
		return
	end
	local speed = Economy.BaseWalkSpeed(player)
	if state.Gear.CoilUntil > os.time() then
		speed = speed * Config.CoilSpeedMult
	elseif state.Carrying ~= nil then
		speed = speed * Config.CarrySpeedMult
	end
	humanoid.WalkSpeed = speed
end

function Gear.BuyGear(player, gearId)
	local state = Economy.Get(player)
	if state == nil then
		return false, "no state"
	end
	local def = nil
	for _, g in ipairs(BrainrotData.GEAR) do
		if g.Id == gearId then
			def = g
		end
	end
	if def == nil then
		return false, "unknown gear"
	end
	if state.Cash < def.Cost then
		return false, "not enough cash"
	end
	state.Cash = state.Cash - def.Cost
	if gearId == "slap" then
		state.Gear.Slap = true
		Gear.GiveSlapTool(player)
	elseif gearId == "coil" then
		state.Gear.CoilUntil = os.time() + Config.CoilDuration
		local character = player.Character
		if character ~= nil then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				humanoid.WalkSpeed = Economy.BaseWalkSpeed(player) * Config.CoilSpeedMult
			end
		end
	elseif gearId == "trap" then
		if state.Gear.Traps >= Config.TrapMaxActive then
			state.Cash = state.Cash + def.Cost
			return false, "too many traps"
		end
		state.Gear.Traps = state.Gear.Traps + 1
		Gear.PlaceTrap(player)
	end
	Economy.NoteGearBought(player)
	return true, "bought"
end

function Gear.GiveSlapTool(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack == nil then
		return
	end
	if backpack:FindFirstChild("Slap") ~= nil then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 3, 1.4)
	handle.Color = Color3.new(0.95, 0.75, 0.35)
	handle.Parent = tool
	tool.Parent = backpack
end

function Gear.PlaceTrap(player)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local trap = Instance.new("Part")
	trap.Name = "Trap"
	trap.Size = Vector3.new(4, 0.6, 4)
	trap.Position = root.Position + Vector3.new(0, -2, 0)
	trap.Color = Color3.new(1, 0.2, 0.2)
	trap.Material = Enum.Material.Neon
	trap.Anchored = true
	trap.Parent = workspace
	table.insert(Gear.Traps, { Part = trap, Owner = player.UserId })
end

function Gear.Slap(player)
	local state = Economy.Get(player)
	if state == nil or not state.Gear.Slap then
		return nil
	end
	local character = player.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return nil
	end
	for _, other in ipairs(game.Players:GetPlayers()) do
		if other ~= player then
			local otherState = Economy.Get(other)
			-- Only a thief carrying stolen goods can be slapped down.
			if otherState ~= nil and otherState.Carrying ~= nil and not otherState.Carrying.FromConveyor then
				local otherChar = other.Character
				if otherChar ~= nil then
					local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
					if otherRoot ~= nil and (otherRoot.Position - root.Position).Magnitude < 9 then
						local humanoid = otherChar:FindFirstChildOfClass("Humanoid")
						if humanoid ~= nil then
							humanoid.WalkSpeed = 0
							task.spawn(function()
								task.wait(2)
								restoreSpeed(other)
							end)
						end
						return other
					end
				end
			end
		end
	end
	return nil
end

function Gear.CheckTraps(Steal)
	for i = #Gear.Traps, 1, -1 do
		local trap = Gear.Traps[i]
		for _, player in ipairs(game.Players:GetPlayers()) do
			local state = Economy.Get(player)
			if state ~= nil and state.Carrying ~= nil and player.UserId ~= trap.Owner then
				local character = player.Character
				if character ~= nil then
					local root = character:FindFirstChild("HumanoidRootPart")
					if root ~= nil and (root.Position - trap.Part.Position).Magnitude < 4 then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid ~= nil then
							humanoid.WalkSpeed = 0
							task.spawn(function()
								task.wait(Config.TrapFreezeSeconds)
								restoreSpeed(player)
							end)
						end
						trap.Part:Destroy()
						table.remove(Gear.Traps, i)
						break
					end
				end
			end
		end
	end
end

return Gear
