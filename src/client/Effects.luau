-- Effects: small feedback moments. The money label flashes green on
-- a purchase, the banner turns red on a steal alert, and event
-- banners pop in the centre of the screen.
-- Sounds play client-side only, for the player concerned: buy is a
-- bright cha-ching ping, steal is a low alarm, rebirth is a three-note
-- fanfare. All three are pitch variations of one built-in Roblox
-- sound (rbxasset://sounds/electronicpingshort.wav), so they can
-- never fail on a bad asset id - the pcall is a second safety net.

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Effects = {}

local PING = "rbxasset://sounds/electronicpingshort.wav"

local function playPing(speed, volume)
	local ok, err = pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = PING
		sound.PlaybackSpeed = speed
		sound.Volume = volume or 0.7
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
		task.spawn(function()
			task.wait(3)
			if sound.Parent ~= nil then
				sound:Destroy()
			end
		end)
	end)
	if not ok then
		warn("Effects: sound failed: " .. tostring(err))
	end
end

-- kind: "buy" (cha-ching), "steal" / "alarm" (low alarm),
-- "rebirth" (three-note fanfare).
function Effects.PlaySound(kind)
	if kind == "buy" then
		playPing(1.4, 0.8)
		task.spawn(function()
			task.wait(0.12)
			playPing(1.8, 0.7)
		end)
	elseif kind == "steal" or kind == "alarm" then
		playPing(0.55, 0.9)
		task.spawn(function()
			task.wait(0.25)
			playPing(0.55, 0.9)
		end)
	elseif kind == "rebirth" then
		playPing(1.0, 0.8)
		task.spawn(function()
			task.wait(0.16)
			playPing(1.26, 0.8)
			task.wait(0.16)
			playPing(1.5, 0.9)
		end)
	end
end

function Effects.PlayPurchase(hud)
	if hud.MoneyLabel == nil then
		return
	end
	local goal = { TextColor3 = Color3.new(0.4, 1, 0.4) }
	local tween = TweenService:Create(hud.MoneyLabel, TweenInfo.new(0.3), goal)
	tween:Play()
	tween.Completed:Connect(function()
		local back = { TextColor3 = Color3.new(1, 0.85, 0.2) }
		TweenService:Create(hud.MoneyLabel, TweenInfo.new(0.6), back):Play()
	end)
end

function Effects.PlayStealAlert(hud)
	if hud.TimerLabel == nil then
		return
	end
	hud.TimerLabel.Text = "YOUR BASE IS BEING ROBBED!"
	hud.TimerLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
end

function Effects.PlayEventBanner(hud, text, color)
	if hud.TimerLabel == nil then
		return
	end
	hud.TimerLabel.Text = text
	hud.TimerLabel.TextColor3 = color
end

return Effects
