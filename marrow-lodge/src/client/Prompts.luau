-- Only shows a prompt to someone carrying what it needs: a key for locks, a hairpin
-- for picking, the pry bar for the boards, a spare key to hand to someone else.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Prompts = {}

local player = Players.LocalPlayer
local tracked = {} -- [ProximityPrompt] = door model or false

local function doorOf(prompt)
	local node = prompt.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:GetAttribute("Door") then
			return node
		end
		node = node.Parent
	end
	return false
end

local function track(d)
	if d:IsA("ProximityPrompt") and d:GetAttribute("Need") then
		d.Enabled = false
		tracked[d] = doorOf(d)
	end
end

local function carried()
	local have = { Key = false, Hairpin = false, Crowbar = false, CopyKey = false }
	for _, place in { player.Character, player:FindFirstChildOfClass("Backpack") } do
		if place then
			for _, t in place:GetChildren() do
				if t:IsA("Tool") then
					local item = t:GetAttribute("LodgeItem")
					if item then
						have[item] = true
						if item == "Key" and t:GetAttribute("Master") ~= true then
							have.CopyKey = true
						end
					end
				end
			end
		end
	end
	return have
end

local function refresh()
	local have = carried()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for prompt, door in tracked do
		if prompt.Parent == nil then
			tracked[prompt] = nil
			continue
		end
		local need = prompt:GetAttribute("Need")
		local show
		if need == "GiveKey" then
			show = have.CopyKey and prompt.Parent ~= myRoot
		else
			show = have[need] == true
		end
		if show and prompt:GetAttribute("When") == "Locked" then
			show = door and door:GetAttribute("Locked") == true
		end
		if prompt.Enabled ~= show then
			prompt.Enabled = show
		end
	end
end

function Prompts.start()
	for _, d in workspace:GetDescendants() do
		track(d)
	end
	workspace.DescendantAdded:Connect(track)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.2 then
			acc = 0
			refresh()
		end
	end)
end

return Prompts
