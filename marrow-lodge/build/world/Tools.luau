-- Held items, stored in ServerStorage and handed out by the server.

local B = require("../lib/B")

local V, CF = B.V, B.CF
local M = B.M
local CFrame = B.CFrame
local Instance = B.Instance

local Tools = {}

local function newTool(name, item, droppable)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = droppable
	tool.RequiresHandle = true
	tool.ToolTip = ""
	tool:SetAttribute("LodgeItem", item)
	return tool
end

local function finishTool(tool, handle)
	for _, d in tool:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = d == handle
			d.Massless = true
			if d ~= handle then
				B.weld(handle, d)
			end
		end
	end
end

-- A skeleton key. The shank runs along +Y so it points forward from the hand.
local function key(name, color, master)
	local tool = newTool(name, "Key", not master)
	tool:SetAttribute("Master", master)
	B.push(tool)
	local o = { reflectance = if master then 0.08 else 0.22 }
	local handle = B.cyl(V(0.14, 0.62, 0.62), CFrame.new(0, 0, 0), color, M.Metal, { name = "Handle", reflectance = o.reflectance })
	B.cyl(V(0.16, 0.28, 0.28), CFrame.new(0, 0, 0), B.rgb(30, 24, 18), M.SmoothPlastic, { name = "Eye" })
	B.rod(V(0, 0.28, 0), V(0, 1.45, 0), 0.13, color, M.Metal, { name = "Shank", reflectance = o.reflectance })
	B.cyl(V(0.2, 0.24, 0.24), CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.pi / 2), color, M.Metal, { name = "Collar" })
	B.box(V(0.1, 0.34, 0.3), CFrame.new(0, 1.28, 0.18), color, M.Metal, { name = "Bit" })
	B.box(V(0.1, 0.1, 0.12), CFrame.new(0, 1.2, 0.36), color, M.Metal, { name = "Ward" })
	if master then
		-- the cord it hangs from
		local pts = { V(0, -0.1, 0), V(0, -0.9, 0.35), V(0, -1.1, -0.1), V(0, -0.1, 0) }
		for i = 1, #pts - 1 do
			B.rod(pts[i], pts[i + 1], 0.05, B.rgb(40, 30, 26), M.Fabric, { name = "Cord" })
		end
	end
	B.pop()
	tool.Grip = CFrame.new(0, 0.15, 0)
	finishTool(tool, handle)
	return tool
end

function Tools.build(parent)
	local f = Instance.new("Folder")
	f.Name = "LodgeItems"
	f.Parent = parent

	key("Old Key", B.rgb(184, 140, 58), true).Parent = f
	key("Key", B.rgb(232, 194, 96), false).Parent = f

	local pin = newTool("Hairpin", "Hairpin", true)
	B.push(pin)
	local ph = B.box(V(0.06, 0.75, 0.06), CFrame.new(0, 0, 0), B.rgb(40, 34, 30), M.Metal, { name = "Handle" })
	B.box(V(0.06, 0.68, 0.06), CFrame.new(0.1, 0.03, 0) * CFrame.Angles(0, 0, math.rad(-4)), B.rgb(40, 34, 30), M.Metal, { name = "Leg" })
	B.ball(0.16, V(0.05, -0.32, 0), B.rgb(240, 200, 60), M.SmoothPlastic, { name = "Bead" })
	B.pop()
	pin.Grip = CFrame.new(0, -0.2, 0)
	finishTool(pin, ph)
	pin.Parent = f

	local bar = newTool("Pry Bar", "Crowbar", true)
	B.push(bar)
	local iron = B.rgb(70, 40, 34)
	local bh = B.cyl(V(3.6, 0.22, 0.22), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.pi / 2), iron, M.Metal, { name = "Handle" })
	B.rod(V(0, 1.75, 0), V(0, 2.2, 0.45), 0.22, iron, M.Metal, { name = "Hook" })
	B.box(V(0.26, 0.08, 0.5), CFrame.new(0, 2.25, 0.62), iron, M.Metal, { name = "Tip" })
	B.box(V(0.3, 0.35, 0.08), CFrame.new(0, -1.85, 0.06), iron, M.Metal, { name = "Claw" })
	B.pop()
	bar.Grip = CFrame.new(0, -1.1, 0)
	finishTool(bar, bh)
	bar.Parent = f

	return f
end

return Tools
