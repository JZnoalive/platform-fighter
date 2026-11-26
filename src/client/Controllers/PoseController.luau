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

local function smooth(a: number): number
	return a * a * (3 - 2 * a) -- arranque y frenada suaves (smoothstep)
end

-- Guardia del arma (pose neutral) con respiración/balanceo suave. {} si el arma no tiene.
local function guardPose(weapon: string?)
	local guard = weapon and Poses.Guard and Poses.Guard[weapon]
	if not guard then
		return EMPTY
	end
	local t = os.clock()
	local breathe = math.sin(t * 2.6) -- ~2,4 s por respiración
	local sway = math.sin(t * 1.3)
	local result = table.clone(guard)
	result.Waist = (guard.Waist or Vector3.zero) + Vector3.new(breathe * 2.5, sway * 2, 0)
	result.RightShoulder = (guard.RightShoulder or Vector3.zero) + Vector3.new(breathe * 2, 0, 0)
	result.LeftShoulder = (guard.LeftShoulder or Vector3.zero) + Vector3.new(-breathe * 2, 0, 0)
	result.Neck = (guard.Neck or Vector3.zero) + Vector3.new(-breathe * 1.5, 0, 0)
	return result
end

-- Ataque por FOTOGRAMAS CLAVE (pose.keys): cada clave dice en qué fase está
-- ("startup" / "active" / "recovery") y en qué punto de esa fase (at = 0..1).
-- Fases típicas: anticipación → inicio del avance → extensión → impacto → seguimiento
-- → recuperación → guardia. Entre claves se interpola con arranque y frenada suaves.
local function keyedPose(pose, data, t: number, weapon: string?)
	local starts = { startup = 0, active = data.startup, recovery = data.startup + data.active }
	local lengths = { startup = data.startup, active = data.active, recovery = data.recovery }
	local guard = guardPose(weapon)
	local prevTime, prevPose = 0, guard
	for _, key in pose.keys do
		local keyTime = starts[key.phase] + lengths[key.phase] * key.at
		local keyPose = if key.pose == "guard" then guard else key.pose
		if t <= keyTime then
			local span = math.max(keyTime - prevTime, 1e-3)
			return lerpPose(prevPose, keyPose, smooth(math.clamp((t - prevTime) / span, 0, 1)))
		end
		prevTime, prevPose = keyTime, keyPose
	end
	return prevPose
end

local LEGS = { RightHip = true, RightKnee = true, LeftHip = true, LeftKnee = true }

-- Pose "base" con las articulaciones de `parts` tomadas de `over`.
local function mergePose(base, over, parts)
	local result = table.clone(base)
	for joint in parts do
		result[joint] = over[joint]
	end
	return result
end

-- REACCIÓN AL GOLPE (por código): el cuerpo se dobla hacia donde lo empujan, más
-- exagerado el primer instante (latigazo) y, si el golpe es fuerte, da vueltas.
-- Lee HitAt (hora del golpe), HitForce (fuerza) y HitDir (lado del empujón) del servidor.
local function hitPose(model: Model)
	local base = Poses.States.Flinch or Poses.States.Hitstun
	local hitAt = model:GetAttribute("HitAt")
	local force = model:GetAttribute("HitForce") or 0
	local dir = model:GetAttribute("HitDir") or 0
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local facing = if root and root.CFrame.LookVector.X < 0 then -1 else 1
	-- Empujado hacia su espalda → se dobla hacia atrás (1); hacia su frente → hacia delante (-1)
	local lean = if dir ~= 0 and dir == facing then -1 else 1
	-- (durante el hitlag "since" es negativo: la pose se queda en el latigazo máximo)
	local since = if type(hitAt) == "number" then math.max(workspace:GetServerTimeNow() - hitAt, 0) else 1
	local snap = if since < 0.1 then 1.35 - since * 3.5 else 1 -- latigazo inicial
	local result = {}
	for joint, v in base do
		result[joint] = v * snap
	end
	result.Root = Vector3.new((base.Root and base.Root.X or 0) * lean * snap, 0, 0)
	result.Waist = Vector3.new((base.Waist and base.Waist.X or 0) * lean * snap, 0, 0)
	if force >= (Poses.States.TumbleForce or 55) and since > 0.08 then
		-- Sale volando: voltereta continua mientras dura el aturdimiento
		result.Root = result.Root + Vector3.new(-lean * since * 540, 0, 0)
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

	if pose.keys then
		return keyedPose(pose, data, t, weapon)
	end

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
		if Poses.CodePosesForStates then
			pose = hitPose(model)
		elseif not Animations.States.Hurt then
			pose = Poses.States.Hitstun
		end
	elseif state == "Dodging" then
		if not Animations.States.Dodge then
			pose = Poses.States.Dodging
		end
	else
		-- En el aire (saltando / cayendo) no hay animación: postura aérea por código.
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local weapon = model:GetAttribute("Weapon")
		local hasGuard = Poses.Guard and Poses.Guard[weapon] ~= nil
		if root and math.abs(root.AssemblyLinearVelocity.Y) > 4 then
			-- En el aire: piernas de salto + brazos en guardia del arma (si tiene).
			pose = if hasGuard then mergePose(guardPose(weapon), Poses.Locomotion.Air, LEGS) else Poses.Locomotion.Air
		elseif hasGuard and root and math.abs(root.AssemblyLinearVelocity.X) < 2 then
			-- Quieto: guardia del arma con respiración (no la animación genérica de Roblox).
			pose = guardPose(weapon)
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
