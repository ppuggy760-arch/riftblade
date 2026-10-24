-- Everything outside: ground, paths, the front gate, the backyard, the pond, and the pines.

local B = require("../lib/B")
local P = require("./Props")
local L = require("./Layout")
local Story = require("./Story")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame
local Instance = B.Instance
local Enum = B.Enum
local roblox = B.roblox

local Yard = {}

local function at(x, y, z, look)
	local p = V(x, y, z)
	return CFrame.lookAt(p, p + (look or V(0, 0, -1)))
end

-- fence rectangle around the property
local FX0, FX1, FZ0, FZ1 = -66, 66, -80, 108

---------------------------------------------------------------- ground

local function terrainTile(r, y0, y1, material, color, partMaterial, attrs)
	local p = B.box(V(r[2] - r[1], y1 - y0, r[4] - r[3]), CF((r[1] + r[2]) / 2, (y0 + y1) / 2, (r[3] + r[4]) / 2), color, partMaterial or material, {
		name = "Ground",
		shadow = false,
	})
	p:SetAttribute("TerrainMaterial", material.Name)
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	return p
end

local function ground()
	B.within("Ground", function()
		local houseHole = { -40, 40, -32, 32 }
		local shedHole = { 16, 32, 32, 52 }
		for _, r in B.rectsMinus({ -320, 320, -320, 320 }, { houseHole, shedHole }) do
			terrainTile(r, -8, 0, M.Grass, C.grass, M.Grass, { TerrainOrder = 1 })
		end
		-- gravel apron hugging the foundation and the coal shed (always parts)
		local foot = { L.X0 - L.stoneT / 2, L.X1 + L.stoneT / 2, L.Z0 - L.stoneT / 2, L.Z1 + L.stoneT / 2 }
		for _, r in B.rectsMinus(houseHole, { foot }) do
			B.box(V(r[2] - r[1], 1, r[4] - r[3]), CF((r[1] + r[2]) / 2, -0.5, (r[3] + r[4]) / 2), B.rgb(150, 136, 116), M.Pebble, { name = "Apron", shadow = false })
		end
		local s = L.shed
		for _, r in B.rectsMinus(shedHole, { { s.x0, s.x1, s.z0, s.z1 } }) do
			B.box(V(r[2] - r[1], 1, r[4] - r[3]), CF((r[1] + r[2]) / 2, -0.5, (r[3] + r[4]) / 2), B.rgb(130, 112, 90), M.Ground, { name = "Apron", shadow = false })
		end
	end)
end

-- Dirt path strip from a to b (flat on the ground). Becomes terrain at runtime.
local function path(a, b, w)
	local p0, p1 = V(a.X, -0.15, a.Z), V(b.X, -0.15, b.Z)
	local part = B.between(p0, p1, w, 0.34, C.dirt, M.Ground, { name = "Path", shadow = false })
	part:SetAttribute("TerrainMaterial", "Ground")
	part:SetAttribute("TerrainOrder", 2)
	part:SetAttribute("TerrainSurface", true)
	-- stepping stones
	local len = (p1 - p0).Magnitude
	local dir = (p1 - p0).Unit
	local side = dir:Cross(V(0, 1, 0))
	local k = 1.2
	while k < len - 0.6 do
		local c = p0 + dir * k + side * B.range(-w * 0.18, w * 0.18)
		local d = B.range(1.4, 2.1)
		B.cyl(V(0.3, d, d * B.range(0.8, 1)), CFrame.new(c.X, 0.06, c.Z) * CFrame.Angles(0, B.range(0, 3), math.pi / 2), B.vary(C.stone, 0.1), M.Slate, { name = "SteppingStone" })
		k += B.range(1.9, 2.5)
	end
end

---------------------------------------------------------------- plants

local function pine(pos, h)
	local trunkH = h * 0.42
	local d = math.max(0.9, h * 0.045)
	B.vcyl(trunkH, d, pos + V(0, trunkH / 2, 0), B.vary(B.rgb(92, 64, 44), 0.1), M.Wood, { name = "Trunk" })
	local tiers = 4
	local spin = B.range(0, math.pi)
	for i = 0, tiers - 1 do
		local base = h * 0.2 + i * h * 0.19
		local th = h * 0.34
		local w = h * 0.48 * (1 - i * 0.2)
		local col = B.vary(B.rgb(46, 84, 50), 0.14)
		for k = 0, 1 do
			B.tent(CFrame.new(pos + V(0, base, 0)) * CFrame.Angles(0, spin + k * math.pi / 2 + i * 0.4, 0), w, th, w, col, M.Grass, { name = "Needles", collide = false })
		end
	end
end

local function leafyTree(pos, h, palette, trunkColor, spread)
	trunkColor = trunkColor or B.rgb(110, 80, 56)
	local d = math.max(1.0, h * 0.06)
	B.vcyl(h * 0.6, d, pos + V(0, h * 0.3, 0), trunkColor, M.Wood, { name = "Trunk" })
	local n = math.floor(5 + h * 0.15)
	spread = spread or 0.32
	for i = 1, n do
		local a = B.range(0, math.pi * 2)
		local r = B.range(0, h * spread)
		local y = h * B.range(0.55, 0.95)
		local s = h * B.range(0.22, 0.34)
		B.ball(s, pos + V(math.cos(a) * r, y, math.sin(a) * r), B.vary(B.pick(palette), 0.08), M.LeafyGrass, { name = "Leaves", collide = false })
		if i % 3 == 0 then
			B.rod(pos + V(0, h * 0.45, 0), pos + V(math.cos(a) * r * 0.8, y - s * 0.2, math.sin(a) * r * 0.8), d * 0.4, trunkColor, M.Wood, { name = "Branch", collide = false })
		end
	end
end

local GOLD = { B.rgb(255, 196, 40), B.rgb(244, 168, 36), B.rgb(255, 214, 70), B.rgb(214, 130, 40) }
local AUTUMN = { B.rgb(236, 150, 40), B.rgb(214, 96, 40), B.rgb(250, 190, 60), B.rgb(150, 150, 60) }

local function birch(pos, h)
	leafyTree(pos, h, GOLD, B.rgb(236, 230, 214), 0.22)
	for k = 0, 3 do
		B.box(V(h * 0.05 + 0.1, 0.25, 0.2), CFrame.new(pos + V(0, 2 + k * h * 0.12, -math.max(1.0, h * 0.06) / 2)), C.soot, M.SmoothPlastic, { name = "Mark", collide = false })
	end
end

local function bush(pos, s, palette)
	for i = 1, 4 do
		B.ball(s * B.range(0.7, 1.1), pos + V(B.range(-s * 0.5, s * 0.5), s * 0.35, B.range(-s * 0.5, s * 0.5)), B.vary(B.pick(palette or { B.rgb(70, 110, 50), B.rgb(90, 120, 50) }), 0.1), M.LeafyGrass, { name = "Bush", collide = false })
	end
end

local function rock(pos, s)
	B.box(V(s, s * 0.6, s * 0.8), CFrame.new(pos + V(0, s * 0.2, 0)) * CFrame.Angles(B.range(-0.3, 0.3), B.range(0, 3), B.range(-0.3, 0.3)), B.vary(B.rgb(130, 124, 116), 0.12), M.Rock, { name = "Rock" })
end

local function flowers(center, r, n, palette)
	for i = 1, n do
		local a = B.range(0, math.pi * 2)
		local d = math.sqrt(B.rand()) * r
		local p = center + V(math.cos(a) * d, 0, math.sin(a) * d)
		B.vcyl(0.9, 0.08, p + V(0, 0.45, 0), B.rgb(80, 130, 60), M.SmoothPlastic, { name = "Stem", collide = false, shadow = false })
		B.ball(0.38, p + V(0, 0.95, 0), B.pick(palette), M.SmoothPlastic, { name = "Bloom", collide = false, shadow = false })
	end
end

local function sunflower(pos, h)
	B.vcyl(h, 0.22, pos + V(0, h / 2, 0), B.rgb(80, 120, 50), M.Grass, { name = "Stalk", collide = false })
	for k = 0, 2 do
		B.box(V(1.2, 0.08, 0.7), CFrame.new(pos + V(0, h * 0.35 + k * h * 0.2, 0)) * CFrame.Angles(0, k * 2.1, math.rad(20)) * CF(0.55, 0, 0), B.rgb(80, 130, 50), M.Grass, { name = "Leaf", collide = false, shadow = false })
	end
	local head = CFrame.new(pos + V(0, h + 0.3, 0)) * CFrame.Angles(math.rad(-25), B.range(-0.6, 0.6), 0)
	B.cyl(V(0.15, 2.0, 2.0), head * CFrame.Angles(0, math.pi / 2, 0), B.rgb(255, 204, 30), M.SmoothPlastic, { name = "Petals", collide = false })
	B.cyl(V(0.25, 1.0, 1.0), head * CF(0, 0, -0.08) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(90, 56, 30), M.Fabric, { name = "Seeds", collide = false })
end

local function pumpkin(pos, s)
	for k = 0, 3 do
		B.ball(s, pos + V(math.cos(k * 1.57) * s * 0.15, s * 0.42, math.sin(k * 1.57) * s * 0.15), B.vary(B.rgb(236, 120, 30), 0.06), M.SmoothPlastic, { name = "Pumpkin" })
	end
	B.vcyl(s * 0.3, s * 0.12, pos + V(0, s * 0.9, 0), B.rgb(90, 110, 50), M.Wood, { name = "PumpkinStem", collide = false })
end

---------------------------------------------------------------- built things

local function fenceRun(a, b, gapFrom, gapTo)
	local dir = (b - a).Unit
	local len = (b - a).Magnitude
	local spacing = 8
	local n = math.floor(len / spacing + 0.5)
	local pts = {}
	for i = 0, n do
		table.insert(pts, a + dir * (len * i / n))
	end
	for i = 1, #pts do
		local p = pts[i]
		local inGap = gapFrom and (p - a).Magnitude > gapFrom + 0.1 and (p - a).Magnitude < gapTo - 0.1
		if not inGap then
			B.vcyl(4.6, 0.8, p + V(0, 2.3, 0), B.vary(B.rgb(130, 96, 62), 0.08), M.Wood, { name = "FencePost" })
		end
		if i < #pts then
			local q = pts[i + 1]
			local da, db = (p - a).Magnitude, (q - a).Magnitude
			local skip = gapFrom and db > gapFrom and da < gapTo
			if not skip then
				for _, y in { 1.6, 3.4 } do
					B.rod(p + V(0, y, 0), q + V(0, y + B.range(-0.1, 0.1), 0), 0.45, B.vary(B.rgb(150, 110, 70), 0.08), M.Wood, { name = "FenceRail" })
				end
			end
		end
	end
end

local function gateArch()
	B.within("Gate", function()
		for _, x in { -3.8, 3.8 } do
			B.vcyl(11, 1.3, V(x, 5.5, FZ0), B.vary(C.log, 0.05), M.Wood, { name = "GatePost" })
			B.box(V(2, 0.6, 2), CF(x, 0.3, FZ0), C.stoneDark, M.Slate, { name = "PostStone" })
		end
		B.cyl(V(10, 1.1, 1.1), CF(0, 10.6, FZ0), C.logDark, M.Wood, { name = "GateBeam" })
		for _, x in { -2.2, 2.2 } do
			B.rod(V(x, 10.1, FZ0), V(x, 8.9, FZ0), 0.08, C.iron, M.Metal, { name = "SignChain", collide = false })
		end
		local sign = B.box(V(6.4, 1.6, 0.25), CF(0, 8.2, FZ0), B.rgb(110, 70, 38), M.WoodPlanks, { name = "Sign" })
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
			B.surfaceText(sign, face, "MARROW LODGE", { font = Enum.Font.Fondamento, color = B.rgb(250, 220, 150) })
		end
		-- lanterns on the gate posts
		for _, x in { -3.8, 3.8 } do
			P.lantern(V(x, 11.1, FZ0), { range = 16, brightness = 1.0 })
		end
	end)
end

local function lampPost(pos)
	B.vcyl(0.4, 1.4, pos + V(0, 0.2, 0), C.iron, M.Metal, { name = "LampFoot" })
	B.vcyl(7, 0.35, pos + V(0, 3.6, 0), C.iron, M.Metal, { name = "LampPost" })
	P.lantern(pos + V(0, 7.1, 0), { range = 18, brightness = 1.1, shadows = true })
end

local function car(cf)
	B.within("OldWagon", function()
		local paint = B.rgb(196, 156, 80)
		local woody = B.rgb(130, 82, 44)
		B.box(V(6.6, 2.2, 15), cf * CF(0, 2.3, 0), paint, M.Metal, { name = "Body" })
		for _, sx in { -1, 1 } do
			B.box(V(0.1, 1.2, 10), cf * CF(sx * 3.31, 2.4, 1.2), woody, M.WoodPlanks, { name = "WoodPanel" })
		end
		B.box(V(6.2, 2.4, 9.4), cf * CF(0, 4.6, 1.9), paint, M.Metal, { name = "Cabin" })
		local glass = B.rgb(50, 60, 60)
		B.box(V(6.3, 1.7, 8.8), cf * CF(0, 4.75, 1.9), glass, M.Glass, { name = "Windows", transparency = 0.25, reflectance = 0.3 })
		B.box(V(5.6, 1.6, 0.1), cf * CF(0, 4.75, -2.85) * CFrame.Angles(math.rad(-25), 0, 0), glass, M.Glass, { name = "Windshield", transparency = 0.25, reflectance = 0.3 })
		for _, z in { -7.6, 7.6 } do
			B.box(V(6.8, 0.6, 0.4), cf * CF(0, 1.5, z), B.rgb(200, 200, 196), M.Metal, { name = "Bumper" })
		end
		for _, sx in { -2.4, 2.4 } do
			B.cyl(V(0.2, 0.8, 0.8), cf * CF(sx, 2.3, -7.55) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(255, 240, 200), M.Glass, { name = "Headlight", collide = false })
		end
		for _, sx in { -1, 1 } do
			for _, z in { -4.8, 4.6 } do
				B.cyl(V(1.0, 2.8, 2.8), cf * CF(sx * 3.0, 1.3, z), B.rgb(30, 30, 30), M.Rubber, { name = "Tire" })
				B.cyl(V(1.05, 1.3, 1.3), cf * CF(sx * 3.0, 1.3, z), B.rgb(180, 180, 176), M.Metal, { name = "Hubcap", collide = false })
			end
		end
		-- fallen leaves on the roof and hood
		for i = 1, 14 do
			B.cyl(V(0.05, 0.6, 0.6), cf * CF(B.range(-2.8, 2.8), if i < 8 then 5.82 else 3.42, if i < 8 then B.range(-2.5, 6.5) else B.range(-7, -3)) * CFrame.Angles(0, B.range(0, 3), math.pi / 2), B.pick(AUTUMN), M.SmoothPlastic, { name = "Leaf", collide = false, shadow = false })
		end
	end)
end

local function fireCircle(c)
	B.within("FirePit", function()
		for i = 0, 13 do
			local a = i / 14 * math.pi * 2
			rock(c + V(math.cos(a) * 3.0, -0.1, math.sin(a) * 3.0), B.range(1.1, 1.5))
		end
		B.vcyl(0.12, 5.2, c + V(0, 0.06, 0), B.rgb(50, 44, 40), M.Slate, { name = "Ash", collide = false })
		for k = 0, 2 do
			B.cyl(V(3.2, 0.7, 0.7), CFrame.new(c + V(0, 0.5 + k * 0.15, 0)) * CFrame.Angles(0, k * 1.05, math.rad(12)), B.rgb(80, 52, 32), M.Wood, { name = "Log", collide = false })
		end
		local ember = B.box(V(2.2, 0.3, 2.2), CFrame.new(c + V(0, 0.4, 0)), B.rgb(255, 110, 30), M.Neon, { name = "Embers", collide = false, shadow = false })
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Heat = 9
		fire.Color = B.rgb(255, 170, 60)
		fire.SecondaryColor = B.rgb(255, 70, 10)
		fire.Parent = ember
		B.warmLight(ember, 28, 2.2, true, B.rgb(255, 160, 80))
		ember:SetAttribute("Flicker", true)
		ember:SetAttribute("FireLight", true)
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + 0.4
			local p = c + V(math.cos(a) * 7.5, 0, math.sin(a) * 7.5)
			P.adirondack(CFrame.lookAt(p, V(c.X, 0, c.Z)), B.pick({ C.mustard, B.rgb(196, 80, 50), B.rgb(80, 120, 120), B.rgb(236, 220, 190) }))
		end
		-- a log bench
		local bench = c + V(0, 0, -8.5)
		B.cyl(V(6, 1.6, 1.6), CFrame.new(bench + V(0, 0.8, 0)) * CFrame.Angles(0, 0.2, 0), B.rgb(130, 90, 56), M.Wood, { name = "LogBench" })
	end)
end

local function stringLights(points, sag)
	B.within("StringLights", function()
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local len = (b - a).Magnitude
			local n = math.floor(len / 1.6)
			local prev = a
			for k = 1, n do
				local t = k / n
				local p = a:Lerp(b, t) - V(0, math.sin(t * math.pi) * sag, 0)
				B.rod(prev, p, 0.06, B.rgb(40, 36, 30), M.SmoothPlastic, { name = "Wire", collide = false, shadow = false })
				if k < n then
					local bulb = B.ball(0.38, p - V(0, 0.3, 0), B.rgb(255, 214, 120), M.Neon, { name = "Bulb", collide = false, shadow = false })
					if k % 4 == 0 then
						B.warmLight(bulb, 10, 0.8)
					end
				end
				prev = p
			end
		end
	end)
end

local function swingTree(base)
	B.within("SwingTree", function()
		local trunkH = 15
		B.vcyl(trunkH, 3.6, base + V(0, trunkH / 2, 0), B.rgb(100, 72, 50), M.Wood, { name = "Trunk" })
		for i = 0, 4 do
			local a = i * 1.3
			B.rod(base + V(0, 0.6, 0), base + V(math.cos(a) * 3.2, -0.2, math.sin(a) * 3.2), 1.2, B.rgb(100, 72, 50), M.Wood, { name = "Root", collide = false })
		end
		-- the swing branch reaches toward the house
		local bStart = base + V(0, 13.5, 0)
		local bEnd = base + V(-11, 15.5, -3)
		B.rod(bStart, bEnd, 1.4, B.rgb(100, 72, 50), M.Wood, { name = "Bough" })
		for i = 0, 3 do
			local a = i * 1.6 + 0.6
			B.rod(base + V(0, 12 + i, 0), base + V(math.cos(a) * 9, 18 + i * 1.5, math.sin(a) * 9), 1.0, B.rgb(100, 72, 50), M.Wood, { name = "Branch", collide = false })
		end
		for i = 1, 16 do
			local a = B.range(0, math.pi * 2)
			local r = B.range(0, 10)
			B.ball(B.range(6, 9), base + V(math.cos(a) * r - 2, B.range(17, 25), math.sin(a) * r), B.vary(B.pick(AUTUMN), 0.08), M.LeafyGrass, { name = "Leaves", collide = false })
		end
		-- rope swing
		local hang = bStart:Lerp(bEnd, 0.62)
		local seatY = 2.2
		for _, dz in { -1.3, 1.3 } do
			B.rod(hang + V(0, -0.4, dz), V(hang.X, seatY + 0.2, hang.Z + dz), 0.12, B.rgb(200, 180, 140), M.Fabric, { name = "Rope", collide = false })
		end
		B.box(V(1.4, 0.25, 3.2), CFrame.new(hang.X, seatY, hang.Z), B.rgb(150, 100, 60), M.WoodPlanks, { name = "SwingSeat" })
		P.wallNote(CFrame.lookAt(base + V(-1.85, 4.2, 0), base + V(-10, 4.2, 0)), Story.swingNote.text, Story.swingNote.style)
		-- leaves on the ground under it
		for i = 1, 30 do
			local a = B.range(0, math.pi * 2)
			local r = B.range(2, 12)
			B.cyl(V(0.05, 0.7, 0.7), CFrame.new(base + V(math.cos(a) * r, 0.03, math.sin(a) * r)) * CFrame.Angles(0, B.range(0, 3), math.pi / 2), B.pick(AUTUMN), M.SmoothPlastic, { name = "FallenLeaf", collide = false, shadow = false })
		end
	end)
end

local function clothesline(a, b)
	B.within("Clothesline", function()
		for _, p in { a, b } do
			B.vcyl(8, 0.5, p + V(0, 4, 0), B.rgb(150, 110, 70), M.Wood, { name = "LinePost" })
			B.box(V(3, 0.4, 0.4), CFrame.new(p + V(0, 7.6, 0)), B.rgb(150, 110, 70), M.Wood, { name = "Crossbar" })
		end
		B.rod(a + V(0, 7.4, 0), b + V(0, 7.4, 0), 0.06, B.rgb(220, 214, 200), M.Fabric, { name = "Line", collide = false })
		local dir = (b - a).Unit
		for i, t in { 0.22, 0.5, 0.78 } do
			local p = a:Lerp(b, t) + V(0, 7.4, 0)
			local look = CFrame.lookAt(p, p + dir:Cross(V(0, 1, 0)))
			B.box(V(4.4, 5.2, 0.08), look * CF(0, -2.6, 0) * CFrame.Angles(math.rad(6 * (i - 2)), 0, 0), B.rgb(246, 242, 232), M.Fabric, { name = "Sheet", collide = false })
			for _, dx in { -1.8, 1.8 } do
				B.box(V(0.15, 0.4, 0.15), look * CF(dx, 0, 0), B.rgb(170, 130, 90), M.Wood, { name = "Peg", collide = false })
			end
		end
	end)
end

local function well(c)
	B.within("Well", function()
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			B.box(V(1.4, 3.2, 1.0), CFrame.new(c + V(math.cos(a) * 2.6, 1.6, math.sin(a) * 2.6)) * CFrame.Angles(0, -a, 0), B.vary(C.stone, 0.1), M.Cobblestone, { name = "WellStone" })
		end
		B.vcyl(0.2, 4.6, c + V(0, 1.0, 0), B.rgb(20, 24, 26), M.Glass, { name = "WellWater", collide = false, transparency = 0.1, reflectance = 0.4 })
		for _, sx in { -2.6, 2.6 } do
			B.box(V(0.6, 7.5, 0.6), CFrame.new(c + V(sx, 3.75, 0)), B.rgb(120, 84, 50), M.Wood, { name = "WellPost" })
		end
		B.tent(CFrame.new(c + V(0, 7.2, 0)) * CFrame.Angles(0, math.pi / 2, 0), 6.4, 2.4, 6.6, C.roof, M.RoofShingles, { name = "WellRoof" })
		B.cyl(V(5.2, 0.5, 0.5), CFrame.new(c + V(0, 5.2, 0)), B.rgb(110, 76, 46), M.Wood, { name = "Windlass", collide = false })
		B.rod(c + V(0, 5.2, 0), c + V(0, 3.6, 0), 0.08, B.rgb(200, 180, 140), M.Fabric, { name = "Rope", collide = false })
		B.vcyl(1.0, 1.0, c + V(0, 3.1, 0), B.rgb(130, 90, 56), M.Wood, { name = "Bucket", collide = false })
	end)
end

local function pond(c, r)
	B.within("Pond", function()
		local mud = B.cyl(V(1.2, r * 2 + 3, r * 2 + 3), CFrame.new(c + V(0, -0.58, 0)) * CFrame.Angles(0, 0, math.pi / 2), B.rgb(110, 92, 64), M.Mud, { name = "PondEdge", shadow = false })
		mud:SetAttribute("TerrainMaterial", "Mud")
		mud:SetAttribute("TerrainOrder", 3)
		local water = B.cyl(V(6, r * 2, r * 2), CFrame.new(c + V(0, -2.94, 0)) * CFrame.Angles(0, 0, math.pi / 2), B.rgb(60, 90, 90), M.Glass, { name = "PondWater", transparency = 0.25, reflectance = 0.3, shadow = false })
		water:SetAttribute("TerrainMaterial", "Water")
		water:SetAttribute("TerrainOrder", 4)
		-- reeds and a little dock
		for i = 1, 24 do
			local a = B.range(0, math.pi * 2)
			local p = c + V(math.cos(a) * (r + B.range(-0.5, 1.2)), 0, math.sin(a) * (r + B.range(-0.5, 1.2)))
			B.vcyl(B.range(2, 3.5), 0.12, p + V(0, 1.2, 0), B.rgb(110, 130, 60), M.Grass, { name = "Reed", collide = false, shadow = false })
		end
		local d0 = c + V(r + 6, 0, 0)
		local d1 = c + V(r * 0.35, 0, 0)
		local dir = (d1 - d0).Unit
		local len = (d1 - d0).Magnitude
		local k = 0.5
		while k < len do
			local p = d0 + dir * k
			B.box(V(0.8, 0.25, 4), CFrame.new(p.X, 0.9, p.Z), B.vary(B.rgb(140, 100, 64), 0.08), M.WoodPlanks, { name = "DockBoard" })
			k += 0.9
		end
		for i = 0, 3 do
			local p = d0 + dir * (len * i / 3)
			for _, dz in { -1.8, 1.8 } do
				B.vcyl(3.4, 0.5, V(p.X, -0.8, p.Z + dz), B.rgb(100, 72, 46), M.Wood, { name = "DockPost" })
			end
		end
		P.lantern(d1 + V(0, 1.05, 1.6), { range = 14, brightness = 0.8 })
	end)
end

---------------------------------------------------------------- build

function Yard.build(root)
	local f = B.folder("Grounds", root)
	B.push(f)
	B.seed(77)
	ground()

	-- front: path, lamps, gate, fence, the old wagon
	B.within("FrontYard", function()
		path(V(0, 0, L.Z0 - 13), V(0, 0, FZ0 - 2), 5)
		path(V(0, 0, FZ0 - 2), V(0, 0, -100), 5)
		for _, z in { -48, -62, -74 } do
			for _, x in { -4.2, 4.2 } do
				lampPost(V(x, 0, z))
			end
		end
		gateArch()
		car(CFrame.lookAt(V(-24, 0, -64), V(-21, 0, -40)))
		-- mailbox
		local mb = V(7.5, 0, -84)
		B.box(V(0.5, 4, 0.5), CFrame.new(mb + V(0, 2, 0)), B.rgb(110, 76, 46), M.Wood, { name = "MailPost" })
		B.cyl(V(2.2, 1.2, 1.2), CFrame.new(mb + V(0, 4.4, 0)) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(150, 50, 40), M.Metal, { name = "Mailbox" })
		B.box(V(1.0, 1.1, 0.8), CFrame.new(mb + V(0, 4.15, 0)), B.rgb(150, 50, 40), M.Metal, { name = "MailboxBody" })
		B.box(V(0.08, 0.8, 0.3), CFrame.new(mb + V(0.62, 4.9, 0.3)), B.rgb(220, 60, 40), M.Metal, { name = "Flag", collide = false })
		-- flower beds along the porch
		for _, x in { -18, 18 } do
			B.box(V(20, 0.6, 2.6), CF(x, 0.2, L.Z0 - 10.6), C.dirt, M.Ground, { name = "Bed" })
			for i = 0, 18 do
				local px = x - 9.2 + i
				B.ball(B.range(0.7, 1.0), V(px, 0.9, L.Z0 - 10.6 + B.range(-0.5, 0.5)), B.vary(B.rgb(70, 120, 50), 0.12), M.LeafyGrass, { name = "Leaves", collide = false, shadow = false })
				B.ball(B.range(0.45, 0.6), V(px + B.range(-0.3, 0.3), 1.45, L.Z0 - 10.6 + B.range(-0.5, 0.5)), B.pick({ B.rgb(255, 200, 40), B.rgb(255, 150, 40), B.rgb(250, 240, 210), B.rgb(220, 70, 50) }), M.SmoothPlastic, { name = "Bloom", collide = false, shadow = false })
			end
		end
		leafyTree(V(-46, 0, -56), 26, GOLD)
		leafyTree(V(44, 0, -60), 24, AUTUMN)
		birch(V(26, 0, -50), 22)
		birch(V(-34, 0, -44), 20)
	end)

	-- back: fire, lights, swing, garden, line, well, pond
	B.within("Backyard", function()
		path(V(0, 0, L.Z1 + 13.6), V(-12, 0, 56), 4.5)
		path(V(0, 0, L.Z1 + 13.6), V(26, 0, 74), 4)
		path(V(0, 0, L.Z1 + 13.6), V(2, 0, 70), 4)
		path(V(2, 0, 70), V(0, 0, FZ1 + 2), 4)
		path(V(0, 0, FZ1 + 2), V(2, 0, 138), 3.6)
		fireCircle(V(-14, 0, 62))
		local hx = L.Z1 + 0.9
		stringLights({ V(-20, 13.5, hx), V(-20, 11, 46), V(-12, 10.5, 70), V(8, 10.5, 66), V(12, 11, 46), V(12, 13.5, hx) }, 1.2)
		for _, p in { V(-20, 0, 46), V(-12, 0, 70), V(8, 0, 66), V(12, 0, 46) } do
			B.vcyl(11.4, 0.6, p + V(0, 5.7, 0), B.rgb(130, 96, 62), M.Wood, { name = "LightPole" })
		end
		swingTree(V(34, 0, 80))
		clothesline(V(-44, 0, 46), V(-44, 0, 70))
		well(V(-52, 0, 40))
		pond(V(-46, 0, 92), 11)
		-- garden: raised beds, pumpkins, sunflowers
		for _, z in { 58, 66 } do
			B.box(V(12, 1.2, 4), CF(44, 0.6, z), B.rgb(130, 90, 56), M.WoodPlanks, { name = "RaisedBed" })
			B.box(V(11.4, 0.2, 3.4), CF(44, 1.25, z), C.dirt, M.Ground, { name = "Soil", collide = false })
			for i = 0, 3 do
				pumpkin(V(39.5 + i * 3, 1.3, z + B.range(-0.6, 0.6)), B.range(1.3, 1.9))
			end
		end
		for i = 0, 7 do
			sunflower(V(37 + i * 2.2, 0, 73 + B.range(-0.6, 0.6)), B.range(6, 8))
		end
		-- woodpile against the shed
		for row = 0, 4 do
			for k = 0, 8 - row do
				B.cyl(V(2.2, 0.9, 0.9), CFrame.new(L.shed.x1 + 1.6, 0.5 + row * 0.8, L.shed.z0 + 2 + k * 0.92 + row * 0.46) * CFrame.Angles(0, 0, 0), B.vary(B.rgb(150, 104, 64), 0.12), M.Wood, { name = "Firewood" })
			end
		end
		-- chopping block with an axe
		B.vcyl(1.6, 2.2, V(34, 0.8, 40), B.rgb(140, 100, 64), M.Wood, { name = "ChoppingBlock" })
		B.box(V(0.2, 3.2, 0.2), CFrame.new(34.3, 2.6, 40) * CFrame.Angles(0, 0, math.rad(-35)), B.rgb(150, 110, 70), M.Wood, { name = "AxeHandle", collide = false })
		B.box(V(0.9, 0.6, 0.12), CFrame.new(33.6, 1.7, 40) * CFrame.Angles(0, 0, math.rad(-35)), C.iron, M.Metal, { name = "AxeHead", collide = false })
		-- where the path goes into the woods, one lantern on a stake
		B.vcyl(4.5, 0.25, V(2.6, 2.25, 136), B.rgb(110, 76, 46), M.Wood, { name = "Stake" })
		P.lantern(V(2.6, 4.5, 136), { range = 16, brightness = 0.9 })
		birch(V(-30, 0, 100), 22)
		birch(V(52, 0, 50), 24)
		leafyTree(V(-58, 0, 66), 22, GOLD)
		leafyTree(V(56, 0, 98), 26, AUTUMN)
	end)

	-- fence around the property, gaps at the gate and at the back
	B.within("Fence", function()
		fenceRun(V(FX0, 0, FZ0), V(FX1, 0, FZ0), (0 - FX0) - 4.5, (0 - FX0) + 4.5)
		fenceRun(V(FX0, 0, FZ1), V(FX1, 0, FZ1), (0 - FX0) - 4, (0 - FX0) + 4)
		fenceRun(V(FX0, 0, FZ0), V(FX0, 0, FZ1))
		fenceRun(V(FX1, 0, FZ0), V(FX1, 0, FZ1))
	end)

	-- the pines, thick all the way round
	B.within("Woods", function()
		local placed = 0
		local tries = 0
		while placed < 190 and tries < 5000 do
			tries += 1
			local x = B.range(-200, 200)
			local z = B.range(-200, 220)
			local inside = x > FX0 - 6 and x < FX1 + 6 and z > FZ0 - 6 and z < FZ1 + 6
			local nearSpawn = math.abs(x) < 16 and z < FZ0 and z > -112
			local onPath = math.abs(x - 1) < 5 and z > FZ1 and z < 140
			if not inside and not nearSpawn and not onPath then
				local p = V(x, 0, z)
				if B.rand() < 0.82 then
					pine(p, B.range(26, 44))
				else
					birch(p, B.range(20, 28))
				end
				placed += 1
			end
		end
		for i = 1, 40 do
			local x, z = B.range(-160, 160), B.range(-160, 170)
			local inYard = x > FX0 - 2 and x < FX1 + 2 and z > FZ0 - 2 and z < FZ1 + 2
			if not inYard then
				bush(V(x, 0, z), B.range(2, 3.5))
			end
		end
		for i = 1, 26 do
			local x, z = B.range(-150, 150), B.range(-150, 160)
			local inHouse = x > -48 and x < 48 and z > -46 and z < 60
			if not inHouse then
				rock(V(x, 0, z), B.range(1.6, 4.5))
			end
		end
		-- low growth inside the fence line
		for _, p in { V(-60, 0, -20), V(60, 0, -30), V(-62, 0, 20), V(61, 0, 15), V(-50, 0, 104), V(48, 0, 104), V(-60, 0, -74), V(58, 0, -74) } do
			bush(p, 2.8, { B.rgb(70, 110, 50), B.rgb(214, 160, 52) })
		end
		flowers(V(-30, 0, 76), 5, 40, GOLD)
		flowers(V(46, 0, 32), 4, 26, { B.rgb(250, 240, 220), B.rgb(255, 200, 40) })
		flowers(V(-48, 0, -30), 5, 30, GOLD)
	end)

	-- an invisible edge to the world
	B.within("Boundary", function()
		for _, r in { { -175, 175, -177, -175 }, { -175, 175, 185, 187 }, { -177, -175, -177, 187 }, { 175, 177, -177, 187 } } do
			B.box(V(r[2] - r[1], 120, r[4] - r[3]), CF((r[1] + r[2]) / 2, 50, (r[3] + r[4]) / 2), C.grass, M.SmoothPlastic, { name = "Edge", transparency = 1, shadow = false })
		end
	end)

	B.pop()
	return f
end

return Yard
