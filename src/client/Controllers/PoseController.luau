-- StarterPlayer.StarterPlayerScripts.Client.Controllers.PoseController
-- "Animaciones por código". Cada cliente dibuja las poses de TODOS los luchadores
-- que ve, leyendo sus atributos (State, Move, MoveTime) que pone el servidor.
-- No necesita animaciones subidas: gira las articulaciones R15 (Motor6D.Transform).
--
--   Atacando  → pose de preparación → golpe → vuelta a neutral (Shared.Config.Poses)
--   Hitstun   → pose de recibir golpe
--   Esquivando→ pose encogida
--   CPU       → además, correr / saltar / quieta (Roblox no anima a los NPC)
-- Los jugadores, fuera de esos estados, usan las animaciones normales de Roblox.
--
-- Se aplica en RunService.Stepped: después de las animaciones de Roblox y antes
-- de la física, así la pose de ataque manda en ese frame.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local Poses = require(ReplicatedStorage.Shared.Config.Poses)

local PoseController = {}

-- Articulación → parte R15 que la contiene
local JOINTS = {
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
	Waist = "UpperTorso",
	Neck = "Head",
}

local EMPTY = {}
local motorCache: { [Model]: { [string]: Motor6D } } = {}
local runPhase: { [Model]: number } = {}
local overridden: { [Model]: boolean } = {} -- true si este frame le pusimos pose

local function getMotors(model: Model): { [string]: Motor6D }
	local cached = motorCache[model]
	if cached then
		local anyMotor = next(cached)
		-- Si el cuerpo se rehízo (ApplyDescription) o aún no había cargado, se vuelve a buscar.
		if anyMotor ~= nil and (cached[anyMotor] :: Motor6D):IsDescendantOf(model) then
			return cached
		end
	end
	local motors = {}
	for jointName, partName in JOINTS do
		local part = model:FindFirstChild(partName)
		local motor = part and part:FindFirstChild(jointName)
		if motor and motor:IsA("Motor6D") then
			motors[jointName] = motor
		end
	end
	motorCache[model] = motors
	return motors
end

local function easeOut(a: number): number
	return 1 - (1 - a) * (1 - a)
end

local function lerpPose(from, to, alpha: number)
	local result = {}
	for joint in JOINTS do
		local a = from[joint]
		local b = to[joint]
		if a or b then
			result[joint] = (a or Vector3.zero):Lerp(b or Vector3.zero, alpha)
		end
	end
	return result
end

-- Pose de ataque según el tiempo transcurrido, o nil si no hay datos.
local function attackPose(model: Model)
	local moveName = model:GetAttribute("Move")
	local moveTime = model:GetAttribute("MoveTime")
	local moveset = Movesets[model:GetAttribute("FighterId")]
	local data = moveset and moveName and moveset[moveName]
	local pose = moveName and Poses.Moves[moveName]
	if not data or not pose or type(moveTime) ~= "number" then
		return nil
	end

	local t = workspace:GetServerTimeNow() - moveTime
	if t < data.startup then
		return lerpPose(EMPTY, pose.windup, easeOut(math.clamp(t / data.startup, 0, 1)))
	elseif t < data.startup + data.active then
		-- Golpe: llega a la pose en 0.04 s (rápido pero visible)
		local a = math.clamp((t - data.startup) / 0.04, 0, 1)
		return lerpPose(pose.windup, pose.strike, a)
	end
	local a = math.clamp((t - data.startup - data.active) / math.max(data.recovery, 0.01), 0, 1)
	return lerpPose(pose.strike, EMPTY, a)
end

-- Correr / aire / quieto para la CPU.
local function locomotionPose(model: Model, dt: number)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return EMPTY
	end
	local vel = root.AssemblyLinearVelocity
	local loco = Poses.Locomotion
	if math.abs(vel.Y) > 3 then
		return loco.Air
	end
	local speed = math.abs(vel.X)
	if speed > 1 then
		local phase = (runPhase[model] or 0) + dt * speed * loco.RunCycleSpeed * math.pi * 2
		runPhase[model] = phase
		local s = math.sin(phase)
		return {
			RightHip = Vector3.new(loco.RunHipSwing * s, 0, 0),
			LeftHip = Vector3.new(-loco.RunHipSwing * s, 0, 0),
			RightKnee = Vector3.new(-25 - 20 * math.max(0, -s), 0, 0),
			LeftKnee = Vector3.new(-25 - 20 * math.max(0, s), 0, 0),
			RightShoulder = Vector3.new(-loco.RunArmSwing * s, 0, 0),
			LeftShoulder = Vector3.new(loco.RunArmSwing * s, 0, 0),
			Waist = Vector3.new(-8, 0, 0),
		}
	end
	-- Quieta: respiración suave
	local breathe = math.sin(os.clock() * 2) * 3
	return {
		Waist = Vector3.new(breathe, 0, 0),
		RightShoulder = Vector3.new(10, 0, 8),
		LeftShoulder = Vector3.new(5, 0, -8),
	}
end

local function applyPose(model: Model, pose)
	for joint, motor in getMotors(model) do
		local deg = pose[joint]
		if deg then
			motor.Transform = CFrame.Angles(math.rad(deg.X), math.rad(deg.Y), math.rad(deg.Z))
		else
			motor.Transform = CFrame.identity
		end
	end
end

local function updateModel(model: Model, isCpu: boolean, dt: number)
	local state = model:GetAttribute("State")
	local pose = nil
	if state == "Attacking" then
		pose = attackPose(model)
	elseif state == "Hitstun" then
		pose = Poses.States.Hitstun
	elseif state == "Dodging" then
		pose = Poses.States.Dodging
	end
	if not pose and isCpu then
		pose = locomotionPose(model, dt)
	end
	if pose then
		applyPose(model, pose)
		overridden[model] = true
	elseif overridden[model] then
		-- Al salir de la pose, todo a neutral una vez; luego mandan las animaciones de Roblox.
		applyPose(model, EMPTY)
		overridden[model] = nil
	end
end

function PoseController.Start()
	RunService.Stepped:Connect(function(_, dt)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character and character.Parent then
				updateModel(character, false, dt)
			end
		end
		for _, model in CollectionService:GetTagged("CameraTarget") do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				updateModel(model, true, dt)
			end
		end
	end)

	-- Limpieza de cachés cuando un modelo desaparece.
	task.spawn(function()
		while true do
			task.wait(5)
			for model in motorCache do
				if not model.Parent then
					motorCache[model] = nil
					runPhase[model] = nil
					overridden[model] = nil
				end
			end
		end
	end)
end

return PoseController
