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
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuyPrompt"
			prompt.ActionText = "BELI"
			prompt.ObjectText = def.Name .. " - " .. Format.Money(slot.Cost)
			prompt.HoldDuration = 1
			prompt.MaxActivationDistance = 10
			prompt:SetAttribute("SlotIndex", i)
			prompt.Parent = model.PrimaryPart
			ConveyorDisplay.Models[i] = model
		end
	end
end

return ConveyorDisplay
