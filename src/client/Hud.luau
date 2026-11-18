-- Hud: the screen interface. Money top-right, event banner and pity
-- countdown top-centre, base panel on the left, Top-5 leaderboard
-- under it, action buttons bottom-right, tutorial toasts on join.
-- Dark cards, bold white text, gold prices: readable when the
-- screenshot is shrunk.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Format = require(ReplicatedStorage.Shared.Format)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local Hud = {}
Hud.MoneyLabel = nil
Hud.IncomeLabel = nil
Hud.PendingLabel = nil
Hud.BannerLabel = nil
Hud.PityLabel = nil
Hud.BasePanel = nil
Hud.LeaderboardPanel = nil
Hud.TutorialLabel = nil
Hud.ToastFrame = nil
Hud.LockButton = nil
Hud.RebirthButton = nil
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

	-- Top-right money block.
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.Size = UDim2.new(0, 260, 0, 110)
	moneyFrame.Position = UDim2.new(1, -280, 0, 16)
	moneyFrame.BackgroundColor3 = DARK
	moneyFrame.BorderColor3 = GOLD
	moneyFrame.BorderSizePixel = 2
	moneyFrame.Parent = gui
	Hud.MoneyLabel = makeLabel(moneyFrame, "Money", UDim2.new(1, -16, 0, 48), UDim2.new(0, 8, 0, 4), "$100", GOLD, 28)
	Hud.IncomeLabel = makeLabel(moneyFrame, "Income", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 52), "+$0/s", Color3.new(0.4, 1, 0.4), 20)
	Hud.PendingLabel = makeLabel(moneyFrame, "Pending", UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 78), "Pile: $0 - walk to COLLECT", Color3.new(1, 1, 1), 20)

	-- Top-centre banner + pity countdown.
	Hud.BannerLabel = makeLabel(gui, "Banner", UDim2.new(0, 560, 0, 44), UDim2.new(0.5, -280, 0, 12), "BRAINROT NIGHT MARKET", LIME, 24)
	Hud.PityLabel = makeLabel(gui, "Pity", UDim2.new(0, 560, 0, 28), UDim2.new(0.5, -280, 0, 58), "Legendary guaranteed in 08:00", GOLD, 20)

	-- Tutorial toasts under the banner.
	Hud.TutorialLabel = makeLabel(gui, "Tutorial", UDim2.new(0, 620, 0, 60), UDim2.new(0.5, -310, 0, 96), "1. Buy a brainrot on the red carpet", Color3.new(1, 1, 1), 20)
	Hud.TutorialLabel.BackgroundColor3 = DARK
	Hud.TutorialLabel.BackgroundTransparency = 0.1

	-- Toast feed bottom-left.
	Hud.ToastFrame = Instance.new("Frame")
	Hud.ToastFrame.Name = "Toasts"
	Hud.ToastFrame.Size = UDim2.new(0, 420, 0, 120)
	Hud.ToastFrame.Position = UDim2.new(0, 16, 1, -140)
	Hud.ToastFrame.BackgroundTransparency = 1
	Hud.ToastFrame.Parent = gui

	-- Left base panel (12 slots: 8 base + up to 4 from rebirth).
	local baseFrame = Instance.new("Frame")
	baseFrame.Name = "BasePanel"
	baseFrame.Size = UDim2.new(0, 230, 0, 460)
	baseFrame.Position = UDim2.new(0, 16, 0, 180)
	baseFrame.BackgroundColor3 = DARK
	baseFrame.BorderColor3 = LIME
	baseFrame.BorderSizePixel = 2
	baseFrame.Parent = gui
	makeLabel(baseFrame, "Title", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), "MY BASE - click a slot to sell", Color3.new(1, 1, 1), 20)
	Hud.BasePanel = baseFrame

	-- Top-5 leaderboard under the money block (right side, so it fits
	-- on a 720p screen next to the tall 12-slot base panel).
	local boardFrame = Instance.new("Frame")
	boardFrame.Name = "LeaderboardPanel"
	boardFrame.Size = UDim2.new(0, 260, 0, 190)
	boardFrame.Position = UDim2.new(1, -280, 0, 140)
	boardFrame.BackgroundColor3 = DARK
	boardFrame.BorderColor3 = GOLD
	boardFrame.BorderSizePixel = 2
	boardFrame.Parent = gui
	makeLabel(boardFrame, "Title", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), "TOP 5  $/s", GOLD, 20)
	Hud.LeaderboardPanel = boardFrame

	-- Bottom-right action buttons.
	Hud.LockButton = makeButton(gui, "LockButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -220), "LOCK BASE $1,500", Color3.new(0.3, 0.6, 1), 20)
	Hud.RebirthButton = makeButton(gui, "RebirthButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -164), "REBIRTH", LIME, 20)
	Hud.CollectButton = makeButton(gui, "CollectButton", UDim2.new(0, 200, 0, 48), UDim2.new(1, -220, 1, -108), "COLLECT PILE", Color3.new(0.15, 0.85, 0.25), 20)
	local gearButton = makeButton(gui, "GearButton", UDim2.new(0, 96, 0, 48), UDim2.new(1, -326, 1, -108), "GEAR", GOLD, 20)
	local indexButton = makeButton(gui, "IndexButton", UDim2.new(0, 96, 0, 48), UDim2.new(1, -326, 1, -164), "INDEX", Color3.new(0.68, 0.4, 0.95), 20)
	local buffButton = makeButton(gui, "BuffButton", UDim2.new(0, 96, 0, 48), UDim2.new(1, -326, 1, -220), "BUFF", Color3.new(0.15, 0.85, 0.25), 20)
	local missionButton = makeButton(gui, "MissionButton", UDim2.new(0, 96, 0, 48), UDim2.new(1, -432, 1, -108), "MISI", Color3.new(1, 0.55, 0.2), 20)
	local fuseButton = makeButton(gui, "FuseButton", UDim2.new(0, 96, 0, 48), UDim2.new(1, -432, 1, -164), "FUSE", Color3.new(0.68, 0.4, 0.95), 20)

	Hud.LockButton.MouseButton1Click:Connect(function()
		remotes.LockBase:FireServer()
	end)
	Hud.RebirthButton.MouseButton1Click:Connect(function()
		callbacks.ToggleRebirth()
	end)
	Hud.CollectButton.MouseButton1Click:Connect(function()
		remotes.CollectCash:FireServer()
	end)
	gearButton.MouseButton1Click:Connect(function()
		callbacks.ToggleGear()
	end)
	indexButton.MouseButton1Click:Connect(function()
		callbacks.ToggleIndex()
	end)
	buffButton.MouseButton1Click:Connect(function()
		callbacks.ToggleBuff()
	end)
	missionButton.MouseButton1Click:Connect(function()
		callbacks.ToggleMission()
	end)
	fuseButton.MouseButton1Click:Connect(function()
		callbacks.ToggleFuse()
	end)
end

function Hud.Render(snapshot)
	Hud.LastSnapshot = snapshot
	if Hud.MoneyLabel ~= nil then
		Hud.MoneyLabel.Text = Format.Money(snapshot.Cash)
		Hud.IncomeLabel.Text = Format.Rate(snapshot.Income)
		Hud.PendingLabel.Text = "Pile: " .. Format.Money(snapshot.Pending) .. " - walk to COLLECT"
	end
	if Hud.PityLabel ~= nil then
		Hud.PityLabel.Text = "Legendary in " .. Format.Seconds(snapshot.PityLegendary) .. "  |  Epic in " .. Format.Seconds(snapshot.PityEpic)
	end
	if Hud.BannerLabel ~= nil then
		if snapshot.Event == "RushHour" then
			Hud.BannerLabel.Text = "RUSH HOUR! Thief on the loose - guard your base!"
			Hud.BannerLabel.TextColor3 = Color3.new(1, 0.3, 0.3)
		elseif snapshot.Event == "Festival" then
			Hud.BannerLabel.Text = "FESTIVAL! 2x income for " .. Format.Seconds(snapshot.EventTimeLeft)
			Hud.BannerLabel.TextColor3 = Color3.new(1, 0.85, 0.2)
		elseif snapshot.Event == "GoldenHour" then
			Hud.BannerLabel.Text = "GOLDEN HOUR! Every spawn is Golden!"
			Hud.BannerLabel.TextColor3 = Color3.new(1, 0.85, 0.2)
		else
			Hud.BannerLabel.Text = "BRAINROT NIGHT MARKET - next event in " .. Format.Seconds(snapshot.EventTimeLeft)
			Hud.BannerLabel.TextColor3 = LIME
		end
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
	if Hud.RebirthButton ~= nil then
		Hud.RebirthButton.Text = "REBIRTH Lv" .. tostring(snapshot.Rebirth + 1) .. " - " .. Format.Money(snapshot.RebirthCost)
	end
	if Hud.CollectButton ~= nil then
		Hud.CollectButton.Text = "COLLECT " .. Format.Money(snapshot.Pending)
	end
	if Hud.TutorialLabel ~= nil then
		if snapshot.TutorialStep == 0 then
			Hud.TutorialLabel.Text = "1. Buy a brainrot on the red carpet"
		elseif snapshot.TutorialStep == 1 then
			Hud.TutorialLabel.Text = "2. Carry it to your base and click a pad"
		elseif snapshot.TutorialStep == 2 then
			Hud.TutorialLabel.Text = "3. Lock your base before you leave!"
		else
			Hud.TutorialLabel.Text = ""
		end
	end
	Hud.RenderBaseSlots(snapshot)
	Hud.RenderLeaderboard(snapshot)
end

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
	for _, item in ipairs(snapshot.Placed) do
		placedBySlot[item.Slot] = item
	end
	for slot = 1, snapshot.Slots do
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
		button.Size = UDim2.new(1, -16, 0, 30)
		button.Position = UDim2.new(0, 8, 0, 36 + (slot - 1) * 34)
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

function Hud.RenderLeaderboard(snapshot)
	if Hud.LeaderboardPanel == nil then
		return
	end
	for _, child in ipairs(Hud.LeaderboardPanel:GetChildren()) do
		if child.Name == "BoardLine" then
			child:Destroy()
		end
	end
	local rows = snapshot.Leaderboard or {}
	for i = 1, 5 do
		local row = rows[i]
		local text = tostring(i) .. ". ---"
		if row ~= nil then
			text = tostring(i) .. ". " .. row.Name .. "  " .. Format.Money(row.Income) .. "/s"
		end
		local label = Instance.new("TextLabel")
		label.Name = "BoardLine"
		label.Size = UDim2.new(1, -16, 0, 28)
		label.Position = UDim2.new(0, 8, 0, 36 + (i - 1) * 30)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = Hud.LeaderboardPanel
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
