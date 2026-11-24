-- StarterPlayer.StarterPlayerScripts.Client.Controllers.MovementController
-- Movimiento del personaje local: correr con aceleración, salto, saltos aéreos,
-- caída máxima, bloqueo en el plano Z = 0 y knockback recibido (hitstun).
-- Corre en el cliente porque Roblox da al jugador la física de su propio personaje.
-- Todos los números están en Shared.Config.MovementConfig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local InputController = require(script.Parent.InputController)

local MovementController = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local facing = 1 -- 1 = derecha (+X), -1 = izquierda (-X)
local speedX = 0 -- velocidad horizontal que queremos (con aceleración)
local airJumpsLeft = MovementConfig.MaxAirJumps
local groundJumpAvailable = true
local lastGroundedAt = -math.huge
local inHitstun = false
local hitstunUntil = 0

function MovementController.GetFacing(): number
	return facing
end

local function approach(current: number, target: number, maxStep: number): number
	if current < target then
		return math.min(current + maxStep, target)
	end
	return math.max(current - maxStep, target)
end

local function getBody(): (BasePart?, Humanoid?)
	local character = Players.LocalPlayer.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChildOfClass("Humanoid")
end

-- Lo llama el servidor (remote ApplyKnockback) cuando nos golpean.
function MovementController.ApplyKnockback(velocity: Vector3, hitstun: number)
	local root, humanoid = getBody()
	if not root or not humanoid then
		return
	end
	inHitstun = true
	hitstunUntil = os.clock() + hitstun
	InputController.ClearJump()
	-- Estado Physics: el Humanoid deja de frenar al personaje mientras vuela.
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	root.AssemblyLinearVelocity = velocity
end

-- Lo llama el servidor (remote FighterReset) tras un respawn: empezar de cero.
function MovementController.ResetMotion()
	speedX = 0
	inHitstun = false
	airJumpsLeft = MovementConfig.MaxAirJumps
	groundJumpAvailable = true
	InputController.ClearJump()
	local root, humanoid = getBody()
	if root and humanoid then
		root.AssemblyLinearVelocity = Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

local function lockToPlane(root: BasePart)
	local pos = root.Position
	local rotation = if facing == 1 then FACE_RIGHT else FACE_LEFT
	root.CFrame = CFrame.new(pos.X, pos.Y, 0) * rotation

	local vel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(vel.X, math.max(vel.Y, -MovementConfig.MaxFallSpeed), 0)
	root.AssemblyAngularVelocity = Vector3.zero
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = true
	humanoid.JumpPower = MovementConfig.JumpVelocity
	speedX = 0
	airJumpsLeft = MovementConfig.MaxAirJumps
	groundJumpAvailable = true
	inHitstun = false
end

local function step(dt: number)
	local root, humanoid = getBody()
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()

	-- 0. Hitstun: sin control, solo se vuela.
	if inHitstun then
		if now < hitstunUntil then
			humanoid.WalkSpeed = 0
			humanoid:Move(Vector3.zero)
			lockToPlane(root)
			return
		end
		inHitstun = false
		speedX = root.AssemblyLinearVelocity.X -- conservar el impulso al recuperar el control
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	end

	local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
	if grounded then
		lastGroundedAt = now
		airJumpsLeft = MovementConfig.MaxAirJumps
		groundJumpAvailable = true
	end

	local character = root.Parent :: Model
	local attacking = character:GetAttribute("State") == "Attacking"

	-- 1. Horizontal: acelerar hacia la velocidad objetivo.
	-- Atacando en el suelo no se avanza; en el aire se conserva el control.
	local moveX = if attacking and grounded then 0 else InputController.GetMoveX()
	local maxSpeed = if grounded then MovementConfig.GroundSpeed else MovementConfig.AirSpeed
	local rate
	if moveX ~= 0 then
		rate = if grounded then MovementConfig.GroundAcceleration else MovementConfig.AirAcceleration
	else
		rate = if grounded then MovementConfig.GroundDeceleration else MovementConfig.AirDeceleration
	end
	speedX = approach(speedX, moveX * maxSpeed, rate * dt)

	-- El Humanoid aplica la velocidad: así respeta suelo, rampas y animaciones.
	if math.abs(speedX) < 0.05 then
		humanoid.WalkSpeed = 0
		humanoid:Move(Vector3.zero)
	else
		humanoid.WalkSpeed = math.abs(speedX)
		humanoid:Move(Vector3.new(math.sign(speedX), 0, 0))
	end

	-- Durante un ataque no se gira (el golpe sale hacia donde mirabas).
	if not attacking then
		if moveX > 0 then
			facing = 1
		elseif moveX < 0 then
			facing = -1
		end
	end

	-- 2. Saltos (no durante un ataque).
	if not attacking and InputController.HasBufferedJump(MovementConfig.JumpBuffer) then
		local canGroundJump = groundJumpAvailable and (now - lastGroundedAt) <= MovementConfig.CoyoteTime
		if canGroundJump then
			InputController.ClearJump()
			groundJumpAvailable = false
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		elseif not grounded and airJumpsLeft > 0 then
			InputController.ClearJump()
			airJumpsLeft -= 1
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, MovementConfig.AirJumpVelocity, 0)
		end
		-- Si no se puede saltar, el salto queda guardado un instante (JumpBuffer).
	end

	-- 3. Plano 2D, orientación y caída máxima.
	lockToPlane(root)
end

function MovementController.Start()
	local player = Players.LocalPlayer
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)

	-- Los controles por defecto de Roblox llaman a Humanoid:Move(...) cada frame
	-- con prioridad "Input". Nos ejecutamos justo DESPUÉS para que nuestro Move
	-- sea el último antes de la física (si no, ellos lo pisan con cero).
	RunService:BindToRenderStep("PlatformFighterMovement", Enum.RenderPriority.Input.Value + 1, step)

	-- Esperar al remote en segundo plano para no bloquear a nadie.
	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local applyKnockback = remotes:WaitForChild("ApplyKnockback") :: RemoteEvent
		applyKnockback.OnClientEvent:Connect(MovementController.ApplyKnockback)
		local fighterReset = remotes:WaitForChild("FighterReset") :: RemoteEvent
		fighterReset.OnClientEvent:Connect(MovementController.ResetMotion)
	end)
end

return MovementController
