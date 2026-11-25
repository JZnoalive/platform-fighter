-- ServerScriptService.Server.Services.CombatService
-- Ataques: valida la petición del cliente, controla startup/active/recovery,
-- crea la hitbox y decide quién recibe el golpe.
-- El cliente solo dice "quiero hacer Jab"; el servidor decide todo lo demás.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local FighterService = require(script.Parent.FighterService)
local Remotes = require(script.Parent.Parent.Remotes)


local CombatService = {}

local function getRootFacing(root: BasePart): number
	return if root.CFrame.LookVector.X >= 0 then 1 else -1
end

-- Hacia dónde mira el luchador PARA SU ATAQUE. El servidor ve el giro del jugador con
-- retraso: si te girabas y atacabas enseguida, el golpe salía hacia el otro lado.
-- Por eso el cliente manda su orientación al pedir el ataque y se usa esa.
local attackFacings: { [Model]: { current: number?, queued: number? } } = setmetatable({}, { __mode = "k" }) :: any

local function facingOf(fighter: FighterService.Fighter): number
	local entry = fighter.player and attackFacings[fighter.model]
	if entry and entry.current then
		return entry.current
	end
	return getRootFacing(fighter.root)
end

-- Compensación de latencia: el servidor ve al JUGADOR con retraso (Roblox interpola su
-- posición), así que en un combo aéreo la hitbox salía donde estabas hace ~0,15 s.
-- Mientras ataca, el cliente manda su posición real ("Aim"); si es reciente y está cerca
-- de lo que ve el servidor (anti-trampas), la hitbox sale desde ahí.
local CLIENT_POS_MAX_AGE = 0.25
local CLIENT_POS_MAX_DIST = 20 -- saltando a 75 studs/s, 0,15 s de retraso ya son ~11 studs
local clientPositions: { [Model]: { pos: Vector3, at: number } } = setmetatable({}, { __mode = "k" }) :: any

local function attackOrigin(fighter: FighterService.Fighter): Vector3
	local serverPos = fighter.root.Position
	local report = fighter.player and clientPositions[fighter.model]
	if report and os.clock() - report.at <= CLIENT_POS_MAX_AGE and (report.pos - serverPos).Magnitude <= CLIENT_POS_MAX_DIST then
		return report.pos
	end
	return serverPos
end

local function hitboxCFrame(fighter: FighterService.Fighter, attack): CFrame
	local facing = facingOf(fighter)
	local offset = attack.hitbox.offset
	local pos = attackOrigin(fighter)
	return CFrame.new(pos.X + offset.X * facing, pos.Y + offset.Y, 0)
end

-- Guarda la posición que dice el cliente (solo números válidos).
local function storeClientPos(fighter: FighterService.Fighter, pos: any)
	if typeof(pos) == "Vector3" and pos.X == pos.X and pos.Y == pos.Y then
		clientPositions[fighter.model] = { pos = Vector3.new(pos.X, pos.Y, 0), at = os.clock() }
	end
end

local function makeDebugPart(size: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = "DebugHitbox"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Color = Color3.fromRGB(255, 40, 40)
	part.Transparency = 0.5
	part.Size = size
	part.Parent = workspace
	return part
end

-- Animaciones de ataque: se reproducen desde el servidor (se ven en todos los clientes).
-- Solo si el ataque tiene animationId (IDs en docs/ENTREGAS.md). Sin ID, no pasa nada.
local animationTracks: { [Model]: { [string]: AnimationTrack } } = {}

local function playAttackAnimation(fighter: FighterService.Fighter, attack)
	local id = attack.animationId
	if not id then
		return
	end
	local animator = fighter.humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local assetId = `rbxassetid://{id}`
	local cache = animationTracks[fighter.model]
	if not cache then
		cache = {}
		animationTracks[fighter.model] = cache
		fighter.model.Destroying:Connect(function()
			animationTracks[fighter.model] = nil
		end)
	end
	local track = cache[assetId]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = assetId
		local ok, result = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok then
			warn("[CombatService] no se pudo cargar la animación", assetId, result)
			return
		end
		track = result
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		cache[assetId] = track
	end
	track:Play(0.05)
end

-- Proyectil (pistolas): avanza cada frame desde el atacante en la dirección del
-- disparo y golpea al PRIMER luchador que toque. Lo decide el servidor.
-- Si projectile.count > 1, salen varios en abanico separados projectile.spread grados.
function CombatService.SpawnProjectile(fighter: FighterService.Fighter, attack)
	local spec = attack.projectile
	local count = spec.count or 1
	for i = 1, count do
		local offsetAngle = (i - (count + 1) / 2) * (spec.spread or 0)
		CombatService.SpawnOneProjectile(fighter, attack, (spec.angle or 0) + offsetAngle)
	end
end

function CombatService.SpawnOneProjectile(fighter: FighterService.Fighter, attack, angleDegrees: number)
	local spec = attack.projectile
	local facing = facingOf(fighter)
	local angle = math.rad(angleDegrees)
	local direction = Vector3.new(math.cos(angle) * facing, math.sin(angle), 0)
	local offset = attack.hitbox.offset
	local origin = fighter.root.Position
	local position = Vector3.new(origin.X + offset.X * facing, origin.Y + offset.Y, 0)
	local size: Vector3 = spec.size

	local visual = Instance.new("Part")
	visual.Name = "Projectile"
	visual.Anchored = true
	visual.CanCollide = false
	visual.CanQuery = false
	visual.CanTouch = false
	visual.CastShadow = false
	visual.Material = Enum.Material.Neon
	visual.Color = Color3.fromHex(spec.color or "FFFFFF")
	visual.Size = size
	visual.CFrame = CFrame.lookAt(position, position + direction)
	visual.Parent = workspace

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local traveled = 0

	task.spawn(function()
		while traveled < spec.range and visual.Parent do
			local dt = RunService.Heartbeat:Wait()
			local step = spec.speed * dt
			position += direction * step
			traveled += step
			local boxCFrame = CFrame.lookAt(position, position + direction)
			visual.CFrame = boxCFrame

			local targets = {}
			for _, model in FighterService.GetModels() do
				if model ~= fighter.model then
					table.insert(targets, model)
				end
			end
			if #targets > 0 then
				params.FilterDescendantsInstances = targets
				for _, part in workspace:GetPartBoundsInBox(boxCFrame, size, params) do
					local target = FighterService.GetFromInstance(part)
					if target then
						FighterService.ApplyHit(target, attack, facing)
						visual:Destroy()
						return
					end
				end
			end
		end
		visual:Destroy()
	end)
end

-- Ejecuta un ataque completo. Funciona igual para jugador o CPU.
-- moveName ("Jab", "Heavy"...) se publica en el modelo para que los clientes
-- dibujen la pose de ataque (PoseController): atributos Move y MoveTime.
function CombatService.PerformAttack(fighter: FighterService.Fighter, attack, moveName: string)
	fighter.attackToken += 1
	local token = fighter.attackToken
	fighter.queuedAttack = nil
	fighter.model:SetAttribute("Move", moveName)
	fighter.model:SetAttribute("MoveTime", workspace:GetServerTimeNow())
	fighter.model:SetAttribute("MoveId", token) -- identifica ESTE ataque (para las animaciones)
	FighterService.SetState(fighter, "Attacking")
	playAttackAnimation(fighter, attack)

	local function stillAttacking(): boolean
		return fighter.attackToken == token
			and fighter.model.Parent ~= nil
			and FighterService.GetState(fighter) == "Attacking"
	end

	task.spawn(function()
		-- 1. Startup
		task.wait(attack.startup)
		if not stillAttacking() then
			return
		end

		-- 2a. Ataque a distancia (pistolas): sale un proyectil y vive por su cuenta.
		if attack.projectile then
			CombatService.SpawnProjectile(fighter, attack)
		end

		-- 2b. Active: la hitbox busca objetivos cada frame (no en los disparos)
		local alreadyHit: { [Model]: boolean } = {}
		local landedHit = false
		local hitlagExtra = 0
		local debugPart = if workspace:GetAttribute("DebugHitboxes") and not attack.projectile
			then makeDebugPart(attack.hitbox.size)
			else nil
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include

		-- Golpes múltiples (firmas): el active se reparte en "hits" impactos. Los primeros
		-- solo enganchan (knockback pequeño que mantiene al rival cerca) y el último remata.
		local hits = attack.hits or 1
		local hitInterval = attack.active / hits
		local activeStart = os.clock()
		local currentTick = 0
		local lastLagTick = -1 -- el hitlag alarga el ataque una vez por impacto
		local linkAttack = nil
		if hits > 1 then
			-- Por defecto el enganche deja al rival QUIETO en el sitio (vertical y flojo):
			-- así el atacante, que avanza, lo vuelve a alcanzar con el siguiente impacto.
			linkAttack = table.clone(attack)
			linkAttack.baseKnockback = attack.linkKnockback or 6
			linkAttack.knockbackScale = 0
			linkAttack.angle = attack.linkAngle or 90
			linkAttack.activeInput = nil
		end

		-- Active input (guadaña): si MIENTRAS golpeas mantienes la dirección HACIA ATRÁS,
		-- el golpe lanza hacia atrás (ángulo reflejado). Eliges hacia dónde mandar al rival.
		-- (fighter.inputDir lo actualiza el cliente con la acción "Aim" durante el ataque.)
		local function aimed(data)
			local inputDir = fighter.inputDir
			if data.activeInput and inputDir ~= 0 and inputDir == -facingOf(fighter) then
				local mirrored = table.clone(data)
				mirrored.angle = 180 - data.angle
				return mirrored
			end
			return data
		end

		local activeEnd = os.clock() + attack.active
		while not attack.projectile and os.clock() < activeEnd and stillAttacking() do
			-- math.max: el nº de impacto NUNCA retrocede (el hitlag retrasa activeStart y,
			-- sin esto, volvía al impacto anterior y golpeaba en bucle infinito).
			local tick = math.max(currentTick, math.min(hits - 1, math.floor((os.clock() - activeStart) / hitInterval)))
			if tick ~= currentTick then
				currentTick = tick
				alreadyHit = {} -- nuevo impacto: se puede volver a golpear al mismo rival
			end
			local hitData = aimed(if linkAttack and tick < hits - 1 then linkAttack else attack)

			local boxCFrame = hitboxCFrame(fighter, attack)
			if debugPart then
				debugPart.CFrame = boxCFrame
			end

			-- Solo luchadores registrados, nunca el propio atacante.
			local targets = {}
			for _, model in FighterService.GetModels() do
				if model ~= fighter.model and not alreadyHit[model] then
					table.insert(targets, model)
				end
			end

			if #targets > 0 then
				params.FilterDescendantsInstances = targets
				local parts = workspace:GetPartBoundsInBox(boxCFrame, attack.hitbox.size, params)
				for _, part in parts do
					local target = FighterService.GetFromInstance(part)
					if target and not alreadyHit[target.model] then
						alreadyHit[target.model] = true -- un objetivo, un golpe por ataque
						local direction = facingOf(fighter)
						if attack.awayFromAttacker then
							-- Golpes a los dos lados: empujar hacia donde está el rival.
							direction = if target.root.Position.X >= fighter.root.Position.X then 1 else -1
						end
						FighterService.ApplyHit(target, hitData, direction, fighter)
						if lastLagTick ~= tick then
							lastLagTick = tick
							-- Hitlag: el ataque del atacante se "pausa" ese instante.
							-- (Se desplaza MoveTime para que la pose también se quede quieta.)
							hitlagExtra = FighterService.ComputeHitlag(hitData)
							local moveTime = fighter.model:GetAttribute("MoveTime")
							if type(moveTime) == "number" then
								fighter.model:SetAttribute("MoveTime", moveTime + hitlagExtra)
							end
							activeEnd += hitlagExtra
							activeStart += hitlagExtra -- los siguientes impactos también esperan
						end
						landedHit = true
					end
				end
			end

			-- Golpe único que ya acertó: la hitbox se apaga y empieza la recuperación YA
			-- (como en Brawlhalla: así DLight > aéreo es un combo verdadero).
			if landedHit and hits == 1 then
				-- El hitlag (atacante congelado) no debe comerse la recuperación.
				task.wait(hitlagExtra)
				break
			end
			RunService.Heartbeat:Wait()
		end
		if attack.projectile then
			task.wait(attack.active) -- el atacante sigue "disparando" durante el active
		end

		if debugPart then
			debugPart:Destroy()
		end
		if not stillAttacking() then
			return
		end

		-- 3. Recovery (más corto si el golpe acertó: así se encadenan combos)
		local recovery = attack.recovery
		if landedHit then
			recovery *= GameConfig.RecoveryOnHitMultiplier
		end
		task.wait(recovery)
		if not stillAttacking() then
			return
		end
		FighterService.SetState(fighter, "Idle")

		-- 4. Búfer: si se pidió otro ataque durante este, sale ya.
		local queued = fighter.queuedAttack
		local queuedMove = fighter.queuedMove
		fighter.queuedAttack = nil
		if queued and queuedMove and os.clock() - fighter.queuedAt <= GameConfig.AttackBufferWindow then
			fighter.inputDir = fighter.queuedDir
			local facings = attackFacings[fighter.model]
			if facings then
				facings.current = facings.queued
			end
			CombatService.PerformAttack(fighter, queued, queuedMove)
		end
	end)
end

local function onActionRequest(player: Player, payload: any)
	-- Validación: nunca confiar en lo que manda el cliente.
	if type(payload) ~= "table" then
		return
	end
	local fighter = FighterService.Get(player.Character)
	if not fighter then
		return
	end

	if payload.action == "Dodge" then
		FighterService.TryStartDodge(fighter) -- valida estado y enfriamiento
		return
	end
	if payload.action == "Aim" then
		-- Dirección mantenida durante el ataque (active input). Solo -1, 0 o 1.
		-- (el cliente solo la manda cuando cambia; sin "dir" se conserva la anterior)
		if payload.dir ~= nil then
			fighter.inputDir = if payload.dir == 1 or payload.dir == -1 then payload.dir else 0
		end
		storeClientPos(fighter, payload.pos)
		return
	end
	storeClientPos(fighter, payload.pos)
	if payload.action ~= "Attack" or type(payload.move) ~= "string" then
		return
	end
	local moveset = FighterService.GetMoveset(fighter) -- según el arma que lleva
	local attack = moveset and moveset[payload.move]
	if not attack then
		return
	end

	-- Dirección pulsada (-1, 0, 1) para el active input. Cualquier otra cosa = 0.
	local dir = if payload.dir == 1 or payload.dir == -1 then payload.dir else 0
	-- Orientación del jugador al pulsar (1 derecha, -1 izquierda).
	local facing = if payload.facing == 1 or payload.facing == -1 then payload.facing else nil
	local facings = attackFacings[fighter.model]
	if not facings then
		facings = {}
		attackFacings[fighter.model] = facings
	end

	local state = FighterService.GetState(fighter)
	if state == "Idle" then
		fighter.inputDir = dir
		facings.current = facing
		CombatService.PerformAttack(fighter, attack, payload.move)
	elseif state == "Attacking" and not attack.selfImpulse then
		-- Pedido durante otro ataque: se guarda y sale al terminar (si no caduca).
		fighter.queuedAttack = attack
		fighter.queuedMove = payload.move
		fighter.queuedDir = dir
		facings.queued = facing
		fighter.queuedAt = os.clock()
	end
end

function CombatService.Start()
	-- Valor inicial de las cajas rojas; el menú de práctica puede cambiarlo.
	workspace:SetAttribute("DebugHitboxes", GameConfig.DebugHitboxes)
	Remotes.ActionRequest.OnServerEvent:Connect(onActionRequest)
end

return CombatService
