
-- ==== [ Workspace.Live.Blocking Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Blocking Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")
local block_module = shared.Get("Block")

attributes_module:Configure(character)
block_module:StartBlocking(character)

while true do
	attributes_module:Set(character, "Parry", false)
	--attributes_module:Set(character, "Posture", 5)

	task.wait()
end

-- ==== [ Workspace.Live.Blocking Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")

attributes_module:Configure(character)

-- ==== [ Workspace.Live.Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.High HP Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.High HP Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")

attributes_module:Configure(character)

-- ==== [ Workspace.Live.High HP Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.Low HP Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Low HP Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")

attributes_module:Configure(character)

-- ==== [ Workspace.Live.Low HP Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.Moving Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Moving Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")

attributes_module:Configure(character)

character.Humanoid.WalkSpeed = 30

local c = 1
while true do
	local p = workspace.Ignore.MovementPoints:FindFirstChild(c)
	if p then
		character.Humanoid.WalkToPoint = p.Position
	end

	c += 1
	if c > 5 then
		c = 1
	end

	task.wait(1)
end

-- ==== [ Workspace.Live.Moving Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.Parry Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Parry Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")
local block_module = shared.Get("Block")

attributes_module:Configure(character)
block_module:StartBlocking(character)

while true do
	attributes_module:Set(character, "Parry", true)
	
	task.wait()
end

-- ==== [ Workspace.Live.Parry Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ Workspace.Live.Swinging Dummy.DamageHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid: Humanoid = character:WaitForChild("Humanoid")

local animation_module = shared.Get("Animation")

local previoushealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < previoushealth then
		animation_module:StopAll(character)
	end
	previoushealth = health
end)

-- ==== [ Workspace.Live.Swinging Dummy.Handler ] ==== --
task.wait(1.5)
local character = script.Parent
print(character, "Init")

local attributes_module = shared.Get("Attributes")
local equipweaopon_module = shared.Get("EquipWeapon")
local swing_module = shared.Get("Swing")

attributes_module:Configure(character)

equipweaopon_module:Equip(character)

task.wait(1)
swing_module:StartSwinging(character)

-- ==== [ Workspace.Live.Swinging Dummy.StunHandler ] ==== --
task.wait(0.5)

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

character:GetAttributeChangedSignal("Stuns"):Connect(function()
	local stuns = character:GetAttribute("Stuns")
	if stuns > 0 then
		humanoid.WalkSpeed = 2
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
	end
end)

-- ==== [ ReplicatedStorage.Documentation ] ==== --
--[[

Documentation on How to Use my Modules
by 012/pleb

//// How the modules are Required/Initialized

: System :
- In ReplicatedStorage there is a module called System
- This is what the Init scripts use to require and initialize the modules
- It also adds function to the global "shared" table called "Get"

Example: shared.Get(Module Name)
- This will return the module so you dont need to require() everytime you need one

: Server :
- In ServerScriptService (ServerScriptService>Scripts>Init>Server)
- This script uses the "System" module located in ReplicatedStorage
- It required all the modules in ServerScriptService(Server) and Replicatedstorage(Shared)
- After it requires the modules, it initializes them

: Client :
- In ReplicatedFirst (ReplicatedFirst>Scripts>Init>Server)
- This script uses the "System" module located in ReplicatedStorage
- It required all the modules in StarterPlayerScripts(Client) and Replicatedstorage(Shared)
- After it requires the modules, it initializes them

//// How I handle DataSave
I use "ProfileStore", an open source module

- In ServerScriptService (ServerScriptService>Scripts>Init>Profile) is where I handle everything
- The only thing you will need to do is use the "Profile" module I made

//// Profile Module
(ReplicatedStorage>Modules>Core>Profile)

//// Request Module
(ReplicatedStorage>Modules>Util>Request)

Description: The "Request" module is where I handle all my remotes

- To create an event for when you fire a remote its very simple
Example: Request_Module:Register({
			Name = "Callback Name",
			Callback = function(player, ...)
				
			end
         })
- Whatever you want to happen would be written inside the "Callback" function

- To fire a remote is just as simple
Example: Request_Module:Send({
			Name = "Callback Name", -- The name of the callback that you previously registered
			Class = "Unreliable", -- The class of the remote (Event, Unreliable, Function) (Function is not coded ngl)
			All = true, -- This is optional, only needed if your firing from the server to fire to all clients
			Perameters = {player} -- You only need to put the player in if your firing from the Server and All is false, otherwise just put whatever
		})

//// Attributes Module
(ReplicatedStorage>Modules>Util>Attributes)

Description: The "Attributes" module is where I handle all my character attributes INCLUDING the characters state

HOW TO USE "CAP"
when you see cap in these examples its completly optional
but it will cap whatever you add/sub/mult so it cant go over or under the number given

Example: Attributes_Module:Add(Character, "Health", 20000, {Size = ">", Value = 100})
The size will either equal ">" or "<"
this will determine if you want the cap to be smaller or bigger (mainly a problem for multiplying)

- To set the attributes value to something
Attributes_Module:Set(Character, Attribute, Value)

- To set the attributes value to something for a certain amount of time
Attributes_Module:TempSet(Character, Attribute, Value, Duration)

- To add to the attributes value to something
Attributes_Module:Add(Character, Attribute, Value, Cap)

- To add to the attributes value to something for a certain ammount of time
Attributes_Module:TempAdd(Character, Attribute, Value, Duration)

- To sub from the attributes value to something
Attributes_Module:Sub(Character, Attribute, Value)

- To multiply the attributes value to something
Attributes_Module:Mult(Character, Attribute, Value, Cap)

- To get the attributes value
Attributes_Module:Get(Character, Attribute)

//// Tasks Module
(ReplicatedStorage>Modules>Util>Tasks)

//// Animation Module
(ReplicatedStorage>Modules>Util>Animation)

Description: The "Animation" module is where I handle all my animations
Now you lowkey dont need to use this since to play an animation you will use the request module

Example: Request_Module:Send({
			Name = "Play Animation", -- The name of the callback
			Class = "Unreliable", -- Unreliable because we want to fire an UnreliableRemoteEvent
			All = true, -- We want to fire to all clients so everyone will see
			Perameters = {character, AnimationName, AnimationSpeed, AnimationWeight, AnimationLooped, AnimationPriority} -- Everything after AnimationName is optional
		})
		
- How to get the length of an animation
local AnimationLength = Animation_Module:GetLength(AnimationName)

- How to get the length of an animation event, Peram will equal the given info from the event (its not necessary)
local AnimationEventLength, Peram = Animation_Module:GetEventLength(AnimationName, EventName)

//// Force Module
(ReplicatedStorage>Modules>Util>Force)

//// Hitbox Module
(ReplicatedStorage>Modules>Util>Hitbox)

Description: The "Hitbox" module is where I handle all my hitboxes

local Hitbox = Hitbox_Module:SpawnBox({
				CFrame = CFrame, -- Set to a CFrame value of the cframe of the hitbox
				Size = Vector3, -- Set to a Vector3.new() of the size
				Filter = {}, -- Fill the table with every character you want exluded from the hitbox
				Visible = bool, -- Set to true or false if you want the hitbox to be visible
			})
			
local Hitbox = Hitbox_Module:SpawnMagnitude({
				Position = Vector3, -- Set to a Vector3.new() of the position
				Radius = number, -- Set to a number of the radius of the hitbox
				Filter = {}, -- Fill the table with every character you want exluded from the hitbox
				Visible = bool, -- Set to true or false if you want the hitbox to be visible
			})
			
- These functions will return a table filled with every character hit by the hitbox

//// VFX Module
(ReplicatedStorage>Modules>Util>VFX)

Description: The "VFX" module is where I handle all my visual effects
lowkey only thing i got in here rn is particle emitting, but just like the animation module you just need to do this

Example: Request_Module:Send({
			Name = "Emit VFX", -- The name of the callback
			Class = "Unreliable", -- Unreliable because we want to fire an UnreliableRemoteEvent
			All = true, -- We want to fire to all clients so everyone will see
			Perameters = {character, VFXName}
		})

//// SFX Module
(ReplicatedStorage>Modules>Util>SFX)

]]--

-- ==== [ ServerScriptService.Scripts.Cmdr.Init ] ==== --
local serverscriptservice = game:GetService("ServerScriptService")
local modules = serverscriptservice:WaitForChild("Modules")
local cmdr = require(modules:WaitForChild("Cmdr"))

local commands = script.Parent:WaitForChild("Commands")
local hooks = script.Parent:WaitForChild("Hooks")
local types = script.Parent:WaitForChild("Types")

cmdr:RegisterDefaultCommands()

cmdr:RegisterCommandsIn(commands)
cmdr:RegisterHooksIn(hooks)
cmdr:RegisterTypesIn(types)

-- ==== [ ServerScriptService.Scripts.Init.CarryScript ] ==== --
local players = game:GetService("Players")
local carry_remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CarryPlayer")
local attributes_module = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Util"):WaitForChild("Attributes"))

local set_massless = function(character, bool)
	for index, value: BasePart in pairs(character:GetDescendants()) do
		if value:IsA("BasePart") then
			value.Massless = bool
		end
	end
end

local get_carrying = function(character)
	for index, value in pairs(workspace.Live:GetChildren()) do
		local victim_state = value:GetAttribute("State")
		if victim_state == "Knocked" then
			local carry_weld = value:FindFirstChild("Carry Weld")
			if carry_weld and carry_weld.Part0.Parent == character then
				return value
			end
		end
	end
end


carry_remote.OnServerEvent:Connect(function(plr, char, victim_char, knocked)
	print("Okay")
	if knocked and char ~= nil then 
		
		--local carryer_state = attributes_module:Get(carryer, "State")
		--local victim_state = attributes_module:Get(victim, "State")

		--if not table.find({"Idle", "Sprinting"}, carryer_state) or victim_state ~= "Knocked" then
		--	return
		--end

		local carryer_humanoidrootpart = char:FindFirstChild("HumanoidRootPart")
		local victim_humanoidrootpart = victim_char:FindFirstChild("HumanoidRootPart")
		local victim_humanoid = victim_char:FindFirstChild("Humanoid")

		if not carryer_humanoidrootpart or not victim_humanoidrootpart or not victim_humanoid then
			return
		end

		victim_humanoid.PlatformStand = true
		victim_humanoid.AutoRotate = false
		set_massless(victim_char, true)

		local carry_weld = Instance.new("Weld")
		carry_weld.Name = "Carry Weld"
		carry_weld.Part0 = carryer_humanoidrootpart
		carry_weld.Part1 = victim_humanoidrootpart
		carry_weld.C0 = CFrame.new(2, 1.5, 0) * CFrame.Angles(0, 0, 0)
		carry_weld.Parent = victim_char


		--victim_humanoidrootpart.Position += Vector3.new(0.5, 1.2, -1.35) <<make it so the victim char rests on the player shoulder
	elseif char == nil then --working on uncarry
		
		print("RUN")

		local victim = victim_char
		print(victim)
		if not victim then
			return
		end

		local victim_humanoid = victim:FindFirstChild("Humanoid")
		if not victim_humanoid then
			return
		end

		victim_humanoid.PlatformStand = false
		victim_humanoid.AutoRotate = true
		set_massless(victim, false)

		local carry_weld = victim:FindFirstChild("Carry Weld")
		if carry_weld then
			carry_weld:Destroy()

			attributes_module:Set(char, "State", "Idle")
		end

		--]]
	end
end)

-- ==== [ ServerScriptService.Scripts.Init.CharacterCollisions ] ==== --
local players = game:GetService("Players")

local assign_collision = function(character)
	for index, value in pairs(character:GetChildren()) do
		if value:IsA("BasePart") then
			value.CollisionGroup = "Character"
		end
	end
end

players.PlayerAdded:Connect(function(player)
	local character = player.CharacterAdded:Wait()
	assign_collision(character)
	player.CharacterAdded:Connect(assign_collision)
end)

-- ==== [ ServerScriptService.Scripts.Init.Profile ] ==== --
local runservice = game:GetService("RunService")

local players = game:GetService("Players")

local replicatedstorage = game:GetService("ReplicatedStorage")
local shared_modules = replicatedstorage:WaitForChild("Modules")
local profile_module = require(shared_modules.Core:WaitForChild("Profile"))

local serverscriptservice = game:GetService("ServerScriptService")
local modules = serverscriptservice:WaitForChild("Modules")
local profilestore = require(modules:WaitForChild("ProfileStore"))

local getstorename = function()
	return runservice:IsStudio() and "Test" or "Live"
end

local template = {
	["Weapon"] = "Fists",
	["Skills"] = {
		[1] = "Test1",
		[2] = "Test2",
		[3] = "Test3",
		[4] = "",
		[5] = "",
		[6] = "",
		[7] = "",
		[8] = "",
		[9] = "",
		[0] = "",
	}
}

local playerstore = profilestore.New(getstorename(), template)
local profiles = {}

local player_added = function(player)
	local profile = playerstore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= players
		end,
	})
	
	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		
		profile.OnSessionEnd:Connect(function()
			profile_module:RemoveProfile(player)
			player:Kick("Data error occured, please rejoin.")
		end)
		
		if player.Parent == players then
			profile_module:AddProfile(player, profile)
		else
			profile:EndSession()
		end
		
		profiles[player] = profile
	else
		player:Kick("Data error occured, please rejoin.")
	end
end

for index, value in pairs(players:GetPlayers()) do
	task.spawn(player_added, value)
end

players.PlayerAdded:Connect(player_added)
players.PlayerRemoving:Connect(function(player)
	profile_module:RemoveProfile(player)
	
	local profile = profiles[player]
	if profile then
		profile:EndSession()
		profiles[player] = nil
		
	end
end)



-- ==== [ ServerScriptService.Scripts.Init.Server ] ==== --
local serverscriptservice = game:GetService("ServerScriptService")
local server_modules = serverscriptservice:WaitForChild("Modules")

local replicatedstorage = game:GetService("ReplicatedStorage")
local shared_modules = replicatedstorage:WaitForChild("Modules")
local system = require(replicatedstorage:WaitForChild("System"))

system:Load(server_modules:GetChildren(), {}, {"Cmdr"})
system:Load(shared_modules:GetChildren())
system:Initialize()

-- ==== [ StarterGui.RemoteWatcher.server ] ==== --
local remotes = game:GetDescendants()

local alert = script:WaitForChild("Alert")

local list = script.Parent:WaitForChild("List")
local slist = list:WaitForChild("Server")

local add_alert = function(text)
	local new = alert:Clone()
	new.Text = text
	new.Parent = slist
	game.Debris:AddItem(new, 0.035)
end

for index, value in pairs(remotes) do
	if value:IsA("RemoteEvent") or value:IsA("UnreliableRemoteEvent") then
		value.OnServerEvent:Connect(function(player)
			player = tostring(player)
			add_alert("FireServer() : "..player.." : "..value.Name)
		end)
	elseif value:IsA("RemoteFunction") then
		value.OnServerInvoke = function(player)
			player = tostring(player)
			add_alert("InvokeServer() : "..player.." : "..value.Name)
		end
	end
end

game.DescendantAdded:Connect(function(value)
	if value:IsA("RemoteEvent") or value:IsA("UnreliableRemoteEvent") then
		value.OnServerEvent:Connect(function(player)
			player = tostring(player)
			add_alert("FireServer() : "..player.." : "..value.Name)
		end)
	elseif value:IsA("RemoteFunction") then
		value.OnServerInvoke = function(player)
			player = tostring(player)
			add_alert("InvokeServer() : "..player.." : "..value.Name)
		end
	end
end)

-- ==== [ StarterPlayer.StarterCharacterScripts.Scripts.ClientToServerCFrame.Server ] ==== --
local remote = script.Parent:WaitForChild("Sync")

remote.OnServerEvent:Connect(function(player, position)
	local character = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute("CFrame", position)
end)

-- ==== [ StarterPlayer.StarterCharacterScripts.Scripts.SmoothMovement.Lerp ] ==== --
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--local LocalPlayer = game.Players.LocalPlayer
--local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Character = script.Parent.Parent.Parent

local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Torso = Character:WaitForChild("Torso")

local RootJoint = HumanoidRootPart:WaitForChild("RootJoint")
local Neck = Torso:WaitForChild("Neck")
local RightShoulder = Torso:WaitForChild("Right Shoulder")
local LeftShoulder = Torso:WaitForChild("Left Shoulder")
local RightHip = Torso:WaitForChild("Right Hip")
local LeftHip = Torso:WaitForChild("Left Hip")

local RootJointC0 = RootJoint.C0
local NeckC0 = Neck.C0
local RightShoulderC0 = RightShoulder.C0
local LeftShoulderC0 = LeftShoulder.C0
local RightHipC0 = RightHip.C0
local LeftHipC0 = LeftHip.C0

local RootJointTilt = CFrame.new()
local NeckTilt = CFrame.new()
local RightShoulderTilt = CFrame.new()
local LeftShoulderTilt = CFrame.new()
local RightHipTilt = CFrame.new()
local LeftHipTilt = CFrame.new()

local DefaultLerpAlpha = 0.1 -- Lerping Speed
local dotThreshold = 0.95 -- dotThreshold (Do not edit)
local lastTime = 0 -- Last Time (Do not edit)
local tickRate = 1 / 60 -- 60 fps limit

local function UpdateDirectionalMovement(DeltaTime)
	local Now = workspace:GetServerTimeNow() -- os.clock Instead? Idrk

	if Now - lastTime >= tickRate then
		lastTime = Now

		local MoveDirection = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)

		if MoveDirection:Dot(Vector3.new(1,0,-1).Unit) > dotThreshold then
			--print("Forwards-Right")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 5, 0, math.rad(-MoveDirection.X) * 15), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 5, 0, math.rad(MoveDirection.X) * 15), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(1,0,1).Unit) > dotThreshold then
			--print("Backwards-Right")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 5, 0, math.rad(MoveDirection.X) * 15), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 5, 0, math.rad(-MoveDirection.X) * 15), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(-1,0,1).Unit) > dotThreshold then
			--print("Backwards-Left")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 5, 0, math.rad(MoveDirection.X) * 15), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 5, 0, math.rad(-MoveDirection.X) * 15), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(-1,0,-1).Unit) > dotThreshold then
			--print("Forwards-Left")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 5, 0, math.rad(-MoveDirection.X) * 15), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 5, 0, math.rad(MoveDirection.X) * 15), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 10, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(0,0,-1).Unit) > dotThreshold then
			--print("Forwards")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 0, 0, 0), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 0, 0, 0), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(1,0,0).Unit) > dotThreshold then
			--print("Right")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(0, 0, math.rad(-MoveDirection.X) * 35), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(0, 0, math.rad(MoveDirection.X) * 35), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 15, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 15, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 30, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(0,0,1).Unit) > dotThreshold then
			--print("Backwards")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(math.rad(-MoveDirection.Z) * 15, 0, 0), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(math.rad(MoveDirection.Z) * 15, 0, 0), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection:Dot(Vector3.new(-1,0,0).Unit) > dotThreshold then
			--print("Left")
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(0, 0, math.rad(-MoveDirection.X) * 35), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(0, 0, math.rad(MoveDirection.X) * 35), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 15, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, math.rad(MoveDirection.X) * 15, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 30, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, math.rad(-MoveDirection.X) * 35, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		elseif MoveDirection == Vector3.new(0, 0, 0) or script:GetAttribute("Toggle") == false then
			RootJointTilt = RootJointTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RootJoint.C0 = RootJointC0 * RootJointTilt

			NeckTilt = NeckTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			Neck.C0 = NeckC0 * NeckTilt

			RightShoulderTilt = RightShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightShoulder.C0 = RightShoulderC0 * RightShoulderTilt

			LeftShoulderTilt = LeftShoulderTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftShoulder.C0 = LeftShoulderC0 * LeftShoulderTilt

			RightHipTilt = RightHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			RightHip.C0 = RightHipC0 * RightHipTilt

			LeftHipTilt = LeftHipTilt:Lerp(CFrame.Angles(0, 0, 0), DefaultLerpAlpha)
			LeftHip.C0 = LeftHipC0 * LeftHipTilt
		end
	end
end

RunService.Heartbeat:Connect(UpdateDirectionalMovement)

-- ==== [ StarterPlayer.StarterCharacterScripts.Health ] ==== --
script:Destroy()

