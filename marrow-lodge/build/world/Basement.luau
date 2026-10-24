-- The cellar: workshop, furnace, the locked key room, and the old coal chute that
-- climbs out under the coal shed in the yard.

local B = require("../lib/B")
local P = require("./Props")
local Kit = require("./Kit")
local L = require("./Layout")
local Story = require("./Story")
local Pickups = require("./Pickups")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame
local Enum = B.Enum

local Basement = {}

local N, S, E, W = V(0, 0, 1), V(0, 0, -1), V(1, 0, 0), V(-1, 0, 0)

local function at(x, y, z, look)
	local p = V(x, y, z)
	return CFrame.lookAt(p, p + (look or S))
end

local by = L.yBasement
local ceil = L.yGround - 1

local KEYROOM = { x0 = 16, z1 = -12, doorX = 25 }

local function cellar()
	B.within("Cellar", function()
		-- key room walls
		local t = 0.8
		local dw, dh = Kit.doorHole(4.4, 8.6)
		B.flatWall("x", KEYROOM.z1, KEYROOM.x0, L.bX1, by, ceil, t, { { KEYROOM.doorX - dw, KEYROOM.doorX + dw, by, by + dh } }, B.rgb(150, 110, 70), M.WoodPlanks, { name = "KeyRoomWall" })
		B.flatWall("z", KEYROOM.x0, L.bZ0, KEYROOM.z1 + t / 2, by, ceil, t, {}, B.rgb(150, 110, 70), M.WoodPlanks, { name = "KeyRoomWall" })

		-- key room contents
		local board = P.keyRack(at(25, by + 6.2, L.bZ0, N), 9)
		board:SetAttribute("KeyRack", true)
		B.prompt(board, {
			Name = "KeyPrompt",
			ActionText = "Take Key",
			ObjectText = "",
			HoldDuration = 0.8,
			MaxActivationDistance = 7,
		})
		local bench = P.table(at(L.bX1 - 2.0, by, -19.5, W), 5.0, 2.6, 3.2, B.rgb(110, 76, 46))
		P.keyCutter(bench * CF(0, -3.2, 0))
		P.note(bench * CF(-1.5, 0.02, 0.4) * CFrame.Angles(0, 0.3, 0), Story.ledger.text, Story.ledger.style)
		P.wallClock(at(KEYROOM.x0 + 0.45, by + 7.5, -19.5, E), 0.8)
		-- iron safe
		local safe = at(19, by, -25.2, N)
		B.box(V(3, 3.6, 2.6), safe * CF(0, 1.8, 0), B.rgb(40, 52, 46), M.Metal, { name = "Safe" })
		B.cyl(V(0.2, 1.0, 1.0), safe * CF(0, 2.0, -1.35) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, { name = "Dial", collide = false })
		B.box(V(2.4, 0.15, 0.1), safe * CF(0, 3.2, -1.32), C.brass, M.Metal, { name = "Trim", collide = false })
		P.bareBulb(V(25, ceil, -19.5), 2.0, { range = 18, brightness = 1.1 })

		-- furnace and coal
		P.furnace(at(17, by, 19, S))
		local bin = { x0 = 28.5, x1 = L.bX1, z0 = 19 }
		B.box(V(bin.x1 - bin.x0, 2.8, 0.4), CFrame.new((bin.x0 + bin.x1) / 2, by + 1.4, bin.z0), B.rgb(110, 76, 46), M.WoodPlanks, { name = "CoalBin" })
		B.box(V(0.4, 2.8, L.bZ1 - bin.z0), CFrame.new(bin.x0, by + 1.4, (bin.z0 + L.bZ1) / 2), B.rgb(110, 76, 46), M.WoodPlanks, { name = "CoalBin" })
		P.coalPile(at((bin.x0 + bin.x1) / 2, by, (bin.z0 + L.bZ1) / 2, S), 3.2)
		local shovel = at(27.5, by, 18.2, S)
		B.box(V(0.15, 4.2, 0.15), shovel * CF(0, 2.6, 0) * CFrame.Angles(math.rad(-14), 0, 0), B.rgb(140, 100, 60), M.Wood, { name = "ShovelShaft" })
		B.box(V(1.0, 1.2, 0.08), shovel * CF(0, 0.5, -0.1) * CFrame.Angles(math.rad(-14), 0, 0), C.iron, M.Metal, { name = "ShovelBlade" })
		B.within("DanaNote", function()
			P.wallNote(at(14, by + 6.5, L.bZ1, S), Story.danaNote.text, Story.danaNote.style)
		end)

		-- workshop along the west wall
		local wb = P.workbench(at(L.bX0 + 1.4, by, -6, E), 10)
		Pickups.hairpin(wb * CF(2.0, 0, -0.6) * CFrame.Angles(0, 0.5, 0))
		P.lantern((wb * CF(-3.0, 0, 0)).Position, { range = 12, brightness = 0.7 })
		P.jarShelf(at(-27, by, L.bZ1 - 0.8, S), 9, 4)
		P.jarShelf(at(-17, by, L.bZ1 - 0.8, S), 9, 4)
		for i = 0, 2 do
			P.barrel(at(-31 + i * 2.6, by, -24.6, N), 3.6)
		end
		P.barrel(at(-29.7, by, -24.6, N) * CF(0, 3.6, 0), 3.0)
		-- wash tub and mangle
		local wt = V(-8, by, 23)
		B.vcyl(2.2, 3.2, wt + V(0, 1.1, 0), B.rgb(150, 150, 146), M.Metal, { name = "Washtub" })
		B.vcyl(0.15, 2.9, wt + V(0, 2.2, 0), B.rgb(170, 190, 196), M.Glass, { name = "Water", collide = false, transparency = 0.3 })
		B.box(V(1.4, 1.8, 0.15), CFrame.new(wt + V(0.6, 2.6, 0)) * CFrame.Angles(0, 0, 0.25), B.rgb(170, 170, 160), M.Metal, { name = "Washboard", collide = false })
		-- water heater
		B.vcyl(6.4, 2.4, V(-2, by + 3.2, 24.5), B.rgb(196, 190, 176), M.Metal, { name = "Heater" })
		B.rod(V(-2, by + 6.4, 24.5), V(-2, ceil, 24.5), 0.3, B.rgb(160, 110, 70), M.Metal, { name = "Pipe" })
		for i = 0, 4 do
			P.crate(at(-30 + (i % 2) * 2.5, by, 8 + math.floor(i / 2) * 2.6, E) * CF(0, 0, 0), 2.4)
		end
		P.crate(at(-30, by, 8, E) * CF(0, 2.4, 0) * CFrame.Angles(0, 0.3, 0), 1.8)
		P.sheetCovered(at(-20, by, 10, S), 3.6, 3.8, 2.4)
		P.sheetCovered(at(4, by, -22, N), 6, 2.6, 2.6)
		-- bare bulbs, one by the stair foot
		for _, p in { V(-24, ceil, -10), V(-24, ceil, 14), V(-6, ceil, 8), V(6, ceil, -14), V(30, ceil, 8), V(24, ceil, 22) } do
			P.bareBulb(p, 2.2, { range = 20, brightness = 1.15 })
		end
		P.rug(at(-26, by, -6, E), 6, 9, B.rgb(120, 70, 46), B.rgb(170, 120, 60))

		-- wine rack along the front wall
		local wr = at(0, by, L.bZ0 + 0.9, N)
		B.box(V(12, 7.2, 1.6), wr * CF(0, 3.6, 0.1), B.rgb(110, 76, 46), M.Wood, { name = "WineRack" })
		for row = 0, 4 do
			for col = 0, 9 do
				local x = -5.4 + col * 1.2
				local y = 0.9 + row * 1.3
				B.box(V(1.0, 1.0, 0.1), wr * CF(x, y, -0.72), B.rgb(70, 46, 28), M.Wood, { name = "Cubby", collide = false })
				if (row * 7 + col * 3) % 5 ~= 0 then
					B.cyl(V(1.3, 0.55, 0.55), wr * CF(x, y, -0.4) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(40, 70, 46), M.Glass, { name = "Bottle", collide = false, transparency = 0.15 })
				end
			end
		end
		-- shelves of preserves by the stair foot
		P.jarShelf(at(L.bX1 - 0.8, by, 9, W), 9, 4)
		-- laundry line with two sheets near the wash tub
		local l0, l1 = V(-15, by + 8.2, 17.5), V(1, by + 8.2, 17.5)
		B.rod(l0, l1, 0.06, B.rgb(220, 214, 200), M.Fabric, { name = "Line", collide = false })
		for _, x in { -11, -5 } do
			B.box(V(4.2, 5.4, 0.08), CFrame.new(x, by + 5.5, 17.5) * CFrame.Angles(0, 0, math.rad(B.range(-3, 3))), B.rgb(244, 240, 228), M.Fabric, { name = "Sheet", collide = false })
		end
		-- someone slept down here
		local camp = at(10, by, -18, E)
		B.box(V(3.2, 0.4, 7), camp * CF(0, 0.2, 0), B.rgb(80, 96, 70), M.Fabric, { name = "Bedroll" })
		B.box(V(2.4, 0.6, 1.2), camp * CF(0, 0.5, 2.8), B.rgb(200, 190, 160), M.Fabric, { name = "RolledCoat", collide = false })
		for i = 0, 2 do
			B.vcyl(0.7, 0.6, (camp * CF(2.3 + i * 0.7, 0.35, -1 + B.range(-0.3, 0.3))).Position, B.rgb(170, 170, 160), M.Metal, { name = "Tin", collide = false })
		end
		P.lantern((camp * CF(2.4, 0, 1.6)).Position, { range = 9, brightness = 0.45 })
		-- cobwebs in the corners
		for _, c in { V(L.bX0 + 0.5, ceil - 0.5, L.bZ0 + 0.5), V(L.bX0 + 0.5, ceil - 0.5, L.bZ1 - 0.5), V(L.bX1 - 0.5, ceil - 0.5, L.bZ1 - 0.5) } do
			for k = 0, 2 do
				B.box(V(2.6, 0.03, 0.03), CFrame.new(c) * CFrame.Angles(0, k * 0.5 + 0.4, math.rad(-35)), B.rgb(240, 240, 236), M.SmoothPlastic, { name = "Web", collide = false, transparency = 0.4, shadow = false })
			end
		end
	end)

	-- the copy room stays locked until someone with a key opens it
	B.push(Basement.doorFolder)
	Kit.door({
		id = "KeyRoomDoor",
		name = "KeyRoomDoor",
		frame = at(KEYROOM.doorX, by, KEYROOM.z1, N),
		w = 4.4,
		h = 8.6,
		wallT = 0.8,
		style = "plank",
		lockable = true,
		pickable = false,
		locked = true,
		color = B.rgb(96, 60, 34),
	})
	B.pop()
end

local function chute()
	local ch = L.chute
	local x0, x1 = ch.x0, ch.x1
	local cx = (x0 + x1) / 2
	local w = x1 - x0
	local wallOut = L.Z1 + L.stoneT / 2
	local yTop = 0 -- the chute climbs to ground level
	local slope = (yTop - by) / (ch.rampEnd - ch.rampStart)
	local function floorY(z)
		if z <= ch.rampStart then
			return by
		end
		return math.min(yTop, by + (z - ch.rampStart) * slope)
	end

	B.within("CoalChute", function()
		-- the boards nailed across the opening on the cellar side
		B.within("ChuteBoards", function(m)
			m:SetAttribute("ChuteBoards", true)
			local z = L.bZ1 - 0.15
			local first
			for k = 0, 3 do
				local y = by + 1.1 + k * 1.65
				local tilt = math.rad(({ 2, -3, 1, -2 })[k + 1])
				local bd = B.box(V(w + 1.6, 1.3, 0.3), CFrame.new(cx, y, z) * CFrame.Angles(0, 0, tilt), B.vary(B.rgb(130, 92, 56), 0.08), M.WoodPlanks, { name = "Board" })
				first = first or bd
				for _, sx in { -1, 1 } do
					B.ball(0.14, (bd.CFrame * CF(sx * (w / 2 + 0.4), 0, -0.17)).Position, C.iron, M.Metal, { name = "Nail", collide = false })
				end
			end
			B.box(V(w, ch.top - by, L.stoneT), CFrame.new(cx, (by + ch.top) / 2, L.Z1), C.soot, M.SmoothPlastic, {
				name = "Blocker",
				transparency = 1,
				shadow = false,
			})
			B.prompt(B.attach(first, CF(0, 2.4, -0.3), "PryPoint"), {
				Name = "PryPrompt",
				ActionText = "Pry",
				ObjectText = "",
				HoldDuration = 2.5,
				MaxActivationDistance = 7,
			}, { Need = "Crowbar" })
		end)

		-- tunnel
		local tunnel = B.folder("Tunnel")
		B.push(tunnel)
		local soot = B.rgb(58, 54, 50)
		-- landing then ramp
		B.box(V(w, 1, ch.rampStart - L.bZ1 + 0.2), CFrame.new(cx, by - 0.5, (L.bZ1 + ch.rampStart) / 2), soot, M.Slate, { name = "ChuteFloor" })
		local p0 = V(cx, by, ch.rampStart)
		local p1 = V(cx, yTop, ch.rampEnd)
		local dir = (p1 - p0).Unit
		local n = V(0, dir.Z, -dir.Y)
		B.between(p0 - n * 0.4, p1 - n * 0.4, w, 0.8, soot, M.Slate, { name = "Ramp" }, n)
		-- cleats so it reads as a chute
		local len = (p1 - p0).Magnitude
		local k = 1.0
		while k < len - 0.5 do
			local c = p0 + dir * k
			B.between(c - V(w / 2 - 0.2, 0, 0) + n * 0.1, c + V(w / 2 - 0.2, 0, 0) + n * 0.1, 0.35, 0.2, B.rgb(90, 66, 44), M.Wood, { name = "Cleat" }, n)
			k += 1.5
		end
		-- side walls (stop at ground level outside the shed, run a little higher inside it)
		local shed = L.shed
		for _, sx in { x0 - 0.5, x1 + 0.5 } do
			B.box(V(1, yTop - by + 1, shed.z0 - wallOut), CFrame.new(sx, (by - 1 + yTop) / 2, (wallOut + shed.z0) / 2), B.rgb(110, 102, 94), M.Cobblestone, { name = "TunnelWall" })
			B.box(V(1, yTop + 0.2 - by + 1, ch.rampEnd - shed.z0), CFrame.new(sx, (by - 1 + yTop + 0.2) / 2, (shed.z0 + ch.rampEnd) / 2), B.rgb(110, 102, 94), M.Cobblestone, { name = "TunnelWall" })
		end
		-- ceiling: flat over the landing, then parallel to the ramp until the shed
		local headroom = 7
		B.box(V(w + 2, 1, ch.rampStart - wallOut), CFrame.new(cx, ch.top + 0.5, (wallOut + ch.rampStart) / 2), soot, M.Slate, { name = "ChuteCeiling" })
		local c0 = V(cx, by + headroom, ch.rampStart)
		local zEnd = shed.z0
		local c1 = V(cx, floorY(zEnd) + headroom, zEnd)
		B.between(c0 + n * 0.5, c1 + n * 0.5, w + 2, 1, soot, M.Slate, { name = "ChuteCeiling" }, n)
		-- timber frames
		for _, z in { wallOut + 0.4, ch.rampStart + 2, ch.rampStart + 4.2 } do
			local fy = floorY(z)
			local top = if z <= ch.rampStart then ch.top else fy + headroom
			for _, sx in { x0 + 0.25, x1 - 0.25 } do
				B.box(V(0.5, top - fy, 0.5), CFrame.new(sx, (fy + top) / 2, z), C.beam, M.Wood, { name = "Prop" })
			end
			B.box(V(w, 0.5, 0.5), CFrame.new(cx, top - 0.25, z), C.beam, M.Wood, { name = "Header" })
		end
		P.lantern(V(cx, ch.top - 1.6, ch.rampStart - 0.6), { range = 12, brightness = 0.55 }, 0.2)
		-- loose coal on the ramp
		for i = 1, 14 do
			local z = B.range(ch.rampStart, ch.rampEnd - 2)
			local s = B.range(0.3, 0.6)
			B.box(V(s, s * 0.7, s), CFrame.new(cx + B.range(-w / 2 + 0.6, w / 2 - 0.6), floorY(z) + s * 0.35, z) * CFrame.Angles(B.range(0, 3), B.range(0, 3), 0), B.vary(B.rgb(26, 26, 28), 0.3), M.Slate, { name = "Coal", collide = false })
		end
		B.pop()
	end)

	-- coal shed sitting over the top of the chute
	B.within("CoalShed", function()
		local s = L.shed
		local cxs = (s.x0 + s.x1) / 2
		local wallH = 8
		local ld = 1.0
		local doorW, doorH = 4, 7
		local dw, dh = Kit.doorHole(doorW, doorH)
		-- floor with the pit cut out
		for _, r in B.rectsMinus({ s.x0, s.x1, s.z0, s.z1 }, { { x0 - 1, x1 + 1, s.z0, ch.rampEnd } }) do
			B.box(V(r[2] - r[1], 0.3, r[4] - r[3]), CFrame.new((r[1] + r[2]) / 2, 0.05, (r[3] + r[4]) / 2), B.rgb(110, 78, 50), M.WoodPlanks, { name = "ShedFloor" })
		end
		B.logWall("z", s.x0, s.z0 - 0.6, s.z1 + 0.6, 0, wallH, ld, {}, { chinkFrom = s.z0, chinkTo = s.z1 })
		B.logWall("z", s.x1, s.z0 - 0.6, s.z1 + 0.6, 0, wallH, ld, {}, { chinkFrom = s.z0, chinkTo = s.z1 })
		B.logWall("x", s.z0, s.x0, s.x1, 0, wallH, ld, {}, {})
		B.logWall("x", s.z1, s.x0, s.x1, 0, wallH, ld, { { cxs - dw, cxs + dw, 0, dh } }, {})
		-- gable ends + roof
		local rise = 4.2
		for _, z in { s.z0, s.z1 } do
			B.tent(CFrame.new(cxs, wallH, z), s.x1 - s.x0 + 0.6, rise, 0.8, B.rgb(120, 80, 48), M.WoodPlanks, { name = "Gable" })
		end
		local halfW = (s.x1 - s.x0) / 2
		local over = halfW + 1.2
		for _, side in { -1, 1 } do
			local ridge = V(cxs, wallH + rise, (s.z0 + s.z1) / 2)
			local eave = V(cxs + side * over, wallH + rise - over * rise / halfW, ridge.Z)
			local d = (eave - ridge).Unit
			local n = V(side * math.abs(d.Y), math.abs(d.X), 0).Unit
			B.between(ridge + n * 0.3, eave + n * 0.3, s.z1 - s.z0 + 2, 0.5, C.roof, M.RoofShingles, { name = "ShedRoof" }, n)
		end
		B.cyl(V(s.z1 - s.z0 + 2.2, 0.7, 0.7), CFrame.new(cxs, wallH + rise + 0.75, (s.z0 + s.z1) / 2) * CFrame.Angles(0, math.pi / 2, 0), C.logDark, M.Wood, { name = "Ridge" })
		-- sacks, a lantern
		for i = 0, 2 do
			B.box(V(1.6, 2.2, 1.2), CFrame.new(s.x0 + 1.6, 1.2, s.z1 - 2 - i * 1.5) * CFrame.Angles(0, 0, math.rad(B.range(-8, 8))), B.rgb(150, 130, 100), M.Fabric, { name = "Sack" })
		end
		P.lantern(V(s.x1 - 1.5, 5.6, s.z1 - 1.5), { range = 14, brightness = 0.8 })
		B.box(V(0.6, 0.3, 0.6), CFrame.new(s.x1 - 1.2, 5.45, s.z1 - 1.5), C.iron, M.Metal, { name = "Bracket", collide = false })
	end)

	B.push(Basement.doorFolder)
	do
		local s = L.shed
		Kit.door({
			id = "ShedDoor",
			name = "ShedDoor",
			frame = at((s.x0 + s.x1) / 2, 0.2, s.z1, N),
			w = 4,
			h = 7,
			wallT = 1.0,
			style = "plank",
			color = B.rgb(120, 84, 50),
		})
	end
	B.pop()
end

function Basement.build(root, doorFolder)
	Basement.doorFolder = doorFolder
	local f = B.folder("Basement", root)
	B.push(f)
	cellar()
	chute()
	B.pop()
	return f
end

return Basement
