-- StarterPlayer.StarterPlayerScripts.Client.Controllers.InputController
-- Traduce teclas a acciones del juego. El resto del código solo pregunta
-- por acciones ("¿quiere saltar?"), nunca por teclas concretas.
-- Así luego se pueden añadir mando y controles táctiles sin tocar el movimiento.
--
-- Usa ContextActionService con prioridad alta y "Sink": nuestras acciones se
-- quedan con las teclas y los controles por defecto de Roblox ya no las reciben.
-- (No dependemos de PlayerModule, que no siempre existe.)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)

local InputController = {}

local BINDINGS: { [string]: { any } } = {
	Left = { Enum.KeyCode.A, Enum.KeyCode.Left },
	Right = { Enum.KeyCode.D, Enum.KeyCode.Right },
	Up = { Enum.KeyCode.W, Enum.KeyCode.Up },
	Down = { Enum.KeyCode.S, Enum.KeyCode.Down },
	Jump = { Enum.KeyCode.Space },
	Light = { Enum.KeyCode.J, Enum.UserInputType.MouseButton1 },
	Heavy = { Enum.KeyCode.K, Enum.UserInputType.MouseButton2 },
	Dodge = { Enum.KeyCode.LeftShift, Enum.KeyCode.L },
}

-- Acciones que avisan en el momento de pulsar (ataques y esquiva).
local PRESS_ACTIONS = { Light = true, Heavy = true, Dodge = true }

local PRIORITY = Enum.ContextActionPriority.High.Value + 1

local held = {
	Left = false,
	Right = false,
	Up = false,
	Down = false,
	Jump = false,
	Light = false,
	Heavy = false,
	Dodge = false,
}
local lastJumpPressedAt = -math.huge
local tapJumpAt: number? = nil -- W pulsada: salto pendiente durante TapJumpWindow
local pressListeners: { (string, string) -> () } = {}
local diagnosticListeners: { (string) -> () } = {}
local lastActionPressAt = -math.huge -- última pulsación que SÍ llegó a nuestras acciones

-- ¿Está pulsada DE VERDAD alguna tecla de esta acción? Se pregunta al teclado/ratón
-- en el momento, en vez de fiarse solo de "pulsó / soltó": si Roblox pierde el aviso de
-- soltar (soltar el ratón encima del menú, cambiar de ventana...), la tecla se quedaba
-- "pegada" y J dejaba de funcionar o W/S convertían J en otro ataque.
local function isDown(action: string): boolean
	if not held[action] then
		return false
	end
	for _, input in BINDINGS[action] do
		if input.EnumType == Enum.KeyCode then
			if UserInputService:IsKeyDown(input) then
				return true
			end
		elseif UserInputService:IsMouseButtonPressed(input) then
			return true
		end
	end
	held[action] = false -- estaba "pegada": se corrige
	return false
end

-- ¿Está mantenida esta acción ahora mismo? (p. ej. "Light" para la cadena manteniendo J)
function InputController.IsHeld(action: string): boolean
	return isDown(action)
end

-- Diagnóstico: avisa si una tecla de ataque llegó pero la capturó la interfaz
-- (un cuadro de texto con el foco, el chat...). Así se sabe si "J no llega".
function InputController.OnDiagnostic(callback: (string) -> ())
	table.insert(diagnosticListeners, callback)
end

function InputController.GetMoveX(): number
	return (if isDown("Right") then 1 else 0) - (if isDown("Left") then 1 else 0)
end

function InputController.IsUpHeld(): boolean
	return isDown("Up")
end

function InputController.IsDownHeld(): boolean
	return isDown("Down")
end

function InputController.HasBufferedJump(buffer: number): boolean
	local now = os.clock()
	-- W ("tap jump"): si pasó la ventana sin pulsar ataque, se convierte en salto.
	if tapJumpAt and now - tapJumpAt >= MovementConfig.TapJumpWindow then
		lastJumpPressedAt = now
		tapJumpAt = nil
	end
	return now - lastJumpPressedAt <= buffer
end

function InputController.ClearJump()
	lastJumpPressedAt = -math.huge
	tapJumpAt = nil
end

-- Registra una función que se llama con "Light", "Heavy" o "Dodge" al pulsar.
function InputController.OnPress(callback: (string, string) -> ())
	table.insert(pressListeners, callback)
end

local function keyName(inputObject: InputObject?): string
	if not inputObject then
		return "?"
	end
	if inputObject.KeyCode ~= Enum.KeyCode.Unknown then
		return inputObject.KeyCode.Name
	end
	return inputObject.UserInputType.Name
end

function InputController.Start()
	for action, inputs in BINDINGS do
		ContextActionService:BindActionAtPriority("PF_" .. action, function(_, state, inputObject)
			if state == Enum.UserInputState.Begin then
				if action == "Jump" and not held.Jump then
					lastJumpPressedAt = os.clock() -- Space: salto inmediato
				end
				if action == "Up" and not held.Up then
					tapJumpAt = os.clock() -- W: salto tras TapJumpWindow, salvo que llegue un ataque
				end
				-- Cada pulsación nueva cuenta (no se exige haber "soltado" antes: si se perdió
				-- el aviso de soltar, la tecla ya no queda bloqueada).
				if PRESS_ACTIONS[action] then
					-- W + ataque casi a la vez = ataque hacia arriba, sin saltar.
					tapJumpAt = nil
					lastActionPressAt = os.clock()
					for _, callback in pressListeners do
						task.spawn(callback, action, keyName(inputObject))
					end
				end
				held[action] = true
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				held[action] = false
			end
			return Enum.ContextActionResult.Sink
		end, false, PRIORITY, table.unpack(inputs))
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed and (input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.K) then
			-- Nuestras acciones también la marcan como "usada": solo es un problema si NO
			-- llegó a ellas (otro elemento de la interfaz se la quedó).
			local pressedAt = os.clock()
			task.delay(0.05, function()
				if lastActionPressAt >= pressedAt - 0.05 then
					return
				end
				for _, callback in diagnosticListeners do
					task.spawn(callback, input.KeyCode.Name .. " llegó pero la capturó la interfaz (cuadro de texto o chat con el foco)")
				end
			end)
		end
	end)

	-- Si la ventana pierde el foco, se sueltan todas las teclas.
	UserInputService.WindowFocusReleased:Connect(function()
		for action in held do
			held[action] = false
		end
	end)
end

return InputController
