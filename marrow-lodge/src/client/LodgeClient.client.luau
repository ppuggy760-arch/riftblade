-- Marrow Lodge client entry point.

local Prompts = require(script:WaitForChild("Prompts"))
local Pages = require(script:WaitForChild("Pages"))
local Ambience = require(script:WaitForChild("Ambience"))

Prompts.start()
Pages.start()
Ambience.start()
