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

-- Key to unwrap proxies
local REAL_INSTANCE = newproxy()

local function wrapInstance(instance)
	if typeof(instance) ~= "Instance" then
		return instance
	end

	local proxy = newproxy(true)
	local meta = getmetatable(proxy)

	meta.__index = function(_, key)
		if key == REAL_INSTANCE then
			return instance
		end

		if key == "WaitForChild" then
			return function(_, childName)
				local child = instance:FindFirstChild(childName)
				return wrapInstance(child)
			end
		elseif key == "GetService" and instance == gameReal then
			return function(_, serviceName)
				if serviceName == "RunService" then
					return {
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
				end
				if serviceName == "TestService" then
					return {
						Error = function(_, message)
							stdio.write(
								stdio.color("red")
									.. "[TestService Error] "
									.. tostring(message)
									.. stdio.color("reset")
									.. "\n"
							)
						end,
						Message = function(_, message)
							print("[TestService Message] " .. tostring(message))
						end,
						Checkpoint = function() end,
					}
				end
				return wrapInstance(gameReal:GetService(serviceName))
			end
		end

		local val = instance[key]
		if typeof(val) == "function" then
			return function(_, ...)
				local args = { ... }
				-- Extract real instances from proxies
				for i, v in ipairs(args) do
					if typeof(v) == "userdata" then
						local m = getmetatable(v)
						if m and m.__index then
							local real = v[REAL_INSTANCE]
							if real then
								args[i] = real
							end
						end
					end
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

-- 3. Module Loader
local loadedModules = {}

local function requireInstance(moduleScript)
	-- Unwrap proxy if necessary
	if typeof(moduleScript) == "userdata" then
		local real = moduleScript[REAL_INSTANCE]
		if real then
			moduleScript = real
		end
	end

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
		local realTarget = target
		if typeof(target) == "userdata" then
			local real = target[REAL_INSTANCE]
			if real then
				realTarget = real
			end
		end

		if typeof(realTarget) == "Instance" and realTarget:IsA("ModuleScript") then
			return requireInstance(realTarget)
		end

		-- Fallback to standard require (expects string)
		return require(target)
	end

	-- Compile and run
	local success, result = pcall(function()
		local bytecode = luau.compile(moduleScript.Source)
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
