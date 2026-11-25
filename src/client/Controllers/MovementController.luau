-- StarterPlayer.StarterPlayerScripts.Client.Controllers.MovementController
-- Movimiento del personaje local: correr con aceleración, salto, saltos aéreos,
-- caída máxima, caída rápida, esquiva, bloqueo en el plano Z = 0 y knockback recibido.
-- Corre en el cliente porque Roblox da al jugador la física de su propio personaje.
-- Números en Shared.Config.MovementConfig (y tiempos de esquiva en GameConfig).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local OneWayPlatforms = require(ReplicatedStorage.Shared.Modules.OneWayPlatforms)
local InputController = require(script.Parent.InputController)

local MovementController = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local facing = 1 -- 1 = derecha (+X), -1 = izquierda (-X)
local speedX = 0 -- velocidad horizontal que queremos (con aceleración)
local airJumpsLeft = MovementConfig.MaxAirJumps
local groundJumpAvailable = true
local lastGroundedAt = -math.huge
local inHitstun = false
local hitstunUntil = 0
local recoveryAvailable = true -- el Recovery se usa 1 vez por vuelo
local inDodge = false
local dodgeUntil = 0
local dodgeVelocity = Vector3.zero
local dodgeOnGround = false
local lastDodgeAt = -math.huge
local airDodgeAvailable = true -- la esquiva aérea se usa 1 vez por vuelo
local pendingKnockback: Vector3? = nil -- se aplica al terminar el hitlag
local knockbackAt = 0
local lastLandedAt = -math.huge -- último golpe que acerté (chase dodge)
local platformState = { dropUntil = 0 } -- plataformas de un solo sentido
local downHeldSince: number? = nil -- desde cuándo se mantiene S (dejarse caer)
local lastAttackingAt = -math.huge -- para no perder el salto pulsado al final de un ataque
local localAttackUntil = 0 -- ataque recién pulsado que el servidor aún no ha confirmado

-- Lo llama CombatController al pulsar un ataque: mientras dure, cuenta como "atacando"
-- (no se gira ni se camina) aunque el estado del servidor no haya llegado todavía.
function MovementController.NotifyAttackStarted(duration: number)
	localAttackUntil = os.clock() + duration
end

function MovementController.GetFacing(): number
	return facing
end

function MovementController.IsGrounded(): boolean
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
end

-- Devuelve true y lo gasta si el Recovery está disponible.
function MovementController.TryUseRecovery(): boolean
	if not recoveryAvailable then
		return false
	end
	recoveryAvailable = false
	return true
end

local function approach(current: number, target: number, maxStep: number): number
	if current < target then
		return math.min(current + maxStep, target)
	end
	return math.max(current - maxStep, target)
end

local function getBody(): (BasePart?, Humanoid?)
	local character = Players.LocalPlayer.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChildOfClass("Humanoid")
end

-- Lo llama el servidor (remote ApplyKnockback) cuando nos golpean.
-- hitlag: segundos congelado ANTES de salir volando (estilo Smash).
function MovementController.ApplyKnockback(velocity: Vector3, hitstun: number, hitlag: number?)
	local root, humanoid = getBody()
	if not root or not humanoid then
		return
	end
	local lag = hitlag or 0
	inHitstun = true
	hitstunUntil = os.clock() + lag + hitstun
	pendingKnockback = velocity
	knockbackAt = os.clock() + lag
	InputController.ClearJump()
	inDodge = false
	-- Como en el género: recibir un golpe devuelve los saltos aéreos, el Recovery
	-- y la esquiva aérea.
	airJumpsLeft = MovementConfig.MaxAirJumps
	recoveryAvailable = true
	airDodgeAvailable = true
	-- Estado Physics: el Humanoid deja de frenar al personaje mientras vuela.
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	root.AssemblyLinearVelocity = Vector3.zero -- quieto durante el hitlag
end

-- Avisado por EffectsController cuando YO acierto un golpe (para la chase dodge).
function MovementController.NotifyLandedHit()
	lastLandedAt = os.clock()
end

-- Impulso propio de un ataque (Recovery, GroundPound). forward/up según selfImpulse.
-- forward = 0 conserva la velocidad horizontal actual.
function MovementController.ApplySelfImpulse(forward: number, up: number)
	local root = getBody()
	if not root then
		return
	end
	local vel = root.AssemblyLinearVelocity
	local x = if forward ~= 0 then forward * facing else vel.X
	if forward ~= 0 then
		speedX = x
	end
	root.AssemblyLinearVelocity = Vector3.new(x, up, 0)
end

-- ¿Se puede esquivar ahora? (enfriamiento + 1 esquiva aérea por vuelo)
function MovementController.CanDodge(): boolean
	if inHitstun or inDodge then
		return false
	end
	local now = os.clock()
	local cooldown = if now - lastLandedAt <= GameConfig.ChaseDodgeWindow
		then GameConfig.ChaseDodgeCooldown
		else GameConfig.DodgeCooldown
	if now - lastDodgeAt < cooldown then
		return false
	end
	return MovementController.IsGrounded() or airDodgeAvailable
end

-- Empieza la esquiva. dirX: -1/0/1 (A/D). dirY: -1/0/1 (S/W, solo cuenta en el aire).
-- Sin dirección = esquiva en el sitio. La invulnerabilidad la decide el servidor.
function MovementController.StartDodge(dirX: number, dirY: number)
	local root, humanoid = getBody()
	if not root or not humanoid then
		return
	end
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		dirY = 0
	else
		airDodgeAvailable = false
	end

	lastDodgeAt = os.clock()
	dodgeUntil = lastDodgeAt + GameConfig.DodgeDuration
	inDodge = true
	dodgeOnGround = grounded
	InputController.ClearJump()

	if dirX == 0 and dirY == 0 then
		dodgeVelocity = Vector3.zero
	else
		local dir = Vector2.new(dirX, dirY).Unit
		local speed = if grounded then MovementConfig.DodgeSpeed else MovementConfig.AirDodgeSpeed
		dodgeVelocity = Vector3.new(dir.X * speed, dir.Y * speed, 0)
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
end

-- Lo llama el servidor (remote FighterReset) tras un respawn: empezar de cero.
function MovementController.ResetMotion()
	speedX = 0
	inHitstun = false
	inDodge = false
	pendingKnockback = nil
	airDodgeAvailable = true
	airJumpsLeft = MovementConfig.MaxAirJumps
	groundJumpAvailable = true
	recoveryAvailable = true
	InputController.ClearJump()
	local root, humanoid = getBody()
	if root and humanoid then
		root.AssemblyLinearVelocity = Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function lockToPlane(root: BasePart, maxFallSpeed: number)
	local pos = root.Position
	local rotation = if facing == 1 then FACE_RIGHT else FACE_LEFT
	root.CFrame = CFrame.new(pos.X, pos.Y, 0) * rotation

	local vel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -maxFallSpeed), 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = true
	humanoid.JumpPower = MovementConfig.JumpVelocity
	speedX = 0
	airJumpsLeft = MovementConfig.MaxAirJumps
	groundJumpAvailable = true
	recoveryAvailable = true
	airDodgeAvailable = true
	inHitstun = false
	inDodge = false
end

local function step(dt: number)
	local root, humanoid = getBody()
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()

	-- Plataformas de un solo sentido (siempre, también en hitstun: se atraviesan al salir
	-- lanzado hacia arriba). Mantener S sin atacar = dejarse caer.
	local body = root.Parent :: Model
	-- (hay que mantener S un instante: un toque rápido de S + J sigue siendo DownLight)
	if InputController.IsDownHeld() then
		downHeldSince = downHeldSince or now
	else
		downHeldSince = nil
	end
	local wantsDrop = downHeldSince ~= nil
		and now - downHeldSince >= 0.12
		and not inHitstun
		and body:GetAttribute("State") == "Idle"
	OneWayPlatforms.Update(body, root, humanoid, wantsDrop, platformState)

	-- 0. Hitstun: sin control. Primero congelado (hitlag), luego sale volando.
	if inHitstun then
		if now < hitstunUntil then
			humanoid.WalkSpeed = 0
			humanoid:Move(Vector3.zero)
			if pendingKnockback then
				if now >= knockbackAt then
					root.AssemblyLinearVelocity = pendingKnockback
					pendingKnockback = nil
				else
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end
			lockToPlane(root, MovementConfig.MaxFallSpeed)
			return
		end
		inHitstun = false
		speedX = root.AssemblyLinearVelocity.X -- conservar el impulso al recuperar el control
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	-- 0b. Esquiva: velocidad fija durante DodgeDuration, sin control.
	if inDodge then
		if now < dodgeUntil then
			humanoid.WalkSpeed = 0
			humanoid:Move(Vector3.zero)
			local vel = root.AssemblyLinearVelocity
			-- En el suelo se conserva la gravedad (para no flotar si ruedas fuera del borde);
			-- en el aire la esquiva "congela" la caída, como en el género.
			local y = if dodgeOnGround then vel.Y else dodgeVelocity.Y
			root.AssemblyLinearVelocity = Vector3.new(dodgeVelocity.X, y, 0)
			lockToPlane(root, MovementConfig.MaxFallSpeed)
			return
		end
		inDodge = false
		speedX = dodgeVelocity.X * 0.3
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	local character = root.Parent :: Model

	-- 0c. Hitlag como ATACANTE: quieto un instante al acertar (el servidor pone FrozenUntil).
	local frozenUntil = character:GetAttribute("FrozenUntil")
	if type(frozenUntil) == "number" and workspace:GetServerTimeNow() < frozenUntil then
		humanoid.WalkSpeed = 0
		humanoid:Move(Vector3.zero)
		root.AssemblyLinearVelocity = Vector3.zero
		lockToPlane(root, MovementConfig.MaxFallSpeed)
		return
	end

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		lastGroundedAt = now
		airJumpsLeft = MovementConfig.MaxAirJumps
		groundJumpAvailable = true
		recoveryAvailable = true
		airDodgeAvailable = true
	end

	local attacking = character:GetAttribute("State") == "Attacking" or now < localAttackUntil

	-- 1. Horizontal: acelerar hacia la velocidad objetivo.
	-- Atacando en el suelo no se avanza; en el aire se conserva el control.
	local moveX = if attacking and grounded then 0 else InputController.GetMoveX()
	local maxSpeed = if grounded then MovementConfig.GroundSpeed else MovementConfig.AirSpeed
	local rate
	if moveX ~= 0 then
		rate = if grounded then MovementConfig.GroundAcceleration else MovementConfig.AirAcceleration
	else
		rate = if grounded then MovementConfig.GroundDeceleration else MovementConfig.AirDeceleration
	end
	speedX = approach(speedX, moveX * maxSpeed, rate * dt)

	-- El Humanoid aplica la velocidad: así respeta suelo, rampas y animaciones.
	if math.abs(speedX) < 0.05 then
		humanoid.WalkSpeed = 0
		humanoid:Move(Vector3.zero)
	else
		humanoid.WalkSpeed = math.abs(speedX)
		humanoid:Move(Vector3.new(math.sign(speedX), 0, 0))
	end

	-- Durante un ataque no se gira (el golpe sale hacia donde mirabas).
	if not attacking then
		if moveX > 0 then
			facing = 1
		elseif moveX < 0 then
			facing = -1
		end
	end

	-- 2. Saltos (no durante un ataque). Si el ataque ACABA de terminar, vale un salto
	-- pulsado durante su final (hasta 0,35 s antes): el fin del ataque llega del servidor
	-- con retraso y, sin esto, el salto del combo se perdía.
	if attacking then
		lastAttackingAt = now
	end
	local jumpWindow = if now - lastAttackingAt <= 0.1 then 0.35 else MovementConfig.JumpBuffer
	if not attacking and InputController.HasBufferedJump(jumpWindow) then
		local canGroundJump = groundJumpAvailable and (now - lastGroundedAt) <= MovementConfig.CoyoteTime
		if canGroundJump then
			InputController.ClearJump()
			groundJumpAvailable = false
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			-- Despegue INSTANTÁNEO (el salto del Humanoid tarda unos frames en empujar):
			-- clave para que DLight > salto > aéreo sea un combo verdadero.
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.JumpVelocity, 0)
		elseif not grounded and airJumpsLeft > 0 then
			InputController.ClearJump()
			airJumpsLeft -= 1
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.AirJumpVelocity, 0)
		end
		-- Si no se puede saltar, el salto queda guardado un instante (JumpBuffer).
	end

	-- 3. Caída rápida: mantener S en el aire cuando ya no subes.
	local maxFall = MovementConfig.MaxFallSpeed
	if not grounded and InputController.IsDownHeld() then
		maxFall = MovementConfig.FastFallSpeed
		local vel = root.AssemblyLinearVelocity
		if vel.Y < MovementConfig.FastFallTrigger then
			root.AssemblyLinearVelocity = Vector3.new(vel.X, -MovementConfig.FastFallSpeed, 0)
		end
	end

	-- 4. Plano 2D, orientación y caída máxima.
	lockToPlane(root, maxFall)
end

function MovementController.Start()
	local player = Players.LocalPlayer
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Los controles por defecto de Roblox llaman a Humanoid:Move(...) cada frame
	-- con prioridad "Input". Nos ejecutamos justo DESPUÉS para que nuestro Move
	-- sea el último antes de la física (si no, ellos lo pisan con cero).
	RunService:BindToRenderStep("PlatformFighterMovement", Enum.RenderPriority.Input.Value + 1, step)

	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local applyKnockback = remotes:WaitForChild("ApplyKnockback") :: RemoteEvent
		applyKnockback.OnClientEvent:Connect(MovementController.ApplyKnockback)
		local fighterReset = remotes:WaitForChild("FighterReset") :: RemoteEvent
		fighterReset.OnClientEvent:Connect(MovementController.ResetMotion)
	end)
end

return MovementController
