-- round 4
-- Events: the market clock. Every few minutes the market flips to
-- Rush Hour (fast conveyor plus a roaming thief) or Festival (double
-- income), with a Golden Hour bonus round in between. The HUD and the
-- pity board always show what is coming next.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local Events = {}
Events.Current = "None"
Events.EndsAt = 0
Events.NextAt = os.time() + Config.EventInterval
Events.LastKind = "Festival"
Events.OnStart = nil
Events.OnEnd = nil

function Events.IsFestival()
	return Events.Current == "Festival"
end

function Events.IsRushHour()
	return Events.Current == "RushHour"
end

function Events.IncomeMult()
	if Events.Current == "Festival" then
		return Config.FestivalIncomeMult
	end
	return 1
end

function Events.ConveyorInterval()
	if Events.Current == "RushHour" then
		return Config.ConveyorRushInterval
	end
	return Config.ConveyorInterval
end

function Events.StartEvent(kind)
	Events.Current = kind
	local duration = Config.EventDuration
	if kind == "GoldenHour" then
		duration = Config.GoldenHourDuration
	end
	Events.EndsAt = os.time() + duration
	Events.LastKind = kind
	if Events.OnStart ~= nil then
		Events.OnStart(kind)
	end
end

function Events.ForceEvent(kind)
	if kind == "RushHour" or kind == "Festival" or kind == "GoldenHour" then
		Events.StartEvent(kind)
		return true
	end
	return false
end

function Events.Tick()
	local now = os.time()
	if Events.Current ~= "None" and now >= Events.EndsAt then
		Events.Current = "None"
		Events.NextAt = now + Config.EventInterval
		if Events.OnEnd ~= nil then
			Events.OnEnd()
		end
		return
	end
	if Events.Current == "None" and now >= Events.NextAt then
		if Events.LastKind == "Festival" then
			Events.StartEvent("RushHour")
		elseif Events.LastKind == "RushHour" then
			Events.StartEvent("GoldenHour")
		else
			Events.StartEvent("Festival")
		end
	end
end

function Events.TimeLeft()
	if Events.Current == "None" then
		return math.max(0, Events.NextAt - os.time())
	end
	return math.max(0, Events.EndsAt - os.time())
end

return Events
