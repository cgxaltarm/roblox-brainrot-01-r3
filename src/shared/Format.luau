-- Format: money and time formatting for the HUD and billboards.

local Format = {}

function Format.Money(amount)
	local n = math.floor(amount + 0.5)
	if n >= 1000000000 then
		return "$" .. string.format("%.2fB", n / 1000000000)
	elseif n >= 1000000 then
		return "$" .. string.format("%.2fM", n / 1000000)
	elseif n >= 10000 then
		return "$" .. string.format("%.1fK", n / 1000)
	elseif n >= 1000 then
		return "$" .. tostring(n)
	else
		return "$" .. tostring(n)
	end
end

function Format.MoneyShort(amount)
	return Format.Money(amount)
end

function Format.Seconds(total)
	local s = math.max(0, math.floor(total))
	local m = math.floor(s / 60)
	local rest = s - m * 60
	if rest < 10 then
		return tostring(m) .. ":0" .. tostring(rest)
	else
		return tostring(m) .. ":" .. tostring(rest)
	end
end

function Format.Rate(income)
	return "+" .. Format.Money(income) .. "/s"
end

return Format
