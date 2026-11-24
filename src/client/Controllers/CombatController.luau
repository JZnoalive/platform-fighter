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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)
local InputController = require(script.Parent.InputController)
local MovementController = require(script.Parent.MovementController)

local CombatController = {}

-- Devuelve el nombre del ataque, o nil si no hay ninguno válido (p. ej. Recovery gastado).
local function chooseMove(action: string): string?
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
		return if MovementController.TryUseRecovery() then "Recovery" else nil
	elseif down then
		return "GroundPound"
	end
	return "Heavy"
end

function CombatController.Start()
	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local actionRequest = remotes:WaitForChild("ActionRequest") :: RemoteEvent

		InputController.OnPress(function(action)
			local character = Players.LocalPlayer.Character
			if not character or character:GetAttribute("State") ~= "Idle" then
				return -- atacando, en hitstun o reapareciendo: no se pide nada
			end

			local moveName = chooseMove(action)
			if not moveName then
				return
			end

			actionRequest:FireServer({ action = "Attack", move = moveName })

			-- Impulso propio (Recovery, GroundPound): lo aplica el cliente porque
			-- el jugador es dueño de la física de su personaje.
			local moveset = Movesets[character:GetAttribute("FighterId")]
			local attack = moveset and moveset[moveName]
			if attack and attack.selfImpulse then
				MovementController.ApplySelfImpulse(attack.selfImpulse.X, attack.selfImpulse.Y)
			end
		end)
	end)
end

return CombatController
