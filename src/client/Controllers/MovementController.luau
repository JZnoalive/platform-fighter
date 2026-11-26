-- StarterPlayer.StarterPlayerScripts.Client.Controllers.MovementController
-- Movimiento del personaje local: correr con aceleración, salto, saltos aéreos,
-- caída máxima, caída rápida, esquiva, bloqueo en el plano Z = 0 y knockback recibido.
-- Corre en el cliente porque Roblox da al jugador la física de su propio personaje.
-- Números en Shared.Config.MovementConfig (y tiempos de esquiva en GameConfig).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local OneWayPlatforms = require(ReplicatedStorage.Shared.Modules.OneWayPlatforms)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local MovementMath = require(ReplicatedStorage.Shared.Modules.MovementMath)
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
-- Caminar / correr / dash y caída rápida
local prevInputX = 0
local lastTapDir, lastTapAt = 0, -math.huge
local dashUntil, dashDir = 0, 1
local running = false
local fastFallActive = false

-- Datos para el panel de depuración de la sala de prueba (atributos LOCALES del
-- personaje propio: no se replican; los lee DebugController).
local function publishDebug(character: Model, moveState: string, vy: number, attackPhase: string?)
	character:SetAttribute("MoveState", moveState)
	character:SetAttribute("VY", math.floor(vy + 0.5))
	character:SetAttribute("JumpsLeft", airJumpsLeft)
	character:SetAttribute("RecoveryReady", recoveryAvailable)
	character:SetAttribute("AirDodgeReady", airDodgeAvailable)
	character:SetAttribute("AttackPhase", attackPhase or "-")
end

-- Desplazamiento propio del ataque en curso (campo lunge)
local lastMoveId: any = nil
local lungeFrom, lungeUntil, lungeSpeed = 0, 0, 0
local lungeVy: number? = nil
local lungeVyDone = true
local lastSelfImpulseAt = 0

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
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return humanoid ~= nil
		and humanoid.FloorMaterial ~= Enum.Material.Air
		and not (root and root.AssemblyLinearVelocity.Y >= 10) -- subiendo rápido = en el aire
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
	lungeUntil = 0 -- un golpe recibido corta el avance del ataque
	knockbackAt = os.clock() + lag
	InputController.ClearJump()
	inDodge = false
	-- Como en el género: recibir un golpe devuelve los saltos aéreos, el Recovery
	-- y la esquiva aérea.
	local full = MovementMath.FullResources(MovementConfig)
	airJumpsLeft = full.jumps
	recoveryAvailable = full.recovery
	airDodgeAvailable = full.airDodge
	-- Estado Physics: el Humanoid deja de frenar al personaje mientras vuela.
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	root.AssemblyLinearVelocity = Vector3.zero -- quieto durante el hitlag
end

-- Avisado por EffectsController cuando YO acierto un golpe (para la chase dodge).
function MovementController.NotifyLandedHit()
	lastLandedAt = os.clock()
	-- Al conectar, el avance del ataque se corta: el atacante no atraviesa ni se queda
	-- pegado al rival (queda a distancia para el siguiente golpe).
	lungeUntil = math.min(lungeUntil, os.clock())
end

-- ¿Acerté un golpe hace muy poco? (ventana de la chase dodge)
function MovementController.LandedHitRecently(): boolean
	return os.clock() - lastLandedAt <= GameConfig.ChaseDodgeWindow
end

-- Impulso propio de un ataque (Recovery, GroundPound). forward/up según selfImpulse.
-- forward = 0 conserva la velocidad horizontal actual.
function MovementController.ApplySelfImpulse(forward: number, up: number)
	local root = getBody()
	if not root then
		return
	end
	lastSelfImpulseAt = os.clock() -- este ataque mueve solo al personaje: no flota
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
		airDodgeAvailable = MovementMath.ConsumeAirDodge({ jumps = airJumpsLeft, recovery = recoveryAvailable, airDodge = airDodgeAvailable }).airDodge
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

-- Coloca al personaje en un punto mirando a un lado (botón de reinicio de la sala de prueba).
function MovementController.PlaceAt(x: number, y: number, newFacing: number)
	local root = getBody()
	if not root then
		return
	end
	facing = if newFacing < 0 then -1 else 1
	root.CFrame = CFrame.new(x, y, 0)
	MovementController.ResetMotion()
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

-- Fuerza hacia arriba que quita parte de la gravedad durante los ataques aéreos.
-- Es una fuerza FÍSICA (se aplica en cada paso de la física, no solo una vez por
-- fotograma), así la "flotación" es estable aunque la física vaya más rápido que la pantalla.
local function getHoverForce(root: BasePart): VectorForce
	local force = root:FindFirstChild("HoverForce") :: VectorForce?
	if force then
		return force
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "HoverAttachment"
	attachment.Parent = root
	local newForce = Instance.new("VectorForce")
	newForce.Name = "HoverForce"
	newForce.Attachment0 = attachment
	newForce.RelativeTo = Enum.ActuatorRelativeTo.World
	newForce.ApplyAtCenterOfMass = true
	newForce.Force = Vector3.zero
	newForce.Parent = root
	return newForce
end

local function step(dt: number)
	local root, humanoid = getBody()
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	local hoverForce = getHoverForce(root)
	hoverForce.Force = Vector3.zero -- se vuelve a encender abajo solo si hay ataque aéreo

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
			publishDebug(body, "Hitstun", root.AssemblyLinearVelocity.Y, nil)
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
			publishDebug(body, if dodgeOnGround then "Dodging" else "AirDodging", root.AssemblyLinearVelocity.Y, nil)
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

	-- Si subes rápido NO estás en el suelo aunque el Humanoid aún detecte suelo cerca
	-- (pasaba al usar el Recovery a poca altura: recargaba los saltos sin aterrizar).
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air and root.AssemblyLinearVelocity.Y < 10
	if grounded then
		lastGroundedAt = now
		local full = MovementMath.FullResources(MovementConfig) -- al aterrizar se recarga todo
		airJumpsLeft = full.jumps
		groundJumpAvailable = true
		recoveryAvailable = full.recovery
		airDodgeAvailable = full.airDodge
	end

	local attacking = character:GetAttribute("State") == "Attacking" or now < localAttackUntil

	-- 0d. Ataque CON DESPLAZAMIENTO (campo lunge del ataque): cuando el servidor confirma
	-- un ataque nuevo (cambia MoveId), se programa el avance descontando lo que ya pasó.
	-- Así también avanzan los ataques que salen del búfer en un combo.
	local moveId = character:GetAttribute("MoveId")
	if moveId ~= lastMoveId then
		lastMoveId = moveId
		lungeUntil = 0
		if character:GetAttribute("State") == "Attacking" then
			local moveset = FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
			local data = moveset and moveset[character:GetAttribute("Move")]
			local lunge = data and data.lunge
			local moveTime = character:GetAttribute("MoveTime")
			if lunge and type(moveTime) == "number" then
				local elapsed = workspace:GetServerTimeNow() - moveTime
				lungeFrom = now + math.max(0, (lunge.delay or 0) - elapsed)
				lungeUntil = lungeFrom + lunge.time
				lungeSpeed = lunge.speed
				lungeVy = lunge.vy
				lungeVyDone = false
			end
		end
	end

	-- Fase del ataque en curso (para saber cuánto control hay): solo se bloquea en las
	-- ventanas de arranque/golpe en el suelo; en la recuperación y en el aire hay control parcial.
	local attackPhase: string? = nil
	local hovering = false -- ataque aéreo en arranque/golpe: casi flota
	if character:GetAttribute("State") == "Attacking" then
		local moveset = FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
		local data = moveset and moveset[character:GetAttribute("Move")]
		local moveTime = character:GetAttribute("MoveTime")
		if data and type(moveTime) == "number" then
			attackPhase = MovementMath.AttackPhase(workspace:GetServerTimeNow() - moveTime, data)
			local descends = (data.lunge and data.lunge.vy and data.lunge.vy < 0)
				or (data.selfImpulse and data.selfImpulse.Y ~= 0) -- picados, GroundPound, Recovery
			hovering = not grounded and attackPhase ~= "done" and not descends
		else
			attackPhase = "startup"
		end
	elseif now < localAttackUntil then
		attackPhase = "startup" -- recién pulsado, el servidor aún no lo confirmó
		hovering = not grounded and now - lastSelfImpulseAt > 0.3 -- flota ya desde que pulsas
	end

	-- 1. Horizontal: caminar, correr (tras un dash) y DASH (doble toque de A/D en el suelo).
	local inputX = InputController.GetMoveX()
	if grounded and attackPhase == nil and inputX ~= 0 and inputX ~= prevInputX then
		if inputX == lastTapDir and now - lastTapAt <= MovementConfig.DashDoubleTapWindow then
			dashUntil = now + MovementConfig.DashTime
			dashDir = inputX
			running = true
		end
		lastTapDir = inputX
		lastTapAt = now
	end
	if inputX == 0 and grounded then
		running = false
	end
	prevInputX = inputX

	local control = MovementMath.ControlFactor(attackPhase, grounded, MovementConfig)
	local moveX = inputX * control
	-- Stat de Velocidad del personaje (FighterStats)
	local baseSpeed = if grounded
		then (if running then MovementConfig.RunSpeed else MovementConfig.WalkSpeed)
		else MovementConfig.AirSpeed
	local maxSpeed = baseSpeed * FighterStats.SpeedMultiplier(character:GetAttribute("FighterId"))
	local rate
	if moveX ~= 0 then
		rate = if grounded then MovementConfig.GroundAcceleration else MovementConfig.AirAcceleration
		-- Dash jump: en el aire, si vas MÁS rápido que AirSpeed en la misma dirección,
		-- el impulso se conserva y solo se pierde poco a poco.
		if not grounded and math.sign(speedX) == math.sign(moveX) and math.abs(speedX) > math.abs(moveX * maxSpeed) then
			rate = MovementConfig.AirDeceleration
		end
	else
		rate = if grounded then MovementConfig.GroundDeceleration else MovementConfig.AirDeceleration
	end
	speedX = approach(speedX, moveX * maxSpeed, rate * dt)
	if now < dashUntil then
		speedX = MovementConfig.DashSpeed * dashDir
	end
	-- Desplazamiento del ataque: manda sobre lo anterior mientras dura.
	if now >= lungeFrom and now < lungeUntil then
		speedX = lungeSpeed * facing
		if lungeVy and not lungeVyDone then
			lungeVyDone = true
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, lungeVy, 0)
		end
	end
	-- Durante un ataque (avance, embestida...), si hay un rival justo delante el avance se
	-- para: no se le atraviesa y el siguiente golpe queda a buena distancia.
	if attackPhase and speedX * facing > 0 then
		for _, model in CollectionService:GetTagged("CameraTarget") do
			local other = model ~= character and model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if other and math.abs(other.Position.Y - root.Position.Y) < 4 then
				local ahead = (other.Position.X - root.Position.X) * facing
				if ahead > -0.5 and ahead < MovementConfig.LungeStopDistance then
					speedX = 0
				end
			end
		end
	end

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
		if inputX > 0 then
			facing = 1
		elseif inputX < 0 then
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
		elseif not grounded and MovementMath.CanAirJump(airJumpsLeft) then
			InputController.ClearJump()
			airJumpsLeft = MovementMath.ConsumeAirJump({ jumps = airJumpsLeft, recovery = recoveryAvailable, airDodge = airDodgeAvailable }).jumps
			fastFallActive = false
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.AirJumpVelocity, 0)
		end
		-- Si no se puede saltar, el salto queda guardado un instante (JumpBuffer).
	end

	-- 3. Gravedad por fases (subida / punto alto / bajada) y CAÍDA RÁPIDA gradual:
	-- mantener S en el aire, solo si ya bajas o estás en el punto alto.
	local vel = root.AssemblyLinearVelocity
	local fastFalling = false
	if not grounded then
		fastFalling = InputController.IsDownHeld()
			and (fastFallActive or MovementMath.CanStartFastFall(vel.Y, MovementConfig))
		fastFallActive = fastFalling
		if hovering then
			-- Ataque aéreo: la fuerza quita (1 - AirAttackGravityMultiplier) de la gravedad
			-- y aquí solo se limita la caída (mismo resultado que VerticalStep con hovering).
			local g = workspace.Gravity
			hoverForce.Force = Vector3.new(0, root.AssemblyMass * g * (1 - MovementConfig.AirAttackGravityMultiplier), 0)
			root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -MovementConfig.AirAttackMaxFallSpeed), 0)
		else
			root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementMath.VerticalStep(vel.Y, dt, MovementConfig, fastFalling), 0)
		end
	else
		fastFallActive = false
	end
	local maxFall = if fastFalling then MovementConfig.FastFallSpeed else MovementConfig.MaxFallSpeed

	-- 4. Estado para el panel de depuración (atributos LOCALES: no se envían al servidor).
	local moveName = character:GetAttribute("Move")
	local moveState
	if attackPhase then
		moveState = if moveName == "Recovery" then "Recovering" elseif grounded then "Attacking" else "AirAttacking"
	elseif grounded then
		moveState = if running then "Running" elseif math.abs(speedX) > 1 then "Walking" else "Grounded"
	elseif fastFalling then
		moveState = "FastFalling"
	else
		moveState = if root.AssemblyLinearVelocity.Y > 0 then "Jumping" else "Falling"
	end
	publishDebug(character, moveState, root.AssemblyLinearVelocity.Y, attackPhase)

	-- 5. Plano 2D, orientación y caída máxima.
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
