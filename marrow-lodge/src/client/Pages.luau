-- Reading the letters, pages and drawings found around the lodge.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LodgeConfig"))

local Pages = {}

local player = Players.LocalPlayer

local STYLES = {
	hand = { font = Enum.Font.Kalam, color = Color3.fromRGB(38, 34, 70), paper = Color3.fromRGB(240, 228, 196), size = 26 },
	child = { font = Enum.Font.IndieFlower, color = Color3.fromRGB(70, 60, 150), paper = Color3.fromRGB(250, 246, 234), size = 30 },
	ledger = { font = Enum.Font.SpecialElite, color = Color3.fromRGB(40, 34, 30), paper = Color3.fromRGB(232, 220, 188), size = 22 },
	faded = { font = Enum.Font.Kalam, color = Color3.fromRGB(110, 96, 110), paper = Color3.fromRGB(222, 206, 170), size = 26 },
}

local gui, shade, paper, label
local openedAt, openedFrom = 0, nil

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "Pages"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	shade = Instance.new("TextButton")
	shade.Name = "Shade"
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.BackgroundColor3 = Color3.fromRGB(20, 12, 4)
	shade.BackgroundTransparency = 1
	shade.Size = UDim2.fromScale(1, 1)
	shade.Parent = gui

	paper = Instance.new("Frame")
	paper.Name = "Paper"
	paper.AnchorPoint = Vector2.new(0.5, 0.5)
	paper.Position = UDim2.fromScale(0.5, 0.52)
	paper.Size = UDim2.fromScale(0.42, 0.8)
	paper.Rotation = -1.2
	paper.BorderSizePixel = 0
	paper.Parent = gui
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 0.74
	aspect.Parent = paper
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = paper
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 110, 60)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = paper
	local tint = Instance.new("UIGradient")
	tint.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(250, 240, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(226, 200, 150)),
	})
	tint.Rotation = 60
	tint.Parent = paper

	label = Instance.new("TextLabel")
	label.Name = "Writing"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.84, 0.88)
	label.TextWrapped = true
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = paper
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 28
	limit.MinTextSize = 10
	limit.Parent = label

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -6, 0, 6)
	close.Size = UDim2.fromOffset(34, 34)
	close.BackgroundTransparency = 1
	close.Text = "×"
	close.TextSize = 30
	close.Font = Enum.Font.Kalam
	close.TextColor3 = Color3.fromRGB(110, 80, 50)
	close.Parent = paper

	shade.Activated:Connect(Pages.hide)
	close.Activated:Connect(Pages.hide)
end

function Pages.hide()
	if not gui or not gui.Enabled then
		return
	end
	local t = TweenService:Create(shade, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
	t:Play()
	TweenService:Create(paper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 0.6) }):Play()
	task.delay(0.2, function()
		gui.Enabled = false
	end)
	openedFrom = nil
end

function Pages.show(text, styleName, from)
	if not gui then
		build()
	end
	local style = STYLES[styleName] or STYLES.hand
	label.Text = text
	label.Font = style.font
	label.TextColor3 = style.color
	label.TextTransparency = if styleName == "faded" then 0.2 else 0
	label:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize = style.size
	paper.BackgroundColor3 = style.paper
	paper.Position = UDim2.fromScale(0.5, 0.58)
	paper.Rotation = math.random(-20, 20) / 10
	shade.BackgroundTransparency = 1
	gui.Enabled = true
	TweenService:Create(shade, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(paper, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.52) }):Play()
	openedAt = os.clock()
	openedFrom = from
	if Config.Sounds.Page ~= "" then
		local s = Instance.new("Sound")
		s.SoundId = Config.Sounds.Page
		s.Volume = 0.6
		s.Parent = gui
		s:Play()
		game:GetService("Debris"):AddItem(s, 4)
	end
end

function Pages.start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= player or prompt.Name ~= "ReadPrompt" then
			return
		end
		local page = prompt.Parent
		local text = page and page:GetAttribute("NoteText")
		if not text then
			return
		end
		-- the same key puts the page back down
		if gui and gui.Enabled and openedFrom == page.Position and os.clock() - openedAt > 0.3 then
			Pages.hide()
		else
			Pages.show(text, page:GetAttribute("NoteStyle"), page.Position)
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if not gui or not gui.Enabled or os.clock() - openedAt < 0.3 then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then
			Pages.hide()
		end
	end)
	-- walking away puts the page down
	RunService.Heartbeat:Connect(function()
		if openedFrom and gui and gui.Enabled then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - openedFrom).Magnitude > 12 then
				Pages.hide()
			end
		end
	end)
end

return Pages
