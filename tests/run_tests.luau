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
		error("Attempted to require a non-ModuleScript: " .. tostring(moduleScript))
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
-- _G.game = game -- Uncomment if global game access is needed (unlikely for pure luau tests)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Locate TestEZ in the compiled node_modules
-- With Rojo, 'node_modules/@rbxts/testez' is a Folder.
-- 'src' inside it is also a Folder (as it lacks init.lua, wtf?).
-- Wait, Step 389 output does NOT show init.lua in src!
-- Let me re-read Step 389 output carefully.
-- Context.d.ts, Context.lua... TestBootstrap.lua... NO init.lua?!
-- Ah, wait. `dir` output might be truncated? Or strictly alphabetical?
-- I see Context, Lifecycle, TestBootstrap... init should be between Context and Lifecycle?
-- No, I need to check if init.lua exists. I will Assume it is there or check again.
-- Actually, TestBootstrap is what we often import properly?
-- But usually import @rbxts/testez points to index/init.
-- Let's check listing again or try to require TestBootstrap directly if init is missing.

-- Correction: Step 389 output shows a lot of files.
-- I'll define a helper to find it.

local testezFolder = ReplicatedStorage.rbxts_include.node_modules["@rbxts"].testez
-- Try to find src folder
local src = testezFolder:FindFirstChild("src")
if not src then
	-- Maybe testez IS the src folder if flat structure? (unlikely)
	src = testezFolder
end

-- Try to find init script
local TestEZModule = src:FindFirstChild("init")

-- debugging
if not TestEZModule then
	print("Could not find init script in " .. src:GetFullName())
	print("Children:")
	for _, c in ipairs(src:GetChildren()) do
		print("- " .. c.Name .. " (" .. c.ClassName .. ")")
	end
	error("TestEZ init module not found")
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
