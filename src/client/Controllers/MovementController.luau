-- StarterPlayer.StarterPlayerScripts.Client.Controllers.MovementController
-- M1: mantiene al personaje local en el plano Z = 0 y mirando a izquierda o derecha.
-- El movimiento propio (velocidades, saltos) llega en M2.
-- Corre en el cliente porque Roblox da al jugador la física de su propio personaje.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementController = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local facing = 1 -- 1 = derecha (+X), -1 = izquierda (-X)

function MovementController.GetFacing(): number
	return facing
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.AutoRotate = false
end

function MovementController.Start()
	local player = Players.LocalPlayer
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			return
		end

		local moveX = humanoid.MoveDirection.X
		if moveX > 0.1 then
			facing = 1
		elseif moveX < -0.1 then
			facing = -1
		end

		local pos = root.Position
		local rotation = if facing == 1 then FACE_RIGHT else FACE_LEFT
		root.CFrame = CFrame.new(pos.X, pos.Y, 0) * rotation

		local vel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y, 0)
		root.AssemblyAngularVelocity = Vector3.zero
	end)
end

return MovementController
