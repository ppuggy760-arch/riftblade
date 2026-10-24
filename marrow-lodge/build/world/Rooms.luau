-- Furnishing for every room of the lodge, the notes, and the item spots.

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

local Rooms = {}

local N, S, E, W = V(0, 0, 1), V(0, 0, -1), V(1, 0, 0), V(-1, 0, 0)

local function at(x, y, z, look)
	local p = V(x, y, z)
	return CFrame.lookAt(p, p + (look or S))
end

local function note(cf, key, size)
	return P.note(cf, Story[key].text, Story[key].style, size)
end

local function wallNote(cf, key)
	return P.wallNote(cf, Story[key].text, Story[key].style)
end

local gy, uy = L.yGround, L.yUpper

---------------------------------------------------------------- ground floor

local function greatHall()
	B.within("GreatHall", function()
		-- hearth on the west wall
		local fire = at(L.inX0 + 1.6, gy, -11, E)
		local mantel = P.fireplace(fire, 11, L.yCeilG - gy)
		P.candlestick((mantel * CF(-3.5, 0, 0)).Position, 0.9, { range = 9, brightness = 0.6 })
		P.candlestick((mantel * CF(3.5, 0, 0)).Position, 0.9, nil)
		B.box(V(1.6, 1.4, 0.8), mantel * CF(0, 0.7, 0.2), B.rgb(98, 54, 28), M.Wood, { name = "MantelClock" })
		P.clockFace(mantel * CF(0, 0.75, -0.25) * CFrame.Angles(0, 0, 0), 0.5, C.cream)
		P.painting(at(L.inX0 + 3.2, gy + 10.4, -11, E), 5.6, 3.8, "portrait")

		-- sitting area
		P.rug(at(-22, gy, -11, E), 12, 15, B.rgb(150, 50, 36), B.rgb(214, 160, 52), B.rgb(120, 40, 30))
		P.sofa(at(-15.5, gy, -11, W), 9.5, B.rgb(110, 54, 36))
		P.armchair(at(-23, gy, -19.5, V(-0.3, 0, 1).Unit), B.rgb(130, 76, 40))
		P.armchair(at(-23, gy, -2.5, V(-0.3, 0, -1).Unit), B.rgb(130, 76, 40))
		local tableTop = P.table(at(-22, gy, -11, E), 5.0, 3.0, 1.9, B.rgb(120, 76, 40), "log")
		P.candle((tableTop * CF(0, 0, 1.2)).Position, 0.6, { range = 7, brightness = 0.5 })
		B.box(V(1.2, 0.3, 0.9), tableTop * CF(0.2, 0.15, -1.0), B.rgb(120, 30, 28), M.Fabric, { name = "Book", collide = false })
		B.box(V(1.1, 0.25, 0.85), tableTop * CF(0.25, 0.42, -1.0) * CFrame.Angles(0, 0.3, 0), C.navy, M.Fabric, { name = "Book", collide = false })
		B.vcyl(0.45, 0.4, (tableTop * CF(-0.6, 0.23, 0.3)).Position, B.rgb(240, 236, 226), M.SmoothPlastic, { name = "Mug", collide = false })
		for _, z in { -17.2, -4.8 } do
			local side = P.table(at(-15.5, gy, z, W), 2.0, 2.0, 2.6, B.rgb(120, 76, 40))
			P.tableLamp(side, B.rgb(244, 214, 150), { range = 16, brightness = 1.2, shadows = true })
		end
		P.floorLamp(at(-29, gy, -20.5, E))
		P.rockingChair(at(-30, gy, -2.5, V(0.6, 0, -1).Unit))
		P.chandelier(V(-22, L.yCeilG - 1.1, -11), 3.2, 2.6, 8)

		-- by the door
		local console = P.table(at(-4.5, gy, -26.2, N), 4.2, 1.5, 3.0, B.rgb(110, 66, 34))
		note(console * CF(-0.6, 0.02, 0) * CFrame.Angles(0, math.rad(8), 0), "register", V(1.4, 0.18, 1.0))
		P.tableLamp(console * CF(1.3, 0, 0), B.rgb(236, 206, 150))
		P.wallClock(at(-4.5, gy + 7.8, L.inZ0, N), 0.8)
		-- coat tree with a hat and a lantern coat
		local ct = V(3.6, gy, -25.6)
		B.vcyl(7.4, 0.3, ct + V(0, 3.7, 0), B.rgb(90, 56, 30), M.Wood, { name = "CoatTree" })
		for i = 0, 3 do
			local a = i * math.pi / 2
			B.rod(ct + V(0, 6.6, 0), ct + V(math.cos(a) * 0.8, 7.2, math.sin(a) * 0.8), 0.12, B.rgb(90, 56, 30), M.Wood, { name = "Peg", collide = false })
			B.rod(ct + V(0, 0.2, 0), ct + V(math.cos(a + 0.7) * 1.0, 0.05, math.sin(a + 0.7) * 1.0), 0.18, B.rgb(90, 56, 30), M.Wood, { name = "Foot", collide = false })
		end
		B.box(V(1.4, 2.6, 0.6), CFrame.new(ct + V(0.6, 5.6, 0.2)) * CFrame.Angles(0, 0.4, 0.1), B.rgb(110, 90, 60), M.Fabric, { name = "Coat", collide = false })
		B.vcyl(0.6, 1.2, ct + V(-0.6, 7.4, 0.2), C.soot, M.Fabric, { name = "Hat", collide = false })
		B.vcyl(0.1, 1.8, ct + V(-0.6, 7.1, 0.2), C.soot, M.Fabric, { name = "HatBrim", collide = false })

		-- runner from the door to the dining room
		P.rug(at(2.5, gy, -11, N), 4.5, 28, B.rgb(120, 40, 34), B.rgb(214, 160, 52), B.rgb(150, 56, 40))
		P.piano(at(7.4, gy, -25.4, N))
		P.painting(at(11.6, gy + 7.5, -11.8, W), 5, 3.5, "pines")
		P.painting(at(-26.5, gy + 8, 5.6, S), 4, 3, "lake")
		-- china hutch between the arches
		local hutch = at(-12.5, gy, 4.4, S)
		B.box(V(8, 3.6, 2.2), hutch * CF(0, 1.8, 0), B.rgb(110, 66, 34), M.Wood, { name = "Hutch" })
		B.box(V(8.4, 0.25, 2.4), hutch * CF(0, 3.72, 0), B.rgb(126, 78, 42), M.Wood, { name = "HutchTop" })
		B.box(V(7.4, 5.2, 1.0), hutch * CF(0, 6.5, 0.5), B.rgb(110, 66, 34), M.Wood, { name = "HutchUpper" })
		for k = 0, 2 do
			B.box(V(7.0, 0.12, 0.8), hutch * CF(0, 4.6 + k * 1.6, 0.4), B.rgb(126, 78, 42), M.Wood, { name = "HutchShelf", collide = false })
			for i = 0, 5 do
				B.cyl(V(0.08, 1.0, 1.0), hutch * CF(-2.9 + i * 1.15, 5.1 + k * 1.6, 0.6) * CFrame.Angles(0, math.pi / 2, math.rad(-12)), B.rgb(236, 230, 214), M.SmoothPlastic, { name = "Plate", collide = false })
			end
		end
		P.sconce(at(-35.15 + 0.1, gy + 7, -23, E))
		P.sconce(at(11.55, gy + 7, -24, W))
		P.sconce(at(11.55, gy + 7, 1.5, W))
		P.pottedPlant(at(-34, gy, 4, E), 1.1)
		P.pottedPlant(at(10.4, gy, 4.2, W), 0.9)
	end)
end

local function kitchen()
	B.within("Kitchen", function()
		local counterTop = P.counter(at(-24.6, gy, L.inZ1 - 1.3, S), 21, { sink = 5.6 })
		note(counterTop * CF(-6, 0.03, 0.2) * CFrame.Angles(0, math.rad(-14), 0), "recipe", V(0.8, 0.04, 1.1))
		B.vcyl(0.6, 1.0, (counterTop * CF(-3, 0.3, 0)).Position, B.rgb(200, 150, 90), M.Wood, { name = "BreadBoard", collide = false })
		B.ball(0.9, (counterTop * CF(-3, 0.85, 0)).Position, B.rgb(210, 150, 70), M.SmoothPlastic, { name = "Loaf", collide = false })
		for i = 0, 3 do
			B.vcyl(B.range(0.6, 1.0), 0.45, (counterTop * CF(-8 + i * 0.55, 0.4, 0.6)).Position, B.pick({ C.red, C.mustard, C.cream, C.green }), M.SmoothPlastic, { name = "Canister", collide = false })
		end
		P.woodStove(at(L.inX0 + 1.6, gy, 11, E))
		P.icebox(at(-13.8, gy, 8.6, W))
		P.jarShelf(at(L.inX0 + 0.8, gy, 23.5, E), 5, 4)
		local top = P.table(at(-24, gy, 16, E), 4.5, 8, 3.0, B.rgb(150, 100, 56), "log")
		for _, side in { -1, 1 } do
			for _, dx in { -1.8, 1.8 } do
				P.chair(at(-24 + dx, gy, 16 + side * 3.5, if side > 0 then S else N))
			end
		end
		note(top * CF(1.2, 0.02, -0.6) * CFrame.Angles(0, math.rad(20), 0), "odetteLetter", V(0.95, 0.04, 1.25))
		B.vcyl(0.5, 2.0, (top * CF(-0.6, 0.25, 0.8)).Position, B.rgb(196, 140, 84), M.Wood, { name = "Bowl", collide = false })
		for i = 0, 4 do
			B.ball(0.5, (top * CF(-0.6 + B.range(-0.5, 0.5), 0.6, 0.8 + B.range(-0.5, 0.5))).Position, B.pick({ B.rgb(200, 40, 30), B.rgb(220, 180, 40) }), M.SmoothPlastic, { name = "Apple", collide = false })
		end
		B.vcyl(0.5, 1.8, (top * CF(0.4, 0.25, 2.2)).Position, B.rgb(220, 160, 80), M.SmoothPlastic, { name = "Pie", collide = false })
		P.hangingPots(at(-24, L.yCeilG - 2.2, 16, E), 6)
		P.pendant(V(-24, L.yCeilG - 1.1, 12.5), 3.2, B.rgb(160, 110, 50))
		P.pendant(V(-24, L.yCeilG - 1.1, 19.5), 3.2, B.rgb(160, 110, 50))
		P.wallClock(at(-12.45, gy + 8.5, 25, W), 0.8)
		-- butter churn and flour barrel by the icebox
		P.barrel(at(-14.5, gy, 12.5, W), 3.0)
		B.vcyl(3.2, 1.2, V(-31, gy + 1.6, 7.5), B.rgb(170, 120, 70), M.Wood, { name = "Churn" })
		B.vcyl(2.0, 0.12, V(-31, gy + 4.0, 7.5), B.rgb(140, 100, 60), M.Wood, { name = "Dasher", collide = false })
	end)
end

local function dining()
	B.within("Dining", function()
		P.rug(at(0, gy, 17, N), 10, 18, B.rgb(46, 58, 86), B.rgb(214, 160, 52), B.rgb(60, 72, 100))
		P.table(at(0, gy, 17, E), 14, 5, 3.0, B.rgb(110, 66, 34))
		-- chairs along both long sides and at the ends
		for i = -1, 1 do
			P.chair(at(-3.4, gy, 17 + i * 4, E))
			P.chair(at(3.4, gy, 17 + i * 4, W))
		end
		P.chair(at(0, gy, 8.6, N))
		P.chair(at(0, gy, 25.4, S))
		-- set for three: the head of the table and the two places nearest it
		for _, p in { { 0, 23.0 }, { -1.6, 21.0 }, { 1.6, 21.0 } } do
			local pos = V(p[1], gy + 3.0, p[2])
			B.cyl(V(0.08, 1.2, 1.2), CFrame.new(pos + V(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2), B.rgb(244, 240, 228), M.SmoothPlastic, { name = "Plate", collide = false })
			B.vcyl(0.6, 0.35, pos + V(0.8, 0.3, 0.2), B.rgb(220, 236, 236), M.Glass, { name = "Glass", collide = false, transparency = 0.5 })
			B.box(V(0.1, 0.04, 0.9), CFrame.new(pos + V(-0.8, 0.03, 0)), B.rgb(200, 200, 196), M.Metal, { name = "Fork", collide = false })
			B.box(V(0.1, 0.04, 0.9), CFrame.new(pos + V(0.75, 0.03, -0.4)), B.rgb(200, 200, 196), M.Metal, { name = "Knife", collide = false })
		end
		for _, z in { 13, 17, 21 } do
			P.candlestick(V(0, gy + 3.0, z), 0.9, if z == 17 then { range = 12, brightness = 0.8 } else nil)
		end
		P.chandelier(V(0, L.yCeilG - 1.1, 17), 4.2, 2.4, 6)
		-- hutch against the study wall and a painting
		local sb = at(10.6, gy, 10.4, W)
		B.box(V(5.6, 3.4, 1.8), sb * CF(0, 1.7, 0), B.rgb(118, 70, 36), M.Wood, { name = "Sideboard" })
		B.box(V(6.0, 0.25, 2.0), sb * CF(0, 3.52, 0), B.rgb(132, 82, 44), M.Wood, { name = "SideboardTop" })
		for i = 0, 2 do
			B.box(V(1.6, 2.4, 0.08), sb * CF(-1.8 + i * 1.8, 1.7, -0.93), B.vary(B.rgb(118, 70, 36), 0.08), M.Wood, { name = "Door", collide = false })
		end
		P.candlestick((sb * CF(-2, 3.65, 0)).Position, 0.8, { range = 9, brightness = 0.6 })
		B.vcyl(1.4, 1.0, (sb * CF(1.2, 4.35, 0)).Position, B.rgb(60, 90, 140), M.SmoothPlastic, { name = "Vase", collide = false })
		for i = 0, 4 do
			B.ball(0.55, (sb * CF(1.2 + B.range(-0.5, 0.5), 5.4 + B.range(0, 0.5), B.range(-0.3, 0.3))).Position, B.pick({ B.rgb(255, 200, 40), B.rgb(250, 160, 30) }), M.SmoothPlastic, { name = "Flower", collide = false })
		end
		P.painting(at(11.55, gy + 7.5, 24, W), 3.6, 4.4, "lake")
		P.painting(at(-11.55, gy + 7.5, 24.5, E), 3.2, 4.0, "pines")
		-- hooks and boots by the back door
		for i = 0, 3 do
			B.box(V(0.2, 0.2, 0.6), at(-11.3, gy + 6.2, 23.5 + i * 0.8, E), C.iron, M.Metal, { name = "Hook", collide = false })
		end
		B.box(V(1.4, 3.0, 0.5), at(-11.1, gy + 4.6, 24.3, E), B.rgb(80, 60, 40), M.Fabric, { name = "Jacket", collide = false })
		for i = 0, 1 do
			B.box(V(0.7, 1.4, 1.3), at(-10.6, gy + 0.7, 23.6 + i * 0.9, E), B.rgb(60, 40, 26), M.Leather, { name = "Boot", collide = false })
		end
		P.sconce(at(-11.55, gy + 7, 8.5, E))
		P.sconce(at(11.55, gy + 7, 21.5, W))
	end)
end

local function study()
	B.within("Study", function()
		local shelfH = 8.5
		-- fixed cases either side of the moving one
		local books1 = P.bookshelf(at(L.inX1 - 0.75, gy, 10.0, W), 6.8, shelfH, 1.5)
		local books2 = P.bookshelf(at(L.inX1 - 0.75, gy, 23.3, W), 7.6, shelfH, 1.5)
		local _ = books1, books2
		-- one crown across all three so they read as a single built-in
		B.box(V(2.0, 0.6, L.inZ1 - 6.4), CFrame.new(L.inX1 - 0.85, gy + shelfH + 0.6, (L.inZ1 + 6.4) / 2), B.rgb(100, 60, 30), M.Wood, { name = "Crown" })
		B.box(V(2.2, 0.25, L.inZ1 - 6.2), CFrame.new(L.inX1 - 0.9, gy + shelfH + 1.0, (L.inZ1 + 6.4) / 2), B.rgb(100, 60, 30), M.Wood, { name = "CrownCap" })

		P.rug(at(23, gy, 16, E), 11, 13, B.rgb(36, 46, 78), B.rgb(170, 120, 50), B.rgb(46, 60, 96))
		local desk = P.desk(at(22, gy, 21.5, S), 7)
		P.bankerLamp(desk * CF(-2.4, 0, 0.6))
		note(desk * CF(0.3, 0.02, 0) * CFrame.Angles(0, math.rad(-6), 0), "journal1", V(1.6, 0.12, 1.1))
		B.vcyl(0.4, 0.35, (desk * CF(1.9, 0.2, 0.5)).Position, C.soot, M.Glass, { name = "Inkwell", collide = false, transparency = 0.2 })
		B.rod((desk * CF(1.9, 0.35, 0.5)).Position, (desk * CF(2.2, 1.2, 0.8)).Position, 0.06, B.rgb(240, 236, 220), M.SmoothPlastic, { name = "Quill", collide = false })
		for i = 0, 2 do
			B.box(V(0.9, 0.02, 1.2), desk * CF(2.4 + B.range(-0.2, 0.2), 0.02 + i * 0.02, -0.4) * CFrame.Angles(0, B.range(-0.4, 0.4), 0), C.paper, M.SmoothPlastic, { name = "Paper", collide = false })
		end
		P.armchair(at(22, gy, 24.4, S), B.rgb(90, 40, 30))
		-- reading chair by the shelves with the second page
		P.armchair(at(30.5, gy, 12.5, V(-0.6, 0, -1).Unit), B.rgb(60, 80, 56))
		local side = P.table(at(32.8, gy, 15.5, W), 1.8, 1.8, 2.6, B.rgb(110, 66, 34))
		note(side * CF(0, 0.02, 0) * CFrame.Angles(0, math.rad(25), 0), "journal2")
		P.candle((side * CF(0.5, 0, 0.5)).Position, 0.5, { range = 7, brightness = 0.5 })
		P.floorLamp(at(28, gy, 10, W))
		-- globe
		local g = V(15.5, gy, 24.5)
		B.vcyl(2.6, 0.25, g + V(0, 1.3, 0), B.rgb(110, 66, 34), M.Wood, { name = "GlobeStand" })
		B.ball(1.6, g + V(0, 3.3, 0), B.rgb(150, 170, 120), M.SmoothPlastic, { name = "Globe" })
		B.cyl(V(0.12, 1.9, 1.9), CFrame.new(g + V(0, 3.3, 0)) * CFrame.Angles(0, 0.5, math.rad(23)), C.brass, M.Metal, { name = "Meridian", collide = false })
		P.painting(at(12.45, gy + 8, 9.5, E), 4.4, 3.4, "pines")
		P.wallClock(at(12.45, gy + 8.5, 23.5, E), 0.8)
		Pickups.hairpin(desk * CF(-0.8, 0.0, -0.9) * CFrame.Angles(0, 0.7, 0))
	end)
end

local function secretShelf(doorFolder)
	-- The middle case swings into the hidden passage when the green book is pulled.
	B.push(doorFolder)
	local p = V(L.X1, gy, 16.5)
	local frame = CFrame.lookAt(p, p + W)
	local trigger, decoys = nil, {}
	Kit.door({
		id = "Bookcase",
		name = "Bookcase",
		frame = frame,
		w = 5.4,
		h = 8.5,
		wallT = L.logD,
		proximity = false,
		autoClose = 9,
		swingDir = 1,
		openAngle = 78,
		frameParts = false,
		buildLeaf = function(Lc, pw, H, T)
			-- front of the case faces the study (+Z of the hinge frame)
			local depth = 2.9
			local base = Lc(pw / 2, -H / 2, 0.85) * CFrame.Angles(0, math.pi, 0)
			local books = P.bookshelf(base, pw - 0.05, H, depth)
			-- pick a spine on the third shelf for the green book, and a few decoys
			local candidates = {}
			for _, b in books do
				local localY = (base:Inverse() * b.CFrame).Position.Y
				if localY > 3.4 and localY < 5.3 and b.Size.X > 0.28 then
					table.insert(candidates, b)
				end
			end
			trigger = candidates[math.max(1, math.floor(#candidates * 0.6))] or books[math.floor(#books / 2)]
			trigger.Color = B.rgb(40, 116, 66)
			trigger.Name = "GreenBook"
			trigger:SetAttribute("PullBook", true)
			for i, b in books do
				if b ~= trigger and i % 11 == 5 and #decoys < 5 then
					b:SetAttribute("DecoyBook", true)
					table.insert(decoys, b)
				end
			end
			-- back of the case, seen from the passage: plain boards and an iron ring pull
			local back = B.box(V(pw, H - 0.2, 0.2), Lc(pw / 2, 0, -0.65), B.rgb(96, 64, 38), M.WoodPlanks, { name = "BackBoards" })
			B.cyl(V(0.12, 0.7, 0.7), Lc(pw - 0.7, -0.6, -0.85) * CFrame.Angles(0, math.pi / 2, 0), C.iron, M.Metal, { name = "RingPull", collide = false })
			back:SetAttribute("InnerPull", true)
			B.prompt(B.attach(back, CF(pw / 2 - 0.7, -0.6, -0.35), "PullPoint"), {
				Name = "PullPrompt",
				ActionText = "Pull",
				ObjectText = "",
				HoldDuration = 0.4,
				MaxActivationDistance = 6,
				RequiresLineOfSight = true,
			}, { Opens = "Bookcase" })
		end,
	})
	B.pop()
	for _, b in { trigger, table.unpack(decoys) } do
		B.prompt(b, {
			Name = "PullPrompt",
			ActionText = "Pull",
			ObjectText = "",
			HoldDuration = 0.5,
			MaxActivationDistance = 6,
		}, if b == trigger then { Opens = "Bookcase" } else { Decoy = true })
	end
end

local function bathroom()
	B.within("Bathroom", function()
		P.clawTub(at(30, gy, -24.6, N))
		local sinkTop = P.pedestalSink(at(20, gy, -13.4, S))
		Pickups.hairpin(sinkTop * CF(-0.2, 0, 0.2) * CFrame.Angles(0, 1.2, 0))
		B.box(V(3.0, 3.8, 0.2), at(20, gy + 7.4, -12.5, S), C.brass, M.Metal, { name = "MirrorFrame" })
		B.box(V(2.6, 3.4, 0.1), at(20, gy + 7.4, -12.65, S), B.rgb(210, 220, 220), M.Glass, { name = "Mirror", reflectance = 0.55, transparency = 0.05 })
		P.sconce(at(17.6, gy + 7.6, -12.45, S), { range = 12, brightness = 0.9 })
		P.sconce(at(22.4, gy + 7.6, -12.45, S), { range = 12, brightness = 0.9 })
		P.toilet(at(L.inX1 - 1.2, gy, -15.5, W))
		-- towel rail with a towel
		B.rod(V(14, gy + 5, -12.6), V(17, gy + 5, -12.6), 0.15, C.brass, M.Metal, { name = "TowelRail", collide = false })
		B.box(V(1.4, 2.6, 0.12), at(15.5, gy + 3.9, -12.75, S), C.cream, M.Fabric, { name = "Towel", collide = false })
		P.rug(at(29, gy, -20.6, N), 5, 2.5, B.rgb(214, 160, 52), C.cream)
		P.pottedPlant(at(14, gy, -26, N), 0.8)
		local stool = P.table(at(25, gy, -25.5, N), 1.6, 1.6, 2.4, B.rgb(196, 146, 90))
		B.box(V(1.2, 0.5, 0.9), stool * CF(0, 0.25, 0), C.cream, M.Fabric, { name = "FoldedTowel", collide = false })
		P.candle((stool * CF(0.4, 0.5, 0.2)).Position, 0.6, { range = 7, brightness = 0.5 })
	end)
end

local function pantry()
	B.within("Pantry", function()
		P.jarShelf(at(24, gy, -10.8, N), 10, 4)
		P.jarShelf(at(30, gy, 4.8, S), 8, 4)
		P.barrel(at(14.5, gy, -9.8, N), 3.2)
		P.barrel(at(16.8, gy, -10.0, N), 3.2)
		P.crate(at(15.0, gy, 3.8, S), 2.4)
		P.crate(at(15.2, gy, 3.6, S) * CF(0, 2.4, 0) * CFrame.Angles(0, 0.4, 0), 1.8)
		for i = 0, 2 do
			B.box(V(1.6, 2.2, 1.2), at(19.5 + i * 1.8, gy + 1.1, 4.6, S) * CFrame.Angles(0, 0, math.rad(B.range(-6, 6))), B.rgb(214, 196, 160), M.Fabric, { name = "FlourSack" })
		end
		P.bareBulb(V(24, L.yCeilG, -3.5), 2.6, { range = 20, brightness = 1.2 })
		P.lantern(V(13.6, gy + 6, -0.5), { range = 10, brightness = 0.6 })
		B.box(V(0.6, 0.3, 0.6), at(13.6, gy + 5.85, -0.2, W), C.iron, M.Metal, { name = "LanternBracket", collide = false })
	end)
end

---------------------------------------------------------------- upper floor

local function hallway()
	B.within("Hallway", function()
		P.rug(at(0, uy, 0, S), 64, 4.2, B.rgb(120, 40, 34), B.rgb(214, 160, 52), B.rgb(150, 56, 40))
		P.grandfatherClock(at(L.inX0 + 1.1, uy, 0, E))
		local console = P.table(at(L.inX1 - 1.0, uy, 0, W), 4.0, 1.6, 3.0, B.rgb(110, 66, 34))
		P.tableLamp(console * CF(1.0, 0, 0), B.rgb(244, 214, 150))
		B.vcyl(1.2, 0.9, (console * CF(-1.0, 0.6, 0)).Position, B.rgb(200, 90, 50), M.SmoothPlastic, { name = "Vase", collide = false })
		for _, x in { -30, -12, 12, 30 } do
			P.sconce(at(x, uy + 7, 5.55, S))
		end
		for _, x in { -30, 30 } do
			P.sconce(at(x, uy + 7, -5.55, N))
		end
		P.painting(at(-6, uy + 7.6, 5.55, S), 3.4, 2.6, "pines")
		P.painting(at(18, uy + 7.6, 5.55, S), 3.4, 2.6, "lake")
		P.painting(at(18, uy + 7.6, -5.55, N), 3.0, 3.6, "portrait")
	end)
end

local function loft()
	B.within("Loft", function()
		P.rug(at(3, uy, -16, S), 12, 10, B.rgb(46, 58, 86), B.rgb(214, 160, 52), B.rgb(60, 72, 100))
		-- window seat under the big front window
		local seat = at(0, uy, L.inZ0 + 1.4, N)
		B.box(V(9, 2.2, 2.6), seat * CF(0, 1.1, 0), B.rgb(150, 98, 54), M.Wood, { name = "WindowSeat" })
		B.box(V(8.6, 0.5, 2.4), seat * CF(0, 2.45, 0), C.mustard, M.Fabric, { name = "SeatCushion" })
		for i = 0, 3 do
			B.box(V(1.3, 1.3, 0.4), seat * CF(-3.4 + i * 2.2, 3.2, 0.9) * CFrame.Angles(math.rad(12), 0, math.rad(B.range(-10, 10))), B.pick({ C.red, C.cream, C.navy, C.green }), M.Fabric, { name = "Pillow", collide = false })
		end
		P.bookshelf(at(11.6 - 0.75, uy, -16, W), 8, 9, 1.5)
		P.armchair(at(4.5, uy, -12, V(-0.2, 0, -1).Unit), B.rgb(150, 50, 36))
		-- the rocking chair faces the top of the stairs
		P.rockingChair(at(-3.5, uy, -9.5, V(-0.4, 0, 1).Unit), B.rgb(98, 58, 30))
		local side = P.table(at(7.5, uy, -9.0, S), 1.8, 1.8, 2.6, B.rgb(110, 66, 34))
		P.tableLamp(side, B.rgb(236, 206, 150), { range = 16, brightness = 1.1, shadows = true })
		P.floorLamp(at(-5, uy, -25, N))
		P.pottedPlant(at(8.5, uy, -25.5, N), 1.0)
		P.chandelier(V(0, L.yCeilU - 1.0, -15), 3.0, 2.2, 6)
	end)
end

local function guestRoom()
	B.within("GuestRoom", function()
		P.bed(at(L.inX0 + 4.6, uy, -10.6, E), 6, 8.5, B.rgb(70, 110, 140), B.rgb(236, 224, 190))
		local ns = P.nightstand(at(L.inX0 + 1.4, uy, -15.6, E))
		P.tableLamp(ns, B.rgb(236, 206, 150), { range = 15, brightness = 1.0, shadows = true })
		note(ns * CF(0.2, 0.02, -0.4) * CFrame.Angles(0, math.rad(30), 0), "theoNote")
		P.wardrobe(at(-14.0, uy, -24.5, W))
		local dresserTop = P.dresser(at(-13.4, uy, -18, W), 5, true)
		Pickups.hairpin(dresserTop * CF(1.4, 0, 0.2) * CFrame.Angles(0, 0.4, 0))
		-- the Okafors' open suitcase
		local sc = at(-20, uy, -12, V(0.4, 0, -1).Unit)
		B.box(V(3.2, 0.9, 2.2), sc * CF(0, 0.45, 0), B.rgb(120, 60, 40), M.Leather, { name = "Suitcase" })
		B.box(V(3.2, 2.2, 0.3), sc * CF(0, 1.9, 1.2) * CFrame.Angles(math.rad(-15), 0, 0), B.rgb(120, 60, 40), M.Leather, { name = "SuitcaseLid" })
		B.box(V(2.8, 0.4, 1.8), sc * CF(0, 0.95, 0), B.rgb(230, 210, 170), M.Fabric, { name = "Clothes", collide = false })
		B.box(V(1.4, 0.3, 1.1), sc * CF(0.6, 1.25, -0.2) * CFrame.Angles(0, 0.4, 0), B.rgb(60, 110, 160), M.Fabric, { name = "Shirt", collide = false })
		P.chair(at(-15, uy, -9, V(-1, 0, -0.3).Unit))
		P.rug(at(-24, uy, -16, E), 7, 9, B.rgb(70, 110, 140), C.cream)
		P.bareBulb(V(-24, L.yCeilU, -16), 1.6, { range = 18, brightness = 0.9 })
	end)
end

local function sewingRoom()
	B.within("SewingRoom", function()
		P.sewingTable(at(20, uy, L.inZ0 + 1.6, N))
		P.chair(at(20, uy, -22.4, S))
		P.dressForm(at(30.5, uy, -20, V(-1, 0, 0.4).Unit))
		P.rockingChair(at(30, uy, -11, V(-0.6, 0, -1).Unit), B.rgb(150, 98, 54))
		-- yarn basket
		local yb = V(27.5, uy, -10)
		B.vcyl(1.2, 2.0, yb + V(0, 0.6, 0), B.rgb(180, 140, 80), M.Fabric, { name = "Basket" })
		for i = 0, 4 do
			B.ball(0.7, yb + V(B.range(-0.5, 0.5), 1.3 + B.range(0, 0.3), B.range(-0.5, 0.5)), B.pick({ C.red, C.mustard, C.cream, B.rgb(196, 120, 140) }), M.Fabric, { name = "Yarn", collide = false })
		end
		-- shelf of fabric bolts
		local sh = at(L.inX1 - 0.8, uy, -24, W)
		B.box(V(6, 0.2, 1.4), sh * CF(0, 4.5, 0), B.rgb(150, 98, 54), M.Wood, { name = "Shelf" })
		B.box(V(6, 0.2, 1.4), sh * CF(0, 6.5, 0), B.rgb(150, 98, 54), M.Wood, { name = "Shelf" })
		for k = 0, 1 do
			for i = 0, 4 do
				B.cyl(V(1.2, 0.8, 0.8), sh * CF(-2.4 + i * 1.2, 5.05 + k * 2.0, 0) * CFrame.Angles(0, math.pi / 2, 0), B.pick({ C.red, C.mustard, C.cream, C.navy, C.green, B.rgb(196, 120, 140) }), M.Fabric, { name = "Bolt", collide = false })
			end
		end
		-- pincushion with a hairpin beside it
		local cushion = V(18.6, uy + 3.12, L.inZ0 + 1.6)
		B.ball(0.6, cushion + V(0, 0.2, 0.2), C.red, M.Fabric, { name = "Pincushion", collide = false })
		Pickups.hairpin(CFrame.new(cushion + V(1.0, 0, 0.5)) * CFrame.Angles(0, 0.9, 0))
		P.rug(at(24, uy, -16, E), 8, 8, B.rgb(196, 120, 140), C.cream)
		P.pendant(V(22, L.yCeilU, -18), 2.2, B.rgb(196, 160, 90))
		P.painting(at(12.45, uy + 8, -18, E), 3.0, 3.6, "lake")
	end)
end

local function masterBedroom()
	B.within("MasterBedroom", function()
		P.bed(at(-17.15, uy, 16.5, W), 6.6, 8.5, B.rgb(150, 50, 36), B.rgb(236, 216, 170))
		for _, z in { 11.6, 21.4 } do
			local ns = P.nightstand(at(-13.6, uy, z, W))
			P.tableLamp(ns, B.rgb(244, 214, 150), { range = 15, brightness = 1.0, shadows = z < 15 })
		end
		local dresserTop = P.dresser(at(L.inX0 + 1.2, uy, 10.5, E), 5.5, true)
		note(dresserTop * CF(0.8, 0.02, 0) * CFrame.Angles(0, math.rad(-12), 0), "odetteUnsent")
		P.candlestick((dresserTop * CF(-1.8, 0, 0.3)).Position, 0.8, { range = 9, brightness = 0.6 })
		P.wardrobe(at(-31.5, uy, 7.6, N))
		-- vanity with a hairpin
		local vanity = P.table(at(-24, uy, L.inZ1 - 1.2, S), 3.6, 1.8, 2.8, B.rgb(140, 90, 50))
		B.box(V(2.6, 3.0, 0.15), at(-24, uy + 4.8, L.inZ1 - 0.25, S), B.rgb(210, 220, 220), M.Glass, { name = "Mirror", reflectance = 0.5, transparency = 0.05 })
		Pickups.hairpin(vanity * CF(0.8, 0, 0.1) * CFrame.Angles(0, 0.3, 0))
		B.vcyl(0.5, 0.4, (vanity * CF(-0.8, 0.25, 0.2)).Position, B.rgb(200, 160, 200), M.Glass, { name = "Perfume", collide = false, transparency = 0.3 })
		P.armchair(at(-27, uy, 19.5, V(0.4, 0, -1).Unit), B.rgb(140, 120, 90), M.Fabric)
		P.rug(at(-22, uy, 16.5, E), 10, 12, B.rgb(150, 50, 36), B.rgb(214, 160, 52), B.rgb(120, 40, 30))
		-- a child's chair, empty, by the bed
		local cc = at(-20, uy, 11, V(0.5, 0, 1).Unit)
		B.box(V(1.2, 0.2, 1.2), cc * CF(0, 1.4, 0), B.rgb(214, 160, 52), M.Wood, { name = "SmallSeat" })
		for _, sx in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				B.box(V(0.15, 1.4, 0.15), cc * CF(sx, 0.7, sz), B.rgb(214, 160, 52), M.Wood, { name = "SmallLeg" })
			end
		end
		B.box(V(1.2, 1.2, 0.15), cc * CF(0, 2.1, 0.55), B.rgb(214, 160, 52), M.Wood, { name = "SmallBack" })
		P.chandelier(V(-24, L.yCeilU - 1.0, 16.5), 2.6, 2.0, 5)
		P.painting(at(-12.45, uy + 9.6, 16.5, W), 4.0, 2.6, "pines")
	end)
end

local function junesRoom()
	B.within("JunesRoom", function()
		P.cot(at(0, uy, L.inZ1 - 4.0, S), B.rgb(240, 200, 60))
		P.teddy(at(0.6, uy + 2.6, L.inZ1 - 2.6, S), 0.55, B.rgb(196, 140, 80))
		for _, x in { -3.2, 3.2 } do
			local ns = P.nightstand(at(x, uy, L.inZ1 - 1.2, S))
			if x < 0 then
				P.tableLamp(ns, B.rgb(255, 214, 90), { range = 15, brightness = 1.1, shadows = true })
			else
				P.candle((ns * CF(0, 0, 0)).Position, 0.5, { range = 8, brightness = 0.5 })
			end
		end
		P.rockingHorse(at(-6.5, uy, 13, V(1, 0, -0.4).Unit))
		local dt = P.table(at(7.5, uy, 12.5, W), 6.4, 5.2, 2.6, B.rgb(214, 196, 150))
		P.dollhouse(dt)
		local toy = P.trunk(at(-8.8, uy, 22, E), 3.2, false)
		B.ball(0.9, (toy * CF(0, 0.5, 0)).Position, B.rgb(220, 60, 50), M.SmoothPlastic, { name = "Ball", collide = false })
		-- small table set for tea
		local tt = P.table(at(5.5, uy, 20, S), 2.6, 2.6, 1.8, B.rgb(240, 236, 220))
		for i = 0, 2 do
			local a = i * 2.1
			B.vcyl(0.3, 0.5, (tt * CF(math.cos(a) * 0.7, 0.15, math.sin(a) * 0.7)).Position, B.rgb(250, 250, 250), M.SmoothPlastic, { name = "Cup", collide = false })
		end
		local dresserTop = P.dresser(at(-10.5, uy, 9.0, E), 3.6, false)
		Pickups.hairpin(dresserTop * CF(0.6, 0, 0) * CFrame.Angles(0, 1.1, 0))
		B.box(V(0.9, 0.06, 0.9), dresserTop * CF(-0.8, 0.03, 0), B.rgb(255, 214, 90), M.Fabric, { name = "HairRibbon", collide = false })
		-- drawings pinned to the wall, one of them can be read
		P.drawing(at(-11.55, uy + 6.0, 16, E), "house")
		P.drawing(at(-11.55, uy + 6.2, 19, E), "girl")
		wallNote(at(-11.55, uy + 5.6, 22, E), "juneDrawing")
		P.rug(at(0, uy, 16, E), 7, 7, B.rgb(255, 214, 90), B.rgb(240, 236, 220))
		P.pendant(V(0, L.yCeilU, 15), 2.2, B.rgb(240, 200, 80))
	end)
end

local function atticRoom()
	B.within("AtticRoom", function()
		P.sheetCovered(at(18, uy, 14, S), 5.5, 3.2, 2.6)
		P.sheetCovered(at(30, uy, 12, W), 3, 5.5, 3)
		P.sheetCovered(at(16.5, uy, 22, E), 3.2, 4.2, 3.2)
		P.sheetCovered(at(24, uy, 17, S), 2.4, 2.8, 2.4)
		-- the Okafors' trunk, with their tag
		local tt = P.trunk(at(23.5, uy, 24.5, S), 3.6, false)
		note(tt * CF(0.5, 0.65, -0.3) * CFrame.Angles(0, 0.3, 0), "trunkTag", V(0.6, 0.04, 0.4))
		-- the trunk the bar lives in
		local open = P.trunk(at(30.5, uy, 22.5, W), 4.0, true)
		B.box(V(3.5, 0.3, 1.6), open * CF(0, -0.15, 0), B.rgb(200, 180, 140), M.Fabric, { name = "OldLinen", collide = false })
		Pickups.prybar(open * CF(0, 0.02, 0))
		for i = 0, 3 do
			P.crate(at(33.5, uy, 8.5 + i * 0.1, W) * CF(0, i * 2.2, 0) * CFrame.Angles(0, B.range(-0.2, 0.2), 0), 2.2)
		end
		local crateTop = P.crate(at(14.5, uy, 9, S), 2.6)
		P.crate(at(14.5, uy, 9, S) * CF(0.2, 2.6, 0.1) * CFrame.Angles(0, 0.5, 0), 1.8)
		Pickups.hairpin(crateTop * CF(-0.6, 0, -0.7) * CFrame.Angles(0, 2.1, 0))
		-- picture frames leaning on the wall, faces turned in
		for i = 0, 2 do
			B.box(V(2.4 - i * 0.3, 3.0 - i * 0.4, 0.2), at(20 + i * 0.3, uy + 1.4 - i * 0.2, L.inZ1 - 0.6 - i * 0.3, S) * CFrame.Angles(math.rad(-12), 0, 0), B.rgb(120, 90, 40), M.Wood, { name = "FrameBack", collide = false })
		end
		-- birdcage on a stand
		local bc = V(14.5, uy, 18)
		B.vcyl(4.0, 0.15, bc + V(0, 2.0, 0), C.iron, M.Metal, { name = "Stand" })
		B.vcyl(1.6, 1.4, bc + V(0, 4.8, 0), C.brass, M.Metal, { name = "Cage", transparency = 0.6, collide = false })
		B.ball(0.6, bc + V(0, 5.8, 0), C.brass, M.Metal, { name = "CageTop", collide = false })
		P.bareBulb(V(24, L.yCeilU, 18), 1.8, { range = 18, brightness = 0.7 })
		-- dust in the air
		local dustPart = B.box(V(18, 8, 16), CF(24, uy + 5, 17), C.warm, M.SmoothPlastic, { name = "Dust", collide = false, transparency = 1, shadow = false, query = false })
		local dust = B.Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		dust.Color = B.roblox.ColorSequence.new(B.rgb(255, 230, 180))
		dust.LightEmission = 0.4
		dust.Size = B.roblox.NumberSequence.new(0.07)
		dust.Transparency = B.roblox.NumberSequence.new(0.35)
		dust.Lifetime = B.roblox.NumberRange.new(6, 10)
		dust.Rate = 10
		dust.Speed = B.roblox.NumberRange.new(0.1, 0.4)
		dust.SpreadAngle = B.roblox.Vector2.new(180, 180)
		dust.Shape = Enum.ParticleEmitterShape.Box
		dust.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		dust.Parent = dustPart
		-- cobwebs in the corners
		for _, c in { V(L.inX1 - 0.6, L.yCeilU - 0.6, L.inZ1 - 0.6), V(12.9, L.yCeilU - 0.6, L.inZ1 - 0.6), V(L.inX1 - 0.6, L.yCeilU - 0.6, 6.9) } do
			for k = 0, 2 do
				B.box(V(2.4, 0.03, 0.03), CFrame.new(c) * CFrame.Angles(0, k * 0.5 + 0.5, math.rad(-35)), B.rgb(240, 240, 236), M.SmoothPlastic, { name = "Web", collide = false, transparency = 0.4, shadow = false })
			end
		end
	end)
end

local function passage()
	B.within("NarrowWay", function()
		local lt = L.leanTo
		-- candles along the floor
		for i, z in { 12.5, 20.5, 26 } do
			P.candle(V(41.6, gy, z), 0.6 + i * 0.1, { range = 11, brightness = 0.7, shadows = i == 2 })
		end
		P.drawing(at(lt.x1 - 0.05, gy + 4.6, 21, W), "girl")
		P.drawing(at(lt.x1 - 0.05, gy + 4.4, 23.5, W), "house")
		wallNote(at(lt.x1 - 0.05, gy + 4.8, 18, W), "lastPage")
		-- a little stool and a doll left sitting on it
		local st = V(41.5, gy, 22)
		B.box(V(1.4, 0.2, 1.4), CFrame.new(st + V(0, 1.4, 0)), B.rgb(120, 80, 46), M.Wood, { name = "Stool" })
		for _, sx in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				B.box(V(0.15, 1.4, 0.15), CFrame.new(st + V(sx, 0.7, sz)), B.rgb(120, 80, 46), M.Wood, { name = "StoolLeg" })
			end
		end
		B.ball(0.5, st + V(0, 2.3, 0), B.rgb(240, 214, 190), M.SmoothPlastic, { name = "DollHead", collide = false })
		B.box(V(0.6, 0.8, 0.4), CFrame.new(st + V(0, 1.85, 0)), B.rgb(240, 200, 60), M.Fabric, { name = "DollDress", collide = false })
		B.box(V(0.55, 0.25, 0.1), CFrame.new(st + V(0, 2.5, -0.2)), B.rgb(150, 90, 40), M.Fabric, { name = "DollHair", collide = false })
		-- cobwebs
		for _, z in { 11, 27 } do
			for k = 0, 2 do
				B.box(V(2.0, 0.03, 0.03), CFrame.new(41.8, 9.0, z) * CFrame.Angles(0, k * 0.6, math.rad(-30)), B.rgb(240, 240, 236), M.SmoothPlastic, { name = "Web", collide = false, transparency = 0.4, shadow = false })
			end
		end
	end)
end

function Rooms.build(root, doorFolder)
	local interior = B.folder("Interior", root)
	B.push(interior)
	greatHall()
	kitchen()
	dining()
	study()
	bathroom()
	pantry()
	hallway()
	loft()
	guestRoom()
	sewingRoom()
	masterBedroom()
	junesRoom()
	atticRoom()
	passage()
	B.pop()
	secretShelf(doorFolder)
	return interior
end

return Rooms
