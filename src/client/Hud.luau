-- round 4
-- Hud: the screen interface, decluttered (Wira 19 Nov: "sangat padat
-- dan berantakan"). Only the essentials stay on the main screen:
-- money top-right, ONE timer line top-centre, ONE mission line under
-- it, a compact collapsible base panel on the left, and three buttons
-- bottom-right (MENU / LOCK / COLLECT). Everything else (gear, buff,
-- index, missions, fuse, rebirth, Top-5) lives in the single MENU
-- panel (Shop). The middle of the screen stays empty so the game
-- itself is visible. A new player should get it in 3 seconds: how
-- much money, what to do next, where to buy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local Hud = {}
Hud.MoneyLabel = nil
Hud.IncomeLabel = nil
Hud.PendingLabel = nil
Hud.TimerLabel = nil
Hud.MissionLabel = nil
Hud.BasePanel = nil
Hud.BaseHeader = nil
Hud.BaseCollapsed = false
Hud.ToastFrame = nil
Hud.LockButton = nil
Hud.CollectButton = nil
Hud.LastSnapshot = nil
Hud.Remotes = nil

local DARK = Color3.new(0.06, 0.09, 0.16)
local LIME = Color3.new(0.64, 0.90, 0.21)
local GOLD = Color3.new(1, 0.85, 0.2)

local function makeLabel(parent, name, size, pos, text, color, fontSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, pos, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = DARK
	button.BorderColor3 = color
	button.BorderSizePixel = 2
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	return button
end

function Hud.Build(remotes, callbacks)
	Hud.Remotes = remotes
	local gui = Instance.new("ScreenGui")
	gui.Name = "NightMarketHud"
	gui.ResetOnSpawn = false
	gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Top-right money block, slim: cash, income, pile.
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Size = UDim2.new(0, 240, 0, 96)
	moneyFrame.Position = UDim2.new(1, -260, 0, 12)
	moneyFrame.BackgroundColor3 = DARK
	moneyFrame.BorderColor3 = GOLD
	moneyFrame.BorderSizePixel = 2
	moneyFrame.Parent = gui
	Hud.MoneyLabel = makeLabel(moneyFrame, "Money", UDim2.new(1, -16, 0, 38), UDim2.new(0, 8, 0, 4), "$100", GOLD, 28)
	Hud.IncomeLabel = makeLabel(moneyFrame, "Income", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 44), "+$0/s", Color3.new(0.4, 1, 0.4), 20)
	Hud.PendingLabel = makeLabel(moneyFrame, "Pending", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 68), "Pile: $0", Color3.new(1, 1, 1), 20)

	-- ONE timer line top-centre: next event + both pity clocks.
	Hud.TimerLabel = makeLabel(gui, "Timer", UDim2.new(0, 560, 0, 26), UDim2.new(0.5, -280, 0, 0), "", LIME, 20)

	-- ONE mission line under it, small, never blocking the centre.
	Hud.MissionLabel = makeLabel(gui, "Mission", UDim2.new(0, 480, 0, 22), UDim2.new(0.5, -240, 0, 30), "1. Buy a brainrot on the red carpet", Color3.new(1, 1, 1), 20)
	Hud.MissionLabel.BackgroundColor3 = DARK
	Hud.MissionLabel.BackgroundTransparency = 0.1

	-- Toast feed: right of the base panel, above the conveyor cards.
	Hud.ToastFrame = Instance.new("Frame")
	Hud.ToastFrame.Name = "Toasts"
	Hud.ToastFrame.Size = UDim2.new(0, 300, 0, 120)
	Hud.ToastFrame.Position = UDim2.new(0, 216, 1, -280)
	Hud.ToastFrame.BackgroundTransparency = 1
	Hud.ToastFrame.Parent = gui

	-- Left base panel, compact and collapsible. Height is set by
	-- RenderBaseSlots: header + filled slots + one empty slot.
	local baseFrame = Instance.new("Frame")
	baseFrame.Name = "BasePanel"
	baseFrame.Size = UDim2.new(0, 200, 0, 66)
	baseFrame.Position = UDim2.new(0, 16, 0, 180)
	baseFrame.BackgroundColor3 = DARK
	baseFrame.BorderColor3 = LIME
	baseFrame.BorderSizePixel = 2
	baseFrame.Parent = gui
	Hud.BasePanel = baseFrame
	local header = Instance.new("TextButton")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 30)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Text = "MY BASE  0/8  ▼"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextScaled = true
	header.Font = Enum.Font.GothamBold
	header.Parent = baseFrame
	Hud.BaseHeader = header
	header.MouseButton1Click:Connect(function()
		Hud.BaseCollapsed = not Hud.BaseCollapsed
		if Hud.LastSnapshot ~= nil then
			Hud.RenderBaseSlots(Hud.LastSnapshot)
		end
	end)

	-- Bottom-right: only three buttons. Everything else is in MENU.
	local menuButton = makeButton(gui, "MenuButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -276), "MENU", LIME, 20)
	Hud.LockButton = makeButton(gui, "LockButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -220), "LOCK BASE $1,500", Color3.new(0.3, 0.6, 1), 20)
	Hud.CollectButton = makeButton(gui, "CollectButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -164), "COLLECT PILE", Color3.new(0.15, 0.85, 0.25), 20)

	menuButton.MouseButton1Click:Connect(function()
		callbacks.ToggleMenu()
	end)
	Hud.LockButton.MouseButton1Click:Connect(function()
		remotes.LockBase:FireServer()
	end)
	Hud.CollectButton.MouseButton1Click:Connect(function()
		remotes.CollectCash:FireServer()
	end)
end

function Hud.Render(snapshot)
	Hud.LastSnapshot = snapshot
	if Hud.MoneyLabel ~= nil then
		Hud.MoneyLabel.Text = Format.Money(snapshot.Cash)
		Hud.IncomeLabel.Text = Format.Rate(snapshot.Income)
		Hud.PendingLabel.Text = "Pile: " .. Format.Money(snapshot.Pending)
	end
	if Hud.TimerLabel ~= nil then
		local eventText = "Next event in " .. Format.Seconds(snapshot.EventTimeLeft)
		local color = LIME
		if snapshot.Event == "RushHour" then
			eventText = "RUSH HOUR " .. Format.Seconds(snapshot.EventTimeLeft)
			color = Color3.new(1, 0.3, 0.3)
		elseif snapshot.Event == "Festival" then
			eventText = "FESTIVAL 2x " .. Format.Seconds(snapshot.EventTimeLeft)
			color = GOLD
		elseif snapshot.Event == "GoldenHour" then
			eventText = "GOLDEN HOUR " .. Format.Seconds(snapshot.EventTimeLeft)
			color = GOLD
		end
		Hud.TimerLabel.Text = eventText .. "  ·  Legendary in " .. Format.Seconds(snapshot.PityLegendary) .. "  ·  Epic in " .. Format.Seconds(snapshot.PityEpic)
		Hud.TimerLabel.TextColor3 = color
	end
	if Hud.LockButton ~= nil then
		if snapshot.LockLeft > 0 then
			Hud.LockButton.Text = "LOCKED " .. Format.Seconds(snapshot.LockLeft)
		elseif snapshot.LockCooldown > 0 then
			Hud.LockButton.Text = "LOCK in " .. Format.Seconds(snapshot.LockCooldown)
		else
			Hud.LockButton.Text = "LOCK BASE $1,500"
		end
	end
	if Hud.CollectButton ~= nil then
		Hud.CollectButton.Text = "COLLECT " .. Format.Money(snapshot.Pending)
	end
	if Hud.MissionLabel ~= nil then
		if snapshot.TutorialStep == 0 then
			Hud.MissionLabel.Text = "1. Buy a brainrot on the red carpet"
		elseif snapshot.TutorialStep == 1 then
			Hud.MissionLabel.Text = "2. Carry it to your base and click a pad"
		elseif snapshot.TutorialStep == 2 then
			Hud.MissionLabel.Text = "3. Lock your base before you leave!"
		else
			Hud.MissionLabel.Text = ""
		end
	end
	Hud.RenderBaseSlots(snapshot)
end

-- Only filled slots plus the first empty one; the panel grows and
-- shrinks with what you own instead of always showing 12 rows.
function Hud.RenderBaseSlots(snapshot)
	if Hud.BasePanel == nil then
		return
	end
	for _, child in ipairs(Hud.BasePanel:GetChildren()) do
		if child.Name == "SlotButton" then
			child:Destroy()
		end
	end
	local placedBySlot = {}
	local placedCount = 0
	for _, item in ipairs(snapshot.Placed) do
		placedBySlot[item.Slot] = item
		placedCount = placedCount + 1
	end
	local visible = {}
	for slot = 1, snapshot.Slots do
		if placedBySlot[slot] ~= nil then
			table.insert(visible, slot)
		end
	end
	local firstEmpty = 0
	for slot = 1, snapshot.Slots do
		if placedBySlot[slot] == nil then
			firstEmpty = slot
			break
		end
	end
	if firstEmpty > 0 then
		table.insert(visible, firstEmpty)
	end
	if Hud.BaseHeader ~= nil then
		Hud.BaseHeader.Text = "MY BASE  " .. tostring(placedCount) .. "/" .. tostring(snapshot.Slots) .. (Hud.BaseCollapsed and "  ▲" or "  ▼")
	end
	if Hud.BaseCollapsed then
		Hud.BasePanel.Size = UDim2.new(0, 200, 0, 34)
		return
	end
	Hud.BasePanel.Size = UDim2.new(0, 200, 0, 34 + #visible * 28 + 6)
	for i, slot in ipairs(visible) do
		local item = placedBySlot[slot]
		local text = "Empty"
		local color = Color3.new(0.6, 0.6, 0.6)
		if item ~= nil then
			local def = BrainrotData.FindCharacter(item.CharId)
			if def ~= nil then
				text = def.Name .. "  " .. Format.Money(BrainrotData.IncomeFor(def, item.Mutation, snapshot.Rebirth, 1)) .. "/s"
				local rarityColor = BrainrotData.RarityColor(def.Rarity)
				color = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
			end
		end
		local button = Instance.new("TextButton")
		button.Name = "SlotButton"
		button.Size = UDim2.new(1, -16, 0, 26)
		button.Position = UDim2.new(0, 8, 0, 34 + (i - 1) * 28)
		button.BackgroundColor3 = DARK
		button.BorderColor3 = color
		button.BorderSizePixel = 2
		button.Text = text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.Parent = Hud.BasePanel
		local slotIndex = slot
		local hasItem = item ~= nil
		button.MouseButton1Click:Connect(function()
			if hasItem then
				Hud.Remotes.SellBrainrot:FireServer(slotIndex)
			end
		end)
	end
end

function Hud.ShowToast(text)
	if Hud.ToastFrame == nil then
		return
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 28)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundColor3 = DARK
	label.BackgroundTransparency = 0.1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = Hud.ToastFrame
	for _, child in ipairs(Hud.ToastFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child.Position = child.Position + UDim2.new(0, 0, 0, 30)
		end
	end
	task.spawn(function()
		task.wait(5)
		label:Destroy()
	end)
end

return Hud
