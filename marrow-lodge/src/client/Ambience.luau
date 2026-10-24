-- Candle and fire flicker, the odd lamp that dims for a moment, and an optional
-- ambient sound bed.

local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LodgeConfig"))

local Ambience = {}

local flames = {} -- { light, base, seed, strength }
local bulbs = {} -- { light, base, part }

local function collect()
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Flicker") then
			local light = d:FindFirstChildWhichIsA("Light")
			local isFire = d:GetAttribute("FireLight") == true
			local isBulb = d.Name == "Bulb" or d.Name == "AtticGlow"
			if light then
				if isBulb then
					table.insert(bulbs, { light = light, base = light.Brightness, part = d })
				else
					table.insert(flames, { light = light, base = light.Brightness, seed = math.random() * 100, strength = if isFire then 0.28 else 0.12 })
				end
			elseif d.Name == "AtticGlow" then
				table.insert(bulbs, { part = d, baseT = d.Transparency })
			end
		end
	end
end

function Ambience.start()
	collect()
	local t = 0
	local acc = 0
	local nextDip = os.clock() + math.random(18, 40)
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		acc += dt
		if acc < 1 / 20 then
			return
		end
		acc = 0
		for _, f in flames do
			local n = math.noise(t * 6, f.seed) + 0.5 * math.noise(t * 17, f.seed + 9)
			f.light.Brightness = f.base * (1 + n * f.strength)
		end
		if os.clock() > nextDip and #bulbs > 0 then
			nextDip = os.clock() + math.random(20, 55)
			local b = bulbs[math.random(1, #bulbs)]
			task.spawn(function()
				for _ = 1, math.random(2, 4) do
					if b.light then
						b.light.Brightness = b.base * 0.15
					end
					if b.baseT then
						b.part.Transparency = 0.85
					end
					task.wait(0.05 + math.random() * 0.08)
					if b.light then
						b.light.Brightness = b.base
					end
					if b.baseT then
						b.part.Transparency = b.baseT
					end
					task.wait(0.05 + math.random() * 0.15)
				end
			end)
		end
	end)

	if Config.Sounds.Ambience ~= "" then
		local s = Instance.new("Sound")
		s.Name = "Ambience"
		s.SoundId = Config.Sounds.Ambience
		s.Looped = true
		s.Volume = 0.35
		s.Parent = SoundService
		s:Play()
	end
end

return Ambience
