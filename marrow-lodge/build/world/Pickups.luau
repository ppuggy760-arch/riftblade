-- Things lying around that a player can take: hairpins and the pry bar.
-- The server turns each "Pickup" model into a working item spot.

local B = require("../lib/B")

local V, CF = B.V, B.CF
local M, C = B.M, B.C
local CFrame = B.CFrame
local Instance = B.Instance
local Enum = B.Enum

local Pickups = {}

local function spot(kind, objectText, respawn, cf, build)
	local m = Instance.new("Model")
	m.Name = kind .. "Spot"
	m:SetAttribute("Pickup", kind)
	m:SetAttribute("Respawn", respawn)
	m.Parent = B.parent
	B.push(m)
	local main = build(cf)
	B.pop()
	m.PrimaryPart = main
	B.prompt(main, {
		Name = "TakePrompt",
		ActionText = "Take",
		ObjectText = objectText,
		HoldDuration = 0.2,
		MaxActivationDistance = 6.5,
		KeyboardKeyCode = Enum.KeyCode.E,
	})
	return m
end

-- cf: lying on a surface.
function Pickups.hairpin(cf)
	return spot("Hairpin", "Hairpin", 75, cf, function(c)
		local dark = B.rgb(40, 34, 30)
		local main = B.box(V(0.05, 0.03, 0.62), c * CF(0, 0.02, 0), dark, M.Metal, { name = "Pin", collide = false })
		B.box(V(0.05, 0.03, 0.55), c * CF(0.09, 0.02, 0.035) * CFrame.Angles(0, math.rad(4), 0), dark, M.Metal, { name = "Pin", collide = false })
		B.ball(0.07, (c * CF(0.045, 0.02, -0.31)).Position, dark, M.Metal, { name = "Bend", collide = false })
		-- a little enamel flower so it can be spotted
		B.ball(0.14, (c * CF(0.045, 0.05, 0.22)).Position, B.rgb(240, 200, 60), M.SmoothPlastic, { name = "Bead", collide = false })
		return main
	end)
end

function Pickups.prybar(cf)
	return spot("Crowbar", "Pry Bar", 0, cf, function(c)
		local iron = B.rgb(70, 40, 34)
		local main = B.cyl(V(3.6, 0.22, 0.22), c * CF(0, 0.12, 0), iron, M.Metal, { name = "Bar", collide = false })
		B.cyl(V(0.7, 0.22, 0.22), c * CF(2.0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(40)), iron, M.Metal, { name = "Hook", collide = false })
		B.box(V(0.35, 0.08, 0.26), c * CF(-1.85, 0.12, 0), iron, M.Metal, { name = "Claw", collide = false })
		B.box(V(0.6, 0.06, 0.08), c * CF(2.3, 0.62, 0), iron, M.Metal, { name = "Tip", collide = false })
		return main
	end)
end

return Pickups
