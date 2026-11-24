-- ServerScriptService.Server.Services.TrainingService
-- MODO PRÁCTICA: crea UNA CPU (Blade) por código, la registra en FighterService,
-- se la da a CpuService y atiende los comandos del menú de práctica.
-- Nunca hay luchadores colocados a mano en Workspace (así no se repite el bug
-- de golpear a varios dummies a la vez).
-- Si la CPU sale de la BlastZone, vuelve a su spawn con 0 %.
--
-- Solo existe en modo libre (menos de 2 jugadores). MatchService la quita al
-- empezar una partida (SetActive(false)) y la devuelve al terminar.
--
-- Atributos que publica en Workspace (los lee el menú del cliente):
--   PracticeActive (bool), CpuBehavior (string). DebugHitboxes lo crea CombatService.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CpuConfig = require(ReplicatedStorage.Shared.Config.CpuConfig)
local FighterService = require(script.Parent.FighterService)
local CpuService = require(script.Parent.CpuService)
local Remotes = require(script.Parent.Parent.Remotes)

local TrainingService = {}

local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local wantActive = false
local spawning = false
local cpuFighter: FighterService.Fighter? = nil
local spawnCFrame: CFrame? = nil
local currentBehavior = CpuConfig.DefaultBehavior

local function isInside(position: Vector3, zone: BasePart): boolean
	local half = zone.Size / 2
	local center = zone.Position
	return math.abs(position.X - center.X) <= half.X and math.abs(position.Y - center.Y) <= half.Y
end

local function isValidBehavior(name: any): boolean
	return type(name) == "string" and table.find(CpuConfig.Behaviors, name) ~= nil
end

-- Colores provisionales de Blade (paleta de docs/PERSONAJES.md) hasta tener su modelo (M6).
local function makeDescription(): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromHex("DDD6FE")
	desc.TorsoColor = Color3.fromHex("7C3AED")
	desc.LeftArmColor = Color3.fromHex("1E1B2E")
	desc.RightArmColor = Color3.fromHex("1E1B2E")
	desc.LeftLegColor = Color3.fromHex("110E1B")
	desc.RightLegColor = Color3.fromHex("110E1B")
	return desc
end

local function resetCpu(fighter: FighterService.Fighter)
	if not spawnCFrame then
		return
	end
	fighter.model:PivotTo(spawnCFrame)
	fighter.root.AssemblyLinearVelocity = Vector3.zero
	FighterService.Reset(fighter)
	fighter.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	CpuService.ResetState(fighter)
end

local function spawnCpu()
	local arena = workspace:FindFirstChild("Arena")
	local spawnPoints = arena and arena:FindFirstChild("SpawnPoints")
	local spawnPart = spawnPoints and spawnPoints:FindFirstChild("Spawn2")
	local blastZone = arena and arena:FindFirstChild("BlastZone")
	if not spawnPart or not blastZone then
		warn("[TrainingService] falta Workspace.Arena.SpawnPoints.Spawn2 o Workspace.Arena.BlastZone")
		return
	end

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(makeDescription(), Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		warn("[TrainingService] no se pudo crear la CPU:", model)
		return
	end

	-- Mientras se creaba, puede que haya empezado una partida.
	if not wantActive then
		model:Destroy()
		return
	end

	spawnCFrame = CFrame.new(spawnPart.Position.X, spawnPart.Position.Y + 3, 0) * FACE_LEFT
	model.Name = "CPU_Blade"
	model:PivotTo(spawnCFrame :: CFrame)
	model.Parent = workspace

	local fighter = FighterService.Register(model, "Cpu", "Blade", nil)
	if not fighter then
		model:Destroy()
		return
	end
	fighter.root:SetNetworkOwner(nil) -- el servidor controla su física
	CollectionService:AddTag(model, "CameraTarget") -- la cámara también la encuadra
	CpuService.Attach(fighter, currentBehavior)
	cpuFighter = fighter

	workspace:SetAttribute("CpuBehavior", currentBehavior)
	workspace:SetAttribute("PracticeActive", true)

	-- Fuera de la BlastZone: vuelve a su sitio con 0 %.
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			return
		end
		if not isInside(fighter.root.Position, blastZone) then
			resetCpu(fighter)
		end
	end)

	print("[TrainingService] CPU lista (modo práctica)")
end

local function onPracticeCommand(player: Player, command: any, value: any)
	local fighter = cpuFighter
	if not wantActive or not fighter or not fighter.model.Parent then
		return -- solo en modo práctica
	end

	if command == "Behavior" then
		if isValidBehavior(value) then
			currentBehavior = value
			CpuService.SetBehavior(fighter, value)
			workspace:SetAttribute("CpuBehavior", value)
		end
	elseif command == "Percent" then
		if type(value) == "number" and value >= 0 and value <= 300 then
			fighter.model:SetAttribute("Percent", math.floor(value))
		end
	elseif command == "Reset" then
		resetCpu(fighter)
		local playerFighter = FighterService.Get(player.Character)
		if playerFighter then
			playerFighter.model:SetAttribute("Percent", 0)
		end
	elseif command == "Hitboxes" then
		if type(value) == "boolean" then
			workspace:SetAttribute("DebugHitboxes", value)
		end
	end
end

-- true = debe haber CPU de práctica; false = se quita.
function TrainingService.SetActive(active: boolean)
	wantActive = active

	if not active then
		workspace:SetAttribute("PracticeActive", false)
		if cpuFighter then
			cpuFighter.model:Destroy() -- FighterService y CpuService la dan de baja solos
			cpuFighter = nil
			print("[TrainingService] CPU retirada (empieza partida)")
		end
		return
	end

	if (cpuFighter and cpuFighter.model.Parent) or spawning then
		return -- ya hay una o se está creando
	end
	spawning = true
	task.spawn(function()
		spawnCpu()
		spawning = false
	end)
end

function TrainingService.Start()
	workspace:SetAttribute("PracticeActive", false)
	workspace:SetAttribute("CpuBehavior", currentBehavior)
	Remotes.PracticeCommand.OnServerEvent:Connect(onPracticeCommand)
	TrainingService.SetActive(true)
end

return TrainingService
