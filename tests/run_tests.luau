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

-- Instance:WaitForChild polyfill
local function patchInstances(root)
	for _, instance in ipairs(root:GetDescendants()) do
		-- Lune's instances are handled via metatables, but we can't easily patch them.
		-- Instead, we ensure the environment's 'game' and 'script' proxies handle these.
	end
end

local MockRunService = {
	IsStudio = function()
		return false
	end,
	IsRunning = function()
		return true
	end,
	IsRunMode = function()
		return true
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
	Stepped = {
		Wait = function()
			return task.wait()
		end,
		Connect = function()
			return { Disconnect = function() end }
		end,
	},
}

local MockTestService = {
	Error = function(_, message)
		stdio.write(stdio.color("red") .. "[TestService Error] " .. message .. stdio.color("reset") .. "\n")
	end,
	Message = function(_, message)
		print("[TestService Message] " .. message)
	end,
	Checkpoint = function() end,
}

-- Mock Enum
local MockEnum = setmetatable({}, {
	__index = function(self, serviceName)
		local serviceEnums = setmetatable({}, {
			__index = function(self2, itemName)
				local item = newproxy(true)
				getmetatable(item).__tostring = function()
					return "Enum." .. serviceName .. "." .. itemName
				end
				rawset(self2, itemName, item)
				return item
			end,
		})
		rawset(self, serviceName, serviceEnums)
		return serviceEnums
	end,
})

-- Instance Proxy to handle WaitForChild etc.
local function wrapInstance(instance)
	if typeof(instance) ~= "Instance" then
		return instance
	end

	local proxy = newproxy(true)
	local meta = getmetatable(proxy)

	meta.__index = function(_, key)
		if key == "WaitForChild" then
			return function(_, childName)
				local child = instance:FindFirstChild(childName)
				return wrapInstance(child)
			end
		elseif key == "GetService" and instance == gameReal then
			return function(_, serviceName)
				if serviceName == "RunService" then
					return MockRunService
				end
				if serviceName == "TestService" then
					return MockTestService
				end
				return wrapInstance(gameReal:GetService(serviceName))
			end
		end

		local val = instance[key]
		if typeof(val) == "function" then
			return function(_, ...)
				local args = { ... }
				-- Unmask proxies if passed back to real methods
				for i, v in ipairs(args) do
					-- (This is simplified, real unmasking might be needed)
				end
				local results = { val(instance, unpack(args)) }
				-- Wrap results
				for i, v in ipairs(results) do
					results[i] = wrapInstance(v)
				end
				return unpack(results)
			end
		end
		return wrapInstance(val)
	end

	meta.__tostring = function()
		return tostring(instance)
	end
	return proxy
end

local GameProxy = wrapInstance(gameReal)

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
	env.script = wrapInstance(moduleScript)
	env.game = GameProxy
	env.workspace = GameProxy.Workspace
	env.Enum = MockEnum
	env.task = task
	env.wait = task.wait
	env.spawn = task.spawn
	env.delay = task.delay
	env.tick = os.clock
	env.warn = function(...)
		stdio.write(stdio.color("yellow") .. table.concat({ ... }, " ") .. stdio.color("reset") .. "\n")
	end

	env.require = function(target)
		if typeof(target) == "userdata" then -- Check if it's our proxy
			-- Extract real instance from proxy would be better,
			-- but here we assume the target passed to require is the real instance or handled
		end

		-- If it's a proxy, we might need a way to get back the real instance
		-- For now, let's try to handle both
		local realTarget = target
		-- (Implementation detail: how to get real instance from proxy?
		-- For simplicity, let's try to find it in the game)

		if typeof(realTarget) == "Instance" and realTarget:IsA("ModuleScript") then
			return requireInstance(realTarget)
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
	GameProxy.ServerScriptService.TS,
	GameProxy.ReplicatedStorage.TS,
})

if results.failureCount > 0 or #results.errors > 0 then
	print("Tests failed with " .. results.failureCount .. " failures")
	process.exit(1)
end
