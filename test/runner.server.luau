--!strict

-- This script is used by CI to run tests
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService: ServerScriptService = game:GetService("ServerScriptService")

-- Locate TestEZ in the compiled node_modules
local TestEZ = require(
	ReplicatedStorage:WaitForChild("rbxts_include")
		:WaitForChild("node_modules")
		:WaitForChild("@rbxts")
		:WaitForChild("testez")
)

-- Run tests on the TS folder in ServerScriptService (server) and ReplicatedStorage (shared)
local results = TestEZ.TestBootstrap:run({ ServerScriptService.TS, ReplicatedStorage.TS })

if results.failureCount > 0 or #results.errors > 0 then
	error("Tests failed with " .. results.failureCount .. " failures")
end

-- Shutdown the server after tests finish (successful)
game:Shutdown()
