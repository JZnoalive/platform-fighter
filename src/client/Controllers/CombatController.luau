-- StarterPlayer.StarterPlayerScripts.Client.Controllers.CombatController
-- Decide QUÉ ataque pide el jugador según la tecla, la dirección y si está
-- en el suelo o en el aire, y se lo pide al servidor.
-- No calcula daño ni golpes: eso es del servidor.
--
--               suelo                          aire
--   Ligero  W   UpLight                        AirUpLight
--           S   DownLight                      AirDownLight
--          A/D  SideLight                      AirLight
--           -   Jab                            AirLight
--   Pesado  W   UpHeavy                        Recovery (1 vez por vuelo)
--           S   DownHeavy                      GroundPound
--          A/D  Heavy                          Heavy
--           -   Heavy                          Heavy
-- Si se pulsan W y S a la vez, gana W.
-- Esquiva (Shift / L): en el sitio, o hacia A/D (y W/S en el aire).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local ChainLogic = require(ReplicatedStorage.Shared.Modules.ChainLogic)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local InputController = require(script.Parent.InputController)
local MovementController = require(script.Parent.MovementController)
local AnimationController = require(script.Parent.AnimationController)

local CombatController = {}

local lastAttackPressAt = -math.huge -- última vez que se pidió un ataque
local lastAimDir: number? = nil -- última dirección enviada con "Aim"

-- Devuelve el nombre del ataque, o nil si no hay ninguno válido (p. ej. Recovery gastado).
-- canImpulse = false cuando se está atacando: los ataques con impulso propio
-- (Recovery, GroundPound) no se guardan en el búfer.
-- ¿Tiene el arma actual este ataque? (las armas sin cadena o sin aéreo lateral usan el básico)
local function hasMove(name: string): boolean
	local character = Players.LocalPlayer.Character
	local moveset = character and FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
	return moveset ~= nil and moveset[name] ~= nil
end

-- Cadena de ligeros: golpe 1 → 2 → 3 con pulsaciones dentro de la ventana (ChainLogic).
local chainIndex, chainAt = 0, -math.huge

local function nextChainMove(): string
	local chain = GameConfig.LightChain
	-- Longitud real: solo los golpes que tiene esta arma (si no tiene Jab2, siempre Jab).
	local length = 0
	for _, name in chain.Moves do
		if hasMove(name) then
			length += 1
		else
			break
		end
	end
	local now = os.clock()
	chainIndex = ChainLogic.NextIndex(chainIndex, chainAt, now, chain.Window, math.max(length, 1))
	chainAt = now
	return chain.Moves[chainIndex] or "Jab"
end

local function chooseMove(action: string, canImpulse: boolean): string?
	local grounded = MovementController.IsGrounded()
	local up = InputController.IsUpHeld()
	local down = InputController.IsDownHeld() and not up

	if action == "Light" then
		if grounded then
			if up then
				chainIndex = 0
				return "UpLight" -- lanzador vertical
			elseif down then
				chainIndex = 0
				return "DownLight" -- barrido / iniciador bajo
			elseif InputController.GetMoveX() ~= 0 then
				chainIndex = 0
				return "SideLight" -- más avance horizontal
			end
			return nextChainMove() -- cadena neutra de 3 golpes
		end
		chainIndex = 0
		if up then
			return "AirUpLight"
		elseif down then
			return "AirDownLight"
		elseif InputController.GetMoveX() ~= 0 and hasMove("AirSideLight") then
			return "AirSideLight" -- aéreo lateral (distinto del neutro)
		end
		return "AirLight"
	end

	-- Pesado
	if grounded then
		if up then
			return "UpHeavy"
		elseif down then
			return "DownHeavy"
		end
		return "Heavy"
	end
	if up then
		if not canImpulse then
			return nil
		end
		return if MovementController.TryUseRecovery() then "Recovery" else nil
	elseif down then
		return if canImpulse then "GroundPound" else nil
	end
	return "Heavy"
end

function CombatController.Start()
	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local actionRequest = remotes:WaitForChild("ActionRequest") :: RemoteEvent

		-- Active input: mientras atacas, avisar al servidor si cambias la dirección
		-- (A/D) para que el golpe lance hacia donde mantienes. Solo cuando cambia.
		-- Además manda la posición REAL del personaje (el servidor la ve con retraso):
		-- así la hitbox sale donde estás de verdad en los combos aéreos.
		-- (también justo después de pulsar: la confirmación "Attacking" llega con retraso)
		RunService.Heartbeat:Connect(function()
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				return
			end
			if character:GetAttribute("State") ~= "Attacking" and os.clock() - lastAttackPressAt > 0.4 then
				lastAimDir = nil
				return
			end
			-- La dirección solo se manda cuando CAMBIA; la posición, cada frame.
			local dir = InputController.GetMoveX()
			local payload = { action = "Aim", pos = root.Position, dir = nil :: number? }
			if dir ~= lastAimDir then
				lastAimDir = dir
				payload.dir = dir
			end
			actionRequest:FireServer(payload)
		end)

		InputController.OnPress(function(action)
			local character = Players.LocalPlayer.Character
			local state = character and character:GetAttribute("State")

			-- Esquiva (Shift / L): solo desde Idle. Dirección con A/D (y W/S en el aire).
			if action == "Dodge" then
				-- Desde Idle, o durante un ataque que ACABA de acertar (chase dodge).
				local chase = state == "Attacking" and MovementController.LandedHitRecently()
				if (state ~= "Idle" and not chase) or not MovementController.CanDodge() then
					return
				end
				actionRequest:FireServer({ action = "Dodge" })
				local dirY = if InputController.IsUpHeld()
					then 1
					elseif InputController.IsDownHeld() then -1
					else 0
				MovementController.StartDodge(InputController.GetMoveX(), dirY)
				return
			end

			-- Idle: ataque normal. Attacking: el servidor lo guarda en su búfer (combos).
			-- Hitstun, KO, reapareciendo...: no se pide nada.
			if state ~= "Idle" and state ~= "Attacking" then
				return
			end

			local isIdle = state == "Idle"
			local moveName = chooseMove(action, isIdle)
			if not moveName then
				return
			end

			-- dir: dirección pulsada (para el "active input" de la guadaña)
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			lastAttackPressAt = os.clock()
			actionRequest:FireServer({
				action = "Attack",
				move = moveName,
				dir = InputController.GetMoveX(),
				pos = if root then root.Position else nil,
				facing = MovementController.GetFacing(),
			})

			local moveset = FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
			local attack = moveset and moveset[moveName]
			if isIdle and attack then
				-- Desde YA cuenta como atacando en mi pantalla (no girar, no caminar), sin
				-- esperar a que el servidor lo confirme.
				MovementController.NotifyAttackStarted(math.min(attack.startup + attack.active, 0.35))
			end
			if isIdle then
				-- Respuesta instantánea: la animación empieza ya en mi pantalla.
				AnimationController.PredictAttack(moveName)
			end

			-- Impulso propio (Recovery, GroundPound, embestidas): lo aplica el cliente
			-- porque el jugador es dueño de la física de su personaje.
			-- impulseAtStartup = la embestida sale cuando sale el golpe, no al pulsar.
			if isIdle and attack and attack.selfImpulse then
				local impulse = attack.selfImpulse
				if attack.impulseAtStartup then
					task.delay(attack.startup, function()
						if character:GetAttribute("State") == "Attacking" then
							MovementController.ApplySelfImpulse(impulse.X, impulse.Y)
						end
					end)
				else
					MovementController.ApplySelfImpulse(impulse.X, impulse.Y)
				end
			end
		end)
	end)
end

return CombatController
