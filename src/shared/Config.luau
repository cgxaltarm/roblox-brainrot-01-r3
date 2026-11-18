-- Config: every tuning number for Brainrot Night Market lives here.
-- No other module hard-codes an economy number.

local Config = {}

Config.StartCash = 100
Config.BaseSlots = 8
Config.MaxSlots = 12
Config.SellRefund = 0.5

Config.ConveyorSlots = 5
Config.ConveyorInterval = 6
Config.ConveyorRushInterval = 3
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
Config.FuseMachinePosition = { -6, 0, 6 }
Config.LeaderboardPosition = { 30, 0, -40 }

return Config
