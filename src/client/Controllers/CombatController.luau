-- StarterPlayer.StarterPlayerScripts.Client.Controllers.CombatController
-- Decide QUÉ ataque pide el jugador según la tecla, la dirección y si está
-- en el suelo o en el aire, y se lo pide al servidor.
-- No calcula daño ni golpes: eso es del servidor.
--
--               suelo                          aire
--   Ligero  W   UpLight                        AirUpLight
--           S   DownLight                      AirDownLight
--          A/D  SideLight                      AirSideLight (o AirLight)
--           -   CADENA Jab > Jab2 > Jab3       AirLight
--   Pesado  W   UpHeavy                        Recovery (1 vez por vuelo)
--           S   DownHeavy                      GroundPound
--          A/D  Heavy                          Heavy
--           -   Heavy                          Heavy
-- Si se pulsan W y S a la vez, gana W.
-- Esquiva (Shift / L): en el sitio, o hacia A/D (y W/S en el aire).
--
-- CADENA DE LIGEROS (J sin dirección, en el suelo):
--   · Pulsar J durante un golpe de la cadena → el siguiente queda en el búfer y sale al
--     terminar el actual (1 solo en el búfer).
--   · Pulsar J hasta GameConfig.LightChain.Window s DESPUÉS de que termine el golpe →
--     sigue la cadena. Más tarde → vuelve al golpe 1.
--   · MANTENER J también encadena los 3 golpes (se suelta para volver a empezar).
--   · El índice de la cadena sale del ataque que el SERVIDOR está ejecutando de verdad
--     (atributo Move), no de contar pulsaciones: así no se desincroniza.
-- Cada paso y cada motivo de rechazo se muestran en el panel ENTRADA (DebugController).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local InputController = require(script.Parent.InputController)
local MovementController = require(script.Parent.MovementController)
local AnimationController = require(script.Parent.AnimationController)
local DebugController = require(script.Parent.DebugController)

local CombatController = {}

local lastAttackPressAt = -math.huge -- última vez que se pidió un ataque
local lastAimDir: number? = nil -- última dirección enviada con "Aim"

local function log(text: string, kind: string?)
	DebugController.LogInput(text, kind)
end

local function getMoveset()
	local character = Players.LocalPlayer.Character
	return character and FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
end

-- ¿Tiene el arma actual este ataque? (las armas sin cadena o sin aéreo lateral usan el básico)
local function hasMove(name: string): boolean
	local moveset = getMoveset()
	return moveset ~= nil and moveset[name] ~= nil
end

---------------------------------------------------------------- CADENA
local CHAIN = GameConfig.LightChain

local function chainIndexOf(name: any): number?
	return if type(name) == "string" then table.find(CHAIN.Moves, name) else nil
end

-- Longitud real: solo los golpes que tiene esta arma (si no tiene Jab2, siempre Jab).
local function chainLength(): number
	local length = 0
	for _, name in CHAIN.Moves do
		if hasMove(name) then
			length += 1
		else
			break
		end
	end
	return math.max(length, 1)
end

local chainCurrent = 0 -- golpe de la cadena en curso / último (lo confirma el servidor)
local chainEndedAt = -math.huge -- cuándo terminó el último golpe de la cadena
local chainQueued = false -- ya hay un golpe de la cadena guardado en el búfer
-- Ataque pedido que el servidor aún no confirmó (para detectar si lo rechaza).
local pending: { move: string, index: number?, at: number }? = nil
local holdChain = false -- J mantenida desde un golpe de la cadena
-- Última entrada (para la línea de estado del panel ENTRADA)
local lastInput: { key: string, at: number, dir: string, requested: string, selected: string, reason: string }? = nil
local lightPressedAt = -math.huge
local HOLD_DELAY = 0.22 -- mantener J más que esto = cadena automática (un toque normal dura menos)

-- Siguiente golpe de la cadena. Devuelve (ataque, índice, nota) o (nil, nil, motivo).
local function nextChain(state: string?): (string?, number?, string?)
	local character = Players.LocalPlayer.Character
	local length = chainLength()
	local now = os.clock()
	local busy = state == "Attacking" or pending ~= nil
	if busy then
		local current = if pending then pending.index else chainIndexOf(character and character:GetAttribute("Move"))
		if not current then
			local name = if pending then pending.move else tostring(character and character:GetAttribute("Move"))
			return nil, nil, `ataque bloqueado: estás en {name} (no es de la cadena)`
		end
		if chainQueued then
			return nil, nil, "ataque bloqueado: ya hay un golpe guardado en el búfer"
		end
		if current >= length then
			return nil, nil, `ataque bloqueado: {CHAIN.Moves[length]} en curso (la cadena termina en {length})`
		end
		return CHAIN.Moves[current + 1], current + 1, "va al búfer: sale al terminar el golpe actual"
	end
	if chainCurrent >= 1 and chainCurrent < length then
		local since = now - chainEndedAt
		if since <= CHAIN.Window then
			return CHAIN.Moves[chainCurrent + 1], chainCurrent + 1, string.format("dentro de ventana (%.2f s)", since)
		end
		return CHAIN.Moves[1], 1, string.format("fuera de ventana (%.2f s > %.2f s): vuelve a CHAIN 1", since, CHAIN.Window)
	end
	return CHAIN.Moves[1], 1, if chainCurrent >= length then "cadena completa: empieza de nuevo" else nil
end

-- Devuelve (ataque, índice de cadena, nota/motivo). Ataque nil = no hay ataque válido.
-- canImpulse = false cuando se está atacando: los ataques con impulso propio
-- (Recovery, GroundPound) no se guardan en el búfer.
local function chooseMove(action: string, canImpulse: boolean, state: string?): (string?, number?, string?)
	local grounded = MovementController.IsGrounded()
	local up = InputController.IsUpHeld()
	local down = InputController.IsDownHeld() and not up
	local moveX = InputController.GetMoveX()

	if action == "Light" then
		if grounded then
			if up then
				return "UpLight", nil, "dirección: W pulsada → ataque hacia arriba (suelta W para la cadena)"
			elseif down then
				return "DownLight", nil, "dirección: S pulsada → ataque abajo (suelta S para la cadena)"
			elseif moveX ~= 0 then
				return "SideLight", nil,
					`dirección: {if moveX > 0 then "D" else "A"} pulsada → ataque lateral (suelta A/D para la cadena)`
			end
			return nextChain(state) -- cadena neutra de 3 golpes
		end
		local note = "en el aire: los aéreos no son la cadena"
		if up then
			return "AirUpLight", nil, note
		elseif down then
			return "AirDownLight", nil, note
		elseif moveX ~= 0 and hasMove("AirSideLight") then
			return "AirSideLight", nil, note
		end
		return "AirLight", nil, note
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
			return nil, nil, "ataque bloqueado: el Recovery no se guarda en el búfer"
		end
		if MovementController.TryUseRecovery() then
			return "Recovery"
		end
		return nil, nil, "Recovery ya gastado (se recarga al aterrizar o al recibir un golpe)"
	elseif down then
		if canImpulse then
			return "GroundPound"
		end
		return nil, nil, "ataque bloqueado: GroundPound no se guarda en el búfer"
	end
	return "Heavy"
end

-- Rival más cercano (en la sala de prueba, la CPU).
local function rivalModel(): Model?
	local me = Players.LocalPlayer.Character
	for _, model in CollectionService:GetTagged("CameraTarget") do
		if model ~= me and model:IsA("Model") and model:GetAttribute("FighterId") then
			return model
		end
	end
	return nil
end

-- Aviso si el rival no está al alcance del ataque (no impide atacar).
local function rangeWarning(attack, root: BasePart): string?
	local rival = rivalModel()
	local rivalRoot = rival and rival:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rivalRoot or not attack.hitbox then
		return nil
	end
	local facing = MovementController.GetFacing()
	local dx = (rivalRoot.Position.X - root.Position.X) * facing
	local lunge = if attack.lunge then attack.lunge.speed * attack.lunge.time else 0
	local reach = attack.hitbox.offset.X + attack.hitbox.size.X / 2 + lunge + 1 -- +1 = medio cuerpo del rival
	if dx < -1 then
		return string.format("rival DETRÁS (a %.1f studs): date la vuelta", -dx)
	elseif dx > reach then
		return string.format("rival fuera de rango (%.1f studs, alcance %.1f)", dx, reach)
	end
	return nil
end

function CombatController.Start()
	InputController.OnDiagnostic(function(message)
		log("INPUT NO RECIBIDO: " .. message, "fail")
	end)

	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local actionRequest = remotes:WaitForChild("ActionRequest") :: RemoteEvent
		local hitEvent = remotes:WaitForChild("HitEvent") :: RemoteEvent

		local function handlePress(action: string, key: string)
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

			if action == "Light" and not string.find(key, "mantenida") then
				lightPressedAt = os.clock()
			end
			local dirX = InputController.GetMoveX()
			local dirText = if InputController.IsUpHeld()
				then "arriba"
				elseif InputController.IsDownHeld() then "abajo"
				elseif dirX > 0 then "derecha"
				elseif dirX < 0 then "izquierda"
				else "ninguna"
			log(string.format("INPUT %s · dir %s · estado %s · %s", key, dirText, tostring(state),
				if MovementController.IsGrounded() then "suelo" else "aire"), "input")
			lastInput = {
				key = key,
				at = os.clock(),
				dir = dirText,
				requested = if action == "Light" then "ligero (J)" else "pesado (K)",
				selected = "-",
				reason = "",
			}

			-- Idle: ataque normal. Attacking: el servidor lo guarda en su búfer (combos).
			-- Hitstun, KO, reapareciendo...: no se pide nada.
			if not character or (state ~= "Idle" and state ~= "Attacking") then
				log(`estado incorrecto: {tostring(state)} (solo se ataca en Idle o durante otro ataque)`, "fail")
				if lastInput then
					lastInput.reason = "RECHAZADO: estado incorrecto (" .. tostring(state) .. ")"
				end
				return
			end

			local isIdle = state == "Idle" and pending == nil
			local moveName, chainIndex, note = chooseMove(action, state == "Idle", state)
			if not moveName then
				log(note or "sin ataque válido", "fail")
				if lastInput then
					lastInput.reason = "RECHAZADO: " .. (note or "sin ataque válido")
				end
				return
			end
			if lastInput then
				lastInput.selected = moveName .. (if chainIndex then " · CHAIN " .. chainIndex else "")
				lastInput.reason = note or ""
			end

			local moveset = getMoveset()
			local attack = moveset and moveset[moveName]
			local weapon = character:GetAttribute("Weapon") or "?"
			log(string.format("ATTACK %s %s%s", tostring(weapon), moveName,
				if chainIndex then string.format(" (Light %d)", chainIndex) else ""), "ok")
			if chainIndex then
				log(string.format("CHAIN %d%s", chainIndex, if note then " · " .. note else ""), "ok")
				chainCurrent = chainIndex
				holdChain = action == "Light"
				if not isIdle then
					chainQueued = true
				end
			else
				if action == "Light" or action == "Heavy" then
					chainCurrent = 0 -- otro ataque corta la cadena
					holdChain = false
				end
				if note then
					log(note, "info")
				end
			end

			-- dir: dirección pulsada (para el "active input" de la guadaña)
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and attack and isIdle then
				local warning = rangeWarning(attack, root)
				if warning then
					log(warning, "fail")
				end
			end
			lastAttackPressAt = os.clock()
			if isIdle then
				pending = { move = moveName, index = chainIndex, at = os.clock() }
			end
			actionRequest:FireServer({
				action = "Attack",
				move = moveName,
				dir = dirX,
				pos = if root then root.Position else nil,
				facing = MovementController.GetFacing(),
			})

			if isIdle and attack then
				-- Desde YA cuenta como atacando en mi pantalla (no girar, no caminar), sin
				-- esperar a que el servidor lo confirme.
				MovementController.NotifyAttackStarted(math.min(attack.startup + attack.active, 0.35))
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
		end

		InputController.OnPress(handlePress)

		-- Lo que confirma el SERVIDOR: qué ataque ejecuta, cuándo termina y si acierta.
		local prevState: any = nil
		local prevMoveId: any = nil
		local prevMove: any = nil
		local queueCheckAt: number? = nil
		RunService.Heartbeat:Connect(function()
			local character = Players.LocalPlayer.Character
			if not character then
				return
			end
			local now = os.clock()
			local state = character:GetAttribute("State")
			local move = character:GetAttribute("Move")
			local moveId = character:GetAttribute("MoveId")
			-- (MoveId puede llegar un fotograma antes que State = "Attacking": se espera a los dos)
			if moveId ~= prevMoveId and state == "Attacking" and move then
				prevMoveId = moveId
				local index = chainIndexOf(move)
				chainQueued = false
				queueCheckAt = nil -- el golpe guardado ya salió
				if index then
					chainCurrent = index
				end
				log(string.format("SERVIDOR ejecuta %s%s", tostring(move),
					if index then string.format(" (CHAIN %d)", index) else ""), "ok")
				pending = nil
			end
			if prevState == "Attacking" and state ~= "Attacking" and chainIndexOf(prevMove) then
				chainEndedAt = now
				local endedIndex = chainIndexOf(prevMove) :: number
				if endedIndex < chainLength() and not chainQueued then
					log(string.format("ventana abierta %.2f s → pulsa J para CHAIN %d", CHAIN.Window, endedIndex + 1), "info")
				end
				if chainQueued then
					-- El servidor pasa un instante por Idle antes de lanzar el golpe guardado:
					-- se comprueba un poco después si de verdad salió.
					queueCheckAt = now + 0.3
				end
			end
			if queueCheckAt and now >= queueCheckAt then
				queueCheckAt = nil
				if chainQueued then
					log("el golpe del búfer no salió (pulsado demasiado pronto: el búfer dura "
						.. GameConfig.AttackBufferWindow .. " s antes del final del golpe)", "fail")
					chainQueued = false
				end
			end
			prevState = state
			prevMove = move
			if pending and now - pending.at > 0.5 then
				log(`el SERVIDOR no ejecutó {pending.move} (estado en el servidor: {tostring(state)})`, "fail")
				if pending.index then
					chainCurrent = math.max(pending.index - 1, 0)
				end
				pending = nil
			end

			-- Línea de estado del panel: última tecla, ataque y cuánto le queda a la ventana.
			local window
			if (state == "Attacking" or pending) and chainIndexOf(if pending then pending.move else move) then
				window = if chainQueued then "siguiente golpe ya en el búfer" else "abierta (búfer: pulsa J ya)"
			elseif state == "Idle" and chainCurrent >= 1 and chainCurrent < chainLength() then
				local left = CHAIN.Window - (now - chainEndedAt)
				window = if left > 0 then string.format("%.2f s para CHAIN %d", left, chainCurrent + 1) else "cerrada (vuelve a CHAIN 1)"
			else
				window = "cerrada"
			end
			local status
			if lastInput then
				status = string.format(
					"Última: <b>%s</b> hace %.1f s · dir %s · estado %s\nSolicitado: %s → elegido: <b>%s</b>\nCadena: %d · ventana: <b>%s</b>%s",
					lastInput.key, now - lastInput.at, lastInput.dir, tostring(state), lastInput.requested,
					lastInput.selected, chainCurrent, window,
					if lastInput.reason ~= "" then "\nMotivo: " .. lastInput.reason else "")
			else
				status = "Última: (ninguna tecla todavía) · ventana: " .. window
			end
			DebugController.SetInputStatus(status .. "\n──────────")

			-- MANTENER J: pide el siguiente golpe de la cadena (al búfer) sin volver a pulsar.
			if holdChain and not InputController.IsHeld("Light") then
				holdChain = false
			end
			if holdChain and now - lightPressedAt >= HOLD_DELAY and not chainQueued and (state == "Attacking" or pending) and chainCurrent >= 1
				and chainCurrent < chainLength() and chainIndexOf(if pending then pending.move else move)
			then
				handlePress("Light", "J (mantenida)")
			end
		end)

		-- Aciertos del jugador: confirma que el golpe conectó y el combo del rival.
		hitEvent.OnClientEvent:Connect(function(target, _position, _force, _duration, attacker)
			if attacker ~= Players.LocalPlayer.Character or typeof(target) ~= "Instance" then
				return
			end
			local moveName = tostring(attacker:GetAttribute("Move"))
			task.delay(0.05, function()
				local combo = target:GetAttribute("ComboHits") or 0
				log(string.format("HIT OK %s · rival combo x%d · %d%%", moveName, combo,
					math.floor(target:GetAttribute("Percent") or 0)), "ok")
			end)
		end)

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
	end)
end

return CombatController
