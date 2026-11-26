-- ServerScriptService.Server.Services.CpuService
-- Controla a los luchadores de tipo "Cpu". Corre en el SERVIDOR porque el servidor
-- es el dueño de la física de la CPU.
-- La CPU usa exactamente el mismo combate que un jugador (CombatService.PerformAttack
-- y FighterService.TryStartDodge): no hace trampas con daño ni hitboxes.
--
-- Comportamientos (los elige el menú de práctica):
--   Idle   = Quieta     : no hace nada (ni siquiera vuelve si la sacas)
--   Walk   = Caminar    : va y viene por el escenario
--   Jump   = Saltar     : salta y hace un salto aéreo cada poco
--   Dodge  = Esquivar   : esquiva cuando un jugador cercano ataca
--   Attack = Atacar     : se queda quieta y ataca cada segundo
--   Fight  = Pelear     : se acerca, ataca, esquiva y remata (IA simple)
-- Todos menos Idle intentan volver al escenario si los sacan.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CpuConfig = require(ReplicatedStorage.Shared.Config.CpuConfig)
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local OneWayPlatforms = require(ReplicatedStorage.Shared.Modules.OneWayPlatforms)
local FighterService = require(script.Parent.FighterService)
local CombatService = require(script.Parent.CombatService)

local CpuService = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

type Controller = {
	fighter: FighterService.Fighter,
	behavior: string,
	facing: number,
	airJumpsLeft: number,
	recoveryAvailable: boolean,
	patrolDir: number,
	nextJumpAt: number,
	nextAirJumpAt: number,
	nextAttackAt: number,
	nextReactAt: number,
	dodgeVelocity: Vector3,
	attackToggle: boolean,
	platformState: { dropUntil: number }, -- plataformas de un solo sentido
}

local controllers: { [Model]: Controller } = {}

local function sign(x: number): number
	return if x >= 0 then 1 else -1
end

-- Jugador vivo más cercano (o nil).
local function getTarget(position: Vector3): FighterService.Fighter?
	local best, bestDist = nil, math.huge
	for _, other in FighterService.GetAll() do
		if other.kind == "Player" then
			local state = FighterService.GetState(other)
			if state ~= "KO" and state ~= "Respawning" and state ~= "Eliminated" then
				local dist = (other.root.Position - position).Magnitude
				if dist < bestDist then
					best, bestDist = other, dist
				end
			end
		end
	end
	return best
end

local function jump(ctrl: Controller, grounded: boolean)
	local fighter = ctrl.fighter
	if grounded then
		fighter.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local vel = fighter.root.AssemblyLinearVelocity -- despegue instantáneo
		fighter.root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.JumpVelocity, 0)
	elseif ctrl.airJumpsLeft > 0 then
		ctrl.airJumpsLeft -= 1
		local vel = fighter.root.AssemblyLinearVelocity
		fighter.root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.AirJumpVelocity, 0)
	end
end

local function attack(ctrl: Controller, moveName: string): boolean
	local fighter = ctrl.fighter
	local moveset = FighterStats.Moveset(fighter.model:GetAttribute("Weapon"), fighter.fighterId) -- según el arma que lleva
	local data = moveset and moveset[moveName]
	if not data or FighterService.GetState(fighter) ~= "Idle" then
		return false
	end
	-- Mirar hacia donde toca ANTES de atacar (la hitbox usa la orientación del cuerpo).
	local pos = fighter.root.Position
	fighter.root.CFrame = CFrame.new(pos.X, pos.Y, 0) * (if ctrl.facing == 1 then FACE_RIGHT else FACE_LEFT)

	CombatService.PerformAttack(fighter, data, moveName)
	if data.selfImpulse then
		local facing = ctrl.facing
		local function push()
			local vel = fighter.root.AssemblyLinearVelocity
			local x = if data.selfImpulse.X ~= 0 then data.selfImpulse.X * facing else vel.X
			fighter.root.AssemblyLinearVelocity = Vector3.new(x, data.selfImpulse.Y, 0)
		end
		if data.impulseAtStartup then
			-- Embestidas: el impulso sale con el golpe, no al empezar
			task.delay(data.startup, function()
				if fighter.model.Parent and FighterService.GetState(fighter) == "Attacking" then
					push()
				end
			end)
		else
			push()
		end
	end
	-- Ataque con desplazamiento propio (campo lunge): avanza mientras dura.
	if data.lunge then
		local lunge = data.lunge
		local facing = ctrl.facing
		local moveId = fighter.model:GetAttribute("MoveId")
		task.spawn(function()
			task.wait(lunge.delay or 0)
			local stopAt = os.clock() + lunge.time
			local vyDone = false
			while os.clock() < stopAt do
				if not fighter.model.Parent or FighterService.GetState(fighter) ~= "Attacking"
					or fighter.model:GetAttribute("MoveId") ~= moveId then
					return
				end
				local vel = fighter.root.AssemblyLinearVelocity
				local vy = vel.Y
				if lunge.vy and not vyDone then
					vy = lunge.vy
					vyDone = true
				end
				fighter.root.AssemblyLinearVelocity = Vector3.new(lunge.speed * facing, vy, 0)
				RunService.Heartbeat:Wait()
			end
		end)
	end
	return true
end

local function dodge(ctrl: Controller, dirX: number)
	if FighterService.TryStartDodge(ctrl.fighter) then
		ctrl.dodgeVelocity = Vector3.new(dirX * MovementConfig.DodgeSpeed, 0, 0)
	end
end

-- Decide qué hacer este frame. Devuelve hacia dónde caminar (-1, 0, 1).
local function decide(ctrl: Controller, state: string, grounded: boolean, pos: Vector3, vel: Vector3): number
	local behavior = ctrl.behavior
	if behavior == "Idle" then
		return 0
	end
	local now = os.clock()

	-- Volver al escenario si lo sacaron (todos menos Quieta).
	local offstage = math.abs(pos.X) > CpuConfig.StageHalfWidth or pos.Y < CpuConfig.StageTopY
	if offstage and not grounded then
		local toCenter = if pos.X > 0 then -1 else 1
		ctrl.facing = toCenter
		if state == "Idle" and vel.Y < 0 then
			if ctrl.airJumpsLeft > 0 and now >= ctrl.nextAirJumpAt then
				jump(ctrl, false)
				ctrl.nextAirJumpAt = now + 0.35
			elseif ctrl.airJumpsLeft == 0 and ctrl.recoveryAvailable then
				ctrl.recoveryAvailable = false
				attack(ctrl, "Recovery")
			end
		end
		return toCenter
	end

	if behavior == "Walk" then
		if pos.X > CpuConfig.PatrolHalfWidth then
			ctrl.patrolDir = -1
		elseif pos.X < -CpuConfig.PatrolHalfWidth then
			ctrl.patrolDir = 1
		end
		return ctrl.patrolDir
	end

	if behavior == "Jump" then
		if grounded and now >= ctrl.nextJumpAt then
			jump(ctrl, true)
			ctrl.nextJumpAt = now + CpuConfig.JumpInterval
			ctrl.nextAirJumpAt = now + 0.4
		elseif
			not grounded
			and now >= ctrl.nextAirJumpAt
			and ctrl.airJumpsLeft == MovementConfig.MaxAirJumps
			and vel.Y < 5
		then
			jump(ctrl, false) -- un solo salto aéreo por ciclo
		end
		return 0
	end

	local target = getTarget(pos)
	if not target then
		return 0
	end
	local targetPos = target.root.Position
	local dx = targetPos.X - pos.X
	local dy = targetPos.Y - pos.Y
	local dist = math.abs(dx)
	local targetState = FighterService.GetState(target)
	if state ~= "Attacking" then
		ctrl.facing = sign(dx)
	end

	if behavior == "Dodge" then
		if state == "Idle" and now >= ctrl.nextReactAt and dist < CpuConfig.DodgeReactRange and targetState == "Attacking" then
			ctrl.nextReactAt = now + 0.3
			dodge(ctrl, -sign(dx)) -- se aparta del atacante
		end
		return 0
	end

	if behavior == "Attack" then
		if state == "Idle" and now >= ctrl.nextAttackAt then
			ctrl.attackToggle = not ctrl.attackToggle
			attack(ctrl, if ctrl.attackToggle then "Jab" else "SideLight")
			ctrl.nextAttackAt = now + CpuConfig.AttackInterval
		end
		return 0
	end

	-- behavior == "Fight"
	if state ~= "Idle" then
		return if dist > CpuConfig.AttackRange then sign(dx) else 0
	end

	-- Reaccionar a un ataque cercano con una esquiva (a veces).
	if targetState == "Attacking" and dist < CpuConfig.DodgeReactRange and now >= ctrl.nextReactAt then
		ctrl.nextReactAt = now + 0.5
		if math.random() < CpuConfig.DodgeChance then
			dodge(ctrl, -sign(dx))
			return 0
		end
	end

	-- Acercarse (y saltar si el rival está arriba).
	if dist > CpuConfig.AttackRange then
		if dy > 6 and grounded and now >= ctrl.nextJumpAt then
			jump(ctrl, true)
			ctrl.nextJumpAt = now + 0.8
		end
		return sign(dx)
	end

	-- En rango: atacar.
	if now >= ctrl.nextAttackAt then
		local moveName
		local targetPercent = target.model:GetAttribute("Percent") or 0
		if dy > 3 then
			moveName = if grounded then "UpLight" else "AirUpLight"
		elseif not grounded then
			moveName = "AirLight"
		elseif targetPercent >= CpuConfig.KillPercent and math.random() < 0.5 then
			moveName = if math.random() < 0.5 then "Heavy" else "UpHeavy"
		else
			local options = { "Jab", "Jab", "SideLight", "DownLight" }
			moveName = options[math.random(#options)]
		end
		attack(ctrl, moveName)
		ctrl.nextAttackAt = now + CpuConfig.AttackCooldown + math.random() * CpuConfig.ReactionJitter
	end
	return 0
end

local function step(ctrl: Controller)
	local fighter = ctrl.fighter
	local root, humanoid = fighter.root, fighter.humanoid
	local state = FighterService.GetState(fighter)
	OneWayPlatforms.Update(fighter.model, root, humanoid, false, ctrl.platformState)
	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		ctrl.airJumpsLeft = MovementConfig.MaxAirJumps
		ctrl.recoveryAvailable = true
	end

	local pos = root.Position
	local vel = root.AssemblyLinearVelocity
	local moveX = 0

	-- Hitlag como atacante: quieta un instante al acertar (FrozenUntil lo pone FighterService).
	local frozenUntil = fighter.model:GetAttribute("FrozenUntil")
	local frozen = state ~= "Hitstun"
		and type(frozenUntil) == "number"
		and workspace:GetServerTimeNow() < frozenUntil

	if frozen then
		humanoid:Move(Vector3.zero)
		root.AssemblyLinearVelocity = Vector3.zero
	elseif state == "Idle" or state == "Attacking" then
		moveX = decide(ctrl, state, grounded, pos, vel)
		if state == "Attacking" and grounded then
			moveX = 0
		end
		if moveX ~= 0 and state == "Idle" then
			ctrl.facing = moveX
		end
		humanoid.WalkSpeed = (if grounded then MovementConfig.GroundSpeed else MovementConfig.AirSpeed)
			* CpuConfig.SpeedMultiplier
			* FighterStats.SpeedMultiplier(fighter.fighterId)
		humanoid:Move(Vector3.new(moveX, 0, 0))
	else
		humanoid:Move(Vector3.zero)
		if state == "Dodging" then
			root.AssemblyLinearVelocity = Vector3.new(ctrl.dodgeVelocity.X, vel.Y, 0)
		end
	end

	-- Plano 2D, orientación y caída máxima (Hitstun incluido: se conserva el vuelo).
	pos = root.Position
	root.CFrame = CFrame.new(pos.X, pos.Y, 0) * (if ctrl.facing == 1 then FACE_RIGHT else FACE_LEFT)
	vel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -MovementConfig.MaxFallSpeed), 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

-- Empieza a controlar un luchador CPU ya registrado en FighterService.
function CpuService.Attach(fighter: FighterService.Fighter, behavior: string)
	local humanoid = fighter.humanoid
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = true
	humanoid.JumpPower = MovementConfig.JumpVelocity

	local ctrl: Controller = {
		fighter = fighter,
		behavior = behavior,
		facing = -1,
		airJumpsLeft = MovementConfig.MaxAirJumps,
		recoveryAvailable = true,
		patrolDir = -1,
		nextJumpAt = 0,
		nextAirJumpAt = 0,
		nextAttackAt = 0,
		nextReactAt = 0,
		dodgeVelocity = Vector3.zero,
		attackToggle = false,
		platformState = { dropUntil = 0 },
	}
	controllers[fighter.model] = ctrl

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not fighter.model.Parent then
			connection:Disconnect()
			controllers[fighter.model] = nil
			return
		end
		step(ctrl)
	end)
end

function CpuService.SetBehavior(fighter: FighterService.Fighter, behavior: string)
	local ctrl = controllers[fighter.model]
	if ctrl then
		ctrl.behavior = behavior
		ctrl.nextAttackAt = 0
		ctrl.nextJumpAt = 0
	end
end

-- Tras recolocarla (KO / reinicio): saltos y recovery recargados.
function CpuService.ResetState(fighter: FighterService.Fighter)
	local ctrl = controllers[fighter.model]
	if ctrl then
		ctrl.airJumpsLeft = MovementConfig.MaxAirJumps
		ctrl.recoveryAvailable = true
		ctrl.facing = -1
	end
end

return CpuService
