-- CharacterModels: build a distinct 3D model for a brainrot from its
-- BrainrotData definition. Every character shares a ball body, head and
-- eyes, but its signature prop parts give it a silhouette no other
-- character has. Labels are three separate lines on a dark backplate.
-- r3: mutations are VISIBLE - the body turns gold / ice-blue / rainbow
-- magenta with a Neon glow, and the label names the mutation and shows
-- the multiplied $/s. Labels never use AlwaysOnTop (HUD overlap rule).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local Format = require(ReplicatedStorage.Shared.Format)

local CharacterModels = {}

local function makePart(parent, name, shape, size, pos, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = Vector3.new(size[1], size[2], size[3])
	part.Position = pos
	part.Color = Color3.new(color[1], color[2], color[3])
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = false
	part.Parent = parent
	return part
end

function CharacterModels.BuildModel(def, mutation, position)
	local model = Instance.new("Model")
	model.Name = def.Name
	local scale = def.Scale
	local bodySize = 2.4 * scale
	local body = makePart(model, "Body", Enum.PartType.Ball, { bodySize, bodySize, bodySize },
		Vector3.new(position.X, position.Y + bodySize * 0.5, position.Z),
		def.Body, Enum.Material.SmoothPlastic)
	model.PrimaryPart = body
	local headSize = 1.5 * scale
	makePart(model, "Head", Enum.PartType.Ball, { headSize, headSize, headSize },
		Vector3.new(position.X, position.Y + bodySize * 0.95, position.Z),
		{ 1, 1, 1 }, Enum.Material.SmoothPlastic)
	local eyeSize = 0.34 * scale
	makePart(model, "EyeLeft", Enum.PartType.Ball, { eyeSize, eyeSize, eyeSize },
		Vector3.new(position.X - 0.45 * scale, position.Y + bodySize * 1.0, position.Z + headSize * 0.45),
		{ 0.05, 0.05, 0.05 }, Enum.Material.SmoothPlastic)
	makePart(model, "EyeRight", Enum.PartType.Ball, { eyeSize, eyeSize, eyeSize },
		Vector3.new(position.X + 0.45 * scale, position.Y + bodySize * 1.0, position.Z + headSize * 0.45),
		{ 0.05, 0.05, 0.05 }, Enum.Material.SmoothPlastic)
	for i, prop in ipairs(def.Props) do
		local kind = prop[1]
		local size = prop[2]
		local offset = prop[3]
		local color = prop[4]
		local shape = Enum.PartType.Block
		if kind == "Ball" then
			shape = Enum.PartType.Ball
		elseif kind == "Cylinder" then
			shape = Enum.PartType.Cylinder
		elseif kind == "Wedge" then
			shape = Enum.PartType.Wedge
		end
		local scaled = { size[1] * scale, size[2] * scale, size[3] * scale }
		local at = Vector3.new(
			position.X + offset[1] * scale,
			position.Y + bodySize * 0.5 + offset[2] * scale,
			position.Z + offset[3] * scale
		)
		makePart(model, "Prop" .. tostring(i), shape, scaled, at, color, Enum.Material.SmoothPlastic)
	end
	CharacterModels.ApplyMutation(model, mutation)
	CharacterModels.AttachLabel(model, def, mutation, bodySize)
	return model
end

-- Mutations must be visible at a glance: the whole body changes colour
-- and glows. Golden = gold Neon, Diamond = ice-blue Neon, Rainbow =
-- magenta Neon plus a magenta point light so it shines at night.
function CharacterModels.ApplyMutation(model, mutation)
	if mutation == nil or mutation == "" then
		return
	end
	for _, mut in ipairs(BrainrotData.MUTATIONS) do
		if mut.Name == mutation then
			local body = model:FindFirstChild("Body")
			if body ~= nil then
				body.Color = Color3.new(mut.Color[1], mut.Color[2], mut.Color[3])
				body.Material = Enum.Material.Neon
				if mutation == "Diamond" then
					body.Transparency = 0.15
				end
				if mutation == "Rainbow" then
					local light = Instance.new("PointLight")
					light.Color = Color3.new(0.9, 0.4, 1.0)
					light.Range = 10
					light.Brightness = 2
					light.Parent = body
				end
			end
		end
	end
end

function CharacterModels.AttachLabel(model, def, mutation, bodySize)
	local primary = model.PrimaryPart
	if primary == nil then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 220, 0, 96)
	gui.StudsOffset = Vector3.new(0, bodySize + 2.6, 0)
	gui.AlwaysOnTop = false
	gui.Parent = primary
	local back = Instance.new("Frame")
	back.Name = "Backplate"
	back.Size = UDim2.new(1, 0, 1, 0)
	back.BackgroundColor3 = Color3.new(0.06, 0.09, 0.16)
	back.BackgroundTransparency = 0.15
	back.BorderSizePixel = 2
	local rarityColor = BrainrotData.RarityColor(def.Rarity)
	back.BorderColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
	back.Parent = gui
	local mark = BrainrotData.MutationMark(mutation)
	local nameText = def.Name
	if mutation ~= nil and mutation ~= "" then
		nameText = mark .. " " .. mutation .. " " .. def.Name
	end
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLine"
	nameLabel.Size = UDim2.new(1, 0, 0, 32)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = nameText
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = back
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLine"
	rarityLabel.Size = UDim2.new(1, 0, 0, 28)
	rarityLabel.Position = UDim2.new(0, 0, 0, 32)
	rarityLabel.BackgroundTransparency = 1
	-- Show the real income, mutation multiplier included.
	rarityLabel.Text = def.Rarity .. "  " .. Format.Money(BrainrotData.IncomeFor(def, mutation, 0, 1)) .. "/s"
	rarityLabel.TextColor3 = Color3.new(rarityColor[1], rarityColor[2], rarityColor[3])
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = back
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLine"
	priceLabel.Size = UDim2.new(1, 0, 0, 32)
	priceLabel.Position = UDim2.new(0, 0, 0, 60)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = Format.Money(def.Cost)
	priceLabel.TextColor3 = Color3.new(1, 0.85, 0.2)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = back
end

function CharacterModels.SetLabelPrice(model, priceText)
	local gui = model:FindFirstChild("BrainrotLabel")
	if gui == nil then
		return
	end
	local back = gui:FindFirstChild("Backplate")
	if back == nil then
		return
	end
	local priceLabel = back:FindFirstChild("PriceLine")
	if priceLabel ~= nil then
		priceLabel.Text = priceText
	end
end

return CharacterModels
