-- World: build the night-market plaza at runtime. Bases are kiosks with
-- low walls on three sides, an awning roof, an owner board, a visible
-- laser gate and a green COLLECT pad out front. Stalls, string lights,
-- lamp posts, the Coins Shop stall, the Fuse Machine and the Top-5
-- leaderboard board fill the plaza around them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local World = {}
World.Bases = {}
World.EventLabel = nil

local function part(parent, name, size, pos, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(size[1], size[2], size[3])
	p.Position = Vector3.new(pos[1], pos[2], pos[3])
	p.Color = Color3.new(color[1], color[2], color[3])
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.Parent = parent
	return p
end

local function boardLabel(parent, name, text, size, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.new(0, size[1], 0, size[2])
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.new(0.06, 0.09, 0.16)
	label.BackgroundTransparency = 0.1
	label.Text = text
	label.TextColor3 = Color3.new(color[1], color[2], color[3])
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return label
end

function World.BuildBase(index, def)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(index)
	folder.Parent = workspace
	local x = def.X
	local z = def.Z
	local c = def.Color
	part(folder, "Platform", { 40, 1, 28 }, { x, 0.5, z }, { 0.22, 0.22, 0.28 }, Enum.Material.Cobblestone)
	part(folder, "Trim", { 40, 0.4, 1 }, { x, 1.1, z + 13.5 }, c, Enum.Material.Neon)
	local doorSide = 1
	if x > 0 then
		doorSide = -1
	end
	-- Back wall (opposite the door), left and right walls; door faces the plaza.
	part(folder, "WallBack", { 40, 5, 1 }, { x - doorSide * 19.5, 3.5, z }, c, Enum.Material.SmoothPlastic)
	part(folder, "WallLeft", { 1, 5, 28 }, { x, 3.5, z - 13.5 }, c, Enum.Material.SmoothPlastic)
	part(folder, "WallRight", { 1, 5, 28 }, { x, 3.5, z + 13.5 }, c, Enum.Material.SmoothPlastic)
	-- Awning roof in the base colour, held by four posts.
	part(folder, "Awning", { 42, 0.6, 30 }, { x, 7.5, z }, c, Enum.Material.Fabric)
	part(folder, "Post1", { 1, 6, 1 }, { x - doorSide * 18, 4, z - 12 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	part(folder, "Post2", { 1, 6, 1 }, { x - doorSide * 18, 4, z + 12 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	part(folder, "Post3", { 1, 6, 1 }, { x + doorSide * 18, 4, z - 12 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	part(folder, "Post4", { 1, 6, 1 }, { x + doorSide * 18, 4, z + 12 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	-- Owner board above the door.
	local board = part(folder, "OwnerBoard", { 10, 3, 0.6 }, { x + doorSide * 19, 6.5, z }, { 0.06, 0.09, 0.16 }, Enum.Material.SmoothPlastic)
	-- Name only when claimed, direction only when empty (play-test
	-- 19 Nov: "BASE NE" piled onto the HUD at some camera angles;
	-- the shorter label stays clear).
	boardLabel(board, "OwnerLabel", def.Name, { 120, 28 }, { 1, 1, 1 })
	-- Laser gate filling the WHOLE door gap (28 studs wide); hidden
	-- until the base is locked, and solid (CanCollide) while locked so
	-- nobody can walk into a locked base at all.
	local laser = part(folder, "LaserGate", { 0.6, 5, 28 }, { x + doorSide * 19.5, 3.5, z }, { 1, 0.1, 0.1 }, Enum.Material.Neon)
	laser.Transparency = 1
	laser.CanCollide = false
	-- Green COLLECT pad at the OUTER corner of the platform.
	-- Play-test 19 Nov: the old inner-corner pads (x = ±4, 8 studs
	-- apart) made both "COLLECT $0" labels print on top of each
	-- other as "COLLICOLLECT $0". Outer corners are 88 studs apart.
	local padX = x - doorSide * 14
	local collect = part(folder, "CollectPad", { 10, 0.6, 8 }, { padX, 1.3, z }, { 0.15, 0.85, 0.25 }, Enum.Material.Neon)
	collect.Name = "CollectPad"
	-- No floating "COLLECT $0" label here (declutter 19 Nov: it
	-- duplicated the HUD money panel and the two pads' labels piled
	-- onto each other). The pad glows green and the money panel
	-- says "Pile: $X".
	local click = Instance.new("ClickDetector")
	click.Name = "CollectClick"
	click.Parent = collect
	-- Twelve pads in three rows of four (rebirth grows slots to 12).
	local pads = {}
	local slot = 1
	for row = 1, 3 do
		for col = 1, 4 do
			local px = x + (col - 2.5) * 8
			local pz = z + (row - 2) * 8
			local pad = part(folder, "Pad" .. tostring(slot), { 6, 0.5, 6 }, { px, 1.25, pz }, { 0.35, 0.35, 0.45 }, Enum.Material.SmoothPlastic)
			pad.Name = "Pad" .. tostring(slot)
			local padClick = Instance.new("ClickDetector")
			padClick.Name = "PadClick"
			padClick.Parent = pad
			pads[slot] = pad
			slot = slot + 1
		end
	end
	-- Coin pile on the collect pad, grows with the pending pile.
	local coins = {}
	for i = 1, 8 do
		local coin = part(folder, "Coin" .. tostring(i), { 1.6, 0.4, 1.6 }, { padX - 3 + (i - 1) * 0.9, 1.8, z - 2 }, { 1, 0.85, 0.2 }, Enum.Material.Metal)
		coin.Shape = Enum.PartType.Cylinder
		coin.Transparency = 1
		coins[i] = coin
	end
	World.Bases[index] = {
		Def = def, Folder = folder, Pads = pads, Laser = laser,
		Board = board, CollectPad = collect, Coins = coins, OwnerId = 0,
	}
	return World.Bases[index]
end

function World.BuildStall(x, z, colorA, colorB)
	local folder = Instance.new("Folder")
	folder.Name = "Stall"
	folder.Parent = workspace
	part(folder, "Counter", { 10, 3, 5 }, { x, 1.5, z }, { 0.45, 0.32, 0.20 }, Enum.Material.Wood)
	part(folder, "PostA", { 0.8, 7, 0.8 }, { x - 4.5, 3.5, z - 2 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	part(folder, "PostB", { 0.8, 7, 0.8 }, { x + 4.5, 3.5, z - 2 }, { 0.4, 0.3, 0.2 }, Enum.Material.Wood)
	for i = 1, 5 do
		local stripe = colorA
		if i % 2 == 0 then
			stripe = colorB
		end
		part(folder, "Awning" .. tostring(i), { 2.2, 0.4, 6 }, { x - 4.4 + (i - 1) * 2.2, 7.2, z }, stripe, Enum.Material.Fabric)
	end
	part(folder, "Crate", { 3, 3, 3 }, { x + 6, 1.5, z + 2 }, { 0.55, 0.40, 0.22 }, Enum.Material.Wood)
	part(folder, "Barrel", { 3, 4, 3 }, { x - 6.5, 2, z + 2 }, { 0.35, 0.35, 0.40 }, Enum.Material.Metal)
end

function World.BuildLamp(x, z)
	local folder = Instance.new("Folder")
	folder.Name = "Lamp"
	folder.Parent = workspace
	part(folder, "Pole", { 0.8, 9, 0.8 }, { x, 4.5, z }, { 0.15, 0.15, 0.18 }, Enum.Material.Metal)
	local bulb = part(folder, "Bulb", { 1.6, 1.6, 1.6 }, { x, 9.4, z }, { 1, 0.85, 0.45 }, Enum.Material.Neon)
	bulb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = Color3.new(1, 0.8, 0.45)
	light.Range = 30
	light.Brightness = 3
	light.Parent = bulb
end

-- Neon chevrons on the ground from spawn to the conveyor, so the
-- player always knows which way to walk (play-test 19 Nov: the
-- camera snags on models/walls and the player loses orientation).
-- Each chevron is a V of two angled neon slabs pointing north (-Z).
function World.BuildChevrons()
	local folder = Instance.new("Folder")
	folder.Name = "Chevrons"
	folder.Parent = workspace
	for _, z in ipairs({ 32, 26, 14 }) do
		for _, side in ipairs({ -1, 1 }) do
			-- Rotation -side*40 makes the two arms meet at the
			-- north end, so the V points toward the conveyor (-Z).
			local arm = Instance.new("Part")
			arm.Name = "Chevron"
			arm.Size = Vector3.new(3.5, 0.3, 1.2)
			arm.CFrame = CFrame.new(side * 1, 0.15, z + 0.8) * CFrame.Angles(0, math.rad(-side * 40), 0)
			arm.Color = Color3.new(0.64, 0.90, 0.21)
			arm.Material = Enum.Material.Neon
			arm.Anchored = true
			arm.CanCollide = false
			arm.Parent = folder
		end
	end
end

function World.BuildGearStall()
	local pos = Config.GearStallPosition
	local folder = Instance.new("Folder")
	folder.Name = "GearStall"
	folder.Parent = workspace
	part(folder, "Counter", { 14, 3, 6 }, { pos[1], 1.5, pos[2] }, { 0.15, 0.15, 0.20 }, Enum.Material.SmoothPlastic)
	part(folder, "Roof", { 16, 0.6, 8 }, { pos[1], 7, pos[2] }, { 1, 0.85, 0.2 }, Enum.Material.Fabric)
	local sign = part(folder, "Sign", { 12, 3, 0.6 }, { pos[1], 5.5, pos[2] + 3 }, { 0.06, 0.09, 0.16 }, Enum.Material.SmoothPlastic)
	-- Short label only (play-test 19 Nov: "COINS SHOP - GEAR"
	-- piled onto the HUD at some camera angles).
	boardLabel(sign, "GearLabel", "GEAR", { 140, 28 }, { 1, 0.85, 0.2 })
	local click = Instance.new("ClickDetector")
	click.Name = "GearClick"
	click.Parent = sign
end

-- Fuse Machine: feed it 3 brainrots of the same rarity, get 1 of the
-- next tier up. Clicking its sign opens the Fuse panel.
function World.BuildFuseMachine()
	local pos = Config.FuseMachinePosition
	local folder = Instance.new("Folder")
	folder.Name = "FuseMachine"
	folder.Parent = workspace
	part(folder, "Base", { 9, 1, 7 }, { pos[1], 0.5, pos[3] }, { 0.25, 0.25, 0.32 }, Enum.Material.Metal)
	part(folder, "Body", { 7, 6, 5 }, { pos[1], 4, pos[3] }, { 0.68, 0.40, 0.95 }, Enum.Material.SmoothPlastic)
	part(folder, "Chute", { 3, 2, 3 }, { pos[1], 7.5, pos[3] }, { 0.06, 0.09, 0.16 }, Enum.Material.Metal)
	part(folder, "Glow", { 7.2, 0.6, 5.2 }, { pos[1], 6.2, pos[3] }, { 1, 0.85, 0.2 }, Enum.Material.Neon)
	local sign = part(folder, "Sign", { 7, 2.2, 0.6 }, { pos[1], 9.5, pos[3] }, { 0.06, 0.09, 0.16 }, Enum.Material.SmoothPlastic)
	-- No floating "FUSE MACHINE" label (declutter 19 Nov: it
	-- duplicated the MENU > FUSE tab). The purple machine + glow
	-- marks it; clicking the sign opens the Fuse tab.
	local click = Instance.new("ClickDetector")
	click.Name = "FuseClick"
	click.Parent = sign
end

function World.BuildPityBoard()
	local folder = Instance.new("Folder")
	folder.Name = "PityBoard"
	folder.Parent = workspace
	local board = part(folder, "Board", { 26, 5, 1 }, { 0, 13, -40 }, { 0.06, 0.09, 0.16 }, Enum.Material.SmoothPlastic)
	-- Neon market sign with a dark backplate, above the conveyor.
	-- Smaller and higher than r3.0 (play-test 19 Nov: the 700px
	-- sign piled onto the HUD banner + pity text in the spawn view).
	local sign = part(folder, "NeonSign", { 16, 3, 1 }, { 0, 28, -42 }, { 0.06, 0.09, 0.16 }, Enum.Material.SmoothPlastic)
	local signGui = Instance.new("BillboardGui")
	signGui.Name = "NeonLabel"
	signGui.Size = UDim2.new(0, 480, 0, 80)
	signGui.StudsOffset = Vector3.new(0, 0, 0)
	signGui.AlwaysOnTop = false
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Name = "Text"
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "PASAR MALAM BRAINROT"
	signText.TextColor3 = Color3.new(0.64, 0.90, 0.21)
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.Parent = signGui
	-- Warm spotlight over the conveyor.
	local spot = part(folder, "SpotBase", { 2, 1, 2 }, { 0, 24, -34 }, { 0.2, 0.2, 0.25 }, Enum.Material.Metal)
	local spotLight = Instance.new("SpotLight")
	spotLight.Color = Color3.new(1, 0.9, 0.6)
	spotLight.Range = 40
	spotLight.Brightness = 3
	spotLight.Angle = 70
	spotLight.Face = Enum.NormalId.Bottom
	spotLight.Parent = spot
end

function World.BuildWorld()
	for i, def in ipairs(Config.BaseCenters) do
		World.BuildBase(i, def)
	end
	World.BuildStall(-58, -20, { 0.95, 0.30, 0.30 }, { 1, 1, 1 })
	World.BuildStall(58, -20, { 0.25, 0.55, 1.00 }, { 1, 1, 1 })
	World.BuildStall(-58, 8, { 1, 0.85, 0.2 }, { 0.20, 0.70, 0.35 })
	World.BuildStall(58, 8, { 0.85, 0.25, 0.55 }, { 1, 1, 1 })
	World.BuildStall(-58, 30, { 0.68, 0.40, 0.95 }, { 1, 1, 1 })
	World.BuildStall(58, 30, { 0.25, 0.90, 0.90 }, { 0.06, 0.09, 0.16 })
	World.BuildLamp(-14, -28)
	World.BuildLamp(14, -28)
	World.BuildLamp(-14, 28)
	World.BuildLamp(14, 28)
	-- Play-test 19 Nov: the lamp at (0,0) stood in the middle of the
	-- spawn-to-conveyor walkway and blocked the path. Moved east,
	-- clear of the NE platform (x >= 10) and the gear stall.
	World.BuildLamp(8, 0)
	-- Play-test round 2: the spawn-to-conveyor path and the areas
	-- around the bases were too dark. Four path lamps flank the
	-- chevron walkway (clear of the fuse machine, gear stall and
	-- base platforms).
	World.BuildLamp(-7, 26)
	World.BuildLamp(7, 26)
	World.BuildLamp(-9, -16)
	World.BuildLamp(9, -16)
	World.BuildChevrons()
	World.BuildGearStall()
	World.BuildFuseMachine()
	World.BuildPityBoard()
end

-- Pity countdown lives in the HUD now (Hud.TimerLabel); this stays as a
-- no-op so the init loop's call keeps working.
function World.SetPityText(text)
end

return World
