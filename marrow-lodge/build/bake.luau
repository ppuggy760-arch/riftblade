-- Builds MarrowLodge.rbxl: the whole world, lighting, items and scripts in one place file.
-- Run from the marrow-lodge folder:  lune run build/bake.luau

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local B = require("./lib/B")
local L = require("./world/Layout")
local Cabin = require("./world/Cabin")
local Rooms = require("./world/Rooms")
local Basement = require("./world/Basement")
local Yard = require("./world/Yard")
local Tools = require("./world/Tools")

local Instance = roblox.Instance
local CFrame = roblox.CFrame
local V = B.V
local Enum = roblox.Enum

local root = if fs.isDir("src") then "." else ".."
local out = process.args[1] or (root .. "/MarrowLodge.rbxl")

local game = Instance.new("DataModel")
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")

---------------------------------------------------------------- world

workspace.StreamingEnabled = false
workspace.FallenPartsDestroyHeight = -150
local terrain = Instance.new("Terrain")
terrain.Parent = workspace
pcall(function()
	terrain.Decoration = true
	terrain.WaterColor = B.rgb(60, 92, 84)
	terrain.WaterTransparency = 0.6
	terrain.WaterReflectance = 0.8
	terrain.WaterWaveSize = 0.08
	terrain.WaterWaveSpeed = 4
end)

local lodge = Instance.new("Model")
lodge.Name = "Lodge"
lodge.Parent = workspace
B.parent = lodge
B.seed(1931)

Cabin.build(lodge)
Rooms.build(lodge, Cabin.doorFolder)
Basement.build(lodge, Cabin.doorFolder)
Yard.build(lodge)

-- where the key holder appears: upstairs in the loft, looking at the top of the stairs
B.box(V(2, 0.2, 2), CFrame.lookAt(V(2, L.yUpper + 0.1, -17), V(-9.5, L.yUpper + 0.1, -1.5)), B.C.warm, B.M.SmoothPlastic, {
	name = "KeeperSpawn",
	transparency = 1,
	collide = false,
	shadow = false,
	query = false,
	parent = lodge,
})

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Gate"
spawn.Size = V(12, 1, 12)
spawn.CFrame = CFrame.lookAt(V(L.spawn.x, -0.4, L.spawn.z), V(L.spawn.x, -0.4, 0))
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.AllowTeamChangeOnTouch = false
spawn.Material = Enum.Material.Slate
spawn.Color = B.rgb(140, 130, 118)
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.BottomSurface = Enum.SurfaceType.Smooth
spawn.Parent = workspace

---------------------------------------------------------------- light

lighting.Technology = Enum.Technology.Future
lighting.ClockTime = 17.65
lighting.GeographicLatitude = 41.7
lighting.Brightness = 2.6
lighting.Ambient = B.rgb(108, 82, 56)
lighting.OutdoorAmbient = B.rgb(156, 118, 78)
lighting.ColorShift_Top = B.rgb(255, 204, 136)
lighting.ColorShift_Bottom = B.rgb(110, 70, 36)
lighting.EnvironmentDiffuseScale = 0.85
lighting.EnvironmentSpecularScale = 0.6
lighting.ExposureCompensation = 0.15
lighting.GlobalShadows = true
lighting.ShadowSoftness = 0.3

local function effect(className, props)
	local e = Instance.new(className)
	for k, v in props do
		e[k] = v
	end
	e.Parent = lighting
	return e
end

local sky = Instance.new("Sky")
for _, face in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do
	sky["Skybox" .. face] = "rbxasset://textures/sky/sky512_" .. string.lower(face) .. ".tex"
end
sky.SunTextureId = "rbxasset://sky/sun.jpg"
sky.MoonTextureId = "rbxasset://sky/moon.jpg"
sky.SunAngularSize = 18
sky.MoonAngularSize = 8
sky.StarCount = 0
sky.Parent = lighting

effect("Atmosphere", {
	Density = 0.34,
	Offset = 0.12,
	Color = B.rgb(255, 214, 150),
	Decay = B.rgb(214, 132, 76),
	Glare = 0.5,
	Haze = 1.8,
})
effect("BloomEffect", { Intensity = 0.8, Size = 36, Threshold = 1.05 })
effect("BlurEffect", { Size = 2.5 })
effect("ColorCorrectionEffect", {
	Brightness = 0.03,
	Contrast = 0.12,
	Saturation = 0.24,
	TintColor = B.rgb(255, 238, 204),
})
effect("SunRaysEffect", { Intensity = 0.11, Spread = 0.8 })
effect("DepthOfFieldEffect", {
	FarIntensity = 0.22,
	FocusDistance = 28,
	InFocusRadius = 38,
	NearIntensity = 0,
})

---------------------------------------------------------------- services

game:GetService("SoundService").AmbientReverb = Enum.ReverbType.LivingRoom

local starterPlayer = game:GetService("StarterPlayer")
starterPlayer.CharacterWalkSpeed = 14
starterPlayer.CameraMaxZoomDistance = 40

Tools.build(game:GetService("ServerStorage"))

local function source(path)
	return fs.readFile(root .. "/src/" .. path)
end

local function script(className, name, path, parent)
	local s = Instance.new(className)
	s.Name = name
	s.Source = source(path)
	s.Parent = parent
	return s
end

script("ModuleScript", "LodgeConfig", "shared/LodgeConfig.luau", game:GetService("ReplicatedStorage"))

local server = script("Script", "LodgeServer", "server/LodgeServer.server.luau", game:GetService("ServerScriptService"))
for _, m in { "Doors", "Items", "Secrets", "Grounds" } do
	script("ModuleScript", m, "server/" .. m .. ".luau", server)
end

local starterScripts = starterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
if not starterScripts then
	starterScripts = Instance.new("StarterPlayerScripts")
	starterScripts.Parent = starterPlayer
end
local client = script("LocalScript", "LodgeClient", "client/LodgeClient.client.luau", starterScripts)
for _, m in { "Prompts", "Pages", "Ambience" } do
	script("ModuleScript", m, "client/" .. m .. ".luau", client)
end

---------------------------------------------------------------- write

local parts, lights = 0, 0
for _, d in game:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	elseif d:IsA("Light") then
		lights += 1
	end
end

fs.writeFile(out, roblox.serializePlace(game))
print(string.format("wrote %s  (%d parts, %d lights)", out, parts, lights))
