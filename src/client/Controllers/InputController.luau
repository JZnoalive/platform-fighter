-- StarterPlayer.StarterPlayerScripts.Client.Controllers.InputController
-- Traduce teclas a acciones del juego. El resto del código solo pregunta
-- por acciones ("¿quiere saltar?"), nunca por teclas concretas.
-- Así luego se pueden añadir mando y controles táctiles sin tocar el movimiento.
--
-- Usa ContextActionService con prioridad alta y "Sink": nuestras acciones se
-- quedan con las teclas y los controles por defecto de Roblox ya no las reciben.
-- (No dependemos de PlayerModule, que no siempre existe.)

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local InputController = {}

local BINDINGS: { [string]: { Enum.KeyCode } } = {
	Left = { Enum.KeyCode.A, Enum.KeyCode.Left },
	Right = { Enum.KeyCode.D, Enum.KeyCode.Right },
	Down = { Enum.KeyCode.S, Enum.KeyCode.Down },
	Jump = { Enum.KeyCode.Space, Enum.KeyCode.W, Enum.KeyCode.Up },
}

local PRIORITY = Enum.ContextActionPriority.High.Value + 1

local held = { Left = false, Right = false, Down = false, Jump = false }
local lastJumpPressedAt = -math.huge

function InputController.GetMoveX(): number
	return (if held.Right then 1 else 0) - (if held.Left then 1 else 0)
end

function InputController.IsDownHeld(): boolean
	return held.Down
end

function InputController.HasBufferedJump(buffer: number): boolean
	return os.clock() - lastJumpPressedAt <= buffer
end

function InputController.ClearJump()
	lastJumpPressedAt = -math.huge
end

function InputController.Start()
	for action, keys in BINDINGS do
		ContextActionService:BindActionAtPriority("PF_" .. action, function(_, state)
			if state == Enum.UserInputState.Begin then
				if action == "Jump" and not held.Jump then
					lastJumpPressedAt = os.clock()
				end
				held[action] = true
			elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
				held[action] = false
			end
			return Enum.ContextActionResult.Sink
		end, false, PRIORITY, table.unpack(keys))
	end

	-- Si la ventana pierde el foco, se sueltan todas las teclas.
	UserInputService.WindowFocusReleased:Connect(function()
		for action in held do
			held[action] = false
		end
	end)
end

return InputController
