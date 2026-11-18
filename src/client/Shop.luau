-- Shop: the conveyor cards, the gear shop, the rebirth panel with its
-- named-character requirements and checkmarks, the collection Index,
-- the mission panel and the Fuse Machine panel. Cards are dark with
-- bold white text, a rarity-coloured border and a gold price, so they
-- read when shrunk. Cards are display-only: buying happens by holding
-- E on the brainrot model itself (ProximityPrompt), like the real
-- Steal a Brainrot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local Shop = {}
Shop.Remotes = nil
Shop.ConveyorFrame = nil
Shop.GearPanel = nil
Shop.RebirthPanel = nil
Shop.IndexPanel = nil
Shop.BuffPanel = nil
Shop.MissionPanel = nil
Shop.FusePanel = nil
Shop.OpenPanel = ""
Shop.FuseSelected = {}

local DARK = Color3.new(0.06, 0.09, 0.16)
local GOLD = Color3.new(1, 0.85, 0.2)

local function makePanel(name, size, pos)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = pos
	panel.BackgroundColor3 = DARK
	panel.BorderColor3 = Color3.new(1, 1, 1)
	panel.BorderSizePixel = 2
	panel.Visible = false
	panel.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NightMarketHud")
	return panel
end

local function makeTitle(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 34)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

function Shop.Build(remotes)
	Shop.Remotes = remotes
	local gui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("NightMarketHud")
	local frame = Instance.new("Frame")
	frame.Name = "ConveyorFrame"
	frame.Size = UDim2.new(0, 760, 0, 120)
	frame.Position = UDim2.new(0.5, -380, 1, -140)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	Shop.ConveyorFrame = frame
	Shop.GearPanel = makePanel("GearPanel", UDim2.new(0, 420, 0, 260), UDim2.new(0.5, -210, 0.5, -130))
	Shop.RebirthPanel = makePanel("RebirthPanel", UDim2.new(0, 460, 0, 300), UDim2.new(0.5, -230, 0.5, -150))
	Shop.IndexPanel = makePanel("IndexPanel", UDim2.new(0, 560, 0, 460), UDim2.new(0.5, -280, 0.5, -230))
	Shop.BuffPanel = makePanel("BuffPanel", UDim2.new(0, 460, 0, 270), UDim2.new(0.5, -230, 0.5, -135))
	Shop.MissionPanel = makePanel("MissionPanel", UDim2.new(0, 480, 0, 340), UDim2.new(0.5, -240, 0.5, -170))
	Shop.FusePanel = makePanel("FusePanel", UDim2.new(0, 480, 0, 460), UDim2.new(0.5, -240, 0.5, -230))
end

function Shop.Toggle(panelName)
	if Shop.OpenPanel == panelName then
		Shop.OpenPanel = ""
	else
		Shop.OpenPanel = panelName
	end
	Shop.GearPanel.Visible = Shop.OpenPanel == "gear"
	Shop.RebirthPanel.Visible = Shop.OpenPanel == "rebirth"
	Shop.IndexPanel.Visible = Shop.OpenPanel == "index"
	Shop.BuffPanel.Visible = Shop.OpenPanel == "buff"
	Shop.MissionPanel.Visible = Shop.OpenPanel == "mission"
	Shop.FusePanel.Visible = Shop.OpenPanel == "fuse"
end

function Shop.ToggleGear()
	Shop.Toggle("gear")
end

function Shop.ToggleRebirth()
	Shop.Toggle("rebirth")
end

function Shop.ToggleIndex()
	Shop.Toggle("index")
end

function Shop.ToggleBuff()
	Shop.Toggle("buff")
end

function Shop.ToggleMission()
	Shop.Toggle("mission")
end

function Shop.ToggleFuse()
	Shop.Toggle("fuse")
end

function Shop.Render(snapshot)
	Shop.LastSnapshot = snapshot
	Shop.RenderConveyor(snapshot)
	if Shop.OpenPanel == "gear" then
		Shop.RenderGear(snapshot)
	elseif Shop.OpenPanel == "rebirth" then
		Shop.RenderRebirth(snapshot)
	elseif Shop.OpenPanel == "index" then
		Shop.RenderIndex(snapshot)
	elseif Shop.OpenPanel == "buff" then
		Shop.RenderBuff(snapshot)
	elseif Shop.OpenPanel == "mission" then
		Shop.RenderMission(snapshot)
	elseif Shop.OpenPanel == "fuse" then
		Shop.RenderFuse(snapshot)
	end
end

function Shop.RenderConveyor(snapshot)
	if Shop.ConveyorFrame == nil then
		return
	end
	for _, child in ipairs(Shop.ConveyorFrame:GetChildren()) do
		child:Destroy()
	end
	for i, slot in ipairs(snapshot.Conveyor) do
		local def = BrainrotData.FindCharacter(slot.CharId)
		if def ~= nil then
			local rarityColor = BrainrotData.RarityColor(def.Rarity)
			local card = Instance.new("Frame")
			card.Name = "Card" .. tostring(i)
			card.Size = UDim2.new(0, 144, 0, 112)
			card.Position = UDim2.new(0, (i - 1) * 152, 0, 0)
			card.BackgroundColor3 = DARK
			card.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
			card.BorderSizePixel = 3
			card.Parent = Shop.ConveyorFrame
			local mark = BrainrotData.MutationMark(slot.Mutation)
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -8, 0, 30)
			nameLabel.Position = UDim2.new(0, 4, 0, 4)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = def.Name .. " " .. mark
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.TextScaled = true
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.Parent = card
			local rarityLabel = Instance.new("TextLabel")
			rarityLabel.Size = UDim2.new(1, -8, 0, 26)
			rarityLabel.Position = UDim2.new(0, 4, 0, 36)
			rarityLabel.BackgroundTransparency = 1
			rarityLabel.Text = def.Rarity .. "  " .. Format.Money(def.Income) .. "/s"
			rarityLabel.TextColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
			rarityLabel.TextScaled = true
			rarityLabel.Font = Enum.Font.GothamBold
			rarityLabel.Parent = card
			local priceLabel = Instance.new("TextLabel")
			priceLabel.Size = UDim2.new(1, -8, 0, 30)
			priceLabel.Position = UDim2.new(0, 4, 0, 66)
			priceLabel.BackgroundTransparency = 1
			priceLabel.Text = Format.Money(slot.Cost)
			priceLabel.TextColor3 = GOLD
			priceLabel.TextScaled = true
			priceLabel.Font = Enum.Font.GothamBold
			priceLabel.Parent = card
			if snapshot.Cash < slot.Cost then
				card.BackgroundTransparency = 0.4
			end
		end
	end
end

function Shop.RenderGear(snapshot)
	for _, child in ipairs(Shop.GearPanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.GearPanel, "COINS SHOP - GEAR")
	for i, gear in ipairs(BrainrotData.GEAR) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -16, 0, 56)
		button.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 64)
		button.BackgroundColor3 = DARK
		button.BorderColor3 = GOLD
		button.BorderSizePixel = 2
		button.Text = gear.Name .. "  " .. Format.Money(gear.Cost) .. " - " .. gear.Desc
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = Shop.GearPanel
		local gearId = gear.Id
		button.MouseButton1Click:Connect(function()
			Shop.Remotes.BuyGear:FireServer(gearId)
		end)
	end
end

function Shop.RenderBuff(snapshot)
	for _, child in ipairs(Shop.BuffPanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.BuffPanel, "BUFF SHOP - UPGRADE PERMANEN")
	local upgrades = snapshot.Upgrades or { Luck = 0, Income = 0, Speed = 0 }
	for i, def in ipairs(BrainrotData.UPGRADES) do
		local level = upgrades[def.Id] or 0
		local maxed = level >= BrainrotData.UPGRADE_MAX
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -16, 0, 64)
		row.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 72)
		row.BackgroundColor3 = DARK
		row.BorderColor3 = GOLD
		row.BorderSizePixel = 2
		row.Parent = Shop.BuffPanel
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -140, 0, 30)
		nameLabel.Position = UDim2.new(0, 8, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = def.Name .. "  Lv " .. tostring(level) .. "/5"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row
		local effectLabel = Instance.new("TextLabel")
		effectLabel.Size = UDim2.new(1, -140, 0, 26)
		effectLabel.Position = UDim2.new(0, 8, 0, 34)
		effectLabel.BackgroundTransparency = 1
		if maxed then
			effectLabel.Text = "MAX - " .. def.Desc .. " / level"
		else
			effectLabel.Text = "Berikutnya: " .. def.Desc .. " - " .. Format.Money(def.Prices[level + 1])
		end
		effectLabel.TextColor3 = GOLD
		effectLabel.TextScaled = true
		effectLabel.Font = Enum.Font.GothamBold
		effectLabel.TextXAlignment = Enum.TextXAlignment.Left
		effectLabel.Parent = row
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 118, 0, 48)
		button.Position = UDim2.new(1, -126, 0, 8)
		button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
		button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = row
		if maxed then
			button.Text = "MAX"
			button.BackgroundTransparency = 0.5
		else
			button.Text = "UPGRADE " .. Format.Money(def.Prices[level + 1])
			if snapshot.Cash < def.Prices[level + 1] then
				row.BackgroundTransparency = 0.4
				button.BackgroundTransparency = 0.5
			end
			local upgradeId = def.Id
			button.MouseButton1Click:Connect(function()
				Shop.Remotes.BuyUpgrade:FireServer(upgradeId)
			end)
		end
	end
end

function Shop.RenderMission(snapshot)
	for _, child in ipairs(Shop.MissionPanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.MissionPanel, "MISI - KLAIM HADIAHNYA")
	local missions = snapshot.Missions or {}
	for i, mission in ipairs(missions) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -16, 0, 52)
		row.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 58)
		row.BackgroundColor3 = DARK
		row.BorderColor3 = GOLD
		row.BorderSizePixel = 2
		row.Parent = Shop.MissionPanel
		local mark = "○"
		local markColor = Color3.new(0.6, 0.6, 0.6)
		if mission.Claimed then
			mark = "✓"
			markColor = Color3.new(0.4, 1, 0.4)
		elseif mission.Done then
			mark = "★"
			markColor = GOLD
		end
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -130, 0, 30)
		textLabel.Position = UDim2.new(0, 8, 0, 2)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = mark .. "  " .. mission.Text
		textLabel.TextColor3 = markColor
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = row
		local progressLabel = Instance.new("TextLabel")
		progressLabel.Size = UDim2.new(1, -130, 0, 18)
		progressLabel.Position = UDim2.new(0, 8, 0, 32)
		progressLabel.BackgroundTransparency = 1
		progressLabel.Text = tostring(mission.Progress) .. "/" .. tostring(mission.Goal) .. "  -  Hadiah " .. Format.Money(mission.Reward)
		progressLabel.TextColor3 = GOLD
		progressLabel.TextScaled = true
		progressLabel.Font = Enum.Font.GothamBold
		progressLabel.TextXAlignment = Enum.TextXAlignment.Left
		progressLabel.Parent = row
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 110, 0, 40)
		button.Position = UDim2.new(1, -118, 0, 6)
		button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
		button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = row
		if mission.Claimed then
			button.Text = "DIKLAIM"
			button.BackgroundTransparency = 0.5
		elseif mission.Done then
			button.Text = "KLAIM"
			local missionId = mission.Id
			button.MouseButton1Click:Connect(function()
				Shop.Remotes.ClaimMission:FireServer(missionId)
			end)
		else
			button.Text = "BELUM"
			button.BackgroundTransparency = 0.5
		end
	end
end

-- Fuse panel: tap up to 3 of your own placed brainrots. When all
-- three share a rarity, FUSE turns them into one of the next tier.
function Shop.RenderFuse(snapshot)
	for _, child in ipairs(Shop.FusePanel:GetChildren()) do
		child:Destroy()
	end
	makeTitle(Shop.FusePanel, "FUSE MACHINE - 3 JADI 1")
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -16, 0, 26)
	hint.Position = UDim2.new(0, 8, 0, 36)
	hint.BackgroundTransparency = 1
	hint.Text = "Pilih 3 brainrot dengan raritas SAMA dari base kamu"
	hint.TextColor3 = Color3.new(1, 1, 1)
	hint.TextScaled = true
	hint.Font = Enum.Font.GothamBold
	hint.Parent = Shop.FusePanel
	-- Drop selections that no longer exist (sold, stolen, fused).
	local placedBySlot = {}
	for _, item in ipairs(snapshot.Placed) do
		placedBySlot[item.Slot] = item
	end
	local selected = {}
	for _, slot in ipairs(Shop.FuseSelected) do
		if placedBySlot[slot] ~= nil then
			table.insert(selected, slot)
		end
	end
	Shop.FuseSelected = selected
	for slot = 1, snapshot.Slots do
		local item = placedBySlot[slot]
		local col = (slot - 1) % 3
		local row = math.floor((slot - 1) / 3)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0, 148, 0, 44)
		button.Position = UDim2.new(0, 8 + col * 156, 0, 68 + row * 50)
		button.BackgroundColor3 = DARK
		button.BorderColor3 = Color3.new(0.6, 0.6, 0.6)
		button.BorderSizePixel = 2
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = Shop.FusePanel
		if item ~= nil then
			local def = BrainrotData.FindCharacter(item.CharId)
			if def ~= nil then
				local rarityColor = BrainrotData.RarityColor(def.Rarity)
				button.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
				button.Text = def.Name .. "\n" .. def.Rarity
				button.TextColor3 = Color3.new(1, 1, 1)
			end
		else
			button.Text = "Slot " .. tostring(slot) .. "\nKosong"
			button.TextColor3 = Color3.new(0.4, 0.4, 0.4)
		end
		local isSelected = false
		for _, s in ipairs(selected) do
			if s == slot then
				isSelected = true
			end
		end
		if isSelected then
			button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
			button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
		end
		local slotIndex = slot
		local hasItem = item ~= nil
		button.MouseButton1Click:Connect(function()
			if not hasItem then
				return
			end
			local nextSelected = {}
			local found = false
			for _, s in ipairs(Shop.FuseSelected) do
				if s == slotIndex then
					found = true
				else
					table.insert(nextSelected, s)
				end
			end
			if not found and #nextSelected < 3 then
				table.insert(nextSelected, slotIndex)
			end
			Shop.FuseSelected = nextSelected
			Shop.RenderFuse(Shop.LastSnapshot or { Placed = {}, Slots = 8 })
		end)
	end
	local fuseButton = Instance.new("TextButton")
	fuseButton.Size = UDim2.new(1, -16, 0, 48)
	fuseButton.Position = UDim2.new(0, 8, 0, 404)
	fuseButton.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
	fuseButton.TextColor3 = Color3.new(0.06, 0.09, 0.16)
	fuseButton.TextScaled = true
	fuseButton.Font = Enum.Font.GothamBold
	fuseButton.Parent = Shop.FusePanel
	local ready = false
	local nextRarity = nil
	if #selected == 3 then
		local firstDef = BrainrotData.FindCharacter(placedBySlot[selected[1]].CharId)
		local same = true
		for _, s in ipairs(selected) do
			local def = BrainrotData.FindCharacter(placedBySlot[s].CharId)
			if def == nil or def.Rarity ~= firstDef.Rarity then
				same = false
			end
		end
		if same then
			nextRarity = BrainrotData.NextRarity(firstDef.Rarity)
			ready = nextRarity ~= nil
		end
	end
	if ready then
		fuseButton.Text = "FUSE  →  " .. nextRarity
		fuseButton.MouseButton1Click:Connect(function()
			Shop.Remotes.Fuse:FireServer(Shop.FuseSelected)
			Shop.FuseSelected = {}
		end)
	else
		fuseButton.Text = "PILIH 3 DENGAN RARITAS SAMA"
		fuseButton.BackgroundTransparency = 0.5
	end
end

function Shop.RenderRebirth(snapshot)
	for _, child in ipairs(Shop.RebirthPanel:GetChildren()) do
		child:Destroy()
	end
	local nextLevel = snapshot.Rebirth + 1
	makeTitle(Shop.RebirthPanel, "REBIRTH Lv" .. tostring(nextLevel) .. " - " .. Format.Money(snapshot.RebirthCost))
	local owned = {}
	for _, charId in ipairs(snapshot.Owned) do
		owned[charId] = true
	end
	local placed = {}
	for _, item in ipairs(snapshot.Placed) do
		placed[item.CharId] = true
	end
	for i, charId in ipairs(snapshot.RebirthNeed) do
		local def = BrainrotData.FindCharacter(charId)
		local hasIt = owned[charId] or placed[charId]
		local mark = "✗"
		local color = Color3.new(1, 0.3, 0.3)
		if hasIt then
			mark = "✓"
			color = Color3.new(0.4, 1, 0.4)
		end
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -16, 0, 34)
		label.Position = UDim2.new(0, 8, 0, 40 + (i - 1) * 38)
		label.BackgroundTransparency = 1
		label.Text = mark .. "  " .. (def ~= nil and def.Name or charId)
		label.TextColor3 = color
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = Shop.RebirthPanel
	end
	local cashLabel = Instance.new("TextLabel")
	cashLabel.Size = UDim2.new(1, -16, 0, 34)
	cashLabel.Position = UDim2.new(0, 8, 0, 130)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Text = "Cash: " .. Format.Money(snapshot.Cash) .. " / " .. Format.Money(snapshot.RebirthCost)
	cashLabel.TextColor3 = GOLD
	cashLabel.TextScaled = true
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.Parent = Shop.RebirthPanel
	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -16, 0, 34)
	rewardLabel.Position = UDim2.new(0, 8, 0, 168)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "Reward: +50% income, +1 base slot, +10s lock"
	rewardLabel.TextColor3 = Color3.new(1, 1, 1)
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.Parent = Shop.RebirthPanel
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -16, 0, 48)
	button.Position = UDim2.new(0, 8, 0, 212)
	button.BackgroundColor3 = Color3.new(0.64, 0.90, 0.21)
	button.Text = "REBIRTH NOW"
	button.TextColor3 = Color3.new(0.06, 0.09, 0.16)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = Shop.RebirthPanel
	if not snapshot.CanRebirth then
		button.BackgroundTransparency = 0.5
	end
	button.MouseButton1Click:Connect(function()
		Shop.Remotes.DoRebirth:FireServer()
	end)
end

function Shop.RenderIndex(snapshot)
	for _, child in ipairs(Shop.IndexPanel:GetChildren()) do
		child:Destroy()
	end
	local owned = {}
	for _, charId in ipairs(snapshot.Owned) do
		owned[charId] = true
	end
	local count = 0
	for _, _ in pairs(owned) do
		count = count + 1
	end
	makeTitle(Shop.IndexPanel, "INDEX - " .. tostring(count) .. "/" .. tostring(#BrainrotData.CHARACTERS) .. " (" .. tostring(math.floor(count / #BrainrotData.CHARACTERS * 100)) .. "%)")
	for i, def in ipairs(BrainrotData.CHARACTERS) do
		local col = (i - 1) % 5
		local row = math.floor((i - 1) / 5)
		local hasIt = owned[def.Id]
		local rarityColor = BrainrotData.RarityColor(def.Rarity)
		local cell = Instance.new("TextLabel")
		cell.Size = UDim2.new(0, 104, 0, 56)
		cell.Position = UDim2.new(0, 8 + col * 110, 0, 44 + row * 62)
		cell.BackgroundColor3 = DARK
		cell.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
		cell.BorderSizePixel = 2
		cell.Text = def.Name .. "\n" .. def.Rarity
		if not hasIt then
			cell.Text = "???\n" .. def.Rarity
			cell.TextColor3 = Color3.new(0.4, 0.4, 0.4)
		else
			cell.TextColor3 = Color3.new(1, 1, 1)
		end
		cell.TextScaled = true
		cell.Font = Enum.Font.GothamBold
		cell.Parent = Shop.IndexPanel
	end
end

return Shop
