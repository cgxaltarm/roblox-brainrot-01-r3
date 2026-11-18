-- Game.client: entrypoint. Builds the HUD and the shop, listens for
-- state snapshots from the server, and wires the Slap key. The client
-- only renders: all money, ownership and steal outcomes live on the
-- server, and every button here fires a RemoteEvent the server checks.
-- Prompts: BuyPrompt (hold E on a conveyor brainrot) buys it,
-- StealPrompt (hold E on a rival's placed brainrot) steals it,
-- LoosePrompt (hold E on a dropped brainrot) picks it up.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")

local Hud = require(PlayerScripts.Client.Hud)
local Shop = require(PlayerScripts.Client.Shop)
local Effects = require(PlayerScripts.Client.Effects)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
for _, name in ipairs({"StateSync", "BuyBrainrot", "SellBrainrot", "LockBase", "DoRebirth", "CollectCash", "BuyGear", "BuyUpgrade", "UseSlap", "StealAttempt", "TakeLoose", "Fuse", "ClaimMission", "OpenGearShop", "OpenFuse", "PlaySound", "Toast"}) do
	remotes:WaitForChild(name)
end

-- Every ProximityPrompt in the world reports its kind by name.
-- BuyPrompt carries SlotIndex, StealPrompt carries OwnerId + Slot,
-- LoosePrompt carries LooseId. Prompts are rebuilt whenever a slot
-- is taken or a brainrot drops, so hook new ones as they appear.
local function hookPrompt(prompt)
	if prompt.Name == "BuyPrompt" then
		prompt.Triggered:Connect(function()
			local slotIndex = prompt:GetAttribute("SlotIndex")
			if slotIndex ~= nil then
				remotes.BuyBrainrot:FireServer(slotIndex)
			end
		end)
	elseif prompt.Name == "StealPrompt" then
		prompt.Triggered:Connect(function()
			local ownerId = prompt:GetAttribute("OwnerId")
			local slot = prompt:GetAttribute("Slot")
			if ownerId ~= nil and slot ~= nil then
				remotes.StealAttempt:FireServer(ownerId, slot)
			end
		end)
	elseif prompt.Name == "LoosePrompt" then
		prompt.Triggered:Connect(function()
			local looseId = prompt:GetAttribute("LooseId")
			if looseId ~= nil then
				remotes.TakeLoose:FireServer(looseId)
			end
		end)
	end
end
for _, descendant in ipairs(Workspace:GetDescendants()) do
	if descendant:IsA("ProximityPrompt") then
		hookPrompt(descendant)
	end
end
Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") then
		hookPrompt(descendant)
	end
end)
local lastCarrying = false

Hud.Build(remotes, {
	ToggleMenu = function()
		Shop.ToggleMenu()
	end,
})
Shop.Build(remotes)

remotes.StateSync.OnClientEvent:Connect(function(snapshot)
	Hud.Render(snapshot)
	Shop.Render(snapshot)
	if snapshot.Carrying ~= nil and not lastCarrying then
		Effects.PlayPurchase(Hud)
	end
	lastCarrying = snapshot.Carrying ~= nil
end)

remotes.Toast.OnClientEvent:Connect(function(text)
	Hud.ShowToast(text)
end)

remotes.OpenGearShop.OnClientEvent:Connect(function()
	Shop.OpenMenuTab("gear")
end)

remotes.OpenFuse.OnClientEvent:Connect(function()
	Shop.OpenMenuTab("fuse")
end)

remotes.PlaySound.OnClientEvent:Connect(function(kind)
	Effects.PlaySound(kind)
end)

local function slapAction(_, state, _)
	if state == Enum.UserInputState.Begin then
		remotes.UseSlap:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("SlapThief", slapAction, false, Enum.KeyCode.Q)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		remotes.UseSlap:FireServer()
	end
end)

print("Brainrot Night Market client ready.")
