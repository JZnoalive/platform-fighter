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
local InputController = require(script.Parent.InputController)
local MovementController = require(script.Parent.MovementController)
local AnimationController = require(script.Parent.AnimationController)

local CombatController = {}

local lastAttackPressAt = -math.huge -- última vez que se pidió un ataque
local lastAimDir: number? = nil -- última dirección enviada con "Aim"

-- Devuelve el nombre del ataque, o nil si no hay ninguno válido (p. ej. Recovery gastado).
-- canImpulse = false cuando se está atacando: los ataques con impulso propio
-- (Recovery, GroundPound) no se guardan en el búfer.
local function chooseMove(action: string, canImpulse: boolean): string?
	local grounded = MovementController.IsGrounded()
	local up = InputController.IsUpHeld()
	local down = InputController.IsDownHeld() and not up

	if action == "Light" then
		if grounded then
			if up then
				return "UpLight"
			elseif down then
				return "DownLight"
			elseif InputController.GetMoveX() ~= 0 then
				return "SideLight"
			end
			return "Jab"
		end
		if up then
			return "AirUpLight"
		elseif down then
			return "AirDownLight"
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
				if state ~= "Idle" or not MovementController.CanDodge() then
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
