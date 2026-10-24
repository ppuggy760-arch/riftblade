-- Architectural kit: doors, windows, stairs, railings.

local B = require("../lib/B")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame
local Instance = B.Instance
local Enum = B.Enum

local Kit = {}

local doorCount = 0

-- Size of the hole a door needs in its wall: half-width and height.
function Kit.doorHole(w, h)
	return w / 2 + 0.3, h + 0.3
end

-- Hole a window needs in its wall: half-width and half-height.
function Kit.windowHole(w, h)
	return w / 2 + 0.15, h / 2 + 0.15
end

local function doorFrame(frame, W, H, wallT, trimColor)
	B.within("Frame", function()
		local jd = wallT + 0.12
		for _, s in { -1, 1 } do
			B.box(V(0.3, H + 0.3, jd), frame * CF(s * (W / 2 + 0.15), (H + 0.3) / 2, 0), trimColor, M.Wood, { name = "Jamb" })
			for _, f in { -1, 1 } do
				B.box(V(0.5, H + 0.6, 0.14), frame * CF(s * (W / 2 + 0.42), (H + 0.6) / 2, f * (wallT / 2 + 0.07)), trimColor, M.Wood, { name = "Casing" })
			end
		end
		B.box(V(W + 0.6, 0.3, jd), frame * CF(0, H + 0.15, 0), trimColor, M.Wood, { name = "Head" })
		for _, f in { -1, 1 } do
			B.box(V(W + 1.6, 0.55, 0.18), frame * CF(0, H + 0.62, f * (wallT / 2 + 0.09)), trimColor, M.Wood, { name = "HeadCasing" })
			B.box(V(W + 1.8, 0.12, 0.3), frame * CF(0, H + 0.95, f * (wallT / 2 + 0.15)), trimColor, M.Wood, { name = "Cap" })
		end
		B.box(V(W + 0.6, 0.12, wallT + 0.3), frame * CF(0, 0.06, 0), C.beam, M.Wood, { name = "Threshold" })
	end)
end

local function plankLeaf(L, pw, H, T, o)
	local n = math.max(4, math.floor(pw / 0.85 + 0.5))
	local bw = pw / n
	local base = o.color or B.rgb(140, 88, 46)
	for i = 1, n do
		B.box(V(bw - 0.04, H - 0.2, T), L(bw * (i - 0.5), 0, 0), B.vary(base, 0.07), M.WoodPlanks, { name = "Board" })
	end
	-- back battens + brace
	local zb = -(T / 2 + 0.06)
	for _, y in { -H * 0.3, H * 0.3 } do
		B.box(V(pw - 0.15, 0.55, 0.12), L(pw / 2, y, zb), B.vary(base, 0.05), M.Wood, { name = "Batten", collide = false })
	end
	local p0 = L(0.4, -H * 0.3 + 0.35, zb).Position
	local p1 = L(pw - 0.4, H * 0.3 - 0.35, zb).Position
	B.between(p0, p1, 0.5, 0.12, B.vary(base, 0.05), M.Wood, { name = "Brace", collide = false }, L(0, 0, 0).LookVector * -1)
	-- front strap hinges
	local zf = T / 2 + 0.03
	for _, y in { -H * 0.33, H * 0.33 } do
		B.box(V(2.0, 0.26, 0.06), L(1.0, y, zf), C.iron, M.Metal, { name = "Strap", collide = false })
		B.box(V(2.0, 0.26, 0.06), L(1.0, y, -zf - 0.12), C.iron, M.Metal, { name = "Strap", collide = false })
		B.cyl(V(0.7, 0.22, 0.22), L(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), C.iron, M.Metal, { name = "Knuckle", collide = false })
		for k = 0, 2 do
			B.ball(0.12, L(0.35 + k * 0.6, y, zf + 0.04).Position, C.iron, M.Metal, { name = "Rivet", collide = false })
		end
	end
end

local function panelLeaf(L, pw, H, T, o)
	local base = o.color or B.rgb(150, 98, 54)
	B.box(V(pw, H - 0.2, T), L(pw / 2, 0, 0), base, M.Wood, { name = "Slab" })
	local raised = B.mix(base, B.rgb(255, 230, 190), 0.08)
	for _, f in { -1, 1 } do
		local z = f * (T / 2 + 0.03)
		for _, col in { 0.27, 0.73 } do
			B.box(V(pw * 0.34, H * 0.42, 0.06), L(pw * col, H * 0.2, z), raised, M.Wood, { name = "Raised", collide = false })
			B.box(V(pw * 0.34, H * 0.3, 0.06), L(pw * col, -H * 0.27, z), raised, M.Wood, { name = "Raised", collide = false })
		end
		B.box(V(pw - 0.3, 0.14, 0.05), L(pw / 2, -H * 0.05, z), B.mix(base, B.rgb(0, 0, 0), 0.15), M.Wood, { name = "Rail", collide = false })
	end
	for _, y in { -H * 0.36, H * 0.36 } do
		B.box(V(0.12, 0.6, 0.2), L(0.0, y, 0), C.brass, M.Metal, { name = "Butt", collide = false })
	end
end

-- Builds a swinging, optionally lockable door.
-- o.frame: CFrame at the bottom centre of the doorway on the wall's centre plane,
--          LookVector pointing to the front side (the side you walk in from).
-- The hinge sits on the left as seen from the front.
function Kit.door(o)
	doorCount += 1
	local W, H = o.w or 4.6, o.h or 8.6
	local wallT = o.wallT or 1.6
	local frame = o.frame
	local T = o.thick or 0.3

	local model = Instance.new("Model")
	model.Name = o.name or ("Door" .. doorCount)
	model.Parent = B.parent
	model:SetAttribute("Door", true)
	model:SetAttribute("DoorId", o.id or model.Name)
	model:SetAttribute("Lockable", o.lockable or false)
	model:SetAttribute("Pickable", o.pickable or false)
	model:SetAttribute("Locked", o.locked or false)
	model:SetAttribute("Proximity", if o.proximity == nil then true else o.proximity)
	if o.autoClose then
		model:SetAttribute("AutoClose", o.autoClose)
	end
	model:SetAttribute("SwingDir", o.swingDir or 0)
	model:SetAttribute("OpenAngle", o.openAngle or 96)
	B.push(model)

	if o.frameParts ~= false then
		doorFrame(frame, W, H, wallT, o.trim or C.trim)
	end

	local hingeCF = frame * CF(W / 2 - 0.12, H / 2, 0) * CFrame.Angles(0, math.pi, 0)
	local hinge = B.box(V(0.2, H, 0.2), hingeCF, C.iron, M.SmoothPlastic, {
		name = "Hinge",
		transparency = 1,
		collide = false,
		shadow = false,
		query = false,
	})
	model.PrimaryPart = hinge
	local pw = W - 0.2
	model:SetAttribute("Width", pw)
	model:SetAttribute("Height", H)

	local function L(x, y, z)
		return hingeCF * CF(x, y, z)
	end

	local leaf = Instance.new("Model")
	leaf.Name = "Leaf"
	leaf.Parent = model
	B.push(leaf)
	local style = o.style or "plank"
	if o.buildLeaf then
		o.buildLeaf(L, pw, H, T)
	elseif style == "panel" then
		panelLeaf(L, pw, H, T, o)
	else
		plankLeaf(L, pw, H, T, o)
	end

	local hy = 3.3 - H / 2
	if not o.buildLeaf then
		for _, f in { -1, 1 } do
			local z = f * (T / 2)
			if style == "panel" then
				B.cyl(V(0.08, 0.36, 0.36), L(pw - 0.45, hy, z + f * 0.04) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, { name = "Rose", collide = false })
				B.ball(0.34, L(pw - 0.45, hy, z + f * 0.28).Position, C.brass, M.Metal, { name = "Knob", collide = false })
			else
				B.box(V(0.12, 1.0, 0.1), L(pw - 0.5, hy, z + f * 0.32), C.iron, M.Metal, { name = "Grip", collide = false })
				B.box(V(0.1, 0.1, 0.3), L(pw - 0.5, hy + 0.42, z + f * 0.17), C.iron, M.Metal, { name = "Standoff", collide = false })
				B.box(V(0.1, 0.1, 0.3), L(pw - 0.5, hy - 0.42, z + f * 0.17), C.iron, M.Metal, { name = "Standoff", collide = false })
			end
			if o.lockable then
				B.box(V(0.34, 0.66, 0.05), L(pw - 0.45, hy - 0.8, z + f * 0.025), C.brass, M.Metal, { name = "Escutcheon", collide = false })
				B.box(V(0.08, 0.22, 0.06), L(pw - 0.45, hy - 0.84, z + f * 0.04), C.soot, M.SmoothPlastic, { name = "Keyhole", collide = false })
				B.ball(0.12, L(pw - 0.45, hy - 0.7, z + f * 0.05).Position, C.soot, M.SmoothPlastic, { name = "Keyhole", collide = false })
			end
		end
		if o.knocker then
			B.box(V(0.6, 0.6, 0.06), L(pw / 2, H * 0.18, T / 2 + 0.03), C.brass, M.Metal, { name = "KnockerPlate", collide = false })
			B.cyl(V(0.12, 0.9, 0.9), L(pw / 2, H * 0.1, T / 2 + 0.12) * CFrame.Angles(0, math.pi / 2, 0), C.brass, M.Metal, { name = "Knocker", collide = false })
		end
	end

	if o.lockable then
		B.box(V(0.6, 0.2, 0.2), L(pw + 0.22, hy - 0.4, 0), C.brass, M.Metal, {
			name = "Bolt",
			collide = false,
			transparency = if o.locked then 0 else 1,
		})
	end
	B.pop()

	B.weldAll(hinge, leaf)

	local att = B.attach(hinge, CF(pw - 0.55, hy, 0), "PromptPoint")
	if o.lockable then
		B.prompt(att, {
			Name = "LockPrompt",
			ActionText = if o.locked then "Unlock" else "Lock",
			ObjectText = "",
			HoldDuration = 0.3,
			KeyboardKeyCode = Enum.KeyCode.E,
			MaxActivationDistance = 7.5,
		}, { Need = "Key" })
		if o.pickable then
			B.prompt(att, {
				Name = "PickPrompt",
				ActionText = "Pick Lock",
				ObjectText = "",
				HoldDuration = 3.5,
				KeyboardKeyCode = Enum.KeyCode.F,
				MaxActivationDistance = 6,
			}, { Need = "Hairpin", When = "Locked" })
		end
	end

	B.pop()
	return model, hinge, L, pw
end

-- Window set into a wall.
-- cf: centre of the opening on the wall centre plane, LookVector = outward.
function Kit.window(cf, w, h, wallT, o)
	o = o or {}
	local ex = -1 -- exterior is local -Z
	B.within(o.name or "Window", function()
		B.box(V(w + 0.1, h + 0.1, 0.12), cf, o.frosted and B.rgb(250, 244, 230) or C.glass, M.Glass, {
			name = "Glass",
			transparency = if o.frosted then 0.25 else 0.62,
			reflectance = 0.08,
			shadow = false,
		})
		local sash = o.sash or B.rgb(236, 222, 190)
		for _, s in { -1, 1 } do
			B.box(V(0.28, h, 0.32), cf * CF(s * (w / 2 - 0.14), 0, 0), sash, M.Wood, { name = "Stile" })
			B.box(V(w, 0.28, 0.32), cf * CF(0, s * (h / 2 - 0.14), 0), sash, M.Wood, { name = "Rail" })
		end
		local px, py = o.panesX or 2, o.panesY or 3
		for i = 1, px - 1 do
			B.box(V(0.12, h - 0.4, 0.2), cf * CF(-w / 2 + w * i / px, 0, 0), sash, M.Wood, { name = "Muntin", collide = false })
		end
		for j = 1, py - 1 do
			B.box(V(w - 0.4, 0.12, 0.2), cf * CF(0, -h / 2 + h * j / py, 0), sash, M.Wood, { name = "Muntin", collide = false })
		end
		local trim = o.trim or C.trim
		-- liners across the wall thickness
		for _, s in { -1, 1 } do
			B.box(V(0.15, h + 0.3, wallT), cf * CF(s * (w / 2 + 0.075), 0, 0), trim, M.Wood, { name = "Liner" })
			B.box(V(w + 0.3, 0.15, wallT), cf * CF(0, s * (h / 2 + 0.075), 0), trim, M.Wood, { name = "Liner" })
		end
		-- casings on both faces
		for _, f in { -1, 1 } do
			local z = f * (wallT / 2 + 0.08)
			for _, s in { -1, 1 } do
				B.box(V(0.5, h + 1.0, 0.16), cf * CF(s * (w / 2 + 0.4), 0, z), trim, M.Wood, { name = "Casing" })
			end
			B.box(V(w + 1.5, 0.6, 0.2), cf * CF(0, h / 2 + 0.45, z + f * 0.02), trim, M.Wood, { name = "HeadCasing" })
		end
		B.box(V(w + 1.9, 0.12, 0.5), cf * CF(0, h / 2 + 0.8, ex * (wallT / 2 + 0.25)), trim, M.Wood, { name = "Drip" })
		B.box(V(w + 1.4, 0.22, 0.95), cf * CF(0, -h / 2 - 0.2, ex * (wallT / 2 + 0.32)), trim, M.Wood, { name = "Sill" })
		B.box(V(w + 1.2, 0.2, 0.75), cf * CF(0, -h / 2 - 0.2, -ex * (wallT / 2 + 0.25)), trim, M.Wood, { name = "Stool" })
		B.box(V(w + 0.9, 0.5, 0.14), cf * CF(0, -h / 2 - 0.55, -ex * (wallT / 2 + 0.07)), trim, M.Wood, { name = "Apron" })

		if o.shutters then
			local sc = o.shutterColor or B.rgb(54, 82, 60)
			local sw = w * 0.5
			for _, s in { -1, 1 } do
				local x = s * (w / 2 + 0.7 + sw / 2)
				local z = ex * (wallT / 2 + 0.14)
				for k = 0, 2 do
					B.box(V(sw / 3 - 0.04, h + 0.5, 0.14), cf * CF(x - sw / 2 + sw / 6 + k * sw / 3, 0, z), B.vary(sc, 0.06), M.Wood, { name = "Shutter" })
				end
				for _, y in { -h * 0.32, h * 0.32 } do
					B.box(V(sw, 0.35, 0.1), cf * CF(x, y, z + ex * 0.1), B.vary(sc, 0.04), M.Wood, { name = "ShutterBatten", collide = false })
				end
				-- little pine cut-out painted dark
				B.wedge(V(0.1, 0.5, 0.35), cf * CF(x, h * 0.05, z + ex * 0.075) * CFrame.Angles(0, math.pi / 2, 0), B.rgb(30, 40, 30), M.SmoothPlastic, { name = "Cutout", collide = false })
			end
		end

		if o.flowerBox then
			local fz = ex * (wallT / 2 + 0.85)
			local fy = -h / 2 - 0.85
			B.box(V(w + 0.8, 0.95, 1.05), cf * CF(0, fy, fz), B.rgb(120, 74, 40), M.WoodPlanks, { name = "FlowerBox" })
			B.box(V(w + 0.6, 0.12, 0.85), cf * CF(0, fy + 0.45, fz), C.dirt, M.Ground, { name = "Soil", collide = false })
			local cols = { B.rgb(220, 60, 50), B.rgb(255, 200, 40), B.rgb(250, 240, 220), B.rgb(170, 90, 200), B.rgb(255, 140, 40) }
			local n = math.floor(w * 2.2)
			for i = 1, n do
				local x = -w / 2 + (i - 0.5) * (w / n)
				local zz = fz + B.range(-0.25, 0.25)
				B.ball(B.range(0.45, 0.7), (cf * CF(x, fy + 0.7, zz)).Position, B.vary(B.rgb(70, 120, 50), 0.15), M.Grass, { name = "Leaves", collide = false, shadow = false })
				B.ball(B.range(0.3, 0.45), (cf * CF(x + B.range(-0.15, 0.15), fy + 1.05 + B.range(0, 0.25), zz)).Position, B.pick(cols), M.SmoothPlastic, { name = "Bloom", collide = false, shadow = false })
			end
		end

		if o.curtains then
			local z = -ex * (wallT / 2 + 0.5)
			local top = h / 2 + 1.0
			B.rod((cf * CF(-w / 2 - 1.4, top, z)).Position, (cf * CF(w / 2 + 1.4, top, z)).Position, 0.12, C.brass, M.Metal, { name = "CurtainRod", collide = false })
			for _, s in { -1, 1 } do
				B.ball(0.3, (cf * CF(s * (w / 2 + 1.5), top, z)).Position, C.brass, M.Metal, { name = "Finial", collide = false })
				for k = 0, 3 do
					local x = s * (w / 2 - 0.2 + k * 0.38)
					local dz = (k % 2 == 0) and 0.08 or -0.06
					B.box(V(0.42, h + 2.2, 0.12), cf * CF(x, -0.2, z + dz), B.vary(o.curtains, 0.05), M.Fabric, { name = "Curtain", collide = false })
				end
			end
		end

		if o.shaft then
			local anchor = B.box(V(0.2, 0.2, 0.2), cf * CF(0, 0, -ex * (wallT / 2 + 0.2)), C.warm, M.SmoothPlastic, {
				name = "ShaftAnchor",
				transparency = 1,
				collide = false,
				shadow = false,
				query = false,
			})
			local a0 = B.attach(anchor, CF(), "A0")
			local a1 = B.attach(anchor, CF(0, -o.shaft.drop, -ex * o.shaft.reach), "A1")
			local beam = Instance.new("Beam")
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = w * 0.9
			beam.Width1 = w * 1.5
			beam.FaceCamera = true
			beam.LightEmission = 0.8
			beam.LightInfluence = 0
			beam.Segments = 1
			beam.Color = B.roblox.ColorSequence.new(B.rgb(255, 214, 140))
			beam.Transparency = B.roblox.NumberSequence.new({
				B.roblox.NumberSequenceKeypoint.new(0, 0.86),
				B.roblox.NumberSequenceKeypoint.new(0.7, 0.93),
				B.roblox.NumberSequenceKeypoint.new(1, 1),
			})
			beam.Parent = anchor
		end
	end)
end

-- Solid stair run. start = bottom-front centre of the first step at floor height,
-- dir = horizontal unit direction of travel, each step rises `rise` (negative to descend).
function Kit.stairs(start, dir, width, rise, tread, count, baseY, color)
	local right = dir:Cross(V(0, 1, 0)).Unit
	local look = CFrame.lookAt(V(0, 0, 0), dir)
	B.within("Stairs", function()
		for k = 1, count do
			local topY = start.Y + rise * k
			local along = (k - 0.5) * tread
			local c = start + dir * along
			local bottom = math.min(baseY, topY)
			local hgt = math.abs(topY - bottom)
			if hgt > 0.05 then
				local cf = CFrame.new(c.X, bottom + hgt / 2, c.Z) * look.Rotation
				B.box(V(width, hgt, tread), cf, B.vary(color or C.floorDark, 0.04), M.Wood, { name = "Step" })
			end
			-- nosing overhangs toward the lower step
			local tcf = CFrame.new(c.X, topY - 0.08, c.Z) * look.Rotation * CF(0, 0, if rise > 0 then 0.12 else -0.12)
			B.box(V(width + 0.2, 0.22, tread + 0.25), tcf, B.vary(C.floor, 0.06), M.WoodPlanks, { name = "Tread", collide = false })
		end
	end)
	return right
end

-- Balustrade between two floor points: handrail at railH above, balusters spaced ~0.8.
function Kit.railing(p0, p1, railH, o)
	o = o or {}
	local col = o.color or C.trim
	B.within("Railing", function()
		local top0, top1 = p0 + V(0, railH, 0), p1 + V(0, railH, 0)
		B.between(top0, top1, 0.45, 0.32, col, M.Wood, { name = "Handrail" })
		if not o.noBottom then
			B.between(p0 + V(0, 0.35, 0), p1 + V(0, 0.35, 0), 0.32, 0.25, col, M.Wood, { name = "BottomRail" })
		end
		local len = (p1 - p0).Magnitude
		local n = math.max(1, math.floor(len / (o.spacing or 0.8)))
		for i = 1, n - 1 do
			local t = i / n
			local b = p0:Lerp(p1, t)
			local logStyle = o.log
			if logStyle then
				B.rod(b + V(0, 0.4, 0), b + V(0, railH, 0), 0.32, B.vary(C.log, 0.08), M.Wood, { name = "Baluster" })
			else
				B.box(V(0.22, railH - 0.4, 0.22), CFrame.new(b + V(0, 0.4 + (railH - 0.4) / 2, 0)), col, M.Wood, { name = "Baluster" })
			end
		end
		if not o.noPosts then
			for _, p in { p0, p1 } do
				B.box(V(0.6, railH + 0.4, 0.6), CFrame.new(p + V(0, (railH + 0.4) / 2, 0)), col, M.Wood, { name = "Newel" })
				B.box(V(0.75, 0.2, 0.75), CFrame.new(p + V(0, railH + 0.5, 0)), col, M.Wood, { name = "NewelCap" })
			end
		end
	end)
end

-- Railing that follows a stair run: bottom/top are floor points at each end of the flight.
function Kit.stairRail(bottom, top, railH, o)
	o = o or {}
	local col = o.color or C.trim
	B.within("StairRail", function()
		B.between(bottom + V(0, railH, 0), top + V(0, railH, 0), 0.45, 0.32, col, M.Wood, { name = "Handrail" })
		local len = (top - bottom).Magnitude
		local n = math.max(2, math.floor(len / 1.1))
		for i = 1, n - 1 do
			local b = bottom:Lerp(top, i / n)
			B.box(V(0.22, railH, 0.22), CFrame.new(b + V(0, railH / 2, 0)), col, M.Wood, { name = "Baluster" })
		end
		for _, p in { bottom, top } do
			B.box(V(0.7, railH + 0.6, 0.7), CFrame.new(p + V(0, (railH + 0.6) / 2, 0)), col, M.Wood, { name = "Newel" })
			B.ball(0.8, p + V(0, railH + 0.75, 0), col, M.Wood, { name = "NewelBall" })
		end
	end)
end

return Kit
