-- ConveyorDisplay: the five brainrot models standing on the red
-- carpet, spaced wide apart so their three-line labels never overlap.
-- Hold E on a model to buy it (ProximityPrompt); the display rebuilds
-- whenever a slot is taken or a new brainrot rolls in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Conveyor = require(ServerScriptService.Server.Conveyor)
local CharacterModels = require(ServerScriptService.Server.CharacterModels)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local ConveyorDisplay = {}
ConveyorDisplay.Models = {}
-- Set by init.server: called when a player clicks a conveyor model
-- (ClickDetector). Same buy path as the hold-E prompt, so buying
-- works even if the prompt UI is ever hidden behind the HUD.
ConveyorDisplay.OnBuyClick = nil

function ConveyorDisplay.SlotPosition(index)
	local x = (index - 3) * Config.ConveyorSpacing
	return Vector3.new(x, 1, Config.ConveyorZ)
end

function ConveyorDisplay.Refresh()
	for _, model in pairs(ConveyorDisplay.Models) do
		model:Destroy()
	end
	ConveyorDisplay.Models = {}
	local slots = Conveyor.GetSlots()
	for i, slot in ipairs(slots) do
		local def = BrainrotData.FindCharacter(slot.CharId)
		if def ~= nil then
			local model = CharacterModels.BuildModel(def, slot.Mutation, ConveyorDisplay.SlotPosition(i))
			CharacterModels.SetLabelPrice(model, Format.Money(slot.Cost))
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			model.Parent = workspace
			-- Hold-E prompt. UIOffset lifts the bubble above the
			-- conveyor cards at the bottom of the screen (play-test
			-- 19 Nov: the bubble sat exactly behind them), and the
			-- wider range survives the 10s set rotation.
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuyPrompt"
			prompt.ActionText = "BELI"
			prompt.ObjectText = def.Name .. " - " .. Format.Money(slot.Cost)
			prompt.HoldDuration = 1
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.UIOffset = Vector2.new(0, -160)
			prompt:SetAttribute("SlotIndex", i)
			prompt.Parent = model.PrimaryPart
			-- Click fallback: clicking the model buys it through the
			-- same server check as the prompt. The detector dies with
			-- the model on the next refresh, so no stale handlers.
			local click = Instance.new("ClickDetector")
			click.Name = "BuyClick"
			click.MaxActivationDistance = 20
			click.Parent = model.PrimaryPart
			local slotIndex = i
			click.MouseClick:Connect(function(player)
				if ConveyorDisplay.OnBuyClick ~= nil then
					ConveyorDisplay.OnBuyClick(player, slotIndex)
				end
			end)
			ConveyorDisplay.Models[i] = model
		end
	end
end

return ConveyorDisplay
