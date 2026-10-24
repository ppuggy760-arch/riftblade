-- Swaps the flat grass/path/pond parts for real terrain when the server starts,
-- so the yard gets swaying grass and the pond gets water.

local Grounds = {}

local function convert(part, terrain)
	local material = Enum.Material[part:GetAttribute("TerrainMaterial")]
	if part:GetAttribute("TerrainSurface") then
		-- a strip on top of the grass: repaint the top layer
		local cf = CFrame.new(part.Position.X, -2, part.Position.Z) * part.CFrame.Rotation
		terrain:FillBlock(cf, Vector3.new(part.Size.X, 4, part.Size.Z), material)
	elseif part:IsA("Part") and part.Shape == Enum.PartType.Cylinder then
		terrain:FillCylinder(CFrame.new(part.Position), part.Size.X, part.Size.Y / 2, material)
	else
		terrain:FillBlock(part.CFrame, part.Size, material)
	end
end

function Grounds.start(config)
	if not config.TerrainGround then
		return
	end
	local terrain = workspace.Terrain
	local parts = {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("TerrainMaterial") then
			table.insert(parts, d)
		end
	end
	table.sort(parts, function(a, b)
		return (a:GetAttribute("TerrainOrder") or 0) < (b:GetAttribute("TerrainOrder") or 0)
	end)
	local ok, err = pcall(function()
		for _, part in parts do
			convert(part, terrain)
		end
	end)
	if not ok then
		warn("Marrow Lodge: terrain conversion failed, keeping the ground parts:", err)
		return
	end
	for _, part in parts do
		part:Destroy()
	end
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(132, 150, 62))
		terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(126, 96, 64))
		terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(104, 86, 62))
	end)
end

return Grounds
