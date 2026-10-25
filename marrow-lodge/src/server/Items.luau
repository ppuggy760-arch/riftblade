-- Keys, hairpins and the pry bar: who starts with what, the key rack in the cellar,
-- handing a key to someone else, and the spots where things can be picked up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Items = {}

local config
local Doors
local templates
local keepers = {} -- [Player] = true

local TOOL_FOR = {
	Hairpin = "Hairpin",
	Crowbar = "Pry Bar",
}

local function isCreator(player)
	if table.find(config.KeeperUserIds, player.UserId) then
		return true
	end
	if game.CreatorId == 0 then
		return false
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		return ok and rank >= 255
	end
	return false
end

local function anyKeeperHere()
	for p in keepers do
		if p.Parent == Players then
			return true
		end
	end
	return false
end

function Items.isKeeper(player)
	return keepers[player] == true
end

local function isCopyKey(tool)
	return tool:GetAttribute("Master") ~= true
end

local function backpackOf(player)
	return player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
end

local function giveMasterKey(player)
	if Doors.findItem(player, "Key", function(t)
		return t:GetAttribute("Master") == true
	end) then
		return
	end
	local bp = backpackOf(player)
	if bp then
		templates["Old Key"]:Clone().Parent = bp
	end
end

local function keeperSpawn()
	local lodge = workspace:FindFirstChild("Lodge")
	return lodge and lodge:FindFirstChild("KeeperSpawn", true)
end

local function addGivePrompt(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GivePrompt"
	prompt.ActionText = "Give Key"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.G
	prompt:SetAttribute("Need", "GiveKey")
	prompt.Parent = root
	prompt.Triggered:Connect(function(giver)
		if giver == player then
			return
		end
		local key = Doors.findItem(giver, "Key", isCopyKey)
		if not key then
			return
		end
		if Doors.findItem(player, "Key") then
			return
		end
		local bp = backpackOf(player)
		if bp then
			key.Parent = bp
			Doors.playSound(root, config.Sounds.Keys, 0.6, 1)
		end
	end)
end

local function onCharacter(player, character)
	task.spawn(addGivePrompt, player, character)
	if not keepers[player] then
		return
	end
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not root then
			return
		end
		-- give the new backpack a moment to exist before putting the key in it
		task.wait(0.2)
		giveMasterKey(player)
		local spot = keeperSpawn()
		if config.KeeperStartsInside and spot and character.Parent then
			character:PivotTo(spot.CFrame + Vector3.new(0, 3, 0))
		end
	end)
end

local function onPlayer(player)
	local keeper = isCreator(player)
	if not keeper and RunService:IsStudio() and config.StudioFirstPlayerIsKeeper and not anyKeeperHere() then
		keeper = true
	end
	if keeper then
		keepers[player] = true
	end
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

---------------------------------------------------------------- cellar key rack

local function setupKeyRack(board)
	local prompt = board:FindFirstChild("KeyPrompt")
	if not prompt then
		return
	end
	local busy = {}
	prompt.Triggered:Connect(function(player)
		if busy[player] then
			return
		end
		if Doors.findItem(player, "Key", isCopyKey) then
			return
		end
		busy[player] = true
		local bp = backpackOf(player)
		if bp then
			templates["Key"]:Clone().Parent = bp
			Doors.playSound(board, config.Sounds.Keys, 0.6, 1.1)
		end
		task.delay(1, function()
			busy[player] = nil
		end)
	end)
end

---------------------------------------------------------------- pickup spots

local function anyExists(item)
	for _, p in Players:GetPlayers() do
		if Doors.findItem(p, item) then
			return true
		end
	end
	for _, d in workspace:GetChildren() do
		if d:IsA("Tool") and d:GetAttribute("LodgeItem") == item then
			return true
		end
	end
	return false
end

local function setupSpot(model)
	local item = model:GetAttribute("Pickup")
	local respawn = model:GetAttribute("Respawn") or 60
	local prompt = model:FindFirstChild("TakePrompt", true)
	if not prompt or not TOOL_FOR[item] then
		return
	end
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			parts[d] = d.Transparency
		end
	end
	local present = true
	local function show(on)
		present = on
		for part, t in parts do
			part.Transparency = if on then t else 1
		end
		prompt.Enabled = on
	end
	prompt.Triggered:Connect(function(player)
		if not present or Doors.findItem(player, item) then
			return
		end
		local bp = backpackOf(player)
		if not bp then
			return
		end
		templates[TOOL_FOR[item]]:Clone().Parent = bp
		Doors.playSound(prompt.Parent, config.Sounds.Pickup, 0.5, 1)
		show(false)
		if respawn > 0 then
			task.delay(respawn, function()
				show(true)
			end)
		else
			-- one of a kind: comes back only once nobody has it any more
			task.spawn(function()
				repeat
					task.wait(5)
				until not anyExists(item)
				show(true)
			end)
		end
	end)
end

function Items.start(cfg, doors)
	config = cfg
	Doors = doors
	templates = {}
	local folder = ServerStorage:WaitForChild("LodgeItems")
	for _, t in folder:GetChildren() do
		templates[t.Name] = t
	end

	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("KeyRack") then
			setupKeyRack(d)
		elseif d:IsA("Model") and d:GetAttribute("Pickup") then
			setupSpot(d)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayer, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		keepers[p] = nil
	end)
end

return Items
