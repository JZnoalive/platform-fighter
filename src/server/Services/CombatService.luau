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

local function getFacing(root: BasePart): number
	return if root.CFrame.LookVector.X >= 0 then 1 else -1
end

local function hitboxCFrame(fighter: FighterService.Fighter, attack): CFrame
	local facing = getFacing(fighter.root)
	local offset = attack.hitbox.offset
	local pos = fighter.root.Position
	return CFrame.new(pos.X + offset.X * facing, pos.Y + offset.Y, 0)
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
function CombatService.SpawnProjectile(fighter: FighterService.Fighter, attack)
	local spec = attack.projectile
	local facing = getFacing(fighter.root)
	local angle = math.rad(spec.angle or 0)
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

		local activeEnd = os.clock() + attack.active
		while not attack.projectile and os.clock() < activeEnd and stillAttacking() do
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
						local direction = getFacing(fighter.root)
						if attack.awayFromAttacker then
							-- Golpes a los dos lados: empujar hacia donde está el rival.
							direction = if target.root.Position.X >= fighter.root.Position.X then 1 else -1
						end
						FighterService.ApplyHit(target, attack, direction, fighter)
						if not landedHit then
							-- Hitlag: el ataque del atacante se "pausa" ese instante.
							-- (Se desplaza MoveTime para que la pose también se quede quieta.)
							hitlagExtra = FighterService.ComputeHitlag(attack)
							local moveTime = fighter.model:GetAttribute("MoveTime")
							if type(moveTime) == "number" then
								fighter.model:SetAttribute("MoveTime", moveTime + hitlagExtra)
							end
							activeEnd += hitlagExtra
						end
						landedHit = true
					end
				end
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
	if payload.action ~= "Attack" or type(payload.move) ~= "string" then
		return
	end
	local moveset = FighterService.GetMoveset(fighter) -- según el arma que lleva
	local attack = moveset and moveset[payload.move]
	if not attack then
		return
	end

	local state = FighterService.GetState(fighter)
	if state == "Idle" then
		CombatService.PerformAttack(fighter, attack, payload.move)
	elseif state == "Attacking" and not attack.selfImpulse then
		-- Pedido durante otro ataque: se guarda y sale al terminar (si no caduca).
		fighter.queuedAttack = attack
		fighter.queuedMove = payload.move
		fighter.queuedAt = os.clock()
	end
end

function CombatService.Start()
	-- Valor inicial de las cajas rojas; el menú de práctica puede cambiarlo.
	workspace:SetAttribute("DebugHitboxes", GameConfig.DebugHitboxes)
	Remotes.ActionRequest.OnServerEvent:Connect(onActionRequest)
end

return CombatService
