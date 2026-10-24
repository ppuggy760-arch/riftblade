-- The lodge shell: foundation, floors, log walls, partitions, roof, porch, deck,
-- stairs, chimney, the lean-to, and every door and window.

local B = require("../lib/B")
local Kit = require("./Kit")
local L = require("./Layout")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame

local Cabin = {}
Cabin.doors = {}

local d = L.logD

---------------------------------------------------------------- openings

-- Exterior walls. axis/c as in B.flatWall, out = outward normal.
local walls = {
	front = { axis = "x", c = L.Z0, out = V(0, 0, -1), holes = {} },
	back = { axis = "x", c = L.Z1, out = V(0, 0, 1), holes = {} },
	west = { axis = "z", c = L.X0, out = V(-1, 0, 0), holes = {} },
	east = { axis = "z", c = L.X1, out = V(1, 0, 0), holes = {} },
}

-- Window centres line up with the log rows so openings never leave half-cut logs.
local winV = {
	x = { g = 8.4, u = 22.8 },
	z = { g = 9.2, u = 22.0 },
}
local WIN_H = 6.1

local function wallPoint(wall, u, v)
	if wall.axis == "x" then
		return V(u, v, wall.c)
	end
	return V(wall.c, v, u)
end

local windows = {
	-- front
	{ "front", -28, 5, "g", { shutters = true, flowerBox = true, curtains = C.red, shaft = { drop = 7, reach = 10 } } },
	{ "front", -19, 5, "g", { shutters = true, flowerBox = true, curtains = C.red, shaft = { drop = 7, reach = 10 } } },
	{ "front", 24, 3.4, "g", { frosted = true, panesY = 2, shutters = true } },
	{ "front", -28, 5, "u", { shutters = true, curtains = C.cream } },
	{ "front", -19, 5, "u", { shutters = true, curtains = C.cream } },
	{ "front", 0, 7, "u", { panesX = 3, curtains = C.mustard, shaft = { drop = 6, reach = 9 } } },
	{ "front", 20, 5, "u", { shutters = true, curtains = B.rgb(196, 120, 140) } },
	{ "front", 29, 5, "u", { shutters = true, curtains = B.rgb(196, 120, 140) } },
	-- back
	{ "back", -29, 5, "g", { curtains = B.rgb(214, 196, 120), flowerBox = true } },
	{ "back", -19, 5, "g", { curtains = B.rgb(214, 196, 120), flowerBox = true } },
	{ "back", -7, 4, "g", { curtains = C.green } },
	{ "back", 7, 4, "g", { curtains = C.green } },
	{ "back", 20, 5, "g", { curtains = B.rgb(120, 40, 34), shaft = { drop = 7, reach = 9 } } },
	{ "back", 29, 5, "g", { curtains = B.rgb(120, 40, 34) } },
	{ "back", -29, 5, "u", { curtains = C.navy } },
	{ "back", -19, 5, "u", { curtains = C.navy } },
	{ "back", -5, 4, "u", { curtains = C.mustard, shaft = { drop = 6, reach = 8 } } },
	{ "back", 5, 4, "u", { curtains = C.mustard } },
	{ "back", 20, 5, "u", {} },
	{ "back", 29, 5, "u", {} },
	-- west
	{ "west", -23, 5, "g", { curtains = C.red, shaft = { drop = 7, reach = 11 } } },
	{ "west", 1, 5, "g", { curtains = C.red } },
	{ "west", 17, 5, "g", { curtains = B.rgb(214, 196, 120), flowerBox = true, shutters = true } },
	{ "west", -17, 5, "u", { curtains = C.cream, shutters = true } },
	{ "west", 17, 5, "u", { curtains = C.navy, shutters = true } },
	-- east
	{ "east", -20, 3.4, "g", { frosted = true, panesY = 2 } },
	{ "east", 2.5, 4, "g", {} },
	{ "east", -17, 5, "u", { curtains = B.rgb(196, 120, 140) } },
	{ "east", 17, 5, "u", {} },
}

local FRONT_DOOR = { w = 5, h = 9.3 }
local SHELF_DOOR = { w = 5.4, h = 8.5, z = 16.5 }

local function addHole(wall, u0, u1, v0, v1)
	table.insert(wall.holes, { u0, u1, v0, v1 })
end

for _, win in windows do
	local wall = walls[win[1]]
	local vc = winV[wall.axis][win[4]]
	local hw, hh = Kit.windowHole(win[3], WIN_H)
	addHole(wall, win[2] - hw, win[2] + hw, vc - hh, vc + hh)
end
do
	local hw, hh = Kit.doorHole(FRONT_DOOR.w, FRONT_DOOR.h)
	addHole(walls.front, -hw, hw, L.yGround, L.yGround + hh)
	addHole(walls.back, -hw, hw, L.yGround, L.yGround + hh)
	local sw, sh = Kit.doorHole(SHELF_DOOR.w, SHELF_DOOR.h)
	addHole(walls.east, SHELF_DOOR.z - sw, SHELF_DOOR.z + sw, L.yGround, L.yGround + sh)
end
-- attic windows high in both gables
local GABLE_V, GABLE_W, GABLE_H = 37.2, 4, 4.5
for _, w in { walls.west, walls.east } do
	local hw, hh = Kit.windowHole(GABLE_W, GABLE_H)
	addHole(w, -hw, hw, GABLE_V - hh, GABLE_V + hh)
end

---------------------------------------------------------------- helpers

local function partition(axis, c, u0, u1, v0, v1, holes, color)
	color = color or C.plank
	B.flatWall(axis, c, u0, u1, v0, v1, L.intT, holes, color, M.WoodPlanks, { name = "Partition" })
	-- baseboards on both faces, skipping door gaps
	local cuts = {}
	for _, h in holes or {} do
		if h[3] <= v0 + 0.1 then
			table.insert(cuts, { h[1], h[2] })
		end
	end
	for _, seg in B.intervalsMinus(u0, u1, cuts) do
		local len, uc = seg[2] - seg[1], (seg[1] + seg[2]) / 2
		for _, f in { -1, 1 } do
			local off = f * (L.intT / 2 + 0.08)
			if axis == "x" then
				B.box(V(len, 0.7, 0.16), CF(uc, v0 + 0.35, c + off), C.trim, M.Wood, { name = "Baseboard", collide = false })
			else
				B.box(V(0.16, 0.7, len), CF(c + off, v0 + 0.35, uc), C.trim, M.Wood, { name = "Baseboard", collide = false })
			end
		end
	end
end

-- Log posts and a header beam framing an open archway.
local function archTrim(axis, c, u0, u1, v0, v1)
	local function at(u, v)
		if axis == "x" then
			return V(u, v, c)
		end
		return V(c, v, u)
	end
	for _, u in { u0 + 0.4, u1 - 0.4 } do
		B.vcyl(v1 - v0, 0.9, at(u, (v0 + v1) / 2), B.vary(C.log, 0.05), M.Wood, { name = "ArchPost" })
	end
	B.rod(at(u0 - 0.2, v1 + 0.45), at(u1 + 0.2, v1 + 0.45), 1.1, B.vary(C.logDark, 0.05), M.Wood, { name = "ArchBeam" })
end

local function door(o)
	B.push(Cabin.doorFolder)
	local model = Kit.door(o)
	B.pop()
	Cabin.doors[o.id] = model
	return model
end

---------------------------------------------------------------- build

function Cabin.build(root)
	local structure = B.folder("Structure", root)
	Cabin.doorFolder = B.folder("Doors", root)
	B.push(structure)

	-------------------------------------------------- foundation & floors
	B.within("Foundation", function()
		local t = L.stoneT
		local chuteHole = { L.chute.x0, L.chute.x1, L.yBasement, L.chute.top }
		B.flatWall("x", L.Z0, L.X0 - t / 2, L.X1 + t / 2, L.yBasement - 1, L.yGround, t, {}, C.stone, M.Cobblestone, { name = "StoneWall" })
		B.flatWall("x", L.Z1, L.X0 - t / 2, L.X1 + t / 2, L.yBasement - 1, L.yGround, t, { chuteHole }, C.stone, M.Cobblestone, { name = "StoneWall" })
		B.flatWall("z", L.X0, L.Z0 + t / 2, L.Z1 - t / 2, L.yBasement - 1, L.yGround, t, {}, C.stone, M.Cobblestone, { name = "StoneWall" })
		B.flatWall("z", L.X1, L.Z0 + t / 2, L.Z1 - t / 2, L.yBasement - 1, L.yGround, t, {}, C.stone, M.Cobblestone, { name = "StoneWall" })
		B.box(V(L.X1 - L.X0, 1, L.Z1 - L.Z0), CF(0, L.yBasement - 0.5, 0), B.rgb(118, 112, 104), M.Slate, { name = "BasementFloor" })
	end)

	B.within("Floors", function()
		local cs = L.cellarStair
		-- ground floor, open over the cellar stair
		for _, r in B.rectsMinus({ L.X0, L.X1, L.Z0, L.Z1 }, { { cs.xStart, L.X1, cs.z0, cs.z1 } }) do
			B.box(V(r[2] - r[1], 1, r[4] - r[3]), CF((r[1] + r[2]) / 2, L.yGround - 0.5, (r[3] + r[4]) / 2), C.floor, M.WoodPlanks, { name = "GroundFloor" })
		end
		-- upper floor, open over the main stair
		local ms = L.mainStair
		for _, r in B.rectsMinus({ L.X0, L.X1, L.Z0, L.Z1 }, { { ms.x0, ms.x1, ms.zStart, ms.zTop } }) do
			B.box(V(r[2] - r[1], 1, r[4] - r[3]), CF((r[1] + r[2]) / 2, L.yUpper - 0.5, (r[3] + r[4]) / 2), B.rgb(160, 104, 58), M.WoodPlanks, { name = "UpperFloor" })
		end
		-- upper ceiling
		B.box(V(L.X1 - L.X0, 1, L.Z1 - L.Z0), CF(0, L.yCeilU + 0.5, 0), B.rgb(206, 160, 104), M.WoodPlanks, { name = "Ceiling" })
		-- exposed joists under each ceiling
		for _, x in { -33, -27, -21, -15, -3, 3, 9, 15, 21, 27, 33 } do
			B.box(V(0.9, 1.1, L.Z1 - L.Z0 - d), CF(x, L.yCeilG - 0.55, 0), B.vary(C.beam, 0.06), M.Wood, { name = "Joist" })
		end
		for x = -33, 33, 6 do
			B.box(V(0.9, 1.0, L.Z1 - L.Z0 - d), CF(x, L.yCeilU - 0.5, 0), B.vary(C.beam, 0.06), M.Wood, { name = "Joist" })
		end
		-- basement ceiling beams and posts
		for _, z in { -14, 0, 14 } do
			B.box(V(L.X1 - L.X0 - L.stoneT, 1.4, 1.2), CF(0, L.yGround - 1.7, z), B.vary(C.beam, 0.06), M.Wood, { name = "Girder" })
			for _, x in { -24, -12, 0 } do
				B.box(V(1.0, L.yGround - 2.4 - L.yBasement, 1.0), CF(x, (L.yGround - 2.4 + L.yBasement) / 2, z), B.vary(C.beam, 0.06), M.Wood, { name = "Post" })
			end
		end
		-- bathroom tiles
		B.box(V(L.inX1 - 12.4, 0.06, -12.4 - L.inZ0), CF((L.inX1 + 12.4) / 2, L.yGround + 0.03, (-12.4 + L.inZ0) / 2), B.rgb(232, 226, 210), M.CeramicTiles, { name = "Tiles", collide = false })
		-- kitchen flagstones
		B.box(V(-12.4 - L.inX0, 0.06, L.inZ1 - 6.4), CF((L.inX0 - 12.4) / 2, L.yGround + 0.03, (L.inZ1 + 6.4) / 2), B.rgb(176, 150, 120), M.Slate, { name = "KitchenStone", collide = false })
	end)

	-------------------------------------------------- exterior log walls
	B.within("LogWalls", function()
		local ext = 1.6
		local top = L.yEave
		local function rows(wall, v0)
			local nRows = math.floor((top - v0) / d + 0.001)
			return v0 + nRows * d
		end
		-- front/back rows start on the sill, side rows are offset half a log
		for _, key in { "front", "back" } do
			local w = walls[key]
			B.logWall("x", w.c, L.X0 - ext, L.X1 + ext, L.yGround, top, d, w.holes, { chinkFrom = L.X0, chinkTo = L.X1 })
			local plateY = rows(w, L.yGround)
			B.box(V(L.X1 - L.X0 + 2 * ext, top + 0.6 - plateY, d), CF(0, (plateY + top + 0.6) / 2, w.c), C.logDark, M.Wood, { name = "TopPlate" })
		end
		for _, key in { "west", "east" } do
			local w = walls[key]
			local v0 = L.yGround + d / 2
			B.logWall("z", w.c, L.Z0 - ext, L.Z1 + ext, v0, top, d, w.holes, { chinkFrom = L.Z0, chinkTo = L.Z1 })
			B.flatWall("z", w.c, L.Z0 - ext, L.Z1 + ext, L.yGround, v0, d, w.holes, C.logDark, M.Wood, { name = "SillLog" })
			-- gable: rows keep going and shorten under the roof line
			local gv0 = rows(w, v0)
			B.logWall("z", w.c, L.Z0, L.Z1, gv0, L.yRidge, d, w.holes, {
				chink = false,
				limit = function(yc)
					local half = L.Z1 - (yc + d / 2 - L.yEave) / L.roofSlope - 0.3
					if half < 0.8 then
						return nil
					end
					return -half, half
				end,
			})
			-- chinking strips behind the gable rows
			local y = gv0
			while y + d < L.yRidge do
				local half = L.Z1 - (y + d - L.yEave) / L.roofSlope - 0.6
				if half > 0.8 then
					B.flatWall("z", w.c, -half, half, y, y + d, d * 0.62, w.holes, C.chink, M.Plaster, { name = "Chinking" })
				end
				y += d
			end
		end
	end)

	-------------------------------------------------- windows
	B.within("Windows", function()
		for _, win in windows do
			local wall = walls[win[1]]
			local vc = winV[wall.axis][win[4]]
			local p = wallPoint(wall, win[2], vc)
			Kit.window(CFrame.lookAt(p, p + wall.out), win[3], WIN_H, d, win[5])
		end
		for _, wall in { walls.west, walls.east } do
			local p = wallPoint(wall, 0, GABLE_V)
			local cf = CFrame.lookAt(p, p + wall.out)
			Kit.window(cf, GABLE_W, GABLE_H, d, { panesX = 2, panesY = 2 })
			-- the attic behind it always has a light on
			local glow = B.box(V(GABLE_W + 1, GABLE_H + 1, 0.2), cf * CF(0, 0, 3), B.rgb(255, 196, 110), M.Neon, { name = "AtticGlow", collide = false, shadow = false })
			glow.Transparency = 0.35
			glow:SetAttribute("Flicker", true)
		end
	end)

	-------------------------------------------------- partitions
	B.within("Partitions", function()
		local g0, g1 = L.yGround, L.yCeilG
		local u0, u1 = L.yUpper, L.yCeilU
		local doorW, doorH = 4.4, 8.6
		local dw, dh = Kit.doorHole(doorW, doorH)
		local function dHole(u, v)
			return { u - dw, u + dw, v, v + dh }
		end
		local archH = 9.5
		-- ground floor
		partition("x", 6, L.inX0, 12 - L.intT / 2, g0, g1, { { -30, -18, g0, g0 + archH }, { -7, 7, g0, g0 + archH } })
		archTrim("x", 6, -30, -18, g0, g0 + archH)
		archTrim("x", 6, -7, 7, g0, g0 + archH)
		partition("x", 6, 12 + L.intT / 2, L.inX1, g0, g1, {})
		partition("z", -12, 6 + L.intT / 2, L.inZ1, g0, g1, { { 12, 22, g0, g0 + archH } })
		archTrim("z", -12, 12, 22, g0, g0 + archH)
		partition("z", 12, L.inZ0, L.inZ1, g0, g1, { dHole(-20, g0), dHole(-3.5, g0), dHole(17, g0) })
		partition("x", -12, 12 + L.intT / 2, L.inX1, g0, g1, {})
		-- upper floor
		partition("x", -6, L.inX0, -12, u0, u1, { dHole(-24, u0) }, B.rgb(206, 156, 100))
		partition("x", -6, 12, L.inX1, u0, u1, { dHole(24, u0) }, B.rgb(206, 156, 100))
		partition("x", 6, L.inX0, L.inX1, u0, u1, { dHole(-24, u0), dHole(0, u0), dHole(24, u0) }, B.rgb(206, 156, 100))
		for _, x in { -12, 12 } do
			partition("z", x, L.inZ0, -6 - L.intT / 2, u0, u1, {}, B.rgb(206, 156, 100))
			partition("z", x, 6 + L.intT / 2, L.inZ1, u0, u1, {}, B.rgb(206, 156, 100))
		end
	end)

	-------------------------------------------------- stairs
	B.within("MainStair", function()
		local ms = L.mainStair
		local cx = (ms.x0 + ms.x1) / 2
		Kit.stairs(V(cx, L.yGround, ms.zStart), V(0, 0, 1), ms.x1 - ms.x0, 1, ms.tread, ms.steps, L.yGround, C.floorDark)
		for _, x in { ms.x0 + 0.35, ms.x1 - 0.35 } do
			Kit.stairRail(V(x, L.yGround + 1, ms.zStart + ms.tread * 0.5), V(x, L.yGround + ms.steps, ms.zTop - ms.tread * 0.5), 3.2)
			-- closed stringer
			local p0 = V(x + (if x < cx then -0.2 else 0.2), L.yGround + 0.6, ms.zStart)
			local p1 = V(p0.X, L.yGround + ms.steps + 0.6, ms.zTop)
			B.between(p0, p1, 1.4, 0.3, C.trim, M.Wood, { name = "Stringer" }, V(1, 0, 0))
		end
		-- balustrade around the opening upstairs
		local y = L.yUpper
		Kit.railing(V(ms.x1 + 0.3, y, ms.zStart - 0.3), V(ms.x1 + 0.3, y, ms.zTop - 0.2), 3.4)
		Kit.railing(V(ms.x0 + 0.5, y, ms.zStart - 0.3), V(ms.x1 + 0.3, y, ms.zStart - 0.3), 3.4)
		Kit.railing(V(ms.x0 + 0.3, y, -6 + 0.4), V(ms.x0 + 0.3, y, ms.zTop - 0.2), 3.4)
	end)

	B.within("CellarStair", function()
		local cs = L.cellarStair
		local cz = (cs.z0 + cs.z1) / 2
		Kit.stairs(V(cs.xStart, L.yGround, cz), V(1, 0, 0), cs.z1 - cs.z0, -1, cs.tread, cs.steps, L.yBasement, B.rgb(96, 66, 40))
		Kit.railing(V(cs.xStart, L.yGround, cs.z0 - 0.3), V(L.inX1 - 0.3, L.yGround, cs.z0 - 0.3), 3.2)
		Kit.railing(V(cs.xStart, L.yGround, cs.z1 + 0.3), V(L.inX1 - 0.3, L.yGround, cs.z1 + 0.3), 3.2)
		-- a rail on the wall side going down
		B.between(V(cs.xStart + 0.5, L.yGround + 2.4, cs.z1 + 0.2), V(cs.xEnd, L.yBasement + 3.2, cs.z1 + 0.2), 0.3, 0.3, C.trim, M.Wood, { name = "Handrail" })
	end)

	-------------------------------------------------- roof
	B.within("Roof", function()
		local slope = L.roofSlope
		local ang = math.atan(slope)
		local overZ, overX = 3.5, 2.6
		local width = L.X1 - L.X0 + overX * 2
		local tk = 1.0
		for _, side in { -1, 1 } do
			local n = V(0, math.cos(ang), side * math.sin(ang))
			local down = V(0, -math.sin(ang), side * math.cos(ang))
			local ridge = V(0, L.yRidge, 0)
			local eave = V(0, L.yEave - overZ * slope, side * (L.Z1 + overZ))
			local p0 = ridge + n * (tk / 2) - down * 0.4
			local p1 = eave + n * (tk / 2)
			B.between(p0, p1, width, tk, C.roof, M.RoofShingles, { name = "RoofSlope" }, n)
			B.between(ridge - down * 0.3 - n * 0.1, eave - n * 0.1, width, 0.2, B.rgb(150, 100, 60), M.WoodPlanks, { name = "Soffit", collide = false }, n)
			-- shingle courses for texture
			local len = (p1 - p0).Magnitude
			local k = 1.6
			while k < len - 0.5 do
				local a = p0 + down * k + n * (tk / 2 + 0.06)
				B.between(a - V(width / 2, 0, 0), a + V(width / 2, 0, 0), 0.6, 0.12, B.vary(C.roof, 0.06), M.RoofShingles, { name = "Course", collide = false, shadow = false }, n)
				k += 1.6
			end
			-- fascia along the eave
			B.between(eave + n * 0.35 - V(width / 2, 0, 0), eave + n * 0.35 + V(width / 2, 0, 0), 1.3, 0.3, C.trim, M.Wood, { name = "Fascia" }, down)
			-- rafter tails under the overhang
			for x = L.X0 + 1, L.X1 - 1, 3 do
				local a = V(x, L.yEave - 0.4, side * (L.Z1 + 0.6))
				local b = V(x, L.yEave - overZ * slope - 0.4, side * (L.Z1 + overZ - 0.2))
				B.between(a, b, 0.5, 0.7, C.beam, M.Wood, { name = "RafterTail", collide = false }, n)
			end
			-- barge boards along both gable edges
			for _, sx in { -1, 1 } do
				local gx = sx * (width / 2 + 0.15)
				B.between(V(gx, L.yRidge + 0.3, 0), V(gx, L.yEave - overZ * slope, side * (L.Z1 + overZ)), 0.3, 1.2, C.trim, M.Wood, { name = "Barge" }, n)
			end
		end
		B.cyl(V(width + 0.4, 1.3, 1.3), CF(0, L.yRidge + 0.75, 0), C.logDark, M.Wood, { name = "RidgeLog" })
	end)

	-------------------------------------------------- chimney (west gable)
	B.within("Chimney", function()
		local x0, x1 = L.X0 - 5.2, L.X0 - 0.8
		local z0, z1 = -14, -8
		local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
		B.box(V(x1 - x0 + 1.2, 16, z1 - z0 + 1.6), CF(cx - 0.2, 8, cz), C.stone, M.Cobblestone, { name = "ChimneyBase" })
		B.box(V(x1 - x0 + 0.6, 0.8, z1 - z0 + 0.8), CF(cx - 0.1, 16.4, cz), C.stoneDark, M.Cobblestone, { name = "Shoulder" })
		B.box(V(x1 - x0, L.yRidge + 5 - 16, z1 - z0), CF(cx, (16 + L.yRidge + 5) / 2, cz), C.stone, M.Cobblestone, { name = "Stack" })
		B.box(V(x1 - x0 + 0.8, 0.7, z1 - z0 + 0.8), CF(cx, L.yRidge + 5.2, cz), C.stoneDark, M.Slate, { name = "Cap" })
		local flue = B.box(V(2, 0.8, 2), CF(cx, L.yRidge + 5.8, cz), C.soot, M.Slate, { name = "Flue" })
		local smoke = B.Instance.new("Smoke")
		smoke.Color = B.rgb(220, 210, 200)
		smoke.Opacity = 0.12
		smoke.RiseVelocity = 4
		smoke.Size = 3
		smoke.Parent = flue
	end)

	-------------------------------------------------- front porch
	B.within("Porch", function()
		local z0, z1 = L.Z0 - 9, L.Z0 - d / 2
		local x0, x1 = -31, 31
		local y = L.yGround
		-- deck boards
		local zz = z1
		while zz > z0 do
			local w = math.min(0.9, zz - z0)
			B.box(V(x1 - x0, 0.3, w - 0.06), CF(0, y - 0.15, zz - w / 2), B.vary(C.floor, 0.06), M.WoodPlanks, { name = "DeckBoard" })
			zz -= w
		end
		B.box(V(x1 - x0, y - 0.3, z1 - z0), CF(0, (y - 0.3) / 2, (z0 + z1) / 2), B.rgb(60, 44, 32), M.Wood, { name = "Underdeck" })
		-- lattice skirt
		for x = x0 + 0.5, x1 - 0.5, 1.0 do
			B.box(V(0.12, y - 0.3, 0.12), CFrame.new(x, (y - 0.3) / 2, z0 - 0.1) * CFrame.Angles(0, 0, math.rad(35)), C.trim, M.Wood, { name = "Lattice", collide = false })
		end
		-- posts and beam
		local pz = z0 + 0.7
		local posts = { -30, -18, -4.6, 4.6, 18, 30 }
		for _, x in posts do
			B.vcyl(10.4, 1.2, V(x, y + 5.2, pz), B.vary(C.log, 0.05), M.Wood, { name = "PorchPost" })
			B.box(V(1.5, 0.3, 1.5), CF(x, y + 0.15, pz), C.stoneDark, M.Slate, { name = "PostFoot" })
		end
		B.cyl(V(x1 - x0 + 1.5, 1.3, 1.3), CF(0, y + 10.9, pz), C.logDark, M.Wood, { name = "PorchBeam" })
		-- roof
		local hiY, loY = y + 13.4, y + 11.4
		local hiZ, loZ = z1, z0 - 1.2
		local n = V(0, (hiZ - loZ), -(hiY - loY)).Unit
		B.between(V(0, hiY, hiZ) + n * 0.4, V(0, loY, loZ) + n * 0.4, x1 - x0 + 2, 0.8, C.roof, M.RoofShingles, { name = "PorchRoof" }, n)
		B.between(V(0, hiY - 0.1, hiZ), V(0, loY - 0.1, loZ), x1 - x0 + 2, 0.2, B.rgb(170, 116, 70), M.WoodPlanks, { name = "PorchCeiling", collide = false }, n)
		for x = x0, x1, 2.5 do
			B.between(V(x, hiY - 0.5, hiZ), V(x, loY - 0.5, loZ + 0.3), 0.45, 0.6, C.beam, M.Wood, { name = "Rafter", collide = false }, n)
		end
		B.between(V(x0 - 1, loY - 0.3, loZ), V(x1 + 1, loY - 0.3, loZ), 0.8, 0.25, C.trim, M.Wood, { name = "Fascia" }, V(0, 0, -1))
		-- railings
		local railY = y
		local spans = {
			{ -30, -18 },
			{ -18, -4.6 },
			{ 4.6, 18 },
			{ 18, 30 },
		}
		for _, s in spans do
			Kit.railing(V(s[1] + 0.6, railY, pz), V(s[2] - 0.6, railY, pz), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		end
		for _, x in { -30, 30 } do
			Kit.railing(V(x, railY, pz + 0.6), V(x, railY, z1 - 0.3), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		end
		-- stone steps
		for k = 1, 3 do
			local top = y - k * 0.5
			local zc = z0 - (k - 0.5) * 1.2
			B.box(V(8.6, top + 0.5, 1.25), CF(0, (top - 0.5) / 2, zc), B.vary(C.stone, 0.05), M.Slate, { name = "Step" })
		end
	end)

	-------------------------------------------------- back deck
	B.within("BackDeck", function()
		local z0, z1 = L.Z1 + d / 2, L.Z1 + 10
		local x0, x1 = -22, 12
		local y = L.yGround
		local xx = x0
		while xx < x1 do
			local w = math.min(0.9, x1 - xx)
			B.box(V(w - 0.06, 0.3, z1 - z0), CF(xx + w / 2, y - 0.15, (z0 + z1) / 2), B.vary(C.floor, 0.06), M.WoodPlanks, { name = "DeckBoard" })
			xx += w
		end
		B.box(V(x1 - x0, y - 0.3, z1 - z0), CF((x0 + x1) / 2, (y - 0.3) / 2, (z0 + z1) / 2), B.rgb(60, 44, 32), M.Wood, { name = "Underdeck" })
		for _, p in { V(x0 + 0.4, 0, z1 - 0.4), V(x1 - 0.4, 0, z1 - 0.4), V(-4.6, 0, z1 - 0.4), V(4.6, 0, z1 - 0.4) } do
			B.vcyl(5.2, 0.9, V(p.X, y + 2.6, p.Z), B.vary(C.log, 0.05), M.Wood, { name = "DeckPost" })
		end
		Kit.railing(V(x0 + 0.9, y, z1 - 0.4), V(-5.1, y, z1 - 0.4), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		Kit.railing(V(5.1, y, z1 - 0.4), V(x1 - 0.9, y, z1 - 0.4), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		Kit.railing(V(x0 + 0.4, y, z0 + 0.3), V(x0 + 0.4, y, z1 - 0.9), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		Kit.railing(V(x1 - 0.4, y, z0 + 0.3), V(x1 - 0.4, y, z1 - 0.9), 3.0, { log = true, noPosts = true, spacing = 0.9 })
		for k = 1, 3 do
			local top = y - k * 0.5
			B.box(V(8.6, top + 0.5, 1.25), CF(0, (top - 0.5) / 2, z1 + (k - 0.5) * 1.2), B.vary(C.floor, 0.06), M.WoodPlanks, { name = "Step" })
		end
	end)

	-------------------------------------------------- lean-to (hides the narrow way)
	B.within("LeanTo", function()
		local lt = L.leanTo
		local y = L.yGround
		local hiY, loY = 12.4, 9.6
		B.box(V(lt.x1 - lt.x0 + 0.6, y, lt.z1 - lt.z0 + 0.6), CF((lt.x0 + lt.x1) / 2 + 0.3, y / 2, (lt.z0 + lt.z1) / 2), C.stone, M.Cobblestone, { name = "Plinth" })
		B.box(V(lt.x1 - lt.x0, 0.3, lt.z1 - lt.z0), CF((lt.x0 + lt.x1) / 2, y + 0.15 - 0.3, (lt.z0 + lt.z1) / 2), C.floorDark, M.WoodPlanks, { name = "PassageFloor" })
		local wallC = B.rgb(118, 80, 48)
		-- outer wall
		B.box(V(0.6, loY - y, lt.z1 - lt.z0 + 0.6), CF(lt.x1 + 0.3, (y + loY) / 2, (lt.z0 + lt.z1) / 2), wallC, M.WoodPlanks, { name = "OuterWall" })
		-- end walls with sloped tops; the far end has the little door
		local exitHole = { 37.8, 41.6, y, y + 7.3 }
		for _, z in { lt.z0, lt.z1 } do
			local holes = if z == lt.z1 then { exitHole } else {}
			B.flatWall("x", z, lt.x0, lt.x1 + 0.6, y, loY, 0.6, holes, wallC, M.WoodPlanks, { name = "EndWall" })
			B.wedge(V(0.6, hiY - loY, lt.x1 + 0.6 - lt.x0), CF((lt.x0 + lt.x1 + 0.6) / 2, (hiY + loY) / 2, z) * CFrame.Angles(0, -math.pi / 2, 0), wallC, M.WoodPlanks, { name = "EndGable" })
		end
		-- roof
		local rp0 = V(lt.x0, hiY + 0.3, (lt.z0 + lt.z1) / 2)
		local rp1 = V(lt.x1 + 1.4, loY - 0.35, (lt.z0 + lt.z1) / 2)
		local dir = rp1 - rp0
		local n = V(-dir.Y, dir.X, 0).Unit
		local cf = CFrame.lookAt((rp0 + rp1) / 2 + n * 0.4, rp1 + n * 0.4, n)
		B.box(V(lt.z1 - lt.z0 + 1.6, 0.8, (rp1 - rp0).Magnitude), cf, C.roof, M.RoofShingles, { name = "LeanRoof" })
		-- firewood stacked against the outside so nobody looks twice
		for row = 0, 5 do
			local z = lt.z0 + 1
			while z < lt.z1 - 1 do
				B.cyl(V(1.6, 0.85, 0.85), CF(lt.x1 + 1.5, 0.45 + row * 0.8, z + (row % 2) * 0.4) * CFrame.Angles(0, 0, 0), B.vary(B.rgb(150, 104, 64), 0.12), M.Wood, { name = "Firewood" })
				z += 0.86
			end
		end
	end)

	B.pop()

	-------------------------------------------------- doors
	local gy, uy = L.yGround, L.yUpper
	local function frameAt(x, y, z, look)
		local p = V(x, y, z)
		return CFrame.lookAt(p, p + look)
	end
	door({
		id = "FrontDoor",
		frame = frameAt(0, gy, L.Z0, V(0, 0, -1)),
		w = FRONT_DOOR.w,
		h = FRONT_DOOR.h,
		wallT = d,
		lockable = true,
		knocker = true,
		color = B.rgb(150, 50, 38),
	})
	door({
		id = "BackDoor",
		frame = frameAt(0, gy, L.Z1, V(0, 0, 1)),
		w = FRONT_DOOR.w,
		h = FRONT_DOOR.h,
		wallT = d,
		lockable = true,
		color = B.rgb(70, 92, 66),
	})
	local inner = { w = 4.4, h = 8.6, wallT = L.intT }
	local function innerDoor(id, x, y, z, look, style, color)
		door({
			id = id,
			frame = frameAt(x, y, z, look),
			w = inner.w,
			h = inner.h,
			wallT = inner.wallT,
			style = style or "panel",
			lockable = true,
			pickable = true,
			color = color,
		})
	end
	innerDoor("BathroomDoor", 12, gy, -20, V(-1, 0, 0))
	innerDoor("CellarDoor", 12, gy, -3.5, V(-1, 0, 0), "plank", B.rgb(120, 80, 46))
	innerDoor("StudyDoor", 12, gy, 17, V(-1, 0, 0), "panel", B.rgb(110, 62, 34))
	innerDoor("GuestDoor", -24, uy, -6, V(0, 0, 1))
	innerDoor("SewingDoor", 24, uy, -6, V(0, 0, 1))
	innerDoor("MasterDoor", -24, uy, 6, V(0, 0, -1), "panel", B.rgb(120, 70, 38))
	innerDoor("JuneDoor", 0, uy, 6, V(0, 0, -1), "panel", B.rgb(214, 196, 150))
	innerDoor("AtticDoor", 24, uy, 6, V(0, 0, -1), "plank", B.rgb(110, 76, 46))
	-- the little door at the end of the narrow way: no lock, it only latches
	door({
		id = "PassageExit",
		frame = frameAt(39.7, gy, L.leanTo.z1, V(0, 0, 1)),
		w = 3.2,
		h = 7.0,
		wallT = 0.6,
		style = "plank",
		color = B.rgb(108, 74, 44),
	})

	Cabin.walls = walls
	Cabin.shelfDoor = SHELF_DOOR
	return structure
end

return Cabin
