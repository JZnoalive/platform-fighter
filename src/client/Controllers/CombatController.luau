-- StarterPlayer.StarterPlayerScripts.Client.Controllers.CombatController
-- Decide QUÉ ataque pide el jugador según la tecla y la situación,
-- y se lo pide al servidor. No calcula daño ni golpes: eso es del servidor.
--   Ligero en el aire          → AirLight
--   Ligero + A/D en el suelo   → SideLight
--   Ligero sin dirección       → Jab
--   Pesado                     → Heavy

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputController = require(script.Parent.InputController)

local CombatController = {}

local function chooseMove(action: string, humanoid: Humanoid): string
	if action == "Heavy" then
		return "Heavy"
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return "AirLight"
	end
	if InputController.GetMoveX() ~= 0 then
		return "SideLight"
	end
	return "Jab"
end

function CombatController.Start()
	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local actionRequest = remotes:WaitForChild("ActionRequest") :: RemoteEvent

		InputController.OnPress(function(action)
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid or character:GetAttribute("State") ~= "Idle" then
				return -- atacando o en hitstun: no se pide nada
			end
			actionRequest:FireServer({ action = "Attack", move = chooseMove(action, humanoid) })
		end)
	end)
end

return CombatController
