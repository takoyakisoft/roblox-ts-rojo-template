local lune = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local stdio = require("@lune/stdio")
local process = require("@lune/process")

local file = lune.readFile("test.rbxl")
local game = roblox.deserializePlace(file)

local loadedModules = {}

-- Custom require function to load ModuleScripts from the game data model
local function requireInstance(moduleScript)
	if typeof(moduleScript) ~= "Instance" or not moduleScript:IsA("ModuleScript") then
		error(
			"Attempted to require a non-ModuleScript: "
				.. tostring(moduleScript)
				.. " ("
				.. (typeof(moduleScript) == "Instance" and moduleScript.ClassName or typeof(moduleScript))
				.. ")"
		)
	end

	if loadedModules[moduleScript] then
		return loadedModules[moduleScript]
	end

	-- Prepare the environment for the module
	local env = setmetatable({}, { __index = _G })
	env.script = moduleScript
	env.require = function(target)
		if typeof(target) == "Instance" and target:IsA("ModuleScript") then
			return requireInstance(target)
		end
		return require(target) -- Fallback to Lune's standard require for non-instances
	end

	-- Compile and run the module's source code
	local bytecode = luau.compile(moduleScript.Source)
	local success, result = pcall(function()
		local fn = luau.load(bytecode, { environment = env })
		return fn()
	end)

	if not success then
		error("Failed to load module " .. moduleScript:GetFullName() .. ": " .. tostring(result))
	end

	loadedModules[moduleScript] = result
	return result
end

-- Setup global shared environment if needed by TestEZ or tests
-- _G.game = game

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Locate TestEZ in the compiled node_modules
local testezFolder = ReplicatedStorage.rbxts_include.node_modules["@rbxts"].testez

-- [FIX]: Resolve TestEZ entry point robustly
local TestEZModule = testezFolder:FindFirstChild("init")

-- Fallback: Check inside 'src' if init is not found in root
if not TestEZModule then
	local src = testezFolder:FindFirstChild("src")
	if src then
		TestEZModule = src:FindFirstChild("init")
	end
end

-- Debug: If still not found, print structure to help diagnosis
if not TestEZModule or not TestEZModule:IsA("ModuleScript") then
	stdio.write(stdio.color("red") .. "Error: Could not find TestEZ 'init' ModuleScript.\n" .. stdio.color("reset"))
	print("Path checked: " .. testezFolder:GetFullName())
	print("Children found:")
	for _, child in testezFolder:GetChildren() do
		print(string.format("- %s [%s]", child.Name, child.ClassName))
		if child.Name == "src" or child:IsA("Folder") then
			for _, grandChild in child:GetChildren() do
				print(string.format("  |- %s [%s]", grandChild.Name, grandChild.ClassName))
			end
		end
	end
	process.exit(1)
end

local TestEZ = requireInstance(TestEZModule)

-- Run tests
local results = TestEZ.TestBootstrap:run({
	ServerScriptService.TS,
	ReplicatedStorage.TS,
})

if results.failureCount > 0 or #results.errors > 0 then
	print("Tests failed with " .. results.failureCount .. " failures")
	process.exit(1)
end
