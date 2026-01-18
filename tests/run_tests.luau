local lune = require("@lune/fs")
local roblox = require("@lune/roblox")
local stdio = require("@lune/stdio")
local stdio = require("@lune/stdio")

local file = lune.readFile("test.rbxl")
local game = roblox.deserializePlace(file)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Locate TestEZ in the compiled node_modules within the place
local TestEZ = require(ReplicatedStorage.rbxts_include.node_modules["@rbxts"].testez)

-- Assuming your tests are compiled into ServerScriptService.TS and ReplicatedStorage.TS
local results = TestEZ.TestBootstrap:run({
	ServerScriptService.TS,
	ReplicatedStorage.TS,
})

if results.failureCount > 0 or #results.errors > 0 then
	print("Tests failed with " .. results.failureCount .. " failures")
	process.exit(1)
end
