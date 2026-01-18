local lune = require("@lune/fs")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")
local testez = require("../node_modules/@rbxts/testez/src") -- path to TestEZ might need adjustment

local file = lune.readFile("test.rbxl")
local game = roblox.deserializePlace(file)

local TextService = game:GetService("TextService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assuming your tests are compiled into ServerScriptService.TS and ReplicatedStorage.TS
local results = testez.TestBootstrap:run({
	ServerScriptService.TS,
	ReplicatedStorage.TS,
})

if results.failureCount > 0 or #results.errors > 0 then
	print("Tests failed with " .. results.failureCount .. " failures")
	process.exit(1)
end
