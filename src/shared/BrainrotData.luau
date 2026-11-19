-- round 4
-- BrainrotData: catalogue of every character in Brainrot Night Market.
-- Each character has a distinct silhouette: a ball body plus a signature
-- prop built from Parts. A prop entry is {Kind, Size, Offset, Color} where
-- Kind is Block, Ball, Cylinder or Wedge, Size and Offset are {x, y, z} in
-- studs relative to the body centre, Color is {r, g, b} 0-1.
-- CharacterModels builds the model from this table alone.
-- r3: 30 characters (10 new Indonesian-food faces, mostly Rare/Epic/
-- Legendary), plus the mission list and the fuse ladder.

local BrainrotData = {}

BrainrotData.RARITIES = {
	{ Name = "Common", Color = { 0.62, 0.78, 0.45 }, Weight = 50 },
	{ Name = "Rare", Color = { 0.30, 0.60, 1.00 }, Weight = 25 },
	{ Name = "Epic", Color = { 0.68, 0.40, 0.95 }, Weight = 13 },
	{ Name = "Legendary", Color = { 1.00, 0.80, 0.20 }, Weight = 7 },
	{ Name = "Mythic", Color = { 1.00, 0.35, 0.55 }, Weight = 3 },
	{ Name = "Secret", Color = { 0.25, 0.90, 0.90 }, Weight = 1.5 },
	{ Name = "Brainrot God", Color = { 1.00, 0.55, 0.05 }, Weight = 0.5 },
}

-- Fuse ladder: three of one tier become one of the next tier up.
BrainrotData.FUSE_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

BrainrotData.MUTATIONS = {
	{ Name = "Golden", Color = { 1.00, 0.85, 0.20 }, Chance = 0.04, IncomeMult = 2, CostMult = 1.5, Mark = "★" },
	{ Name = "Rainbow", Color = { 0.90, 0.40, 1.00 }, Chance = 0.008, IncomeMult = 5, CostMult = 3, Mark = "◆" },
	{ Name = "Diamond", Color = { 0.65, 0.90, 1.00 }, Chance = 0.0015, IncomeMult = 10, CostMult = 5, Mark = "♦" },
}

-- Missions: five goals in order, each with a cash reward claimed once.
-- Key names a progress counter on the player state; Goal is its target.
BrainrotData.MISSIONS = {
	{ Id = "buy1", Text = "Beli 1 brainrot di karpet merah", Reward = 250, Key = "Bought", Goal = 1 },
	{ Id = "collect1000", Text = "Kumpulkan $1.000 total dari base", Reward = 500, Key = "CollectedTotal", Goal = 1000 },
	{ Id = "steal1", Text = "Curi 1 brainrot dari base lain", Reward = 1000, Key = "Stolen", Goal = 1 },
	{ Id = "gear1", Text = "Beli 1 gear di Coins Shop", Reward = 750, Key = "GearBought", Goal = 1 },
	{ Id = "rebirth1", Text = "Rebirth 1x", Reward = 5000, Key = "Rebirths", Goal = 1 },
}

-- Id, Name, Rarity, Cost, IncomePerSec, Scale, BodyColor, Props
BrainrotData.CHARACTERS = {
	{
		Id = "tahu-gejrot", Name = "Tahu Gejrot", Rarity = "Common", Cost = 50, Income = 1, Scale = 1.0,
		Body = { 0.98, 0.92, 0.78 },
		Props = {
			{ "Block", { 1.6, 0.7, 1.6 }, { 0, 1.7, 0 }, { 1.00, 1.00, 0.95 } },
			{ "Wedge", { 0.5, 1.0, 0.5 }, { 0.7, 2.1, 0 }, { 0.90, 0.10, 0.10 } },
			{ "Ball", { 0.4, 0.4, 0.4 }, { -0.6, 2.0, 0.3 }, { 0.20, 0.70, 0.20 } },
		},
	},
	{
		Id = "es-teh-manis", Name = "Es Teh Manis", Rarity = "Common", Cost = 120, Income = 2, Scale = 1.0,
		Body = { 0.85, 0.55, 0.25 },
		Props = {
			{ "Cylinder", { 1.1, 1.8, 1.1 }, { 0, 1.6, 0 }, { 0.95, 0.85, 0.70 } },
			{ "Cylinder", { 0.18, 2.2, 0.18 }, { 0.5, 2.2, 0 }, { 0.95, 0.30, 0.35 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { -0.3, 2.4, 0.2 }, { 0.70, 0.90, 1.00 } },
		},
	},
	{
		Id = "bakso-beranak", Name = "Bakso Beranak", Rarity = "Common", Cost = 250, Income = 4, Scale = 1.1,
		Body = { 0.72, 0.50, 0.32 },
		Props = {
			{ "Cylinder", { 2.2, 0.9, 2.2 }, { 0, 1.5, 0 }, { 0.20, 0.35, 0.90 } },
			{ "Ball", { 0.9, 0.9, 0.9 }, { -0.5, 2.0, 0.2 }, { 0.85, 0.65, 0.45 } },
			{ "Ball", { 0.6, 0.6, 0.6 }, { 0.5, 1.9, -0.2 }, { 0.85, 0.65, 0.45 } },
			{ "Ball", { 0.45, 0.45, 0.45 }, { 0.1, 2.2, 0.4 }, { 0.85, 0.65, 0.45 } },
		},
	},
	{
		Id = "krupuk-terbang", Name = "Krupuk Terbang", Rarity = "Rare", Cost = 600, Income = 12, Scale = 1.1,
		Body = { 0.95, 0.75, 0.45 },
		Props = {
			{ "Cylinder", { 2.6, 0.25, 2.6 }, { 0, 1.2, 0 }, { 1.00, 0.90, 0.70 } },
			{ "Block", { 1.8, 0.12, 0.9 }, { -1.6, 1.4, 0 }, { 1.00, 1.00, 1.00 } },
			{ "Block", { 1.8, 0.12, 0.9 }, { 1.6, 1.4, 0 }, { 1.00, 1.00, 1.00 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { 0, 1.9, 0 }, { 0.90, 0.20, 0.20 } },
		},
	},
	{
		Id = "sate-klopo", Name = "Sate Klopo", Rarity = "Rare", Cost = 1000, Income = 22, Scale = 1.1,
		Body = { 0.60, 0.40, 0.25 },
		Props = {
			{ "Cylinder", { 0.16, 3.4, 0.16 }, { 0, 1.8, 0 }, { 0.85, 0.70, 0.45 } },
			{ "Block", { 0.9, 0.9, 0.9 }, { -0.7, 1.4, 0 }, { 0.75, 0.45, 0.20 } },
			{ "Block", { 0.9, 0.9, 0.9 }, { 0, 1.9, 0 }, { 0.75, 0.45, 0.20 } },
			{ "Block", { 0.9, 0.9, 0.9 }, { 0.7, 1.4, 0 }, { 0.75, 0.45, 0.20 } },
		},
	},
	{
		Id = "es-cendol", Name = "Es Cendol Segar", Rarity = "Rare", Cost = 900, Income = 18, Scale = 1.1,
		Body = { 0.35, 0.80, 0.45 },
		Props = {
			{ "Cylinder", { 1.3, 1.9, 1.3 }, { 0, 1.6, 0 }, { 0.90, 1.00, 0.90 } },
			{ "Ball", { 0.45, 0.45, 0.45 }, { -0.4, 2.3, 0.2 }, { 0.20, 0.85, 0.35 } },
			{ "Ball", { 0.45, 0.45, 0.45 }, { 0.3, 2.4, -0.1 }, { 0.20, 0.85, 0.35 } },
			{ "Cylinder", { 0.16, 2.0, 0.16 }, { 0.6, 2.2, 0 }, { 1.00, 0.40, 0.60 } },
		},
	},
	{
		Id = "mie-ayam", Name = "Mie Ayam Mantap", Rarity = "Rare", Cost = 1500, Income = 32, Scale = 1.2,
		Body = { 0.95, 0.80, 0.30 },
		Props = {
			{ "Cylinder", { 2.3, 0.9, 2.3 }, { 0, 1.5, 0 }, { 0.90, 0.30, 0.30 } },
			{ "Cylinder", { 1.7, 0.4, 1.7 }, { 0, 2.0, 0 }, { 1.00, 0.90, 0.55 } },
			{ "Cylinder", { 0.14, 2.4, 0.14 }, { -0.5, 2.4, 0.3 }, { 0.85, 0.65, 0.35 } },
			{ "Cylinder", { 0.14, 2.4, 0.14 }, { 0.5, 2.4, -0.3 }, { 0.85, 0.65, 0.35 } },
		},
	},
	{
		Id = "pisang-goreng", Name = "Pisang Goreng Manis", Rarity = "Rare", Cost = 1800, Income = 38, Scale = 1.2,
		Body = { 0.95, 0.80, 0.30 },
		Props = {
			{ "Wedge", { 1.4, 1.6, 0.6 }, { -0.6, 1.8, 0 }, { 1.00, 0.85, 0.30 } },
			{ "Wedge", { 1.4, 1.6, 0.6 }, { 0.6, 1.8, 0 }, { 1.00, 0.75, 0.20 } },
			{ "Cylinder", { 2.2, 0.5, 2.2 }, { 0, 1.4, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { 0, 2.5, 0.2 }, { 0.55, 0.30, 0.10 } },
		},
	},
	{
		Id = "es-kelapa", Name = "Es Kelapa Muda", Rarity = "Rare", Cost = 1400, Income = 28, Scale = 1.1,
		Body = { 0.35, 0.75, 0.35 },
		Props = {
			{ "Ball", { 2.2, 1.8, 2.2 }, { 0, 1.6, 0 }, { 0.85, 0.65, 0.45 } },
			{ "Cylinder", { 0.18, 2.2, 0.18 }, { 0.5, 2.3, 0 }, { 1.00, 0.40, 0.50 } },
			{ "Ball", { 0.6, 0.6, 0.6 }, { -0.5, 2.5, 0.2 }, { 1.00, 1.00, 1.00 } },
			{ "Ball", { 0.4, 0.4, 0.4 }, { 0.4, 2.4, -0.2 }, { 0.20, 0.85, 0.35 } },
		},
	},
	{
		Id = "lumpia-semarang", Name = "Lumpia Semarang", Rarity = "Rare", Cost = 2000, Income = 42, Scale = 1.2,
		Body = { 0.90, 0.70, 0.40 },
		Props = {
			{ "Cylinder", { 1.0, 2.6, 1.0 }, { -0.6, 1.8, 0 }, { 0.95, 0.85, 0.60 } },
			{ "Cylinder", { 1.0, 2.6, 1.0 }, { 0.6, 1.8, 0 }, { 0.90, 0.75, 0.45 } },
			{ "Ball", { 0.7, 0.5, 0.7 }, { 0, 2.6, 0 }, { 0.85, 0.30, 0.15 } },
			{ "Block", { 2.2, 0.3, 1.4 }, { 0, 1.3, 0 }, { 0.95, 0.95, 0.95 } },
		},
	},
	{
		Id = "nasi-goreng", Name = "Nasi Goreng Gila", Rarity = "Epic", Cost = 2200, Income = 60, Scale = 1.2,
		Body = { 0.95, 0.65, 0.30 },
		Props = {
			{ "Cylinder", { 2.4, 0.5, 2.4 }, { 0, 1.5, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Cylinder", { 1.5, 0.3, 1.5 }, { 0, 1.9, 0 }, { 1.00, 1.00, 1.00 } },
			{ "Ball", { 0.8, 0.4, 0.8 }, { 0, 2.1, 0 }, { 1.00, 0.75, 0.10 } },
			{ "Block", { 0.3, 0.9, 0.3 }, { 0.9, 1.9, 0.4 }, { 0.90, 0.15, 0.15 } },
		},
	},
	{
		Id = "martabak-manis", Name = "Martabak Manis", Rarity = "Epic", Cost = 4000, Income = 105, Scale = 1.3,
		Body = { 0.70, 0.50, 0.30 },
		Props = {
			{ "Wedge", { 2.4, 1.1, 2.0 }, { 0, 1.6, 0 }, { 0.85, 0.65, 0.35 } },
			{ "Ball", { 0.35, 0.35, 0.35 }, { -0.7, 2.2, 0.3 }, { 0.30, 0.15, 0.10 } },
			{ "Ball", { 0.35, 0.35, 0.35 }, { 0.1, 2.3, -0.2 }, { 0.30, 0.15, 0.10 } },
			{ "Ball", { 0.35, 0.35, 0.35 }, { 0.7, 2.2, 0.3 }, { 0.30, 0.15, 0.10 } },
			{ "Block", { 2.0, 0.3, 0.4 }, { 0, 1.2, 0.9 }, { 0.95, 0.85, 0.55 } },
		},
	},
	{
		Id = "gado-gado", Name = "Gado-Gado Juara", Rarity = "Epic", Cost = 3200, Income = 85, Scale = 1.2,
		Body = { 0.40, 0.85, 0.35 },
		Props = {
			{ "Cylinder", { 2.4, 0.5, 2.4 }, { 0, 1.5, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Ball", { 1.0, 0.6, 1.0 }, { 0, 1.9, 0 }, { 0.80, 0.55, 0.25 } },
			{ "Block", { 0.7, 0.7, 0.7 }, { -0.7, 2.1, 0.2 }, { 0.30, 0.70, 0.30 } },
			{ "Block", { 0.7, 0.7, 0.7 }, { 0.7, 2.1, -0.2 }, { 0.90, 0.85, 0.60 } },
		},
	},
	{
		Id = "soto-ayam", Name = "Soto Ayam Panas", Rarity = "Epic", Cost = 6000, Income = 150, Scale = 1.3,
		Body = { 0.95, 0.80, 0.25 },
		Props = {
			{ "Cylinder", { 2.3, 1.0, 2.3 }, { 0, 1.5, 0 }, { 0.95, 0.90, 0.75 } },
			{ "Ball", { 0.5, 1.0, 0.5 }, { -0.4, 2.4, 0 }, { 0.90, 0.90, 0.90 } },
			{ "Ball", { 0.5, 1.0, 0.5 }, { 0.4, 2.4, 0 }, { 0.90, 0.90, 0.90 } },
			{ "Block", { 1.2, 0.25, 0.35 }, { 0.9, 2.0, 0.5 }, { 0.70, 0.70, 0.70 } },
		},
	},
	{
		Id = "sate-ayam", Name = "Sate Ayam Madura", Rarity = "Epic", Cost = 5500, Income = 140, Scale = 1.3,
		Body = { 0.55, 0.40, 0.25 },
		Props = {
			{ "Cylinder", { 0.16, 3.4, 0.16 }, { -0.4, 1.8, 0 }, { 0.85, 0.70, 0.45 } },
			{ "Cylinder", { 0.16, 3.4, 0.16 }, { 0.4, 1.8, 0 }, { 0.85, 0.70, 0.45 } },
			{ "Block", { 0.8, 0.8, 0.8 }, { -0.4, 1.5, 0 }, { 0.80, 0.50, 0.20 } },
			{ "Block", { 0.8, 0.8, 0.8 }, { 0.4, 1.9, 0 }, { 0.80, 0.50, 0.20 } },
			{ "Ball", { 1.0, 0.6, 1.0 }, { 0, 1.3, 0.5 }, { 0.75, 0.45, 0.15 } },
		},
	},
	{
		Id = "rawon", Name = "Rawon Surabaya", Rarity = "Epic", Cost = 7000, Income = 175, Scale = 1.3,
		Body = { 0.30, 0.25, 0.20 },
		Props = {
			{ "Cylinder", { 2.4, 1.0, 2.4 }, { 0, 1.5, 0 }, { 0.95, 0.90, 0.75 } },
			{ "Cylinder", { 1.9, 0.6, 1.9 }, { 0, 1.9, 0 }, { 0.15, 0.10, 0.08 } },
			{ "Ball", { 0.6, 0.4, 0.6 }, { -0.4, 2.2, 0.2 }, { 0.90, 0.90, 0.85 } },
			{ "Block", { 0.4, 1.0, 0.4 }, { 0.8, 2.1, -0.2 }, { 0.30, 0.70, 0.30 } },
		},
	},
	{
		Id = "nasi-uduk", Name = "Nasi Uduk Betawi", Rarity = "Epic", Cost = 4800, Income = 125, Scale = 1.2,
		Body = { 0.95, 0.85, 0.25 },
		Props = {
			{ "Wedge", { 1.8, 2.0, 1.8 }, { 0, 2.0, 0 }, { 1.00, 0.95, 0.85 } },
			{ "Cylinder", { 2.4, 0.4, 2.4 }, { 0, 1.4, 0 }, { 0.20, 0.70, 0.35 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { -0.7, 1.8, 0.3 }, { 0.85, 0.60, 0.30 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { 0.7, 1.8, -0.3 }, { 0.90, 0.15, 0.15 } },
		},
	},
	{
		Id = "durian-runtuh", Name = "Durian Runtuh", Rarity = "Legendary", Cost = 9000, Income = 260, Scale = 1.4,
		Body = { 0.35, 0.75, 0.20 },
		Props = {
			{ "Wedge", { 0.5, 1.1, 0.5 }, { 0, 2.3, 0 }, { 0.25, 0.60, 0.15 } },
			{ "Wedge", { 0.5, 1.1, 0.5 }, { -0.9, 1.9, 0.4 }, { 0.25, 0.60, 0.15 } },
			{ "Wedge", { 0.5, 1.1, 0.5 }, { 0.9, 1.9, -0.4 }, { 0.25, 0.60, 0.15 } },
			{ "Wedge", { 0.5, 1.1, 0.5 }, { 0.4, 1.9, 0.9 }, { 0.25, 0.60, 0.15 } },
			{ "Wedge", { 0.5, 1.1, 0.5 }, { -0.4, 1.9, -0.9 }, { 0.25, 0.60, 0.15 } },
		},
	},
	{
		Id = "rendang-abadi", Name = "Rendang Abadi", Rarity = "Legendary", Cost = 16000, Income = 460, Scale = 1.4,
		Body = { 0.45, 0.30, 0.20 },
		Props = {
			{ "Cylinder", { 2.4, 0.5, 2.4 }, { 0, 1.5, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Ball", { 1.2, 0.7, 1.2 }, { 0, 1.9, 0 }, { 0.55, 0.30, 0.12 } },
			{ "Block", { 0.9, 0.9, 0.9 }, { 0, 2.4, 0 }, { 0.40, 0.20, 0.08 } },
			{ "Ball", { 0.4, 0.4, 0.4 }, { 0.8, 2.1, 0.3 }, { 0.90, 0.15, 0.15 } },
		},
	},
	{
		Id = "ayam-geprek", Name = "Ayam Geprek Pedas", Rarity = "Legendary", Cost = 12000, Income = 340, Scale = 1.4,
		Body = { 0.95, 0.55, 0.25 },
		Props = {
			{ "Ball", { 1.1, 1.1, 1.1 }, { -0.5, 1.7, 0 }, { 0.85, 0.60, 0.30 } },
			{ "Cylinder", { 0.35, 1.6, 0.35 }, { 0.9, 1.7, 0 }, { 0.95, 0.95, 0.90 } },
			{ "Wedge", { 0.5, 1.2, 0.5 }, { 0.3, 2.3, 0 }, { 0.95, 0.10, 0.10 } },
			{ "Wedge", { 0.5, 1.2, 0.5 }, { -0.8, 2.3, 0.3 }, { 0.95, 0.10, 0.10 } },
		},
	},
	{
		Id = "pempek", Name = "Pempek Palembang", Rarity = "Legendary", Cost = 22000, Income = 620, Scale = 1.5,
		Body = { 0.90, 0.80, 0.60 },
		Props = {
			{ "Cylinder", { 1.8, 0.8, 1.8 }, { 0, 1.8, 0 }, { 0.85, 0.70, 0.45 } },
			{ "Cylinder", { 0.9, 0.9, 0.9 }, { 1.2, 1.7, 0 }, { 0.30, 0.20, 0.10 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { -0.9, 2.1, 0.3 }, { 0.95, 0.85, 0.40 } },
		},
	},
	{
		Id = "gudeg", Name = "Gudeg Jogja", Rarity = "Legendary", Cost = 20000, Income = 580, Scale = 1.4,
		Body = { 0.40, 0.30, 0.20 },
		Props = {
			{ "Cylinder", { 2.2, 1.1, 2.2 }, { 0, 1.6, 0 }, { 0.90, 0.85, 0.70 } },
			{ "Ball", { 1.1, 0.7, 1.1 }, { 0, 2.1, 0 }, { 0.55, 0.35, 0.15 } },
			{ "Ball", { 0.6, 0.6, 0.6 }, { -0.6, 2.4, 0.2 }, { 1.00, 0.95, 0.85 } },
			{ "Ball", { 0.4, 0.4, 0.4 }, { 0.7, 2.3, -0.2 }, { 0.90, 0.15, 0.15 } },
		},
	},
	{
		Id = "bebek-madura", Name = "Bebek Madura", Rarity = "Legendary", Cost = 26000, Income = 720, Scale = 1.5,
		Body = { 0.85, 0.55, 0.25 },
		Props = {
			{ "Cylinder", { 0.5, 2.2, 0.5 }, { -0.7, 1.9, 0 }, { 0.90, 0.70, 0.40 } },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0.7, 1.8, 0 }, { 0.80, 0.55, 0.25 } },
			{ "Wedge", { 0.5, 1.1, 0.5 }, { 0.2, 2.4, 0 }, { 0.95, 0.10, 0.10 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { -0.9, 2.4, 0.3 }, { 0.20, 0.70, 0.20 } },
		},
	},
	{
		Id = "soto-betawi", Name = "Soto Betawi", Rarity = "Legendary", Cost = 18000, Income = 520, Scale = 1.4,
		Body = { 0.95, 0.85, 0.25 },
		Props = {
			{ "Cylinder", { 2.3, 1.0, 2.3 }, { 0, 1.5, 0 }, { 0.95, 0.90, 0.75 } },
			{ "Ball", { 0.9, 0.6, 0.9 }, { 0, 1.9, 0 }, { 1.00, 0.90, 0.70 } },
			{ "Block", { 0.6, 0.6, 0.6 }, { -0.6, 2.1, 0.2 }, { 0.60, 0.35, 0.15 } },
			{ "Block", { 0.6, 0.6, 0.6 }, { 0.6, 2.1, -0.2 }, { 0.60, 0.35, 0.15 } },
		},
	},
	{
		Id = "kopi-tubruk", Name = "Kopi Tubruk Titan", Rarity = "Mythic", Cost = 45000, Income = 1250, Scale = 1.6,
		Body = { 0.25, 0.15, 0.12 },
		Props = {
			{ "Cylinder", { 1.6, 1.7, 1.6 }, { 0, 1.7, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Cylinder", { 1.3, 1.5, 1.3 }, { 0, 1.8, 0 }, { 0.20, 0.12, 0.08 } },
			{ "Cylinder", { 0.25, 1.0, 0.25 }, { 0.9, 1.8, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Ball", { 0.45, 1.1, 0.45 }, { -0.4, 2.8, 0 }, { 0.95, 0.95, 0.95 } },
			{ "Ball", { 0.45, 1.1, 0.45 }, { 0.4, 2.9, 0 }, { 0.95, 0.95, 0.95 } },
		},
	},
	{
		Id = "sambal-petir", Name = "Sambal Petir", Rarity = "Mythic", Cost = 80000, Income = 2300, Scale = 1.7,
		Body = { 0.90, 0.15, 0.15 },
		Props = {
			{ "Wedge", { 0.6, 1.6, 0.6 }, { -0.6, 1.9, 0 }, { 0.95, 0.10, 0.10 } },
			{ "Wedge", { 0.6, 1.6, 0.6 }, { 0.6, 2.1, 0 }, { 1.00, 0.85, 0.10 } },
			{ "Wedge", { 0.5, 1.2, 0.5 }, { 0, 2.5, 0 }, { 1.00, 0.85, 0.10 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { 0.9, 1.5, 0.3 }, { 0.20, 0.70, 0.20 } },
		},
	},
	{
		Id = "ikan-bakar", Name = "Ikan Bakar Jimbaran", Rarity = "Mythic", Cost = 60000, Income = 1700, Scale = 1.6,
		Body = { 0.45, 0.55, 0.65 },
		Props = {
			{ "Ball", { 2.2, 1.0, 1.0 }, { 0, 1.6, 0 }, { 0.55, 0.60, 0.65 } },
			{ "Wedge", { 1.0, 1.2, 0.3 }, { 1.4, 1.6, 0 }, { 0.55, 0.60, 0.65 } },
			{ "Block", { 0.9, 1.3, 0.2 }, { -0.3, 2.2, 0 }, { 0.90, 0.40, 0.20 } },
			{ "Ball", { 0.4, 0.4, 0.4 }, { -0.9, 1.9, 0.3 }, { 0.10, 0.10, 0.10 } },
		},
	},
	{
		Id = "cumi-bakar", Name = "Cumi Bakar Pedas", Rarity = "Mythic", Cost = 70000, Income = 2000, Scale = 1.6,
		Body = { 0.90, 0.70, 0.50 },
		Props = {
			{ "Cylinder", { 0.35, 2.0, 0.35 }, { -0.8, 1.2, 0 }, { 0.95, 0.85, 0.75 } },
			{ "Cylinder", { 0.35, 2.0, 0.35 }, { -0.3, 1.1, 0.3 }, { 0.95, 0.85, 0.75 } },
			{ "Cylinder", { 0.35, 2.0, 0.35 }, { 0.3, 1.1, -0.3 }, { 0.95, 0.85, 0.75 } },
			{ "Cylinder", { 0.35, 2.0, 0.35 }, { 0.8, 1.2, 0 }, { 0.95, 0.85, 0.75 } },
			{ "Block", { 2.4, 0.4, 1.2 }, { 0, 2.2, 0 }, { 0.30, 0.30, 0.35 } },
		},
	},
	{
		Id = "nasi-padang", Name = "Nasi Padang Semesta", Rarity = "Secret", Cost = 220000, Income = 8500, Scale = 1.9,
		Body = { 0.95, 0.95, 0.95 },
		Props = {
			{ "Wedge", { 1.6, 1.8, 1.6 }, { 0, 2.0, 0 }, { 1.00, 0.95, 0.80 } },
			{ "Cylinder", { 3.4, 0.25, 3.4 }, { 0, 2.6, 0 }, { 0.30, 0.60, 1.00 } },
			{ "Ball", { 0.7, 0.7, 0.7 }, { 1.5, 2.6, 0 }, { 1.00, 0.70, 0.20 } },
			{ "Ball", { 0.5, 0.5, 0.5 }, { -1.4, 2.7, 0.4 }, { 0.90, 0.30, 0.40 } },
		},
	},
	{
		Id = "nasi-tumpeng", Name = "Nasi Tumpeng Raja", Rarity = "Brainrot God", Cost = 400000, Income = 15000, Scale = 2.2,
		Body = { 1.00, 0.85, 0.20 },
		Props = {
			{ "Wedge", { 2.2, 2.6, 2.2 }, { 0, 2.2, 0 }, { 1.00, 0.85, 0.30 } },
			{ "Cylinder", { 1.0, 0.5, 1.0 }, { 0, 3.6, 0 }, { 1.00, 0.80, 0.10 } },
			{ "Wedge", { 0.5, 0.9, 0.5 }, { -0.7, 3.9, 0 }, { 1.00, 0.80, 0.10 } },
			{ "Wedge", { 0.5, 0.9, 0.5 }, { 0.7, 3.9, 0 }, { 1.00, 0.80, 0.10 } },
			{ "Cylinder", { 3.6, 0.25, 3.6 }, { 0, 1.4, 0 }, { 1.00, 0.75, 0.15 } },
		},
	},
}

-- Rebirth ladder: each level needs cash plus two NAMED characters.
BrainrotData.REBIRTHS = {
	{ Level = 1, Cost = 500000, Need = { "krupuk-terbang", "sate-klopo" } },
	{ Level = 2, Cost = 2000000, Need = { "nasi-goreng", "martabak-manis" } },
	{ Level = 3, Cost = 4500000, Need = { "durian-runtuh", "rendang-abadi" } },
	{ Level = 4, Cost = 8000000, Need = { "kopi-tubruk", "sambal-petir" } },
	{ Level = 5, Cost = 15000000, Need = { "nasi-padang", "nasi-tumpeng" } },
}

-- Gear sold for cash at the Coins Shop stall.
BrainrotData.GEAR = {
	{ Id = "slap", Name = "Slap", Cost = 500, Desc = "Knock a thief down. They drop what they carry." },
	{ Id = "coil", Name = "Speed Coil", Cost = 750, Desc = "+50% walk speed for 30 seconds." },
	{ Id = "trap", Name = "Trap", Cost = 1000, Desc = "Freeze a thief for 7 seconds. Max 3 active." },
}

-- Buff Shop: permanent per-session upgrades, max level 5 each.
-- Prices are per track, per level (level 1 costs Prices[1], etc.).
BrainrotData.UPGRADE_MAX = 5
BrainrotData.UPGRADES = {
	{ Id = "Luck", Name = "LUCK", Desc = "+15% bobot langka", Prices = { 1000, 2500, 6000, 15000, 35000 } },
	{ Id = "Income", Name = "INCOME", Desc = "+20% income", Prices = { 1000, 2500, 6000, 15000, 35000 } },
	{ Id = "Speed", Name = "SPEED", Desc = "+2 WalkSpeed", Prices = { 1000, 2500, 6000, 15000, 35000 } },
}

function BrainrotData.FindCharacter(id)
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

function BrainrotData.FindRarity(name)
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		if rarity.Name == name then
			return rarity
		end
	end
	return BrainrotData.RARITIES[1]
end

function BrainrotData.RarityColor(name)
	local rarity = BrainrotData.FindRarity(name)
	return rarity.Color
end

function BrainrotData.IncomeFor(def, mutationName, rebirthLevel, eventMult)
	local income = def.Income
	for _, mut in ipairs(BrainrotData.MUTATIONS) do
		if mut.Name == mutationName then
			income = income * mut.IncomeMult
		end
	end
	income = income * (1 + 0.5 * rebirthLevel)
	income = income * eventMult
	return math.floor(income)
end

function BrainrotData.RollRarity(luckLevel)
	luckLevel = luckLevel or 0
	-- Luck multiplies every non-Common weight by (1 + 0.15 x level);
	-- the roll below normalises against the new total.
	local mult = 1 + 0.15 * luckLevel
	local function weight(rarity)
		if rarity.Name == "Common" then
			return rarity.Weight
		end
		return rarity.Weight * mult
	end
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		total = total + weight(rarity)
	end
	local roll = math.random() * total
	local acc = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		acc = acc + weight(rarity)
		if roll <= acc then
			return rarity.Name
		end
	end
	return "Common"
end

function BrainrotData.RollCharacterOfRarity(rarityName)
	local pool = {}
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.Rarity == rarityName then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		return BrainrotData.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Fixed in r3: chances accumulate (Golden 4%, then Rainbow 0.8%, then
-- Diamond 0.15%). The old code compared the raw roll against each
-- chance in turn, so Rainbow and Diamond could never roll.
function BrainrotData.RollMutation()
	local roll = math.random()
	local acc = 0
	for _, mut in ipairs(BrainrotData.MUTATIONS) do
		acc = acc + mut.Chance
		if roll <= acc then
			return mut.Name
		end
	end
	return ""
end

function BrainrotData.MutationMark(mutationName)
	for _, mut in ipairs(BrainrotData.MUTATIONS) do
		if mut.Name == mutationName then
			return mut.Mark
		end
	end
	return ""
end

-- Next tier up the fuse ladder, or nil when the rarity cannot fuse.
function BrainrotData.NextRarity(rarityName)
	for i, name in ipairs(BrainrotData.FUSE_ORDER) do
		if name == rarityName then
			return BrainrotData.FUSE_ORDER[i + 1]
		end
	end
	return nil
end

return BrainrotData
