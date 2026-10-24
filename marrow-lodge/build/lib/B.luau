-- Geometry helpers for baking the lodge with Lune.
-- Everything here runs offline (lune run build/bake.luau), never inside Roblox.

local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local B = {}

B.roblox = roblox
B.Instance = Instance
B.Vector3 = Vector3
B.CFrame = CFrame
B.Color3 = Color3
B.Enum = Enum
B.M = Enum.Material
B.V = Vector3.new
B.CF = CFrame.new

B.parent = nil
local stack = {}

function B.push(p)
	table.insert(stack, B.parent)
	B.parent = p
	return p
end

function B.pop()
	B.parent = table.remove(stack)
end

-- Creates a container under the current parent and runs fn with it as the parent.
function B.within(name, fn, className)
	local m = Instance.new(className or "Model")
	m.Name = name
	m.Parent = B.parent
	B.push(m)
	fn(m)
	B.pop()
	return m
end

function B.folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or B.parent
	return f
end

---------------------------------------------------------------- random

local seed = 1931
function B.seed(s)
	seed = s
end
function B.rand()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
function B.range(a, b)
	return a + (b - a) * B.rand()
end
function B.pick(t)
	return t[math.floor(B.rand() * #t) + 1]
end

---------------------------------------------------------------- colour

function B.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

function B.vary(c, amt)
	local k = 1 + (B.rand() * 2 - 1) * amt
	return Color3.new(math.clamp(c.R * k, 0, 1), math.clamp(c.G * k, 0, 1), math.clamp(c.B * k, 0, 1))
end

function B.mix(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- Palette shared by every builder module.
B.C = {
	log = Color3.fromRGB(168, 108, 58),
	logDark = Color3.fromRGB(122, 76, 40),
	chink = Color3.fromRGB(226, 208, 170),
	floor = Color3.fromRGB(150, 96, 52),
	floorDark = Color3.fromRGB(112, 70, 38),
	plank = Color3.fromRGB(196, 146, 90),
	trim = Color3.fromRGB(104, 64, 34),
	beam = Color3.fromRGB(92, 56, 30),
	stone = Color3.fromRGB(150, 138, 122),
	stoneDark = Color3.fromRGB(104, 96, 88),
	roof = Color3.fromRGB(96, 60, 44),
	brass = Color3.fromRGB(214, 172, 74),
	iron = Color3.fromRGB(44, 40, 38),
	glass = Color3.fromRGB(255, 236, 200),
	warm = Color3.fromRGB(255, 196, 112),
	flame = Color3.fromRGB(255, 170, 60),
	cream = Color3.fromRGB(240, 226, 196),
	red = Color3.fromRGB(150, 46, 36),
	mustard = Color3.fromRGB(214, 160, 52),
	green = Color3.fromRGB(62, 92, 54),
	navy = Color3.fromRGB(46, 58, 86),
	paper = Color3.fromRGB(236, 222, 186),
	soot = Color3.fromRGB(30, 28, 27),
	grass = Color3.fromRGB(122, 148, 62),
	dirt = Color3.fromRGB(120, 88, 58),
}

---------------------------------------------------------------- parts

local function finish(p, color, material, o)
	o = o or {}
	p.Anchored = if o.anchored == nil then true else o.anchored
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color or Color3.fromRGB(200, 200, 200)
	p.Material = material or Enum.Material.SmoothPlastic
	if o.name then
		p.Name = o.name
	end
	if o.transparency then
		p.Transparency = o.transparency
	end
	if o.reflectance then
		p.Reflectance = o.reflectance
	end
	p.CanCollide = if o.collide == nil then true else o.collide
	p.CastShadow = if o.shadow == nil then true else o.shadow
	p.CanTouch = o.touch or false
	if o.query == false then
		p.CanQuery = false
	end
	if o.massless then
		p.Massless = true
	end
	if o.attrs then
		for k, v in o.attrs do
			p:SetAttribute(k, v)
		end
	end
	p.Parent = o.parent or B.parent
	return p
end

function B.box(size, cf, color, material, o)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	return finish(p, color, material, o)
end

-- Cylinder: axis runs along the part's X axis (size.X = length).
function B.cyl(size, cf, color, material, o)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = size
	p.CFrame = cf
	return finish(p, color, material, o)
end

-- Vertical cylinder (axis along world Y) standing on its centre point.
function B.vcyl(height, diameter, pos, color, material, o)
	return B.cyl(Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, o)
end

function B.ball(d, pos, color, material, o)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(d, d, d)
	p.CFrame = if typeof(pos) == "CFrame" then pos else CFrame.new(pos)
	return finish(p, color, material, o)
end

-- WedgePart: vertical face at +Z (back), slope faces -Z (front) and drops to the front-bottom edge.
function B.wedge(size, cf, color, material, o)
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	return finish(p, color, material, o)
end

local function frameAlong(p0, p1, up)
	local dir = p1 - p0
	local mid = p0 + dir * 0.5
	local unit = dir.Unit
	up = up or Vector3.new(0, 1, 0)
	if math.abs(unit:Dot(up.Unit)) > 0.985 then
		up = Vector3.new(1, 0, 0)
		if math.abs(unit:Dot(up)) > 0.985 then
			up = Vector3.new(0, 0, 1)
		end
	end
	return CFrame.lookAt(mid, p1, up), dir.Magnitude
end

-- Box stretched from p0 to p1 (length along local Z), w across, t thick.
function B.between(p0, p1, w, t, color, material, o, up)
	local cf, len = frameAlong(p0, p1, up)
	return B.box(Vector3.new(w, t, len), cf, color, material, o)
end

-- Cylinder stretched from p0 to p1.
function B.rod(p0, p1, d, color, material, o)
	local cf, len = frameAlong(p0, p1)
	return B.cyl(Vector3.new(len, d, d), cf * CFrame.Angles(0, math.pi / 2, 0), color, material, o)
end

-- Two wedges back to back: a triangular prism with its ridge along local Z.
-- cf sits at the centre of the base; w = base width, h = height, len = ridge length.
function B.tent(cf, w, h, len, color, material, o)
	-- Each wedge's tall (+Z) edge must face the ridge in the middle.
	local a = B.wedge(Vector3.new(len, h, w / 2), cf * CFrame.new(-w / 4, h / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), color, material, o)
	local b = B.wedge(Vector3.new(len, h, w / 2), cf * CFrame.new(w / 4, h / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), color, material, o)
	return a, b
end

---------------------------------------------------------------- lights, fx, prompts

function B.light(parent, className, props)
	local l = Instance.new(className or "PointLight")
	for k, v in props or {} do
		l[k] = v
	end
	l.Parent = parent
	return l
end

function B.warmLight(parent, range, brightness, shadows, color)
	return B.light(parent, "PointLight", {
		Range = range or 16,
		Brightness = brightness or 1,
		Color = color or B.C.warm,
		Shadows = shadows or false,
	})
end

function B.attach(part, localCF, name)
	local a = Instance.new("Attachment")
	a.Name = name or "Attachment"
	a.CFrame = localCF or CFrame.new()
	a.Parent = part
	return a
end

function B.prompt(parent, props, attrs)
	local p = Instance.new("ProximityPrompt")
	p.RequiresLineOfSight = false
	p.MaxActivationDistance = 8
	p.HoldDuration = 0.25
	for k, v in props or {} do
		p[k] = v
	end
	for k, v in attrs or {} do
		p:SetAttribute(k, v)
	end
	p.Parent = parent
	return p
end

-- Rigid joint that keeps p1 where it is relative to p0. Part1 must be unanchored to follow.
function B.weld(p0, p1)
	local w = Instance.new("Weld")
	w.Name = "Weld_" .. p1.Name
	w.Part0 = p0
	w.Part1 = p1
	w.C0 = p0.CFrame:Inverse() * p1.CFrame
	w.C1 = CFrame.new()
	w.Parent = p1
	return w
end

-- Welds every BasePart under `root` to `anchor` and unanchors them.
function B.weldAll(anchor, root)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d ~= anchor then
			d.Anchored = false
			B.weld(anchor, d)
		end
	end
end

function B.surfaceText(part, face, text, props)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = (props and props.ppS) or 60
	sg.LightInfluence = 1
	sg.Parent = part
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = roblox.UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.TextWrapped = true
	t.FontFace = roblox.Font.fromEnum((props and props.font) or Enum.Font.Fondamento)
	t.TextColor3 = (props and props.color) or Color3.fromRGB(40, 28, 20)
	t.Parent = sg
	return sg, t
end

---------------------------------------------------------------- rectangles

-- Subtract hole {u0,u1,v0,v1} from rect, returning the leftover pieces.
local function subtract(r, h)
	if h[1] >= r[2] or h[2] <= r[1] or h[3] >= r[4] or h[4] <= r[3] then
		return { r }
	end
	local out = {}
	local function add(u0, u1, v0, v1)
		if u1 - u0 > 0.02 and v1 - v0 > 0.02 then
			table.insert(out, { u0, u1, v0, v1 })
		end
	end
	add(r[1], h[1], r[3], r[4])
	add(h[2], r[2], r[3], r[4])
	local a, b = math.max(r[1], h[1]), math.min(r[2], h[2])
	add(a, b, r[3], h[3])
	add(a, b, h[4], r[4])
	return out
end

function B.rectsMinus(rect, holes)
	local rects = { rect }
	for _, h in holes or {} do
		local nextRects = {}
		for _, r in rects do
			for _, piece in subtract(r, h) do
				table.insert(nextRects, piece)
			end
		end
		rects = nextRects
	end
	return rects
end

-- Free intervals of [a,b] after removing the given [x0,x1] intervals.
function B.intervalsMinus(a, b, cuts)
	table.sort(cuts, function(p, q)
		return p[1] < q[1]
	end)
	local out = {}
	local cur = a
	for _, c in cuts do
		if c[2] > cur and c[1] < b then
			if c[1] > cur + 0.05 then
				table.insert(out, { cur, math.min(c[1], b) })
			end
			cur = math.max(cur, c[2])
		end
	end
	if b > cur + 0.05 then
		table.insert(out, { cur, b })
	end
	return out
end

---------------------------------------------------------------- walls

-- Flat wall. axis "x": runs along X at z = c. axis "z": runs along Z at x = c.
-- u = coordinate along the wall, v = world Y. holes = {{u0,u1,v0,v1}, ...}
function B.flatWall(axis, c, u0, u1, v0, v1, t, holes, color, material, o)
	local parts = {}
	for _, r in B.rectsMinus({ u0, u1, v0, v1 }, holes) do
		local du, dv = r[2] - r[1], r[4] - r[3]
		local uc, vc = (r[1] + r[2]) / 2, (r[3] + r[4]) / 2
		local p
		if axis == "x" then
			p = B.box(Vector3.new(du, dv, t), CFrame.new(uc, vc, c), color, material, o)
		else
			p = B.box(Vector3.new(t, dv, du), CFrame.new(c, vc, uc), color, material, o)
		end
		table.insert(parts, p)
	end
	return parts
end

-- Stacked round logs with plaster chinking behind them.
-- opts.limit(vCentre) -> (uMin, uMax) narrows rows (used for gable ends).
function B.logWall(axis, c, u0, u1, v0, v1, d, holes, opts)
	opts = opts or {}
	local rows = math.floor((v1 - v0) / d + 0.001)
	for i = 0, rows - 1 do
		local y = v0 + i * d
		local yc = y + d / 2
		local a, b = u0, u1
		if opts.limit then
			local la, lb = opts.limit(yc)
			if not la then
				continue
			end
			a, b = math.max(a, la), math.min(b, lb)
			if b - a < 0.6 then
				continue
			end
		end
		local cuts = {}
		for _, h in holes or {} do
			if h[3] < y + d - 0.05 and h[4] > y + 0.05 then
				table.insert(cuts, { h[1], h[2] })
			end
		end
		for _, seg in B.intervalsMinus(a, b, cuts) do
			local len = seg[2] - seg[1]
			local uc = (seg[1] + seg[2]) / 2
			local col = B.vary(opts.color or B.C.log, 0.09)
			local cf
			if axis == "x" then
				cf = CFrame.new(uc, yc, c)
			else
				cf = CFrame.new(c, yc, uc) * CFrame.Angles(0, math.pi / 2, 0)
			end
			B.cyl(Vector3.new(len, d, d), cf, col, Enum.Material.Wood, { name = "Log" })
		end
	end
	if opts.chink ~= false and not opts.limit then
		local ca, cb = opts.chinkFrom or u0, opts.chinkTo or u1
		B.flatWall(axis, c, ca, cb, v0, v0 + rows * d, d * 0.62, holes, B.C.chink, Enum.Material.Plaster, { name = "Chinking" })
	end
end

return B
