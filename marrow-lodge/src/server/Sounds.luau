-- Sounds that live in the world: the fires crackle, and the hall clock ticks
-- even though its hands never move.

local Sounds = {}

local function loop(parent, id, volume, maxDistance)
	if not id or id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.Name = "Loop"
	s.SoundId = id
	s.Looped = true
	s.Volume = volume
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 6
	s.RollOffMaxDistance = maxDistance
	s.Parent = parent
	s:Play()
end

function Sounds.start(config)
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("FireLight") then
				loop(d, config.Sounds.Fire, 0.6, 50)
			elseif d:GetAttribute("Ticking") then
				loop(d, config.Sounds.ClockTick, 0.35, 32)
			end
		end
	end
end

return Sounds
