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

local Animations = require(ReplicatedStorage.Shared.Config.Animations)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local Poses = require(ReplicatedStorage.Shared.Config.Poses)

local PoseController = {}

-- Articulación → parte R15 que la contiene
local JOINTS = {
	Root = "LowerTorso", -- todo el cuerpo (inclinarse, volteretas)
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	RightWrist = "RightHand",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	LeftWrist = "LeftHand",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
	Waist = "UpperTorso",
	Neck = "Head",
}

local EMPTY = {}
-- Articulación = Motor6D (rig clásico) o AnimationConstraint (sistema nuevo de
-- articulaciones de Roblox). Las dos tienen la propiedad Transform.
local motorCache: { [Model]: { [string]: any } } = {}
local runPhase: { [Model]: number } = {}
local overridden: { [Model]: boolean } = {} -- true si este frame le pusimos pose

local function isJoint(instance: Instance?): boolean
	return instance ~= nil and (instance:IsA("Motor6D") or instance:IsA("AnimationConstraint"))
end

local function getMotors(model: Model): { [string]: any }
	local cached = motorCache[model]
	if cached then
		local anyMotor = next(cached)
		-- Si el cuerpo se rehízo (ApplyDescription) o aún no había cargado, se vuelve a buscar.
		if anyMotor ~= nil and (cached[anyMotor] :: Instance):IsDescendantOf(model) then
			return cached
		end
	end
	local motors = {}
	for jointName, partName in JOINTS do
		local part = model:FindFirstChild(partName)
		-- Puede haber varios hijos con el mismo nombre en otras partes: se busca el que sea articulación.
		if part then
			for _, child in part:GetChildren() do
				if child.Name == jointName and isJoint(child) then
					motors[jointName] = child
					break
				end
			end
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
	local weapon = model:GetAttribute("Weapon")
	local moveset = FighterStats.Moveset(weapon, model:GetAttribute("FighterId"))
	local data = moveset and moveName and moveset[moveName]
	-- Pose propia del arma si existe (Poses.Weapons), si no la general (Poses.Moves).
	local weaponPoses = Poses.Weapons[weapon]
	local pose = moveName and ((weaponPoses and weaponPoses[moveName]) or Poses.Moves[moveName])
	if not data or not pose or type(moveTime) ~= "number" then
		return nil
	end

	local now = workspace:GetServerTimeNow()
	local t = now - moveTime

	-- Ataques con GANCHO y poses clave (guadaña): preparar → estirar → enganchar →
	-- tirar → lanzar. El instante del enganche lo marca el servidor (atributo HookAt).
	if pose.hookUp and data.hook then
		if t < data.startup then
			return lerpPose(EMPTY, pose.windup, easeOut(math.clamp(t / data.startup, 0, 1)))
		end
		local hookAt = model:GetAttribute("HookAt")
		if type(hookAt) == "number" and hookAt >= moveTime then
			local h = now - hookAt
			local pull, hold = data.hook.pullTime, data.hook.holdTime
			if h < pull * 0.45 then
				return lerpPose(pose.strike, pose.hookUp, easeOut(math.clamp(h / (pull * 0.45), 0, 1)))
			elseif h < pull then
				return lerpPose(pose.hookUp, pose.pull, easeOut(math.clamp((h - pull * 0.45) / (pull * 0.55), 0, 1)))
			elseif h < pull + hold then
				return pose.pull
			elseif h < pull + hold + 0.07 then
				return lerpPose(pose.pull, pose.throw, easeOut(math.clamp((h - pull - hold) / 0.07, 0, 1)))
			end
			local after = h - pull - hold - 0.07
			return lerpPose(pose.throw, EMPTY, math.clamp(after / math.max(data.recovery * 0.6, 0.05), 0, 1))
		end
		-- Sin enganche (todavía o falló): estira la guadaña y vuelve.
		if t < data.startup + data.active then
			return lerpPose(pose.windup, pose.strike, math.clamp((t - data.startup) / 0.05, 0, 1))
		end
		local a = math.clamp((t - data.startup - data.active) / math.max(data.recovery, 0.01), 0, 1)
		return lerpPose(pose.strike, EMPTY, a)
	end

	if t < data.startup then
		return lerpPose(EMPTY, pose.windup, easeOut(math.clamp(t / data.startup, 0, 1)))
	elseif t < data.startup + data.active then
		-- Golpe: llega a la pose en 0.04 s (rápido pero visible)
		local a = math.clamp((t - data.startup) / 0.04, 0, 1)
		local result = lerpPose(pose.windup, pose.strike, a)
		if pose.spin then
			-- Giro de todo el cuerpo repartido durante el active (voltereta, barrido)
			local progress = math.clamp((t - data.startup) / math.max(data.active, 0.01), 0, 1)
			result.Root = (result.Root or Vector3.zero) + pose.spin * progress
		end
		return result
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

-- ¿Hay animación REAL para este ataque? (entonces la pose por código no se usa)
local function hasAttackAnimation(model: Model): boolean
	local move = model:GetAttribute("Move")
	local weapon = model:GetAttribute("Weapon")
	-- Poses diseñadas a mano a partir de los vídeos (codePose) mandan sobre la animación.
	if Poses.CodePosesForAllAttacks then
		return false
	end
	local weaponPoses = weapon and Poses.Weapons[weapon]
	if move and weaponPoses and weaponPoses[move] and weaponPoses[move].codePose then
		return false
	end
	local byWeapon = weapon and Animations.Weapons[weapon]
	return move ~= nil and ((byWeapon and byWeapon[move]) or Animations.Generic[move]) ~= nil
end

local function updateModel(model: Model, _isCpu: boolean, dt: number)
	local state = model:GetAttribute("State")
	local pose = nil
	-- Respaldo: las poses solo se usan si no hay animación real (Animations.luau).
	if state == "Attacking" then
		if not hasAttackAnimation(model) then
			pose = attackPose(model)
		end
	elseif state == "Hitstun" then
		if not Animations.States.Hurt then
			pose = Poses.States.Hitstun
		end
	elseif state == "Dodging" then
		if not Animations.States.Dodge then
			pose = Poses.States.Dodging
		end
	else
		-- En el aire (saltando / cayendo) no hay animación: postura aérea por código.
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and math.abs(root.AssemblyLinearVelocity.Y) > 4 then
			pose = Poses.Locomotion.Air
		elseif not Animations.States.Idle then
			pose = locomotionPose(model, dt)
		end
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
