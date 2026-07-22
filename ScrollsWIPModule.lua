

-- ==== [ ReplicatedStorage.Assets.Hooks.MainHook ] ==== --
-- A ModuleScript inside your hooks folder.

local Admins = {
	86711237;
	7073954647;
	795261895;
	2359024102;
	199242596;
}

return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		if context.Group == "DefaultAdmin" and not table.find(Admins, context.Executor.UserId) then
			return "You don't have permission to run this command"
		end
	end)
end


-- ==== [ ReplicatedStorage.Modules.Core.Logger ] ==== --
local runservice = game:GetService("RunService")

local logremote = script.LogRemote

local client_log_event = Instance.new("BindableEvent")
local logger_module = {
	ClientLogEvent = client_log_event.Event,
	
	Logs = {
		[1] = {
			Threat = 1,
			Time = 0,
			Message = "Server Started"
		}
	},
	StartTime = os.time()
}

function convertToHMS(Seconds)
	local function Format(Int)
		return string.format("%02i", Int)
	end
	
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

logger_module.Initialize = function()
	if runservice:IsServer() then
		
	end
	
	if runservice:IsClient() then
		logremote.OnClientEvent:Connect(function(log)
			client_log_event:Fire(log.Threat, log.Time, log.Message)
		end)
	end
end

function logger_module:Log(threat, message)
	if runservice:IsClient() then
		return
	end
	
	local startime = logger_module.StartTime
	local logtime = convertToHMS(os.time() - startime)
	
	local log = {
		Threat = threat,
		Time = logtime,
		Message = message
	}
	
	table.insert(logger_module.Logs, log)
	logremote:FireAllClients(log)
end

return logger_module

-- ==== [ ReplicatedStorage.Modules.Core.Profile ] ==== --
local runservice = game:GetService("RunService")

local players = game:GetService("Players")

local sync_remote = script:WaitForChild("Sync")

local profile_module = {
	Profiles = {},
	Profile = nil,
	
	ServerProfileChanged = {},
	ClientProfileChanged = Instance.new("BindableEvent")
}

profile_module.Initialize = function()
	if runservice:IsServer() then
		return
	end
	
	local player = players.LocalPlayer
	
	sync_remote.OnClientEvent:Connect(function(profile, what_changed)
		profile_module.Profile = profile
		
		profile_module.ClientProfileChanged:Fire(profile, what_changed)
		
		--print("Synced:", profile_module.Profile)
	end)
end

function profile_module:Sync(player, what_changed)
	if runservice:IsClient() then
		return
	end
	
	if not player then
		return
	end
	
	if not profile_module.Profiles[player] then
		return
	end
	
	local bindeableevent = profile_module.ServerProfileChanged[player]
	if bindeableevent then
		bindeableevent:Fire(profile_module.Profiles[player].Data, what_changed)
	end
	
	sync_remote:FireClient(player, profile_module.Profiles[player].Data, what_changed)
end

function profile_module:GetChangedEvent(player)
	if runservice:IsClient() then
		return
	end
	
	local bindeableevent = profile_module.ServerProfileChanged[player]
	
	if not bindeableevent then
		repeat task.wait()
			bindeableevent = profile_module.ServerProfileChanged[player]
		until bindeableevent
	end
	
	return bindeableevent
end

function profile_module:AddProfile(player, profile)	
	if runservice:IsClient() then
		return
	end
	
	if profile_module.Profiles[player] then
		--print("Profile already exists for", player)
		return
	end
	
	profile_module.Profiles[player] = profile
	profile_module.ServerProfileChanged[player] = Instance.new("BindableEvent")
	
	profile_module:Sync(player)
end

function profile_module:RemoveProfile(player)
	if runservice:IsClient() then
		return
	end
	
	if not profile_module.Profiles[player] then
		--print("Profile doesnt exist for", player)
		return
	end
	
	profile_module.Profiles[player] = nil
	
	profile_module:Sync(player)
end

function profile_module:GetProfile(player)
	if runservice:IsServer() then
		local profile = profile_module.Profiles[player]
		if not profile then
			repeat task.wait()
				profile = profile_module.Profiles[player]
			until profile
		end
		return profile
	end
	
	if runservice:IsClient() then
		local profile = profile_module.Profile
		if not profile then
			repeat task.wait()
				profile = profile_module.Profile
			until profile
		end
		return profile
	end
end

function profile_module:Set(player, key, value)
	if runservice:IsClient() then
		return
	end
	
	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end
	
	if profile.Data[key] then
		profile.Data[key] = value
		
		profile_module:Sync(player, key)
	end
end

function profile_module:Add(player, key, add)
	if runservice:IsClient() then
		return
	end

	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end
	
	if profile.Data[key] then
		if type(profile.Data[key]) == "number" then
			profile.Data[key] += add
		
			profile_module:Sync(player, key)
		end
	end
end

function profile_module:Sub(player, key, sub)
	if runservice:IsClient() then
		return
	end

	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end

	if profile.Data[key] then
		if type(profile.Data[key]) == "number" then
			profile.Data[key] -= sub
			
			profile_module:Sync(player, key)
		end
	end
end

function profile_module:Insert(player, key, value)
	if runservice:IsClient() then
		return
	end

	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end
	
	if profile.Data[key] and type(profile.Data[key]) == "table" then
		table.insert(profile.Data[key], value)

		profile_module:Sync(player, key)
	end
end

function profile_module:TableSet(player, key1, key2, value)
	if runservice:IsClient() then
		return
	end
	
	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end
	
	if profile.Data[key1] and type(profile.Data[key1]) == "table" then
		profile.Data[key1][key2] = value
		
		profile_module:Sync(player, key1)
	end
end

return profile_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Block ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local localplayer = players.LocalPlayer

local gamedata = require(replicatedstorage:WaitForChild("GameData"))
local weapons_data = gamedata.Weapons
local weapons_settings = weapons_data.Settings

local get_player_and_character = function(user: Instance)
	local player
	local character
	
	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end
	
	return player, character
end

local profile_module
local tasks_module
local input_module
local request_module
local attributes_module
local animation_module
local hitbox_module
local damage_module
local sprint_module
local block_module = {
	user_info = {}
}

local get_user_info = function(user)
	local player, character = get_player_and_character(user)

	block_module.user_info[player or character] = block_module.user_info[player or character] or {
		previous_posture = 0,
		reset_cooldown = 0,
		parry_cooldown = 0,
	}
	return block_module.user_info[player or character]
end

block_module.Initialize = function()
	profile_module = shared.Get("Profile")
	tasks_module = shared.Get("Tasks")
	request_module = shared.Get("Request")
	animation_module = shared.Get("Animation")
	attributes_module = shared.Get("Attributes")
	hitbox_module = shared.Get("Hitbox")
	sprint_module = shared.Get("Sprint")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Start Blocking",
			Key = Enum.KeyCode.F,
			Type = "Began",
			Callback = function()
				block_module:StartBlocking(localplayer)
			end,
		})
		
		input_module:Register({
			Name = "Stop Blocking",
			Key = Enum.KeyCode.F,
			Type = "Ended",
			Callback = function()
				block_module:StopBlocking(localplayer)
			end
		})
	end
	
	if runservice:IsServer() then
		damage_module = shared.Get("Damage")
		
		request_module:Register({
			Name = "Start Blocking",
			Callback = function(...)
				block_module:StartBlocking(...)
			end,
		})
		
		request_module:Register({
			Name = "Stop Blocking",
			Callback = function(...)
				block_module:StopBlocking(...)
			end,
		})
	end
end

function block_module:StartBlocking(user)
	local player, character = get_player_and_character(user)
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end
	
	if runservice:IsClient() then
		request_module:Send({
			Name = "Start Blocking",
			Class = "Unreliable",
			Perameters = {}
		})
		
		return
	end
	
	if character_state == "Sprinting" then
		sprint_module:StopSprinting(player)
	end
	
	local user_info = get_user_info(user)
	
	attributes_module:Set(character, "State", "Blocking")
	
	if os.time() - user_info.reset_cooldown > 2 then
		user_info.reset_cooldown = os.time()
		
		attributes_module:Set(character, "Posture", 5)
		attributes_module:TempSet(character, "Parry", true, 0.5)
	else
		attributes_module:Set(character, "Posture", user_info.previous_posture)
	end
	
	if player then
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "Blocking", 1, 1, true}
		})
	else
		local block_animation = animation_module.new(character, "Blocking")
		block_animation:Play()
		block_animation.Looped = true
	end
end

function block_module:StopBlocking(user)
	local player, character = get_player_and_character(user)
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")

	if runservice:IsClient() then
		request_module:Send({
			Name = "Stop Blocking",
			Class = "Unreliable",
			Perameters = {}
		})

		return
	end

	if character_state == "Blocking" then
		attributes_module:Set(character, "State", "Idle")
	end
	
	local user_info = get_user_info(user)
	user_info.previous_posture = attributes_module:Get(character, "Posture")
	
	attributes_module:Set(character, "Posture", 0)

	if player then
		request_module:Send({
			Name = "Stop Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "Blocking"}
		})
	else
		local block_animation = animation_module:GetSpecificAnimation(character, "Blocking")
		if block_animation then
			block_animation:Stop()
		end
	end
end

return block_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.EquipWeapon ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local request_module
local input_module
local attributes_module
local profile_module
local checkattributes_function
local equipweapon_module = {
	active_functions = {}
}

equipweapon_module.Initialize = function()
	request_module = shared.Get("Request")
	attributes_module = shared.Get("Attributes")
	profile_module = shared.Get("Profile")
	checkattributes_function = shared.Get("CheckAttributes")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Equip or Unequip Weapon",
			Key = Enum.KeyCode.One,
			Type = "Began",
			Callback = function()
				request_module:Send({
					Name = "Equip or Unequip Weapon",
					Class = "Unreliable",
					Perameters = {}
				})
			end,
		})
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Equip or Unequip Weapon",
			Callback = function(player)
				local character = player.Character
				local weaponequipped = attributes_module:Get(character, "WeaponEquipped")
				if weaponequipped then
					equipweapon_module:Unequip(character)
				else
					equipweapon_module:Equip(character)
				end
			end,
		})
	end
end

function equipweapon_module:Equip(character)
	local player = players:GetPlayerFromCharacter(character)
	
	local valid_check = checkattributes_function(character, {
		State = {"Idle", "Sprinting"},
		Stuns = 0,
		WeaponEquipped = false,
	})
	if not valid_check then
		return
	end
	
	local weapon = "Fists"
	if player then
		local profile = profile_module:GetProfile(player)
		weapon = profile.Data.Weapon
	end
	
	attributes_module:Set(character, "WeaponEquipped", true)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, weapon.."Equip", 1, 1, false, Enum.AnimationPriority.Action2}
	})
	
	if equipweapon_module.active_functions[character] then
		task.cancel(equipweapon_module.active_functions[character])
	end
	equipweapon_module.active_functions[character] = task.spawn(function()
		local playing_walk, playing_idle = false, false
		local previous = character.HumanoidRootPart.Position
		while true do
			if (previous - character.HumanoidRootPart.Position).Magnitude > 0.1 then
				if not playing_walk then
					playing_walk = true
					playing_idle = false
					
					request_module:Send({
						Name = "Stop Animation",
						Class = "Unreliable",
						All = true,
						Perameters = {character, weapon.."Idle"}
					})
					
					request_module:Send({
						Name = "Play Animation",
						Class = "Unreliable",
						All = true,
						Perameters = {character, weapon.."Walk", 1, 1, true, Enum.AnimationPriority.Movement}
					})
				end
			else
				if not playing_idle then
					playing_idle = true
					playing_walk = false
					
					request_module:Send({
						Name = "Stop Animation",
						Class = "Unreliable",
						All = true,
						Perameters = {character, weapon.."Walk"}
					})
					
					request_module:Send({
						Name = "Play Animation",
						Class = "Unreliable",
						All = true,
						Perameters = {character, weapon.."Idle", 1, 1, true, Enum.AnimationPriority.Movement}
					})
				end
			end
			
			previous = character.HumanoidRootPart.Position
			runservice.Heartbeat:Wait()
		end
	end)
end

function equipweapon_module:Unequip(character)
	local player = players:GetPlayerFromCharacter(character)

	local valid_check = checkattributes_function(character, {
		State = {"Idle", "Sprinting"},
		Stuns = 0,
		WeaponEquipped = true,
	})
	if not valid_check then
		return
	end

	local weapon = "Fists"
	if player then
		local profile = profile_module:GetProfile(player)
		weapon = profile.Data.Weapon
	end

	attributes_module:Set(character, "WeaponEquipped", false)
	
	request_module:Send({
		Name = "Stop Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, weapon.."Idle"}
	})
	request_module:Send({
		Name = "Stop Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, weapon.."Walk"}
	})
	request_module:Send({
		Name = "Stop Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, weapon.."Equip"}
	})
	
	if equipweapon_module.active_functions[character] then
		task.cancel(equipweapon_module.active_functions[character])
	end
end

return equipweapon_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Execute ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local get_player_and_character = function(user: Instance)
	local player
	local character

	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end

	return player, character
end

local attributes_module
local tasks_module
local sprint_module
local input_module
local requests_module
local animation_module
local knocked_module
local profile_module
local execute_module = {}

local get_knocked = function(character)
	for index, value in pairs(workspace.Live:GetChildren()) do
		if value == character then
			continue
		end
		
		local victim_state = value:GetAttribute("State")
		if victim_state == "Knocked" then
			local carry_weld = value:FindFirstChild("Carry Weld")
			if carry_weld then
				continue
			end
			
			local magnitude = (value.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
			if magnitude <= 5 then
				return value
			end
		end
	end
end

execute_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	tasks_module = shared.Get("Tasks")
	sprint_module = shared.Get("Sprint")
	requests_module = shared.Get("Request")
	animation_module = shared.Get("Animation")
	knocked_module = shared.Get("Knocked")
	profile_module = shared.Get("Profile")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Execute",
			Key = Enum.KeyCode.B,
			Type = "Began",
			Callback = function()
				requests_module:Send({
					Name = "Execute",
					Class = "Unreliable",
					Perameters = {}
				})
			end
		})
	end
	
	if runservice:IsServer() then
		requests_module:Register({
			Name = "Execute",
			Callback = function(player)
				local character = player.Character
				local victim = get_knocked(character)
				if not victim then
					return
				end
				
				execute_module:Execute(character, victim)
			end
		})
	end
end

function execute_module:Execute(executor, victim)
	local executer_state = attributes_module:Get(executor, "State")
	local victim_state = attributes_module:Get(victim, "State")
	
	if victim_state ~= "Knocked" or executer_state ~= "Idle" then
		return
	end
	
	local executer_player = players:GetPlayerFromCharacter(executor)
	local executer_humanoid = executor:FindFirstChild("Humanoid")
	local executer_humanoidrootpart = executor:FindFirstChild("HumanoidRootPart")
	local victim_humanoid = victim:FindFirstChild("Humanoid")
	local victim_humanoidrootpart = victim:FindFirstChild("HumanoidRootPart")
	
	if not executer_humanoid or not executer_humanoidrootpart or not victim_humanoid or not victim_humanoidrootpart then
		return
	end
	
	local weapon = "Fists"
	if executer_player then
		local executer_profile = profile_module:GetProfile(executer_player)
		if executer_profile then
			weapon = executer_profile.Data.Weapon
		end
	end
	
	knocked_module:UnKnock(victim)
	
	executer_humanoid.AutoRotate = false
	executer_humanoid.WalkSpeed = 0
	executer_humanoid.JumpPower = 0
	attributes_module:Set(executor, "State", "Executing")
	
	victim_humanoid.AutoRotate = false
	victim_humanoid.WalkSpeed = 0
	victim_humanoid.JumpPower = 0
	
	
	local weld = Instance.new("Weld")
	weld.Part0 = executer_humanoidrootpart
	weld.Part1 = victim_humanoidrootpart
	weld.Name = "Execute Weld"
	weld.Parent = victim
	--victim:PivotTo(executer_humanoidrootpart.CFrame * CFrame.new(0, -3, -4) * CFrame.Angles(0, math.rad(180), 0))
	
	local execute_animation_length = animation_module:GetLength(weapon.."Grip")
	local execute_event_length = animation_module:GetEventLength(weapon.."GripVictim", "Die")
	
	task.delay(execute_animation_length, function()
		executer_humanoid.AutoRotate = true
		executer_humanoid.WalkSpeed = 16
		executer_humanoid.JumpPower = 50
		attributes_module:Set(executor, "State", "Idle")
	end)
	
	task.delay(execute_event_length, function()
		victim_humanoid.Health = 0
		
		weld:Destroy()
	end)
	
	requests_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {executor, weapon.."Grip", 1, 1, false, Enum.AnimationPriority.Action4}
	})
	
	requests_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {victim, weapon.."GripVictim", 1, 1, false, Enum.AnimationPriority.Action4}
	})
end

function execute_module:StopExecuting(executer, victim)
	
end

return execute_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.HeavyPunch ] ==== --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local HeavyPunch = {}

local input_module
local request_module
local attributes_module
local animation_module
local hitbox_module
local damage_module
local sfx_module

local REQ_START = "Ability_HeavyPunch_Start"
local REQ_CAST = "Ability_HeavyPunch_Cast"

local KEY = Enum.KeyCode.R
local COOLDOWN = 2.0
local RADIUS = 7
local DAMAGE = 20

local ANIM_NAME = "HeavyPunchAnim"
local SFX_NAME = "HeavyPunchHit"
local VFX_NAME = "HeavyPunchVFX"

local pending_cast = false
local casting_window = {}
local last_cast = {}

local function can_start(character: Model)
	local state = attributes_module:Get(character, "State")
	local stuns = attributes_module:Get(character, "Stuns") or 0
	if not table.find({ "Idle", "Sprinting" }, state) then
		return false
	end
	if stuns > 0 then
		return false
	end
	return true
end

function HeavyPunch:StartServer(player: Player)
	local character = player.Character
	if not character then return end
	if not can_start(character) then return end

	local now = os.clock()
	local prev = last_cast[player] or -math.huge
	if (now - prev) < COOLDOWN then
		return
	end
	last_cast[player] = now

	local anim_len = animation_module:GetLength(ANIM_NAME) or 0.7
	casting_window[player] = now + anim_len + 0.5

	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = { character, ANIM_NAME, 1, 1, false }
	})

	task.delay(anim_len + 0.6, function()
		if casting_window[player] and casting_window[player] <= os.clock() then
			casting_window[player] = nil
		end
	end)
end

function HeavyPunch:CastServer(player: Player)
	local expires = casting_window[player]
	if not expires or os.clock() > expires then
		return
	end
	casting_window[player] = nil

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hits = hitbox_module:SpawnBox({
		CFrame = hrp.CFrame * CFrame.new(0, 0, -3),
		Size = Vector3.new(4, 5, 6),
		Filter = {character},
		Visible = true,
	})

	local hitCount = 0
	local unique = {}

	for _, victim in ipairs(hits) do
		if victim and victim ~= character and not unique[victim] then
			unique[victim] = true
			hitCount += 1

			damage_module:Damage({
				Attacker = character,
				Victim = victim,
				Damage = DAMAGE,
				Type = "Ability",
				Knockback = true,
				GuardBreak = true
			})
		end
	end

	if hitCount > 0 then
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = { hrp, VFX_NAME }
		})

		sfx_module:Play(hrp, SFX_NAME, { Volume = 1 })
	end
end

function HeavyPunch.Initialize()
	request_module = shared.Get("Request")
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	sfx_module = shared.Get("SFX")

	if RunService:IsClient() then
		input_module = shared.Get("Input")

		local function on_cast_marker(character)
			if character ~= (localPlayer.Character) then
				return
			end
			if not pending_cast then
				return
			end
			pending_cast = false
			request_module:Send({
				Name = REQ_CAST,
				Class = "Unreliable",
				Perameters = {}
			})
		end

		animation_module:RegisterMarker({
			Name = "Cast",
			Callback = function(character, ...)
				on_cast_marker(character)
			end
		})

		input_module:Register({
			Name = "HeavyPunch_Ability",
			Key = KEY,
			Type = "Began",
			Callback = function()
				pending_cast = true
				task.delay(2, function()
					pending_cast = false
				end)

				request_module:Send({
					Name = REQ_START,
					Class = "Unreliable",
					Perameters = {}
				})
			end
		})
	end

	if RunService:IsServer() then
		damage_module = shared.Get("Damage")

		request_module:Register({
			Name = REQ_START,
			Callback = function(player)
				HeavyPunch:StartServer(player)
			end
		})

		request_module:Register({
			Name = REQ_CAST,
			Callback = function(player)
				HeavyPunch:CastServer(player)
			end
		})
	end
end

return HeavyPunch

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Knocked ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local get_player_and_character = function(user: Instance)
	local player
	local character

	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end

	return player, character
end

local attributes_module
local tasks_module
local sprint_module
local ragdoll_module
local animation_module
local request_module
local equipweapon_module
local knocked_module = {}

knocked_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	tasks_module = shared.Get("Tasks")
	sprint_module = shared.Get("Sprint")
	animation_module = shared.Get("Animation")
	request_module = shared.Get("Request")
	equipweapon_module = shared.Get("EquipWeapon")
end

function knocked_module:Knock(character)
	if runservice:IsClient() then
		return
	end
	
	local player, character = get_player_and_character(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart")
	local character_state = attributes_module:Get(character, "State")
	
	if not humanoid or not humanoidrootpart or character_state == "Knocked" then
		return
	end
	
	if character_state == "Sprinting" and player then
		sprint_module:StopSprinting(player)
	end
	
	equipweapon_module:Unequip(character)
	
	attributes_module:Set(character, "State", "Knocked")
	
	tasks_module.overwrite({
		Player = player or character,
		Name = "Knocked",
		Callback = function()
			if player then
				request_module:Send({
					Name = "Play Animation",
					Class = "Unreliable",
					All = true,
					Perameters = {character, "KnockedIdle", 1, 1, true, Enum.AnimationPriority.Movement}
				})
			else
				local knocked_idle = animation_module.new(character, "KnockedIdle")
				knocked_idle.Priority = Enum.AnimationPriority.Movement
				knocked_idle:Play()
				knocked_idle.Looped = true
			end
			
			local walking, played_animation = false, false
			local previous_position = humanoidrootpart.Position
			while runservice.Heartbeat:Wait() do
				humanoid.WalkSpeed = 3
				humanoid.JumpPower = 0
				
				if not humanoidrootpart.Parent then
					break
				end
				
				local magnitude = (humanoidrootpart.Position - previous_position).Magnitude
				if magnitude >= 0.01 then
					walking = true
					if walking and not played_animation then
						if character:FindFirstChild("Carry Weld") then
							continue
						end
						
						played_animation = true
						
						if player then
							request_module:Send({
								Name = "Play Animation",
								Class = "Unreliable",
								All = true,
								Perameters = {character, "KnockedWalk", 1, 1, true, Enum.AnimationPriority.Movement}
							})
						else
							local knocked_walk = animation_module.new(character, "KnockedWalk")
							knocked_walk.Priority = Enum.AnimationPriority.Movement
							knocked_walk:Play()
							knocked_walk.Looped = true
						end
					end
				else
					walking = false
					played_animation = false
					
					if player then
						request_module:Send({
							Name = "Stop Animation",
							Class = "Unreliable",
							All = true,
							Perameters = {character, "KnockedWalk"}
						})
					else
						local knocked_walk = animation_module:GetSpecificAnimation(character, "KnockedWalk")
						if knocked_walk then
							knocked_walk:Stop()
						end
					end
				end
				previous_position = humanoidrootpart.Position
			end
		end
	})
end

function knocked_module:UnKnock(character)
	if runservice:IsClient() then
		return
	end
	
	local player, character = get_player_and_character(character)
	local humanoid = character:FindFirstChild("Humanoid")
	local character_state = attributes_module:Get(character, "State")

	if not humanoid or character_state ~= "Knocked" then
		return
	end

	attributes_module:Set(character, "State", "Idle")
	
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	
	if player then
		request_module:Send({
			Name = "Stop Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "KnockedWalk"}
		})
		
		request_module:Send({
			Name = "Stop Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "KnockedIdle"}
		})
	else
		local knocked_idle = animation_module:GetSpecificAnimation(character, "KnockedIdle")
		if knocked_idle then
			knocked_idle:Stop()
		end
		
		local knocked_walk = animation_module:GetSpecificAnimation(character, "KnockedWalk")
		if knocked_walk then
			knocked_walk:Stop()
		end
	end
	
	tasks_module.cancel({
		Player = player or character,
		Name = "Knocked"
	})
end

return knocked_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local numbers_to_key = {
	[1] = Enum.KeyCode.Z,
	[2] = Enum.KeyCode.X,
	[3] = Enum.KeyCode.C,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
	[7] = Enum.KeyCode.Seven,
	[8] = Enum.KeyCode.Eight,
	[9] = Enum.KeyCode.Nine,
	[10] = Enum.KeyCode.Zero,
}

local get_player_and_character = function(user: Instance)
	local player
	local character

	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end

	return player, character
end

local input_module
local request_module
local profile_module
local attributes_module
local skills_module = {
	skills = {},
	user_info = {}
}

local get_user_info = function(user)
	local player, character = get_player_and_character(user)

	skills_module.user_info[player or character] = skills_module.user_info[player or character] or {}
	return skills_module.user_info[player or character]
end

skills_module.Initialize = function()
	profile_module = shared.Get("Profile")
	request_module = shared.Get("Request")
	attributes_module = shared.Get("Attributes")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		for key = 1, 10 do
			input_module:Register({
				Name = "Use Skill Slot "..tostring(key),
				Key = numbers_to_key[key],
				Type = "Began",
				Callback = function()
					request_module:Send({
						Name = "Use Skill",
						Class = "Unreliable",
						Perameters = {key}
					})
				end,
			})
		end
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Use Skill",
			Callback = function(player, key)
				skills_module:UseSkill(player, key)
			end,
		})
		
		for index, value in pairs(script:GetChildren()) do
			if value:IsA("Folder") then
				for _, module in pairs(value:GetChildren()) do
					skills_module.skills[module.Name] = require(module)
				end
			else
				skills_module.skills[value.Name] = require(value)
			end
		end
		
		for index, value in pairs(skills_module.skills) do
			if value.Initialize then
				value.Initialize()
			end
		end
	end
end

function skills_module:UseSkill(user, slot)
	local player, character = get_player_and_character(user)
	local user_info = get_user_info(user)
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end
	
	local user_skills
	if player then
		local player_profile = profile_module:GetProfile(player)
		user_skills = player_profile.Data.Skills
	else
		
	end
	
	local skill = user_skills[slot] ; if not skill then return end
	local skill_module = skills_module.skills[skill] ; if not skill_module then return end
	local cooldown = skill_module.Cooldown
	
	user_info[slot] = user_info[slot] or 0
	
	if os.time() - user_info[slot] < cooldown then
		return
	end
	user_info[slot] = os.time()
	
	skill_module:Use(character)
end

return skills_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.Test.Test1 ] ==== --
local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx_module
local sfx_module
local ragdoll_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx_module = shared.Get("VFX")
	sfx_module = shared.Get("SFX")
	ragdoll_module = shared.Get("Ragdoll")
end

function module:Use(character)
	attributes_module:Set(character, "State", "Using Skill") -- this will set the characters state to using a skill
	print("used skill", script.Name)
	attributes_module:Set(character, "State", "Idle") -- this will set the characters state to back to default which is idle
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.TimeMagic.Time Bomb ] ==== --
local debris = game:GetService("Debris")
local replicatedstorage = game:GetService("ReplicatedStorage")

local assets = replicatedstorage:WaitForChild("Assets")
local vfx_assets = assets:WaitForChild("VFX")

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx_module
local sfx_module
local ragdoll_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx_module = shared.Get("VFX")
	sfx_module = shared.Get("SFX")
	ragdoll_module = shared.Get("Ragdoll")
end

function module:Use(character)
	local animation_length = animation_module:GetLength("TimeMagicBomb")
	local event_length = animation_module:GetEventLength("TimeMagicBomb", "Slash")
	
	attributes_module:TempSet(character, "State", "UsingSkill", animation_length)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "TimeMagicBomb", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	sfx_module:Play(character.HumanoidRootPart, "TimeMagicBomb")
	
	task.wait(event_length)
	
	local vfx_part = assets.Part:Clone()
	vfx_part.Name = "TimeMagic"
	vfx_part.Size = Vector3.new(1.477, 1.477, 1.477)
	vfx_part.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
	vfx_part.CanCollide = false
	vfx_part.Anchored = true
	vfx_part.Transparency = 1
	vfx_part.Parent = workspace.Ignore
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicBomb"}
	})
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicCharge"}
	})
	
	local box_hitbox = hitbox_module:SpawnBox({
		CFrame = vfx_part.CFrame * CFrame.new(0, 0, -1),
		Size = Vector3.new(6.6, 5, 7.7),
		Filter = {character},
		Visible = false,
	})
	if #box_hitbox > 0  then
		for _, hit in pairs(box_hitbox) do
			local damage_success = damage_module:Damage({
				Attacker = character,
				Victim = hit,
				Damage = 5,
			})
			if damage_success then
				ragdoll_module:Ragdoll(hit, 2)
			end
		end
	end
	
	task.wait(vfx_assets.TimeMagicCharge.SlashImpact.Spec22.Lifetime.Max)
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicExplosion"}
	})
	debris:AddItem(vfx_part, vfx_module:GetLifetime(vfx_assets.TimeMagicExplosion))
	
	local mag_hitbox = hitbox_module:SpawnMagnitude({
		Position = vfx_part.Position,
		Radius = 12,
		Filter = {character},
		Visible = false,
	})
	if #mag_hitbox > 0  then
		for _, hit in pairs(mag_hitbox) do
			local damage_success = damage_module:Damage({
				Attacker = character,
				Victim = hit,
				Damage = 10,
				Knockback = true,
				Ragdoll = true,
			})
		end
	end
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.TimeMagic.Time Slow ] ==== --
local debris = game:GetService("Debris")
local replicatedstorage = game:GetService("ReplicatedStorage")

local assets = replicatedstorage:WaitForChild("Assets")
local vfx_assets = assets:WaitForChild("VFX")

local slowed_duration = 3

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx_module
local sfx_module
local ragdoll_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx_module = shared.Get("VFX")
	sfx_module = shared.Get("SFX")
	ragdoll_module = shared.Get("Ragdoll")
end

function module:Use(character)
	local animation_length = animation_module:GetLength("TimeMagicSlow")
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "TimeMagicSlow", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	task.wait(animation_length)
	
	sfx_module:Play(character.HumanoidRootPart, "TimeMagicSlow")
	
	local vfx_part = assets.Part:Clone()
	vfx_part.Name = "TimeMagic"
	vfx_part.Size = Vector3.new(95.091, 95.091, 95.091)
	vfx_part.CFrame = character.HumanoidRootPart.CFrame
	vfx_part.CanCollide = false
	vfx_part.Anchored = true
	vfx_part.Transparency = 1
	vfx_part.Parent = workspace.Ignore
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicSlow"}
	})
	debris:AddItem(vfx_part, vfx_module:GetLifetime(vfx_assets.TimeMagicSlow))
	
	local hitbox = hitbox_module:SpawnBox({
		CFrame = vfx_part.CFrame,
		Size = vfx_part.Size,
		Filter = {character},
		Visible = false,
	})
	
	if #hitbox > 0  then
		for _, hit in pairs(hitbox) do
			request_module:Send({
				Name = "Play VFX",
				Class = "Unreliable",
				All = true,
				Perameters = {hit.HumanoidRootPart, "TimeMagicSlowed", slowed_duration}
			})
			
			attributes_module:TempAdd(hit, "Stuns", 1, slowed_duration)
		end
	end
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.TimeMagic.Time Step ] ==== --
local debris = game:GetService("Debris")
local replicatedstorage = game:GetService("ReplicatedStorage")

local assets = replicatedstorage:WaitForChild("Assets")
local vfx_assets = assets:WaitForChild("VFX")

local length_till_teleport = 3.5

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx_module
local sfx_module
local ragdoll_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx_module = shared.Get("VFX")
	sfx_module = shared.Get("SFX")
	ragdoll_module = shared.Get("Ragdoll")
end

function module:Use(character)
	local animation_length = animation_module:GetLength("TimeMagicStep")
	local event_length = animation_module:GetEventLength("TimeMagicStep", "Step", 0.25)
	
	attributes_module:TempSet(character, "State", "UsingSkill", animation_length)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "TimeMagicStep", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	task.wait(event_length)
	
	local teleport_cframe = character.HumanoidRootPart.CFrame
	
	local vfx_part = assets.Part:Clone()
	vfx_part.Name = "TimeMagic"
	vfx_part.Size = Vector3.new(8, 0.3, 8)
	vfx_part.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)
	vfx_part.Transparency = 1
	vfx_part.CanCollide = false
	vfx_part.Anchored = true
	vfx_part.Parent = workspace.Ignore
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicStepStart"}
	})
	
	task.delay(0.1, function()
		sfx_module:Play(vfx_part, "TimeMagicStep")
	end)
	
	local start_time, wait_time = os.time(), 0.75
	while true do
		task.wait(wait_time)
		
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = {vfx_part, "TimeMagicStep"}
		})
		
		if os.time() - start_time >= length_till_teleport then
			break
		end
	end
	
	vfx_part.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "TimeMagicStepEnd"}
	})
	debris:AddItem(vfx_part, vfx_module:GetLifetime(vfx_assets.TimeMagicStepEnd))
	
	character:PivotTo(teleport_cframe)
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.Yami.Dark Pull ] ==== --
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local assets = replicatedstorage:WaitForChild("Assets")
local mesh_assets = assets:WaitForChild("Mesh")
local vfx_assets = assets:WaitForChild("VFX")

local set_massless = function(object, bool)
	for index, value in pairs(object:GetDescendants()) do
		if value:IsA("BasePart") then
			value.Massless = bool
		end
	end
end

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx_module
local sfx_module
local ragdoll_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx_module = shared.Get("VFX")
	sfx_module = shared.Get("SFX")
	ragdoll_module = shared.Get("Ragdoll")
end

function module:Use(character)
	local player = players:GetPlayerFromCharacter(character)
	
	local pull_animation_length = animation_module:GetLength("YamiPull")
	local pull_event_length = animation_module:GetEventLength("YamiPull", "Pull", 0.6)
	local throw_event_length = animation_module:GetEventLength("YamiThrow", "Throw", 0.2)
	
	attributes_module:Set(character, "State", "UsingSkill")
	
	local bodyposition = force_module.set({
		Object = character.HumanoidRootPart,
		Position = character.HumanoidRootPart.Position,
		MaxForce = Vector3.new(math.huge, math.huge, math.huge),
		Speed = 1e8,
	})
	
	local vfx_part = assets.Part:Clone()
	vfx_part.Name = "VFX"
	vfx_part.CanCollide = false
	vfx_part.Anchored = false
	vfx_part.Massless = true
	vfx_part.Transparency = 1
	vfx_part.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(180), 0)
	vfx_part.Size = Vector3.new(6, 6, 20)
	local weld = Instance.new("Weld")
	weld.Part0 = character.HumanoidRootPart
	weld.Part1 = vfx_part
	weld.C1 = CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(180), 0)
	weld.Parent = vfx_part
	vfx_part.Parent = workspace.Ignore
	debris:AddItem(vfx_part, vfx_module:GetLifetime(vfx_assets.YamiPull))
	
	request_module:Send({
		Name = "Emit VFX",
		Class = "Unreliable",
		All = true,
		Perameters = {vfx_part, "YamiPull"}
	})
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "YamiPull", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	sfx_module:Play(character.HumanoidRootPart, "YamiPull")
	
	task.wait(pull_event_length)
	
	local hit = hitbox_module:SpawnBox({
		CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10),
		Size = Vector3.new(6, 6, 20),
		Filter = {character},
		Visible = false,
	})
	if #hit > 0 then
		hit = hit[1]
		
		local hit_state = attributes_module:Get(hit, "State")
		if table.find({"Invincible", "Knocked"}, hit_state) then
			hit = nil
		end
	else
		hit = nil
	end
	
	if hit then
		request_module:Send({
			Name = "Stop Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "YamiPull"}
		})
		
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "YamiThrow", 1, 1, false, Enum.AnimationPriority.Action}
		})
		
		request_module:Send({
			Name = "Trail VFX",
			Class = "Unreliable",
			All = true,
			Perameters = {hit.HumanoidRootPart, 2}
		})
		
		damage_module:Damage({
			Attacker = character,
			Victim = hit,
			Damage = 5,
			GuardBreak = true,
		})
		
		--hit.Humanoid.PlatformStand = true
		ragdoll_module:Ragdoll(hit, 2)
		
		set_massless(hit, true)
		
		local weld = Instance.new("Weld")
		weld.Part0 = character["Right Arm"]
		weld.Part1 = hit.HumanoidRootPart
		weld.C1 = CFrame.Angles(math.rad(-90), math.rad(180), 0) * CFrame.new(0, 1, 0)
		weld.Parent = character
		
		task.wait(throw_event_length)
		
		sfx_module:Play(character.HumanoidRootPart, "YamiThrow")
		
		damage_module:Damage({
			Attacker = character,
			Victim = hit,
			Damage = 5,
			GuardBreak = true,
		})
		
		set_massless(hit, false)
		
		weld:Destroy()
		
		local bodyvelocity = force_module.apply({
			Object = hit.HumanoidRootPart,
			Velocity = character.HumanoidRootPart.CFrame.LookVector,
			Speed = 80,
			Power = 1250,
			MaxForce = Vector3.new(1e6, 1e2, 1e6),
			Lifetime = 0.25,
			Fade = {0.25, "Out"}
		})
	end
	
	bodyposition:Destroy()
	
	attributes_module:Set(character, "State", "Idle")
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.Yami.Dark Slash ] ==== --
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local tweeninfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint)

local assets = replicatedstorage:WaitForChild("Assets")
local mesh_assets = assets:WaitForChild("Mesh")

local set_enabled = function(object, bool)
	for _, instance in pairs(object:GetDescendants()) do
		local success, _ = pcall(function() 
			instance["Enabled"] = instance["Enabled"]
		end)
		
		if success then
			instance.Enabled = bool
		end
	end
end

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local vfx3d_module
local sfx_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	vfx3d_module = shared.Get("3DVFX")
	sfx_module = shared.Get("SFX")
end

function module:Use(character)
	local player = players:GetPlayerFromCharacter(character)
	
	local animation_length = animation_module:GetLength("YamiSlash")
	local event_length = animation_module:GetEventLength("YamiSlash", "Cast", 0.3)
	
	attributes_module:TempSet(character, "State", "UsingSkill", animation_length)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "YamiSlash", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	task.wait(event_length)
	
	sfx_module:Play(character.HumanoidRootPart, "YamiSlash")
	
	local slash = mesh_assets.Slash:Clone()
	slash.Name = character.Name.." Yami Slash"
	slash.Transparency = 0
	slash.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	set_enabled(slash, true)
	slash.Parent = workspace.Ignore
	
	vfx3d_module:FollowingRockTrail({
		Object = slash,
		SetOrientation = character.HumanoidRootPart.Orientation,
		Duration = 0.6,
		Radius = 1.5,
		Size = 2,
		RaycastLength = 5,
	})
	
	task.delay(0.6, function()
		set_enabled(slash, false)
		
		local tween = tweenservice:Create(slash, tweeninfo, {Transparency = 1})
		tween:Play()
		tween.Completed:Wait()
		
		slash:Destroy()
	end)
	
	local already_hit = {}
	while slash.Parent ~= nil do
		slash.CFrame *= CFrame.new(0, 0, -2)
		
		local hitbox = hitbox_module:SpawnBox({
			CFrame = slash.CFrame,
			Size = Vector3.new(11.566, 2.816, 5.911),
			Filter = {character},
			Visible = false,
		})
		
		if #hitbox > 0 then
			for _, hit in pairs(hitbox) do
				if table.find(already_hit, hit) then
					continue
				end
				table.insert(already_hit, hit)
				
				local damage_success = damage_module:Damage({
					Attacker = character,
					Victim = hit,
					Damage = 10,
					Knockback = true,
					Ragdoll = true,
					GuardBreak = true,
					VFX = "YamiExplosion",
				})
			end
		end
		
		runservice.Heartbeat:Wait()
	end
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Skills.Yami.Dark Small Slash ] ==== --
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local tweeninfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint)

local assets = replicatedstorage:WaitForChild("Assets")
local mesh_assets = assets:WaitForChild("Mesh")

local set_enabled = function(object, bool)
	for _, instance in pairs(object:GetDescendants()) do
		local success, _ = pcall(function() 
			instance["Enabled"] = instance["Enabled"]
		end)
		
		if success then
			instance.Enabled = bool
		end
	end
end

local attributes_module
local animation_module
local hitbox_module
local request_module
local force_module
local damage_module
local sfx_module
local module = {
	Cooldown = 1
}

module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	request_module = shared.Get("Request")
	force_module = shared.Get("Force")
	damage_module = shared.Get("Damage")
	sfx_module = shared.Get("SFX")
end

function module:Use(character)
	local player = players:GetPlayerFromCharacter(character)
	
	local animation_length = animation_module:GetLength("YamiSlash")
	local event_length = animation_module:GetEventLength("YamiSlash", "Cast", 0.3)
	
	attributes_module:TempSet(character, "State", "UsingSkill", animation_length)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "YamiSlash", 1, 1, false, Enum.AnimationPriority.Action}
	})
	
	task.wait(event_length)
	
	sfx_module:Play(character.HumanoidRootPart, "YamiSmallSlash")
	
	local slash = mesh_assets.SmallSlash:Clone()
	slash.Name = character.Name.." Yami Slash"
	slash.Transparency = 0
	slash.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
	set_enabled(slash, true)
	slash.Parent = workspace.Ignore
	
	task.delay(0.6, function()
		set_enabled(slash, false)
		
		local tween = tweenservice:Create(slash, tweeninfo, {Transparency = 1})
		tween:Play()
		tween.Completed:Wait()
		
		slash:Destroy()
	end)
	
	local already_hit = {}
	while slash.Parent ~= nil do
		slash.CFrame *= CFrame.new(0, 0, -2)
		
		local hitbox = hitbox_module:SpawnBox({
			CFrame = slash.CFrame,
			Size = Vector3.new(11.566, 2.816, 5.911),
			Filter = {character},
			Visible = false,
		})
		
		if #hitbox > 0 then
			for _, hit in pairs(hitbox) do
				if table.find(already_hit, hit) then
					continue
				end
				table.insert(already_hit, hit)
				
				local damage_success = damage_module:Damage({
					Attacker = character,
					Victim = hit,
					Damage = 10,
					Knockback = true,
					Ragdoll = true,
					VFX = "YamiExplosion",
				})
			end
		end
		
		runservice.Heartbeat:Wait()
	end
end

return module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Swing ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local localplayer = players.LocalPlayer

local gamedata = require(replicatedstorage:WaitForChild("GameData"))
local weapons_data = gamedata.Weapons
local weapons_settings = weapons_data.Settings

local get_player_and_character = function(user: Instance)
	local player
	local character
	
	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end
	
	return player, character
end

local profile_module
local tasks_module
local input_module
local request_module
local attributes_module
local animation_module
local hitbox_module
local damage_module
local sprint_module
local checkattributes_function
local swing_module = {
	user_info = {}
}

local get_user_info = function(user)
	local player, character = get_player_and_character(user)
	
	swing_module.user_info[player or character] = swing_module.user_info[player or character] or {
		previous = math.huge,
		count = 0,
		cooldown = 0,
	}
	return swing_module.user_info[player or character]
end

local get_count = function(user)
	local user_info = get_user_info(user)
	
	local current = os.time()
	local difference =  current - user_info.previous
	user_info.previous = current

	if difference >= weapons_settings.Tick then
		user_info.count = 1
	else
		user_info.count += 1
		if user_info.count > weapons_settings.Count then
			user_info.count = 1
		end
	end
	
	return user_info.count
end

swing_module.Initialize = function()
	profile_module = shared.Get("Profile")
	tasks_module = shared.Get("Tasks")
	request_module = shared.Get("Request")
	animation_module = shared.Get("Animation")
	attributes_module = shared.Get("Attributes")
	hitbox_module = shared.Get("Hitbox")
	sprint_module = shared.Get("Sprint")
	checkattributes_function = shared.Get("CheckAttributes")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Start Swinging",
			Key = Enum.UserInputType.MouseButton1,
			Type = "Began",
			Callback = function()
				swing_module:StartSwinging(localplayer)
			end,
		})
		
		input_module:Register({
			Name = "Stop Swinging",
			Key = Enum.UserInputType.MouseButton1,
			Type = "Ended",
			Callback = function()
				swing_module:StopSwinging(localplayer)
			end
		})
		
		--animation_module:RegisterMarker({
		--	Name = "Hit",
		--	Callback = function(...)
		--		swing_module:Detect(...)
		--	end,
		--})
	end
	
	if runservice:IsServer() then
		damage_module = shared.Get("Damage")
		
		request_module:Register({
			Name = "Swing",
			Callback = function(...)
				swing_module:Swing(...)
			end,
		})
		
		request_module:Register({
			Name = "Detect",
			Callback = function(...)
				swing_module:Detect(...)
			end,
		})
		
		--animation_module:RegisterMarker({
		--	Name = "Hit",
		--	Callback = function(...)
		--		swing_module:Detect(...)
		--	end,
		--})
	end
end

function swing_module:StartSwinging(user)
	local player, character = get_player_and_character(user)
	
	tasks_module.overwrite({
		Player = player or character,
		Name = "Swing",
		Callback = function()
			while true do
				local valid_check = checkattributes_function(character, {
					State = {"Idle", "Sprinting"},
					Stuns = 0,
					WeaponEquipped = true,
				})
				if not valid_check then
					task.wait(0.1)
					continue
				end
				
				if runservice:IsServer() then
					swing_module:Swing(user)
				else
					request_module:Send({
						Name = "Swing",
						Class = "Unreliable",
						Perameters = {}
					})
				end
				
				task.wait(0.1)
			end
		end,
	})
end

function swing_module:StopSwinging(user)
	local player, character = get_player_and_character(user)

	tasks_module.cancel({
		Player = player or character,
		Name = "Swing",
	})
end

function swing_module:Swing(user)
	if runservice:IsClient() then
		return
	end
	
	local player, character = get_player_and_character(user)
	local user_info = get_user_info(user)
	
	local character_state = attributes_module:Get(character, "State")
	
	local valid_check = checkattributes_function(character, {
		State = {"Idle", "Sprinting"},
		Stuns = 0,
		WeaponEquipped = true,
	})
	if not valid_check then
		return
	end
	
	if os.time() - user_info.cooldown < weapons_settings.Cooldown then
		return
	end
	
	if character_state == "Sprinting" then
		sprint_module:StopSprinting(player)
	end
	
	local weapon = "Fists"
	local weapon_settings = weapons_data[weapon]
	local count = get_count(user)
	local swing_animation_name = weapon.."Swing"..count
	
	local swing_animation_length = animation_module:GetLength(swing_animation_name) - 0.15
	local swing_hit_length = animation_module:GetEventLength(swing_animation_name, "Hit", 0.4)
	
	attributes_module:TempSet(character, "State", "Swinging", swing_animation_length / weapon_settings.AnimationSpeed)
	
	if player then
		local player_profile = profile_module:GetProfile(player)
		weapon = player_profile.Data.Weapon
		weapon_settings = weapons_data[weapon]
		
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, swing_animation_name, weapon_settings.AnimationSpeed, weapon_settings.AnimationWeight}
		})
	else
		local swing_animation = animation_module.new(character, swing_animation_name)
		swing_animation:Play()
		swing_animation:AdjustSpeed(weapon_settings.AnimationSpeed)
		swing_animation:AdjustWeight(weapon_settings.AnimationWeight)
	end
	
	task.delay(swing_hit_length / weapon_settings.AnimationSpeed, function()
		swing_module:Detect(character)
	end)
	
	if count >= weapons_settings.Count then
		user_info.cooldown = os.time()
	end
end

function swing_module:Detect(character)
	local player, character = get_player_and_character(character)
	local user_info = get_user_info(character)
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart")
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	if not humanoidrootpart or character_state ~= "Swinging" or character_stuns > 0 then
		return
	end

	local hitbox = hitbox_module:SpawnBox({
		CFrame = character:GetAttribute("CFrame") * CFrame.new(0, 0, -3),
		Size = Vector3.new(4.5, 5, 4),
		Filter = {character},
		Visible = false,
	})
	
	if runservice:IsServer() then
		local weapon = "Fists"
		local weapon_settings = weapons_data[weapon]
		if player then
			local player_profile = profile_module:GetProfile(player)
			weapon = player_profile.Data.Weapon
			weapon_settings = weapons_data[weapon]
		end
		
		if #hitbox > 0 then
			for index, hit in pairs(hitbox) do
				damage_module:Damage({
					Attacker = character,	
					Victim = hit,
					Damage = weapon_settings.Damage,
					Type = "Swing",
					Knockback = user_info.count == weapons_settings.Count,
					Ragdoll = true,
					Animation = "Hit"..user_info.count,
					VFX = "HitBasic",
					SFX = "HitBasic"..user_info.count,
				})
			end
		end
	end
	
	if runservice:IsClient() then
		--if #hitbox > 0 then
		--	request_module:Send({
		--		Name = "Detect",
		--		Class = "Unreliable",
		--		Perameters = {}
		--	})
		--end
	end
end

return swing_module

-- ==== [ ReplicatedStorage.Modules.Core.Combat.Vent ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")

local localplayer = players.LocalPlayer

local get_player_and_character = function(user: Instance)
	local player
	local character

	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end

	return player, character
end

local ragdoll_module
local input_module
local request_module
local hitbox_module
local attributes_module
local damage_module
local force_module
local ragdoll_module
local vent_module = {}

vent_module.Initialize = function()
	request_module = shared.Get("Request")
	hitbox_module = shared.Get("Hitbox")
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Vent",
			Key = Enum.KeyCode.G,
			Type = "Began",
			Callback = function()
				request_module:Send({
					Name = "Vent",
					Class = "Unreliable",
					Perameters = {localplayer}
				})
			end,
		})
	end
	
	if runservice:IsServer() then
		damage_module = shared.Get("Damage")
		ragdoll_module = shared.Get("Ragdoll")
		
		request_module:Register({
			Name = "Vent",
			Callback = function(...)
				vent_module:Vent(...)
			end,
		})
	end
end

function vent_module:Vent(user)
	local player, character = get_player_and_character(user)
	local humanoidrootpart = character.HumanoidRootPart
	
	local character_vent = attributes_module:Get(character, "Vent")
	if character_vent < 100 then
		return
	end
	
	attributes_module:Set(character, "Vent", 0)
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "Vent"}
	})
	
	local hitbox = hitbox_module:SpawnMagnitude({
		Radius = 10,
		Position = character.HumanoidRootPart.Position,
		Filter = {character},
		Visible = true,
	})
	
	if #hitbox <= 0 then
		attributes_module:TempAdd(character, "Stuns", 1, 2.5)
		
		request_module:Send({
			Name = "Stop Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {character, "Vent"}
		})
		
		return
	end
	
	for index, victim in pairs(hitbox) do
		local success_damage = damage_module:Damage({
			Attacker = character,
			Victim = victim,
			Damage = 5,
			Knockback = true,
			Ragdoll = false,
			Animation = "Vented",
			VFX = "HitBasicHard",
		})
		
		if success_damage then
			attributes_module:TempAdd(victim, "Stuns", 1, 2)
		end
	end
end

return vent_module

-- ==== [ ReplicatedStorage.Modules.Core.Movement.AirJump ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer
local previous_press = 0

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local airjump_module = {
	user_info = {}
}

local get_user_info = function(player)
	airjump_module.user_info[player] = airjump_module.user_info[player] or {
		cooldown = 0
	}
	return airjump_module.user_info[player]
end

airjump_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Air Jump",
			Key = Enum.KeyCode.Space,
			Type = "Began",
			Callback = function()
				request_module:Send({
					Name = "Air Jump",
					Class = "Unreliable",
					Perameters = {}
				})
			end,
		})
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Air Jump",
			Callback = function(...)
				airjump_module:Jump(...)
			end,
		})
	end
end

function airjump_module:Jump(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end
	
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	
	local user_info = get_user_info(player)
	if os.time() - user_info.cooldown < 3 then
		return
	end
	user_info.cooldown = os.time()
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "AirJump"}
	})
	
	force_module.apply({
		Object = humanoidrootpart,
		Velocity = humanoidrootpart.CFrame.UpVector,
		Speed = 100,
		MaxForce = Vector3.new(1e6, 1e6, 1e6),
		Power = 1250,
		Fade = {0.05, "Out"},
		Lifetime = "Fade",
	})
end

return airjump_module

-- ==== [ ReplicatedStorage.Modules.Core.Movement.Roll ] ==== --
local runservice = game:GetService("RunService")
local userinputservice = game:GetService("UserInputService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer

local directions = {
	[Enum.KeyCode.W] = "Front",
	[Enum.KeyCode.A] = "Left",
	[Enum.KeyCode.S] = "Back",
	[Enum.KeyCode.D] = "Right"
}
local get_direction = function()
	local behavior = userinputservice.MouseBehavior
	if behavior == Enum.MouseBehavior.LockCenter then
		local keysdown = userinputservice:GetKeysPressed()
		for index, object in pairs(keysdown) do
			local keycode = object.KeyCode
			if directions[keycode] then
				return directions[keycode]
			end
		end

		return "Front"
	else
		return "Front"
	end
end

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local roll_module = {
	cooldown = 0
}

roll_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Roll",
			Key = Enum.KeyCode.Q,
			Type = "Began",
			Callback = function()
				local character = localplayer.Character or localplayer.CharacterAdded:Wait()
				local character_state = attributes_module:Get(character, "State")
				local character_stuns = attributes_module:Get(character, "Stuns")

				if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
					return
				end
				if os.time() - roll_module.cooldown < 3 then
					return
				end
				roll_module.cooldown = os.time()
				
				roll_module:Roll(localplayer, get_direction())
				
				--request_module:Send({
				--	Name = "Roll",
				--	Class = "Unreliable",
				--	Perameters = {get_direction()}
				--})
			end,
		})
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Roll",
			Callback = function(...)
				roll_module:Roll(...)
			end,
		})
	end
end

function roll_module:Roll(player, direction)
	if runservice:IsClient() then
		--return
	end
	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidrootpart then
		return
	end
	
	local velocities = {
		["Front"] = humanoidrootpart.CFrame.LookVector,
		["Left"] = humanoidrootpart.CFrame.RightVector * -1,
		["Right"] = humanoidrootpart.CFrame.RightVector,
		["Back"] = humanoidrootpart.CFrame.LookVector * -1,
	}
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end
	
	local roll_animation_length = animation_module:GetLength("Roll"..direction)
	attributes_module:TempSet(character, "State", "Rolling", roll_animation_length)
	
	--request_module:Send({
	--	Name = "Play Animation",
	--	Class = "Unreliable",
	--	All = true,
	--	Perameters = {character, direction.."Roll"}
	--})
	
	local roll_animation = animation_module.new(character, "Roll"..direction)
	roll_animation.Priority = Enum.AnimationPriority.Action2
	roll_animation:Play()
	roll_animation.Looped = false
	
	local bodyvelocity = force_module.apply({
		Object = humanoidrootpart,
		Velocity = Vector3.new(0, 0, 0),
		MaxForce = Vector3.new(1e6, 1e2, 1e6),
		Speed = 45,
		Power = 1250,
		Fade = {0.25, "Out"},
		Lifetime = "Fade",
	})
	
	while bodyvelocity.Parent do
		bodyvelocity.Velocity = velocities[direction] * 45

		runservice.Heartbeat:Wait()
	end
end

return roll_module

-- ==== [ ReplicatedStorage.Modules.Core.Movement.Sprint ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer
local previous_press = 0

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local sprint_module = {}

sprint_module.Initialize = function()
	print("passed check 0")
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Start Sprinting",
			Key = Enum.KeyCode.W,
			Type = "Began",
			Callback = function()
				local character = localplayer.Character or localplayer.CharacterAdded:Wait()
				local character_state = attributes_module:Get(character, "State")
				local character_stuns = attributes_module:Get(character, "Stuns")
				if not table.find({"Idle", "Rolling"}, character_state) or character_stuns > 0 then
					return
				end
				if os.time() - previous_press > 0.1 then
					previous_press = os.time()
					return
				end
				
				request_module:Send({
					Name = "Start Sprinting",
					Class = "Unreliable",
					Perameters = {}
				})
			end,
		})

		input_module:Register({
			Name = "Stop Sprinting",
			Key = Enum.KeyCode.W,
			Type = "Ended",
			Callback = function()
				local character = localplayer.Character or localplayer.CharacterAdded:Wait()
				local character_state = attributes_module:Get(character, "State")
				if not table.find({"Idle", "Rolling", "Sprinting"}, character_state) then
					return
				end

				request_module:Send({
					Name = "Stop Sprinting",
					Class = "Unreliable",
					Perameters = {}
				})
			end,
		})
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Start Sprinting",
			Callback = function(...)
				sprint_module:StartSprinting(...)
			end,
		})
		
		request_module:Register({
			Name = "Stop Sprinting",
			Callback = function(...)
				sprint_module:StopSprinting(...)
			end,
		})
	end
end

function sprint_module:StartSprinting(player)
	print("passed check 1")
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid")
	print("passed check 2")

	if not humanoid then
		return
	end
	print("passed check 3")

	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	print("passed check 4")

	if not table.find({"Idle", "Rolling", "Carrying"}, character_state) or character_stuns > 0 then --if not idle or rolling, or if stunned, cannot sprint
		return
	end
	print("passed check 5")

	attributes_module:Set(character, "State", "Sprinting")
	
	humanoid.WalkSpeed = 25
	
	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "RunningAnim", 1, 1, true}
	})
end

function sprint_module:StopSprinting(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local character_stuns = attributes_module:Get(character, "Stuns")
	local character_state = attributes_module:Get(character, "State")
	
	if character_state ~= "Sprinting" then
		return
	end
	
	if character_stuns <= 0 then
		attributes_module:Set(character, "State", "Idle")
		
		humanoid.WalkSpeed = 16
	end
	
	request_module:Send({
		Name = "Stop Animation",
		Class = "Unreliable",
		All = true,
		Perameters = {character, "RunningAnim"}
	})
end

return sprint_module

-- ==== [ ReplicatedStorage.Modules.Core.Movement.WallJumping ] ==== --
local runservice = game:GetService("RunService")
local tweenservice = game:GetService("TweenService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer
local holding_keys = {
	Space = false,
	D = false,
	A = false,
	W = false,
}

local side_infos = {
	Right = {
		rotation = CFrame.Angles(0, math.rad(90), 0),
		offset = CFrame.new(-15, 5, 0)
	},
	Left = {
		rotation = CFrame.Angles(0, math.rad(-90), 0),
		offset = CFrame.new(-15, 5, 0)
	}
}

local tweeninfo = TweenInfo.new(2, Enum.EasingStyle.Quint)

local raycast_params = RaycastParams.new()
raycast_params.FilterType = Enum.RaycastFilterType.Exclude

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local walljumping_module = {
	user_info = {}
}

local get_user_info = function(player)
	walljumping_module.user_info[player] = walljumping_module.user_info[player] or {
		cooldown = 0,
		walljumping = false,
		side = "",
	}
	return walljumping_module.user_info[player]
end

local configured
local configure_character = function(character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	
	if configured then
		configured:Disconnect()
	end
	
	configured = runservice.Heartbeat:Connect(function()
		if not character.Parent then
			return
		end
		
		local humanoid_state = humanoid:GetState()
		if humanoid_state == Enum.HumanoidStateType.Freefall and holding_keys.Space then
			walljumping_module:StartWallJumping(localplayer)
		end
	end)
end

walljumping_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")

	if runservice:IsClient() then
		input_module = shared.Get("Input")

		for key, _ in pairs(holding_keys) do
			input_module:Register({
				Name = "Wall Run Holding "..key,
				Key = Enum.KeyCode[key],
				Type = "Began",
				Callback = function()
					holding_keys[key] = true
				end,
			})
		end

		for key, _ in pairs(holding_keys) do
			input_module:Register({
				Name = "Wall Run Holding "..key,
				Key = Enum.KeyCode[key],
				Type = "Ended",
				Callback = function()
					holding_keys[key] = false
					
					if key == "Space" then
						walljumping_module:StopWallJumping(localplayer)
					end
				end,
			})
		end

		local character = localplayer.Character or localplayer.CharacterAdded:Wait()
		configure_character(character)

		localplayer.CharacterAdded:Connect(configure_character)
	end

	if runservice:IsServer() then
	end
end

function walljumping_module:StartWallJumping(player)
	local character:Model = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end

	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end

	local humanoid_state = humanoid:GetState()
	if not table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping}, humanoid_state) then
		return
	end
	
	local user_info = get_user_info(player)
	
	if os.time() - user_info.cooldown < 1 then
		return
	end
	user_info.cooldown = os.time()
	
	raycast_params.FilterDescendantsInstances = workspace.Live:GetChildren()
	local raycast
	local attempted_side = ""
	
	if holding_keys.W and holding_keys.D then
		attempted_side = "Right"
		raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * 4, raycast_params)
	elseif holding_keys.W and holding_keys.A then
		attempted_side = "Left"
		raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * -4, raycast_params)
	end
	
	if raycast then
		user_info.side = attempted_side
		user_info.walljumping = true
		
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		
		--animation_module:StopAll(character)
		
		local walljump_animation = animation_module.new(character, "WallJump"..user_info.side)
		walljump_animation:Play()
		walljump_animation.Looped = false
		
		local side_info = side_infos[user_info.side]
		local face = CFrame.new(raycast.Position + raycast.Normal, raycast.Position) * side_info.rotation
		
		local bodygryo = force_module.rotate({
			Object = humanoidrootpart,
			CFrame = face,
			MaxTorque = Vector3.new(math.huge, math.huge, math.huge),
		})
		
		local bodyposition = force_module.set({
			Object = humanoidrootpart,
			Position = face.Position,
			MaxForce = Vector3.new(math.huge, math.huge, math.huge),
			Power = 4e4,
		})
		
		local alternate = false
		while user_info.walljumping do
			local raycast
			if user_info.side == "Left" then
				attempted_side = "Right"
				raycast = workspace:Raycast(
					humanoidrootpart.Position,
					(humanoidrootpart.CFrame * CFrame.Angles(0, math.rad(120), 0)).LookVector * -40,
					raycast_params
				)
			elseif user_info.side == "Right" then
				attempted_side = "Left"
				raycast = workspace:Raycast(
					humanoidrootpart.Position,
					(humanoidrootpart.CFrame * CFrame.Angles(0, math.rad(-120), 0)).LookVector * -40,
					raycast_params
				)
			end
			
			if raycast then
				local walljump_animation = animation_module.new(character, "WallJump"..user_info.side)
				walljump_animation:Play()
				walljump_animation.Looped = false
				
				--if raycast then
				--	local distance = (humanoidrootpart.Position - raycast.Position).Magnitude
				--	local p = Instance.new("Part")
				--	p.Anchored = true
				--	p.CanCollide = false
				--	p.BrickColor = BrickColor.Red()
				--	p.Material = Enum.Material.Neon
				--	p.Size = Vector3.new(0.1, 0.1, distance)
				--	p.CFrame = CFrame.lookAt(humanoidrootpart.Position, raycast.Position)*CFrame.new(0, 0, -distance/2)
				--	p.Parent = workspace.Ignore
				--	game.Debris:AddItem(p, 0.25)
				--end
				
				local face = CFrame.new(raycast.Position + raycast.Normal, raycast.Position) * side_info.rotation
				face *= CFrame.new(0, 8, 0)
				
				user_info.side = attempted_side
				
				bodyposition.Position = face.Position
				 
				task.wait(0.3)
			else
				if user_info.side == "Left" then
					--local down_raycast = workspace:Raycast(humanoidrootpart.CFrame * CFrame.new(20, 10, 0), humanoidrootpart.CFrame.UpVector * -40, raycast_params)
					--if down_raycast then
					--	print(down_raycast.Instance)
					--end
					bodyposition.Position = (humanoidrootpart.CFrame * CFrame.new(30, 5, -10)).Position
				elseif user_info.side == "Right" then
					bodyposition.Position = (humanoidrootpart.CFrame * CFrame.new(-30, 5, -10)).Position
				end
				
				local walljump_animation = animation_module.new(character, "WallJump"..user_info.side)
				walljump_animation:Play()
				walljump_animation.Looped = false
				
				tweenservice:Create(bodyposition, tweeninfo, {P = 0}):Play()
				
				task.wait(0.25)
				walljumping_module:StopWallJumping(player)
			end
			
			runservice.Heartbeat:Wait()
		end
	end
end

function walljumping_module:StopWallJumping(player)
	local character:Model = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end
	
	local user_info = get_user_info(player)
	if not user_info.walljumping then
		return
	end
	
	user_info.walljumping = false
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	
	local bodyposition = humanoidrootpart:FindFirstChildOfClass("BodyPosition")
	if bodyposition then
		bodyposition:Destroy()
	end
	
	local bodygyro = humanoidrootpart:FindFirstChildOfClass("BodyGyro")
	if bodygyro then
		bodygyro:Destroy()
	end
end

return walljumping_module

-- ==== [ ReplicatedStorage.Modules.Func.CheckAttributes ] ==== --
return function(character, attributes)
	if not character then
		return
	end
	
	if not attributes or type(attributes) ~= "table" then
		return
	end
	
	for attribute, value in pairs(attributes) do
		local check = character:GetAttribute(attribute)
		if type(value) == "table" then
			if not table.find(value, check) then
				return false
			end
		else
			if check ~= value then
				return false
			end
		end
	end
	
	return true
end

-- ==== [ ServerScriptService.Modules.Core.Damage ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")

local attributes_module
local animation_module
local request_module
local sfx_module
local force_module
local knocked_module
local ragdoll_module
local get_up15 -- these two variables (get_up and get_up15) are later set as the task.delay functions that make the victim get up from being knocked
local get_up
local damage_module = {}


damage_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	request_module = shared.Get("Request")
	sfx_module = shared.Get("SFX")
	force_module = shared.Get("Force")
	knocked_module = shared.Get("Knocked")
	ragdoll_module = shared.Get("Ragdoll")
end

function damage_module:Damage(info)
	local attacker = info.Attacker
	local victim = info.Victim
	local damage = info.Damage
	local guardbreak = info.GuardBreak
	local attacktype = info.Type
	local knockback = info.Knockback
	local ragdoll = info.Ragdoll
	local animation = info.Animation
	local vfx = info.VFX
	local sfx = info.SFX
	local unknock_stopped = false
	
	
	
	local force_parry = info.ForceParry
	local force_damage = info.ForceDamage
	
	local attacker_humanoidrootpart = attacker:FindFirstChild("HumanoidRootPart") ; if not attacker_humanoidrootpart then return end

	local victim_humanoid = victim:FindFirstChild("Humanoid") ; if victim_humanoid.Health == 0 then return end
	local victim_humanoidrootpart = victim:FindFirstChild("HumanoidRootPart") ; if not victim_humanoidrootpart then return end
	local victim_state = attributes_module:Get(victim, "State")
	local victim_posture = attributes_module:Get(victim, "Posture")
	local victim_parry = attributes_module:Get(victim, "Parry")
	
	if victim_state == "Invincible" then
		return
	end
	
	victim_humanoidrootpart.CFrame = CFrame.lookAt(victim_humanoidrootpart.Position, attacker_humanoidrootpart.Position)
	
	if force_parry or not force_damage and not guardbreak and victim_parry == true then
		attributes_module:TempAdd(attacker, "Stuns", 1, 2.5)
		
		attributes_module:Mult(attacker, "Vent", 0.75, {Size = "<", Value = 0})
		
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {attacker, "Parried", 1, 1, false, Enum.AnimationPriority.Action4}
		})
		
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {victim, "Parry", 1, 1, false, Enum.AnimationPriority.Action4}
		})
		
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = {attacker_humanoidrootpart, "HitPerfect"}
		})
		
		return
	end

	if not force_damage and not guardbreak and victim_posture > 0 then
		attributes_module:Sub(victim, "Posture", 1)
		if attributes_module:Get(victim, "Posture") <= 0 then
			--attributes_module:Set(victim, "State", "Idle")
			attributes_module:Set(victim, "Posture", 0)
		end
		
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = {victim_humanoidrootpart, "HitBlock"}
		})
		
		if sfx then
			sfx_module:Play(victim_humanoidrootpart, "HitBlock", {Volume = 1})
		end
		
		return
	end
	
	if guardbreak or victim_state == "Blocking" and attributes_module:Get(victim, "Posture") <= 0 then
		attributes_module:Set(victim, "State", "Idle")
		
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {victim, "GuardBreak"}
		})
	end
	
	

	attributes_module:Add(victim, "Vent", 15, {Size = ">", Value = 100})
	attributes_module:TempAdd(victim, "Stuns", 1, 1)
	
	--[[if knockback then
		if ragdoll then
			ragdoll_module:Ragdoll(victim, 2)
		end
		
		force_module.apply({
			Object = victim_humanoidrootpart,
			Velocity = attacker_humanoidrootpart.CFrame.LookVector,
			Speed = 50,
			MaxForce = Vector3.new(1e6, 1e2, 1e6),
			Power = 1250,
			Fade = {0.05, "Out"},
			Lifetime = "Fade",
		})
	end]]
	
	if animation and victim_state ~= "Knocked" then
		request_module:Send({
			Name = "Play Animation",
			Class = "Unreliable",
			All = true,
			Perameters = {victim, animation}
		})
	end
	if vfx then
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = {victim_humanoidrootpart, vfx}
		})
	end
	if sfx then
		sfx_module:Play(victim_humanoidrootpart, sfx, {Volume = 1})
	end
	
	local health_after_damage = victim_humanoid.Health - damage
	
	if health_after_damage <= 0 and victim_state ~= "Knocked" then
		victim_humanoid.Health = 1

		knocked_module:Knock(victim)

		get_up15 = task.delay(15, function()
			if not unknock_stopped then
				knocked_module:UnKnock(victim)
			end

		end)


		--knocked_module:UnKnock(victim)


		return
	elseif health_after_damage <= 0 and victim_state == "Knocked" then
			victim_humanoid.Health = 1
			
			task.cancel(get_up15)
			unknock_stopped = true
			
			if get_up ~= nil then
				print("not nil", get_up)
				task.cancel(get_up)
			else
				print(nil, get_up)
			end
			
			get_up = task.delay(60, function()
				if unknock_stopped then
					unknock_stopped = false
					knocked_module:UnKnock(victim)
				end
			end)
			
			return
	end
	victim_humanoid:TakeDamage(damage)
	
	return "Success"
end

return damage_module

-- ==== [ ServerScriptService.Modules.Core.Inventory ] ==== --
local profile_module
local logger_module
local inventory_module = {}

inventory_module.Initialize = function()
	profile_module = shared.Get("Profile")
	logger_module = shared.Get("Logger")
end

function inventory_module:Add(player, item_type, item_name)
	local profile = profile_module:GetProfile(player)
	if not profile then
		return
	end	
	
	local inventory = profile.Data["Inventory "..item_type]
	if not inventory then
		return
	end
	
	if table.find(inventory, item_name) then
		--print("already owned")
		return
	end
	
	logger_module:Log(1, "Added "..item_name.." to "..player.Name)
	
	profile_module:Insert(player, "Inventory "..item_type, item_name)
end

return inventory_module

-- ==== [ ServerScriptService.Modules.Core.User ] ==== --
local players = game:GetService("Players")

local replicatedstorage = game:GetService("ReplicatedStorage")

local attributes

local user_module = {
	configured = {}
}

user_module.Initialize = function()
	attributes = shared.Get("Attributes")
	
	players.PlayerAdded:Connect(user_module.configure_player)
	
	for index, player in pairs(players:GetPlayers()) do
		user_module.configure_player(player)
		
		local character = player.Character
		if character then
			user_module.configure_character(character)
		end
	end
end

user_module.configure_player = function(player)
	if table.find(user_module.configured, player) then
		return
	end
	table.insert(user_module.configured, player)
	
	player.CharacterAdded:Connect(user_module.configure_character)
end

user_module.configure_character = function(character)
	attributes:Configure(character)
	
	task.wait(0.2)
	character.Parent = workspace.Live
end

return user_module

-- ==== [ ServerScriptService.Modules.Cmdr ] ==== --
local RunService = game:GetService("RunService")
local Util = require(script.Shared:WaitForChild("Util"))

if RunService:IsServer() == false then
	error("Cmdr server module is somehow running on a client!")
end

local Cmdr do
	Cmdr = setmetatable({
		ReplicatedRoot = nil;
		RemoteFunction = nil;
		RemoteEvent = nil;
		Util = Util;
		DefaultCommandsFolder = script.BuiltInCommands;
	}, {
		__index = function (self, k)
			local r = self.Registry[k]
			if r and type(r) == "function" then
				return function (_, ...)
					return r(self.Registry, ...)
				end
			end
		end
	})

	Cmdr.Registry = require(script.Shared.Registry)(Cmdr)
	Cmdr.Dispatcher = require(script.Shared.Dispatcher)(Cmdr)

	require(script.Initialize)(Cmdr)
end

-- Handle command invocations from the clients.
Cmdr.RemoteFunction.OnServerEvent:Connect(function(player, text, options)
	if #text > 100_000 then
		return "Input too long"
	end

	Cmdr.Dispatcher:EvaluateAndRun(text, player, options)
end)

return Cmdr

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.announce ] ==== --
return {
	Name = "announce";
	Aliases = {"m"};
	Description = "Makes a server-wide announcement.";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "string";
			Name = "text";
			Description = "The announcement text.";
		},
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.announceServer ] ==== --
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local Chat = game:GetService("Chat")

return function (context, text)
	local filterResult = TextService:FilterStringAsync(text, context.Executor.UserId, Enum.TextFilterContext.PublicChat)

	for _, player in ipairs(Players:GetPlayers()) do
		if Chat:CanUsersChatAsync(context.Executor.UserId, player.UserId) then
			context:SendEvent(player, "Message", filterResult:GetChatForUserAsync(player.UserId), context.Executor)
		end
	end

	return "Created announcement."
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.gotoPlace ] ==== --
return {
	Name = "goto-place";
	Aliases = {};
	Description = "Teleport to a Roblox place";
	Group = "DefaultAdmin";
	AutoExec = {
		"alias \"follow-player|Join a player in another server\" goto-place $1{players|Players} ${{get-player-place-instance $2{playerId|Target}}}",
		"alias \"rejoin|Rejoin this place. You might end up in a different server.\" goto-place $1{players|Players} ${get-player-place-instance ${me} PlaceId}"
	};
	Args = {
		{
			Type = "players";
			Name = "Players";
			Description = "The players you want to teleport";
		},
		{
			Type = "integer";
			Name = "Place ID";
			Description = "The Place ID you want to teleport to";
		},
		{
			Type = "string";
			Name = "JobId";
			Description = "The specific JobId you want to teleport to";
			Optional = true;
		}
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.gotoPlaceServer ] ==== --
local TeleportService = game:GetService("TeleportService")

return function(context, players, placeId, jobId)
	players = players or { context.Executor }

	if placeId <= 0 then
		return "Invalid place ID"
	elseif jobId == "-" then
		return "Invalid job ID"
	end

	context:Reply("Commencing teleport...")

	if jobId then
		for _, player in ipairs(players) do
			TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
		end
	else
		TeleportService:TeleportAsync(placeId, players)
	end

	return "Teleported."
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.kick ] ==== --
return {
	Name = "kick";
	Aliases = {"boot"};
	Description = "Kicks a player or set of players.";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "players";
			Name = "players";
			Description = "The players to kick.";
		},
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.kickServer ] ==== --
return function (_, players)
	for _, player in pairs(players) do
		player:Kick("Kicked by admin.")
	end

	return ("Kicked %d players."):format(#players)
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.kill ] ==== --
return {
	Name = "kill";
	Aliases = {"slay"};
	Description = "Kills a player or set of players.";
	Group = "DefaultAdmin";
	Args = {
		{
			Type = "players";
			Name = "victims";
			Description = "The players to kill.";
		},
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.killServer ] ==== --
return function (_, players)
	for _, player in pairs(players) do
		if player.Character then
			player.Character:BreakJoints()
		end
	end

	return ("Killed %d players."):format(#players)
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.respawn ] ==== --
return {
	Name = "respawn";
	Description = "Respawns a player or a group of players.";
	Group = "DefaultAdmin";
	AutoExec = {
		"alias \"refresh|Respawns the player and returns them to their previous location.\" var= .refresh_pos ${position $1{player|Player}} && respawn $1 && tp $1 @${{var .refresh_pos}}"
	},
	Args = {
		{
			Type = "players";
			Name = "targets";
			Description = "The players to respawn."
		}
	}
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.respawnServer ] ==== --
return function(_, players)
	for _, player in pairs(players) do
		if player.Character then
			player:LoadCharacter()
		end
	end
	return ("Respawned %d players."):format(#players)
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.teleport ] ==== --
return {
	Name = "teleport";
	Aliases = {"tp"};
	Description = "Teleports a player or set of players to one target.";
	Group = "DefaultAdmin";
	AutoExec = {
		"alias \"bring|Brings a player or set of players to you.\" teleport $1{players|players|The players to bring} ${me}";
		"alias \"to|Teleports you to another player or location.\" teleport ${me} $1{player @ vector3|Destination|The player or location to teleport to}";
	};
	Args = {
		{
			Type = "players";
			Name = "From";
			Description = "The players to teleport";
		},
		{
			Type = "player @ vector3";
			Name = "Destination";
			Description = "The player to teleport to"
		}
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Admin.teleportServer ] ==== --
return function (_, fromPlayers, destination)
	local cframe

	if typeof(destination) == "Instance" then
		if destination.Character and destination.Character:FindFirstChild("HumanoidRootPart") then
			cframe = destination.Character.HumanoidRootPart.CFrame
		else
			return "Target player has no character."
		end
	elseif typeof(destination) == "Vector3" then
		cframe = CFrame.new(destination)
	end

	for _, player in ipairs(fromPlayers) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = cframe
		end
	end

	return ("Teleported %d players."):format(#fromPlayers)
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.blink ] ==== --
return {
	Name = "blink";
	Aliases = {"b"};
	Description = "Teleports you to where your mouse is hovering.";
	Group = "DefaultDebug";
	Args = {};

	ClientRun = function(context)
		-- We implement this here because player position is owned by the client.
		-- No reason to bother the server for this!

		local mouse = context.Executor:GetMouse()
		local character = context.Executor.Character

		if not character then
			return "You don't have a character."
		end

		character:MoveTo(mouse.Hit.p)

		return "Blinked!"
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.fetch ] ==== --
return {
	Name = "fetch";
	Aliases = {};
	Description = "Fetch a value from the Internet";
	Group = "DefaultDebug";
	Args = {
		{
			Type = "url";
			Name = "URL";
			Description = "The URL to fetch.";
		}
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.fetchServer ] ==== --
local HttpService = game:GetService("HttpService")

return function (_, url)
	return HttpService:GetAsync(url)
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.getPlayerPlaceInstance ] ==== --
return {
	Name = "get-player-place-instance";
	Aliases = {};
	Description = "Returns the target player's Place ID and the JobId separated by a space. Returns 0 if the player is offline or something else goes wrong.";
	Group = "DefaultDebug";
	Args = {
		{
			Type = "playerId";
			Name = "Player";
			Description = "Get the place instance of this player";
		},
		function(context)
			return {
				Type = context.Cmdr.Util.MakeEnumType("PlaceInstance Format", {"PlaceIdJobId", "PlaceId", "JobId"}),
				Name = "Format";
				Description = "What data to return. PlaceIdJobId returns both separated by a space.";
				Default = "PlaceIdJobId";
			}
		end
	};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.getPlayerPlaceInstanceServer ] ==== --
local TeleportService = game:GetService("TeleportService")

return function (_, playerId, format)
	format = format or "PlaceIdJobId"

	local ok, _, errorText, placeId, jobId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(playerId)
	end)

	if not ok or (errorText and #errorText > 0) then
		if format == "PlaceIdJobId" then
			return "0" .. " -"
		elseif format == "PlaceId" then
			return "0"
		elseif format == "JobId" then
			return "-"
		end
	end

	if format == "PlaceIdJobId" then
		return placeId .. " " .. jobId
	elseif format == "PlaceId" then
		return tostring(placeId)
	elseif format == "JobId" then
		return tostring(jobId)
	end
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.position ] ==== --
local Players = game:GetService("Players")

return {
	Name = "position";
	Aliases = {"pos"};
	Description = "Returns Vector3 position of you or other players. Empty string is the player has no character.";
	Group = "DefaultDebug";
	Args = {
		{
			Type = "player";
			Name = "Player";
			Description = "The player to report the position of. Omit for your own position.";
			Default = Players.LocalPlayer;
		}
	};

	ClientRun = function(_, player)
		local character = player.Character

		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return ""
		end

		return tostring(character.HumanoidRootPart.Position):gsub("%s", "")
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.thru ] ==== --
return {
	Name = "thru";
	Aliases = {"t", "through"};
	Description = "Teleports you through whatever your mouse is hovering over, placing you equidistantly from the wall.";
	Group = "DefaultDebug";
	Args = {
		{
			Type = "number";
			Name = "Extra distance";
			Description = "Go through the wall an additional X studs.";
			Default = 0;
		}
	};

	ClientRun = function(context, extra)
		-- We implement this here because player position is owned by the client.
		-- No reason to bother the server for this!

		local mouse = context.Executor:GetMouse()
		local character = context.Executor.Character

		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return "You don't have a character."
		end

		local pos = character.HumanoidRootPart.Position
		local diff = (mouse.Hit.p - pos)

		character:MoveTo((diff * 2) + (diff.unit * extra) + pos)

		return "Blinked!"
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.uptime ] ==== --
return {
	Name = "uptime";
	Aliases = {};
	Description = "Returns the amount of time the server has been running.";
	Group = "DefaultDebug";
	Args = {};
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.uptimeServer ] ==== --
local startTime = os.time()

return function ()
	local uptime = os.time() - startTime
	return ("%dd %dh %dm %ds"):format(
		math.floor(uptime / (60 * 60 * 24)),
		math.floor(uptime / (60 * 60)) % 24,
		math.floor(uptime / 60) % 60,
		math.floor(uptime) % 60
	)
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Debug.version ] ==== --
local version = "v1.12.0"

return {
	Name = "version",
	Args = {},
	Description = "Shows the current version of Cmdr",
	Group = "DefaultDebug",

	Run = function()
		return ("Cmdr Version %s"):format(version)
	end,
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.alias ] ==== --
return {
	Name = "alias";
	Aliases = {};
	Description = "Creates a new, single command out of a command and given arguments.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "Alias name";
			Description = "The key or input type you'd like to bind the command to."
		},
		{
			Type = "string";
			Name = "Command string";
			Description = "The command text you want to run. Separate multiple commands with \"&&\". Accept arguments with $1, $2, $3, etc."
		},
	};

	ClientRun = function(context, name, commandString)
		context.Cmdr.Registry:RegisterCommandObject(
			context.Cmdr.Util.MakeAliasCommand(name, commandString),
			true
		)

		return ("Created alias %q"):format(name)
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.bind ] ==== --
local UserInputService = game:GetService("UserInputService")

return {
	Name = "bind";
	Aliases = {};
	Description = "Binds a command string to a key or mouse input.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "userInput ! bindableResource @ player";
			Name = "Input";
			Description = "The key or input type you'd like to bind the command to."
		},
		{
			Type = "command";
			Name = "Command";
			Description = "The command you want to run on this input"
		},
		{
			Type = "string";
			Name = "Arguments";
			Description = "The arguments for the command";
			Default = "";
		}
	};

	ClientRun = function(context, bind, command, arguments)
		local binds = context:GetStore("CMDR_Binds")

		command = command .. " " .. arguments

		if binds[bind] then
			binds[bind]:Disconnect()
		end

		local bindType = context:GetArgument(1).Type.Name

		if bindType == "userInput" then
			binds[bind] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end

				if input.UserInputType == bind or input.KeyCode == bind then
					context:Reply(context.Dispatcher:EvaluateAndRun(context.Cmdr.Util.RunEmbeddedCommands(context.Dispatcher, command)))
				end
			end)
		elseif bindType == "bindableResource" then
			return "Unimplemented..."
		elseif bindType == "player" then
			binds[bind] = bind.Chatted:Connect(function(message)
				local args = { message }
				local chatCommand = context.Cmdr.Util.RunEmbeddedCommands(context.Dispatcher, context.Cmdr.Util.SubstituteArgs(command, args))
				context:Reply(("%s $ %s : %s"):format(
					bind.Name,
					chatCommand,
					context.Dispatcher:EvaluateAndRun(chatCommand)
				), Color3.fromRGB(244, 92, 66))
			end)
		end


		return "Bound command to input."
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.clear ] ==== --
local Players = game:GetService("Players")

return {
	Name = "clear",
	Aliases = {},
	Description = "Clear all lines above the entry line of the Cmdr window.",
	Group = "DefaultUtil",
	Args = {},
	ClientRun = function()
		local player = Players.LocalPlayer
		local gui = player:WaitForChild("PlayerGui"):WaitForChild("Cmdr")
		local frame = gui:WaitForChild("Frame")

		if gui and frame then
			for _, child in pairs(frame:GetChildren()) do
				if child.Name == "Line" and child:IsA("TextBox") then
					child:Destroy()
				end
			end
		end
		return ""
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.convertTimestamp ] ==== --
return {
	Name = "convertTimestamp";
	Aliases = { "date" },
	Description = "Convert a timestamp to a human-readable format.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "number";
			Name = "timestamp";
			Description = "A numerical representation of a specific moment in time.";
			Optional = true
		}
	};
	ClientRun = function(_, timestamp)
		timestamp = timestamp or os.time()
		return `{os.date("%x", timestamp)} {os.date("%X", timestamp)}`
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.echo ] ==== --
return {
	Name = "echo";
	Aliases = {"="};
	Description = "Echoes your text back to you.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "Text";
			Description = "The text."
		},
	};

	Run = function(_, text)
		return text
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.edit ] ==== --
local Players = game:GetService("Players")

local TEXT_BOX_PROPERTIES = {
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(17, 17, 17),
	BackgroundTransparency = 0.05,
	BorderColor3 = Color3.fromRGB(17, 17, 17),
	BorderSizePixel = 20,
	ClearTextOnFocus = false,
	MultiLine = true,
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0.5, 0, 0.4, 0),
	Font = Enum.Font.Code,
	TextColor3 = Color3.fromRGB(241, 241, 241),
	TextWrapped = true,
	TextSize = 18,
	TextXAlignment = "Left",
	TextYAlignment = "Top",
	AutoLocalize = false,
	PlaceholderText = "Right click to exit",
}

local lock

return {
	Name = "edit";
	Aliases = {};
	Description = "Edit text in a TextBox";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "Input text";
			Description = "The text you wish to edit";
			Default = "";
		},
		{
			Type = "string";
			Name = "Delimiter";
			Description = "The character that separates each line";
			Default = ",";
		}
	};

	ClientRun = function(context, text, delimeter)
		lock = lock or context.Cmdr.Util.Mutex()

		local unlock = lock()

		context:Reply("Right-click on the text area to exit.", Color3.fromRGB(158, 158, 158))

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "CmdrEditBox"
		screenGui.ResetOnSpawn = false

		local textBox = Instance.new("TextBox")

		for key, value in pairs(TEXT_BOX_PROPERTIES) do
			textBox[key] = value
		end

		textBox.Text = text:gsub(delimeter, "\n")
		textBox.Parent = screenGui

		screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

		local thread = coroutine.running()

		textBox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				coroutine.resume(thread, textBox.Text:gsub("\n", delimeter))
				screenGui:Destroy()
				unlock()
			end
		end)

		return coroutine.yield()
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.history ] ==== --
return {
	Name = "history";
	Aliases = {};
	AutoExec = {
		"alias \"!|Displays previous command from history.\" run ${history $1{number|Line Number}}";
		"alias \"^|Runs the previous command, replacing all occurrences of A with B.\" run ${run replace ${history -1} $1{string|A} $2{string|B}}";
		"alias \"!!|Reruns the last command.\" ! -1";
	};
	Description = "Displays previous commands from history.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "integer";
			Name = "Line Number";
			Description = "Command line number (can be negative to go from end)"
		},
	};

	ClientRun = function(context, line)
		local history = context.Dispatcher:GetHistory()

		if line <= 0 then
			line = #history + line
		end

		return history[line] or ""
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.hover ] ==== --
local Players = game:GetService("Players")

return {
	Name = "hover";
	Description = "Returns the name of the player you are hovering over.";
	Group = "DefaultUtil";
	Args = {};

	ClientRun = function()
		local mouse = Players.LocalPlayer:GetMouse()
		local target = mouse.Target

		if not target then
			return ""
		end

		local p = Players:GetPlayerFromCharacter(target:FindFirstAncestorOfClass("Model"))

		return p and p.Name or ""
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.jsonArrayDecode ] ==== --
return {
	Name = "json-array-decode";
	Aliases = {};
	Description = "Decodes a JSON Array into a comma-separated list";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "json";
			Name = "JSON";
			Description = "The JSON array."
		},
	};

	ClientRun = function(_, value)
		if type(value) ~= "table" then
			value = { value }
		end

		return table.concat(value, ",")
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.jsonArrayEncode ] ==== --
local HttpService = game:GetService("HttpService")

return {
	Name = "json-array-encode";
	Aliases = {};
	Description = "Encodes a comma-separated list into a JSON array";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "CSV";
			Description = "The comma-separated list"
		},
	};

	Run = function(_, text)
		return HttpService:JSONEncode(text:split(","))
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.len ] ==== --
return {
	Name = "len";
	Aliases = {};
	Description = "Returns the length of a comma-separated list";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "CSV";
			Description = "The comma-separated list"
		}
	};

	Run = function(_, list)
		return #(list:split(","))
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.math ] ==== --
return {
	Name = "math";
	Aliases = {};
	Description = "Perform a math operation on 2 values.";
	Group = "DefaultUtil";
	AutoExec = {
		"alias \"+|Perform an addition.\" math + $1{number|Number} $2{number|Number}";
		"alias \"-|Perform a subtraction.\" math - $1{number|Number} $2{number|Number}";
		"alias \"*|Perform a multiplication.\" math * $1{number|Number} $2{number|Number}";
		"alias \"/|Perform a division.\" math / $1{number|Number} $2{number|Number}";
		"alias \"**|Perform an exponentiation.\" math ** $1{number|Number} $2{number|Number}";
		"alias \"%|Perform a modulus.\" math % $1{number|Number} $2{number|Number}";
	};
	Args = {
		{
			Type = "mathOperator";
			Name = "Operation";
			Description = "A math operation."
		};
		{
			Type = "number";
			Name = "Value";
			Description = "A number value."
		};
		{
			Type = "number";
			Name = "Value";
			Description = "A number value."
		}
	};

	ClientRun = function(_, operation, a, b)
		return operation.Perform(a, b)
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.pick ] ==== --
return {
	Name = "pick";
	Aliases = {};
	Description = "Picks a value out of a comma-separated list.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "integer";
			Name = "Index to pick";
			Description = "The index of the item you want to pick";
		},
		{
			Type = "string";
			Name = "CSV";
			Description = "The comma-separated list"
		}
	};

	Run = function(_, index, list)
		return list:split(",")[index] or ""
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.rand ] ==== --
return {
	Name = "rand";
	Aliases = {};
	Description = "Returns a random number between min and max";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "integer";
			Name = "First number";
			Description = "If second number is nil, random number is between 1 and this value. If second number is provided, number is between this number and the second number."
		},
		{
			Type = "integer";
			Name = "Second number";
			Description = "The upper bound.";
			Optional = true;
		}
	};

	Run = function(_, min, max)
		return tostring(max and math.random(min, max) or math.random(min))
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.replace ] ==== --
return {
	Name = "replace";
	Aliases = {"gsub", "//"};
	Description = "Replaces text A with text B";
	Group = "DefaultUtil";
	AutoExec = {
		"alias \"map|Maps a CSV into another CSV\" replace $1{string|CSV} ([^,]+) \"$2{string|mapped value|Use %1 to insert the element}\"",
		"alias \"join|Joins a CSV with a specified delimiter\" replace $1{string|CSV} , $2{string|Delimiter}"
	},
	Args = {
		{
			Type = "string";
			Name = "Haystack";
			Description = "The source string upon which to perform replacement."
		},
		{
			Type = "string";
			Name = "Needle";
			Description = "The string pattern search for."
		},
		{
			Type = "string";
			Name = "Replacement";
			Description = "The string to replace matches (%1 to insert matches).";
			Default = "";
		},
	};

	Run = function(_, haystack, needle, replacement)
		return haystack:gsub(needle, replacement)
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.resolve ] ==== --
return {
	Name = "resolve";
	Aliases = {};
	Description = "Resolves Argument Value Operators into lists. E.g., resolve players * gives you a list of all players.";
	Group = "DefaultUtil";
	AutoExec = {
		"alias \"me|Displays your username\" resolve players ."
	};
	Args = {
		{
			Type = "type";
			Name = "Type";
			Description = "The type for which to resolve"
		},
		function (context)
			if context:GetArgument(1):Validate() == false then
				return
			end

			return {
				Type = context:GetArgument(1):GetValue();
				Name = "Argument Value Operator";
				Description = "The value operator to resolve. One of: * ** . ? ?N";
				Optional = true;
			}
		end
	};

	Run = function(context)
		return table.concat(context:GetArgument(2).RawSegments, ",")
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.run ] ==== --
return {
	Name = "run";
	Aliases = {">"};
	AutoExec = {
		"alias \"discard|Run a command and discard the output.\" replace ${run $1} .* \\\"\\\""
	};
	Description = "Runs a given command string (replacing embedded commands).";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "Command";
			Description = "The command string to run"
		},
	};

	Run = function(context, commandString)
		return context.Cmdr.Util.RunCommandString(context.Dispatcher, commandString)
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.runLines ] ==== --
return {
	Name = "run-lines";
	Aliases = {};
	Description = "Splits input by newlines and runs each line as its own command. This is used by the init-run command.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "string";
			Name = "Script";
			Description = "The script to parse.";
			Default = "";
		}
	};

	ClientRun = function(context, text)
		if #text == 0 then
			return ""
		end

		local shouldPrintOutput = context.Dispatcher:Run("var", "INIT_PRINT_OUTPUT") ~= ""

		local commands = text:gsub("\n+", "\n"):split("\n")

		for _, command in ipairs(commands) do
			if command:sub(1, 1) == "#" then
				continue
			end

			local output = context.Dispatcher:EvaluateAndRun(command)

			if shouldPrintOutput then
				context:Reply(output)
			end
		end

		return ""
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.runif ] ==== --
local conditions = {
	startsWith = function (text, arg)
		if text:sub(1, #arg) == arg then
			return text:sub(#arg + 1)
		end
	end
}

return {
	Name = "runif";
	Aliases = {};
	Description = "Runs a given command string if a certain condition is met.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "conditionFunction";
			Name = "Condition";
			Description = "The condition function"
		},
		{
			Type = "string";
			Name = "Argument";
			Description = "The argument to the condition function"
		},
		{
			Type = "string";
			Name = "Test against";
			Description = "The text to test against."
		},
		{
			Type = "string";
			Name = "Command";
			Description = "The command string to run if requirements are met. If omitted, return value from condition function is used.";
			Optional = true;
		},
	};

	Run = function(context, condition, arg, testAgainst, command)
		local conditionFunc = conditions[condition]

		if not conditionFunc then
			return ("Condition %q is not valid."):format(condition)
		end

		local text = conditionFunc(testAgainst, arg)

		if text then
			return context.Dispatcher:EvaluateAndRun(context.Cmdr.Util.RunEmbeddedCommands(context.Dispatcher, command or text))
		end

		return ""
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.unbind ] ==== --
return {
	Name = "unbind";
	Aliases = {};
	Description = "Unbinds an input previously bound with Bind";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "userInput ! bindableResource @ player";
			Name = "Input/Key";
			Description = "The key or input type you'd like to unbind."
		}
	};

	ClientRun = function(context, inputEnum)
		local binds = context:GetStore("CMDR_Binds")

		if binds[inputEnum] then
			binds[inputEnum]:Disconnect()
			binds[inputEnum] = nil
			return "Unbound command from input."
		else
			return "That input wasn't bound."
		end
	end
}

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.var ] ==== --
return {
	Name = "var";
	Aliases = {};
	Description = "Gets a stored variable.";
	Group = "DefaultUtil";
	AutoExec = {
		"alias \"init-edit|Edit your initialization script\" edit ${var init} \\\\\n && var= init ||",
		"alias \"init-run|Re-runs the initialization script manually.\" run-lines ${var init}",
		"init-run",
	},
	Args = {
		{
			Type = "storedKey";
			Name = "Key";
			Description = "The key to get, retrieved from your user data store. Keys prefixed with . are not saved. Keys prefixed with $ are game-wide. Keys prefixed with $. are game-wide and non-saved.";
		}
	};

	ClientRun = function(context, key)
		context:GetStore("vars_used")[key] = true
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.varServer ] ==== --
local DataStoreService = game:GetService("DataStoreService")

local queue = {}
local DataStoresActive, DataStore
task.spawn(function()
	DataStoresActive, DataStore = pcall(function()
		local DataStore = DataStoreService:GetDataStore("_package/eryn.io/Cmdr")
		DataStore:GetAsync("test_key")
		return DataStore
	end)

	while #queue > 0 do
		coroutine.resume(table.remove(queue, 1))
	end
end)

return function (context, key)
	if DataStoresActive == nil then
		table.insert(queue, coroutine.running())
		coroutine.yield()
	end

	local gameWide = false
	local saved = true

	if key:sub(1, 1) == "$" then
		key = key:sub(2)
		gameWide = true
	end

	if key:sub(1, 1) == "." then
		key = key:sub(2)
		saved = false
	end

	if saved and not DataStoresActive then
		return "# You must publish this place to the web to use saved keys."
	end

	local namespace = "var_" .. (gameWide and "global" or tostring(context.Executor.UserId))

	if saved then
		local keyPath = namespace .. "_" .. key
		local value = DataStore:GetAsync(keyPath) or ""
		if type(value) == "table" then
			return table.concat(value, ",") or ""
		end
		return value
	else
		local store = context:GetStore(namespace)

		local value = store[key] or ""

		if type(value) == "table" then
			return table.concat(value, ",") or ""
		end

		return value
	end
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.varSet ] ==== --
return {
	Name = "var=";
	Aliases = {};
	Description = "Sets a stored value.";
	Group = "DefaultUtil";
	Args = {
		{
			Type = "storedKey";
			Name = "Key";
			Description = "The key to set, saved in your user data store. Keys prefixed with . are not saved. Keys prefixed with $ are game-wide. Keys prefixed with $. are game-wide and non-saved.";
		},
		{
			Type = "string";
			Name = "Value";
			Description = "Value or values to set.";
			Default = "";
		}
	};

	ClientRun = function(context, key)
		context:GetStore("vars_used")[key] = true
	end
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.Utility.varSetServer ] ==== --
local DataStoreService = game:GetService("DataStoreService")

local queue = {}
local DataStoresActive, DataStore
task.spawn(function()
	DataStoresActive, DataStore = pcall(function()
		local DataStore = DataStoreService:GetDataStore("_package/eryn.io/Cmdr")
		DataStore:GetAsync("test_key")
		return DataStore
	end)

	while #queue > 0 do
		coroutine.resume(table.remove(queue, 1))
	end
end)

return function (context, key, value)
	if DataStoresActive == nil then
		table.insert(queue, coroutine.running())
		coroutine.yield()
	end

	local gameWide = false
	local saved = true

	if key:sub(1, 1) == "$" then
		key = key:sub(2)
		gameWide = true
	end

	if key:sub(1, 1) == "." then
		key = key:sub(2)
		saved = false
	end

	if saved and not DataStoresActive then
		return "# You must publish this place to the web to use saved keys."
	end

	local namespace = "var_" .. (gameWide and "global" or tostring(context.Executor.UserId))

	if saved then
		local keyPath = namespace .. "_" .. key

		DataStore:SetAsync(keyPath, value)

		if type(value) == "table" then
			return table.concat(value, ",") or ""
		end

		return value
	else
		local store = context:GetStore(namespace)

		store[key] = value

		if type(value) == "table" then
			return table.concat(value, ",") or ""
		end

		return value
	end
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInCommands.help ] ==== --
local ARGUMENT_SHORTHANDS = [[
Argument Shorthands
-------------------
.   Me/Self
*   All/Everyone
**  Others
?   Random
?N  List of N random values
]]

local TIPS = [[
Tips
----
• Utilize the Tab key to automatically complete commands
• Easily select and copy command output
]]

return {
	Name = "help";
	Description = "Displays a list of all commands, or inspects one command.";
	Group = "Help";
	Args = {
		{
			Type = "command";
			Name = "Command";
			Description = "The command to view information on";
			Optional = true;
		},
	};

	ClientRun = function (context, commandName)
		if commandName then
			local command = context.Cmdr.Registry:GetCommand(commandName)
			context:Reply(`Command: {command.Name}`, Color3.fromRGB(230, 126, 34))
			if command.Aliases and #command.Aliases > 0 then
				context:Reply(`Aliases: {table.concat(command.Aliases, ", ")}`, Color3.fromRGB(230, 230, 230))
			end
			context:Reply(command.Description, Color3.fromRGB(230, 230, 230))
			for i, arg in ipairs(command.Args) do
				context:Reply(
					`#{i} {arg.Name}{if arg.Optional == true then "?" else ""}: {arg.Type} - {arg.Description}`
				)
			end
		else
			context:Reply(ARGUMENT_SHORTHANDS)
			context:Reply(TIPS)

			local commands = context.Cmdr.Registry:GetCommands()
			table.sort(commands, function(a, b)
				return if a.Group and b.Group then a.Group < b.Group else a.Group
			end)
			local lastGroup
			for _, command in ipairs(commands) do
				command.Group = command.Group or "No Group"
				if lastGroup ~= command.Group then
					context:Reply(`\n{command.Group}\n{string.rep("-", #command.Group)}`)
					lastGroup = command.Group
				end
				context:Reply(if command.Description then `{command.Name} - {command.Description}` else command.Name)
			end
		end
		return ""
	end;
}


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.BindableResource ] ==== --
return function (registry)
	registry:RegisterType("bindableResource", registry.Cmdr.Util.MakeEnumType("BindableResource", {"Chat"}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.BrickColor ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local brickColorNames = {
    "White", "Grey", "Light yellow", "Brick yellow", "Light green (Mint)", "Light reddish violet", "Pastel Blue",
    "Light orange brown", "Nougat", "Bright red", "Med. reddish violet", "Bright blue", "Bright yellow", "Earth orange",
    "Black", "Dark grey", "Dark green", "Medium green", "Lig. Yellowich orange", "Bright green", "Dark orange",
    "Light bluish violet", "Transparent", "Tr. Red", "Tr. Lg blue", "Tr. Blue", "Tr. Yellow", "Light blue",
    "Tr. Flu. Reddish orange", "Tr. Green", "Tr. Flu. Green", "Phosph. White", "Light red", "Medium red", "Medium blue",
    "Light grey", "Bright violet", "Br. yellowish orange", "Bright orange", "Bright bluish green", "Earth yellow",
    "Bright bluish violet", "Tr. Brown", "Medium bluish violet", "Tr. Medi. reddish violet", "Med. yellowish green",
    "Med. bluish green", "Light bluish green", "Br. yellowish green", "Lig. yellowish green", "Med. yellowish orange",
    "Br. reddish orange", "Bright reddish violet", "Light orange", "Tr. Bright bluish violet", "Gold", "Dark nougat",
    "Silver", "Neon orange", "Neon green", "Sand blue", "Sand violet", "Medium orange", "Sand yellow", "Earth blue",
    "Earth green", "Tr. Flu. Blue", "Sand blue metallic", "Sand violet metallic", "Sand yellow metallic",
    "Dark grey metallic", "Black metallic", "Light grey metallic", "Sand green", "Sand red", "Dark red",
    "Tr. Flu. Yellow", "Tr. Flu. Red", "Gun metallic", "Red flip/flop", "Yellow flip/flop", "Silver flip/flop", "Curry",
    "Fire Yellow", "Flame yellowish orange", "Reddish brown", "Flame reddish orange", "Medium stone grey", "Royal blue",
    "Dark Royal blue", "Bright reddish lilac", "Dark stone grey", "Lemon metalic", "Light stone grey", "Dark Curry",
    "Faded green", "Turquoise", "Light Royal blue", "Medium Royal blue", "Rust", "Brown", "Reddish lilac", "Lilac",
    "Light lilac", "Bright purple", "Light purple", "Light pink", "Light brick yellow", "Warm yellowish orange",
    "Cool yellow", "Dove blue", "Medium lilac", "Slime green", "Smoky grey", "Dark blue", "Parsley green", "Steel blue",
    "Storm blue", "Lapis", "Dark indigo", "Sea green", "Shamrock", "Fossil", "Mulberry", "Forest green", "Cadet blue",
    "Electric blue", "Eggplant", "Moss", "Artichoke", "Sage green", "Ghost grey", "Lilac", "Plum", "Olivine",
    "Laurel green", "Quill grey", "Crimson", "Mint", "Baby blue", "Carnation pink", "Persimmon", "Maroon", "Gold",
    "Daisy orange", "Pearl", "Fog", "Salmon", "Terra Cotta", "Cocoa", "Wheat", "Buttermilk", "Mauve", "Sunrise",
    "Tawny", "Rust", "Cashmere", "Khaki", "Lily white", "Seashell", "Burgundy", "Cork", "Burlap", "Beige", "Oyster",
    "Pine Cone", "Fawn brown", "Hurricane grey", "Cloudy grey", "Linen", "Copper", "Dirt brown", "Bronze", "Flint",
    "Dark taupe", "Burnt Sienna", "Institutional white", "Mid gray", "Really black", "Really red", "Deep orange",
    "Alder", "Dusty Rose", "Olive", "New Yeller", "Really blue", "Navy blue", "Deep blue", "Cyan", "CGA brown",
    "Magenta", "Pink", "Deep orange", "Teal", "Toothpaste", "Lime green", "Camo", "Grime", "Lavender",
    "Pastel light blue", "Pastel orange", "Pastel violet", "Pastel blue-green", "Pastel green", "Pastel yellow",
    "Pastel brown", "Royal purple", "Hot pink"
}

local brickColorFinder = Util.MakeFuzzyFinder(brickColorNames)

local brickColorType =  {
	Prefixes = "% teamColor";

    Transform = function(text)
        local brickColors = {}
        for i, name in pairs(brickColorFinder(text)) do
            brickColors[i] = BrickColor.new(name)
        end
        return brickColors
    end;

    Validate = function(brickColors)
        return #brickColors > 0, "No valid brick colors with that name could be found."
    end;

    Autocomplete = function(brickColors)
        return Util.GetNames(brickColors)
    end;

    Parse = function(brickColors)
        return brickColors[1]
    end;
}

local brickColor3Type = {
	Transform = brickColorType.Transform;
	Validate = brickColorType.Validate;
	Autocomplete = brickColorType.Autocomplete;

	Parse = function(brickColors)
		return brickColors[1].Color
	end;
}

return function(registry)
    registry:RegisterType("brickColor", brickColorType)
	registry:RegisterType("brickColors", Util.MakeListableType(brickColorType, {
		Prefixes = "% teamColors"
	}))

	registry:RegisterType("brickColor3", brickColor3Type)
    registry:RegisterType("brickColor3s", Util.MakeListableType(brickColor3Type))
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Color3 ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local color3Type = Util.MakeSequenceType({
	Prefixes = "# hexColor3 ! brickColor3";
	ValidateEach = function(value, i)
		if value == nil then
			return false, ("Invalid or missing number at position %d in Color3 type."):format(i)
		elseif value < 0 or value > 255 then
			return false, ("Number out of acceptable range 0-255 at position %d in Color3 type."):format(i)
		elseif value % 1 ~= 0 then
			return false, ("Number is not an integer at position %d in Color3 type."):format(i)
		end

		return true
	end;
	TransformEach = tonumber;
	Constructor = Color3.fromRGB;
	Length = 3;
})

local function parseHexDigit(x)
	if #x == 1 then
		x = x .. x
	end

	return tonumber(x, 16)
end

local hexColor3Type = {
	Transform = function(text)
		local r, g, b = text:match("^#?(%x%x?)(%x%x?)(%x%x?)$")
		return Util.Each(parseHexDigit, r, g, b)
	end;

	Validate = function(r, g, b)
		return r ~= nil and g ~= nil and b ~= nil, "Invalid hex color"
	end;

	Parse = function(...)
		return Color3.fromRGB(...)
	end;
}

return function (cmdr)
	cmdr:RegisterType("color3", color3Type)
	cmdr:RegisterType("color3s", Util.MakeListableType(color3Type, {
		Prefixes = "# hexColor3s ! brickColor3s"
	}))

	cmdr:RegisterType("hexColor3", hexColor3Type)
	cmdr:RegisterType("hexColor3s", Util.MakeListableType(hexColor3Type))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Command ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

return function (cmdr)
	local commandType = {
		Transform = function (text)
			local findCommand = Util.MakeFuzzyFinder(cmdr:GetCommandNames())

			return findCommand(text)
		end;

		Validate = function (commands)
			return #commands > 0, "No command with that name could be found."
		end;

		Autocomplete = function (commands)
			return commands
		end;

		Parse = function (commands)
			return commands[1]
		end;
	}

	cmdr:RegisterType("command", commandType)
	cmdr:RegisterType("commands", Util.MakeListableType(commandType))
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.ConditionFunction ] ==== --
return function (registry)
	registry:RegisterType("conditionFunction", registry.Cmdr.Util.MakeEnumType("ConditionFunction", {"startsWith"}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Duration ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local unitTable = {
    Years = 31556926,
    Months = 2629744,
    Weeks = 604800,
    Days = 86400,
    Hours = 3600,
    Minutes = 60,
    Seconds = 1
}

local searchKeyTable = {}
for key, _ in pairs(unitTable) do
    table.insert(searchKeyTable, key)
end
local unitFinder = Util.MakeFuzzyFinder(searchKeyTable)

local function stringToSecondDuration(stringDuration)
    -- The duration cannot be null or an empty string.
    if stringDuration == nil or stringDuration == "" then
        return nil
    end
    -- Allow 0 by itself (without a unit) to indicate 0 seconds
    local durationNum = tonumber(stringDuration)
    if durationNum and durationNum == 0 then
        return 0, 0, true
    end
    -- The duration must end with a unit,
    -- if it doesn't then return true as the fourth value to indicate the need to offer autocomplete for units.
    local endOnlyString = stringDuration:gsub("-?%d+%a+", "")
    local endNumber = endOnlyString:match("-?%d+")
    if endNumber then
        return nil, tonumber(endNumber), true
    end
    local seconds = nil
    local rawNum, rawUnit
    for rawComponent in stringDuration:gmatch("-?%d+%a+") do
        rawNum, rawUnit = rawComponent:match("(-?%d+)(%a+)")
        local unitNames = unitFinder(rawUnit)
        -- There were no matching units, it's invalid. Return the parsed number to be used for autocomplete
        if #unitNames == 0 then
            return nil, tonumber(rawNum)
        end
        if seconds == nil then seconds = 0 end
        -- While it was already defaulting to use minutes when using just "m", this does it without worrying
        -- about any consistency between list ordering.
        seconds = seconds + (rawUnit:lower() == "m" and 60 or unitTable[unitNames[1]]) * tonumber(rawNum)
    end
    -- If no durations were provided, return nil.
    if seconds == nil then
        return nil
    else
        return seconds, tonumber(rawNum)
    end
end

local function mapUnits(units, rawText, lastNumber, subStart)
    subStart = subStart or 1
    local returnTable = {}
    for i, unit in pairs(units) do
        if lastNumber == 1 then
            returnTable[i] = rawText .. unit:sub(subStart, #unit - 1)
        else
            returnTable[i] = rawText .. unit:sub(subStart)
        end
    end
    return returnTable
end

local durationType = {
    Transform = function(text)
        return text, stringToSecondDuration(text)
    end;

    Validate = function(_, duration)
        return duration ~= nil
    end;

    Autocomplete = function(rawText, duration, lastNumber, isUnitMissing, matchedUnits)
        local returnTable = {}
        if isUnitMissing or matchedUnits then
            local unitsTable = isUnitMissing == true and unitFinder("") or matchedUnits
            if isUnitMissing == true then
                -- Concat the entire unit name to existing text.
                returnTable = mapUnits(unitsTable, rawText, lastNumber)
            else
                -- Concat the rest of the unit based on what already exists of the unit name.
                local existingUnitLength = rawText:match("^.*(%a+)$"):len()
                returnTable = mapUnits(unitsTable, rawText, existingUnitLength + 1)
            end
        elseif duration ~= nil then
            local endingUnit = rawText:match("^.*-?%d+(%a+)%s?$")
            -- Assume there is a singular match at this point
            local fuzzyUnits = unitFinder(endingUnit)
            -- List all possible fuzzy matches. This is for the Minutes/Months ambiguity case.
            returnTable = mapUnits(fuzzyUnits, rawText, lastNumber, #endingUnit + 1)
            -- Sort alphabetically in the Minutes/Months case, so Minutes are displayed on top.
            table.sort(returnTable)
        end
        return returnTable
    end;

    Parse = function(_, duration)
        return duration
    end;
}

return function(registry)
    registry:RegisterType("duration", durationType)
    registry:RegisterType("durations", Util.MakeListableType(durationType))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.JSON ] ==== --
local HttpService = game:GetService("HttpService")

return function(registry)
	registry:RegisterType("json", {
		Validate = function(text)
			return pcall(HttpService.JSONDecode, HttpService, text)
		end;

		Parse = function(text)
			return HttpService:JSONDecode(text)
		end
	})
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.MathOperator ] ==== --
return function(registry)
	registry:RegisterType("mathOperator", registry.Cmdr.Util.MakeEnumType("Math Operator", {
		{
			Name = "+";
			Perform = function(a, b)
				return a + b
			end
		};
		{
			Name = "-";
			Perform = function(a, b)
				return a - b
			end
		};
		{
			Name = "*";
			Perform = function(a, b)
				return a * b
			end
		};
		{
			Name = "/";
			Perform = function(a, b)
				return a / b
			end
		};
		{
			Name = "**";
			Perform = function(a, b)
				return a ^ b
			end
		};
		{
			Name = "%";
			Perform = function(a, b)
				return a % b
			end
		}
	}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Player ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)
local Players = game:GetService("Players")

local playerType = {
	Transform = function (text)
		local findPlayer = Util.MakeFuzzyFinder(Players:GetPlayers())

		return findPlayer(text)
	end;

	Validate = function (players)
		return #players > 0, "No player with that name could be found."
	end;

	Autocomplete = function (players)
		return Util.GetNames(players)
	end;

	Parse = function (players)
		return players[1]
	end;

	Default = function(player)
		return player.Name
	end;

	ArgumentOperatorAliases = {
		me = ".";
		all = "*";
		others = "**";
		random = "?";
	};
}

return function (cmdr)
	cmdr:RegisterType("player", playerType)
	cmdr:RegisterType("players", Util.MakeListableType(playerType, {
		Prefixes = "% teamPlayers";
	}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.PlayerId ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)
local Players = game:GetService("Players")

local nameCache = {}
local function getUserId(name)
	if nameCache[name] then
		return nameCache[name]
	elseif Players:FindFirstChild(name) then
		nameCache[name] = Players[name].UserId
		return Players[name].UserId
	else
		local ok, userid = pcall(Players.GetUserIdFromNameAsync, Players, name)

		if not ok then
			return nil
		end

		nameCache[name] = userid
		return userid
	end
end

local playerIdType = {
	DisplayName = "Full Player Name";
	Prefixes = "# integer";

	Transform = function (text)
		local findPlayer = Util.MakeFuzzyFinder(Players:GetPlayers())

		return text, findPlayer(text)
	end;

	ValidateOnce = function (text)
		return getUserId(text) ~= nil, "No player with that name could be found."
	end;

	Autocomplete = function (_, players)
		return Util.GetNames(players)
	end;

	Parse = function (text)
		return getUserId(text)
	end;

	Default = function(player)
		return player.Name
	end;

	ArgumentOperatorAliases = {
		me = ".";
		all = "*";
		others = "**";
		random = "?";
	};
}

return function (cmdr)
	cmdr:RegisterType("playerId", playerIdType)
	cmdr:RegisterType("playerIds", Util.MakeListableType(playerIdType, {
		Prefixes = "# integers"
	}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Primitives ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local stringType = {
	Validate = function (value)
		return value ~= nil
	end;

	Parse = function (value)
		return tostring(value)
	end;
}

local numberType = {
	Transform = function (text)
		return tonumber(text)
	end;

	Validate = function (value)
		return value ~= nil
	end;

	Parse = function (value)
		return value
	end;
}

local intType = {
	Transform = function (text)
		return tonumber(text)
	end;

	Validate = function (value)
		return value ~= nil and value == math.floor(value), "Only whole numbers are valid."
	end;

	Parse = function (value)
		return value
	end
}

local positiveIntType = {
	Transform = function (text)
		return tonumber(text)
	end,

	Validate = function (value)
		return value ~= nil and value == math.floor(value) and value > 0, "Only positive whole numbers are valid."
	end,

	Parse = function (value)
		return value
	end,
}

local nonNegativeIntType = {
	Transform = function (text)
		return tonumber(text)
	end,

	Validate = function (value)
		return value ~= nil and value == math.floor(value) and value >= 0, "Only non-negative whole numbers are valid."
	end,

	Parse = function (value)
		return value
	end,
}

local byteType = {
	Transform = function (text)
		return tonumber(text)
	end,

	Validate = function (value)
		return value ~= nil and value == math.floor(value) and value >= 0 and value <= 255, "Only bytes are valid."
	end,

	Parse = function (value)
		return value
	end,
}

local digitType = {
	Transform = function (text)
		return tonumber(text)
	end,

	Validate = function (value)
		return value ~= nil and value == math.floor(value) and value >= 0 and value <= 9, "Only digits are valid."
	end,

	Parse = function (value)
		return value
	end,
}

local boolType do
	local truthy = Util.MakeDictionary({"true", "t", "yes", "y", "on", "enable", "enabled", "1", "+"});
	local falsy = Util.MakeDictionary({"false"; "f"; "no"; "n"; "off"; "disable"; "disabled"; "0"; "-"});

	boolType = {
		Transform = function (text)
			return text:lower()
		end;

		Validate = function (value)
			return truthy[value] ~= nil or falsy[value] ~= nil, "Please use true/yes/on or false/no/off."
		end;

		Parse = function (value)
			if truthy[value] then
				return true
			elseif falsy[value] then
				return false
			else
				return nil
			end
		end;
	}
end

return function (cmdr)
	cmdr:RegisterType("string", stringType)
	cmdr:RegisterType("number", numberType)
	cmdr:RegisterType("integer", intType)
	cmdr:RegisterType("positiveInteger", positiveIntType)
	cmdr:RegisterType("nonNegativeInteger", nonNegativeIntType)
	cmdr:RegisterType("byte", byteType)
	cmdr:RegisterType("digit", digitType)
	cmdr:RegisterType("boolean", boolType)

	cmdr:RegisterType("strings", Util.MakeListableType(stringType))
	cmdr:RegisterType("numbers", Util.MakeListableType(numberType))
	cmdr:RegisterType("integers", Util.MakeListableType(intType))
	cmdr:RegisterType("positiveIntegers", Util.MakeListableType(positiveIntType))
	cmdr:RegisterType("nonNegativeIntegers", Util.MakeListableType(nonNegativeIntType))
	cmdr:RegisterType("bytes", Util.MakeListableType(byteType))
	cmdr:RegisterType("digits", Util.MakeListableType(digitType))
	cmdr:RegisterType("booleans", Util.MakeListableType(boolType))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.SkillName ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local r = game:GetService("ReplicatedStorage")
local m = r:WaitForChild("Modules")
local c = m:WaitForChild("Core")
local co = c:WaitForChild("Combat")
local skills = co:WaitForChild("Skills")

local return_list = {}

for i,v in pairs(skills:GetDescendants()) do
	if v:IsA("ModuleScript") then
		table.insert(return_list, v.Name)
	end
end

return function(registry)
	registry:RegisterType("skillname", registry.Cmdr.Util.MakeEnumType("SkillName", return_list))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.SkillSet ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local r = game:GetService("ReplicatedStorage")
local m = r:WaitForChild("Modules")
local c = m:WaitForChild("Core")
local co = c:WaitForChild("Combat")
local skills = co:WaitForChild("Skills")

local return_list = {}

for i,v in pairs(skills:GetChildren()) do
	table.insert(return_list, v.Name)
end

return function(registry)
	registry:RegisterType("skillset", registry.Cmdr.Util.MakeEnumType("SkillSet", return_list))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.SkillSlot ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

return function(registry)
	registry:RegisterType("skillslot", registry.Cmdr.Util.MakeEnumType("SkillSlots", {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.StoredKey ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local VALID_STORED_KEY_NAME_PATTERNS = {
	"^%a[%w_]*$",
	"^%$%a[%w_]*$",
	"^%.%a[%w_]*$",
	"^%$%.%a[%w_]*$",
}

return function (registry)
	local storedKeyType = {
		Autocomplete = function(text)
			local find = registry.Cmdr.Util.MakeFuzzyFinder(registry.Cmdr.Util.DictionaryKeys(registry:GetStore("vars_used") or {}))

			return find(text)
		end;

		Validate = function(text)
			for _, pattern in ipairs(VALID_STORED_KEY_NAME_PATTERNS) do
				if text:match(pattern) then
					return true
				end
			end

			return false, "Key names must start with an optional modifier: . $ or $. and must begin with a letter."
		end;

		Parse = function(text)
			return text
		end;
	}
	registry:RegisterType("storedKey", storedKeyType)
	registry:RegisterType("storedKeys", Util.MakeListableType(storedKeyType))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Team ] ==== --
local Teams = game:GetService("Teams")
local Util = require(script.Parent.Parent.Shared.Util)

local teamType = {
	Transform = function (text)
		local findTeam = Util.MakeFuzzyFinder(Teams:GetTeams())

		return findTeam(text)
	end;

	Validate = function (teams)
		return #teams > 0, "No team with that name could be found."
	end;

	Autocomplete = function (teams)
		return Util.GetNames(teams)
	end;

	Parse = function (teams)
		return teams[1];
	end;
}

local teamPlayersType = {
	Listable = true;
	Transform = teamType.Transform;
	Validate = teamType.Validate;
	Autocomplete = teamType.Autocomplete;

	Parse = function (teams)
		return teams[1]:GetPlayers()
	end;
}

local teamColorType = {
	Transform = teamType.Transform;
	Validate = teamType.Validate;
	Autocomplete = teamType.Autocomplete;

	Parse = function (teams)
		return teams[1].TeamColor
	end;
}

return function (cmdr)
	cmdr:RegisterType("team", teamType)
	cmdr:RegisterType("teams", Util.MakeListableType(teamType))

	cmdr:RegisterType("teamPlayers", teamPlayersType)

	cmdr:RegisterType("teamColor", teamColorType)
	cmdr:RegisterType("teamColors", Util.MakeListableType(teamColorType))
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Type ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

return function (cmdr)
	local typeType = {
		Transform = function (text)
			local findCommand = Util.MakeFuzzyFinder(cmdr:GetTypeNames())

			return findCommand(text)
		end;

		Validate = function (commands)
			return #commands > 0, "No type with that name could be found."
		end;

		Autocomplete = function (commands)
			return commands
		end;

		Parse = function (commands)
			return commands[1]
		end;
	}

	cmdr:RegisterType("type", typeType)
	cmdr:RegisterType("types", Util.MakeListableType(typeType))
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.URL ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local storedKeyType = {
	Validate = function(text)
		if text:match("^https?://.+$") then
			return true
		end

		return false, "URLs must begin with http:// or https://"
	end;

	Parse = function(text)
		return text
	end;
}

return function (cmdr)
	cmdr:RegisterType("url", storedKeyType)
	cmdr:RegisterType("urls", Util.MakeListableType(storedKeyType))
end


-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.UserInput ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local combinedInputEnums = Enum.UserInputType:GetEnumItems()

for _, e in pairs(Enum.KeyCode:GetEnumItems()) do
	combinedInputEnums[#combinedInputEnums + 1] = e
end

local userInputType = {
	Transform = function (text)
		local findEnum = Util.MakeFuzzyFinder(combinedInputEnums)

		return findEnum(text)
	end;

	Validate = function (enums)
		return #enums > 0
	end;

	Autocomplete = function (enums)
		return Util.GetNames(enums)
	end;

	Parse = function (enums)
		return enums[1];
	end;
}

return function (cmdr)
	cmdr:RegisterType("userInput", userInputType)
	cmdr:RegisterType("userInputs", Util.MakeListableType(userInputType))
end

-- ==== [ ServerScriptService.Modules.Cmdr.BuiltInTypes.Vector ] ==== --
local Util = require(script.Parent.Parent.Shared.Util)

local function validateVector(value, i)
	if value == nil then
		return false, ("Invalid or missing number at position %d in Vector type."):format(i)
	end

	return true
end

local vector3Type = Util.MakeSequenceType({
	ValidateEach = validateVector;
	TransformEach = tonumber;
	Constructor = Vector3.new;
	Length = 3;
})

local vector2Type = Util.MakeSequenceType({
	ValidateEach = validateVector;
	TransformEach = tonumber;
	Constructor = Vector2.new;
	Length = 2;
})

return function (cmdr)
	cmdr:RegisterType("vector3", vector3Type)
	cmdr:RegisterType("vector3s", Util.MakeListableType(vector3Type))

	cmdr:RegisterType("vector2", vector2Type)
	cmdr:RegisterType("vector2s", Util.MakeListableType(vector2Type))
end

-- ==== [ ServerScriptService.Modules.Cmdr.Shared.Argument ] ==== --
local Util = require(script.Parent.Util)

local function unescapeOperators(text)
	for _, operator in ipairs({"%.", "%?", "%*", "%*%*"}) do
		text = text:gsub("\\" .. operator, operator:gsub("%%", ""))
	end

	return text
end

local Argument = {}
Argument.__index = Argument

--- Returns a new ArgumentContext, an object that handles parsing and validating arguments
function Argument.new (command, argumentObject, value)
	local self = {
		Command = command; -- The command that owns this argument
		Type = nil; -- The type definition
		Name = argumentObject.Name; -- The name for this specific argument
		Object = argumentObject; -- The raw ArgumentObject (definition)
		Required = argumentObject.Default == nil and argumentObject.Optional ~= true; -- If the argument is required or not.
		Executor = command.Executor; -- The player who is running the command
		RawValue = value; -- The raw, unparsed value
		RawSegments = {}; -- The raw, unparsed segments (if the raw value was comma-sep)
		TransformedValues = {}; -- The transformed value (generated later)
		Prefix = ""; -- The prefix for this command (%Team)
		TextSegmentInProgress = ""; -- The text of the raw segment the user is currently typing.
		RawSegmentsAreAutocomplete = false;
	}

	if type(argumentObject.Type) == "table" then
		self.Type = argumentObject.Type
	else
		local parsedType, parsedRawValue, prefix = Util.ParsePrefixedUnionType(
			command.Cmdr.Registry:GetTypeName(argumentObject.Type),
			value
		)

		self.Type = command.Dispatcher.Registry:GetType(parsedType)
		self.RawValue = parsedRawValue
		self.Prefix = prefix

		if self.Type == nil then
			error(string.format("%s has an unregistered type %q", self.Name or "<none>", parsedType or "<none>"))
		end
	end

	setmetatable(self, Argument)

	self:Transform()

	return self
end

function Argument:GetDefaultAutocomplete()
	if self.Type.Autocomplete then
		local strings, options = self.Type.Autocomplete(self:TransformSegment(""))
		return strings, options or {}
	end

	return {}
end

--- Calls the transform function on this argument.
-- The return value(s) from this function are passed to all of the other argument methods.
-- Called automatically at instantiation
function Argument:Transform()
	if #self.TransformedValues ~= 0 then
		return
	end

	local rawValue = self.RawValue
	if self.Type.ArgumentOperatorAliases then
		rawValue = self.Type.ArgumentOperatorAliases[rawValue] or rawValue
	end

	if rawValue == "." and self.Type.Default then
		rawValue = self.Type.Default(self.Executor) or ""
		self.RawSegmentsAreAutocomplete = true
	end

	if rawValue == "?" and self.Type.Autocomplete then
		local strings, options = self:GetDefaultAutocomplete()

		if not options.IsPartial and #strings > 0 then
			rawValue = strings[math.random(1, #strings)]
			self.RawSegmentsAreAutocomplete = true
		end

	end

	if self.Type.Listable and #self.RawValue > 0 then
		local randomMatch = rawValue:match("^%?(%d+)$")
		if randomMatch then
			local maxSize = tonumber(randomMatch)

			if maxSize and maxSize > 0 then
				local items = {}
				local remainingItems, options = self:GetDefaultAutocomplete()

				if not options.IsPartial and #remainingItems > 0 then
					for _ = 1, math.min(maxSize, #remainingItems) do
						table.insert(items, table.remove(remainingItems, math.random(1, #remainingItems)))
					end

					rawValue = table.concat(items, ",")
					self.RawSegmentsAreAutocomplete = true
				end
			end
		elseif rawValue == "*" or rawValue == "**" then
			local strings, options = self:GetDefaultAutocomplete()

			if not options.IsPartial and #strings > 0 then
				if rawValue == "**" and self.Type.Default then
					local defaultString = self.Type.Default(self.Executor) or ""

					for i, string in ipairs(strings) do
						if string == defaultString then
							table.remove(strings, i)
						end
					end
				end

				rawValue = table.concat(
					strings,
					","
				)
				self.RawSegmentsAreAutocomplete = true
			end
		end

		rawValue = unescapeOperators(rawValue)

		local rawSegments = Util.SplitStringSimple(rawValue, ",")

		if #rawSegments == 0 then
			rawSegments = {""}
		end

		if rawValue:sub(#rawValue, #rawValue) == "," then
			rawSegments[#rawSegments + 1] = "" -- makes auto complete tick over right after pressing ,
		end

		for i, rawSegment in ipairs(rawSegments) do
			self.RawSegments[i] = rawSegment
			self.TransformedValues[i] = { self:TransformSegment(rawSegment) }
		end

		self.TextSegmentInProgress = rawSegments[#rawSegments]
	else
		rawValue = unescapeOperators(rawValue)

		self.RawSegments[1] = unescapeOperators(rawValue)
		self.TransformedValues[1] = { self:TransformSegment(rawValue) }
		self.TextSegmentInProgress = self.RawValue
	end
end

function Argument:TransformSegment(rawSegment)
	if self.Type.Transform then
		return self.Type.Transform(rawSegment, self.Executor)
	else
		return rawSegment
	end
end

--- Returns whatever the Transform method gave us.
function Argument:GetTransformedValue(segment)
	return unpack(self.TransformedValues[segment])
end

--- Validates that the argument will work without any type errors.
function Argument:Validate(isFinal)
	if self.RawValue == nil or #self.RawValue == 0 and self.Required == false then
		return true
	end

	if self.Required and (self.RawSegments[1] == nil or #self.RawSegments[1] == 0) then
		return false, "This argument is required."
	end

	if self.Type.Validate or self.Type.ValidateOnce then
		for i = 1, #self.TransformedValues do
			if self.Type.Validate then
				local valid, errorText = self.Type.Validate(self:GetTransformedValue(i))

				if not valid then
					return valid, errorText or "Invalid value"
				end
			end

			if isFinal and self.Type.ValidateOnce then
				local validOnce, errorTextOnce = self.Type.ValidateOnce(self:GetTransformedValue(i))

				if not validOnce then
					return validOnce, errorTextOnce
				end
			end
		end

		return true
	else
		return true
	end
end

--- Gets a list of all possible values that could match based on the current value.
function Argument:GetAutocomplete()
	if self.Type.Autocomplete then
		return self.Type.Autocomplete(self:GetTransformedValue(#self.TransformedValues))
	else
		return {}
	end
end

function Argument:ParseValue(i)
	if self.Type.Parse then
		return self.Type.Parse(self:GetTransformedValue(i))
	else
		return self:GetTransformedValue(i)
	end
end

--- Returns the final value of the argument.
function Argument:GetValue()
	if #self.RawValue == 0 and not self.Required and self.Object.Default ~= nil then
		return self.Object.Default
	end

	if not self.Type.Listable then
		return self:ParseValue(1)
	end

	local values = {}

	for i = 1, #self.TransformedValues do
		local parsedValue = self:ParseValue(i)

		if type(parsedValue) ~= "table" then
			error(("Listable types must return a table from Parse (%s)"):format(self.Type.Name))
		end

		for _, value in pairs(parsedValue) do
			values[value] = true -- Put them into a dictionary to ensure uniqueness
		end
	end

	local valueArray = {}

	for value in pairs(values) do
		valueArray[#valueArray + 1] = value
	end

	return valueArray
end

return Argument


-- ==== [ ServerScriptService.Modules.Cmdr.Shared.Command ] ==== --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Argument = require(script.Parent.Argument)

local IsServer = RunService:IsServer()

local Command = {}
Command.__index = Command

--- Returns a new CommandContext, an object which is created for every command validation.
-- This is also what's passed as the context to the "Run" functions in commands
function Command.new (options)
	local self = {
		Dispatcher = options.Dispatcher; -- The dispatcher that created this command context
		Cmdr = options.Dispatcher.Cmdr; -- A quick reference to Cmdr for command context
		Name = options.CommandObject.Name; -- The command name (not alias)
		RawText = options.Text; -- The raw text used to trigger this command
		Object = options.CommandObject; -- The command object (definition)
		Group = options.CommandObject.Group; -- The group this command is in
		State = {}; -- A table which will hold any custom command state information
		Aliases = options.CommandObject.Aliases;
		Alias = options.Alias; -- The command name that was used
		Description = options.CommandObject.Description;
		Executor = options.Executor; -- The player who ran the command
		ArgumentDefinitions = options.CommandObject.Args; -- The argument definitions from the command definition
		RawArguments = options.Arguments; -- Array of strings which are the unparsed values for the arguments
		Arguments = {}; -- A table which will hold ArgumentContexts for each argument
		Data = options.Data; -- A special container for any additional data the command needs to collect from the client
		Response = nil; -- Will be set at the very end when the command is run and a string is returned from the Run function.
	}

	setmetatable(self, Command)

	return self
end

--- Parses all of the command arguments into ArgumentContexts
-- Called by the command dispatcher automatically
-- allowIncompleteArguments: if true, will not throw an error for missing arguments
function Command:Parse (allowIncompleteArguments)
	local hadOptional = false
	for i, definition in ipairs(self.ArgumentDefinitions) do
		if type(definition) == "function" then
			definition = definition(self)

			if definition == nil then
				break
			end
		end

		local required = (definition.Default == nil and definition.Optional ~= true)

		if required and hadOptional then
			error(("Command %q: Required arguments cannot occur after optional arguments."):format(self.Name))
		elseif not required then
			hadOptional = true
		end

		if self.RawArguments[i] == nil and required and allowIncompleteArguments ~= true then
			return false, ("Required argument #%d %s is missing."):format(i, definition.Name)
		elseif self.RawArguments[i] or allowIncompleteArguments then
			self.Arguments[i] = Argument.new(self, definition, self.RawArguments[i] or "")
		end
	end

	return true
end

--- Validates that all of the arguments are in a valid state.
-- This must be called before :Run() is called.
-- Returns boolean (true if ok), errorText
function Command:Validate (isFinal)
	self._Validated = true
	local errorText = ""
	local success = true

	for i, arg in pairs(self.Arguments) do
		local argSuccess, argErrorText = arg:Validate(isFinal)

		if not argSuccess then
			success = false
			errorText = ("%s; #%d %s: %s"):format(errorText, i, arg.Name, argErrorText or "error")
		end
	end

	return success, errorText:sub(3)
end

--- Returns the last argument that has a value.
-- Useful for getting the autocomplete for the argument the user is working on.
function Command:GetLastArgument()
	for i = #self.Arguments, 1, -1 do
		if self.Arguments[i].RawValue then
			return self.Arguments[i]
		end
	end
end

--- Returns a table containing the parsed values for all of the arguments.
function Command:GatherArgumentValues ()
	local values = {}

	for i = 1, #self.ArgumentDefinitions do
		local arg = self.Arguments[i]
		if arg then
			values[i] = arg:GetValue()
		elseif type(self.ArgumentDefinitions[i]) == "table" then
			values[i] = self.ArgumentDefinitions[i].Default
		end
	end

	return values, #self.ArgumentDefinitions
end

--- Runs the command. Handles dispatching to the server if necessary.
-- Command:Validate() must be called before this is called or it will throw.
function Command:Run ()
	if self._Validated == nil then
		error("Must validate a command before running.")
	end

	local beforeRunHook = self.Dispatcher:RunHooks("BeforeRun", self)
	if beforeRunHook then
		return beforeRunHook
	end

	if not IsServer and self.Object.Data and self.Data == nil then
		local values, length = self:GatherArgumentValues()
		self.Data = self.Object.Data(self, unpack(values, 1, length))
	end

	if not IsServer and self.Object.ClientRun then
		local values, length = self:GatherArgumentValues()
		self.Response = self.Object.ClientRun(self, unpack(values, 1, length))
	end

	if self.Response == nil then
		if self.Object.Run then -- We can just Run it here on this machine
			local values, length = self:GatherArgumentValues()
			self.Response = self.Object.Run(self, unpack(values, 1, length))

		elseif IsServer then -- Uh oh, we're already on the server and there's no Run function.
			if self.Object.ClientRun then
				warn(self.Name, "command fell back to the server because ClientRun returned nil, but there is no server implementation! Either return a string from ClientRun, or create a server implementation for this command.")
			else
				warn(self.Name, "command has no implementation!")
			end

			self.Response = "No implementation."
		else -- We're on the client, so we send this off to the server to let the server see what it can do with it.
			self.Response = self.Dispatcher:Send(self.RawText, self.Data)
		end
	end

	local afterRunHook = self.Dispatcher:RunHooks("AfterRun", self)
	if afterRunHook then
		return afterRunHook
	else
		return self.Response
	end
end

--- Returns an ArgumentContext for the specific index
function Command:GetArgument (index)
	return self.Arguments[index]
end

-- Below are functions that are only meant to be used in command implementations --

--- Returns the extra data associated with this command.
-- This needs to be used instead of just context.Data for reliability when not using a remote command.
function Command:GetData ()
	if self.Data then
		return self.Data
	end

	if self.Object.Data and not IsServer then
		self.Data = self.Object.Data(self)
	end

	return self.Data
end

--- Sends an event message to a player
function Command:SendEvent(player, event, ...)
	assert(typeof(player) == "Instance", "Argument #1 must be a Player")
	assert(player:IsA("Player"), "Argument #1 must be a Player")
	assert(type(event) == "string", "Argument #2 must be a string")

	if IsServer then
		self.Dispatcher.Cmdr.RemoteEvent:FireClient(player, event, ...)
	elseif self.Dispatcher.Cmdr.Events[event] then
		assert(player == Players.LocalPlayer, "Event messages can only be sent to the local player on the client.")
		self.Dispatcher.Cmdr.Events[event](...)
	end
end

--- Sends an event message to all players
function Command:BroadcastEvent(...)
	if not IsServer then
		error("Can't broadcast event messages from the client.", 2)
	end

	self.Dispatcher.Cmdr.RemoteEvent:FireAllClients(...)
end

--- Alias of self:SendEvent(self.Executor, "AddLine", text)
function Command:Reply(...)
	return self:SendEvent(self.Executor, "AddLine", ...)
end

--- Alias of Registry:GetStore(...)
function Command:GetStore(...)
	return self.Dispatcher.Cmdr.Registry:GetStore(...)
end

--- Returns true if the command has an implementation on the caller's machine.
function Command:HasImplementation()
	return ((RunService:IsClient() and self.Object.ClientRun) or self.Object.Run) and true or false
end

return Command


-- ==== [ ServerScriptService.Modules.Cmdr.Shared.Dispatcher ] ==== --
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Util = require(script.Parent.Util)
local Command = require(script.Parent.Command)

local HISTORY_SETTING_NAME = "CmdrCommandHistory"
local displayedBeforeRunHookWarning = false

--- The dispatcher handles creating and running commands during the game.
local Dispatcher = {
	Cmdr = nil;
	Registry = nil;
}

--- Takes in raw command information and generates a command out of it.
-- text and executor are required arguments.
-- allowIncompleteData, when true, will ignore errors about arguments missing so we can parse live as the user types.
-- data is for special networked Data about the command gathered on the client. Purely Optional.
-- returns the command if successful, or (false, errorText) if not
function Dispatcher:Evaluate (text, executor, allowIncompleteArguments, data)
	if RunService:IsClient() == true and executor ~= Players.LocalPlayer then
		error("Can't evaluate a command that isn't sent by the local player.")
	end

	local arguments = Util.SplitString(text)
	local commandName = table.remove(arguments, 1)
	local commandObject = self.Registry:GetCommand(commandName)

	if commandObject then
		-- No need to continue splitting when there are no more arguments. We'll just mash any additional arguments into the last one.
		arguments = Util.MashExcessArguments(arguments, #commandObject.Args)

		-- Create the CommandContext and parse it.
		local command = Command.new({
			Dispatcher = self,
			Text = text,
			CommandObject = commandObject,
			Alias = commandName,
			Executor = executor,
			Arguments = arguments,
			Data = data
		})
		local success, errorText = command:Parse(allowIncompleteArguments)

		if success then
			return command
		else
			return false, errorText
		end
	else
		return false, ("%q is not a valid command name. Use the help command to see all available commands."):format(tostring(commandName))
	end
end

--- A helper that evaluates and runs the command in one go.
-- Either returns any validation errors as a string, or the output of the command as a string. Definitely a string, though.
function Dispatcher:EvaluateAndRun (text, executor, options)
	executor = executor or Players.LocalPlayer
	options = options or {}

	if RunService:IsClient() and options.IsHuman then
		self:PushHistory(text)
	end

	local command, errorText = self:Evaluate(text, executor, nil, options.Data)

	if not command then
		return errorText
	end

	local ok, out = xpcall(function()
		local valid, errorText = command:Validate(true) -- luacheck: ignore

		if not valid then
			return errorText
		end
		
		return command:Run()-- or "Command executed."
	end, function(value)
		return debug.traceback(tostring(value))
	end)

	if not ok then
		warn(("Error occurred while evaluating command string %q\n%s"):format(text, tostring(out)))
	end

	return ok and out or "An error occurred while running this command. Check the console for more information."
end

--- Send text as the local user to remote server to be evaluated there.
function Dispatcher:Send (text, data)
	if RunService:IsClient() == false then
		error("Dispatcher:Send can only be called from the client.")
	end
	self.Cmdr.RemoteFunction:FireServer(text, {
		Data = data
	})
	return "Command executed. (or not lmk)"
end

--- Invoke a command programmatically as the local user e.g. from a settings menu
-- Command should be the first argument, all arguments afterwards should be the arguments to the command.
function Dispatcher:Run (...)
	if not Players.LocalPlayer then
		error("Dispatcher:Run can only be called from the client.")
	end

	local args = {...}
	local text = args[1]

	for i = 2, #args do
		text = text .. " " .. tostring(args[i])
	end

	local command, errorText = self:Evaluate(text, Players.LocalPlayer)

	if not command then
		error(errorText) -- We do a full-on error here since this is code-invoked and they should know better.
	end

	local success, errorText = command:Validate(true) -- luacheck: ignore

	if not success then
		error(errorText)
	end

	return command:Run()
end

--- Runs hooks matching name and returns nil for ok or a string for cancellation
function Dispatcher:RunHooks(hookName, commandContext, ...)
	if not self.Registry.Hooks[hookName] then
		error(("Invalid hook name: %q"):format(hookName), 2)
	end

	if
		hookName == "BeforeRun"
		and #self.Registry.Hooks[hookName] == 0
		and commandContext.Group ~= "DefaultUtil"
		and commandContext.Group ~= "UserAlias"
		and commandContext:HasImplementation()
	then

		if RunService:IsStudio() then
			if displayedBeforeRunHookWarning == false then
				commandContext:Reply((RunService:IsServer() and "<Server>" or "<Client>") .. " Commands will not run in-game if no BeforeRun hook is configured. Learn more: https://eryn.io/Cmdr/guide/Hooks.html", Color3.fromRGB(255,228,26))
				displayedBeforeRunHookWarning = true
			end
		else
			return "Command blocked for security as no BeforeRun hook is configured."
		end
	end

	for _, hook in ipairs(self.Registry.Hooks[hookName]) do
		local value = hook.callback(commandContext, ...)

		if value ~= nil then
			return tostring(value)
		end
	end
end

function Dispatcher:PushHistory(text)
	assert(RunService:IsClient(), "PushHistory may only be used from the client.")

	local history = self:GetHistory()

	-- Remove duplicates
	if Util.TrimString(text) == "" or text == history[#history] then
		return
	end

	history[#history + 1] = text

	TeleportService:SetTeleportSetting(HISTORY_SETTING_NAME, history)
end

function Dispatcher:GetHistory()
	assert(RunService:IsClient(), "GetHistory may only be used from the client.")

	return TeleportService:GetTeleportSetting(HISTORY_SETTING_NAME) or {}
end

return function (cmdr)
	Dispatcher.Cmdr = cmdr
	Dispatcher.Registry = cmdr.Registry

	return Dispatcher
end

-- ==== [ ServerScriptService.Modules.Cmdr.Shared.Registry ] ==== --
local RunService = game:GetService("RunService")

local Util = require(script.Parent.Util)

--- The registry keeps track of all the commands and types that Cmdr knows about.
local Registry = {
	TypeMethods = Util.MakeDictionary({"Transform", "Validate", "Autocomplete", "Parse", "DisplayName", "Listable", "ValidateOnce", "Prefixes", "Default", "ArgumentOperatorAliases"});
	CommandMethods = Util.MakeDictionary({"Name", "Aliases", "AutoExec", "Description", "Args", "Run", "ClientRun", "Data", "Group"});
	CommandArgProps = Util.MakeDictionary({"Name", "Type", "Description", "Optional", "Default"});
	Types = {};
	TypeAliases = {};
	Commands = {};
	CommandsArray = {};
	Cmdr = nil;
	Hooks = {
		BeforeRun = {};
		AfterRun = {}
	};
	Stores = setmetatable({}, {
		__index = function (self, k)
			self[k] = {}
			return self[k]
		end
	});
	AutoExecBuffer = {};
}

--- Registers a type in the system.
-- name: The type Name. This must be unique.
function Registry:RegisterType (name, typeObject)
	if not name or typeof(name) ~= "string" then
		error("Invalid type name provided: nil")
	end

	if not name:find("^[%d%l]%w*$") then
		error(('Invalid type name provided: "%s", type names must be alphanumeric and start with a lower-case letter or a digit.'):format(name))
	end

	for key in pairs(typeObject) do
		if self.TypeMethods[key] == nil then
			error("Unknown key/method in type \"" .. name .. "\": " .. key)
		end
	end

	if self.Types[name] ~= nil then
		error(('Type "%s" has already been registered.'):format(name))
	end

	typeObject.Name = name
	typeObject.DisplayName = typeObject.DisplayName or name

	self.Types[name] = typeObject

	if typeObject.Prefixes then
		self:RegisterTypePrefix(name, typeObject.Prefixes)
	end
end

function Registry:RegisterTypePrefix (name, union)
	if not self.TypeAliases[name] then
		self.TypeAliases[name] = name
	end

	self.TypeAliases[name] = ("%s %s"):format(self.TypeAliases[name], union)
end

function Registry:RegisterTypeAlias (name, alias)
	assert(self.TypeAliases[name] == nil, ("Type alias %s already exists!"):format(alias))
	self.TypeAliases[name] = alias
end

--- Helper method that registers types from all module scripts in a specific container.
function Registry:RegisterTypesIn (container)
	for _, object in pairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			object.Parent = self.Cmdr.ReplicatedRoot.Types

			require(object)(self)
		else
			self:RegisterTypesIn(object)
		end
	end
end

-- These are exactly the same thing. No one will notice. Except for you, dear reader.
Registry.RegisterHooksIn = Registry.RegisterTypesIn

--- Registers a command based purely on its definition.
-- Prefer using Registry:RegisterCommand for proper handling of server/client model.
function Registry:RegisterCommandObject (commandObject, fromCmdr)
	for key in pairs(commandObject) do
		if self.CommandMethods[key] == nil then
			error("Unknown key/method in command " .. (commandObject.Name or "unknown command") .. ": " .. key)
		end
	end

	if commandObject.Args then
		for i, arg in pairs(commandObject.Args) do
			if type(arg) == "table" then
				for key in pairs(arg) do
					if self.CommandArgProps[key] == nil then
						error(('Unknown property in command "%s" argument #%d: %s'):format(commandObject.Name or "unknown", i, key))
					end
				end
			end
		end
	end

	if commandObject.AutoExec and RunService:IsClient() then
		table.insert(self.AutoExecBuffer, commandObject.AutoExec)
		self:FlushAutoExecBufferDeferred()
	end

	-- Unregister the old command if it exists...
	local oldCommand = self.Commands[commandObject.Name:lower()]
	if oldCommand and oldCommand.Aliases then
		for _, alias in pairs(oldCommand.Aliases) do
			self.Commands[alias:lower()] = nil
		end
	elseif not oldCommand then
		table.insert(self.CommandsArray, commandObject)
	end

	self.Commands[commandObject.Name:lower()] = commandObject

	if commandObject.Aliases then
		for _, alias in pairs(commandObject.Aliases) do
			self.Commands[alias:lower()] = commandObject
		end
	end
end

--- Registers a command definition and its server equivalent.
-- Handles replicating the definition to the client.
function Registry:RegisterCommand (commandScript, commandServerScript, filter)
	local commandObject = require(commandScript)
	assert(
		typeof(commandObject) == "table",
		`Invalid return value from command script "{commandScript.Name}" (CommandDefinition expected, got {typeof(commandObject)})`
	)

	if commandServerScript then
		assert(RunService:IsServer(), "The commandServerScript parameter is not valid for client usage.")
		commandObject.Run = require(commandServerScript)
	end

	if filter and not filter(commandObject) then
		return
	end

	self:RegisterCommandObject(commandObject)

	commandScript.Parent = self.Cmdr.ReplicatedRoot.Commands
end

--- A helper method that registers all commands inside a specific container.
function Registry:RegisterCommandsIn (container, filter)
	local skippedServerScripts = {}
	local usedServerScripts = {}

	for _, commandScript in pairs(container:GetChildren()) do
		if commandScript:IsA("ModuleScript") then
			if not commandScript.Name:find("Server") then
				local serverCommandScript = container:FindFirstChild(commandScript.Name .. "Server")

				if serverCommandScript then
					usedServerScripts[serverCommandScript] = true
				end

				self:RegisterCommand(commandScript, serverCommandScript, filter)
			else
				skippedServerScripts[commandScript] = true
			end
		else
			self:RegisterCommandsIn(commandScript, filter)
		end
	end

	for skippedScript in pairs(skippedServerScripts) do
		if not usedServerScripts[skippedScript] then
			warn("Command script " .. skippedScript.Name .. " was skipped because it has 'Server' in its name, and has no equivalent shared script.")
		end
	end
end

--- Registers the default commands, with an optional filter function or array of groups.
function Registry:RegisterDefaultCommands (arrayOrFunc)
	assert(RunService:IsServer(), "RegisterDefaultCommands cannot be called from the client.")

	local isArray = type(arrayOrFunc) == "table"

	if isArray then
		arrayOrFunc = Util.MakeDictionary(arrayOrFunc)
	end

	self:RegisterCommandsIn(self.Cmdr.DefaultCommandsFolder, isArray and function (command)
		return arrayOrFunc[command.Group] or false
	end or arrayOrFunc)
end

--- Gets a command definition by name. (Can be an alias)
function Registry:GetCommand (name)
	name = name or ""
	return self.Commands[name:lower()]
end

--- Returns a unique array of all registered commands (not including aliases)
function Registry:GetCommands ()
	return self.CommandsArray
end

--- Returns an array of the names of all registered commands (not including aliases)
function Registry:GetCommandNames ()
	local commands = {}

	for _, command in pairs(self.CommandsArray) do
		table.insert(commands, command.Name)
	end

	return commands
end

Registry.GetCommandsAsStrings = Registry.GetCommandNames

--- Returns an array of the names of all registered types (not including aliases)
function Registry:GetTypeNames ()
	local typeNames = {}

	for typeName in pairs(self.Types) do
		table.insert(typeNames, typeName)
	end

	return typeNames
end


--- Gets a type definition by name.
function Registry:GetType (name)
	return self.Types[name]
end

--- Returns a type name, parsing aliases.
function Registry:GetTypeName (name)
	return self.TypeAliases[name] or name
end

--- Adds a hook to be called when any command is run
function Registry:RegisterHook(hookName, callback, priority)
	if not self.Hooks[hookName] then
		error(("Invalid hook name: %q"):format(hookName), 2)
	end

	table.insert(self.Hooks[hookName], { callback = callback; priority = priority or 0; } )
	table.sort(self.Hooks[hookName], function(a, b) return a.priority < b.priority end)
end

-- Backwards compatability (deprecated)
Registry.AddHook = Registry.RegisterHook

--- Returns the store with the given name
-- Used for commands that require persistent state, like bind or ban
function Registry:GetStore(name)
	return self.Stores[name]
end

--- Calls self:FlushAutoExecBuffer at the end of the frame
function Registry:FlushAutoExecBufferDeferred()
	if self.AutoExecFlushConnection then
		return
	end

	self.AutoExecFlushConnection = RunService.Heartbeat:Connect(function()
		self.AutoExecFlushConnection:Disconnect()
		self.AutoExecFlushConnection = nil
		self:FlushAutoExecBuffer()
	end)
end

--- Runs all pending auto exec commands in Registry.AutoExecBuffer
function Registry:FlushAutoExecBuffer()
	for _, commandGroup in ipairs(self.AutoExecBuffer) do
		for _, command in ipairs(commandGroup) do
			self.Cmdr.Dispatcher:EvaluateAndRun(command)
		end
	end

	self.AutoExecBuffer = {}
end

return function (cmdr)
	Registry.Cmdr = cmdr

	return Registry
end


-- ==== [ ServerScriptService.Modules.Cmdr.Shared.Util ] ==== --
local TextService = game:GetService("TextService")

local Util = {}

--- Takes an array and flips its values into dictionary keys with value of true.
function Util.MakeDictionary(array)
	local dictionary = {}

	for i = 1, #array do
		dictionary[array[i]] = true
	end

	return dictionary
end

--- Takes a dictionary and returns its keys.
function Util.DictionaryKeys(dict)
	local keys = {}

	for key in pairs(dict) do
		table.insert(keys, key)
	end

	return keys
end

-- Takes an array of instances and returns (array<names>, array<instances>)
local function transformInstanceSet(instances)
	local names = {}

	for i = 1, #instances do
		names[i] = instances[i].Name
	end

	return names, instances
end

--- Returns a function that is a fuzzy finder for the specified set or container.
-- Can pass an array of strings, array of instances, array of EnumItems,
-- array of dictionaries with a Name key or an instance (in which case its children will be used)
-- Exact matches will be inserted in the front of the resulting array
function Util.MakeFuzzyFinder(setOrContainer)
	local names
	local instances = {}

	if typeof(setOrContainer) == "Enum" then
		setOrContainer = setOrContainer:GetEnumItems()
	end

	if typeof(setOrContainer) == "Instance" then
		names, instances = transformInstanceSet(setOrContainer:GetChildren())
	elseif typeof(setOrContainer) == "table" then
		if
			typeof(setOrContainer[1]) == "Instance" or typeof(setOrContainer[1]) == "EnumItem" or
				(typeof(setOrContainer[1]) == "table" and typeof(setOrContainer[1].Name) == "string")
		 then
			names, instances = transformInstanceSet(setOrContainer)
		elseif type(setOrContainer[1]) == "string" then
			names = setOrContainer
		elseif setOrContainer[1] ~= nil then
			error("MakeFuzzyFinder only accepts tables of instances or strings.")
		else
			names = {}
		end
	else
		error("MakeFuzzyFinder only accepts a table, Enum, or Instance.")
	end

	-- Searches the set (checking exact matches first)
	return function(text, returnFirst)
		local results = {}

		for i, name in pairs(names) do
			local value = instances and instances[i] or name

			-- Continue on checking for non-exact matches...
			-- Still need to loop through everything, even on returnFirst, because possibility of an exact match.
			if name:lower() == text:lower() then
				if returnFirst then
					return value
				else
					table.insert(results, 1, value)
				end
			elseif name:lower():find(text:lower(), 1, true) then
				results[#results + 1] = value
			end
		end

		if returnFirst then
			return results[1]
		end

		return results
	end
end

--- Takes an array of instances and returns an array of those instances' names.
function Util.GetNames(instances)
	local names = {}

	for i = 1, #instances do
		names[i] = instances[i].Name or tostring(instances[i])
	end

	return names
end

--- Splits a string using a simple separator (no quote parsing)
function Util.SplitStringSimple(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	local i = 1
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

local function charCode(n)
	return utf8.char(tonumber(n, 16))
end

--- Parses escape sequences into their fully qualified characters
function Util.ParseEscapeSequences(text)
	return text:gsub("\\(.)", {
		t = "\t";
		n = "\n";
	})
	:gsub("\\u(%x%x%x%x)", charCode)
	:gsub("\\x(%x%x)", charCode)
end

function Util.EncodeEscapedOperator(text, op)
	local first = op:sub(1, 1)
	local escapedOp = op:gsub(".", "%%%1")
	local escapedFirst = "%" .. first

	return text:gsub("(" .. escapedFirst .. "+)(" .. escapedOp .. ")", function(esc, op)
			return (esc:sub(1, #esc-1) .. op):gsub(".", function(char)
					return "\\u" .. string.format("%04x", string.byte(char), 16)
			end)
	end)
end

local OPERATORS = {"&&", "||", ";"}
function Util.EncodeEscapedOperators(text)
	for _, operator in ipairs(OPERATORS) do
		text = Util.EncodeEscapedOperator(text, operator)
	end

	return text
end

local function encodeControlChars(text)
	return (
		text
		:gsub("\\\\", "___!CMDR_ESCAPE!___")
		:gsub("\\\"", "___!CMDR_QUOTE!___")
		:gsub("\\'", "___!CMDR_SQUOTE!___")
		:gsub("\\\n", "___!CMDR_NL!___")
	)
end

local function decodeControlChars(text)
	return (
		text
		:gsub("___!CMDR_ESCAPE!___", "\\")
		:gsub("___!CMDR_QUOTE!___", "\"")
		:gsub("___!CMDR_NL!___", "\n")
	)
end

--- Splits a string by space but taking into account quoted sequences which will be treated as a single argument.
function Util.SplitString(text, max)
	text = encodeControlChars(text)
	max = max or math.huge
	local t = {}
	local spat, epat = [=[^(['"])]=], [=[(['"])$]=]
	local buf, quoted
	for str in text:gmatch("[^ ]+") do
		str = Util.ParseEscapeSequences(str)
		local squoted = str:match(spat)
		local equoted = str:match(epat)
		local escaped = str:match([=[(\*)['"]$]=])
		if squoted and not quoted and not equoted then
			buf, quoted = str, squoted
		elseif buf and equoted == quoted and #escaped % 2 == 0 then
			str, buf, quoted = buf .. " " .. str, nil, nil
		elseif buf then
			buf = buf .. " " .. str
		end
		if not buf then
			t[#t + (#t > max and 0 or 1)] = decodeControlChars(str:gsub(spat, ""):gsub(epat, ""))
		end
	end

	if buf then
		t[#t + (#t > max and 0 or 1)] = decodeControlChars(buf)
	end

	return t
end

--- Takes an array of arguments and a max value.
-- Any indicies past the max value will be appended to the last valid argument.
function Util.MashExcessArguments(arguments, max)
	local t = {}
	for i = 1, #arguments do
		if i > max then
			t[max] = ("%s %s"):format(t[max] or "", arguments[i])
		else
			t[i] = arguments[i]
		end
	end
	return t
end

--- Trims whitespace from both sides of a string.
function Util.TrimString(str)
	local _, from = string.find(str, "^%s*")
	-- trim the string in two steps to prevent quadratic backtracking when no "%S" match is found
	return from == #str and "" or string.match(str, ".*%S", from + 1)
end

--- Returns the text bounds size based on given text, label (from which properties will be pulled), and optional Vector2 container size.
function Util.GetTextSize(text, label, size)
	return TextService:GetTextSize(text, label.TextSize, label.Font, size or Vector2.new(label.AbsoluteSize.X, 0))
end

--- Makes an Enum type.
function Util.MakeEnumType(name, values)
	local findValue = Util.MakeFuzzyFinder(values)
	return {
		Validate = function(text)
			return findValue(text, true) ~= nil, ("Value %q is not a valid %s."):format(text, name)
		end,
		Autocomplete = function(text)
			local list = findValue(text)
			return type(list[1]) ~= "string" and Util.GetNames(list) or list
		end,
		Parse = function(text)
			return findValue(text, true)
		end
	}
end

--- Parses a prefixed union type argument (such as %Team)
function Util.ParsePrefixedUnionType(typeValue, rawValue)
	local split = Util.SplitStringSimple(typeValue)

	-- Check prefixes in order from longest to shortest
	local types = {}
	for i = 1, #split, 2 do
		types[#types + 1] = {
			prefix = split[i - 1] or "",
			type = split[i]
		}
	end

	table.sort(
		types,
		function(a, b)
			return #a.prefix > #b.prefix
		end
	)

	for i = 1, #types do
		local t = types[i]

		if rawValue:sub(1, #t.prefix) == t.prefix then
			return t.type, rawValue:sub(#t.prefix + 1), t.prefix
		end
	end
end

--- Creates a listable type from a singlular type
function Util.MakeListableType(type, override)
	local listableType = {
		Listable = true,
		Transform = type.Transform,
		Validate = type.Validate,
		ValidateOnce = type.ValidateOnce,
		Autocomplete = type.Autocomplete,
		Default = type.Default,
		ArgumentOperatorAliases = type.ArgumentOperatorAliases,
		Parse = function(...)
			return {type.Parse(...)}
		end
	}

	if override then
		for key, value in pairs(override) do
			listableType[key] = value
		end
	end

	return listableType
end

local function encodeCommandEscape(text)
	return (text:gsub("\\%$", "___!CMDR_DOLLAR!___"))
end

local function decodeCommandEscape(text)
	return (text:gsub("___!CMDR_DOLLAR!___", "$"))
end

function Util.RunCommandString(dispatcher, commandString)
	commandString = Util.ParseEscapeSequences(commandString)
	commandString = Util.EncodeEscapedOperators(commandString)

	local commands = commandString:split("&&")

	local output = ""
	for i, command in ipairs(commands) do
		local outputEncoded = output:gsub("%$", "\\x24"):gsub("%%","%%%%")
		command = command:gsub("||", output:find("%s") and ("%q"):format(outputEncoded) or outputEncoded)

		output = tostring(
			dispatcher:EvaluateAndRun(
				(
					Util.RunEmbeddedCommands(dispatcher, command)
				)
			)
		)


		if i == #commands then
			return output
		end
	end
end

--- Runs embedded commands and replaces them
function Util.RunEmbeddedCommands(dispatcher, str)
	str = encodeCommandEscape(str)

	local results = {}
	-- We need to do this because you can't yield in the gsub function
	for text in str:gmatch("$(%b{})") do
		local doQuotes = true
		local commandString = text:sub(2, #text-1)

		if commandString:match("^{.+}$") then -- Allow double curly for literal replacement
			doQuotes = false
			commandString = commandString:sub(2, #commandString-1)
		end

		results[text] = Util.RunCommandString(dispatcher, commandString)

		if doQuotes then
			if results[text]:find("%s") or results[text] == "" then
				results[text] = string.format("%q", results[text])
			end
		end
	end

	return decodeCommandEscape(str:gsub("$(%b{})", results))
end

--- Replaces arguments in the format $1, $2, $something with whatever the
-- given function returns for it.
function Util.SubstituteArgs(str, replace)
	str = encodeCommandEscape(str)
	-- Convert numerical keys to strings
	if type(replace) == "table" then
		for i = 1, #replace do
			local k = tostring(i)
			replace[k] = replace[i]

			if replace[k]:find("%s") then
				replace[k] = string.format("%q", replace[k])
			end
		end
	end
	return decodeCommandEscape(str:gsub("($%d+)%b{}", "%1"):gsub("$(%w+)", replace))
end

--- Creates an alias command
function Util.MakeAliasCommand(name, commandString)
	local commandName, commandDescription = unpack(name:split("|"))
	local args = {}

	commandString = Util.EncodeEscapedOperators(commandString)

	local seenArgs = {}

	for arg in commandString:gmatch("$(%d+)") do
		if seenArgs[arg] == nil then
			seenArgs[arg] = true
			local options = commandString:match(`${arg}(%b\{})`)

			local argOptional, argType, argName, argDescription
			if options then
				options = options:sub(2, #options - 1) -- remove braces
				argType, argName, argDescription = unpack(options:split("|"))
			end

			argOptional = argType and not not argType:match("%?$")
			argType = if argType then argType:match("^%w+") else "string"
			argName = argName or `Argument {arg}`
			argDescription = argDescription or ""

			table.insert(args, {
				Type = argType,
				Name = argName,
				Description = argDescription,
				Optional = argOptional,
			})
		end
	end

	return {
		Name = commandName,
		Aliases = {},
		Description = `<Alias> {commandDescription or commandString}`,
		Group = "UserAlias",
		Args = args,
		Run = function(context)
			return Util.RunCommandString(context.Dispatcher, Util.SubstituteArgs(commandString, context.RawArguments))
		end,
	}
end

--- Makes a type that contains a sequence, e.g. Vector3 or Color3
function Util.MakeSequenceType(options)
	options = options or {}

	assert(options.Parse ~= nil or options.Constructor ~= nil, "MakeSequenceType: Must provide one of: Constructor, Parse")

	options.TransformEach = options.TransformEach or function(...)
		return ...
	end

	options.ValidateEach = options.ValidateEach or function()
		return true
	end

	return {
		Prefixes = options.Prefixes;

		Transform = function (text)
			return Util.Map(Util.SplitPrioritizedDelimeter(text, {",", "%s"}), function(value)
				return options.TransformEach(value)
			end)
		end;

		Validate = function (components)
			if options.Length and #components > options.Length then
				return false, ("Maximum of %d values allowed in sequence"):format(options.Length)
			end

			for i = 1, options.Length or #components do
				local valid, reason = options.ValidateEach(components[i], i)

				if not valid then
					return false, reason
				end
			end

			return true
		end;

		Parse = options.Parse or function(components)
			return options.Constructor(unpack(components))
		end
	}
end

--- Splits a string by a single delimeter chosen from the given set.
-- The first matching delimeter from the set becomes the split character.
function Util.SplitPrioritizedDelimeter(text, delimeters)
	for i, delimeter in ipairs(delimeters) do
		if text:find(delimeter) or i == #delimeters then
			return Util.SplitStringSimple(text, delimeter)
		end
	end
end

--- Maps values of an array through a callback and returns an array of mapped values
function Util.Map(array, callback)
	local results = {}

	for i, v in ipairs(array) do
		results[i] = callback(v, i)
	end

	return results
end

--- Maps arguments #2-n through callback and returns values as tuple
function Util.Each(callback, ...)
	local results = {}
	for i, value in ipairs({...}) do
		results[i] = callback(value)
	end
	return unpack(results)
end

--- Emulates tabstops with spaces
function Util.EmulateTabstops(text, tabWidth)
	local column = 0
	local textLength = #text
	local result = table.create(textLength)
	for i = 1, textLength do
		local char = string.sub(text, i, i)
		if char == "\t" then
			local spaces = tabWidth - column % tabWidth
			table.insert(result, string.rep(" ", spaces))
			column += spaces
		else
			table.insert(result, char)
			if char == "\n" then
				column = 0 -- Reset column counter on newlines
			elseif char ~= "\r" then
				column += 1
			end
		end
	end
	return table.concat(result)
end

function Util.Mutex()
	local queue = {}
	local locked = false

	return function ()
		if locked then
			table.insert(queue, coroutine.running())
			coroutine.yield()
		else
			locked = true
		end

		return function()
			if #queue > 0 then
				coroutine.resume(table.remove(queue, 1))
			else
				locked = false
			end
		end
	end
end

return Util


-- ==== [ ServerScriptService.Modules.Cmdr.CmdrClient ] ==== --
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Shared = script:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))

if RunService:IsClient() == false then
	error("Server scripts cannot require the client library. Please require the server library to use Cmdr in your own code.")
end

local Cmdr do
	Cmdr = setmetatable({
		ReplicatedRoot = script;
		RemoteFunction = script:WaitForChild("CmdrFunction");
		RemoteEvent = script:WaitForChild("CmdrEvent");
		ActivationKeys = {[Enum.KeyCode.F2] = true};
		Enabled = true;
		MashToEnable = false;
		ActivationUnlocksMouse = false;
		HideOnLostFocus = true;
		PlaceName = "Cmdr";
		Util = Util;
		Events = {};
	}, {
		-- This sucks, and may be redone or removed
		-- Proxies dispatch methods on to main Cmdr object
		__index = function (self, k)
			local r = self.Dispatcher[k]
			if r and type(r) == "function" then
				return function (_, ...)
					return r(self.Dispatcher, ...)
				end
			end
		end
	})

	Cmdr.Registry = require(Shared.Registry)(Cmdr)
	Cmdr.Dispatcher = require(Shared.Dispatcher)(Cmdr)
end

if StarterGui:WaitForChild("Cmdr") and wait() and Player:WaitForChild("PlayerGui"):FindFirstChild("Cmdr") == nil then
	StarterGui.Cmdr:Clone().Parent = Player.PlayerGui
end

local Interface = require(script.CmdrInterface)(Cmdr)

--- Sets a list of keyboard keys (Enum.KeyCode) that can be used to open the commands menu
function Cmdr:SetActivationKeys (keysArray)
	self.ActivationKeys = Util.MakeDictionary(keysArray)
end

--- Sets the place name label on the interface
function Cmdr:SetPlaceName (name)
	self.PlaceName = name
	Interface.Window:UpdateLabel()
end

--- Sets whether or not the console is enabled
function Cmdr:SetEnabled (enabled)
	self.Enabled = enabled
end

--- Sets if activation will free the mouse.
function Cmdr:SetActivationUnlocksMouse (enabled)
	self.ActivationUnlocksMouse = enabled
end

--- Shows Cmdr window
function Cmdr:Show ()
	if not self.Enabled then
		return
	end

	Interface.Window:Show()
end

--- Hides Cmdr window
function Cmdr:Hide ()
	Interface.Window:Hide()
end

--- Toggles Cmdr window
function Cmdr:Toggle ()
	if not self.Enabled then
		return self:Hide()
	end

	Interface.Window:SetVisible(not Interface.Window:IsVisible())
end

--- Enables the "Mash to open" feature
function Cmdr:SetMashToEnable(isEnabled)
	self.MashToEnable = isEnabled

	if isEnabled then
		self:SetEnabled(false)
	end
end

--- Sets the hide on 'lost focus' feature.
function Cmdr:SetHideOnLostFocus(enabled)
	self.HideOnLostFocus = enabled
end

--- Sets the handler for a certain event type
function Cmdr:HandleEvent(name, callback)
	self.Events[name] = callback
end

-- Only register when we aren't in studio because don't want to overwrite what the server portion did
if RunService:IsServer() == false then
	Cmdr.Registry:RegisterTypesIn(script:WaitForChild("Types"))
	Cmdr.Registry:RegisterCommandsIn(script:WaitForChild("Commands"))
end

-- Hook up event listener
Cmdr.RemoteEvent.OnClientEvent:Connect(function(name, ...)
	if Cmdr.Events[name] then
		Cmdr.Events[name](...)
	end
end)

require(script.DefaultEventHandlers)(Cmdr)

return Cmdr


-- ==== [ ServerScriptService.Modules.Cmdr.CmdrClient.CmdrInterface ] ==== --
-- Here be dragons

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

return function (Cmdr)
	local Util = Cmdr.Util

	local Window = require(script:WaitForChild("Window"))
	Window.Cmdr = Cmdr

	local AutoComplete = require(script:WaitForChild("AutoComplete"))(Cmdr)
	Window.AutoComplete = AutoComplete


	-- Sets the Window.ProcessEntry callback so that we can dispatch our commands out
	function Window.ProcessEntry(text)
		text = Util.TrimString(text)

		if #text == 0 then return end

		Window:AddLine(Window:GetLabel() .. " " .. text, Color3.fromRGB(255, 223, 93))

		Window:AddLine(Cmdr.Dispatcher:EvaluateAndRun(text, Player, {
			IsHuman = true
		}))
	end

	-- Sets the Window.OnTextChanged callback so we can update the auto complete
	function Window.OnTextChanged (text)
		local command = Cmdr.Dispatcher:Evaluate(text, Player, true)
		local arguments = Util.SplitString(text)
		local commandText = table.remove(arguments, 1)
		local atEnd = false
		if command then
			arguments = Util.MashExcessArguments(arguments, #command.Object.Args)

			atEnd = #arguments == #command.Object.Args
		end

		local entryComplete = commandText and #arguments > 0

		if text:sub(#text, #text):match("%s") and not atEnd then
			entryComplete = true
			arguments[#arguments + 1] = ""
		end

		if command and entryComplete then
			local commandValid, errorText = command:Validate()

			Window:SetIsValidInput(commandValid, ("Validation errors: %s"):format(errorText or ""))

			local acItems = {}

			local lastArgument = command:GetArgument(#arguments)
			if lastArgument then
				local typedText = lastArgument.TextSegmentInProgress

				local isPartial = false
				if lastArgument.RawSegmentsAreAutocomplete then
					for i, segment in ipairs(lastArgument.RawSegments) do
						acItems[i] = {segment, segment}
					end
				else
					local items, options = lastArgument:GetAutocomplete()
					options = options or {}
					isPartial = options.IsPartial or false

					for i, item in pairs(items) do
						acItems[i] = {typedText, item}
					end
				end

				local valid = true

				if #typedText > 0 then
					valid, errorText = lastArgument:Validate()
				end

				if not atEnd and valid then
					Window:HideInvalidState()
				end

				return AutoComplete:Show(acItems, {
					at = atEnd and #text - #typedText + (text:sub(#text, #text):match("%s") and -1 or 0);
					prefix = #lastArgument.RawSegments == 1 and lastArgument.Prefix or "";
					isLast = #command.Arguments == #command.ArgumentDefinitions and #typedText > 0;
					numArgs = #arguments;
					command = command;
					arg = lastArgument;
					name = lastArgument.Name .. (lastArgument.Required and "" or "?");
					type = lastArgument.Type.DisplayName;
					description = (valid == false and errorText) or lastArgument.Object.Description;
					invalid = not valid;
					isPartial = isPartial;
				})
			end
		elseif commandText and #arguments == 0 then
			Window:SetIsValidInput(true)
			local exactCommand = Cmdr.Registry:GetCommand(commandText)
			local exactMatch
			if exactCommand then
				exactMatch = {exactCommand.Name, exactCommand.Name, options = {
					name = exactCommand.Name;
					description = exactCommand.Description;
				}}

				local arg = exactCommand.Args and exactCommand.Args[1]

				if type(arg) == "function" then
					arg = arg(command)
				end

				if
					arg
					and (not arg.Optional
					and arg.Default == nil)
				then
					Window:SetIsValidInput(false, "This command has required arguments.")
					Window:HideInvalidState()
				end
			else
				Window:SetIsValidInput(false, ("%q is not a valid command name. Use the help command to see all available commands."):format(commandText))
			end

			local acItems = {exactMatch}
			for _, cmd in pairs(Cmdr.Registry:GetCommandNames()) do
				if commandText:lower() == cmd:lower():sub(1, #commandText) and (exactMatch == nil or exactMatch[1] ~= commandText) then
					local commandObject = Cmdr.Registry:GetCommand(cmd)
					acItems[#acItems + 1] = {commandText, cmd, options = {
						name = commandObject.Name;
						description = commandObject.Description;
					}}
				end
			end

			return AutoComplete:Show(acItems)
		end

		Window:SetIsValidInput(false, "Use the help command to see all available commands.")
		AutoComplete:Hide()
	end

	Window:UpdateLabel()
	Window:UpdateWindowHeight()

	return {
		Window = Window;
		AutoComplete = AutoComplete;
	}
end


-- ==== [ ServerScriptService.Modules.Cmdr.CmdrClient.CmdrInterface.AutoComplete ] ==== --
-- luacheck: ignore 212
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

return function(Cmdr)
	local AutoComplete = {
		Items = {},
		ItemOptions = {},
		SelectedItem = 0,
	}

	local Util = Cmdr.Util

	local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("Autocomplete")
	local AutoItem = Gui:WaitForChild("TextButton")
	local Title = Gui:WaitForChild("Title")
	local Description = Gui:WaitForChild("Description")
	local Entry = Gui.Parent:WaitForChild("Frame"):WaitForChild("Entry")
	AutoItem.Parent = nil

	local defaultBarThickness = Gui.ScrollBarThickness

	-- Helper function that sets text and resizes labels
	local function SetText(obj, textObj, text, sizeFromContents)
		obj.Visible = text ~= nil
		textObj.Text = text or ""

		if sizeFromContents then
			textObj.Size = UDim2.new(
				0,
				Util.GetTextSize(text or "", textObj, Vector2.new(1000, 1000), 1, 0).X,
				obj.Size.Y.Scale,
				obj.Size.Y.Offset
			)
		end
	end

	local function UpdateContainerSize()
		Gui.Size = UDim2.new(
			0,
			math.max(Title.Field.TextBounds.X + Title.Field.Type.TextBounds.X, Gui.Size.X.Offset),
			0,
			math.min(Gui.UIListLayout.AbsoluteContentSize.Y, Gui.Parent.AbsoluteSize.Y - Gui.AbsolutePosition.Y - 10)
		)
	end

	-- Update the info display (Name, type, and description) based on given options.
	local function UpdateInfoDisplay(options)
		-- Update the objects' text and sizes
		SetText(Title, Title.Field, options.name, true)
		SetText(
			Title.Field.Type,
			Title.Field.Type,
			options.type and ": " .. options.type:sub(1, 1):upper() .. options.type:sub(2)
		)
		SetText(Description, Description.Label, options.description)

		Description.Label.TextColor3 = options.invalid and Color3.fromRGB(255, 73, 73) or Color3.fromRGB(255, 255, 255)
		Description.Size = UDim2.new(1, 0, 0, 40)

		-- Flow description text
		while not Description.Label.TextFits do
			Description.Size = Description.Size + UDim2.new(0, 0, 0, 2)

			if Description.Size.Y.Offset > 500 then
				break
			end
		end

		-- Update container
		task.wait()
		Gui.UIListLayout:ApplyLayout()
		UpdateContainerSize()
		Gui.ScrollBarThickness = defaultBarThickness
	end

	--- Shows the auto complete menu with the given list and possible options
	-- item = {typedText, suggestedText, options?=options}
	-- The options table is optional. `at` should only be passed into AutoComplete::Show
	-- name, type, and description may be passed in an options dictionary inside the items as well
	-- options.at?: the character index at which to show the menu
	-- options.name?: The name to display in the info box
	-- options.type?: The type to display in the info box
	-- options.prefix?: The current type prefix (%Team)
	-- options.description?: The description for the currently active info box
	-- options.invalid?: If true, description is shown in red.
	-- options.isLast?: If true, auto complete won't keep going after this argument.
	function AutoComplete:Show(items, options)
		options = options or {}

		-- Remove old options.
		for _, item in pairs(self.Items) do
			if item.gui then
				item.gui:Destroy()
			end
		end

		-- Reset state
		self.SelectedItem = 1
		self.Items = items
		self.Prefix = options.prefix or ""
		self.LastItem = options.isLast or false
		self.Command = options.command
		self.Arg = options.arg
		self.NumArgs = options.numArgs
		self.IsPartial = options.isPartial

		-- Generate the new option labels
		local autocompleteWidth = 200

		Gui.ScrollBarThickness = 0

		for i, item in pairs(self.Items) do
			local leftText = item[1]
			local rightText = item[2]
			
			local btn = AutoItem:Clone()
			btn.Name = leftText .. rightText
			btn.BackgroundTransparency = i == self.SelectedItem and 0.5 or 1

			local start, stop = string.find(rightText:lower(), leftText:lower(), 1, true)
			btn.Typed.Text = string.rep(" ", start - 1) .. leftText
			btn.Suggest.Text = string.sub(rightText, 0, start - 1)
				.. string.rep(" ", #leftText)
				.. string.sub(rightText, stop + 1)


			btn.Parent = Gui
			btn.LayoutOrder = i

			local maxBounds = math.max(btn.Typed.TextBounds.X, btn.Suggest.TextBounds.X) + 20
			if maxBounds > autocompleteWidth then
				autocompleteWidth = maxBounds
			end

			item.gui = btn
		end

		Gui.UIListLayout:ApplyLayout()

		-- Todo: Use TextService to find accurate position for auto complete box
		local text = Entry.TextBox.Text
		local words = Util.SplitString(text)
		if text:sub(#text, #text) == " " and not options.at then
			words[#words + 1] = "e"
		end
		table.remove(words, #words)
		local extra = (options.at and options.at or (#table.concat(words, " ") + 1)) * 7

		-- Update the auto complete container
		Gui.Position =
			UDim2.new(0, Entry.TextBox.AbsolutePosition.X - 10 + extra, 0, Entry.TextBox.AbsolutePosition.Y + 30)
		Gui.Size = UDim2.new(0, autocompleteWidth, 0, Gui.UIListLayout.AbsoluteContentSize.Y)
		Gui.Visible = true

		-- Finally, update thge info display
		UpdateInfoDisplay(self.Items[1] and self.Items[1].options or options)
	end

	--- Returns the selected item in the auto complete
	function AutoComplete:GetSelectedItem()
		if Gui.Visible == false then
			return nil
		end

		return AutoComplete.Items[AutoComplete.SelectedItem]
	end

	--- Hides the auto complete
	function AutoComplete:Hide()
		Gui.Visible = false
	end

	--- Returns if the menu is visible
	function AutoComplete:IsVisible()
		return Gui.Visible
	end

	--- Changes the user's item selection by the given delta
	function AutoComplete:Select(delta)
		if not Gui.Visible then
			return
		end

		self.SelectedItem = self.SelectedItem + delta

		if self.SelectedItem > #self.Items then
			self.SelectedItem = 1
		elseif self.SelectedItem < 1 then
			self.SelectedItem = #self.Items
		end

		for i, item in pairs(self.Items) do
			item.gui.BackgroundTransparency = i == self.SelectedItem and 0.5 or 1
		end

		Gui.CanvasPosition = Vector2.new(
			0,
			math.max(
				0,
				Title.Size.Y.Offset
					+ Description.Size.Y.Offset
					+ self.SelectedItem * AutoItem.Size.Y.Offset
					- Gui.Size.Y.Offset
			)
		)

		if self.Items[self.SelectedItem] and self.Items[self.SelectedItem].options then
			UpdateInfoDisplay(self.Items[self.SelectedItem].options or {})
		end
	end

	Gui.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateContainerSize)

	return AutoComplete
end


-- ==== [ ServerScriptService.Modules.Cmdr.CmdrClient.CmdrInterface.Window ] ==== --
-- Here be dragons
-- luacheck: ignore 212
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local WINDOW_MAX_HEIGHT = 300
local MOUSE_TOUCH_ENUM = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.Touch }

--- Window handles the command bar GUI
local Window = {
	Valid = true,
	AutoComplete = nil,
	ProcessEntry = nil,
	OnTextChanged = nil,
	Cmdr = nil,
	HistoryState = nil,
}

local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("Frame")
local Line = Gui:WaitForChild("Line")
local Entry = Gui:WaitForChild("Entry")

Line.Parent = nil

--- Update the text entry label
function Window:UpdateLabel()
	Entry.TextLabel.Text = Player.Name .. "@" .. self.Cmdr.PlaceName .. "$"
end

--- Get the text entry label
function Window:GetLabel()
	return Entry.TextLabel.Text
end

--- Recalculate the window height
function Window:UpdateWindowHeight()
	local windowHeight = Gui.UIListLayout.AbsoluteContentSize.Y
		+ Gui.UIPadding.PaddingTop.Offset
		+ Gui.UIPadding.PaddingBottom.Offset
	Gui.Size = UDim2.new(Gui.Size.X.Scale, Gui.Size.X.Offset, 0, math.clamp(windowHeight, 0, WINDOW_MAX_HEIGHT))
	Gui.CanvasPosition = Vector2.new(0, windowHeight)
end

--- Add a line to the command bar
function Window:AddLine(text, options)
	options = options or {}
	text = tostring(text)

	if typeof(options) == "Color3" then
		options = { Color = options }
	end

	if #text == 0 then
		Window:UpdateWindowHeight()
		return
	end

	local str = self.Cmdr.Util.EmulateTabstops(text or "nil", 8)

	local line = Line:Clone()
	line.Text = str
	line.TextColor3 = options.Color or line.TextColor3
	line.RichText = options.RichText or false
	line.Parent = Gui
end

--- Returns if the command bar is visible
function Window:IsVisible()
	return Gui.Visible
end

--- Sets the command bar visible or not
function Window:SetVisible(visible)
	Gui.Visible = visible

	if visible then
		self.PreviousChatWindowConfigurationEnabled = TextChatService.ChatWindowConfiguration.Enabled
		self.PreviousChatInputBarConfigurationEnabled = TextChatService.ChatInputBarConfiguration.Enabled
		TextChatService.ChatWindowConfiguration.Enabled = false
		TextChatService.ChatInputBarConfiguration.Enabled = false

		Entry.TextBox:CaptureFocus()
		self:SetEntryText("")

		if self.Cmdr.ActivationUnlocksMouse then
			self.PreviousMouseBehavior = UserInputService.MouseBehavior
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	else
		TextChatService.ChatWindowConfiguration.Enabled = if self.PreviousChatWindowConfigurationEnabled ~= nil then 
			self.PreviousChatWindowConfigurationEnabled else true
		TextChatService.ChatInputBarConfiguration.Enabled = if self.PreviousChatInputBarConfigurationEnabled ~= nil then 
			self.PreviousChatInputBarConfigurationEnabled else true

		Entry.TextBox:ReleaseFocus()
		self.AutoComplete:Hide()

		if self.PreviousMouseBehavior then
			UserInputService.MouseBehavior = self.PreviousMouseBehavior
			self.PreviousMouseBehavior = nil
		end
	end
end

--- Hides the command bar
function Window:Hide()
	return self:SetVisible(false)
end

--- Shows the command bar
function Window:Show()
	return self:SetVisible(true)
end

--- Sets the text in the command bar text box, and captures focus
function Window:SetEntryText(text)
	Entry.TextBox.Text = text

	if self:IsVisible() then
		Entry.TextBox:CaptureFocus()
		Entry.TextBox.CursorPosition = #text + 1
		Window:UpdateWindowHeight()
	end
end

--- Gets the text in the command bar text box
function Window:GetEntryText()
	return Entry.TextBox.Text:gsub("\t", "")
end

--- Sets whether the command is in a valid state or not.
-- Cannot submit if in invalid state.
function Window:SetIsValidInput(isValid, errorText)
	Entry.TextBox.TextColor3 = isValid and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 73, 73)
	self.Valid = isValid
	self._errorText = errorText
end

function Window:HideInvalidState()
	Entry.TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
end

--- Event handler for text box focus lost
function Window:LoseFocus(submit)
	local text = Entry.TextBox.Text

	self:ClearHistoryState()

	if Gui.Visible and not GuiService.MenuIsOpen then
		-- self:SetEntryText("")
		Entry.TextBox:CaptureFocus()
	elseif GuiService.MenuIsOpen and Gui.Visible then
		self:Hide()
	end

	if submit and self.Valid then
		wait()
		self:SetEntryText("")
		self.ProcessEntry(text)
	elseif submit then
		self:AddLine(self._errorText, Color3.fromRGB(255, 153, 153))
	end
end

function Window:TraverseHistory(delta)
	local history = self.Cmdr.Dispatcher:GetHistory()

	if self.HistoryState == nil then
		self.HistoryState = {
			Position = #history + 1,
			InitialText = self:GetEntryText(),
		}
	end

	self.HistoryState.Position = math.clamp(self.HistoryState.Position + delta, 1, #history + 1)

	self:SetEntryText(
		self.HistoryState.Position == #history + 1 and self.HistoryState.InitialText
			or history[self.HistoryState.Position]
	)
end

function Window:ClearHistoryState()
	self.HistoryState = nil
end

function Window:SelectVertical(delta)
	if self.AutoComplete:IsVisible() and not self.HistoryState then
		self.AutoComplete:Select(delta)
	else
		self:TraverseHistory(delta)
	end
end

local lastPressTime = 0
local pressCount = 0
--- Handles user input when the box is focused
function Window:BeginInput(input, gameProcessed)
	if GuiService.MenuIsOpen then
		self:Hide()
	end

	if gameProcessed and self:IsVisible() == false then
		return
	end

	if self.Cmdr.ActivationKeys[input.KeyCode] then -- Activate the command bar
		if self.Cmdr.MashToEnable and not self.Cmdr.Enabled then
			if tick() - lastPressTime < 1 then
				if pressCount >= 5 then
					return self.Cmdr:SetEnabled(true)
				else
					pressCount = pressCount + 1
				end
			else
				pressCount = 1
			end
			lastPressTime = tick()
		elseif self.Cmdr.Enabled then
			self:SetVisible(not self:IsVisible())
			wait()
			self:SetEntryText("")

			if GuiService.MenuIsOpen then -- Special case for menu getting stuck open (roblox bug)
				self:Hide()
			end
		end

		return
	end

	if self.Cmdr.Enabled == false or not self:IsVisible() then
		if self:IsVisible() then
			self:Hide()
		end

		return
	end

	if self.Cmdr.HideOnLostFocus and table.find(MOUSE_TOUCH_ENUM, input.UserInputType) then
		local ps = input.Position
		local ap = Gui.AbsolutePosition
		local as = Gui.AbsoluteSize
		if ps.X < ap.X or ps.X > ap.X + as.X or ps.Y < ap.Y or ps.Y > ap.Y + as.Y then
			self:Hide()
		end
	elseif input.KeyCode == Enum.KeyCode.Down then -- Auto Complete Down
		self:SelectVertical(1)
	elseif input.KeyCode == Enum.KeyCode.Up then -- Auto Complete Up
		self:SelectVertical(-1)
	elseif input.KeyCode == Enum.KeyCode.Return then -- Eat new lines
		wait()
		self:SetEntryText(self:GetEntryText():gsub("\n", ""):gsub("\r", ""))
	elseif input.KeyCode == Enum.KeyCode.Tab then -- Auto complete
		local item = self.AutoComplete:GetSelectedItem()
		local text = self:GetEntryText()
		if item and not (text:sub(#text, #text):match("%s") and self.AutoComplete.LastItem) then
			local replace = item[2]
			local newText
			local insertSpace = true
			local command = self.AutoComplete.Command

			if command then
				local lastArg = self.AutoComplete.Arg

				newText = command.Alias
				insertSpace = self.AutoComplete.NumArgs ~= #command.ArgumentDefinitions
					and self.AutoComplete.IsPartial == false

				local args = command.Arguments
				for i = 1, #args do
					local arg = args[i]
					local segments = arg.RawSegments
					if arg == lastArg then
						segments[#segments] = replace
					end

					local argText = arg.Prefix .. table.concat(segments, ",")

					-- Put auto completion options in quotation marks if they have a space
					if argText:find(" ") or argText == "" then
						argText = ("%q"):format(argText)
					end

					newText = ("%s %s"):format(newText, argText)

					if arg == lastArg then
						break
					end
				end
			else
				newText = replace
			end
			-- need to wait a frame so we can eat the \t
			wait()
			-- Update the text box
			self:SetEntryText(newText .. (insertSpace and " " or ""))
		else
			-- Still need to eat the \t even if there is no auto-complete to show
			wait()
			self:SetEntryText(self:GetEntryText())
		end
	else
		self:ClearHistoryState()
	end
end

-- Hook events
Entry.TextBox.FocusLost:Connect(function(submit)
	return Window:LoseFocus(submit)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	return Window:BeginInput(input, gameProcessed)
end)

Entry.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
	Gui.CanvasPosition = Vector2.new(0, Gui.AbsoluteCanvasSize.Y)

	if Entry.TextBox.Text:match("\t") then -- Eat \t
		Entry.TextBox.Text = Entry.TextBox.Text:gsub("\t", "")
		return
	end
	if Window.OnTextChanged then
		return Window.OnTextChanged(Entry.TextBox.Text)
	end
end)

Gui.ChildAdded:Connect(function()
	task.defer(Window.UpdateWindowHeight)
end)

return Window


-- ==== [ ServerScriptService.Modules.Cmdr.CmdrClient.DefaultEventHandlers ] ==== --
local StarterGui = game:GetService("StarterGui")
local Window = require(script.Parent.CmdrInterface.Window)

return function (Cmdr)
	Cmdr:HandleEvent("Message", function (text)
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = ("[Announcement] %s"):format(text);
			Color = Color3.fromRGB(249, 217, 56);
		})
	end)

	Cmdr:HandleEvent("AddLine", function (...)
		Window:AddLine(...)
	end)
end

-- ==== [ ServerScriptService.Modules.Cmdr.CreateGui ] ==== --
return function()
	local Cmdr = Instance.new("ScreenGui")
	Cmdr.DisplayOrder = 1000
	Cmdr.Name = "Cmdr"
	Cmdr.ResetOnSpawn = false
	Cmdr.AutoLocalize = false

	local Frame = Instance.new("ScrollingFrame")
	Frame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	Frame.BackgroundTransparency = 0.4
	Frame.BorderSizePixel = 0
	Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	Frame.Name = "Frame"
	Frame.Position = UDim2.new(0.025, 0, 0, 25)
	Frame.ScrollBarThickness = 6
	Frame.ScrollingDirection = Enum.ScrollingDirection.Y
	Frame.Selectable = false
	Frame.Size = UDim2.new(0.95, 0, 0, 0)
	Frame.Visible = false
	Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Frame.Parent = Cmdr

	local Autocomplete = Instance.new("ScrollingFrame")
	Autocomplete.BackgroundColor3 = Color3.fromRGB(59, 59, 59)
	Autocomplete.BackgroundTransparency = 0.5
	Autocomplete.BorderSizePixel = 0
	Autocomplete.CanvasSize = UDim2.new(0, 0, 0, 0)
	Autocomplete.Name = "Autocomplete"
	Autocomplete.Position = UDim2.new(0, 167, 0, 75)
	Autocomplete.ScrollBarThickness = 6
	Autocomplete.ScrollingDirection = Enum.ScrollingDirection.Y
	Autocomplete.Selectable = false
	Autocomplete.Size = UDim2.new(0, 200, 0, 200)
	Autocomplete.Visible = false
	Autocomplete.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Autocomplete.Parent = Cmdr

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = Frame

	local Line = Instance.new("TextBox")
	Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Line.BackgroundTransparency = 1
	Line.Font = Enum.Font.Code
	Line.Name = "Line"
	Line.Size = UDim2.new(1, 0, 0, 20)
	Line.AutomaticSize = Enum.AutomaticSize.Y
	Line.TextColor3 = Color3.fromRGB(255, 255, 255)
	Line.TextSize = 14
	Line.TextXAlignment = Enum.TextXAlignment.Left
	Line.TextEditable = false
	Line.ClearTextOnFocus = false
	Line.Parent = Frame

	local UIPadding = Instance.new("UIPadding")
	UIPadding.PaddingBottom = UDim.new(0, 10)
	UIPadding.PaddingLeft = UDim.new(0, 10)
	UIPadding.PaddingRight = UDim.new(0, 10)
	UIPadding.PaddingTop = UDim.new(0, 10)
	UIPadding.Parent = Frame

	local Entry = Instance.new("Frame")
	Entry.BackgroundTransparency = 1
	Entry.LayoutOrder = 999999999
	Entry.Name = "Entry"
	Entry.Size = UDim2.new(1, 0, 0, 20)
	Entry.Parent = Frame

	local UIListLayout2 = Instance.new("UIListLayout")
	UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout2.Parent = Autocomplete

	local Title = Instance.new("Frame")
	Title.BackgroundColor3 = Color3.fromRGB(59, 59, 59)
	Title.BackgroundTransparency = 0.2
	Title.BorderSizePixel = 0
	Title.LayoutOrder = -2
	Title.Name = "Title"
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Parent = Autocomplete

	local Description = Instance.new("Frame")
	Description.BackgroundColor3 = Color3.fromRGB(59, 59, 59)
	Description.BackgroundTransparency = 0.2
	Description.BorderSizePixel = 0
	Description.LayoutOrder = -1
	Description.Name = "Description"
	Description.Size = UDim2.new(1, 0, 0, 20)
	Description.Parent = Autocomplete

	local TextButton = Instance.new("TextButton")
	TextButton.BackgroundColor3 = Color3.fromRGB(59, 59, 59)
	TextButton.BackgroundTransparency = 0.5
	TextButton.BorderSizePixel = 0
	TextButton.Font = Enum.Font.Code
	TextButton.Size = UDim2.new(1, 0, 0, 30)
	TextButton.Text = ""
	TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextButton.TextSize = 14
	TextButton.TextXAlignment = Enum.TextXAlignment.Left
	TextButton.Parent = Autocomplete

	local UIListLayout3 = Instance.new("UIListLayout")
	UIListLayout3.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout3.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout3.Padding = UDim.new(0, 7)
	UIListLayout3.Parent = Entry

	local TextBox = Instance.new("TextBox")
	TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.BackgroundTransparency = 1
	TextBox.ClearTextOnFocus = false
	TextBox.Font = Enum.Font.Code
	TextBox.LayoutOrder = 999999999
	TextBox.Position = UDim2.new(0, 140, 0, 0)
	TextBox.Size = UDim2.new(1, 0, 0, 20)
	TextBox.Text = "x"
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.TextSize = 14
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.Selectable = false
	TextBox.Parent = Entry

	local TextLabel = Instance.new("TextLabel")
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.BackgroundTransparency = 1
	TextLabel.Font = Enum.Font.Code
	TextLabel.Size = UDim2.new(0, 0, 0, 20)
	TextLabel.AutomaticSize = Enum.AutomaticSize.X
	TextLabel.Text = ""
	TextLabel.TextColor3 = Color3.fromRGB(255, 223, 93)
	TextLabel.TextSize = 14
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.Parent = Entry

	local Field = Instance.new("TextLabel")
	Field.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Field.BackgroundTransparency = 1
	Field.Font = Enum.Font.SourceSansBold
	Field.Name = "Field"
	Field.Size = UDim2.new(0, 37, 1, 0)
	Field.Text = "from"
	Field.TextColor3 = Color3.fromRGB(255, 255, 255)
	Field.TextSize = 20
	Field.TextXAlignment = Enum.TextXAlignment.Left
	Field.Parent = Title

	local UIPadding2 = Instance.new("UIPadding")
	UIPadding2.PaddingLeft = UDim.new(0, 10)
	UIPadding2.Parent = Title

	local Label = Instance.new("TextLabel")
	Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.SourceSansLight
	Label.Name = "Label"
	Label.Size = UDim2.new(1, 0, 1, 0)
	Label.Text = "The players to teleport. The players to teleport. The players to teleport. The players to teleport. "
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.TextSize = 16
	Label.TextWrapped = true
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextYAlignment = Enum.TextYAlignment.Top
	Label.Parent = Description

	local UIPadding3 = Instance.new("UIPadding")
	UIPadding3.PaddingBottom = UDim.new(0, 10)
	UIPadding3.PaddingLeft = UDim.new(0, 10)
	UIPadding3.PaddingRight = UDim.new(0, 10)
	UIPadding3.Parent = Description

	local Typed = Instance.new("TextLabel")
	Typed.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Typed.BackgroundTransparency = 1
	Typed.Font = Enum.Font.Code
	Typed.Name = "Typed"
	Typed.Size = UDim2.new(1, 0, 1, 0)
	Typed.Text = "Lab"
	Typed.TextColor3 = Color3.fromRGB(131, 222, 255)
	Typed.TextSize = 14
	Typed.TextXAlignment = Enum.TextXAlignment.Left
	Typed.Parent = TextButton

	local UIPadding4 = Instance.new("UIPadding")
	UIPadding4.PaddingLeft = UDim.new(0, 10)
	UIPadding4.Parent = TextButton

	local Suggest = Instance.new("TextLabel")
	Suggest.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Suggest.BackgroundTransparency = 1
	Suggest.Font = Enum.Font.Code
	Suggest.Name = "Suggest"
	Suggest.Size = UDim2.new(1, 0, 1, 0)
	Suggest.Text = "   el"
	Suggest.TextColor3 = Color3.fromRGB(255, 255, 255)
	Suggest.TextSize = 14
	Suggest.TextXAlignment = Enum.TextXAlignment.Left
	Suggest.Parent = TextButton

	local Type = Instance.new("TextLabel")
	Type.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Type.BackgroundTransparency = 1
	Type.BorderColor3 = Color3.fromRGB(255, 153, 153)
	Type.Font = Enum.Font.SourceSans
	Type.Name = "Type"
	Type.Position = UDim2.new(1, 0, 0, 0)
	Type.Size = UDim2.new(0, 0, 1, 0)
	Type.Text = ": Players"
	Type.TextColor3 = Color3.fromRGB(255, 255, 255)
	Type.TextSize = 15
	Type.TextXAlignment = Enum.TextXAlignment.Left
	Type.Parent = Field

	Cmdr.Parent = game:GetService("StarterGui")
	return Cmdr
end


-- ==== [ ServerScriptService.Modules.Cmdr.Initialize ] ==== --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local CreateGui = require(script.Parent.CreateGui)

--- Handles initial preparation of the game server-side.
return function (cmdr)
	local ReplicatedRoot, RemoteFunction, RemoteEvent

	local function Create (class, name, parent)
		local object = Instance.new(class)
		object.Name = name
		object.Parent = parent or ReplicatedRoot

		return object
	end

	ReplicatedRoot = script.Parent.CmdrClient
	ReplicatedRoot.Parent = ReplicatedStorage

	RemoteFunction = Create("RemoteEvent", "CmdrFunction")
	RemoteEvent = Create("RemoteEvent", "CmdrEvent")

	Create("Folder", "Commands")
	Create("Folder", "Types")

	script.Parent.Shared.Parent = ReplicatedRoot

	cmdr.ReplicatedRoot = ReplicatedRoot
	cmdr.RemoteFunction = RemoteFunction
	cmdr.RemoteEvent = RemoteEvent

	cmdr:RegisterTypesIn(script.Parent.BuiltInTypes)

	script.Parent.BuiltInTypes:Destroy()
	script.Parent.BuiltInCommands.Name = "Server commands"

	if StarterGui:FindFirstChild("Cmdr") == nil then
		CreateGui()
	end
end


-- ==== [ ServerScriptService.Modules.ProfileStore ] ==== --
--[[
MAD STUDIO (by loleris)

-[ProfileStore]---------------------------------------

	Periodic DataStore saving solution with session locking
	
	WARNINGS FOR "Profile.Data" VALUES:
	 	! Do not create numeric tables with gaps - attempting to store such tables will result in an error.
		! Do not create mixed tables (some values indexed by number and others by a string key)
			- only numerically indexed  data will be stored.
		! Do not index tables by anything other than numbers and strings.
		! Do not reference Roblox Instances
		! Do not reference userdata (Vector3, Color3, CFrame...) - Serialize userdata before referencing
		! Do not reference functions
		
	Members:
	
		ProfileStore.IsClosing          [bool]
			-- Set to true after a game:BindToClose() trigger
			
		ProfileStore.IsCriticalState    [bool]
			-- Set to true when ProfileStore experiences too many consecutive errors
		
		ProfileStore.OnError            [Signal] (message, store_name, profile_key)
			-- Most ProfileStore errors will be caught and passed to this signal
			
		ProfileStore.OnOverwrite        [Signal] (store_name, profile_key)
			-- Triggered when a DataStore key was likely used to store data that wasn't
			a ProfileStore profile or the ProfileStore structure was invalidly manually
			altered for that DataStore key
			
		ProfileStore.OnCriticalToggle   [Signal] (is_critical)
			-- Triggered when ProfileStore experiences too many consecutive errors
		
		ProfileStore.DataStoreState     [string] ("NotReady", "NoInternet", "NoAccess", "Access")
			-- This value resembles ProfileStore's access to the DataStore; The value starts
			as "NotReady" and will eventually change to one of the other 3 possible values.
	
	Functions:
	
		ProfileStore.New(store_name, template?) --> [ProfileStore]
			store_name   [string] -- DataStore name
			template     [table] or nil -- Profiles will default to given table (hard-copy) when no data was saved previously
			
		ProfileStore.SetConstant(name, value)
			name    [string]
			value   [number]
				
	Members [ProfileStore]:
	
		ProfileStore.Mock   [ProfileStore]
			-- Reflection of ProfileStore methods, but the methods will now query a mock
			DataStore with no relation to the real DataStore
			
		ProfileStore.Name   [string]
		
	Methods [ProfileStore]:
	
		ProfileStore:StartSessionAsync(profile_key, params?) --> [Profile] or nil
			profile_key [string] -- DataStore key
			params      nil or [table]: -- Custom params; E.g. {Steal = true}
				{
					Steal = true, -- Pass this to disregard an existing session lock
					Cancel = fn() -> (boolean), -- Pass this to create a request cancel condition.
						-- If the cancel function returns true, ProfileStore will stop trying to
						-- start the session and return nil
				}
			
		ProfileStore:MessageAsync(profile_key, message) --> is_success [bool]
			profile_key [string] -- DataStore key
			message     [table] -- Data to be messaged to the profile
			
		ProfileStore:GetAsync(profile_key, version?) --> [Profile] or nil
			-- Reads a profile without starting a session - will not autosave
			profile_key   [string] -- DataStore key
			version       nil or [string] -- DataStore key version

		ProfileStore:VersionQuery(profile_key, sort_direction?, min_date?, max_date?) --> [VersionQuery]
			profile_key      [string]
			sort_direction   nil or [Enum.SortDirection]
			min_date         nil or [DateTime]
			max_date         nil or [DateTime]
			
		ProfileStore:RemoveAsync(profile_key) --> is_success [bool]
			-- Completely removes profile data from the DataStore / mock DataStore with no way to recover it.

	Methods [VersionQuery]:

		VersionQuery:NextAsync() --> [Profile] or nil -- (Yields)
			-- Returned profile is similar to profiles returned by ProfileStore:GetAsync()
		
	Members [Profile]:
	
		Profile.Data               [table]
			-- When the profile is active changes to this table are guaranteed to be saved
		Profile.LastSavedData      [table] (Read-only)
			-- Last snapshot of "Profile.Data" that has been successfully saved to the DataStore;
			Useful for proper developer product purchase receipt handling
		
		Profile.FirstSessionTime   [number] (Read-only)
			-- os.time() timestamp of the first profile session
			
		Profile.SessionLoadCount   [number] (Read-only) -- Amount of times a session was started for this profile
			
		Profile.Session            [table] (Read-only) {PlaceId = number, JobId = string} / nil
			-- Set to a table if this profile is in use by a server; nil if released

		Profile.RobloxMetaData     [table] -- Writable table that gets saved automatically and once the profile is released
		Profile.UserIds            [table] -- (Read-only) -- {user_id [number], ...} -- User ids associated with this profile

		Profile.KeyInfo            [DataStoreKeyInfo] -- Changes before OnAfterSave signal
		
		Profile.OnSave             [Signal] ()
			-- Triggered right before changes to Profile.Data are saved to the DataStore
			
		Profile.OnLastSave         [Signal] (reason [string]: "Manual", "External", "Shutdown")
			-- Triggered right before changes to Profile.Data are saved to the DataStore
			for the last time; A reason is provided for the last save:
				- "Manual"   - Profile:EndSession() was called
				- "Shutdown" - The server that has ownership of this profile is shutting down
				- "External" - Another server has started a session for this profile
			Note that this event will not trigger for when a profile session is ended by
			another server trying to take ownership of the session - this is impossible to
			do without compromising on ProfileStore's speed.
			
		Profile.OnSessionEnd       [Signal] ()
			-- Triggered when the profile session is terminated on this server
		
		Profile.OnAfterSave        [Signal] (last_saved_data)
			-- Triggered after a successful save
			last_saved_data [table] -- Profile.LastSavedData
			
		Profile.ProfileStore       [ProfileStore] -- ProfileStore object this profile belongs to
		Profile.Key                [string] -- DataStore key
		
	Methods [Profile]:
	
		Profile:IsActive() --> [bool] -- If "true" is returned, changes to Profile.Data are guaranteed to save;
			This guarantee is only valid until code yields (e.g. task.wait() is used).
			
		Profile:Reconcile() -- Fills in missing (nil) [string_key] = [value] pairs to the Profile.Data structure
			from the "template" argument that was passed to "ProfileStore.New()"
			
		Profile:EndSession() -- Call after the server has finished working with this profile
			e.g., after the player leaves (Profile object will become inactive)

		Profile:AddUserId(user_id) -- Associates user_id with profile (GDPR compliance)
			user_id   [number]

		Profile:RemoveUserId(user_id) -- Removes user_id association with profile (safe function)
			user_id   [number]
			
		Profile:MessageHandler(fn) -- Sets a message handler for this profile
			fn [function] (message [table], processed [function]())
			-- The handler function receives a message table and a callback function;
			The callback function is to be called when a message has been processed
			- this will discard the message from the profile message cache; If the
			callback function is not called, other message handlers will also be triggered
			with unprocessed message data.
			
		Profile:Save() -- If the profile session is still active makes an UpdateAsync call
			to the DataStore to immediately save profile data

		Profile:SetAsync() -- Forcefully saves changes to the profile; Only for profiles
			loaded with ProfileStore:GetAsync() or ProfileStore:VersionQuery()
		
--]]

local AUTO_SAVE_PERIOD = 300 -- (Seconds) Time between when changes to a profile are saved to the DataStore
local LOAD_REPEAT_PERIOD = 10 -- (Seconds) Time between successive profile reads when handling a session conflict
local FIRST_LOAD_REPEAT = 5 -- (Seconds) Time between first and second profile read when handling a session conflict
local SESSION_STEAL = 40 -- (Seconds) Time until a session conflict is resolved with the waiting server stealing the session
local ASSUME_DEAD = 630 -- (Seconds) If a profile hasn't had updates for this long, quickly assume an active session belongs to a crashed server
local START_SESSION_TIMEOUT = 120 -- (Seconds) If a session can't be started for a profile for this long, stop repeating calls to the DataStore

local CRITICAL_STATE_ERROR_COUNT = 5 -- Assume critical state if this many issues happen in a short amount of time
local CRITICAL_STATE_ERROR_EXPIRE = 120 -- (Seconds) Individual issue expiration
local CRITICAL_STATE_EXPIRE = 120 -- (Seconds) Critical state expiration

local MAX_MESSAGE_QUEUE = 1000 -- Max messages saved in a profile that were sent using "ProfileStore:MessageAsync()"

----- Dependencies -----

-- local Util = require(game.ReplicatedStorage.Shared.Util)
-- local Signal = Util.Signal

local Signal do

	local FreeRunnerThread

	--[[
		Yield-safe coroutine reusing by stravant;
		Sources:
		https://devforum.roblox.com/t/lua-signal-class-comparison-optimal-goodsignal-class/1387063
		https://gist.github.com/stravant/b75a322e0919d60dde8a0316d1f09d2f
	--]]

	local function AcquireRunnerThreadAndCallEventHandler(fn, ...)
		local acquired_runner_thread = FreeRunnerThread
		FreeRunnerThread = nil
		fn(...)
		-- The handler finished running, this runner thread is free again.
		FreeRunnerThread = acquired_runner_thread
	end

	local function RunEventHandlerInFreeThread(...)
		AcquireRunnerThreadAndCallEventHandler(...)
		while true do
			AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
		end
	end

	local Connection = {}
	Connection.__index = Connection

	local SignalClass = {}
	SignalClass.__index = SignalClass

	function Connection:Disconnect()

		if self.is_connected == false then
			return
		end

		local signal = self.signal
		self.is_connected = false
		signal.listener_count -= 1

		if signal.head == self then
			signal.head = self.next
		else
			local prev = signal.head
			while prev ~= nil and prev.next ~= self do
				prev = prev.next
			end
			if prev ~= nil then
				prev.next = self.next
			end
		end

	end

	function SignalClass.New()

		local self = {
			head = nil,
			listener_count = 0,
		}
		setmetatable(self, SignalClass)

		return self

	end

	function SignalClass:Connect(listener: (...any) -> ())

		if type(listener) ~= "function" then
			error(`[{script.Name}]: \"listener\" must be a function; Received {typeof(listener)}`)
		end

		local connection = {
			listener = listener,
			signal = self,
			next = self.head,
			is_connected = true,
		}
		setmetatable(connection, Connection)

		self.head = connection
		self.listener_count += 1

		return connection

	end

	function SignalClass:GetListenerCount(): number
		return self.listener_count
	end

	function SignalClass:Fire(...)
		local item = self.head
		while item ~= nil do
			if item.is_connected == true then
				if not FreeRunnerThread then
					FreeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
				end
				task.spawn(FreeRunnerThread, item.listener, ...)
			end
			item = item.next
		end
	end

	function SignalClass:Wait()
		local co = coroutine.running()
		local connection
		connection = self:Connect(function(...)
			connection:Disconnect()
			task.spawn(co, ...)
		end)
		return coroutine.yield()
	end

	Signal = table.freeze({
		New = SignalClass.New,
	})

end

----- Private -----

local ActiveSessionCheck = {} -- {[session_token] = profile, ...}
local AutoSaveList = {} -- {profile, ...} -- Loaded profile table which will be circularly auto-saved
local IssueQueue = {} -- {issue_time, ...}

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PlaceId = game.PlaceId
local JobId = game.JobId

local AutoSaveIndex = 1 -- Next profile to auto save
local LastAutoSave = os.clock()

local LoadIndex = 0

local ActiveProfileLoadJobs = 0 -- Number of active threads that are loading in profiles
local ActiveProfileSaveJobs = 0 -- Number of active threads that are saving profiles

local CriticalStateStart = 0 -- os.clock()

local IsStudio = RunService:IsStudio()
local DataStoreState: "NotReady" | "NoInternet" | "NoAccess" | "Access" = "NotReady"

local MockStore = {}
local UserMockStore = {}
local MockFlag = false

local OnError = Signal.New() -- (message, store_name, profile_key)
local OnOverwrite = Signal.New() -- (store_name, profile_key)

local UpdateQueue = { -- For stability sake, we won't do UpdateAsync calls for the same key until all previous calls finish
	--[[
		[session_token] = {
			coroutine, ...
		},
		...
	--]]
}

local function WaitInUpdateQueue(session_token) --> next_in_queue()

	local is_first = false

	if UpdateQueue[session_token] == nil then
		is_first = true
		UpdateQueue[session_token] = {}
	end

	local queue = UpdateQueue[session_token]

	if is_first == false then
		table.insert(queue, coroutine.running())
		coroutine.yield()
	end

	return function()
		local next_co = table.remove(queue, 1)
		if next_co ~= nil then
			coroutine.resume(next_co)
		else
			UpdateQueue[session_token] = nil
		end
	end

end

local function SessionToken(store_name, profile_key, is_mock)

	local session_token = "L_" -- Live

	if is_mock == true then
		session_token = "U_" -- User mock
	elseif DataStoreState ~= "Access" then
		session_token = "M_" -- Mock, cause no DataStore access
	end

	session_token ..= store_name .. "\0" .. profile_key

	return session_token

end

local function DeepCopyTable(t)
	local copy = {}
	for key, value in pairs(t) do
		if type(value) == "table" then
			copy[key] = DeepCopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function ReconcileTable(target, template)
	for k, v in pairs(template) do
		if type(k) == "string" then -- Only string keys will be reconciled
			if target[k] == nil then
				if type(v) == "table" then
					target[k] = DeepCopyTable(v)
				else
					target[k] = v
				end
			elseif type(target[k]) == "table" and type(v) == "table" then
				ReconcileTable(target[k], v)
			end
		end
	end
end

local function RegisterError(error_message, store_name, profile_key) -- Called when a DataStore API call errors
	warn(`[{script.Name}]: DataStore API error (STORE:{store_name}; KEY:{profile_key}) - {tostring(error_message)}`)
	table.insert(IssueQueue, os.clock()) -- Adding issue time to queue
	OnError:Fire(tostring(error_message), store_name, profile_key)
end

local function RegisterOverwrite(store_name, profile_key) -- Called when a corrupted profile is loaded
	warn(`[{script.Name}]: Invalid profile was overwritten (STORE:{store_name}; KEY:{profile_key})`)
	OnOverwrite:Fire(store_name, profile_key)
end

local function NewMockDataStoreKeyInfo(params)

	local version_id_string = tostring(params.VersionId or 0)
	local meta_data = params.MetaData or {}
	local user_ids = params.UserIds or {}

	return {
		CreatedTime = params.CreatedTime,
		UpdatedTime = params.UpdatedTime,
		Version = string.rep("0", 16) .. "."
			.. string.rep("0", 10 - string.len(version_id_string)) .. version_id_string
			.. "." .. string.rep("0", 16) .. "." .. "01",

		GetMetadata = function()
			return DeepCopyTable(meta_data)
		end,

		GetUserIds = function()
			return DeepCopyTable(user_ids)
		end,
	}

end

local function MockUpdateAsync(mock_data_store, profile_store_name, key, transform_function, is_get_call) --> loaded_data, key_info

	local profile_store = mock_data_store[profile_store_name]

	if profile_store == nil then
		profile_store = {}
		mock_data_store[profile_store_name] = profile_store
	end

	local epoch_time = math.floor(os.time() * 1000)
	local mock_entry = profile_store[key]
	local mock_entry_was_nil = false

	if mock_entry == nil then
		mock_entry_was_nil = true
		if is_get_call ~= true then
			mock_entry = {
				Data = nil,
				CreatedTime = epoch_time,
				UpdatedTime = epoch_time,
				VersionId = 0,
				UserIds = {},
				MetaData = {},
			}
			profile_store[key] = mock_entry
		end
	end

	local mock_key_info = mock_entry_was_nil == false and NewMockDataStoreKeyInfo(mock_entry) or nil

	local transform, user_ids, roblox_meta_data = transform_function(mock_entry and mock_entry.Data, mock_key_info)

	if transform == nil then
		return nil
	else
		if mock_entry ~= nil and is_get_call ~= true then
			mock_entry.Data = DeepCopyTable(transform)
			mock_entry.UserIds = DeepCopyTable(user_ids or {})
			mock_entry.MetaData = DeepCopyTable(roblox_meta_data or {})
			mock_entry.VersionId += 1
			mock_entry.UpdatedTime = epoch_time
		end

		return DeepCopyTable(transform), mock_entry ~= nil and NewMockDataStoreKeyInfo(mock_entry) or nil
	end

end

local function UpdateAsync(profile_store, profile_key, transform_params, is_user_mock, is_get_call, version) --> loaded_data, key_info
	--transform_params = {
	--	ExistingProfileHandle = function(latest_data),
	--	MissingProfileHandle = function(latest_data),
	--	EditProfile = function(latest_data),
	--}

	local loaded_data, key_info

	local next_in_queue = WaitInUpdateQueue(SessionToken(profile_store.Name, profile_key, is_user_mock))

	local success = true

	local success, error_message = pcall(function()
		local transform_function = function(latest_data)

			local missing_profile = false
			local overwritten = false
			local global_updates = {0, {}}

			if latest_data == nil then

				missing_profile = true

			elseif type(latest_data) ~= "table" then

				missing_profile = true
				overwritten = true

			else

				if type(latest_data.Data) == "table" and type(latest_data.MetaData) == "table" and type(latest_data.GlobalUpdates) == "table" then

					-- Regular profile structure detected:

					latest_data.WasOverwritten = false -- Must be set to false if set previously
					global_updates = latest_data.GlobalUpdates

					if transform_params.ExistingProfileHandle ~= nil then
						transform_params.ExistingProfileHandle(latest_data)
					end

				elseif latest_data.Data == nil and latest_data.MetaData == nil and type(latest_data.GlobalUpdates) == "table" then

					-- Regular structure not detected, but GlobalUpdate data exists:

					latest_data.WasOverwritten = false -- Must be set to false if set previously
					global_updates = latest_data.GlobalUpdates or global_updates
					missing_profile = true

				else

					missing_profile = true
					overwritten = true

				end

			end

			-- Profile was not created or corrupted and no GlobalUpdate data exists:
			if missing_profile == true then
				latest_data = {
					-- Data = nil,
					-- MetaData = nil,
					GlobalUpdates = global_updates,
				}
				if transform_params.MissingProfileHandle ~= nil then
					transform_params.MissingProfileHandle(latest_data)
				end
			end

			-- Editing profile:
			if transform_params.EditProfile ~= nil then
				transform_params.EditProfile(latest_data)
			end

			-- Invalid data handling (Silently override with empty profile)
			if overwritten == true then
				latest_data.WasOverwritten = true -- Temporary tag that will be removed on first save
			end

			return latest_data, latest_data.UserIds, latest_data.RobloxMetaData
		end

		if is_user_mock == true then -- Used when the profile is accessed through ProfileStore.Mock

			loaded_data, key_info = MockUpdateAsync(UserMockStore, profile_store.Name, profile_key, transform_function, is_get_call)
			task.wait() -- Simulate API call yield

		elseif DataStoreState ~= "Access" then -- Used when API access is disabled

			loaded_data, key_info = MockUpdateAsync(MockStore, profile_store.Name, profile_key, transform_function, is_get_call)
			task.wait() -- Simulate API call yield

		else

			if is_get_call == true then

				if version ~= nil then

					local success, error_message = pcall(function()
						loaded_data, key_info = profile_store.data_store:GetVersionAsync(profile_key, version)
					end)

					if success == false and type(error_message) == "string" and string.find(error_message, "not valid") ~= nil then
						warn(`[{script.Name}]: Passed version argument is not valid; Traceback:\n` .. debug.traceback())
					end

				else

					loaded_data, key_info = profile_store.data_store:GetAsync(profile_key)

				end

				loaded_data = transform_function(loaded_data)

			else

				loaded_data, key_info = profile_store.data_store:UpdateAsync(profile_key, transform_function)

			end

		end

	end)

	next_in_queue()

	if success == true and type(loaded_data) == "table" then
		-- Invalid data handling:
		if loaded_data.WasOverwritten == true and is_get_call ~= true then
			RegisterOverwrite(
				profile_store.Name,
				profile_key
			)
		end
		-- Return loaded_data:
		return loaded_data, key_info
	else
		-- Error handling:
		RegisterError(
			error_message or "Undefined error",
			profile_store.Name,
			profile_key
		)
		-- Return nothing:
		return nil
	end

end

local function IsThisSession(session_tag)
	return session_tag[1] == PlaceId and session_tag[2] == JobId
end

local function ReadMockFlag(): boolean
	local is_mock = MockFlag
	MockFlag = false
	return is_mock
end

local function WaitForStoreReady(profile_store)
	while profile_store.is_ready == false do
		task.wait()
	end
end

local function AddProfileToAutoSave(profile)

	ActiveSessionCheck[profile.session_token] = profile

	-- Add at AutoSaveIndex and move AutoSaveIndex right:

	table.insert(AutoSaveList, AutoSaveIndex, profile)

	if #AutoSaveList > 1 then
		AutoSaveIndex = AutoSaveIndex + 1
	elseif #AutoSaveList == 1 then
		-- First profile created - make sure it doesn't get immediately auto saved:
		LastAutoSave = os.clock()
	end

end

local function RemoveProfileFromAutoSave(profile)

	ActiveSessionCheck[profile.session_token] = nil

	local auto_save_index = table.find(AutoSaveList, profile)

	if auto_save_index ~= nil then
		table.remove(AutoSaveList, auto_save_index)
		if auto_save_index < AutoSaveIndex then
			AutoSaveIndex = AutoSaveIndex - 1 -- Table contents were moved left before AutoSaveIndex so move AutoSaveIndex left as well
		end
		if AutoSaveList[AutoSaveIndex] == nil then -- AutoSaveIndex was at the end of the AutoSaveList - reset to 1
			AutoSaveIndex = 1
		end
	end

end

local function SaveProfileAsync(profile, is_ending_session, is_overwriting, last_save_reason)

	if type(profile.Data) ~= "table" then
		error(`[{script.Name}]: Developer code likely set "Profile.Data" to a non-table value! (STORE:{profile.ProfileStore.Name}; KEY:{profile.Key})`)
	end

	profile.OnSave:Fire()
	if is_ending_session == true then
		profile.OnLastSave:Fire(last_save_reason or "Manual")
	end

	if is_ending_session == true and is_overwriting ~= true then
		if profile.roblox_message_subscription ~= nil then
			profile.roblox_message_subscription:Disconnect()
		end
		RemoveProfileFromAutoSave(profile)
		profile.OnSessionEnd:Fire()
	end

	ActiveProfileSaveJobs = ActiveProfileSaveJobs + 1

	-- Compare "SessionLoadCount" when writing to profile to prevent a rare case of repeat last save when the profile is loaded on the same server again

	local repeat_save_flag = true -- Released Profile save calls have to repeat until they succeed
	local exp_backoff = 1

	while repeat_save_flag == true do

		if is_ending_session ~= true then
			repeat_save_flag = false
		end

		local loaded_data, key_info = UpdateAsync(
			profile.ProfileStore,
			profile.Key,
			{
				ExistingProfileHandle = nil,
				MissingProfileHandle = nil,
				EditProfile = function(latest_data)

					-- Check if this session still owns the profile:

					local session_owns_profile = false

					if is_overwriting ~= true then

						local active_session = latest_data.MetaData.ActiveSession
						local session_load_count = latest_data.MetaData.SessionLoadCount

						if type(active_session) == "table" then
							session_owns_profile = IsThisSession(active_session) and session_load_count == profile.load_index
						end

					else
						session_owns_profile = true
					end

					-- We may only edit the profile if this server has ownership of the profile:

					if session_owns_profile == true then

						-- Clear processed updates (messages):

						local locked_updates = profile.locked_global_updates -- [index] = true, ...
						local active_updates = latest_data.GlobalUpdates[2]
						-- ProfileService module format: {{update_id, version_id, update_locked, update_data}, ...}
						-- ProfileStore module format: {{update_id, update_data}, ...}

						if next(locked_updates) ~= nil then
							local i = 1
							while i <= #active_updates do
								local update = active_updates[i]
								if locked_updates[update[1]] == true then
									table.remove(active_updates, i)
								else
									i += 1
								end
							end
						end

						-- Save profile data:

						latest_data.Data = profile.Data
						latest_data.RobloxMetaData = profile.RobloxMetaData
						latest_data.UserIds = profile.UserIds

						if is_overwriting ~= true then

							latest_data.MetaData.LastUpdate = os.time()

							if is_ending_session == true then
								latest_data.MetaData.ActiveSession = nil
							end

						else

							latest_data.MetaData.ActiveSession = nil
							latest_data.MetaData.ForceLoadSession = nil

						end

					end

				end,
			},
			profile.is_mock
		)

		if loaded_data ~= nil and key_info ~= nil then

			if is_overwriting == true then
				break
			end

			repeat_save_flag = false

			local active_session = loaded_data.MetaData.ActiveSession
			local session_load_count = loaded_data.MetaData.SessionLoadCount
			local session_owns_profile = false

			if type(active_session) == "table" then
				session_owns_profile = IsThisSession(active_session) and session_load_count == profile.load_index
			end

			local force_load_session = loaded_data.MetaData.ForceLoadSession
			local force_load_pending = false
			if type(force_load_session) == "table" then
				force_load_pending = not IsThisSession(force_load_session)
			end

			local is_active = profile:IsActive()

			-- If another server is trying to start a session for this profile - end the session:

			if force_load_pending == true and session_owns_profile == true then
				if is_active == true then
					SaveProfileAsync(profile, true, false, "External")
				end
				break
			end

			-- Clearing processed update list / Detecting new updates:

			local locked_updates = profile.locked_global_updates -- [index] = true, ...
			local received_updates = profile.received_global_updates -- [index] = true, ...
			local active_updates = loaded_data.GlobalUpdates[2]

			local new_updates = {} -- {}, ...
			local still_pending = {} -- [index] = true, ...

			for _, update in ipairs(active_updates) do
				if locked_updates[update[1]] == true then
					still_pending[update[1]] = true
				elseif received_updates[update[1]] ~= true then
					received_updates[update[1]] = true
					table.insert(new_updates, update)
				end
			end

			for index in pairs(locked_updates) do
				if still_pending[index] ~= true then
					locked_updates[index] = nil
				end
			end

			-- Updating profile values:

			profile.KeyInfo = key_info
			profile.LastSavedData = loaded_data.Data
			profile.global_updates = loaded_data.GlobalUpdates and loaded_data.GlobalUpdates[2] or {}

			if session_owns_profile == true then
				if is_active == true and is_ending_session ~= true then

					-- Processing new global updates (messages):

					for _, update in ipairs(new_updates) do

						local index = update[1]
						local update_data = update[#update] -- Backwards compatibility with ProfileService

						for _, handler in ipairs(profile.message_handlers) do

							local is_processed = false
							local processed_callback = function()
								is_processed = true
								locked_updates[index] = true
							end

							local send_update_data = DeepCopyTable(update_data)

							task.spawn(handler, send_update_data, processed_callback)

							if is_processed == true then
								break
							end

						end

					end

				end
			else

				if profile.roblox_message_subscription ~= nil then
					profile.roblox_message_subscription:Disconnect()
				end

				if is_active == true then
					RemoveProfileFromAutoSave(profile)
					profile.OnSessionEnd:Fire()
				end

			end

			profile.OnAfterSave:Fire(profile.LastSavedData)

		elseif repeat_save_flag == true then

			-- DataStore call likely resulted in an error; Repeat the DataStore call shortly
			task.wait(exp_backoff)
			exp_backoff = math.min(if last_save_reason == "Shutdown" then 8 else 20, exp_backoff * 2)

		end

	end

	ActiveProfileSaveJobs = ActiveProfileSaveJobs - 1

end

----- Public -----

--[[
	Saved profile structure:
	
	{
		Data = {},
		
		MetaData = {
			ProfileCreateTime = 0,
			SessionLoadCount = 0,
			ActiveSession = {place_id, game_job_id, unique_session_id} / nil,
			ForceLoadSession = {place_id, game_job_id} / nil,
			LastUpdate = 0, -- os.time()
			MetaTags = {}, -- Backwards compatibility with ProfileService
		},
		
		RobloxMetaData = {},
		UserIds = {},
		
		GlobalUpdates = {
			update_index,
			{
				{update_index, data}, ...
			},
		},
	}

--]]

export type JSONAcceptable = { JSONAcceptable } | { [string]: JSONAcceptable } | number | string | boolean | buffer

export type Profile<T> = {
	Data: T & JSONAcceptable,
	LastSavedData: T & JSONAcceptable,
	FirstSessionTime: number,
	SessionLoadCount: number,
	Session: {PlaceId: number, JobId: string}?,
	RobloxMetaData: JSONAcceptable,
	UserIds: {number},
	KeyInfo: DataStoreKeyInfo,
	OnSave: {Connect: (self: any, listener: () -> ()) -> ({Disconnect: (self: any) -> ()})},
	OnLastSave: {Connect: (self: any, listener: (reason: "Manual" | "External" | "Shutdown") -> ()) -> ({Disconnect: (self: any) -> ()})},
	OnSessionEnd: {Connect: (self: any, listener: () -> ()) -> ({Disconnect: (self: any) -> ()})},
	OnAfterSave: {Connect: (self: any, listener: (last_saved_data: T & JSONAcceptable) -> ()) -> ({Disconnect: (self: any) -> ()})},
	ProfileStore: JSONAcceptable,
	Key: string,

	IsActive: (self: any) -> (boolean),
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	AddUserId: (self: any, user_id: number) -> (),
	RemoveUserId: (self: any, user_id: number) -> (),
	MessageHandler: (self: any, fn: (message: JSONAcceptable, processed: () -> ()) -> ()) -> (),
	Save: (self: any) -> (),
	SetAsync: (self: any) -> (),
}

export type VersionQuery<T> = {
	NextAsync: (self: any) -> (Profile<T>?),
}

type ProfileStoreStandard<T> = {
	Name: string,
	StartSessionAsync: (self: any, profile_key: string, params: {Steal: boolean?}) -> (Profile<T>?),
	MessageAsync: (self: any, profile_key: string, message: JSONAcceptable) -> (boolean),
	GetAsync: (self: any, profile_key: string, version: string?) -> (Profile<T>?),
	VersionQuery: (self: any, profile_key: string, sort_direction: Enum.SortDirection?, min_date: DateTime | number | nil, max_date: DateTime | number | nil) -> (VersionQuery<T>),
	RemoveAsync: (self: any, profile_key: string) -> (boolean),
}

export type ProfileStore<T> = {
	Mock: ProfileStoreStandard<T>,
} & ProfileStoreStandard<T>

type ConstantName = "AUTO_SAVE_PERIOD" | "LOAD_REPEAT_PERIOD" | "FIRST_LOAD_REPEAT" | "SESSION_STEAL"
| "ASSUME_DEAD" | "START_SESSION_TIMEOUT" | "CRITICAL_STATE_ERROR_COUNT" | "CRITICAL_STATE_ERROR_EXPIRE"
| "CRITICAL_STATE_EXPIRE" | "MAX_MESSAGE_QUEUE"

export type ProfileStoreModule = {
	IsClosing: boolean,
	IsCriticalState: boolean,
	OnError: {Connect: (self: any, listener: (message: string, store_name: string, profile_key: string) -> ()) -> ({Disconnect: (self: any) -> ()})},
	OnOverwrite: {Connect: (self: any, listener: (store_name: string, profile_key: string) -> ()) -> ({Disconnect: (self: any) -> ()})},
	OnCriticalToggle: {Connect: (self: any, listener: (is_critical: boolean) -> ()) -> ({Disconnect: (self: any) -> ()})},
	DataStoreState: "NotReady" | "NoInternet" | "NoAccess" | "Access",
	New: <T>(store_name: string, template: (T & JSONAcceptable)?) -> (ProfileStore<T>),
	SetConstant: (name: ConstantName, value: number) -> ()
}

local Profile = {}
Profile.__index = Profile

function Profile.New(raw_data, key_info, profile_store, key, is_mock, session_token)

	local data = raw_data.Data or {}
	local session = raw_data.MetaData and raw_data.MetaData.ActiveSession or nil

	local global_updates = raw_data.GlobalUpdates and raw_data.GlobalUpdates[2] or {}
	local received_global_updates = {}

	for _, update in ipairs(global_updates) do
		received_global_updates[update[1]] = true
	end

	local self = {

		Data = data,
		LastSavedData = DeepCopyTable(data),

		FirstSessionTime = raw_data.MetaData and raw_data.MetaData.ProfileCreateTime or 0,
		SessionLoadCount = raw_data.MetaData and raw_data.MetaData.SessionLoadCount or 0,
		Session = session and {PlaceId = session[1], JobId = session[2]},

		RobloxMetaData = raw_data.RobloxMetaData or {},
		UserIds = raw_data.UserIds or {},
		KeyInfo = key_info,

		OnAfterSave = Signal.New(),
		OnSave = Signal.New(),
		OnLastSave = Signal.New(),
		OnSessionEnd = Signal.New(),

		ProfileStore = profile_store,
		Key = key,

		load_timestamp = os.clock(),
		is_mock = is_mock,
		session_token = session_token or "",
		load_index = raw_data.MetaData and raw_data.MetaData.SessionLoadCount or 0,
		locked_global_updates = {},
		received_global_updates = received_global_updates,
		message_handlers = {},
		global_updates = global_updates,

	}
	setmetatable(self, Profile)

	return self

end

function Profile:IsActive()
	return ActiveSessionCheck[self.session_token] == self
end

function Profile:Reconcile()
	ReconcileTable(self.Data, self.ProfileStore.template)
end

function Profile:EndSession()
	if self:IsActive() == true then
		task.spawn(SaveProfileAsync, self, true, nil, "Manual") -- Call save function in a new thread with release_from_session = true
	end
end

function Profile:AddUserId(user_id) -- Associates user_id with profile (GDPR compliance)

	if type(user_id) ~= "number" or user_id % 1 ~= 0 then
		warn(`[{script.Name}]: Invalid UserId argument for :AddUserId() ({tostring(user_id)}); Traceback:\n` .. debug.traceback())
		return
	end

	if user_id < 0 and self.is_mock ~= true and DataStoreState == "Access" then
		return -- Avoid giving real Roblox APIs negative UserId's
	end

	if table.find(self.UserIds, user_id) == nil then
		table.insert(self.UserIds, user_id)
	end

end

function Profile:RemoveUserId(user_id) -- Removes user_id association with profile (safe function)

	if type(user_id) ~= "number" or user_id % 1 ~= 0 then
		warn(`[{script.Name}]: Invalid UserId argument for :RemoveUserId() ({tostring(user_id)}); Traceback:\n` .. debug.traceback())
		return
	end

	local index = table.find(self.UserIds, user_id)

	if index ~= nil then
		table.remove(self.UserIds, index)
	end

end

function Profile:SetAsync() -- Saves the profile to the DataStore and removes the session lock

	if self.view_mode ~= true then
		error(`[{script.Name}]: :SetAsync() can only be used in view mode`)
	end

	SaveProfileAsync(self, nil, true)

end

function Profile:MessageHandler(fn)

	if type(fn) ~= "function" then
		error(`[{script.Name}]: fn argument is not a function`)
	end

	if self.view_mode ~= true and self:IsActive() ~= true then
		return -- Don't process messages if the profile session was ended
	end

	local locked_updates = self.locked_global_updates
	table.insert(self.message_handlers, fn)

	for _, update in ipairs(self.global_updates) do

		local index = update[1]
		local update_data = update[#update] -- Backwards compatibility with ProfileService

		if locked_updates[index] ~= true then

			local processed_callback = function()
				locked_updates[index] = true
			end

			local send_update_data = DeepCopyTable(update_data)

			task.spawn(fn, send_update_data, processed_callback)

		end

	end

end

function Profile:Save()

	if self.view_mode == true then
		error(`[{script.Name}]: Can't save profile in view mode; Should you be calling :SetAsync() instead?`)
	end

	if self:IsActive() == false then
		warn(`[{script.Name}]: Attempted saving an inactive profile (STORE:{self.ProfileStore.Name}; KEY:{self.Key});`
			.. ` Traceback:\n` .. debug.traceback())
		return
	end

	-- Move the profile right behind the auto save index to delay the next auto save for it:
	RemoveProfileFromAutoSave(self)
	AddProfileToAutoSave(self)

	-- Perform save in new thread:
	task.spawn(SaveProfileAsync, self)

end

local ProfileStore: ProfileStoreModule = {

	IsClosing = false,
	IsCriticalState = false,
	OnError = OnError, -- (message, store_name, profile_key)
	OnOverwrite = OnOverwrite, -- (store_name, profile_key)
	OnCriticalToggle = Signal.New(), -- (is_critical)
	DataStoreState = "NotReady", -- ("NotReady", "NoInternet", "NoAccess", "Access")

}
ProfileStore.__index = ProfileStore

function ProfileStore.SetConstant(name, value)

	if type(value) ~= "number" then
		error(`[{script.Name}]: Invalid value type`)
	end

	if name == "AUTO_SAVE_PERIOD" then
		AUTO_SAVE_PERIOD = value
	elseif name == "LOAD_REPEAT_PERIOD" then
		LOAD_REPEAT_PERIOD = value
	elseif name == "FIRST_LOAD_REPEAT" then
		FIRST_LOAD_REPEAT = value
	elseif name == "SESSION_STEAL" then
		SESSION_STEAL = value
	elseif name == "ASSUME_DEAD" then
		ASSUME_DEAD = value
	elseif name == "START_SESSION_TIMEOUT" then
		START_SESSION_TIMEOUT = value
	elseif name == "CRITICAL_STATE_ERROR_COUNT" then
		CRITICAL_STATE_ERROR_COUNT = value
	elseif name == "CRITICAL_STATE_ERROR_EXPIRE" then
		CRITICAL_STATE_ERROR_EXPIRE = value
	elseif name == "CRITICAL_STATE_EXPIRE" then
		CRITICAL_STATE_EXPIRE = value
	elseif name == "MAX_MESSAGE_QUEUE" then
		MAX_MESSAGE_QUEUE = value
	else
		error(`[{script.Name}]: Invalid constant name was provided`)
	end

end

function ProfileStore.Test()
	return {
		ActiveSessionCheck = ActiveSessionCheck,
		AutoSaveList = AutoSaveList,
		ActiveProfileLoadJobs = ActiveProfileLoadJobs,
		ActiveProfileSaveJobs = ActiveProfileSaveJobs,
		MockStore = MockStore,
		UserMockStore = UserMockStore,
		UpdateQueue = UpdateQueue,
	}
end

function ProfileStore.New(store_name, template)

	template = template or {}

	if type(store_name) ~= "string" then
		error(`[{script.Name}]: Invalid or missing "store_name"`)
	elseif string.len(store_name) == 0 then
		error(`[{script.Name}]: store_name cannot be an empty string`)
	elseif string.len(store_name) > 50 then
		error(`[{script.Name}]: store_name is too long`)
	end

	if type(template) ~= "table" then
		error(`[{script.Name}]: Invalid template argument`)
	end

	local self
	self = {

		Mock = {

			Name = store_name,

			StartSessionAsync = function(_, profile_key)
				MockFlag = true
				return self:StartSessionAsync(profile_key)
			end,
			MessageAsync = function(_, profile_key, message)
				MockFlag = true
				return self:MessageAsync(profile_key, message)
			end,
			GetAsync = function(_, profile_key, version)
				MockFlag = true
				return self:GetAsync(profile_key, version)
			end,
			VersionQuery = function(_, profile_key, sort_direction, min_date, max_date)
				MockFlag = true
				return self:VersionQuery(profile_key, sort_direction, min_date, max_date)
			end,
			RemoveAsync = function(_, profile_key)
				MockFlag = true
				return self:RemoveAsync(profile_key)
			end
		},

		Name = store_name,

		template = template,
		data_store = nil,
		load_jobs = {},
		mock_load_jobs = {},
		is_ready = true,

	}
	setmetatable(self, ProfileStore)

	local options = Instance.new("DataStoreOptions")
	options:SetExperimentalFeatures({v2 = true})

	if DataStoreState == "NotReady" then

		-- The module is not sure whether DataStores are accessible yet:

		self.is_ready = false

		task.spawn(function()

			repeat task.wait() until DataStoreState ~= "NotReady"

			if DataStoreState == "Access" then
				self.data_store = DataStoreService:GetDataStore(store_name, nil, options)
			end

			self.is_ready = true

		end)

	elseif DataStoreState == "Access" then

		self.data_store = DataStoreService:GetDataStore(store_name, nil, options)

	end

	return self

end

local function RobloxMessageSubscription(profile, unique_session_id)

	local last_roblox_message = 0

	local roblox_message_subscription = MessagingService:SubscribeAsync("PS_" .. unique_session_id, function(message)
		if type(message.Data) == "table" and message.Data.LoadCount == profile.SessionLoadCount then
			-- High reaction rate, based on numPlayers × 10 DataStore budget as of writing
			if os.clock() - last_roblox_message > 6 then 
				last_roblox_message = os.clock()
				if profile:IsActive() == true then
					if message.Data.EndSession == true then
						SaveProfileAsync(profile, true, false, "External")
					else
						profile:Save()
					end
				end
			end
		end
	end)

	if profile:IsActive() == true then
		profile.roblox_message_subscription = roblox_message_subscription
	else
		roblox_message_subscription:Disconnect()
	end

end

function ProfileStore:StartSessionAsync(profile_key, params)

	local is_mock = ReadMockFlag()

	if type(profile_key) ~= "string" then
		error(`[{script.Name}]: profile_key must be a string`)
	elseif string.len(profile_key) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	elseif string.len(profile_key) > 50 then
		error(`[{script.Name}]: profile_key is too long`)
	end

	if params ~= nil and type(params) ~= "table" then
		error(`[{script.Name}]: Invalid params`)
	end

	params = params or {}

	if ProfileStore.IsClosing == true then
		return nil
	end

	WaitForStoreReady(self)

	local session_token = SessionToken(self.Name, profile_key, is_mock)

	if ActiveSessionCheck[session_token] ~= nil then
		error(`[{script.Name}]: Profile (STORE:{self.Name}; KEY:{profile_key}) is already loaded in this session`)
	end

	ActiveProfileLoadJobs = ActiveProfileLoadJobs + 1

	local is_user_cancel = false

	local function cancel_condition()
		if is_user_cancel == false then
			if params.Cancel ~= nil then
				is_user_cancel = params.Cancel() == true
			end
			return is_user_cancel
		end
		return true
	end

	local user_steal = params.Steal == true

	local force_load_steps = 0 -- Session conflict handling values
	local request_force_load = true
	local steal_session = false

	local start = os.clock()
	local exp_backoff = 1

	while ProfileStore.IsClosing == false and cancel_condition() == false do

		-- Load profile:

		-- SPECIAL CASE - If StartSessionAsync is called for the same key again before another StartSessionAsync finishes,
		-- grab the DataStore return for the new call. The early call will return nil. This is supposed to retain
		-- expected and efficient behavior in cases where a player would quickly rejoin the same server.

		LoadIndex += 1
		local load_id = LoadIndex
		local profile_load_jobs = is_mock == true and self.mock_load_jobs or self.load_jobs
		local profile_load_job = profile_load_jobs[profile_key] -- {load_id, {loaded_data, key_info} or nil}

		local loaded_data, key_info
		local unique_session_id = HttpService:GenerateGUID(false)

		if profile_load_job ~= nil then

			profile_load_job[1] = load_id -- Steal load job
			while profile_load_job[2] == nil do -- Wait for job to finish
				task.wait()
			end
			if profile_load_job[1] == load_id then -- Load job hasn't been double-stolen
				loaded_data, key_info = table.unpack(profile_load_job[2])
				profile_load_jobs[profile_key] = nil
			else
				ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
				return nil
			end

		else

			profile_load_job = {load_id, nil}
			profile_load_jobs[profile_key] = profile_load_job

			profile_load_job[2] = table.pack(UpdateAsync(
				self,
				profile_key,
				{
					ExistingProfileHandle = function(latest_data)

						if ProfileStore.IsClosing == true or cancel_condition() == true then
							return
						end

						local active_session = latest_data.MetaData.ActiveSession
						local force_load_session = latest_data.MetaData.ForceLoadSession

						if active_session == nil then
							latest_data.MetaData.ActiveSession = {PlaceId, JobId, unique_session_id}
							latest_data.MetaData.ForceLoadSession = nil
						elseif type(active_session) == "table" then
							if IsThisSession(active_session) == false then
								local last_update = latest_data.MetaData.LastUpdate
								if last_update ~= nil then
									if os.time() - last_update > ASSUME_DEAD then
										latest_data.MetaData.ActiveSession = {PlaceId, JobId, unique_session_id}
										latest_data.MetaData.ForceLoadSession = nil
										return
									end
								end
								if steal_session == true or user_steal == true then
									local force_load_interrupted = if force_load_session ~= nil then not IsThisSession(force_load_session) else true
									if force_load_interrupted == false or user_steal == true then
										latest_data.MetaData.ActiveSession = {PlaceId, JobId, unique_session_id}
										latest_data.MetaData.ForceLoadSession = nil
									end
								elseif request_force_load == true then
									latest_data.MetaData.ForceLoadSession = {PlaceId, JobId}
								end
							else
								latest_data.MetaData.ForceLoadSession = nil
							end
						end

					end,
					MissingProfileHandle = function(latest_data)

						local is_cancel = ProfileStore.IsClosing == true or cancel_condition() == true

						latest_data.Data = DeepCopyTable(self.template)
						latest_data.MetaData = {
							ProfileCreateTime = os.time(),
							SessionLoadCount = 0,
							ActiveSession = if is_cancel == false then {PlaceId, JobId, unique_session_id} else nil,
							ForceLoadSession = nil,
							MetaTags = {}, -- Backwards compatibility with ProfileService
						}

					end,
					EditProfile = function(latest_data)

						if ProfileStore.IsClosing == true or cancel_condition() == true then
							return
						end

						local active_session = latest_data.MetaData.ActiveSession
						if active_session ~= nil and IsThisSession(active_session) == true then
							latest_data.MetaData.SessionLoadCount = latest_data.MetaData.SessionLoadCount + 1
							latest_data.MetaData.LastUpdate = os.time()
						end

					end,
				},
				is_mock
				))
			if profile_load_job[1] == load_id then -- Load job hasn't been stolen
				loaded_data, key_info = table.unpack(profile_load_job[2])
				profile_load_jobs[profile_key] = nil
			else
				ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
				return nil -- Load job stolen
			end
		end

		-- Handle load_data:

		if loaded_data ~= nil and key_info ~= nil then
			local active_session = loaded_data.MetaData.ActiveSession
			if type(active_session) == "table" then

				if IsThisSession(active_session) == true then

					-- Profile is now taken by this session:

					local profile = Profile.New(loaded_data, key_info, self, profile_key, is_mock, session_token)
					AddProfileToAutoSave(profile)

					if is_mock ~= true and DataStoreState == "Access" then

						-- Use MessagingService to quickly detect session conflicts and resolve them quickly:
						task.spawn(RobloxMessageSubscription, profile, unique_session_id) -- Blocking prevention

					end

					if ProfileStore.IsClosing == true or cancel_condition() == true then
						-- The server has initiated a shutdown by the time this profile was loaded
						SaveProfileAsync(profile, true) -- Release profile and yield until the DataStore call is finished
						profile = nil -- Don't return the profile object
					end

					ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
					return profile

				else

					if ProfileStore.IsClosing == true or cancel_condition() == true then
						ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
						return nil
					end

					-- Profile is taken by some other session:

					local force_load_session = loaded_data.MetaData.ForceLoadSession
					local force_load_interrupted = if force_load_session ~= nil then not IsThisSession(force_load_session) else true

					if force_load_interrupted == false then

						if request_force_load == false then
							force_load_steps = force_load_steps + 1
							if force_load_steps >= math.ceil(SESSION_STEAL / LOAD_REPEAT_PERIOD) then
								steal_session = true
							end
						end

						-- Request the remote server to end its session:
						if type(active_session[3]) == "string" then
							local session_load_count = loaded_data.MetaData.SessionLoadCount or 0
							task.spawn(MessagingService.PublishAsync, MessagingService, "PS_" .. active_session[3], {LoadCount = session_load_count, EndSession = true})
						end

						-- Attempt to load the profile again after a delay
						local wait_until = os.clock() + if request_force_load == true then FIRST_LOAD_REPEAT else LOAD_REPEAT_PERIOD
						repeat task.wait() until os.clock() >= wait_until or ProfileStore.IsClosing == true

					else
						-- Another session tried to load this profile:
						ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
						return nil
					end

					request_force_load = false -- Only request a force load once

				end

			else
				ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
				return nil -- In this scenario it is likely that this server started shutting down
			end
		else

			-- A DataStore call has likely ended in an error:

			local default_timeout = false

			if params.Cancel == nil then
				default_timeout = os.clock() - start >= START_SESSION_TIMEOUT
			end

			if default_timeout == true or ProfileStore.IsClosing == true or cancel_condition() == true then
				ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
				return nil
			end

			task.wait(exp_backoff)  -- Repeat the call shortly
			exp_backoff = math.min(20, exp_backoff * 2)

		end

	end

	ActiveProfileLoadJobs = ActiveProfileLoadJobs - 1
	return nil -- Game started shutting down or the request was cancelled - don't return the profile

end

function ProfileStore:MessageAsync(profile_key, message)

	local is_mock = ReadMockFlag()

	if type(profile_key) ~= "string" then
		error(`[{script.Name}]: profile_key must be a string`)
	elseif string.len(profile_key) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	elseif string.len(profile_key) > 50 then
		error(`[{script.Name}]: profile_key is too long`)
	end

	if type(message) ~= "table" then
		error(`[{script.Name}]: message must be a table`)
	end

	if ProfileStore.IsClosing == true then
		return false
	end

	WaitForStoreReady(self)

	local exp_backoff = 1

	while ProfileStore.IsClosing == false do

		-- Updating profile:

		local loaded_data = UpdateAsync(
			self,
			profile_key,
			{
				ExistingProfileHandle = nil,
				MissingProfileHandle = nil,
				EditProfile = function(latest_data)

					local global_updates = latest_data.GlobalUpdates
					local update_list = global_updates[2]
					--{
					--	update_index,
					--	{
					--		{update_index, data}, ...
					--	},
					--},

					global_updates[1] += 1
					table.insert(update_list, {global_updates[1], message})

					-- Clearing queue if above limit:

					while #update_list > MAX_MESSAGE_QUEUE do
						table.remove(update_list, 1)
					end

				end,
			},
			is_mock
		)

		if loaded_data ~= nil then

			local session_token = SessionToken(self.Name, profile_key, is_mock)

			local profile = ActiveSessionCheck[session_token]

			if profile ~= nil then

				-- The message was sent to a profile that is active in this server:
				profile:Save()

			else

				local meta_data = loaded_data.MetaData or {}
				local active_session = meta_data.ActiveSession
				local session_load_count = meta_data.SessionLoadCount or 0

				if type(active_session) == "table" and type(active_session[3]) == "string" then
					-- Request the remote server to auto-save sooner and receive the message:
					task.spawn(MessagingService.PublishAsync, MessagingService, "PS_" .. active_session[3], {LoadCount = session_load_count})
				end

			end

			return true

		else

			task.wait(exp_backoff) -- A DataStore call has likely ended in an error - repeat the call shortly
			exp_backoff = math.min(20, exp_backoff * 2)

		end

	end

	return false

end

function ProfileStore:GetAsync(profile_key, version)

	local is_mock = ReadMockFlag()

	if type(profile_key) ~= "string" then
		error(`[{script.Name}]: profile_key must be a string`)
	elseif string.len(profile_key) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	elseif string.len(profile_key) > 50 then
		error(`[{script.Name}]: profile_key is too long`)
	end

	if ProfileStore.IsClosing == true then
		return nil
	end

	WaitForStoreReady(self)

	if version ~= nil and (is_mock or DataStoreState ~= "Access") then
		return nil -- No version support in mock mode
	end

	local exp_backoff = 1

	while ProfileStore.IsClosing == false do

		-- Load profile:

		local loaded_data, key_info = UpdateAsync(
			self,
			profile_key,
			{
				ExistingProfileHandle = nil,
				MissingProfileHandle = function(latest_data)

					latest_data.Data = DeepCopyTable(self.template)
					latest_data.MetaData = {
						ProfileCreateTime = os.time(),
						SessionLoadCount = 0,
						ActiveSession = nil,
						ForceLoadSession = nil,
						MetaTags = {}, -- Backwards compatibility with ProfileService
					}

				end,
				EditProfile = nil,
			},
			is_mock,
			true, -- Use :GetAsync()
			version -- DataStore key version
		)

		-- Handle load_data:

		if loaded_data ~= nil then

			if key_info == nil then
				return nil -- Load was successful, but the key was empty - return no profile object
			end

			local profile = Profile.New(loaded_data, key_info, self, profile_key, is_mock)
			profile.view_mode = true

			return profile

		else

			task.wait(exp_backoff) -- A DataStore call has likely ended in an error - repeat the call shortly
			exp_backoff = math.min(20, exp_backoff * 2)

		end

	end

	return nil -- Game started shutting down - don't return the profile

end

function ProfileStore:RemoveAsync(profile_key)

	local is_mock = ReadMockFlag()

	if type(profile_key) ~= "string" or string.len(profile_key) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	end

	if ProfileStore.IsClosing == true then
		return false
	end

	WaitForStoreReady(self)

	local wipe_status = false

	local next_in_queue = WaitInUpdateQueue(SessionToken(self.Name, profile_key, is_mock))

	if is_mock == true then -- Used when the profile is accessed through ProfileStore.Mock

		local mock_data_store = UserMockStore[self.Name]

		if mock_data_store ~= nil then
			mock_data_store[profile_key] = nil
			if next(mock_data_store) == nil then
				UserMockStore[self.Name] = nil
			end
		end

		wipe_status = true
		task.wait() -- Simulate API call yield

	elseif DataStoreState ~= "Access" then -- Used when API access is disabled

		local mock_data_store = MockStore[self.Name]

		if mock_data_store ~= nil then
			mock_data_store[profile_key] = nil
			if next(mock_data_store) == nil then
				MockStore[self.Name] = nil
			end
		end

		wipe_status = true
		task.wait() -- Simulate API call yield

	else -- Live DataStore

		wipe_status = pcall(function()
			self.data_store:RemoveAsync(profile_key)
		end)

	end

	next_in_queue()

	return wipe_status

end

local ProfileVersionQuery = {}
ProfileVersionQuery.__index = ProfileVersionQuery

function ProfileVersionQuery.New(profile_store, profile_key, sort_direction, min_date, max_date, is_mock)

	local self = {
		profile_store = profile_store,
		profile_key = profile_key,
		sort_direction = sort_direction,
		min_date = min_date,
		max_date = max_date,

		query_pages = nil,
		query_index = 0,
		query_failure = false,

		is_query_yielded = false,
		query_queue = {},

		is_mock = is_mock,
	}
	setmetatable(self, ProfileVersionQuery)

	return self

end

function MoveVersionQueryQueue(self) -- Hidden ProfileVersionQuery method
	while #self.query_queue > 0 do

		local queue_entry = table.remove(self.query_queue, 1)

		task.spawn(queue_entry)

		if self.is_query_yielded == true then
			break
		end

	end
end

local VersionQueryNextAsyncStackingFlag = false
local WarnAboutVersionQueryOnce = false

function ProfileVersionQuery:NextAsync()

	local is_stacking = VersionQueryNextAsyncStackingFlag == true
	VersionQueryNextAsyncStackingFlag = false

	WaitForStoreReady(self.profile_store)

	if ProfileStore.IsClosing == true then
		return nil -- Silently fail :NextAsync() requests
	end

	if self.is_mock == true or DataStoreState ~= "Access" then
		if IsStudio == true and WarnAboutVersionQueryOnce == false then
			WarnAboutVersionQueryOnce = true
			warn(`[{script.Name}]: :VersionQuery() is not supported in mock mode!`)
		end
		return nil -- Silently fail :NextAsync() requests
	end

	local profile
	local is_finished = false

	local function query_job()

		if self.query_failure == true then
			is_finished = true
			return
		end

		-- First "next" call loads version pages:

		if self.query_pages == nil then

			self.is_query_yielded = true

			task.spawn(function()
				VersionQueryNextAsyncStackingFlag = true
				profile = self:NextAsync()
				is_finished = true
			end)

			local list_success, error_message = pcall(function()
				self.query_pages = self.profile_store.data_store:ListVersionsAsync(
					self.profile_key,
					self.sort_direction,
					self.min_date,
					self.max_date
				)
				self.query_index = 0
			end)

			if list_success == false or self.query_pages == nil then
				warn(`[{script.Name}]: Version query fail - {tostring(error_message)}`)
				self.query_failure = true
			end

			self.is_query_yielded = false

			MoveVersionQueryQueue(self)

			return

		end

		local current_page = self.query_pages:GetCurrentPage()
		local next_item = current_page[self.query_index + 1]

		-- No more entries:

		if self.query_pages.IsFinished == true and next_item == nil then
			is_finished = true
			return
		end

		-- Load next page when this page is over:

		if next_item == nil then

			self.is_query_yielded = true
			task.spawn(function()
				VersionQueryNextAsyncStackingFlag = true
				profile = self:NextAsync()
				is_finished = true
			end)

			local success, error_message = pcall(function()
				self.query_pages:AdvanceToNextPageAsync()
				self.query_index = 0
			end)

			if success == false or #self.query_pages:GetCurrentPage() == 0 then
				self.query_failure = true
			end

			self.is_query_yielded = false
			MoveVersionQueryQueue(self)

			return

		end

		-- Next page item:

		self.query_index += 1
		profile = self.profile_store:GetAsync(self.profile_key, next_item.Version)
		is_finished = true

	end

	if self.is_query_yielded == false then
		query_job()
	else
		if is_stacking == true then
			table.insert(self.query_queue, 1, query_job)
		else
			table.insert(self.query_queue, query_job)
		end
	end

	while is_finished == false do
		task.wait()
	end

	return profile

end

function ProfileStore:VersionQuery(profile_key, sort_direction, min_date, max_date)

	local is_mock = ReadMockFlag()

	if type(profile_key) ~= "string" or string.len(profile_key) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	end

	-- Type check:

	if sort_direction ~= nil and (typeof(sort_direction) ~= "EnumItem"
		or sort_direction.EnumType ~= Enum.SortDirection) then
		error(`[{script.Name}]: Invalid sort_direction ({tostring(sort_direction)})`)
	end

	if min_date ~= nil and typeof(min_date) ~= "DateTime" and typeof(min_date) ~= "number" then
		error(`[{script.Name}]: Invalid min_date ({tostring(min_date)})`)
	end

	if max_date ~= nil and typeof(max_date) ~= "DateTime" and typeof(max_date) ~= "number" then
		error(`[{script.Name}]: Invalid max_date ({tostring(max_date)})`)
	end

	min_date = typeof(min_date) == "DateTime" and min_date.UnixTimestampMillis or min_date
	max_date = typeof(max_date) == "DateTime" and max_date.UnixTimestampMillis or max_date

	return ProfileVersionQuery.New(self, profile_key, sort_direction, min_date, max_date, is_mock)

end

-- DataStore API access check:

if IsStudio == true then

	task.spawn(function()

		local new_state = "NoAccess"

		local status, message = pcall(function()
			-- This will error if current instance has no Studio API access:
			DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
		end)

		local no_internet_access = status == false and string.find(message, "ConnectFail", 1, true) ~= nil

		if no_internet_access == true then
			warn(`[{script.Name}]: No internet access - check your network connection`)
		end

		if status == false and
			(string.find(message, "403", 1, true) ~= nil or -- Cannot write to DataStore from studio if API access is not enabled
				string.find(message, "must publish", 1, true) ~= nil or -- Game must be published to access live keys
				no_internet_access == true) then -- No internet access

			new_state = if no_internet_access == true then "NoInternet" else "NoAccess"
			print(`[{script.Name}]: Roblox API services unavailable - data will not be saved`)
		else
			new_state = "Access"
			--print(`[{script.Name}]: Roblox API services available - data will be saved`)
		end

		DataStoreState = new_state
		ProfileStore.DataStoreState = new_state

	end)

else

	DataStoreState = "Access"
	ProfileStore.DataStoreState = "Access"

end

-- Update loop:

RunService.Heartbeat:Connect(function()

	-- Auto saving:

	local auto_save_list_length = #AutoSaveList
	if auto_save_list_length > 0 then
		local auto_save_index_speed = AUTO_SAVE_PERIOD / auto_save_list_length
		local os_clock = os.clock()
		while os_clock - LastAutoSave > auto_save_index_speed do
			LastAutoSave = LastAutoSave + auto_save_index_speed
			local profile = AutoSaveList[AutoSaveIndex]
			if os_clock - profile.load_timestamp < AUTO_SAVE_PERIOD / 2 then
				-- This profile is freshly loaded - auto saving immediately is not necessary:
				profile = nil
				for _ = 1, auto_save_list_length - 1 do
					-- Move auto save index to the right:
					AutoSaveIndex = AutoSaveIndex + 1
					if AutoSaveIndex > auto_save_list_length then
						AutoSaveIndex = 1
					end
					profile = AutoSaveList[AutoSaveIndex]
					if os_clock - profile.load_timestamp >= AUTO_SAVE_PERIOD / 2 then
						break
					else
						profile = nil
					end
				end
			end
			-- Move auto save index to the right:
			AutoSaveIndex = AutoSaveIndex + 1
			if AutoSaveIndex > auto_save_list_length then
				AutoSaveIndex = 1
			end
			-- Perform save call:
			if profile ~= nil then
				task.spawn(SaveProfileAsync, profile) -- Auto save profile in new thread
			end
		end
	end

	-- Critical state handling:

	if ProfileStore.IsCriticalState == false then
		if #IssueQueue >= CRITICAL_STATE_ERROR_COUNT then
			ProfileStore.IsCriticalState = true
			ProfileStore.OnCriticalToggle:Fire(true)
			CriticalStateStart = os.clock()
			warn(`[{script.Name}]: Entered critical state`)
		end
	else
		if #IssueQueue >= CRITICAL_STATE_ERROR_COUNT then
			CriticalStateStart = os.clock()
		elseif os.clock() - CriticalStateStart > CRITICAL_STATE_EXPIRE then
			ProfileStore.IsCriticalState = false
			ProfileStore.OnCriticalToggle:Fire(false)
			warn(`[{script.Name}]: Critical state ended`)
		end
	end

	-- Issue queue:

	while true do
		local issue_time = IssueQueue[1]
		if issue_time == nil then
			break
		elseif os.clock() - issue_time > CRITICAL_STATE_ERROR_EXPIRE then
			table.remove(IssueQueue, 1)
		else
			break
		end
	end

end)

-- Release all loaded profiles when the server is shutting down:

task.spawn(function()

	while DataStoreState == "NotReady" do
		task.wait()
	end

	if DataStoreState ~= "Access" then

		game:BindToClose(function()
			ProfileStore.IsClosing = true
			task.wait() -- Mock shutdown delay
		end)

		return -- Don't wait for profiles to properly save in mock mode so studio could end the simulation faster

	end

	game:BindToClose(function()

		ProfileStore.IsClosing = true

		-- Release all active profiles:
		-- (Clone AutoSaveList to a new table because AutoSaveList changes when profiles are released)

		local on_close_save_job_count = 0
		local active_profiles = {}
		for index, profile in ipairs(AutoSaveList) do
			active_profiles[index] = profile
		end

		-- Release the profiles; Releasing profiles can trigger listeners that release other profiles, so check active state:
		for _, profile in ipairs(active_profiles) do
			if profile:IsActive() == true then
				on_close_save_job_count = on_close_save_job_count + 1
				task.spawn(function() -- Save profile on new thread
					SaveProfileAsync(profile, true, nil, "Shutdown")
					on_close_save_job_count = on_close_save_job_count - 1
				end)
			end
		end

		-- Yield until all active profile jobs are finished:
		while on_close_save_job_count > 0 or ActiveProfileLoadJobs > 0 or ActiveProfileSaveJobs > 0 do
			task.wait()
		end

		return -- We're done!

	end)

end)

return ProfileStore

-- ==== [ ServerScriptService.Modules.Ragdoll ] ==== --
--// Services
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

--// Modules
local RagdollModule = {}
RagdollModule.PlayersCollisionGroup = "Players" -->> idk, if u have another name for the players collision group just change it
RagdollModule.CanCollide = false -->> set true if you want the parts to collide with each other

if not PhysicsService:IsCollisionGroupRegistered("Uncollidable") then
	local CollisionGroup = PhysicsService:RegisterCollisionGroup("Uncollidable")
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", RagdollModule.PlayersCollisionGroup, false)
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", "Uncollidable", RagdollModule.CanCollide)
end

if not PhysicsService:IsCollisionGroupRegistered(RagdollModule.PlayersCollisionGroup) then
	local CollisionGroup = PhysicsService:RegisterCollisionGroup(RagdollModule.PlayersCollisionGroup)
	PhysicsService:CollisionGroupSetCollidable("Uncollidable", RagdollModule.PlayersCollisionGroup, false)
end

--// Main Function's
local ragdoll_tasks = {}
function RagdollModule:Ragdoll(Character: Model, duration)
	if not Character:GetAttribute("Ragdoll") then
		local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

		if not Humanoid then return end
		
		if ragdoll_tasks[Character] then
			task.cancel(ragdoll_tasks[Character])
		end
		
		if duration then
			ragdoll_tasks[Character] = task.delay(duration, function()
				self:unRagdoll(Character)
			end)
		end
		
		if Character:GetAttribute("Ragdoll") == true then
			return
		end

		for _, Animation in Humanoid.Animator:GetPlayingAnimationTracks() do
			Animation:Stop()
		end

		Character:SetAttribute("Ragdoll", true)
		
		Humanoid.PlatformStand = true
		Humanoid.BreakJointsOnDeath = false
		Humanoid.AutoRotate = false
		Humanoid.RequiresNeck = true
		
		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

		Character:FindFirstChild("HumanoidRootPart").CanCollide = false

		if IsNpc then
			Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
		end

		self:ReplaceJoints(Character)
	end
end

function RagdollModule:unRagdoll(Character : Model)
	if Character:GetAttribute("Ragdoll") then
		local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

		if not Humanoid then return end
		if Humanoid.Health <= 0.1 then return end

		Character:SetAttribute("Ragdoll", false)
		
		Humanoid.PlatformStand = false
		Humanoid.AutoRotate = true
		Humanoid.RequiresNeck = false

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		Character:FindFirstChild("HumanoidRootPart").CanCollide = true

		if IsNpc then
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		self:ResetJoints(Character)
	end
end

--// Attachments CFrame's
local AttachmentCFrames = {
	["Neck"] = {CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1)},
	["Left Shoulder"] = {CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1), CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1)},
	["Right Shoulder"] = {CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)},
	["Left Hip"] = {CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
	["Right Hip"] = {CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1), CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1)},
}

local RagdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}


function RagdollModule:CreateColliderPart(Part: BasePart)
	if not Part then return end
	local RagdollColliderPart = Instance.new("Part")
	RagdollColliderPart.Name = "ColliderPart"
	RagdollColliderPart.Size = Part.Size / 1.7
	RagdollColliderPart.Massless = true			
	RagdollColliderPart.CFrame = Part.CFrame
	RagdollColliderPart.Transparency = 1

	RagdollColliderPart.CollisionGroup = "Uncollidable"

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Part0 = RagdollColliderPart
	WeldConstraint.Part1 = Part

	WeldConstraint.Parent = RagdollColliderPart
	RagdollColliderPart.Parent = Part
end


function RagdollModule:ReplaceJoints(Character: Model)
	local Humanoid : Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	for _, Motor: Motor6D in Character:GetDescendants() do
		if Motor:IsA("Motor6D") then
			if not AttachmentCFrames[Motor.Name] then return end
			Motor.Enabled = false
			local Attachment0, Attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
			Attachment0.CFrame = AttachmentCFrames[Motor.Name][1]
			Attachment1.CFrame = AttachmentCFrames[Motor.Name][2]

			Attachment0.Name = "RagdollAttachment"
			Attachment1.Name = "RagdollAttachment"

			self:CreateColliderPart(Motor.Part1)

			local BallSocketConstraint = Instance.new("BallSocketConstraint")
			BallSocketConstraint.Attachment0 = Attachment0
			BallSocketConstraint.Attachment1 = Attachment1
			BallSocketConstraint.Name = "RagdollConstraint"

			BallSocketConstraint.Radius = 0.15
			BallSocketConstraint.LimitsEnabled = true
			BallSocketConstraint.TwistLimitsEnabled = true
			BallSocketConstraint.MaxFrictionTorque = 0
			BallSocketConstraint.Restitution = 0
			BallSocketConstraint.UpperAngle = 45
			BallSocketConstraint.TwistLowerAngle = -70
			BallSocketConstraint.TwistUpperAngle = 70
			BallSocketConstraint.Restitution = 0

			Attachment0.Parent = Motor.Part0
			Attachment1.Parent = Motor.Part1
			BallSocketConstraint.Parent = Motor.Parent
		end
	end
end

function RagdollModule:ResetJoints(Character: Model)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	if Humanoid then	
		if Humanoid.Health < 0.1 then return end
		for _, Instance in Character:GetDescendants() do
			if RagdollInstanceNames[Instance.Name] then
				Instance:Destroy()
			end

			if Instance:IsA("Motor6D") then
				Instance.Enabled = true
			end
		end
	end
end

return RagdollModule


-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.giveskill ] ==== --
return {
	Name = "giveskill";
	Aliases = {"gs"};
	Description = "Give a player a specific skill.";
	Group = "DefaultAdmin";
	
	
	
	Args = {
		{
			Type = "player";
			Name = "assailant";
			Description = "The players to give skill.";
		},
		
		{
			Type = "skillslot";
			Name = "The slot.";
			Description = "The slot to give the skill to. (0-9)";
		},
		
		{
			Type = "skillname";
			Name = "The skill.";
			Description = "The skill name to give. (exact name, case sensitive)";
		},
	};
}

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.giveskillServer ] ==== --
local profile_module

return function (registry, player, slot, skill)
	profile_module = profile_module or shared.Get("Profile")
	
	profile_module:TableSet(player, "Skills", tonumber(slot), skill)
end

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.giveskillset ] ==== --
return {
	Name = "giveskillset";
	Aliases = {"gss"};
	Description = "Give a player a specific skill set.";
	Group = "DefaultAdmin";
	
	
	
	Args = {
		{
			Type = "player";
			Name = "assailant";
			Description = "The players to give the skill set.";
		},
		
		{
			Type = "skillset";
			Name = "The skill set.";
			Description = "The skill set name to give. (exact name, case sensitive)";
		},
	};
}

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.giveskillsetServer ] ==== --
local r = game:GetService("ReplicatedStorage")
local m = r:WaitForChild("Modules")
local c = m:WaitForChild("Core")
local co = c:WaitForChild("Combat")
local skills = co:WaitForChild("Skills")

local profile_module

return function (registry, player, skill)
	profile_module = profile_module or shared.Get("Profile")
	
	local list = {
		[0] = "",
		[1] = "",
		[2] = "",
		[3] = "",
		[4] = "",
		[5] = "",
		[6] = "",
		[7] = "",
		[8] = "",
		[9] = "",
	}
	
	local skills_list = skills:FindFirstChild(skill)
	if not skills_list then
		return
	end
	
	for index, value in pairs(skills_list:GetChildren()) do
		list[index] = value.Name
	end
	
	profile_module:Set(player, "Skills", list)
end

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.spectate ] ==== --
return {
	Name = "spectate";
	Aliases = {"spec"};
	Description = "Spectate a given player.";
	Group = "DefaultAdmin";
	
	
	
	Args = {
		{
			Type = "player";
			Name = "assailant";
			Description = "The player to spectate.";
		},
	};
}

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.spectateServer ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")

local remotes = replicatedstorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("SpectatePlayer")

return function (registry, player)
	local executor = registry.Executor
	if executor then
		remote:FireClient(executor, player)
	end
end

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.unspectate ] ==== --
return {
	Name = "unspectate";
	Aliases = {"unspec"};
	Description = "Unspectate, if your currently spectating someone.";
	Group = "DefaultAdmin";
	
	
	
	Args = {
	};
}

-- ==== [ ServerScriptService.Scripts.Cmdr.Commands.unspectateServer ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")

local remotes = replicatedstorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("SpectatePlayer")

return function (registry)
	local executor = registry.Executor
	if executor then
		remote:FireClient(executor)
	end
end

-- ==== [ ServerScriptService.Scripts.Cmdr.Hooks.Perm ] ==== --
return function(register)
	register:RegisterHook("BeforeRun", function(context)
		--
	end)
end

-- ==== [ ServerStorage.Block ] ==== --
local runservice = game:GetService("RunService")

local players = game:GetService("Players")
local localplayer = players.LocalPlayer

local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")

local bridgenet = require(modules:WaitForChild("BridgeNet"))
local block_remote = bridgenet.ReferenceBridge("Block")
local gamedata = require(replicatedstorage:WaitForChild("GameData"))
local weapons_settings = gamedata.Weapons.Settings

local input_module
local tasks_module
local profile_module
local animation_module
local hitbox_module
local attributes_module
local force_module
local damage_module
local weapons_module
local block_module = {
	user_info = {}
}

local get_player_and_character = function(character)
	local character = character or localplayer.Character
	local player = players:GetPlayerFromCharacter(character)
	return player, character
end

local get_user_info = function(character)
	local player, character = get_player_and_character(character)
	block_module.user_info[player or character] = block_module.user_info[player or character] or {
		previous_posture = 0,
		reset_cooldown = 0,
		parry_cooldown = 0,
	}
	return block_module.user_info[player or character]
end

block_module.Initialize = function()
	tasks_module = shared.Get("Tasks")
	profile_module = shared.Get("Profile")
	hitbox_module = shared.Get("Hitbox")
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Block_Start",
			Key = Enum.KeyCode.F,
			Type = "Began",
			Callback = function()
				block_module.start_blocking(localplayer.Character)
			end,
		})
		
		input_module:Register({
			Name = "Block_Stop",
			Key = Enum.KeyCode.F,
			Type = "Ended",
			Callback = function()
				block_module.stop_blocking(localplayer.Character)
			end,
		})
	end
	
	if runservice:IsServer() then
		damage_module = shared.Get("Damage")
		weapons_module = shared.Get("Weapons")
		
		block_remote:Connect(function(player, bool)
			local character = player.Character or player.CharacterAdded:Wait()
			local character_posture = attributes_module:Get(character, "Posture")
			local user_info = get_user_info(character)
			
			if bool == true then
				if character_posture <= 0 then
					if os.time() - user_info.reset_cooldown > 2 then
						user_info.reset_cooldown = os.time()
						
						attributes_module:Adjust(character, "Posture", 5)
					else
						attributes_module:Adjust(character, "Posture", user_info.previous_posture)
					end
					
					if os.time() - user_info.parry_cooldown > 2 then
						user_info.parry_cooldown = os.time()
						
						attributes_module:TempAdjust(character, "Parry", true, 1)
					end
					
					attributes_module:Adjust(character, "State", "Blocking")
				end
			elseif bool == false then
				if character_posture > 0 then
					user_info.previous_posture = character_posture
					user_info.reset_cooldown = os.time()
					
					attributes_module:Adjust(character, "Posture", 0)
					
					if attributes_module:Get(character, "State") == "Blocking" then
						attributes_module:Adjust(character, "State", "Idle")
					end
				end
			end
		end)
	end
end

block_module.start_blocking = function(character)
	local player, character = get_player_and_character(character)
	
	local character_posture = attributes_module:Get(character, "Posture")
	if character_posture > 0 then
		return
	end
	
	if runservice:IsServer() then
		attributes_module:Adjust(character, "Posture", 5)
		attributes_module:Adjust(character, "State", "Blocking")
	else
		block_remote:Fire(true)
	end
	
	local block_animation = animation_module.new(character, "Blocking")
	block_animation:Play()
	block_animation.Looped = true
end

block_module.stop_blocking = function(character)
	local player, character = get_player_and_character(character)
	
	local character_posture = attributes_module:Get(character, "Posture")
	if character_posture <= 0 then
		return
	end

	if runservice:IsServer() then
		attributes_module:Adjust(character, "Posture", 0)
		attributes_module:Adjust(character, "State", "Idle")
	else
		block_remote:Fire(false)
	end

	local block_animation = animation_module:GetSpecificAnimation(character, "Blocking")
	if block_animation then
		block_animation:Stop()
	end
end

return block_module

-- ==== [ ServerStorage.Damage ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")

local bridgenet = require(modules:WaitForChild("BridgeNet"))
local basic_damage_effect = bridgenet.ReferenceBridge("BasicDamageEffect")
local blocked_damage_effect = bridgenet.ReferenceBridge("BlockedDamageEffect")
local parried_damage_effect = bridgenet.ReferenceBridge("ParriedDamageEffect")

local animation_module
local attributes_module
local damage_module = {}

damage_module.Initialize = function()
	animation_module = shared.Get("Animation")
	attributes_module = shared.Get("Attributes")
end

function damage_module:Damage(attacker, victim, damage, attack_type)
	local humanoid = victim.Humanoid
	local humanoidrootpart = victim.HumanoidRootPart
	
	local victim_posture = attributes_module:Get(victim, "Posture")
	local victim_parry = attributes_module:Get(victim, "Parry")
	
	if victim_parry == true then
		attributes_module:Add(attacker, "Stuns", 1)
		task.delay(2, function()
			attributes_module:Sub(attacker, "Stuns", 1)
		end)
		
		animation_module:StopAll(attacker)
		
		parried_damage_effect:Fire(bridgenet.AllPlayers(), attacker)
		
		return
	end
	
	if victim_posture > 0  then
		attributes_module:Sub(victim, "Posture", 1)
		
		local victim_posture = attributes_module:Get(victim, "Posture")
		if victim_posture <= 0 then
			print("block broken")
		end
		
		blocked_damage_effect:Fire(bridgenet.AllPlayers(), victim)
		
		return
	end
	
	humanoidrootpart.CFrame = CFrame.lookAt(humanoidrootpart.Position, attacker.HumanoidRootPart.Position)
	humanoid:TakeDamage(damage)
	animation_module:StopAll(victim)
	
	if attack_type == "Basic" then
		basic_damage_effect:Fire(bridgenet.AllPlayers(), victim)
	end
	
	attributes_module:Add(victim, "Stuns", 1)
	task.delay(1.5, function()
		attributes_module:Sub(victim, "Stuns", 1)
	end)
end

return damage_module

-- ==== [ ServerStorage.DamageEffects ] ==== --
local players = game:GetService("Players")
local player = players.LocalPlayer

local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")

local bridgenet = require(modules:WaitForChild("BridgeNet"))

local basic_damage_effect = bridgenet.ReferenceBridge("BasicDamageEffect")
local blocked_damage_effect = bridgenet.ReferenceBridge("BlockedDamageEffect")
local parried_damage_effect = bridgenet.ReferenceBridge("ParriedDamageEffect")

local vfx_module
local animation_module
local damageeffects_module = {}

damageeffects_module.Initialize = function()
	vfx_module = shared.Get("VFX")
	animation_module = shared.Get("Animation")
	
	local hit_animation_iteration = 1
	basic_damage_effect:Connect(function(victim)
		vfx_module:Emit(victim.HumanoidRootPart, "HitBasic")
		
		local block_animation = animation_module:GetSpecificAnimation(victim, "Blocking")
		if block_animation then
			block_animation:Stop()
		end
		
		local hit_animation = animation_module.new(victim, "Hit"..hit_animation_iteration)
		hit_animation:AdjustSpeed(1.4)
		hit_animation:AdjustWeight(1.02)
		hit_animation:Play()
		
		if hit_animation_iteration == 1 then
			hit_animation_iteration = 2
		else
			hit_animation_iteration = 1
		end
	end)
	
	blocked_damage_effect:Connect(function(victim)
		vfx_module:Emit(victim.HumanoidRootPart, "HitBlock")

		--local hit_animation = animation_module.new(victim, "Blo")
		--hit_animation:AdjustSpeed(1.4)
		--hit_animation:AdjustWeight(1.02)
		--hit_animation:Play()
	end)
	
	parried_damage_effect:Connect(function(victim)
		vfx_module:Emit(victim.HumanoidRootPart, "HitPerfect")
		
		local hit_animation = animation_module.new(victim, "Parried")
		hit_animation:AdjustSpeed(1.4)
		hit_animation:AdjustWeight(1.02)
		hit_animation:Play()
	end)
end

return damageeffects_module

-- ==== [ ServerStorage.DownedHandler ] ==== --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DownedHandler = {}
DownedHandler.ThresholdPercent = 0.10
DownedHandler.DownedTime = 15

local RagdollModule = require(ReplicatedStorage:WaitForChild("Ragdoll"))

local function getThreshold(humanoid: Humanoid, percent: number)
	local max = humanoid.MaxHealth
	if max <= 0 then return 0 end
	return max * percent
end

function DownedHandler:BindCharacter(character: Model)
	if not character or not character:IsA("Model") then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end

	if character:GetAttribute("DownedHandler_Bound") then return end
	character:SetAttribute("DownedHandler_Bound", true)

	character:SetAttribute("Downed", false)

	local downed = false
	local downedEndsAt = 0

	local function setDowned(state: boolean)
		downed = state
		character:SetAttribute("Downed", state)
	end

	local function evaluate()
		if humanoid.Parent == nil then return end

		if humanoid.Health <= 0 then
			return
		end

		if downed then
			if os.clock() >= downedEndsAt then
				setDowned(false)
				RagdollModule:unRagdoll(character)
			end
			return
		end

		local threshold = getThreshold(humanoid, self.ThresholdPercent)

		if humanoid.Health <= threshold then
			setDowned(true)
			downedEndsAt = os.clock() + self.DownedTime
			warn("[DownedHandler] Downed:", character.Name, "HP:", humanoid.Health, "Max:", humanoid.MaxHealth)
			RagdollModule:Ragdoll(character)

			task.delay(self.DownedTime, function()
				if not character or character.Parent == nil then return end
				local h = character:FindFirstChildWhichIsA("Humanoid")
				if not h then return end
				if h.Health <= 0 then return end

				if character:GetAttribute("Downed") == true and os.clock() >= downedEndsAt then
					setDowned(false)
					RagdollModule:unRagdoll(character)
				end
			end)
		end
	end

	evaluate()
	humanoid.HealthChanged:Connect(evaluate)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(evaluate)
end

function DownedHandler:Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:BindCharacter(character)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			self:BindCharacter(player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			self:BindCharacter(character)
		end)
	end
end

return DownedHandler


-- ==== [ ServerStorage.HeavyPunch ] ==== --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local HeavyPunch = {}

local input_module
local request_module
local attributes_module
local animation_module
local hitbox_module
local damage_module
local sfx_module

local REQ_START = "Ability_HeavyPunch_Start"
local REQ_CAST = "Ability_HeavyPunch_Cast"

local KEY = Enum.KeyCode.R
local COOLDOWN = 2.0
local RADIUS = 7
local DAMAGE = 20

local ANIM_NAME = "HeavyPunchAnim"
local SFX_NAME = "HeavyPunchHit"
local VFX_NAME = "HeavyPunchVFX"

local pending_cast = false
local casting_window = {}
local last_cast = {}

local function can_start(character: Model)
	local state = attributes_module:Get(character, "State")
	local stuns = attributes_module:Get(character, "Stuns") or 0
	if not table.find({ "Idle", "Sprinting" }, state) then
		return false
	end
	if stuns > 0 then
		return false
	end
	return true
end

function HeavyPunch:StartServer(player: Player)
	local character = player.Character
	if not character then return end
	if not can_start(character) then return end

	local now = os.clock()
	local prev = last_cast[player] or -math.huge
	if (now - prev) < COOLDOWN then
		return
	end
	last_cast[player] = now

	local anim_len = animation_module:GetLength(ANIM_NAME) or 0.7
	casting_window[player] = now + anim_len + 0.5

	request_module:Send({
		Name = "Play Animation",
		Class = "Unreliable",
		All = true,
		Perameters = { character, ANIM_NAME, 1, 1, false }
	})

	task.delay(anim_len + 0.6, function()
		if casting_window[player] and casting_window[player] <= os.clock() then
			casting_window[player] = nil
		end
	end)
end

function HeavyPunch:CastServer(player: Player)
	local expires = casting_window[player]
	if not expires or os.clock() > expires then
		return
	end
	casting_window[player] = nil

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local hits = hitbox_module:SpawnBox({
		CFrame = hrp.CFrame * CFrame.new(0, 0, -3),
		Size = Vector3.new(4, 5, 6),
		Filter = {character},
		Visible = true,
	})

	local hitCount = 0
	local unique = {}

	for _, victim in ipairs(hits) do
		if victim and victim ~= character and not unique[victim] then
			unique[victim] = true
			hitCount += 1

			damage_module:Damage({
				Attacker = character,
				Victim = victim,
				Damage = DAMAGE,
				Type = "Ability",
				Knockback = true,
			})
		end
	end

	if hitCount > 0 then
		request_module:Send({
			Name = "Emit VFX",
			Class = "Unreliable",
			All = true,
			Perameters = { hrp, VFX_NAME }
		})

		sfx_module:Play(hrp, SFX_NAME, { Volume = 1 })
	end
end

function HeavyPunch.Initialize()
	request_module = shared.Get("Request")
	attributes_module = shared.Get("Attributes")
	animation_module = shared.Get("Animation")
	hitbox_module = shared.Get("Hitbox")
	sfx_module = shared.Get("SFX")

	if RunService:IsClient() then
		input_module = shared.Get("Input")

		local function on_cast_marker(character)
			if character ~= (localPlayer.Character) then
				return
			end
			if not pending_cast then
				return
			end
			pending_cast = false
			request_module:Send({
				Name = REQ_CAST,
				Class = "Unreliable",
				Perameters = {}
			})
		end

		if animation_module.marker_callbacks and animation_module.marker_callbacks["Cast"] then
			local old = animation_module.marker_callbacks["Cast"]
			animation_module.marker_callbacks["Cast"] = function(character, ...)
				old(character, ...)
				on_cast_marker(character)
			end
		else
			animation_module:RegisterMarker({
				Name = "Cast",
				Callback = function(character, ...)
					on_cast_marker(character)
				end
			})
		end

		input_module:Register({
			Name = "HeavyPunch_Ability",
			Key = KEY,
			Type = "Began",
			Callback = function()
				pending_cast = true
				task.delay(2, function()
					pending_cast = false
				end)

				request_module:Send({
					Name = REQ_START,
					Class = "Unreliable",
					Perameters = {}
				})
			end
		})
	end

	if RunService:IsServer() then
		damage_module = shared.Get("Damage")

		request_module:Register({
			Name = REQ_START,
			Callback = function(player)
				HeavyPunch:StartServer(player)
			end
		})

		request_module:Register({
			Name = REQ_CAST,
			Callback = function(player)
				HeavyPunch:CastServer(player)
			end
		})
	end
end

return HeavyPunch


-- ==== [ ServerStorage.SkillsService ] ==== --
local SkillsService = {}

function SkillsService:SetMoveset(profile, movesetName)
	local SkillsRoot = game.ReplicatedStorage.Modules.Combat.Skills
	local folder = SkillsRoot:FindFirstChild(movesetName)
	if not folder then return end

	for i = 1, 10 do
		profile.Data.Skills[i] = ""
	end

	local slot = 1
	for _, mod in ipairs(folder:GetChildren()) do
		if mod:IsA("ModuleScript") then
			profile.Data.Skills[slot] = mod.Name
			slot += 1
		end
	end
end

return SkillsService


-- ==== [ ServerStorage.Swing ] ==== --
local runservice = game:GetService("RunService")

local players = game:GetService("Players")
local localplayer = players.LocalPlayer

local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")

local bridgenet = require(modules:WaitForChild("BridgeNet"))
local swing_remote = bridgenet.ReferenceBridge("Swing")
local damage_remote = bridgenet.ReferenceBridge("Damage")
local gamedata = require(replicatedstorage:WaitForChild("GameData"))
local weapons_settings = gamedata.Weapons.Settings

local input_module
local tasks_module
local profile_module
local animation_module
local hitbox_module
local attributes_module
local force_module
local damage_module
local weapons_module
local swing_module = {
	user_info = {}
}

local get_player_and_character = function(character)
	local character = character or localplayer.Character
	local player = players:GetPlayerFromCharacter(character)
	return player, character
end

local get_user_info = function(user)
	swing_module.user_info[user] = swing_module.user_info[user] or {
		swinging = false,
		cooldown = false,
		count = 0,
		previous_tick = math.huge,
	}
	return swing_module.user_info[user]
end

local continue_swings = function(character)
	local player, character = get_player_and_character(character)
	swing_module.user_info[player or character] = swing_module.user_info[player or character] or {
		swinging = false,
		cooldown = false,
		count = 0,
		previous_tick = math.huge,
	}
	local user_info = swing_module.user_info[player or character]
	
	local current = os.time()
	local difference = current - user_info.previous_tick
	user_info.previous_tick = os.time()
	
	if difference > weapons_settings.Tick then
		return false
	end
	
	return true
end

swing_module.Initialize = function()
	tasks_module = shared.Get("Tasks")
	profile_module = shared.Get("Profile")
	hitbox_module = shared.Get("Hitbox")
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Swing_Start",
			Key = Enum.UserInputType.MouseButton1,
			Type = "Began",
			Callback = function()
				swing_module.start_swinging()
			end,
		})

		input_module:Register({
			Name = "Swing_Stop",
			Key = Enum.UserInputType.MouseButton1,
			Type = "Ended",
			Callback = function()
				swing_module.stop_swinging()
			end,
		})

		animation_module:RegisterMarker({
			Name = "Hit",
			Callback = function(character, attack_type)
				local humanoidrootpart = character.HumanoidRootPart
				
				force_module.apply({
					Object = humanoidrootpart,
					Velocity = humanoidrootpart.CFrame.LookVector,
					Speed = 15,
					MaxForce = Vector3.new(1e6, 1e2, 1e6),
					Power = 1250,
					Fade = {0.05, "Out"},
					Lifetime = "Fade",
				})
				
				local hitbox = hitbox_module:SpawnBox({
					CFrame = humanoidrootpart.CFrame * hitbox_module.adjustment,
					Size = hitbox_module.size,
					Filter = {character},
					Visible = false,
				})

				if #hitbox > 0 then
					damage_remote:Fire(attack_type or "Basic")
				end
			end,
		})
	end
	
	if runservice:IsServer() then
		damage_module = shared.Get("Damage")
		weapons_module = shared.Get("Weapons")
		
		swing_remote:Connect(function(player, swinging)
			local character = player.Character
			local character_state = attributes_module:Get(character, "State")

			if swinging == true and character_state == "Idle" then
				attributes_module:Adjust(character, "State", "Swinging")
			elseif swinging == false and character_state == "Swinging" then
				attributes_module:Adjust(character, "State", "Idle")
			end
		end)
		
		animation_module:RegisterMarker({
			Name = "Hit",
			Callback = function(character, attack_type)
				local humanoidrootpart = character.HumanoidRootPart
				force_module.apply({
					Object = humanoidrootpart,
					Velocity = humanoidrootpart.CFrame.LookVector,
					Speed = 15,
					MaxForce = Vector3.new(1e6, 1e2, 1e6),
					Power = 1250,
					Fade = {0.05, "Out"},
					Lifetime = "Fade",
				})
				
				weapons_module.damage_check(character, attack_type or "Basic")
			end,
		})
	end
end

swing_module.start_swinging = function()
	--print("STARTED SWININGING")
	if runservice:IsServer() then
		return
	end
	
	if swing_module.swinging then
		return
	end
	swing_module.swinging = true
	
	local character = localplayer.Character or localplayer.CharacterAdded:Wait()
	local user_info = get_user_info(localplayer)
	
	tasks_module.overwrite({
		Player = localplayer,
		Name = "Swinging",
		Delay = 0,
		Callback = function()
			while task.wait() do
				if user_info.cooldown then
					continue
				end
				
				task.spawn(function()
					swing_module:Swing(character)
				end)
			end
		end,
	})
end

swing_module.stop_swinging = function()
	--print("STOPED SWININGING")
	if runservice:IsServer() then
		return
	end
	
	if not swing_module.swinging then
		return
	end
	swing_module.swinging = false
	
	tasks_module.cancel({
		Player = localplayer,
		Name = "Swinging"
	})
end

function swing_module:Swing(character)
	local player, character = get_player_and_character(character)
	local user_info = get_user_info(player or character)
	if user_info.cooldown then
		return
	end
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	if character_state ~= "Idle" or character_stuns > 0 then
		return
	end
	user_info.cooldown = true
	
	if runservice:IsServer() then
		attributes_module:Adjust(character, "State", "Swinging")
	else
		swing_remote:Fire(true)
	end
	
	local profile
	if player then
		profile = profile_module:GetProfile(player)
	else
		profile = {Weapon = "Fists"}
	end
	
	local weapon = profile.Weapon
	local weapon_settings = gamedata.Weapons[weapon]
	
	if continue_swings(player or character) then
		user_info.count += 1
		if user_info.count > weapons_settings.Count then
			user_info.count = 1
		end
	else
		user_info.count = 1
	end
	
	local swing_animation = animation_module.new(character, weapon.."Swing"..tostring(user_info.count))
	swing_animation:AdjustSpeed(1.4)
	swing_animation:AdjustWeight(1.02)
	swing_animation:Play()
	swing_animation.Stopped:Wait()
	
	if runservice:IsServer() then
		attributes_module:Adjust(character, "State", "Idle")
	else
		swing_remote:Fire(false)
	end
 	
	if user_info.count >= weapons_settings.Count then
		task.wait(weapons_settings.Cooldown)
	end
	user_info.cooldown = false
end

return swing_module

-- ==== [ ServerStorage.WallJump ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer
local previous_press = 0

local raycastparams = RaycastParams.new()
raycastparams.FilterType = Enum.RaycastFilterType.Include

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local walljump_module = {
	user_info = {}
}

local get_user_info = function(player)
	walljump_module.user_info[player] = walljump_module.user_info[player] or {
		
	}
	return walljump_module.user_info[player]
end

walljump_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		input_module = shared.Get("Input")
		
		input_module:Register({
			Name = "Air Jump",
			Key = Enum.KeyCode.Space,
			Type = "Began",
			Callback = function()
				local character = localplayer.Character or localplayer.CharacterAdded:Wait()
				local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
				local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end
				
				if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
					return
				end
				
				raycastparams.FilterDescendantsInstances = workspace.World:GetDescendants()
				local right_raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * 4, raycastparams)
				local left_raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * -4, raycastparams)
				
				local side
				if right_raycast then
					side = "Right"
				elseif left_raycast then
					side = "Left"
				end
				
				if not side then
					return
				end
				
				request_module:Send({
					Name = "Wall Jump",
					Class = "Event",
					Perameters = {side}
				})
			end,
		})
	end
	
	if runservice:IsServer() then
		request_module:Register({
			Name = "Wall Jump",
			Callback = function(...)
				walljump_module:Jump(...)
			end,
		})
	end
end

function walljump_module:Jump(player, side)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end
	
	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end
	
	if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	
	print(side)
	
	--local user_info = get_user_info(player)
	--if os.time() - user_info.cooldown < 3 then
	--	return
	--end
	--user_info.cooldown = os.time()
	
	local velocity_sides = {
		["Right"] = humanoidrootpart.CFrame.RightVector + humanoidrootpart.CFrame.LookVector,
		["Left"] = (humanoidrootpart.CFrame.RightVector * -1) + humanoidrootpart.CFrame.LookVector
	}
	
	force_module.apply({
		Object = humanoidrootpart,
		Velocity = velocity_sides[side],
		Speed = 100,
		MaxForce = Vector3.new(1e6, 1e6, 1e6),
		Power = 1250,
		Fade = {0.05, "Out"},
		Lifetime = "Fade",
	})
end

return walljump_module

-- ==== [ ServerStorage.WallRun ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer
local holding_keys = {
	Space = false,
	D = false,
	A = false,
	W = false,
}

local side_infos = {
	Right = {
		rotation = CFrame.Angles(0, math.rad(90), 0)
	},
	Left = {
		rotation = CFrame.Angles(0, math.rad(-90), 0)
	}
}

local raycast_params = RaycastParams.new()
raycast_params.FilterType = Enum.RaycastFilterType.Exclude

local attributes_module
local force_module
local input_module
local animation_module
local vfx_module
local request_module
local wallrun_module = {
	user_info = {}
}

local get_user_info = function(player)
	wallrun_module.user_info[player] = wallrun_module.user_info[player] or {
		cooldown = 0,
		wallrunning = false,
		side = "",
	}
	return wallrun_module.user_info[player]
end

local configured
local configure_character = function(character)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	
	if configured then
		configured:Disconnect()
	end
	
	configured = runservice.Heartbeat:Connect(function()
		if not character.Parent then
			return
		end
		
		local humanoid_state = humanoid:GetState()
		if humanoid_state == Enum.HumanoidStateType.Freefall and holding_keys.Space then
			wallrun_module:WallRun(localplayer)
		end
	end)
end

wallrun_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	force_module = shared.Get("Force")
	animation_module = shared.Get("Animation")
	vfx_module = shared.Get("VFX")
	request_module = shared.Get("Request")

	if runservice:IsClient() then
		input_module = shared.Get("Input")

		for key, _ in pairs(holding_keys) do
			input_module:Register({
				Name = "Wall Run Holding "..key,
				Key = Enum.KeyCode[key],
				Type = "Began",
				Callback = function()
					holding_keys[key] = true
				end,
			})
		end

		for key, _ in pairs(holding_keys) do
			input_module:Register({
				Name = "Wall Run Holding "..key,
				Key = Enum.KeyCode[key],
				Type = "Ended",
				Callback = function()
					holding_keys[key] = false
					
					if key == "W" then
						wallrun_module:UnWallRun(localplayer)
					end
				end,
			})
		end

		local character = localplayer.Character or localplayer.CharacterAdded:Wait()
		configure_character(character)

		localplayer.CharacterAdded:Connect(configure_character)
	end

	if runservice:IsServer() then
		request_module:Register({
			Name = "Wall Run",
			Callback = function(...)
				wallrun_module:WallRun(...)
			end,
		})
	end
end

function wallrun_module:WallRun(player, raycast)
	local character:Model = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end

	local character_state = attributes_module:Get(character, "State")
	local character_stuns = attributes_module:Get(character, "Stuns")
	if not table.find({"Idle", "Sprinting"}, character_state) or character_stuns > 0 then
		return
	end

	if runservice:IsServer() then
		print(raycast)

		return
	end

	local humanoid_state = humanoid:GetState()
	if not table.find({Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping}, humanoid_state) then
		return
	end

	local user_info = get_user_info(player)
	if user_info.wallrunning then
		return
	end
	
	if os.time() - user_info.cooldown < 1 then
		return
	end
	user_info.cooldown = os.time()

	raycast_params.FilterDescendantsInstances = workspace.Live:GetChildren()
	local raycast
	if holding_keys.W and holding_keys.D then
		user_info.side = "Right"
		raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * 4, raycast_params)
	elseif holding_keys.W and holding_keys.A then
		user_info.side = "Left"
		raycast = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * -4, raycast_params)
	end
	
	local side_info = side_infos[user_info.side]

	if raycast then
		local instance = raycast.Instance
		
		user_info.wallrunning = true
		
		local face = CFrame.new(raycast.Position + raycast.Normal, raycast.Position) * side_info.rotation
		
		local bodygryo = force_module.rotate({
			Object = humanoidrootpart,
			CFrame = face,
			Power = 1e4,
		})
		
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		humanoidrootpart.CFrame = face
		
		local bodyvelocity = force_module.apply({
			Object = humanoidrootpart,
			Velocity = humanoidrootpart.CFrame.LookVector,
			Speed = 50,
			MaxForce = Vector3.new(math.huge, math.huge, math.huge),
		})
		
		--request_module:Send({
		--	Name = "Wall Run",
		--	Class = "Unreliable",
		--	Perameters = {raycast},
		--})
		
		while user_info.wallrunning do
			local wallcheck
			if user_info.side == "Right" then
				wallcheck = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * 4, raycast_params)
			elseif user_info.side == "Left" then
				wallcheck = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.RightVector * -4, raycast_params)
			end
			
			local floorcheck = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.UpVector * -4, raycast_params)
			local frontwallcheck = workspace:Raycast(humanoidrootpart.Position, humanoidrootpart.CFrame.LookVector * 5, raycast_params)
			
			if not wallcheck or floorcheck or frontwallcheck then
				wallrun_module:UnWallRun(player)
			end
			
			runservice.Heartbeat:Wait()
		end
	end
end

function wallrun_module:UnWallRun(player)
	local character:Model = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChild("Humanoid") ; if not humanoid then return end
	local humanoidrootpart = character:FindFirstChild("HumanoidRootPart") ; if not humanoidrootpart then return end
	
	local user_info = get_user_info(player)
	if not user_info.wallrunning then
		return
	end
	
	user_info.wallrunning = false
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	
	local bodyvelocity = humanoidrootpart:FindFirstChildOfClass("BodyVelocity")
	if bodyvelocity then
		bodyvelocity:Destroy()
	end
	
	local bodygyro = humanoidrootpart:FindFirstChildOfClass("BodyGyro")
	if bodygyro then
		bodygyro:Destroy()
	end
end

return wallrun_module

-- ==== [ ServerStorage.Weapons ] ==== --
local players = game:GetService("Players")

local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")

local gamedata = require(replicatedstorage:WaitForChild("GameData"))

local bridgenet = require(modules:WaitForChild("BridgeNet"))
local swing_remote = bridgenet.ReferenceBridge("Swing")
local damage_remote = bridgenet.ReferenceBridge("Damage")

local attributes_module
local hitbox_module
local profile_module
local damage_module
local weapons_module = {}

local get_player_and_character = function(player: Instance)
	local new_player
	local character
	
	if player:IsA("Player") then
		new_player = player
		character = player.Character
	else
		new_player = nil
		character = player
	end
	
	return new_player, character
end

weapons_module.Initialize = function()
	attributes_module = shared.Get("Attributes")
	hitbox_module = shared.Get("Hitbox")
	profile_module = shared.Get("Profile")
	damage_module = shared.Get("Damage")
	
	damage_remote:Connect(weapons_module.damage_check)
end

weapons_module.damage_check = function(player, attack_type)
	local player, character = get_player_and_character(player)
	
	local humanoidrootpart = character.HumanoidRootPart
	
	local profile
	if player then
		profile = profile_module:GetProfile(player)
		profile = profile.Data
	else
		profile = {Weapon = "Fists"}
	end
	
	local weapon = profile.Weapon
	local weapon_settings = gamedata.Weapons[weapon]
	local damage = weapon_settings.Damage
	
	local hitbox = hitbox_module:SpawnBox({
		CFrame = humanoidrootpart.CFrame * hitbox_module.adjustment,
		Size = hitbox_module.size,
		Filter = {character},
		Visible = true,
	})
	
	if #hitbox > 0 then
		for index, hit in pairs(hitbox) do
			damage_module:Damage(character, hit, damage, attack_type)
		end
	end
end

return weapons_module

-- ==== [ StarterPlayer.StarterPlayerScripts.Modules.Uitl.Input ] ==== --
local uis = game:GetService("UserInputService")

local input_module = {
	callbacks = {}
}

input_module.Initialize = function()
	uis.InputBegan:Connect(function(input, gameprocessed)
		if gameprocessed then
			return
		end
		
		local key = input.KeyCode
		local userinput = input.UserInputType
		local callbacks = input_module.callbacks[key] or input_module.callbacks[userinput]
		
		if not callbacks then
			return
		end
		
		for index, info in pairs(callbacks) do
			local name = info.Name
			local keycode = info.Key
			local input_type = info.Type
			local callback = info.Callback
			
			if input_type == "Began" then
				callback()
			end
		end
	end)
	
	uis.InputEnded:Connect(function(input, gameprocessed)
		if gameprocessed then
			return
		end

		local key = input.KeyCode
		local userinput = input.UserInputType
		local callbacks = input_module.callbacks[key] or input_module.callbacks[userinput]
		
		if not callbacks then
			return
		end
		
		for index, info in pairs(callbacks) do
			local name = info.Name
			local keycode = info.Key
			local input_type = info.Type
			local callback = info.Callback

			if input_type == "Ended" then
				callback()
			end
		end
	end)
end

function input_module:Register(info)
	local name = info.Name
	local keycode = info.Key
	local input_type = info.Type
	local callback = info.Callback
	
	input_module.callbacks[keycode] = input_module.callbacks[keycode] or {}
	table.insert(input_module.callbacks[keycode], info)
end

return input_module

-- ==== [ ReplicatedStorage.Modules.Util.VFX ] ==== --
local runservice = game:GetService("RunService")

local replicatedstorage = game:GetService("ReplicatedStorage")
local assets = replicatedstorage:WaitForChild("Assets")
local vfx_assets = assets:WaitForChild("VFX")

local debris = game:GetService("Debris")

local request_module
local vfx_module = {}

local get_lifetime = function(object)
	local longest = 0
	for index, value in pairs(object:GetDescendants()) do
		local haslifetime = pcall(function()
			if value.Lifetime.Max > longest then
				longest = value.Lifetime.Max
			end
		end)
	end
	return (longest + 1)
end

vfx_module.Initialize = function()
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		request_module:Register({
			Name = "Emit VFX",
			Callback = function(player, parent, name)
				vfx_module:Emit(parent, name)
			end
		})
		
		request_module:Register({
			Name = "Play VFX",
			Callback = function(player, parent, name, duration)
				vfx_module:Play(parent, name, duration)
			end
		})
		
		request_module:Register({
			Name = "Trail VFX",
			Callback = function(player, parent, duration)
				vfx_module:Trail(parent, duration)
			end
		})
	end
end

function vfx_module:GetLifetime(object)
	return get_lifetime(object)
end

function vfx_module:Emit(parent, name)
	local vfx = vfx_assets:FindFirstChild(name)
	if not vfx then
		return
	end
	
	local lifetime = get_lifetime(vfx)
	
	for index, value in pairs(vfx:GetChildren()) do
		local clone = value:Clone()
		clone.Parent = parent
		
		if value:IsA("ParticleEmitter") then
			clone:Emit(value:GetAttribute("EmitCount"))
		elseif value:IsA("Attachment") then
			for _, particle in pairs(clone:GetChildren()) do
				if particle:IsA("ParticleEmitter") then
					particle:Emit(particle:GetAttribute("EmitCount"))
				end
			end
		end
		
		debris:AddItem(clone, lifetime)
	end
end

function vfx_module:Play(parent, name, duration)
	local vfx = vfx_assets:FindFirstChild(name)
	if not vfx then
		return
	end

	for index, value in pairs(vfx:GetChildren()) do
		local clone = value:Clone()
		clone.Parent = parent

		if clone:IsA("Attachment") then
			for _, particle in pairs(clone:GetChildren()) do
				if particle:IsA("ParticleEmitter") then
					clone.Enabled = true
				end
			end
		elseif clone:IsA("ParticleEmitter") then
			clone.Enabled = true
		end
	end

	if duration then
		task.delay(duration, function()
			vfx_module:Stop(parent)
		end)
	end
end

function vfx_module:Stop(parent)
	for index, value in pairs(parent:GetChildren()) do
		if value:IsA("ParticleEmitter") then
			value:Destroy()
		elseif value:IsA("Attachment") then
			local particle = value:FindFirstChildOfClass("ParticleEmitter")
			if particle then
				value:Destroy()
			end
		end
	end
end

function vfx_module:Trail(parent, duration)
	local vfx = vfx_assets.Trail
	
	local a0 = vfx.Attachment0:Clone()
	local a1 = vfx.Attachment1:Clone()
	local trail = vfx.Trail:Clone()
	
	a0.Parent = parent
	a1.Parent = parent
	trail.Parent = parent
	
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	
	if duration then
		debris:AddItem(a0, duration)
		debris:AddItem(a1, duration)
		debris:AddItem(trail, duration)
	end
end

return vfx_module

-- ==== [ ReplicatedStorage.Modules.Util.Tasks ] ==== --
local tasks_module = {
	existing = {}
}

tasks_module.overwrite = function(info)
	local player = info.Player
	local name = info.Name
	local length = info.Delay or 0
	local callback = info.Callback
	
	tasks_module.existing[player] = tasks_module.existing[player] or {}
	
	local current = tasks_module.existing[player][name]
	if current then
		tasks_module.cancel(info)
	end
	
	tasks_module.existing[player][name] = task.delay(length, callback)
end

tasks_module.cancel = function(info)
	local player = info.Player
	local name = info.Name
	
	tasks_module.existing[player] = tasks_module.existing[player] or {}
	
	local current = tasks_module.existing[player][name]
	if not current then
		return --warn(name, "task doesnt exist.")
	end
	
	local success, failure = pcall(function()
		task.cancel(current)
	end)
	if not success then
		print(failure)
	end
end

tasks_module.cancelall = function(player)
	tasks_module.existing[player] = tasks_module.existing[player] or {}
	
	for index, value in pairs(tasks_module.existing[player]) do
		local success, failure = pcall(function()
			task.cancel(value)
		end)
		if not success then
			print(failure)
		end
	end
end

return tasks_module

-- ==== [ ReplicatedStorage.Modules.Util.SFX ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")
local assets = replicatedstorage:WaitForChild("Assets")
local sounds = assets:WaitForChild("SFX")

local debris = game:GetService("Debris")

local sound_module = {}

sound_module.get = function(name)
	local sound = sounds:FindFirstChild(name, true)
	if sound then
		sound = sound:Clone()
		return sound
	end
end

function sound_module:Play(parent, name, sound_settings)
	local volume = 1
	local max = 10000
	local min = 10
	
	if sound_settings and type(sound_settings) == "table" then
		volume = sound_settings.Volume or volume
		max = sound_settings.MaxDistance or max
		min = sound_settings.MinDistance or min
	end
	
	local sounds
	
	if type(name) ~= "table" then
		sounds = {name}
	else
		sounds = name
	end
	
	for _, str in pairs(sounds) do
		local sound = sound_module.get(str)
		if sound then
			sound.Volume = volume
			sound.RollOffMaxDistance = max
			sound.RollOffMinDistance = min
			sound.PlayOnRemove = true
			sound.Parent = parent
			sound:Destroy()
		end
	end
end

return sound_module

-- ==== [ ReplicatedStorage.Modules.Util.Request ] ==== --
local runservice = game:GetService("RunService")
local players = game:GetService("Players")

local localplayer = players.LocalPlayer

local request_module = {
	callbacks = {}
}

request_module.Initialize = function()
	local function_remote = script.Function
	local event_remote = script.Event
	local unreliable_remote = script.Unreliable
	
	if runservice:IsClient() then
		event_remote.OnClientEvent:Connect(function(name, perameters)
			local callback = request_module.callbacks[name]
			if not callback then
				return
			end

			callback(localplayer, table.unpack(perameters))
		end)
		
		unreliable_remote.OnClientEvent:Connect(function(name, perameters)
			local callback = request_module.callbacks[name]
			if not callback then
				return
			end

			callback(localplayer, table.unpack(perameters))
		end)
	end
	
	if runservice:IsServer() then
		event_remote.OnServerEvent:Connect(function(player, name, perameters)
			local callback = request_module.callbacks[name]
			if not callback then
				return
			end
			
			callback(player, table.unpack(perameters))
		end)
		
		unreliable_remote.OnServerEvent:Connect(function(player, name, perameters)
			local callback = request_module.callbacks[name]
			if not callback then
				return
			end
			
			callback(player, table.unpack(perameters))
		end)
	end
end

function request_module:Send(info)
	local name = info.Name
	local class = info.Class
	local all = info.All or false
	local perameters = info.Perameters or {}
	
	local remote = script:FindFirstChild(class)
	
	if not name or not class or not remote then
		print(name, class, remote)
		return
	end
	
	if runservice:IsClient() then
		if class == "Function" then
			remote:InvokeServer(name, perameters)
		elseif class == "Event" or class == "Unreliable" then
			remote:FireServer(name, perameters)
		end
	elseif runservice:IsServer() then
		if class == "Function" then
			remote:InvokeClient(name, perameters)
		elseif class == "Event" or class == "Unreliable" then
			if all == true then
				remote:FireAllClients(name, perameters)
			else
				remote:FireClient(perameters[1], name, perameters)
			end
		end
	end
end

function request_module:Register(info)
	local name = info.Name
	local callback = info.Callback
	
	if not name or not callback then
		return
	end
	
	request_module.callbacks[name] = callback
end

return request_module

-- ==== [ ReplicatedStorage.Modules.Util.Hitbox ] ==== --
local replicatedstorage = game:GetService("ReplicatedStorage")
local assets = replicatedstorage:WaitForChild("Assets")

local debris = game:GetService("Debris")

local hitbox_module = {
	adjustment = CFrame.new(0, 0, -2),
	size = Vector3.new(4, 5.5, 3),
	radius = 10,
}

function hitbox_module:SpawnBox(info)
	local cframe = info.CFrame
	local size = info.Size
	local filter = info.Filter
	local visible = info.Visible
	
	if visible then
		local part = assets.Part:Clone()
		part.BrickColor = BrickColor.Red()
		part.Transparency = 0.8
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Size = size
		part.CFrame = cframe
		part.Parent = workspace.Ignore
		
		debris:AddItem(part, 0.1)
	end
	
	local perams = OverlapParams.new()
	perams.FilterType = Enum.RaycastFilterType.Exclude
	perams.FilterDescendantsInstances = filter or {}
	local results = workspace:GetPartBoundsInBox(cframe, size, perams)
	
	local fixed_results = {}
	for index, value in pairs(results) do
		local character = value.Parent
		if character:FindFirstChild("Humanoid") and not table.find(fixed_results, character) then
			table.insert(fixed_results, character)
		end
	end
	
	table.clear(results)
	return fixed_results
end

function hitbox_module:SpawnMagnitude(info)
	local radius = info.Radius
	local position = info.Position
	local visible = info.Visible
	local filter = info.Filter or {}
	
	if visible then
		local size = radius * 2
		local part = assets.Part:Clone()
		part.Shape = Enum.PartType.Ball
		part.BrickColor = BrickColor.Red()
		part.Transparency = 0.5
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Size = Vector3.new(size, size, size)
		part.Position = position
		part.Parent = workspace.Ignore
		
		debris:AddItem(part, 0.1)
	end
	
	local checked = {}
	local results = {}
	
	for index, character in pairs(workspace:GetDescendants()) do
		if character:FindFirstChild("Humanoid") then
			local has_checked = table.find(checked, character) or table.find(checked, character.Parent)
			
			if not has_checked and not table.find(filter, character) then
				local humanoidrootpart = character.HumanoidRootPart
				local magnitude = (humanoidrootpart.Position - position).Magnitude
				if magnitude <= radius then
					table.insert(results, character)
				end
			end
			
			table.insert(checked, character)
		end
	end
	
	return results
end

return hitbox_module

-- ==== [ ReplicatedStorage.Modules.Util.Force ] ==== --
local live = workspace:WaitForChild("Live")

local bodyvelocity = script:WaitForChild("BodyVelocity")
local bodyposition = script:WaitForChild("BodyPosition")
local bodygyro = script:WaitForChild("BodyGyro")

local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")

local force_module = {}

force_module.apply = function(info)
	local object = info.Object
	local velocity = info.Velocity
	local speed = info.Speed
	local maxforce = info.MaxForce
	local power = info.Power
	local lifetime = info.Lifetime
	local fade = info.Fade
	
	local newvelocity = bodyvelocity:Clone()
	newvelocity.Velocity = velocity * speed
	if maxforce then newvelocity.MaxForce = maxforce end
	if power then newvelocity.P = power end
	
	if fade and type(fade) == "table" then
		local duration = fade[1]
		local inout = fade[2]
		
		local delaytime = duration
		local p = 0
		
		if inout == "In" then
			delaytime = 0
			p = power
			
			newvelocity.P = 0
		end
		
		local tweeninfo = TweenInfo.new(duration / 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, delaytime)
		local tween = tweenservice:Create(newvelocity, tweeninfo, {P = p})
		tween:Play()
		
		if lifetime and lifetime == "Fade" then
			tween.Completed:Once(function()
				newvelocity:Destroy()
			end)
		end
	end
	
	if lifetime and lifetime ~= "Fade" then
		debris:AddItem(newvelocity, lifetime)
	end
	
	newvelocity.Parent = object
	return newvelocity
end

force_module.set = function(info)
	local object = info.Object
	local position = info.Position
	local dampening = info.Dampening
	local maxforce = info.MaxForce
	local power = info.Power
	local lifetime = info.Lifetime

	local newposition = bodyposition:Clone()
	if position then newposition.Position = position end
	if dampening then newposition.D = dampening end
	if power then newposition.P = power end
	if maxforce then newposition.MaxForce = maxforce end

	if lifetime then
		debris:AddItem(newposition, lifetime)
	end

	newposition.Parent = object
	return newposition
end

force_module.rotate = function(info)
	local object = info.Object
	local cframe = info.CFrame
	local power = info.Power
	local maxtorque = info.MaxTorque
	local lifetime = info.Lifetime
	
	local newgryo = bodygyro:Clone()
	if cframe then newgryo.CFrame = cframe end
	if power then newgryo.P = power end
	if maxtorque then newgryo.MaxTorque = maxtorque end
	
	if lifetime then
		debris:AddItem(newgryo, lifetime)
	end
	
	newgryo.Parent = object
	return newgryo
end

return force_module

-- ==== [ ReplicatedStorage.Modules.Util.Attributes ] ==== --
local players = game:GetService("Players")

local copy_attributes = {
	["State"] = "Idle",
	["Stuns"] = 0,
	["Posture"] = 0,
	["Parry"] = false,
	["Vent"] = 0,
	["WeaponEquipped"] = false
}

local get_player_and_character = function(user: Instance)
	local player
	local character

	if user:IsA("Player") then
		player = user
		character = user.Character
	elseif user:IsA("Model") then
		player = players:GetPlayerFromCharacter(user)
		character = user
	end

	return player, character
end

local tasks_module
local attributes_module = {}

attributes_module.Initialize = function()
	tasks_module = shared.Get("Tasks")
end

function attributes_module:Configure(character)
	if character:IsA("Player") then
		character = character.Character
	end

	if typeof(character) ~= "Instance" then
		error("Configure expects a valid Instance for Character")
	end

	for index, value in pairs(copy_attributes) do
		character:SetAttribute(index, value)
	end
end

function attributes_module:Set(character, attribute, value)
	local player, character = get_player_and_character(character)
	
	tasks_module.cancel({
		Player = player or character,
		Name = "Temp Set "..attribute
	})

	character:SetAttribute(attribute, value)
end

function attributes_module:TempSet(character, attribute, value, duration)
	local player, character = get_player_and_character(character)
	
	tasks_module.overwrite({
		Player = player or character,
		Name = "Temp Set "..attribute,
		Callback = function()
			local current = character:GetAttribute(attribute)
			character:SetAttribute(attribute, value)
			task.wait(duration)
			character:SetAttribute(attribute, current)
		end,
	})
end

function attributes_module:Add(character, attribute, addition, cap)
	if character:IsA("Player") then
		character = character.Character
	end
	
	local value = character:GetAttribute(attribute)
	if value == nil then
		return
	end
	
	local difference = value + addition

	if cap then
		if cap.Size == ">" then
			if difference > cap.Value then
				difference = cap.Value
			end
		elseif cap.Size == "<" then
			if difference < cap.Value then
				difference = cap.Value
			end
		end
	end
	
	character:SetAttribute(attribute, difference)
end

function attributes_module:TempAdd(character, attribute, value, duration)
	if character:IsA("Player") then
		character = character.Character
	end
	
	attributes_module:Add(character, attribute, value)
	
	task.delay(duration, function()
		attributes_module:Sub(character, attribute, value)
	end)
end

function attributes_module:Sub(character, attribute, subtraction)
	if character:IsA("Player") then
		character = character.Character
	end

	local value = character:GetAttribute(attribute)
	if value == nil then
		return
	end

	character:SetAttribute(attribute, value - subtraction)
end

function attributes_module:Mult(character, attribute, multiplication, cap)
	if character:IsA("Player") then
		character = character.Character
	end

	local value = character:GetAttribute(attribute)
	if value == nil then
		return
	end
	
	local difference = value * multiplication
	
	if cap then
		if cap.Size == ">" then
			if difference > cap.Value then
				difference = cap.Value
			end
		elseif cap.Size == "<" then
			if difference < cap.Value then
				difference = cap.Value
			end
		end
	end

	character:SetAttribute(attribute, difference)
end

function attributes_module:Get(character, attribute)
	if character:IsA("Player") then
		character = character.Character
	end
	
	return character:GetAttribute(attribute) or nil
end

return attributes_module


-- ==== [ ReplicatedStorage.Modules.Util.Animation ] ==== --
local runservice = game:GetService("RunService")
local keyframesequenceprovider = game:GetService("KeyframeSequenceProvider")

local players = game:GetService("Players")
local localplayer = players.LocalPlayer

local replicatedstorage = game:GetService("ReplicatedStorage")
local modules = replicatedstorage:WaitForChild("Modules")
local assets = replicatedstorage:WaitForChild("Assets")
local animations = assets:WaitForChild("Animations")
animations = animations:GetDescendants()

local get_animation = function(name)
	for index, value in pairs(animations) do
		if value.Name == name then
			return value
		end
	end
end

local get_markers = function(animation: Animation)
	local markers = {}
	local sequence = keyframesequenceprovider:GetKeyframeSequenceAsync(animation.AnimationId)

	local function collect(children)
		for _, child in pairs(children) do
			if child.Name ~= "Keyframe" and child.Name ~= "HumanoidRootPart" and child.Name ~= "Torso" then --if child:IsA("KeyframeMarker") then
				table.insert(markers, child)
			end
			if #children > 1 then
				collect(child:GetChildren())
			end
		end

		table.clear(children)
	end

	collect(sequence:GetChildren())
	collect = nil
	
	return markers
end

local request_module
local animation_module = {
	marker_callbacks = {},
	loaded_animations = {},
	animation_times = {},
	animation_event_times = {},
}

animation_module.Initialize = function()
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		request_module:Register({
			Name = "Play Animation",
			Callback = function(player, actor, animation_name, speed, weight, looped, priority)
				local animation = animation_module.new(actor, animation_name)
				animation:Play()
				animation.Looped = looped or false
				animation.Priority = priority or Enum.AnimationPriority.Action
				animation:AdjustSpeed(speed or 1)
				animation:AdjustWeight(weight or 1)
			end,
		})
		
		request_module:Register({
			Name = "Stop Animation",
			Callback = function(player, actor, animation_name)
				local animation = animation_module:GetSpecificAnimation(actor, animation_name)
				if animation then
					animation:Stop()
				end
			end,
		})
	end
	
	local rig = assets["Invisible R6"]:Clone()
	rig.Parent = workspace.Ignore
	
	for index, animation in pairs(animations) do
		if animation.Name == "Blocking" then continue end
		
		local loaded = rig.Humanoid.Animator:LoadAnimation(animation)
		loaded:Play()
		loaded.Looped = false
		loaded:AdjustSpeed(99999)
		loaded.Stopped:Wait()

		local markers = get_markers(animation)
		if #markers > 0 then
			for index, value in pairs(markers) do
				loaded:GetMarkerReachedSignal(value.Name):Once(function(peram)
					animation_module.animation_event_times[animation.Name] = animation_module.animation_event_times[animation.Name] or {}
					animation_module.animation_event_times[animation.Name][value.Name] = {loaded.Length, peram}
				end)
			end

			loaded:Play()
			loaded:AdjustSpeed(99999)
			loaded.Stopped:Wait()
		end

		animation_module.animation_times[animation.Name] = loaded.Length
	end
	rig:Destroy()
	
	if runservice:IsClient() then
		while replicatedstorage:FindFirstChild("AnimationsLoaded")  do
			replicatedstorage.AnimationsLoaded:Fire()
			
			runservice.Heartbeat:Wait()
		end
	end
	warn("Animations Preloaded.")
end

function animation_module:GetLength(animation_name)
	if not animation_module.animation_times[animation_name] then
		warn("Animations are not preloaded yet.")
		return 0
	end
	
	local animation = animation_module.animation_times[animation_name]
	if animation then
		return animation
	end
end

function animation_module:GetEventLength(animation_name, event_name, offset)
	if not animation_module.animation_event_times[animation_name] then
		warn("Animations are not preloaded yet.")
		return 0
	end

	local animation = animation_module.animation_event_times[animation_name][event_name]
	if animation then
		return animation[1] - (offset or 0), animation[2]
	end
end

animation_module.new = function(character, animation_name)
	local animation: Animation = get_animation(animation_name)
	if not animation then
		return warn(animation_name, "doesnt exist.")
	end
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return warn(character, "doesnt have a Humanoid.")
	end
	
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return warn(character, "doesnt have a Animator.")
	end
	
	animation_module.loaded_animations[character] = animation_module.loaded_animations[character] or {}
	
	local animationtrack: AnimationTrack = animation_module.loaded_animations[character][animation] or animator:LoadAnimation(animation)
	animation_module.loaded_animations[character][animation] = animationtrack
	
	animationtrack.Stopped:Once(function()
		animationtrack:Destroy()
	end)
	
	local markers = get_markers(animation)
	for index, marker in pairs(markers) do
		local callback = animation_module.marker_callbacks[marker.Name]
		if callback then
			animationtrack:GetMarkerReachedSignal(marker.Name):Once(function(...)
				callback(character, ...)
			end)
		end
	end
	
	--[[
	animationtrack.KeyframeReached:Connect(function(name)
		local callback = animation_module.marker_callbacks[name]
		if callback then
			callback()
		end
	end)
	]]--
	
	return animationtrack
end

function animation_module:StopAll(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local current_animations = humanoid.Animator:GetPlayingAnimationTracks()
	
	for index, value in pairs(current_animations) do
		if value.Priority ~= Enum.AnimationPriority.Core then
			value:Stop()
		end
	end
	
	table.clear(current_animations)
	current_animations = nil
end

function animation_module:GetSpecificAnimation(character, pattern)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local current_animations = humanoid:GetPlayingAnimationTracks()
	
	for index, value in pairs(current_animations) do
		if string.find(value.Name, pattern) then
			return value
		end
	end
end

function animation_module:RegisterMarker(info)
	local name = info.Name
	local callback = info.Callback
	
	if animation_module.marker_callbacks[name] then
		return warn(name, "is already a registered callback.")
	end
	
	animation_module.marker_callbacks[name] = callback
end

return animation_module

-- ==== [ ReplicatedStorage.Modules.Util.3DVFX ] ==== --
local runservice = game:GetService("RunService")
local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")
local replicatedstorage = game:GetService("ReplicatedStorage")

local tweeninfo_quad_03 = TweenInfo.new(0.3, Enum.EasingStyle.Quad)

local assets = replicatedstorage:WaitForChild("Assets")
local vfx_assets = assets:WaitForChild("VFX")

local request_module
local vfx_module = {}

vfx_module.Initialize = function()
	request_module = shared.Get("Request")
	
	if runservice:IsClient() then
		
	end
end

function vfx_module:FollowingRockTrail(info)
	local object = info.Object
	local setorientation = info.SetOrientation or Vector3.new(0, 0, 0)
	local duration = info.Duratoion or nil
	local radius = info.Radius or 0
	local size = info.Size or 2
	local raycastlength = info.RaycastLength or 4
	
	if not object then
		return
	end
	
	local leftray_part = assets.Part:Clone()
	leftray_part.CanCollide = false
	leftray_part.Massless = true
	leftray_part.Transparency = 1
	leftray_part.Parent = object
	
	local rightray_part = assets.Part:Clone()
	rightray_part.CanCollide = false
	rightray_part.Massless = true
	rightray_part.Transparency = 1
	rightray_part.Parent = object
	
	task.spawn(function()
		local start_time = os.time()
		
		local folder = Instance.new("Folder")
		folder.Name = "FollowingRocksTrail"
		folder.Parent = workspace.Ignore
		
		local destroy_folder = function()
			task.wait(1)
			
			for index, value in pairs(folder:GetChildren()) do
				local tween = tweenservice:Create(value, tweeninfo_quad_03, {Position = value.Position - Vector3.new(0, 3, 0), Transparency = 1})
				tween:Play()

				task.wait()
			end
			
			debris:AddItem(folder, 0.3)
		end
		
		local func
		func = runservice.Heartbeat:Connect(function()
			leftray_part.Position = object.Position
			leftray_part.Orientation = setorientation
			leftray_part.CFrame *= CFrame.new(-radius, 0, -2)
			rightray_part.Position = object.Position
			rightray_part.Orientation = setorientation
			rightray_part.CFrame *= CFrame.new(radius, 0, -2)

			local raycast_perams = RaycastParams.new()
			raycast_perams.FilterType = Enum.RaycastFilterType.Exclude
			raycast_perams.FilterDescendantsInstances = workspace.Live:GetDescendants()
			local left_ray = workspace:Raycast(leftray_part.Position, leftray_part.CFrame.UpVector * -raycastlength)
			local right_ray = workspace:Raycast(rightray_part.Position, rightray_part.CFrame.UpVector * -raycastlength)

			if left_ray then
				local rock = assets.Part:Clone()
				rock.Position = left_ray.Position - Vector3.new(0, 3, 0)
				rock.Orientation = setorientation
				rock.CFrame *= CFrame.Angles(0, math.rad(math.random(-20, 120)), math.rad(45))
				rock.Size = Vector3.new(size/3, size/3, size/3)
				rock.Color = left_ray.Instance.Color
				rock.Material = left_ray.Instance.Material
				rock.Anchored = true
				rock.CanCollide = false
				rock.Parent = folder

				tweenservice:Create(rock, tweeninfo_quad_03, {
					Size = Vector3.new(size, size, size),
					Position = left_ray.Position,
					--CFrame = rock.CFrame * CFrame.Angles(0, math.rad(math.random(-20, 120)), math.rad(45))
				}):Play()
			end
			
			if right_ray then
				local rock = assets.Part:Clone()
				rock.Position = right_ray.Position - Vector3.new(0, 3, 0)
				rock.Orientation = setorientation
				rock.CFrame *= CFrame.Angles(0, math.rad(math.random(-20, 120)), math.rad(-45))
				rock.Size = Vector3.new(size/3, size/3, size/3)
				rock.Color = right_ray.Instance.Color
				rock.Material = right_ray.Instance.Material
				rock.Anchored = true
				rock.CanCollide = false
				rock.Parent = folder

				tweenservice:Create(rock, tweeninfo_quad_03, {
					Size = Vector3.new(size, size, size),
					Position = right_ray.Position,
					--CFrame = rock.CFrame * CFrame.Angles(0, math.rad(math.random(-20, 120)), math.rad(45))
				}):Play()
			end

			if duration then
				if os.time() - start_time >= duration then
					func:Disconnect()
					
					leftray_part:Destroy()
					rightray_part:Destroy()
					
					destroy_folder()
				end
			end
			
			if not object.Parent then
				func:Disconnect()
				
				leftray_part:Destroy()
				rightray_part:Destroy()
				
				destroy_folder()
			end
		end)
		
		--leftray_part:Destroy()
		--rightray_part:Destroy()
	end)
	
end

return vfx_module
