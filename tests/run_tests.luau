local lune = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local stdio = require("@lune/stdio")
local process = require("@lune/process")
local task = require("@lune/task")

-- 1. Load DataModel
local file = lune.readFile("test.rbxl")
local gameReal = roblox.deserializePlace(file)

-- 2. Polyfills & Mocks (Lune -> Roblox Compatibility)
local MockRunService = {
	IsStudio = function()
		return false
	end,
	IsRunning = function()
		return false
	end,
	IsRunMode = function()
		return false
	end,
	IsClient = function()
		return false
	end,
	IsServer = function()
		return true
	end,
	Heartbeat = {
		Wait = function()
			return task.wait()
		end,
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
	RenderStepped = {
		Wait = function()
			return task.wait()
		end,
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
	Stepped = {
		Wait = function()
			return task.wait()
		end,
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
}

-- Mock Enum
local MockEnum = setmetatable({}, {
	__index = function(self, serviceName)
		local serviceEnums = setmetatable({}, {
			__index = function(self2, itemName)
				-- Create a unique userdata for each EnumItem to allow equality checks
				local item = newproxy(true)
				getmetatable(item).__tostring = function()
					return "Enum." .. serviceName .. "." .. itemName
				end
				rawset(self2, itemName, item) -- Cache it
				return item
			end,
		})
		rawset(self, serviceName, serviceEnums) -- Cache it
		return serviceEnums
	end,
})

-- Game Proxy to intercept GetService
local GameProxy = newproxy(true)
local GameMeta = getmetatable(GameProxy)

GameMeta.__index = function(_, key)
	if key == "GetService" then
		return function(_self, serviceName)
			if serviceName == "RunService" then
				return MockRunService
			end
			-- Fallback to real DataModel for other services (Storage, etc.)
			return gameReal:GetService(serviceName)
		end
	end

	-- Forward properties (like Workspace, ReplicatedStorage if accessed directly)
	local val = gameReal[key]
	if typeof(val) == "function" then
		return function(_self, ...)
			return val(gameReal, ...)
		end
	end
	return val
end

-- 3. Module Loader
local loadedModules = {}

local function requireInstance(moduleScript)
	if typeof(moduleScript) ~= "Instance" or not moduleScript:IsA("ModuleScript") then
		error("Attempted to require a non-ModuleScript: " .. tostring(moduleScript))
	end

	if loadedModules[moduleScript] then
		return loadedModules[moduleScript]
	end

	-- Prepare Environment
	local env = setmetatable({}, { __index = _G })

	-- Inject Roblox Globals
	env.script = moduleScript
	env.game = GameProxy
	env.Enum = MockEnum
	env.task = task
	env.wait = task.wait
	env.spawn = task.spawn
	env.delay = task.delay
	env.warn = function(...)
		stdio.write(stdio.color("yellow") .. ... .. stdio.color("reset") .. "\n")
	end

	env.require = function(target)
		if typeof(target) == "Instance" and target:IsA("ModuleScript") then
			return requireInstance(target)
		end
		return require(target)
	end

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

-- 4. Execution
local ReplicatedStorage = gameReal:GetService("ReplicatedStorage")
local ServerScriptService = gameReal:GetService("ServerScriptService")

local testezFolder = ReplicatedStorage.rbxts_include.node_modules["@rbxts"].testez
local TestEZModule = testezFolder:FindFirstChild("init") or testezFolder:FindFirstChild("src")

if not TestEZModule then
	error("TestEZ module not found!")
end

local TestEZ = requireInstance(TestEZModule)

local results = TestEZ.TestBootstrap:run({
	ServerScriptService.TS,
	ReplicatedStorage.TS,
})

if results.failureCount > 0 or #results.errors > 0 then
	print("Tests failed with " .. results.failureCount .. " failures")
	process.exit(1)
end
