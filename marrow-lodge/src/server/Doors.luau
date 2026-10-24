-- Every door in the lodge: swings open on its left hinge when someone walks into it,
-- closes behind them, and can be locked or unlocked by whoever carries a key.
-- A lock stays exactly as it was left until somebody changes it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Doors = {}

local doors = {} -- list of states
local byId = {}
local config

local OPEN_INFO = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local function playSound(parent, id, volume, speed)
	if not id or id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 70
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 6)
end

-- Returns the tool if the player is carrying (holding or in their backpack) an item of that kind.
function Doors.findItem(player, item, filter)
	local places = { player.Character, player:FindFirstChildOfClass("Backpack") }
	for _, place in places do
		if place then
			for _, t in place:GetChildren() do
				if t:IsA("Tool") and t:GetAttribute("LodgeItem") == item and (not filter or filter(t)) then
					return t
				end
			end
		end
	end
	return nil
end

local function rootOf(player)
	local ch = player.Character
	if not ch then
		return nil
	end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then
		return nil
	end
	return ch:FindFirstChild("HumanoidRootPart")
end

local function setLocked(state, locked)
	state.locked = locked
	state.model:SetAttribute("Locked", locked)
	if state.lockPrompt then
		state.lockPrompt.ActionText = if locked then "Unlock" else "Lock"
	end
	local bolt = state.model:FindFirstChild("Bolt", true)
	if bolt then
		bolt.Transparency = if locked then 0 else 1
	end
	playSound(state.hinge, if locked then config.Sounds.Lock else config.Sounds.Unlock, 0.6, if locked then 0.8 else 1.0)
end

local function tweenTo(state, cf, info)
	if state.tween then
		state.tween:Cancel()
	end
	local t = TweenService:Create(state.hinge, info, { CFrame = cf })
	state.tween = t
	t:Play()
	return t
end

-- Picks the swing direction that carries the free edge away from `from`.
local function swingSign(state, from)
	if state.swingDir ~= 0 or not from then
		return if state.swingDir ~= 0 then state.swingDir else 1
	end
	local best, bestDist = 1, -math.huge
	for _, s in { 1, -1 } do
		local latch = (state.closedCF * CFrame.Angles(0, s * math.rad(30), 0)) * Vector3.new(state.width, 0, 0)
		local d = (latch - from).Magnitude
		if d > bestDist then
			best, bestDist = s, d
		end
	end
	return best
end

function Doors.open(state, from)
	if state.locked or state.pendingLock then
		return false
	end
	if state.open and not state.closing then
		state.lastNear = os.clock()
		return true
	end
	local sign = swingSign(state, from)
	state.open = true
	state.closing = false
	state.lastNear = os.clock()
	tweenTo(state, state.closedCF * CFrame.Angles(0, sign * math.rad(state.openAngle), 0), OPEN_INFO)
	playSound(state.hinge, config.Sounds.DoorOpen, 0.45, 0.9 + math.random() * 0.2)
	return true
end

function Doors.close(state, after)
	if not state.open then
		if after then
			after()
		end
		return
	end
	state.closing = true
	local t = tweenTo(state, state.closedCF, CLOSE_INFO)
	playSound(state.hinge, config.Sounds.DoorClose, 0.45, 0.9 + math.random() * 0.2)
	t.Completed:Connect(function(status)
		if status == Enum.PlaybackState.Completed then
			state.open = false
			state.closing = false
			if after then
				after()
			end
		end
	end)
end

local function rattle(state)
	state.rattleAt = os.clock()
	local t = TweenService:Create(state.hinge, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 3, true), {
		CFrame = state.closedCF * CFrame.Angles(0, math.rad(1.2), 0),
	})
	t:Play()
	t.Completed:Connect(function()
		if not state.open then
			state.hinge.CFrame = state.closedCF
		end
	end)
	playSound(state.hinge, config.Sounds.Rattle, 0.5, 0.55)
	task.delay(0.12, function()
		playSound(state.hinge, config.Sounds.Rattle, 0.4, 0.5)
	end)
end

local function onLockPrompt(state, player)
	if not Doors.findItem(player, "Key") then
		return
	end
	if state.locked then
		setLocked(state, false)
		return
	end
	if state.open then
		state.pendingLock = true
		Doors.close(state, function()
			state.pendingLock = false
			setLocked(state, true)
		end)
	else
		setLocked(state, true)
	end
end

local function onPickPrompt(state, player)
	if not state.locked or not state.pickable then
		return
	end
	local pin = Doors.findItem(player, "Hairpin")
	if not pin then
		return
	end
	pin:Destroy()
	setLocked(state, false)
end

local function register(model)
	local hinge = model:FindFirstChild("Hinge")
	if not hinge then
		return
	end
	local state = {
		model = model,
		id = model:GetAttribute("DoorId") or model.Name,
		hinge = hinge,
		closedCF = hinge.CFrame,
		width = model:GetAttribute("Width") or 4,
		height = model:GetAttribute("Height") or 8,
		locked = model:GetAttribute("Locked") == true,
		lockable = model:GetAttribute("Lockable") == true,
		pickable = model:GetAttribute("Pickable") == true,
		proximity = model:GetAttribute("Proximity") ~= false,
		autoClose = model:GetAttribute("AutoClose") or config.DoorCloseDelay,
		swingDir = model:GetAttribute("SwingDir") or 0,
		openAngle = model:GetAttribute("OpenAngle") or 96,
		open = false,
		closing = false,
		pendingLock = false,
		lastNear = 0,
		rattleAt = 0,
	}
	state.centreCF = state.closedCF * CFrame.new(state.width / 2, 0, 0)
	state.lockPrompt = model:FindFirstChild("LockPrompt", true)
	local pick = model:FindFirstChild("PickPrompt", true)
	if state.lockPrompt then
		state.lockPrompt.Triggered:Connect(function(player)
			onLockPrompt(state, player)
		end)
	end
	if pick then
		pick.Triggered:Connect(function(player)
			onPickPrompt(state, player)
		end)
	end
	table.insert(doors, state)
	byId[state.id] = state
end

function Doors.get(id)
	return byId[id]
end

local function step()
	local now = os.clock()
	local roots = {}
	for _, p in Players:GetPlayers() do
		local r = rootOf(p)
		if r then
			table.insert(roots, r.Position)
		end
	end
	for _, state in doors do
		local pushing, pusher, near = false, nil, false
		local hw, hh = state.width / 2, state.height / 2
		for _, pos in roots do
			local lp = state.centreCF:PointToObjectSpace(pos)
			if math.abs(lp.Y) < hh + 3 then
				if math.abs(lp.X) < hw + 0.5 and math.abs(lp.Z) < 2.6 then
					pushing, pusher = true, pos
				end
				if math.abs(lp.X) < hw + 2 and math.abs(lp.Z) < state.width + 1.5 then
					near = true
				end
			end
		end
		if state.proximity and pushing then
			if state.locked then
				if now - state.rattleAt > 1.5 and not state.open then
					rattle(state)
				end
			elseif not state.open or state.closing then
				Doors.open(state, pusher)
			end
		end
		if state.open and not state.closing then
			if near then
				state.lastNear = now
			elseif state.autoClose > 0 and now - state.lastNear > state.autoClose then
				Doors.close(state)
			end
		end
	end
end

function Doors.start(cfg)
	config = cfg
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("Door") then
			register(d)
		end
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.1 then
			acc = 0
			step()
		end
	end)
end

Doors.playSound = playSound

return Doors
