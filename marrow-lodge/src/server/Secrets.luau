-- The two ways out that don't need a key: the bookcase in the study, and the
-- boarded-up coal chute in the cellar.

local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Secrets = {}

local config
local Doors

---------------------------------------------------------------- bookcase

local function weldOf(part)
	return part:FindFirstChild("Weld_" .. part.Name)
end

local function tiltBook(book, amount, hold)
	local weld = weldOf(book)
	if not weld or book:GetAttribute("Tilting") then
		return
	end
	book:SetAttribute("Tilting", true)
	local rest = weld.C0
	local out = rest * CFrame.new(0, 0, -0.3) * CFrame.Angles(math.rad(-amount), 0, 0)
	TweenService:Create(weld, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { C0 = out }):Play()
	task.delay(hold, function()
		local back = TweenService:Create(weld, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { C0 = rest })
		back:Play()
		back.Completed:Wait()
		book:SetAttribute("Tilting", nil)
	end)
end

local function setupBookcase()
	local state = Doors.get("Bookcase")
	if not state then
		return
	end
	for _, d in state.model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Name == "PullPrompt" then
			local holder = d.Parent
			local book = if holder:IsA("BasePart") and holder.Name ~= "BackBoards" then holder else nil
			if d:GetAttribute("Decoy") then
				d.Triggered:Connect(function()
					tiltBook(book, 8, 0.6)
				end)
			elseif d:GetAttribute("Opens") then
				d.Triggered:Connect(function(player)
					if book then
						tiltBook(book, 25, 1.4)
						task.wait(0.45)
					end
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if Doors.open(state, root and root.Position) then
						Doors.playSound(state.hinge, config.Sounds.Shelf, 0.7, 1)
					end
				end)
			end
		end
	end
end

---------------------------------------------------------------- coal chute

local boardsParent, template
local pried = false

local function anyoneNear(position, radius)
	for _, p in Players:GetPlayers() do
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - position).Magnitude < radius then
			return true
		end
	end
	return false
end

local setupBoards

local function reboard(position)
	task.delay(config.ChuteBoardsReset, function()
		while anyoneNear(position, 9) do
			task.wait(3)
		end
		local fresh = template:Clone()
		fresh.Parent = boardsParent
		pried = false
		setupBoards(fresh)
	end)
end

function setupBoards(model)
	local prompt = model:FindFirstChild("PryPrompt", true)
	local blocker = model:FindFirstChild("Blocker")
	if not prompt or not blocker then
		return
	end
	prompt.Triggered:Connect(function(player)
		if pried or not Doors.findItem(player, "Crowbar") then
			return
		end
		pried = true
		local centre = blocker.Position
		prompt:Destroy()
		blocker.CanCollide = false
		Doors.playSound(blocker, config.Sounds.Boards, 0.8, 1)
		for _, b in model:GetChildren() do
			if b:IsA("BasePart") and b.Name == "Board" then
				for _, nail in b:GetChildren() do
					if nail:IsA("Weld") then
						nail:Destroy()
					end
				end
				b.Anchored = false
				b.CanCollide = true
				b.AssemblyLinearVelocity = Vector3.new(math.random(-4, 4), math.random(2, 6), -math.random(6, 10))
				b.AssemblyAngularVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
			elseif b:IsA("BasePart") and b.Name == "Nail" then
				b:Destroy()
			end
		end
		Debris:AddItem(model, 12)
		reboard(centre)
	end)
end

function Secrets.start(cfg, doors)
	config = cfg
	Doors = doors
	setupBookcase()

	local boards
	for _, d in workspace:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("ChuteBoards") then
			boards = d
			break
		end
	end
	if boards then
		boardsParent = boards.Parent
		template = boards:Clone()
		template.Parent = ServerStorage
		setupBoards(boards)
	end
end

return Secrets
