-- ServerScriptService.Server.Services.TrainingService
-- Crea UN dummy de entrenamiento por código y lo registra en FighterService.
-- Nunca hay dummies colocados a mano en Workspace (así no se repite el bug
-- de golpear a varios dummies a la vez).
-- Si el dummy sale de la BlastZone, vuelve a su spawn con 0 %.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FighterService = require(script.Parent.FighterService)

local TrainingService = {}

local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local function isInside(position: Vector3, zone: BasePart): boolean
	local half = zone.Size / 2
	local center = zone.Position
	return math.abs(position.X - center.X) <= half.X and math.abs(position.Y - center.Y) <= half.Y
end

local function spawnDummy()
	local arena = workspace:FindFirstChild("Arena")
	local spawnPart = arena and arena:FindFirstChild("SpawnPoints") and arena.SpawnPoints:FindFirstChild("Spawn2")
	local blastZone = arena and arena:FindFirstChild("BlastZone")
	if not spawnPart or not blastZone then
		warn("[TrainingService] falta Workspace.Arena.SpawnPoints.Spawn2 o Workspace.Arena.BlastZone")
		return
	end

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[TrainingService] no se pudo crear el dummy:", model)
		return
	end

	local spawnCFrame = CFrame.new(spawnPart.Position.X, spawnPart.Position.Y + 3, 0) * FACE_LEFT
	model.Name = "TrainingDummy"
	model:PivotTo(spawnCFrame)
	model.Parent = workspace

	local fighter = FighterService.Register(model, "Dummy", "Dummy", nil)
	if not fighter then
		return
	end
	fighter.root:SetNetworkOwner(nil) -- el servidor controla su física

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			return
		end
		local root = fighter.root
		local pos = root.Position

		if not isInside(pos, blastZone) then
			model:PivotTo(spawnCFrame)
			root.AssemblyLinearVelocity = Vector3.zero
			FighterService.Reset(fighter)
			fighter.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			return
		end

		-- Plano 2D, mirando a la izquierda
		root.CFrame = CFrame.new(pos.X, pos.Y, 0) * FACE_LEFT
		local vel = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y, 0)
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	print("[TrainingService] dummy listo")
end

function TrainingService.Start()
	task.spawn(spawnDummy)
end

return TrainingService
