-- round 4
-- Config: every tuning number for Brainrot Night Market lives here.
-- No other module hard-codes an economy number.

local Config = {}

Config.StartCash = 100
Config.BaseSlots = 8
Config.MaxSlots = 12
Config.SellRefund = 0.5

Config.ConveyorSlots = 5
-- Play-test 19 Nov: a 6s set change was too fast to read or hold E
-- on (and the 3s Rush Hour window kept killing holds mid-way).
-- 10s calm / 6s Rush Hour gives a full hold window every time.
Config.ConveyorInterval = 10
Config.ConveyorRushInterval = 6
Config.ConveyorSpacing = 10

Config.LockCost = 1500
Config.LockDuration = 20
Config.LockBonusPerRebirth = 10
Config.LockCooldown = 30

Config.RebirthIncomeBonus = 0.5
Config.RebirthSlotsBonus = 1

Config.CarryTime = 8
Config.CarrySpeedMult = 0.8
Config.StealCooldown = 60
Config.NewPlayerGrace = 60

Config.EventInterval = 240
Config.EventDuration = 45
Config.FestivalIncomeMult = 2
Config.GoldenHourDuration = 60

Config.PityEpicSeconds = 180
Config.PityLegendarySeconds = 480

Config.CollectPadSize = 10
Config.TrapMaxActive = 3
Config.TrapFreezeSeconds = 7
Config.CoilSpeedMult = 1.5
Config.CoilDuration = 30

-- A dropped brainrot lies on the ground this long before it is
-- returned to its owner's base.
Config.LooseExpireSeconds = 60
Config.LeaderboardSize = 5
Config.LeaderboardInterval = 5

Config.AutosaveSeconds = 120
Config.DataStoreName = "BrainrotNightMarketSaveV2"

Config.BaseCenters = {
	{ Name = "NW", Color = { 0.20, 0.70, 0.35 }, X = -30, Z = 12 },
	{ Name = "NE", Color = { 0.95, 0.55, 0.15 }, X = 30, Z = 12 },
	{ Name = "SW", Color = { 0.25, 0.55, 1.00 }, X = -30, Z = -12 },
	{ Name = "SE", Color = { 0.85, 0.25, 0.55 }, X = 30, Z = -12 },
}

Config.SpawnPosition = { 0, 2, 44 }
Config.ConveyorZ = -34
Config.GearStallPosition = { 0, 0, -8 }
-- Play-test 19 Nov: the fuse machine sat in the middle of the plaza
-- so its sign piled onto the neon sign + HUD banner in the spawn
-- view. Moved to the west edge of the walkway, clear of the NW base
-- platform (x >= -10) and of the chevron path (x = 0).
Config.FuseMachinePosition = { -4, 0, 20 }

return Config
