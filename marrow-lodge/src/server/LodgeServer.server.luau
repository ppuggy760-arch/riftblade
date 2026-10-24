-- Marrow Lodge server entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LodgeConfig"))
local Grounds = require(script:WaitForChild("Grounds"))
local Doors = require(script:WaitForChild("Doors"))
local Items = require(script:WaitForChild("Items"))
local Secrets = require(script:WaitForChild("Secrets"))

Grounds.start(Config)
Doors.start(Config)
Items.start(Config, Doors)
Secrets.start(Config, Doors)
