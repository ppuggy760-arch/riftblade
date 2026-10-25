-- Furniture and small props. Every function takes `at`: a CFrame on the floor under the
-- object, with LookVector pointing the way the object faces (its front is local -Z).

local B = require("../lib/B")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame
local Instance = B.Instance
local Enum = B.Enum
local roblox = B.roblox

local P = {}

local function bx(at, sx, sy, sz, x, y, z, color, mat, o)
	return B.box(V(sx, sy, sz), at * CF(x, y, z), color, mat, o)
end

local function post(at, x, z, h, d, color, mat, o)
	return B.vcyl(h, d, (at * CF(x, h / 2, z)).Position, color, mat, o)
end

local function nc(o)
	o = o or {}
	o.collide = false
	return o
end

---------------------------------------------------------------- light sources

function P.flame(pos, size, lit)
	local f = B.ball(size or 0.22, pos, C.flame, M.Neon, nc({ name = "Flame", shadow = false }))
	B.ball((size or 0.22) * 0.55, pos + V(0, (size or 0.22) * 0.35, 0), B.rgb(255, 236, 170), M.Neon, nc({ name = "FlameTip", shadow = false }))
	if lit then
		B.warmLight(f, lit.range or 8, lit.brightness or 0.8, lit.shadows, lit.color)
	end
	f:SetAttribute("Flicker", true)
	return f
end

function P.candle(pos, h, lit)
	h = h or 0.8
	B.vcyl(h, 0.28, pos + V(0, h / 2, 0), B.rgb(246, 236, 210), M.SmoothPlastic, nc({ name = "Candle" }))
	B.vcyl(0.12, 0.04, pos + V(0, h + 0.06, 0), C.soot, M.SmoothPlastic, nc({ name = "Wick" }))
	return P.flame(pos + V(0, h + 0.2, 0), 0.2, lit)
end

function P.candlestick(pos, h, lit)
	B.vcyl(0.12, 0.6, pos + V(0, 0.06, 0), C.brass, M.Metal, nc({ name = "Dish" }))
	B.vcyl(0.6, 0.14, pos + V(0, 0.4, 0), C.brass, M.Metal, nc({ name = "Stem" }))
	return P.candle(pos + V(0, 0.7, 0), h or 0.7, lit)
end

function P.tableLamp(at, shade, lit)
	shade = shade or B.rgb(244, 220, 170)
	B.vcyl(0.15, 0.9, (at * CF(0, 0.08, 0)).Position, C.brass, M.Metal, nc({ name = "LampFoot" }))
	B.ball(0.95, (at * CF(0, 0.6, 0)).Position, B.rgb(170, 70, 50), M.SmoothPlastic, nc({ name = "LampBody" }))
	B.vcyl(0.9, 0.12, (at * CF(0, 1.4, 0)).Position, C.brass, M.Metal, nc({ name = "LampStem" }))
	local bulb = B.ball(0.42, (at * CF(0, 1.85, 0)).Position, B.rgb(255, 226, 160), M.Neon, nc({ name = "Bulb", shadow = false }))
	B.vcyl(0.95, 1.6, (at * CF(0, 2.05, 0)).Position, shade, M.Fabric, nc({ name = "Shade", transparency = 0.15, shadow = false }))
	B.warmLight(bulb, (lit and lit.range) or 15, (lit and lit.brightness) or 1.1, lit and lit.shadows)
	bulb:SetAttribute("Flicker", true)
	return bulb
end

function P.floorLamp(at, shade)
	B.vcyl(0.2, 1.4, (at * CF(0, 0.1, 0)).Position, C.iron, M.Metal, nc({ name = "LampFoot" }))
	B.vcyl(5.6, 0.16, (at * CF(0, 2.9, 0)).Position, C.brass, M.Metal, nc({ name = "LampStem" }))
	local bulb = B.ball(0.5, (at * CF(0, 5.6, 0)).Position, B.rgb(255, 226, 160), M.Neon, nc({ name = "Bulb", shadow = false }))
	B.vcyl(1.2, 2.0, (at * CF(0, 5.9, 0)).Position, shade or B.rgb(236, 206, 150), M.Fabric, nc({ name = "Shade", transparency = 0.15, shadow = false }))
	B.warmLight(bulb, 18, 1.2, true)
	bulb:SetAttribute("Flicker", true)
	return bulb
end

function P.bankerLamp(at)
	bx(at, 1.0, 0.12, 0.6, 0, 0.06, 0, C.brass, M.Metal, nc({ name = "Base" }))
	B.vcyl(1.0, 0.1, (at * CF(0, 0.6, 0.15)).Position, C.brass, M.Metal, nc({ name = "Stem" }))
	B.cyl(V(1.5, 0.75, 0.75), at * CF(0, 1.15, -0.05), B.rgb(30, 110, 60), M.Glass, nc({ name = "Shade", transparency = 0.12, reflectance = 0.2, shadow = false }))
	local bulb = B.ball(0.3, (at * CF(0, 1.0, -0.05)).Position, B.rgb(255, 226, 160), M.Neon, nc({ name = "Bulb", shadow = false }))
	B.warmLight(bulb, 11, 1.0)
	bulb:SetAttribute("Flicker", true)
end

function P.lantern(pos, lit, hang)
	local iron = C.iron
	if hang then
		B.rod(pos + V(0, 1.35, 0), pos + V(0, 1.35 + hang, 0), 0.08, iron, M.Metal, nc({ name = "Chain" }))
	end
	B.box(V(0.9, 0.12, 0.9), CFrame.new(pos + V(0, 0.06, 0)), iron, M.Metal, nc({ name = "LanternBase" }))
	B.box(V(0.8, 0.9, 0.8), CFrame.new(pos + V(0, 0.6, 0)), B.rgb(255, 230, 170), M.Glass, nc({ name = "LanternGlass", transparency = 0.45, shadow = false }))
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.box(V(0.08, 0.95, 0.08), CFrame.new(pos + V(sx * 0.4, 0.6, sz * 0.4)), iron, M.Metal, nc({ name = "LanternBar" }))
		end
	end
	B.tent(CFrame.new(pos + V(0, 1.03, 0)), 0.95, 0.35, 0.95, iron, M.Metal, nc({ name = "LanternCap" }))
	B.vcyl(0.2, 0.25, pos + V(0, 1.45, 0), iron, M.Metal, nc({ name = "LanternRing" }))
	return P.flame(pos + V(0, 0.55, 0), 0.32, lit or { range = 14, brightness = 1.1 })
end

-- Wall sconce. cf: on the wall surface, LookVector pointing out into the room.
function P.sconce(cf, lit)
	B.box(V(0.6, 1.1, 0.12), cf * CF(0, 0, -0.06), C.brass, M.Metal, nc({ name = "Backplate" }))
	B.box(V(0.12, 0.12, 0.7), cf * CF(0, -0.2, -0.4), C.brass, M.Metal, nc({ name = "Arm" }))
	B.vcyl(0.12, 0.5, (cf * CF(0, -0.15, -0.75)).Position, C.brass, M.Metal, nc({ name = "Cup" }))
	B.vcyl(0.9, 0.55, (cf * CF(0, 0.35, -0.75)).Position, B.rgb(255, 236, 200), M.Glass, nc({ name = "Chimney", transparency = 0.55, shadow = false }))
	return P.candle((cf * CF(0, -0.1, -0.75)).Position, 0.5, lit or { range = 13, brightness = 0.9 })
end

-- Iron ring chandelier hanging from `top` (a point on the ceiling).
function P.chandelier(top, drop, radius, n)
	local centre = top - V(0, drop, 0)
	B.rod(top, centre + V(0, 0.5, 0), 0.12, C.iron, M.Metal, nc({ name = "Chain" }))
	for i = 0, 3 do
		local a = i * math.pi / 2
		B.rod(centre + V(0, 0.5, 0), centre + V(math.cos(a) * radius, -0.1, math.sin(a) * radius), 0.08, C.iron, M.Metal, nc({ name = "Strut" }))
	end
	local segs = 12
	for i = 0, segs - 1 do
		local a0, a1 = i / segs * math.pi * 2, (i + 1) / segs * math.pi * 2
		B.rod(centre + V(math.cos(a0) * radius, -0.1, math.sin(a0) * radius), centre + V(math.cos(a1) * radius, -0.1, math.sin(a1) * radius), 0.2, C.iron, M.Metal, nc({ name = "Ring" }))
	end
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local p = centre + V(math.cos(a) * radius, 0, math.sin(a) * radius)
		B.vcyl(0.12, 0.42, p, C.iron, M.Metal, nc({ name = "Cup" }))
		P.candle(p + V(0, 0.05, 0), 0.6, nil)
	end
	local core = B.ball(0.5, centre + V(0, 0.6, 0), C.iron, M.Metal, nc({ name = "Boss" }))
	B.warmLight(core, radius * 5 + 12, 1.4, true)
	core:SetAttribute("Flicker", true)
end

function P.bareBulb(top, drop, lit)
	local p = top - V(0, drop, 0)
	B.rod(top, p + V(0, 0.4, 0), 0.06, C.soot, M.SmoothPlastic, nc({ name = "Cord" }))
	B.vcyl(0.4, 0.3, p + V(0, 0.35, 0), B.rgb(60, 50, 40), M.Metal, nc({ name = "Socket" }))
	local bulb = B.ball(0.55, p, B.rgb(255, 214, 140), M.Neon, nc({ name = "Bulb", shadow = false }))
	B.warmLight(bulb, (lit and lit.range) or 16, (lit and lit.brightness) or 1.1, true)
	bulb:SetAttribute("Flicker", true)
	return bulb
end

function P.pendant(top, drop, shadeColor)
	local p = top - V(0, drop, 0)
	B.rod(top, p + V(0, 0.6, 0), 0.06, C.soot, M.SmoothPlastic, nc({ name = "Cord" }))
	B.vcyl(0.5, 0.5, p + V(0, 0.55, 0), C.brass, M.Metal, nc({ name = "Cap" }))
	B.vcyl(0.7, 1.6, p + V(0, 0.15, 0), shadeColor or B.rgb(170, 110, 50), M.Metal, nc({ name = "Shade" }))
	local bulb = B.ball(0.5, p - V(0, 0.2, 0), B.rgb(255, 222, 150), M.Neon, nc({ name = "Bulb", shadow = false }))
	B.warmLight(bulb, 17, 1.2, true)
	bulb:SetAttribute("Flicker", true)
end

---------------------------------------------------------------- soft furnishings

function P.rug(at, w, d, a, b, c)
	bx(at, w, 0.06, d, 0, 0.03, 0, a, M.Carpet, nc({ name = "Rug", shadow = false }))
	bx(at, w - 0.7, 0.07, d - 0.7, 0, 0.035, 0, b, M.Carpet, nc({ name = "RugBand", shadow = false }))
	bx(at, w - 1.3, 0.08, d - 1.3, 0, 0.04, 0, c or a, M.Carpet, nc({ name = "RugField", shadow = false }))
	bx(at, (w - 1.3) * 0.4, 0.09, (d - 1.3) * 0.4, 0, 0.045, 0, b, M.Carpet, nc({ name = "RugMedallion", shadow = false }))
end

function P.sofa(at, w, color)
	local legC = C.beam
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			bx(at, 0.35, 0.6, 0.35, sx * (w / 2 - 0.4), 0.3, sz * 1.2, legC, M.Wood)
		end
	end
	bx(at, w, 1.2, 3.0, 0, 1.2, 0.15, color, M.Fabric, { name = "Frame" })
	local n = 3
	for i = 1, n do
		local x = -w / 2 + 0.8 + (i - 0.5) * (w - 1.6) / n
		bx(at, (w - 1.6) / n - 0.08, 0.6, 2.4, x, 2.1, -0.1, B.vary(color, 0.04), M.Fabric, { name = "Cushion" })
		B.box(V((w - 1.6) / n - 0.15, 1.9, 0.6), at * CF(x, 3.0, 0.85) * CFrame.Angles(math.rad(10), 0, 0), B.vary(color, 0.04), M.Fabric, { name = "BackCushion" })
	end
	bx(at, w, 2.6, 0.7, 0, 2.5, 1.3, color, M.Fabric, { name = "Back" })
	for _, sx in { -1, 1 } do
		bx(at, 0.8, 1.9, 3.1, sx * (w / 2 - 0.4), 1.85, 0.1, color, M.Fabric, { name = "Arm" })
		B.cyl(V(3.1, 0.95, 0.95), at * CF(sx * (w / 2 - 0.4), 2.8, 0.1) * CFrame.Angles(0, math.pi / 2, 0), color, M.Fabric, { name = "ArmRoll" })
	end
	B.box(V(1.1, 1.1, 0.35), at * CF(-w / 2 + 1.3, 2.75, 0.4) * CFrame.Angles(math.rad(-15), math.rad(20), math.rad(8)), C.mustard, M.Fabric, nc({ name = "Pillow" }))
	B.box(V(1.1, 1.1, 0.35), at * CF(w / 2 - 1.3, 2.75, 0.4) * CFrame.Angles(math.rad(-15), math.rad(-20), math.rad(-8)), C.cream, M.Fabric, nc({ name = "Pillow" }))
	-- knitted throw over the back
	bx(at, 2.2, 0.12, 1.4, w * 0.18, 3.85, 1.2, B.rgb(200, 72, 52), M.Fabric, nc({ name = "Throw" }))
	bx(at, 2.2, 1.6, 0.12, w * 0.18, 3.1, 1.72, B.rgb(200, 72, 52), M.Fabric, nc({ name = "Throw" }))
end

function P.armchair(at, color, mat)
	mat = mat or M.Leather
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			bx(at, 0.3, 0.6, 0.3, sx * 1.35, 0.3, sz * 1.2, C.beam, M.Wood)
		end
	end
	bx(at, 3.2, 1.2, 3.0, 0, 1.2, 0.1, color, mat, { name = "Frame" })
	bx(at, 2.0, 0.6, 2.4, 0, 2.1, -0.15, B.vary(color, 0.05), mat, { name = "Cushion" })
	B.box(V(3.2, 3.4, 0.7), at * CF(0, 3.0, 1.3) * CFrame.Angles(math.rad(8), 0, 0), color, mat, { name = "Back" })
	for _, sx in { -1, 1 } do
		bx(at, 0.6, 1.6, 3.0, sx * 1.3, 2.3, 0.1, color, mat, { name = "Arm" })
		for k = 0, 4 do
			B.ball(0.12, (at * CF(sx * 1.3, 3.1, -1.4 + k * 0.6)).Position, C.brass, M.Metal, nc({ name = "Tack" }))
		end
	end
end

function P.rockingChair(at, color)
	color = color or B.rgb(120, 74, 40)
	for _, sx in { -1, 1 } do
		B.box(V(0.2, 0.25, 3.2), at * CF(sx * 1.0, 0.25, 0) * CFrame.Angles(math.rad(4), 0, 0), color, M.Wood, { name = "Rocker" })
		post(at, sx * 1.0, -0.9, 2.2, 0.22, color, M.Wood)
		post(at, sx * 1.0, 0.9, 5.4, 0.24, color, M.Wood)
		bx(at, 0.22, 0.2, 2.0, sx * 1.0, 3.3, -0.1, color, M.Wood, { name = "ArmRest" })
	end
	bx(at, 2.2, 0.25, 2.0, 0, 2.2, 0, color, M.Wood, { name = "Seat" })
	for k = 0, 4 do
		bx(at, 0.22, 2.6, 0.12, -0.8 + k * 0.4, 3.8, 0.95, color, M.Wood, { name = "Spindle" })
	end
	bx(at, 2.2, 0.4, 0.2, 0, 5.2, 0.95, color, M.Wood, { name = "Crest" })
	bx(at, 1.8, 0.2, 1.7, 0, 2.38, 0, B.rgb(170, 60, 50), M.Fabric, nc({ name = "SeatPad" }))
end

function P.chair(at, color)
	color = color or B.rgb(130, 80, 42)
	for _, sx in { -1, 1 } do
		post(at, sx * 0.85, -0.8, 2.3, 0.22, color, M.Wood)
		post(at, sx * 0.85, 0.8, 5.6, 0.24, color, M.Wood)
		B.ball(0.3, (at * CF(sx * 0.85, 5.65, 0.8)).Position, color, M.Wood, nc({ name = "Finial" }))
	end
	bx(at, 2.0, 0.25, 1.9, 0, 2.35, 0, color, M.Wood, { name = "Seat" })
	for _, y in { 3.4, 4.2, 5.0 } do
		bx(at, 1.7, 0.32, 0.12, 0, y, 0.8, color, M.Wood, nc({ name = "Slat" }))
	end
	bx(at, 1.7, 0.1, 0.12, 0, 1.0, -0.8, color, M.Wood, nc({ name = "Stretcher" }))
	bx(at, 1.6, 0.1, 1.5, 0, 2.5, 0, B.rgb(200, 170, 120), M.Fabric, nc({ name = "Rush" }))
end

function P.adirondack(at, color)
	color = color or B.rgb(214, 160, 52)
	for _, sx in { -1, 1 } do
		B.box(V(0.25, 0.5, 3.2), at * CF(sx * 1.1, 0.9, 0) * CFrame.Angles(math.rad(8), 0, 0), color, M.WoodPlanks, { name = "Rail" })
		post(at, sx * 1.1, -1.3, 2.6, 0.3, color, M.WoodPlanks)
		bx(at, 0.6, 0.15, 2.6, sx * 1.3, 2.7, -0.2, color, M.WoodPlanks, { name = "Arm" })
	end
	for k = 0, 4 do
		B.box(V(2.4, 0.15, 0.45), at * CF(0, 1.1 - k * 0.05, -1.0 + k * 0.5) * CFrame.Angles(math.rad(8), 0, 0), B.vary(color, 0.04), M.WoodPlanks, { name = "SeatSlat" })
	end
	for k = 0, 4 do
		B.box(V(0.4, 4.0, 0.15), at * CF(-0.9 + k * 0.45, 3.0, 1.55) * CFrame.Angles(math.rad(22), 0, 0), B.vary(color, 0.04), M.WoodPlanks, { name = "BackSlat" })
	end
end

function P.table(at, len, wid, h, color, legStyle)
	color = color or B.rgb(132, 82, 44)
	h = h or 3.0
	bx(at, len, 0.3, wid, 0, h - 0.15, 0, color, M.WoodPlanks, { name = "Top" })
	bx(at, len - 0.6, 0.5, wid - 0.6, 0, h - 0.55, 0, B.vary(color, 0.06), M.Wood, { name = "Apron" })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			if legStyle == "log" then
				post(at, sx * (len / 2 - 0.6), sz * (wid / 2 - 0.6), h - 0.3, 0.55, B.vary(C.log, 0.06), M.Wood)
			else
				bx(at, 0.4, h - 0.3, 0.4, sx * (len / 2 - 0.5), (h - 0.3) / 2, sz * (wid / 2 - 0.5), color, M.Wood, { name = "Leg" })
			end
		end
	end
	return at * CF(0, h, 0)
end

function P.bed(at, w, len, quiltA, quiltB)
	local wood = B.rgb(132, 82, 44)
	-- head at +Z, foot at -Z
	for _, sx in { -1, 1 } do
		post(at, sx * (w / 2), len / 2, 6.2, 0.75, B.vary(C.log, 0.05), M.Wood)
		post(at, sx * (w / 2), -len / 2, 3.6, 0.7, B.vary(C.log, 0.05), M.Wood)
		B.ball(0.8, (at * CF(sx * (w / 2), 6.35, len / 2)).Position, B.vary(C.log, 0.05), M.Wood, nc({ name = "PostCap" }))
		bx(at, 0.4, 0.6, len, sx * (w / 2), 1.3, 0, wood, M.Wood, { name = "SideRail" })
	end
	for i = 0, 3 do
		B.cyl(V(w, 0.55, 0.55), at * CF(0, 2.6 + i * 0.9, len / 2), B.vary(C.log, 0.06), M.Wood, { name = "HeadLog" })
	end
	for i = 0, 1 do
		B.cyl(V(w, 0.5, 0.5), at * CF(0, 1.9 + i * 0.85, -len / 2), B.vary(C.log, 0.06), M.Wood, { name = "FootLog" })
	end
	bx(at, w - 0.5, 0.9, len - 0.6, 0, 1.95, 0, B.rgb(246, 240, 226), M.Fabric, { name = "Mattress" })
	-- patchwork quilt
	local qx, qz = 4, 5
	local qw, ql = w - 0.2, (len - 0.6) * 0.78
	local z0 = -len / 2 + 0.3
	for i = 0, qx - 1 do
		for j = 0, qz - 1 do
			local col = if (i + j) % 2 == 0 then quiltA else quiltB
			bx(at, qw / qx, 0.14, ql / qz, -qw / 2 + (i + 0.5) * qw / qx, 2.45, z0 + (j + 0.5) * ql / qz, B.vary(col, 0.08), M.Fabric, nc({ name = "Patch" }))
		end
	end
	for _, sx in { -1, 1 } do
		bx(at, 0.12, 0.9, ql, sx * (qw / 2 + 0.03), 2.05, z0 + ql / 2, quiltA, M.Fabric, nc({ name = "QuiltSide" }))
	end
	bx(at, qw, 0.9, 0.12, 0, 2.05, z0 - 0.03, quiltA, M.Fabric, nc({ name = "QuiltFoot" }))
	-- folded sheet + pillows
	bx(at, w - 0.4, 0.2, 0.6, 0, 2.5, z0 + ql + 0.3, B.rgb(250, 246, 236), M.Fabric, nc({ name = "Sheet" }))
	for _, sx in { -1, 1 } do
		B.box(V(w / 2 - 0.5, 0.65, 1.4), at * CF(sx * w / 4, 2.75, len / 2 - 1.1) * CFrame.Angles(math.rad(12), 0, 0), B.rgb(252, 248, 238), M.Fabric, nc({ name = "Pillow" }))
	end
end

function P.cot(at, color)
	-- narrow child's bed
	P.bed(at, 3.8, 7.5, color or B.rgb(214, 160, 60), B.rgb(236, 220, 186))
end

function P.nightstand(at)
	local wood = B.rgb(128, 80, 42)
	bx(at, 2.0, 2.4, 1.8, 0, 1.4, 0, wood, M.Wood, { name = "Body" })
	bx(at, 2.2, 0.15, 2.0, 0, 2.66, 0, B.vary(wood, 0.08), M.Wood, { name = "Top" })
	bx(at, 1.7, 0.8, 0.08, 0, 1.9, -0.93, B.vary(wood, 0.08), M.Wood, nc({ name = "Drawer" }))
	B.ball(0.18, (at * CF(0, 1.9, -1.02)).Position, C.brass, M.Metal, nc({ name = "Knob" }))
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			bx(at, 0.25, 0.25, 0.25, sx * 0.85, 0.12, sz * 0.75, wood, M.Wood)
		end
	end
	return at * CF(0, 2.74, 0)
end

function P.dresser(at, w, mirror)
	local wood = B.rgb(124, 76, 40)
	bx(at, w, 3.6, 2.0, 0, 2.0, 0, wood, M.Wood, { name = "Body" })
	bx(at, w + 0.3, 0.2, 2.2, 0, 3.9, 0, B.vary(wood, 0.08), M.Wood, { name = "Top" })
	for row = 0, 2 do
		local y = 0.9 + row * 1.05
		for col = 0, 1 do
			local x = -w / 4 + col * w / 2
			bx(at, w / 2 - 0.2, 0.85, 0.08, x, y, -1.03, B.vary(wood, 0.08), M.Wood, nc({ name = "Drawer" }))
			B.box(V(0.6, 0.12, 0.12), at * CF(x, y, -1.12), C.brass, M.Metal, nc({ name = "Pull" }))
		end
	end
	if mirror then
		bx(at, w * 0.6, 3.4, 0.2, 0, 5.9, 0.85, B.vary(wood, 0.05), M.Wood, { name = "MirrorFrame" })
		bx(at, w * 0.6 - 0.5, 2.9, 0.1, 0, 5.9, 0.72, B.rgb(200, 210, 210), M.Glass, nc({ name = "Mirror", reflectance = 0.55, transparency = 0.05 }))
	end
	return at * CF(0, 4.0, 0)
end

function P.wardrobe(at)
	local wood = B.rgb(116, 72, 38)
	bx(at, 4.2, 8.2, 2.2, 0, 4.3, 0, wood, M.Wood, { name = "Body" })
	bx(at, 4.6, 0.4, 2.5, 0, 8.6, 0, B.vary(wood, 0.08), M.Wood, { name = "Crown" })
	bx(at, 4.4, 0.4, 2.4, 0, 0.2, 0, B.vary(wood, 0.08), M.Wood, { name = "Plinth" })
	for _, sx in { -1, 1 } do
		bx(at, 1.95, 7.2, 0.1, sx * 1.02, 4.4, -1.13, B.vary(wood, 0.06), M.Wood, nc({ name = "WardrobeDoor" }))
		bx(at, 1.4, 2.8, 0.06, sx * 1.02, 5.9, -1.2, B.vary(wood, 0.1), M.Wood, nc({ name = "Panel" }))
		bx(at, 1.4, 2.6, 0.06, sx * 1.02, 2.6, -1.2, B.vary(wood, 0.1), M.Wood, nc({ name = "Panel" }))
		B.ball(0.2, (at * CF(sx * 0.2, 4.4, -1.25)).Position, C.brass, M.Metal, nc({ name = "Knob" }))
	end
end

function P.desk(at, w)
	local wood = B.rgb(112, 66, 34)
	bx(at, w, 0.3, 3.0, 0, 3.05, 0, wood, M.Wood, { name = "Top" })
	bx(at, w - 0.4, 0.08, 2.6, 0, 3.22, 0, B.rgb(50, 82, 56), M.Leather, nc({ name = "Blotter" }))
	for _, sx in { -1, 1 } do
		bx(at, 1.9, 2.9, 2.8, sx * (w / 2 - 1.05), 1.45, 0, B.vary(wood, 0.05), M.Wood, { name = "Pedestal" })
		for k = 0, 2 do
			bx(at, 1.6, 0.75, 0.08, sx * (w / 2 - 1.05), 0.6 + k * 0.92, -1.42, B.vary(wood, 0.08), M.Wood, nc({ name = "Drawer" }))
			B.box(V(0.5, 0.1, 0.12), at * CF(sx * (w / 2 - 1.05), 0.6 + k * 0.92, -1.5), C.brass, M.Metal, nc({ name = "Pull" }))
		end
	end
	return at * CF(0, 3.26, 0)
end

-- Bookcase with shelves of books. Returns the list of book parts and the top surface CFrame.
function P.bookshelf(at, w, h, depth, o)
	o = o or {}
	local wood = o.wood or B.rgb(110, 66, 34)
	local books = {}
	bx(at, w, h, 0.2, 0, h / 2, depth / 2 - 0.1, B.vary(wood, 0.05), M.Wood, { name = "BackBoard" })
	for _, sx in { -1, 1 } do
		bx(at, 0.3, h, depth, sx * (w / 2 - 0.15), h / 2, 0, wood, M.Wood, { name = "Side" })
	end
	bx(at, w + 0.3, 0.35, depth + 0.2, 0, h - 0.17, -0.05, wood, M.Wood, { name = "Top" })
	bx(at, w, 0.5, depth, 0, 0.25, 0, wood, M.Wood, { name = "Plinth" })
	local shelves = o.shelves or math.floor((h - 0.8) / 1.75)
	local gap = (h - 0.85) / shelves
	local palette = {
		B.rgb(120, 30, 28),
		B.rgb(40, 70, 48),
		B.rgb(36, 46, 78),
		B.rgb(96, 60, 34),
		B.rgb(170, 120, 50),
		B.rgb(210, 190, 150),
		B.rgb(70, 30, 40),
		B.rgb(30, 30, 32),
	}
	for s = 0, shelves - 1 do
		local y = 0.5 + s * gap
		if s > 0 then
			bx(at, w - 0.6, 0.18, depth - 0.25, 0, y, 0.05, B.vary(wood, 0.06), M.Wood, { name = "Shelf" })
		end
		local x = -w / 2 + 0.35
		local stop = w / 2 - 0.35
		while x < stop - 0.3 do
			local r = B.rand()
			if r < 0.08 then
				x += B.range(0.4, 0.9) -- gap
			elseif r < 0.13 and x < stop - 1.4 then
				-- a stack lying flat
				local n = math.floor(B.range(2, 5))
				for k = 0, n - 1 do
					local bw = B.range(0.9, 1.2)
					bx(at, bw, 0.22, depth * 0.7, x + 0.6, y + 0.2 + k * 0.22, 0, B.pick(palette), M.Fabric, nc({ name = "Book" }))
				end
				x += 1.3
			else
				local bw = B.range(0.22, 0.42)
				local bh = math.min(gap - 0.3, B.range(0.95, 1.45))
				local bd = depth * B.range(0.62, 0.8)
				local col = B.pick(palette)
				local lean = 0
				if B.rand() < 0.06 then
					lean = math.rad(B.range(10, 18))
				end
				local book = B.box(V(bw, bh, bd), at * CF(x + bw / 2, y + 0.09 + bh / 2, 0.05) * CFrame.Angles(0, 0, lean), col, M.Fabric, nc({ name = "Book" }))
				table.insert(books, book)
				if B.rand() < 0.4 then
					-- gilt band on the spine
					bx(at, bw * 0.9, 0.08, 0.04, x + bw / 2, y + 0.09 + bh * 0.75, -bd / 2 + 0.03, C.brass, M.Metal, nc({ name = "Gilt" }))
				end
				x += bw + 0.02 + lean * 0.8
			end
		end
	end
	return books, at * CF(0, h, 0)
end

function P.fireplace(at, w, h)
	-- at: on the floor against the wall, facing into the room
	local stone = C.stone
	local depth = 3.2
	B.within("Fireplace", function()
		-- stone mass: left and right piers, top lintel area
		local open, openH = 5.2, 4.6
		local pier = (w - open) / 2
		for _, sx in { -1, 1 } do
			bx(at, pier, h, depth, sx * (open / 2 + pier / 2), h / 2, 0, stone, M.Cobblestone, { name = "Pier" })
		end
		bx(at, open, h - openH, depth, 0, openH + (h - openH) / 2, 0, stone, M.Cobblestone, { name = "Breast" })
		-- firebox
		bx(at, open, openH, 0.6, 0, openH / 2, depth / 2 - 0.3, C.soot, M.Slate, { name = "Back" })
		for _, sx in { -1, 1 } do
			bx(at, 0.4, openH, depth - 0.6, sx * (open / 2 - 0.2), openH / 2, 0, B.rgb(60, 50, 44), M.Brick, { name = "Cheek" })
		end
		bx(at, open, 0.2, depth, 0, 0.1, 0, C.soot, M.Slate, { name = "FireFloor" })
		-- hearth slab and mantel
		bx(at, w + 1.2, 0.35, 3.2, 0, 0.17, -depth / 2 - 1.5, C.stoneDark, M.Slate, { name = "Hearth" })
		B.cyl(V(w + 1.4, 1.2, 1.2), at * CF(0, 7.0, -depth / 2 - 0.3), B.rgb(120, 74, 38), M.Wood, { name = "Mantel" })
		bx(at, w + 1.0, 0.25, 1.6, 0, 7.6, -depth / 2 - 0.35, B.rgb(120, 74, 38), M.Wood, { name = "MantelShelf" })
		-- andirons and logs
		for _, sx in { -1, 1 } do
			bx(at, 0.15, 0.9, 1.6, sx * 1.1, 0.6, -0.2, C.iron, M.Metal, nc({ name = "Andiron" }))
			B.ball(0.3, (at * CF(sx * 1.1, 1.15, -1.0)).Position, C.brass, M.Metal, nc({ name = "AndironKnob" }))
		end
		B.cyl(V(3.4, 0.7, 0.7), at * CF(0, 0.75, 0.0), B.rgb(70, 46, 30), M.Wood, nc({ name = "FireLog" }))
		B.cyl(V(3.0, 0.65, 0.65), at * CF(0.2, 1.3, 0.2) * CFrame.Angles(0, math.rad(12), 0), B.rgb(62, 40, 26), M.Wood, nc({ name = "FireLog" }))
		local ember = B.box(V(2.6, 0.3, 1.2), at * CF(0, 0.4, 0.1), B.rgb(255, 110, 30), M.Neon, nc({ name = "Embers", shadow = false }))
		local fire = Instance.new("Fire")
		fire.Size = 4.5
		fire.Heat = 7
		fire.Color = B.rgb(255, 160, 50)
		fire.SecondaryColor = B.rgb(255, 60, 10)
		fire.Parent = ember
		local glow = B.warmLight(ember, 26, 2.2, true, B.rgb(255, 150, 70))
		glow.Name = "FireGlow"
		ember:SetAttribute("Flicker", true)
		ember:SetAttribute("FireLight", true)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "Sparks"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = roblox.ColorSequence.new(B.rgb(255, 180, 80), B.rgb(255, 90, 20))
		sparks.LightEmission = 1
		sparks.Size = roblox.NumberSequence.new(0.18, 0.02)
		sparks.Lifetime = roblox.NumberRange.new(0.8, 1.6)
		sparks.Rate = 6
		sparks.Speed = roblox.NumberRange.new(2, 4)
		sparks.SpreadAngle = roblox.Vector2.new(25, 25)
		sparks.Acceleration = V(0, 1.5, 0)
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Parent = ember
		-- fire tools
		local tp = at * CF(w / 2 + 0.6, 0, -depth / 2 - 1.2)
		B.vcyl(0.15, 0.8, (tp * CF(0, 0.08, 0)).Position, C.iron, M.Metal, nc())
		B.vcyl(3.2, 0.12, (tp * CF(0, 1.7, 0)).Position, C.iron, M.Metal, nc())
		for k = 0, 2 do
			B.vcyl(2.6, 0.08, (tp * CF(-0.2 + k * 0.2, 1.4, 0.05)).Position, C.iron, M.Metal, nc())
		end
		-- stacked firewood beside the hearth
		local wp = at * CF(-w / 2 - 1.4, 0, -depth / 2 - 0.9)
		for row = 0, 3 do
			for k = 0, 3 - row do
				B.cyl(V(2.0, 0.6, 0.6), wp * CF(0, 0.35 + row * 0.5, -0.65 + k * 0.62 + row * 0.31) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, 0), B.vary(B.rgb(140, 96, 60), 0.12), M.Wood, nc({ name = "Firewood" }))
			end
		end
	end)
	return at * CF(0, 7.73, -depth / 2 - 0.35)
end

function P.piano(at)
	local wood = B.rgb(60, 32, 20)
	bx(at, 6.4, 5.0, 2.2, 0, 2.5, 0.4, wood, M.Wood, { name = "Case" })
	bx(at, 6.4, 0.5, 2.0, 0, 3.0, -1.4, wood, M.Wood, { name = "KeyBed" })
	bx(at, 5.8, 0.15, 1.0, 0, 3.3, -1.5, B.rgb(244, 238, 222), M.SmoothPlastic, nc({ name = "Keys" }))
	for k = 0, 34 do
		if k % 7 ~= 2 and k % 7 ~= 6 then
			bx(at, 0.08, 0.14, 0.55, -2.8 + k * 0.165 + 0.08, 3.42, -1.25, C.soot, M.SmoothPlastic, nc({ name = "Sharp" }))
		end
	end
	bx(at, 6.0, 0.3, 0.6, 0, 3.55, -0.75, wood, M.Wood, nc({ name = "Fallboard" }))
	bx(at, 2.4, 1.2, 0.1, 0, 4.2, -0.55, B.rgb(236, 226, 196), M.SmoothPlastic, nc({ name = "SheetMusic" }))
	for _, sx in { -1, 1 } do
		post(at, sx * 2.8, -1.9, 3.0, 0.45, wood, M.Wood)
		P.candlestick((at * CF(sx * 2.5, 5.0, 0.4)).Position, 0.8, nil)
	end
	-- bench
	local bench = at * CF(0, 0, -3.6)
	bx(bench, 3.4, 0.35, 1.3, 0, 2.1, 0, wood, M.Wood, { name = "Bench" })
	for _, sx in { -1, 1 } do
		bx(bench, 0.3, 1.9, 1.1, sx * 1.4, 0.95, 0, wood, M.Wood, { name = "BenchLeg" })
	end
end

function P.grandfatherClock(at)
	local wood = B.rgb(98, 54, 28)
	bx(at, 2.4, 1.2, 1.6, 0, 0.6, 0, wood, M.Wood, { name = "Base" })
	local trunk = bx(at, 1.9, 5.0, 1.3, 0, 3.7, 0, wood, M.Wood, { name = "Trunk" })
	trunk:SetAttribute("Ticking", true)
	bx(at, 1.3, 4.0, 0.06, 0, 3.6, -0.66, B.rgb(255, 230, 190), M.Glass, nc({ name = "TrunkGlass", transparency = 0.6 }))
	B.rod((at * CF(0, 5.6, -0.3)).Position, (at * CF(0, 2.8, -0.3)).Position, 0.1, C.brass, M.Metal, nc({ name = "PendulumRod" }))
	B.cyl(V(0.12, 0.9, 0.9), at * CF(0, 2.6, -0.3) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, nc({ name = "Bob" }))
	bx(at, 2.5, 3.0, 1.8, 0, 7.7, 0, wood, M.Wood, { name = "Hood" })
	B.tent(at * CF(0, 9.2, 0), 2.7, 0.8, 1.9, wood, M.Wood)
	P.clockFace(at * CF(0, 7.7, -0.91), 1.1, B.rgb(244, 232, 204))
	B.ball(0.35, (at * CF(0, 9.8, 0)).Position, C.brass, M.Metal, nc({ name = "Finial" }))
end

-- Clock face, stopped at twenty to seven. cf: centre of the face, LookVector out of the face.
function P.clockFace(cf, r, faceColor)
	B.cyl(V(0.12, r * 2 + 0.2, r * 2 + 0.2), cf * CF(0, 0, 0.04) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, nc({ name = "Bezel" }))
	B.cyl(V(0.12, r * 2, r * 2), cf * CF(0, 0, -0.03) * CFrame.Angles(0, math.pi / 2, 0), faceColor or C.cream, M.SmoothPlastic, nc({ name = "Dial" }))
	-- viewer's right is local -X
	local function dir(deg)
		local a = math.rad(deg)
		return V(-math.sin(a), math.cos(a), 0)
	end
	for h = 0, 11 do
		local d = dir(h * 30)
		B.box(V(0.06, if h % 3 == 0 then 0.22 else 0.12, 0.04), cf * CF(d.X * r * 0.82, d.Y * r * 0.82, -0.1) * CFrame.Angles(0, 0, math.rad(h * 30)), C.soot, M.SmoothPlastic, nc({ name = "Tick" }))
	end
	local hour, minute = dir(200), dir(240)
	B.box(V(0.1, r * 0.55, 0.04), cf * CF(hour.X * r * 0.27, hour.Y * r * 0.27, -0.13) * CFrame.Angles(0, 0, math.rad(200)), C.soot, M.Metal, nc({ name = "HourHand" }))
	B.box(V(0.07, r * 0.85, 0.04), cf * CF(minute.X * r * 0.42, minute.Y * r * 0.42, -0.16) * CFrame.Angles(0, 0, math.rad(240)), C.soot, M.Metal, nc({ name = "MinuteHand" }))
	B.ball(0.12, (cf * CF(0, 0, -0.17)).Position, C.brass, M.Metal, nc({ name = "Pin" }))
end

-- Wall clock. cf: on the wall surface, LookVector out into the room.
function P.wallClock(cf, r)
	r = r or 0.9
	B.cyl(V(0.35, r * 2 + 0.5, r * 2 + 0.5), cf * CF(0, 0, -0.17) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(98, 54, 28), M.Wood, nc({ name = "ClockCase" }))
	P.clockFace(cf * CF(0, 0, -0.38), r, C.cream)
end

-- Framed picture. cf: on the wall surface, LookVector out into the room.
function P.painting(cf, w, h, kind)
	local frameC = C.brass
	local depth = 0.25
	for _, s in { -1, 1 } do
		B.box(V(0.35, h + 0.35, depth), cf * CF(s * (w / 2), 0, -depth / 2), frameC, M.Metal, nc({ name = "Frame" }))
		B.box(V(w + 0.35, 0.35, depth), cf * CF(0, s * (h / 2), -depth / 2), frameC, M.Metal, nc({ name = "Frame" }))
	end
	local canvas = B.box(V(w, h, 0.1), cf * CF(0, 0, -0.06), C.cream, M.SmoothPlastic, nc({ name = "Canvas" }))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 1
	sg.Parent = canvas
	local UDim2 = roblox.UDim2
	local function frame(parent, pos, size, color, corner, rot)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = color
		f.Rotation = rot or 0
		if corner then
			local c = Instance.new("UICorner")
			c.CornerRadius = roblox.UDim.new(corner, 0)
			c.Parent = f
		end
		f.Parent = parent
		return f
	end
	local bg = frame(sg, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), C.cream)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	if kind == "portrait" then
		g.Color = roblox.ColorSequence.new(B.rgb(70, 46, 30), B.rgb(30, 20, 14))
		g.Parent = bg
		-- mother, father and the daughter between them, her face left unfinished
		local people = {
			{ 0.2, 0.30, 1.0, B.rgb(52, 40, 32) },
			{ 0.62, 0.24, 1.0, B.rgb(60, 36, 40) },
			{ 0.43, 0.5, 0.35, B.rgb(200, 180, 150) },
		}
		for _, p in people do
			local x, y, alpha, col = p[1], p[2], p[3], p[4]
			local body = frame(bg, UDim2.fromScale(x - 0.04, y + 0.28), UDim2.fromScale(0.3, 0.6), col, 0.4)
			body.BackgroundTransparency = 1 - alpha
			local head = frame(bg, UDim2.fromScale(x + 0.04, y), UDim2.fromScale(0.14, 0.22), B.rgb(232, 196, 160), 0.5)
			head.BackgroundTransparency = 1 - alpha
		end
	elseif kind == "pines" then
		g.Color = roblox.ColorSequence.new({
			roblox.ColorSequenceKeypoint.new(0, B.rgb(255, 196, 96)),
			roblox.ColorSequenceKeypoint.new(0.55, B.rgb(255, 150, 70)),
			roblox.ColorSequenceKeypoint.new(1, B.rgb(140, 70, 50)),
		})
		g.Parent = bg
		frame(bg, UDim2.fromScale(0.58, 0.42), UDim2.fromScale(0.22, 0.3), B.rgb(255, 236, 160), 0.5)
		for i = 0, 7 do
			local x = i / 7.5
			local hh = 0.35 + (i % 3) * 0.12
			local t = frame(bg, UDim2.fromScale(x, 1 - hh), UDim2.fromScale(0.13, hh), B.rgb(30, 40, 30), nil, 0)
			t.ZIndex = 2
		end
	else -- lake at evening
		g.Color = roblox.ColorSequence.new({
			roblox.ColorSequenceKeypoint.new(0, B.rgb(255, 214, 120)),
			roblox.ColorSequenceKeypoint.new(0.5, B.rgb(255, 170, 90)),
			roblox.ColorSequenceKeypoint.new(0.62, B.rgb(120, 90, 80)),
			roblox.ColorSequenceKeypoint.new(1, B.rgb(70, 60, 70)),
		})
		g.Parent = bg
		frame(bg, UDim2.fromScale(0.36, 0.45), UDim2.fromScale(0.28, 0.12), B.rgb(255, 240, 180), 0.5)
		frame(bg, UDim2.fromScale(0, 0.52), UDim2.fromScale(1, 0.1), B.rgb(46, 52, 44))
	end
	return canvas
end

---------------------------------------------------------------- kitchen

function P.counter(at, len, o)
	o = o or {}
	local wood = o.wood or B.rgb(176, 120, 64)
	bx(at, len, 3.0, 2.4, 0, 1.6, 0, wood, M.Wood, { name = "Cabinet" })
	bx(at, len, 0.2, 2.3, 0, 0.1, 0.1, C.beam, M.Wood, { name = "Kick" })
	bx(at, len + 0.2, 0.35, 2.7, 0, 3.27, -0.1, B.rgb(196, 140, 84), M.WoodPlanks, { name = "Butcherblock" })
	local n = math.max(1, math.floor(len / 2.2))
	for i = 0, n - 1 do
		local x = -len / 2 + (i + 0.5) * len / n
		bx(at, len / n - 0.2, 2.3, 0.08, x, 1.55, -1.23, B.vary(wood, 0.07), M.Wood, nc({ name = "CabDoor" }))
		bx(at, len / n - 0.7, 1.6, 0.05, x, 1.55, -1.28, B.vary(wood, 0.1), M.Wood, nc({ name = "CabPanel" }))
		B.ball(0.18, (at * CF(x + (len / n) * 0.3, 2.3, -1.32)).Position, C.iron, M.Metal, nc({ name = "Knob" }))
	end
	if o.sink then
		local s = at * CF(o.sink, 3.45, -0.1)
		bx(s, 2.6, 0.9, 1.9, 0, -0.3, 0, B.rgb(240, 236, 226), M.SmoothPlastic, { name = "Basin" })
		bx(s, 2.2, 0.1, 1.5, 0, 0.16, 0, B.rgb(150, 160, 160), M.Metal, nc({ name = "Drain" }))
		B.rod((s * CF(0, 0.1, 0.9)).Position, (s * CF(0, 1.4, 0.9)).Position, 0.18, C.brass, M.Metal, nc({ name = "Pump" }))
		B.rod((s * CF(0, 1.3, 0.9)).Position, (s * CF(0, 1.3, 0.2)).Position, 0.14, C.brass, M.Metal, nc({ name = "Spout" }))
	end
	return at * CF(0, 3.45, -0.1)
end

function P.upperCabinets(cf, len)
	-- cf: on wall at the cabinets' vertical centre, facing out
	local wood = B.rgb(186, 130, 72)
	B.box(V(len, 2.8, 1.4), cf * CF(0, 0, -0.7), wood, M.Wood, { name = "Upper" })
	local n = math.max(1, math.floor(len / 2))
	for i = 0, n - 1 do
		local x = -len / 2 + (i + 0.5) * len / n
		B.box(V(len / n - 0.2, 2.5, 0.08), cf * CF(x, 0, -1.43), B.vary(wood, 0.08), M.Wood, nc({ name = "Door" }))
		B.box(V(len / n - 0.8, 1.6, 0.06), cf * CF(x, 0, -1.48), B.rgb(255, 236, 200), M.Glass, nc({ name = "Pane", transparency = 0.4 }))
	end
	B.box(V(len + 0.3, 0.25, 1.7), cf * CF(0, 1.5, -0.8), B.vary(wood, 0.1), M.Wood, { name = "Crown" })
end

function P.woodStove(at)
	local iron = B.rgb(40, 38, 36)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			bx(at, 0.35, 1.0, 0.35, sx * 1.6, 0.5, sz * 1.0, iron, M.Metal)
		end
	end
	bx(at, 4.0, 2.4, 2.6, 0, 2.2, 0, iron, M.Metal, { name = "Body" })
	bx(at, 4.4, 0.25, 2.9, 0, 3.5, 0, B.rgb(60, 58, 56), M.Metal, { name = "Cooktop" })
	bx(at, 1.6, 1.3, 0.1, -0.8, 2.1, -1.32, B.rgb(30, 28, 26), M.Metal, nc({ name = "FireDoor" }))
	local glow = bx(at, 1.0, 0.25, 0.12, -0.8, 1.7, -1.36, B.rgb(255, 120, 30), M.Neon, nc({ name = "Draft", shadow = false }))
	B.warmLight(glow, 10, 1.4, false, B.rgb(255, 140, 60))
	glow:SetAttribute("Flicker", true)
	bx(at, 1.4, 1.3, 0.1, 1.1, 2.1, -1.32, B.rgb(52, 50, 48), M.Metal, nc({ name = "OvenDoor" }))
	B.box(V(0.8, 0.15, 0.15), at * CF(1.1, 2.6, -1.45), B.rgb(200, 200, 196), M.Metal, nc({ name = "Handle" }))
	B.vcyl(10, 0.8, (at * CF(1.2, 8.5, 0.6)).Position, iron, M.Metal, { name = "Stovepipe" })
	-- kettle and pan
	local k = at * CF(-1.0, 3.62, 0.2)
	B.ball(1.0, (k * CF(0, 0.45, 0)).Position, B.rgb(190, 120, 70), M.Metal, nc({ name = "Kettle" }))
	B.rod((k * CF(0.3, 0.6, 0)).Position, (k * CF(0.8, 0.95, 0)).Position, 0.15, B.rgb(190, 120, 70), M.Metal, nc({ name = "Spout" }))
	B.vcyl(0.3, 1.2, (at * CF(1.0, 3.77, 0)).Position, B.rgb(30, 30, 30), M.Metal, nc({ name = "Skillet" }))
	B.box(V(1.2, 0.12, 0.2), at * CF(1.9, 3.85, 0), B.rgb(30, 30, 30), M.Metal, nc({ name = "SkilletHandle" }))
end

function P.icebox(at)
	local oak = B.rgb(170, 110, 56)
	bx(at, 3.0, 6.0, 2.2, 0, 3.0, 0, oak, M.Wood, { name = "Icebox" })
	for _, y in { 4.4, 1.8 } do
		bx(at, 2.5, 2.3, 0.1, 0, y, -1.13, B.vary(oak, 0.08), M.Wood, nc({ name = "Door" }))
		B.box(V(0.2, 0.6, 0.15), at * CF(0.9, y, -1.22), C.brass, M.Metal, nc({ name = "Latch" }))
		for _, hy in { y - 0.8, y + 0.8 } do
			B.box(V(0.3, 0.35, 0.1), at * CF(-1.15, hy, -1.2), C.brass, M.Metal, nc({ name = "Hinge" }))
		end
	end
	return at * CF(0, 6.0, 0)
end

function P.jar(pos, h, content)
	B.vcyl(h, 0.55, pos + V(0, h / 2, 0), B.rgb(220, 236, 230), M.Glass, nc({ name = "Jar", transparency = 0.55, shadow = false }))
	B.vcyl(h * 0.75, 0.45, pos + V(0, h * 0.38, 0), content, M.SmoothPlastic, nc({ name = "Preserve" }))
	B.vcyl(0.1, 0.58, pos + V(0, h + 0.05, 0), C.brass, M.Metal, nc({ name = "Lid" }))
end

function P.jarShelf(at, w, levels)
	local wood = B.rgb(140, 92, 50)
	local contents = { B.rgb(180, 30, 40), B.rgb(110, 140, 50), B.rgb(240, 150, 50), B.rgb(130, 40, 80), B.rgb(230, 190, 70), B.rgb(200, 90, 40) }
	for _, sx in { -1, 1 } do
		bx(at, 0.25, levels * 1.8 + 0.3, 1.5, sx * (w / 2), (levels * 1.8 + 0.3) / 2, 0, wood, M.Wood, { name = "Upright" })
	end
	for l = 0, levels - 1 do
		local y = 0.3 + l * 1.8
		bx(at, w, 0.15, 1.5, 0, y, 0, B.vary(wood, 0.05), M.WoodPlanks, { name = "Shelf" })
		local x = -w / 2 + 0.5
		while x < w / 2 - 0.4 do
			if B.rand() < 0.85 then
				P.jar((at * CF(x, y + 0.08, B.range(-0.3, 0.3))).Position, B.range(0.6, 1.0), B.pick(contents))
			end
			x += B.range(0.6, 0.8)
		end
	end
end

function P.hangingPots(cf, len)
	B.rod((cf * CF(-len / 2, 0, 0)).Position, (cf * CF(len / 2, 0, 0)).Position, 0.15, C.iron, M.Metal, nc({ name = "PotRail" }))
	local cols = { B.rgb(184, 110, 60), B.rgb(40, 40, 40), B.rgb(196, 126, 70) }
	local n = math.floor(len / 1.3)
	for i = 0, n - 1 do
		local x = -len / 2 + 0.6 + i * 1.3
		local d = B.range(0.9, 1.3)
		B.rod((cf * CF(x, 0, 0)).Position, (cf * CF(x, -0.6, 0)).Position, 0.05, C.iron, M.Metal, nc())
		B.vcyl(0.5, d, (cf * CF(x, -0.6 - d / 2, 0.0)).Position, B.pick(cols), M.Metal, nc({ name = "Pot" }))
	end
end

---------------------------------------------------------------- bathroom

function P.clawTub(at)
	local enamel = B.rgb(246, 244, 236)
	bx(at, 3.0, 2.2, 2.8, 0, 1.6, 0, enamel, M.SmoothPlastic, { name = "TubBody" })
	for _, sx in { -1, 1 } do
		B.vcyl(2.2, 2.8, (at * CF(sx * 1.5, 1.6, 0)).Position, enamel, M.SmoothPlastic, { name = "TubEnd" })
		for _, sz in { -1, 1 } do
			B.ball(0.55, (at * CF(sx * 1.7, 0.3, sz * 0.9)).Position, C.brass, M.Metal, nc({ name = "Claw" }))
		end
	end
	bx(at, 4.6, 0.1, 2.3, 0, 2.62, 0, B.rgb(180, 200, 200), M.Glass, nc({ name = "Water", transparency = 0.3, reflectance = 0.2 }))
	B.rod((at * CF(-2.6, 2.6, 0)).Position, (at * CF(-2.6, 3.5, 0)).Position, 0.18, C.brass, M.Metal, nc({ name = "Faucet" }))
	B.rod((at * CF(-2.6, 3.4, 0)).Position, (at * CF(-2.1, 3.3, 0)).Position, 0.15, C.brass, M.Metal, nc({ name = "Spout" }))
end

function P.pedestalSink(at)
	local enamel = B.rgb(246, 244, 236)
	B.vcyl(2.7, 0.7, (at * CF(0, 1.35, 0)).Position, enamel, M.SmoothPlastic, { name = "Pedestal" })
	bx(at, 2.4, 0.6, 1.8, 0, 3.0, 0, enamel, M.SmoothPlastic, { name = "Basin" })
	B.rod((at * CF(0, 3.2, 0.7)).Position, (at * CF(0, 3.9, 0.7)).Position, 0.12, C.brass, M.Metal, nc({ name = "Tap" }))
	B.rod((at * CF(0, 3.85, 0.7)).Position, (at * CF(0, 3.75, 0.3)).Position, 0.1, C.brass, M.Metal, nc({ name = "Spout" }))
	return at * CF(0.7, 3.32, -0.2)
end

function P.toilet(at)
	local enamel = B.rgb(246, 244, 236)
	B.vcyl(1.6, 1.2, (at * CF(0, 0.8, -0.2)).Position, enamel, M.SmoothPlastic, { name = "Bowl" })
	B.vcyl(0.2, 1.7, (at * CF(0, 1.7, -0.3)).Position, B.rgb(120, 74, 40), M.Wood, nc({ name = "Seat" }))
	bx(at, 1.0, 1.8, 0.4, 0, 1.2, 0.7, enamel, M.SmoothPlastic, { name = "Pipe" })
	bx(at, 2.0, 1.2, 0.9, 0, 6.6, 0.6, B.rgb(120, 74, 40), M.Wood, { name = "Cistern" })
	B.rod((at * CF(0.4, 1.8, 0.75)).Position, (at * CF(0.4, 6.0, 0.75)).Position, 0.15, C.brass, M.Metal, nc({ name = "Flushpipe" }))
	B.rod((at * CF(-0.7, 6.0, 0.3)).Position, (at * CF(-0.7, 4.0, 0.3)).Position, 0.04, C.brass, M.Metal, nc({ name = "PullChain" }))
	B.vcyl(0.4, 0.2, (at * CF(-0.7, 3.8, 0.3)).Position, B.rgb(240, 236, 226), M.SmoothPlastic, nc({ name = "PullHandle" }))
end

---------------------------------------------------------------- storage, work

function P.trunk(at, w, open)
	local wood = B.rgb(110, 68, 36)
	bx(at, w, 1.6, 1.9, 0, 0.8, 0, wood, M.WoodPlanks, { name = "Chest" })
	for _, x in { -w / 2 + 0.4, w / 2 - 0.4 } do
		bx(at, 0.2, 1.65, 1.95, x, 0.82, 0, C.iron, M.Metal, nc({ name = "Band" }))
	end
	if open then
		B.box(V(w, 0.5, 1.9), at * CF(0, 2.1, 1.35) * CFrame.Angles(math.rad(70), 0, 0), wood, M.WoodPlanks, nc({ name = "LidOpen" }))
	else
		B.cyl(V(w, 1.9, 1.9), at * CF(0, 1.25, 0), wood, M.WoodPlanks, { name = "Lid" })
		bx(at, 0.45, 0.6, 0.12, 0, 1.4, -0.98, C.brass, M.Metal, nc({ name = "Hasp" }))
	end
	return at * CF(0, 1.6, 0)
end

function P.crate(at, s, color)
	local wood = color or B.vary(B.rgb(176, 130, 80), 0.08)
	bx(at, s, s, s, 0, s / 2, 0, wood, M.WoodPlanks, { name = "Crate" })
	for _, f in { -1, 1 } do
		B.box(V(s + 0.04, 0.3, 0.06), at * CF(0, s * 0.2, f * (s / 2 + 0.03)), B.vary(wood, 0.1), M.Wood, nc({ name = "Slat" }))
		B.box(V(s + 0.04, 0.3, 0.06), at * CF(0, s * 0.8, f * (s / 2 + 0.03)), B.vary(wood, 0.1), M.Wood, nc({ name = "Slat" }))
	end
	return at * CF(0, s, 0)
end

function P.barrel(at, h)
	h = h or 3.6
	local wood = B.vary(B.rgb(130, 82, 44), 0.08)
	B.vcyl(h, 2.2, (at * CF(0, h / 2, 0)).Position, wood, M.Wood, { name = "Barrel" })
	B.vcyl(h * 0.5, 2.4, (at * CF(0, h / 2, 0)).Position, B.vary(wood, 0.05), M.Wood, { name = "Belly" })
	for _, y in { 0.35, h * 0.3, h * 0.7, h - 0.35 } do
		B.vcyl(0.18, if y > 0.5 and y < h - 0.5 then 2.45 else 2.25, (at * CF(0, y, 0)).Position, C.iron, M.Metal, nc({ name = "Hoop" }))
	end
end

function P.workbench(at, w)
	local wood = B.rgb(150, 100, 56)
	bx(at, w, 0.5, 2.6, 0, 3.15, 0, wood, M.WoodPlanks, { name = "Bench" })
	bx(at, w - 0.4, 0.2, 2.2, 0, 0.9, 0, B.vary(wood, 0.06), M.WoodPlanks, { name = "Shelf" })
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			bx(at, 0.45, 2.9, 0.45, sx * (w / 2 - 0.3), 1.45, sz * 1.0, wood, M.Wood, { name = "Leg" })
		end
	end
	-- vise
	local v = at * CF(w / 2 - 1.0, 3.4, -1.0)
	bx(v, 0.9, 0.7, 0.6, 0, 0.35, 0, B.rgb(70, 90, 80), M.Metal, nc({ name = "Vise" }))
	B.rod((v * CF(0, 0.35, -0.3)).Position, (v * CF(0, 0.35, -1.0)).Position, 0.12, C.iron, M.Metal, nc({ name = "ViseScrew" }))
	-- pegboard
	bx(at, w - 0.4, 3.6, 0.15, 0, 5.4, 1.3, B.rgb(150, 116, 80), M.Wood, { name = "Pegboard" })
	local tools = {
		function(c)
			B.box(V(0.15, 1.3, 0.1), c, B.rgb(140, 90, 50), M.Wood, nc({ name = "HammerHandle" }))
			B.box(V(0.7, 0.25, 0.2), c * CF(0, 0.7, 0), C.iron, M.Metal, nc({ name = "HammerHead" }))
		end,
		function(c)
			B.box(V(0.9, 1.6, 0.05), c, B.rgb(180, 180, 176), M.Metal, nc({ name = "SawBlade" }))
			B.box(V(0.35, 0.5, 0.12), c * CF(0, 0.95, 0), B.rgb(140, 90, 50), M.Wood, nc({ name = "SawHandle" }))
		end,
		function(c)
			B.box(V(0.18, 1.2, 0.08), c, B.rgb(150, 150, 150), M.Metal, nc({ name = "Wrench" }))
			B.box(V(0.45, 0.3, 0.08), c * CF(0, 0.6, 0), B.rgb(150, 150, 150), M.Metal, nc({ name = "WrenchJaw" }))
		end,
	}
	local n = math.floor((w - 1) / 1.1)
	for i = 0, n - 1 do
		local c = at * CF(-w / 2 + 0.8 + i * 1.1, 5.5, 1.18)
		tools[(i % #tools) + 1](c)
	end
	return at * CF(0, 3.4, 0)
end

function P.furnace(at)
	local body = B.rgb(70, 66, 62)
	B.vcyl(6.2, 5.0, (at * CF(0, 3.1, 0)).Position, body, M.Metal, { name = "Furnace" })
	B.vcyl(1.0, 5.4, (at * CF(0, 0.5, 0)).Position, B.rgb(50, 48, 46), M.Metal, { name = "FurnaceBase" })
	B.vcyl(0.5, 4.0, (at * CF(0, 6.4, 0)).Position, B.rgb(60, 58, 56), M.Metal, { name = "FurnaceCap" })
	bx(at, 1.8, 1.4, 0.4, 0, 2.0, -2.45, B.rgb(36, 34, 32), M.Metal, nc({ name = "FurnaceDoor" }))
	for k = 0, 3 do
		bx(at, 1.4, 0.1, 0.1, 0, 1.6 + k * 0.28, -2.68, C.soot, M.Metal, nc({ name = "Grill" }))
	end
	local glow = bx(at, 1.3, 1.0, 0.1, 0, 2.0, -2.63, B.rgb(255, 110, 30), M.Neon, nc({ name = "FurnaceGlow", shadow = false }))
	B.warmLight(glow, 18, 1.8, true, B.rgb(255, 130, 50))
	glow:SetAttribute("Flicker", true)
	-- ducts to the floor above
	for i = 0, 2 do
		local a = i * 2.1
		local p0 = (at * CF(math.cos(a) * 1.3, 6.6, math.sin(a) * 1.3)).Position
		B.rod(p0, p0 + V(math.cos(a) * 3, 3.8, math.sin(a) * 3), 1.0, B.rgb(120, 116, 110), M.Metal, { name = "Duct" })
		B.rod(p0 + V(math.cos(a) * 3, 3.8, math.sin(a) * 3), p0 + V(math.cos(a) * 3, 6.4, math.sin(a) * 3), 1.0, B.rgb(120, 116, 110), M.Metal, { name = "Duct" })
	end
end

function P.coalPile(at, r)
	for i = 1, 40 do
		local a = B.range(0, math.pi * 2)
		local d = math.sqrt(B.rand()) * r
		local h = (1 - d / r) * 1.6
		local s = B.range(0.35, 0.7)
		B.box(V(s, s * 0.8, s), at * CF(math.cos(a) * d, h * 0.6 + s * 0.3, math.sin(a) * d) * CFrame.Angles(B.range(0, 3), B.range(0, 3), B.range(0, 3)), B.vary(B.rgb(26, 26, 28), 0.3), M.Slate, nc({ name = "Coal" }))
	end
end

function P.sheetCovered(at, sx, sy, sz)
	local white = B.rgb(236, 232, 222)
	bx(at, sx, sy, sz, 0, sy / 2, 0, white, M.Fabric, { name = "Dustsheet" })
	B.box(V(sx * 0.95, 0.5, sz * 0.95), at * CF(0, sy + 0.2, 0) * CFrame.Angles(0, 0, math.rad(4)), white, M.Fabric, nc({ name = "Drape" }))
	for _, f in { -1, 1 } do
		B.box(V(sx + 0.3, sy * 0.7, 0.12), at * CF(0, sy * 0.35, f * (sz / 2 + 0.08)) * CFrame.Angles(math.rad(f * 6), 0, 0), white, M.Fabric, nc({ name = "Hem" }))
	end
end

function P.dressForm(at)
	B.vcyl(0.15, 1.4, (at * CF(0, 0.08, 0)).Position, C.iron, M.Metal, nc())
	B.vcyl(3.4, 0.12, (at * CF(0, 1.8, 0)).Position, C.iron, M.Metal, nc())
	B.box(V(1.6, 2.6, 1.0), at * CF(0, 4.6, 0), B.rgb(196, 170, 130), M.Fabric, { name = "Torso" })
	B.ball(1.2, (at * CF(0, 4.6, 0)).Position, B.rgb(196, 170, 130), M.Fabric, nc({ name = "Bust" }))
	B.vcyl(0.4, 0.5, (at * CF(0, 6.1, 0)).Position, B.rgb(140, 100, 60), M.Wood, nc({ name = "Neck" }))
	-- a half-finished child's dress pinned to it
	B.box(V(1.7, 1.8, 1.1), at * CF(0, 4.0, 0), B.rgb(230, 190, 80), M.Fabric, nc({ name = "Dress" }))
end

function P.sewingTable(at)
	local wood = B.rgb(120, 74, 40)
	bx(at, 4.0, 0.25, 2.0, 0, 3.0, 0, wood, M.Wood, { name = "Top" })
	for _, sx in { -1, 1 } do
		bx(at, 0.2, 2.9, 1.8, sx * 1.8, 1.45, 0, C.iron, M.Metal, { name = "IronLeg" })
	end
	bx(at, 1.8, 0.2, 1.4, 0, 0.4, 0, C.iron, M.Metal, nc({ name = "Treadle" }))
	local m = at * CF(0, 3.12, 0)
	bx(m, 2.2, 0.4, 0.9, 0, 0.2, 0, C.soot, M.Metal, nc({ name = "MachineBed" }))
	bx(m, 0.5, 1.3, 0.6, 0.8, 1.0, 0, C.soot, M.Metal, nc({ name = "MachinePillar" }))
	bx(m, 1.8, 0.5, 0.6, 0.0, 1.55, 0, C.soot, M.Metal, nc({ name = "MachineArm" }))
	bx(m, 0.4, 0.8, 0.4, -0.8, 1.0, 0, C.soot, M.Metal, nc({ name = "MachineHead" }))
	B.cyl(V(0.2, 0.9, 0.9), m * CF(1.15, 1.0, 0), B.rgb(180, 160, 120), M.Metal, nc({ name = "Wheel" }))
	bx(m, 1.4, 0.06, 0.05, 0.0, 1.6, -0.31, C.brass, M.Metal, nc({ name = "Decal" }))
	-- thread spools
	for k = 0, 3 do
		B.vcyl(0.35, 0.25, (at * CF(-1.6 + k * 0.35, 3.3, 0.7)).Position, B.pick({ C.red, C.mustard, C.navy, C.cream }), M.Fabric, nc({ name = "Spool" }))
	end
end

function P.teddy(at, s, color)
	s = s or 1
	color = color or B.rgb(170, 120, 70)
	B.ball(1.3 * s, (at * CF(0, 0.7 * s, 0)).Position, color, M.Fabric, nc({ name = "TeddyBody" }))
	B.ball(0.95 * s, (at * CF(0, 1.65 * s, 0)).Position, color, M.Fabric, nc({ name = "TeddyHead" }))
	for _, sx in { -1, 1 } do
		B.ball(0.38 * s, (at * CF(sx * 0.38 * s, 2.05 * s, 0)).Position, color, M.Fabric, nc({ name = "TeddyEar" }))
		B.ball(0.5 * s, (at * CF(sx * 0.6 * s, 0.75 * s, -0.2 * s)).Position, color, M.Fabric, nc({ name = "TeddyArm" }))
		B.ball(0.55 * s, (at * CF(sx * 0.35 * s, 0.25 * s, -0.4 * s)).Position, color, M.Fabric, nc({ name = "TeddyLeg" }))
		B.ball(0.1 * s, (at * CF(sx * 0.16 * s, 1.75 * s, -0.43 * s)).Position, C.soot, M.SmoothPlastic, nc({ name = "TeddyEye" }))
	end
	B.ball(0.35 * s, (at * CF(0, 1.55 * s, -0.4 * s)).Position, B.rgb(220, 190, 150), M.Fabric, nc({ name = "TeddySnout" }))
end

function P.rockingHorse(at)
	local wood = B.rgb(236, 220, 190)
	for _, sx in { -1, 1 } do
		B.box(V(0.2, 0.25, 4.0), at * CF(sx * 0.7, 0.2, 0), B.rgb(150, 40, 36), M.Wood, { name = "Rocker" })
		for _, sz in { -1, 1 } do
			B.box(V(0.2, 1.4, 0.2), at * CF(sx * 0.5, 0.9, sz * 1.0) * CFrame.Angles(math.rad(sz * 12), 0, math.rad(sx * 8)), wood, M.Wood, { name = "Leg" })
		end
	end
	bx(at, 0.9, 0.9, 2.6, 0, 1.9, 0, wood, M.Wood, { name = "HorseBody" })
	B.box(V(0.7, 1.4, 0.7), at * CF(0, 2.7, -1.2) * CFrame.Angles(math.rad(-25), 0, 0), wood, M.Wood, { name = "HorseNeck" })
	bx(at, 0.6, 0.6, 1.2, 0, 3.3, -1.75, wood, M.Wood, { name = "HorseHead" })
	bx(at, 0.2, 1.4, 0.4, 0, 2.9, -1.0, B.rgb(120, 70, 40), M.Fabric, nc({ name = "Mane" }))
	bx(at, 0.95, 0.15, 0.9, 0, 2.4, 0.1, B.rgb(150, 40, 36), M.Leather, nc({ name = "Saddle" }))
	for _, sx in { -1, 1 } do
		B.ball(0.12, (at * CF(sx * 0.31, 3.45, -2.0)).Position, C.soot, M.SmoothPlastic, nc({ name = "Eye" }))
	end
end

-- A small model of the lodge itself.
function P.dollhouse(at)
	local s = 0.08
	bx(at, 72 * s, 0.2, 56 * s, 0, 0.1, 0, B.rgb(90, 120, 60), M.Grass, nc({ name = "Base" }))
	bx(at, 72 * s, 28 * s, 56 * s, 0, 0.2 + 14 * s, 0, C.log, M.Wood, nc({ name = "MiniWalls" }))
	B.tent(at * CF(0, 0.2 + 28 * s, 0) * CFrame.Angles(0, math.pi / 2, 0), 60 * s, 18 * s, 76 * s, C.roof, M.RoofShingles, nc())
	for i = -2, 2 do
		local w = bx(at, 0.35, 0.45, 0.05, i * 1.0, 0.2 + 8 * s, -28 * s - 0.03, B.rgb(255, 210, 120), M.Neon, nc({ name = "MiniWindow", shadow = false }))
		w.Transparency = 0.1
	end
	bx(at, 0.5, 0.9, 0.05, 0, 0.2 + 0.45, -28 * s - 0.03, B.rgb(80, 50, 30), M.Wood, nc({ name = "MiniDoor" }))
	-- a tiny figure on the porch
	B.box(V(0.12, 0.35, 0.12), at * CF(0.6, 0.38, -28 * s - 0.4), C.soot, M.SmoothPlastic, nc({ name = "MiniFigure" }))
end

function P.pottedPlant(at, s)
	s = s or 1
	B.vcyl(1.2 * s, 1.3 * s, (at * CF(0, 0.6 * s, 0)).Position, B.rgb(180, 96, 60), M.Brick, { name = "Pot" })
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		B.ball(B.range(0.8, 1.2) * s, (at * CF(math.cos(a) * 0.5 * s, (1.4 + B.range(0, 0.9)) * s, math.sin(a) * 0.5 * s)).Position, B.vary(B.rgb(70, 120, 50), 0.15), M.Grass, nc({ name = "Leaf", shadow = false }))
	end
end

function P.keyRack(cf, n)
	-- cf: on the wall surface, LookVector out
	local wood = B.rgb(110, 66, 34)
	local board = B.box(V(n * 0.7 + 0.6, 2.4, 0.25), cf * CF(0, 0, -0.12), wood, M.Wood, { name = "KeyBoard" })
	B.box(V(n * 0.7 + 0.9, 0.25, 0.4), cf * CF(0, 1.3, -0.2), wood, M.Wood, { name = "KeyBoardCap" })
	for i = 0, n - 1 do
		local x = -(n - 1) * 0.35 + i * 0.7
		B.box(V(0.08, 0.08, 0.35), cf * CF(x, 0.6, -0.4), C.brass, M.Metal, nc({ name = "Hook" }))
		if i % 3 ~= 1 then
			B.cyl(V(0.06, 0.32, 0.32), cf * CF(x, 0.35, -0.5) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, nc({ name = "KeyBow" }))
			B.box(V(0.07, 0.65, 0.05), cf * CF(x, -0.12, -0.5), C.brass, M.Metal, nc({ name = "KeyShank" }))
			B.box(V(0.16, 0.12, 0.05), cf * CF(x + 0.08, -0.38, -0.5), C.brass, M.Metal, nc({ name = "KeyBit" }))
			B.box(V(0.5, 0.3, 0.03), cf * CF(x, -0.75, -0.45), C.paper, M.SmoothPlastic, nc({ name = "Tag" }))
		end
	end
	return board
end

function P.keyCutter(at)
	local iron = B.rgb(70, 90, 80)
	bx(at, 3.2, 0.3, 1.8, 0, 3.35, 0, iron, M.Metal, { name = "CutterBed" })
	B.cyl(V(0.2, 1.2, 1.2), at * CF(0.8, 4.05, 0.2), B.rgb(150, 150, 150), M.Metal, nc({ name = "Grinder" }))
	bx(at, 0.5, 0.9, 0.5, 0.8, 3.9, 0.7, iron, M.Metal, nc({ name = "Motor" }))
	bx(at, 0.8, 0.4, 0.5, -0.6, 3.7, 0.0, iron, M.Metal, nc({ name = "Clamp" }))
	B.rod((at * CF(-0.6, 3.75, 0.25)).Position, (at * CF(-0.6, 3.75, -0.6)).Position, 0.1, C.iron, M.Metal, nc({ name = "Lever" }))
	-- blanks and brass shavings
	for k = 0, 5 do
		B.box(V(0.08, 0.55, 0.04), at * CF(-1.3 + k * 0.12, 3.52, -0.6) * CFrame.Angles(math.rad(90), 0, math.rad(B.range(-20, 20))), C.brass, M.Metal, nc({ name = "Blank" }))
	end
	for k = 0, 10 do
		B.ball(0.08, (at * CF(B.range(-0.2, 1.4), 3.52, B.range(-0.6, 0.6))).Position, C.brass, M.Metal, nc({ name = "Shaving", shadow = false }))
	end
end

---------------------------------------------------------------- paper

-- A readable page. The client shows the text when the prompt fires.
function P.note(cf, text, style, size)
	size = size or V(0.9, 0.04, 1.2)
	local paper = B.box(size, cf, C.paper, M.SmoothPlastic, nc({ name = "Note" }))
	paper:SetAttribute("NoteText", text)
	paper:SetAttribute("NoteStyle", style or "hand")
	B.prompt(paper, {
		Name = "ReadPrompt",
		ActionText = "Read",
		ObjectText = "",
		HoldDuration = 0,
		MaxActivationDistance = 7,
		KeyboardKeyCode = Enum.KeyCode.E,
	})
	-- faint pencil lines so it reads as writing from a distance
	for k = 0, 4 do
		B.box(V(size.X * 0.7, 0.01, 0.03), cf * CF(0, size.Y / 2 + 0.005, -size.Z * 0.35 + k * size.Z * 0.16), B.rgb(120, 100, 80), M.SmoothPlastic, nc({ name = "Line", shadow = false }))
	end
	return paper
end

-- A note pinned flat on a wall. cf on the wall surface, LookVector out of the wall.
function P.wallNote(cf, text, style)
	local paper = B.box(V(1.0, 1.3, 0.04), cf * CF(0, 0, -0.03), C.paper, M.SmoothPlastic, nc({ name = "Note" }))
	paper:SetAttribute("NoteText", text)
	paper:SetAttribute("NoteStyle", style or "hand")
	B.prompt(paper, {
		Name = "ReadPrompt",
		ActionText = "Read",
		ObjectText = "",
		HoldDuration = 0,
		MaxActivationDistance = 7,
		KeyboardKeyCode = Enum.KeyCode.E,
	})
	B.ball(0.12, (cf * CF(0, 0.5, -0.07)).Position, C.red, M.SmoothPlastic, nc({ name = "Pin" }))
	for k = 0, 4 do
		B.box(V(0.7, 0.03, 0.01), cf * CF(0, 0.3 - k * 0.16, -0.055), B.rgb(120, 100, 80), M.SmoothPlastic, nc({ name = "Line", shadow = false }))
	end
	return paper
end

-- Child's crayon drawing on a wall, with a SurfaceGui picture.
function P.drawing(cf, kind)
	local paper = B.box(V(1.6, 1.2, 0.04), cf * CF(0, 0, -0.03), B.rgb(248, 244, 232), M.SmoothPlastic, nc({ name = "Drawing" }))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 60
	sg.LightInfluence = 1
	sg.Parent = paper
	local UDim2 = roblox.UDim2
	local function blob(pos, size, color, corner, rot)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.Position = pos
		f.Size = size
		f.BackgroundColor3 = color
		f.Rotation = rot or 0
		if corner then
			local c = Instance.new("UICorner")
			c.CornerRadius = roblox.UDim.new(corner, 0)
			c.Parent = f
		end
		f.Parent = sg
		return f
	end
	-- sun, always low
	blob(UDim2.fromScale(0.72, 0.5), UDim2.fromScale(0.2, 0.26), B.rgb(255, 196, 40), 0.5)
	blob(UDim2.fromScale(0, 0.78), UDim2.fromScale(1, 0.22), B.rgb(90, 170, 70))
	if kind == "house" then
		blob(UDim2.fromScale(0.12, 0.42), UDim2.fromScale(0.4, 0.38), B.rgb(150, 90, 50))
		blob(UDim2.fromScale(0.1, 0.3), UDim2.fromScale(0.44, 0.14), B.rgb(120, 40, 30), nil, -6)
		blob(UDim2.fromScale(0.26, 0.6), UDim2.fromScale(0.08, 0.2), B.rgb(60, 40, 20))
		-- a tall dark figure in the doorway
		blob(UDim2.fromScale(0.27, 0.5), UDim2.fromScale(0.05, 0.28), B.rgb(20, 20, 20))
	else
		-- little girl holding hands with a tall figure
		blob(UDim2.fromScale(0.3, 0.52), UDim2.fromScale(0.07, 0.1), B.rgb(255, 210, 170), 0.5)
		blob(UDim2.fromScale(0.29, 0.62), UDim2.fromScale(0.09, 0.16), B.rgb(230, 190, 40))
		blob(UDim2.fromScale(0.45, 0.2), UDim2.fromScale(0.08, 0.12), B.rgb(20, 20, 20), 0.5)
		blob(UDim2.fromScale(0.44, 0.32), UDim2.fromScale(0.1, 0.46), B.rgb(20, 20, 20))
		blob(UDim2.fromScale(0.36, 0.6), UDim2.fromScale(0.09, 0.02), B.rgb(20, 20, 20))
		-- keys drawn as little yellow marks on the tall one's belt
		for k = 0, 2 do
			blob(UDim2.fromScale(0.45 + k * 0.03, 0.56), UDim2.fromScale(0.02, 0.06), B.rgb(230, 180, 30))
		end
	end
	return paper
end

return P
