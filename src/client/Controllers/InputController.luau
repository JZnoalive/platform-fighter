-- StarterPlayer.StarterPlayerScripts.Client.Controllers.InputController
-- Traduce teclas a acciones del juego. El resto del código solo pregunta
-- por acciones ("¿quiere saltar?"), nunca por teclas concretas.
-- Así luego se pueden añadir mando y controles táctiles sin tocar el movimiento.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InputController = {}

local KEYMAP: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.A] = "Left",
	[Enum.KeyCode.Left] = "Left",
	[Enum.KeyCode.D] = "Right",
	[Enum.KeyCode.Right] = "Right",
	[Enum.KeyCode.S] = "Down",
	[Enum.KeyCode.Down] = "Down",
	[Enum.KeyCode.Space] = "Jump",
	[Enum.KeyCode.W] = "Jump",
	[Enum.KeyCode.Up] = "Jump",
}

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

local function disableDefaultControls()
	-- Apaga los controles de Roblox (WASD + salto) para usar los nuestros.
	local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
	local ok, err = pcall(function()
		local PlayerModule = require(playerScripts:WaitForChild("PlayerModule") :: ModuleScript)
		PlayerModule:GetControls():Disable()
	end)
	if not ok then
		warn("[InputController] no se pudieron apagar los controles por defecto:", err)
	end
end

function InputController.Start()
	disableDefaultControls()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return -- está escribiendo en el chat, etc.
		end
		local action = KEYMAP[input.KeyCode]
		if not action then
			return
		end
		if action == "Jump" and not held.Jump then
			lastJumpPressedAt = os.clock()
		end
		held[action] = true
	end)

	UserInputService.InputEnded:Connect(function(input)
		local action = KEYMAP[input.KeyCode]
		if action then
			held[action] = false
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
