-- Settings for Marrow Lodge. Lives in ReplicatedStorage so both sides can read it.

local Config = {}

-- Who carries the old key. The account (or group owner) that owns the place always does;
-- add more Roblox user ids here if you want someone else to have it too.
Config.KeeperUserIds = {}

-- In Studio test servers players get fake ids, so the first one in gets the key.
Config.StudioFirstPlayerIsKeeper = true

-- The key holder starts upstairs in the loft instead of out at the gate.
Config.KeeperStartsInside = true

-- Turn the flat grass parts into real terrain (grass blades, pond water) when the server starts.
Config.TerrainGround = true

-- How long (seconds) before the coal chute gets boarded up again after being pried open.
Config.ChuteBoardsReset = 150

-- How long (seconds) an unlocked door stays open after the last person walks away.
Config.DoorCloseDelay = 3

-- Sound ids. Paste ids from the Toolbox's Audio tab (rbxassetid://123...) to fill these in.
-- Empty strings are simply skipped.
Config.Sounds = {
	Lock = "rbxasset://sounds/clickfast.wav",
	Unlock = "rbxasset://sounds/clickfast.wav",
	Rattle = "rbxasset://sounds/clickfast.wav",
	DoorOpen = "",
	DoorClose = "",
	Boards = "",
	Shelf = "",
	Page = "",
	Ambience = "",
	Keys = "",
}

return Config
