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
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local CharacterStyles = require(ReplicatedStorage.Shared.Config.CharacterStyles)
local WeaponStyles = require(ReplicatedStorage.Shared.Config.WeaponStyles)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)
local FighterService = require(script.Parent.FighterService)
local CpuService = require(script.Parent.CpuService)
local AppearanceService = require(script.Parent.AppearanceService)
local Remotes = require(script.Parent.Parent.Remotes)

local TrainingService = {}

local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)

local wantActive = false
local spawning = false
local cpuFighter: FighterService.Fighter? = nil
local spawnCFrame: CFrame? = nil
local currentBehavior = CpuConfig.DefaultBehavior
local testRoom = GameConfig.TestRoom and GameConfig.TestRoom.Enabled and GameConfig.TestRoom or nil
-- personaje de la CPU (cambiable en el menú); en la sala de prueba, el rival de prueba
local cpuFighterId = if testRoom then testRoom.CpuFighter else "Blade"
local cpuWeapon = CharacterStyles[cpuFighterId].defaultWeapon -- se conserva aunque la CPU se recree
local lastCpuHitAt = 0 -- sala de prueba: último golpe que recibió la CPU
local matchControl = false -- true = la CPU está en una partida "VsCpu" (la gestiona MatchService)
local startVsCpuCallback: ((Player) -> ())? = nil

local function isInside(position: Vector3, zone: BasePart): boolean
	local half = zone.Size / 2
	local center = zone.Position
	return math.abs(position.X - center.X) <= half.X and math.abs(position.Y - center.Y) <= half.Y
end

local function isValidBehavior(name: any): boolean
	return type(name) == "string" and table.find(CpuConfig.Behaviors, name) ~= nil
end

-- Ancla al luchador donde está AHORA y se asegura de que los clientes lo vean ahí.
-- (Roblox no reenvía la posición de una pieza anclada que llegó por la física: el
-- cliente se quedaba viendo al rival flotando donde apareció, 4 studs más arriba.)
local function anchorInPlace(fighter: FighterService.Fighter)
	local root = fighter.root
	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = true
	root.CFrame = root.CFrame + Vector3.new(0, 0.01, 0) -- cambio real de propiedad = se replica
end

local function resetCpu(fighter: FighterService.Fighter)
	if not spawnCFrame then
		return
	end
	local root = fighter.root
	root.Anchored = false -- por si venía de estar eliminada en una partida
	fighter.model:SetAttribute("Frozen", false)
	fighter.model:PivotTo(spawnCFrame)
	root.AssemblyLinearVelocity = Vector3.zero
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	FighterService.Reset(fighter)
	fighter.model:SetAttribute("Invulnerable", false)
	local highlight = fighter.model:FindFirstChild("InvulnerableHighlight")
	if highlight then
		highlight:Destroy()
	end
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
		return Players:CreateHumanoidModelFromDescription(
			AppearanceService.GetDescription(cpuFighterId),
			Enum.HumanoidRigType.R15
		)
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
	model.Name = `CPU_{cpuFighterId}`
	model:PivotTo(spawnCFrame :: CFrame)
	AppearanceService.AddGear(model, cpuFighterId) -- pelo, capucha, botas... (estilo bloque)
	AppearanceService.SetWeapon(model, cpuWeapon) -- espada por defecto (cambiable en el menú)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	model.Parent = workspace

	local fighter = FighterService.Register(model, "Cpu", cpuFighterId, nil)
	if not fighter then
		model:Destroy()
		return
	end
	fighter.root:SetNetworkOwner(nil) -- el servidor controla su física
	model:SetAttribute("DisplayName", `{CharacterStyles[cpuFighterId].displayName or cpuFighterId} (CPU)`)
	CollectionService:AddTag(model, "CameraTarget") -- la cámara también la encuadra
	CpuService.Attach(fighter, currentBehavior)
	cpuFighter = fighter

	workspace:SetAttribute("CpuBehavior", currentBehavior)
	workspace:SetAttribute("PracticeActive", true)

	-- Fuera de la BlastZone: vuelve a su sitio con 0 % (solo en práctica;
	-- en una partida "VsCpu" el KO lo gestiona MatchService).
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			connection:Disconnect()
			return
		end
		if not matchControl and not isInside(fighter.root.Position, blastZone) then
			resetCpu(fighter)
			return
		end
		-- Sala de prueba: si la CPU quedó tocada (con % o fuera de su sitio) y lleva
		-- AutoResetDelay s sin recibir golpes, vuelve sola a su sitio con 0 %.
		-- (Desactivado si AutoResetDelay = nil: con la CPU caminando o peleando se
		-- reiniciaba sola cada pocos segundos y parecía bugueada.)
		if testRoom and testRoom.AutoResetDelay and not matchControl then
			local percent = model:GetAttribute("Percent") or 0
			if model:GetAttribute("State") == "Hitstun" then
				lastCpuHitAt = os.clock()
			end
			local moved = spawnCFrame and (fighter.root.Position - spawnCFrame.Position).Magnitude > 3
			if (percent > 0 or moved) and FighterService.GetState(fighter) == "Idle"
				and not model:GetAttribute("Frozen")
				and os.clock() - lastCpuHitAt > testRoom.AutoResetDelay then
				lastCpuHitAt = os.clock()
				resetCpu(fighter)
			end
		end
	end)

	print("[TrainingService] CPU lista (modo práctica)")
end

local function onPracticeCommand(player: Player, command: any, value: any)
	local fighter = cpuFighter
	if not wantActive or matchControl or not fighter or not fighter.model.Parent then
		return -- solo en modo práctica
	end

	if command == "StartVsCpu" then
		if startVsCpuCallback then
			startVsCpuCallback(player)
		end
	elseif command == "Behavior" then
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
	elseif command == "ResetPositions" then
		-- Rival a su sitio, 0 %, QUIETO pero NO congelado: no se mueve por sí solo, pero
		-- los golpes lo doblan y lo lanzan (si se congelaba, no reaccionaba a nada y
		-- parecía que el juego estaba parado). El jugador se coloca a 5 studs (lo hace su cliente).
		resetCpu(fighter) -- (quita Frozen y el anclaje)
		-- En el CENTRO del escenario, sin plataformas encima (su sitio normal está debajo
		-- de la plataforma derecha y al lanzarla hacia arriba chocaba con ella).
		if spawnCFrame then
			fighter.model:PivotTo(CFrame.new(4, spawnCFrame.Position.Y, 0) * spawnCFrame.Rotation)
		end
		CpuService.SetBehavior(fighter, "Idle")
		workspace:SetAttribute("CpuBehavior", "Idle")
		local playerFighter = FighterService.Get(player.Character)
		if playerFighter then
			playerFighter.model:SetAttribute("Percent", 0)
		end
	elseif command == "Hitboxes" then
		if type(value) == "boolean" then
			workspace:SetAttribute("DebugHitboxes", value)
		end
	elseif command == "Weapon" then
		-- Cambiar MI arma (solo en práctica). Se recuerda si reaparezco.
		local playerFighter = FighterService.Get(player.Character)
		if type(value) == "string" and WeaponStyles[value] and playerFighter then
			if FighterService.GetState(playerFighter) == "Idle" then
				AppearanceService.SetWeapon(playerFighter.model, value)
				player:SetAttribute("PreferredWeapon", value)
			end
		end
	elseif command == "CpuWeapon" then
		if type(value) == "string" and WeaponStyles[value] then
			cpuWeapon = value
			AppearanceService.SetWeapon(fighter.model, value)
		end
	elseif command == "Freeze" then
		-- Congelar/descongelar al rival: se queda clavado en el sitio (recibe golpes y
		-- daño, pero no se mueve). Útil para medir hitboxes y cadenas.
		local frozen = not fighter.model:GetAttribute("Frozen")
		fighter.model:SetAttribute("Frozen", frozen)
		if frozen then
			anchorInPlace(fighter)
		else
			fighter.root.Anchored = false
		end
		if frozen then
			CpuService.SetBehavior(fighter, "Idle")
			workspace:SetAttribute("CpuBehavior", "Idle")
		end
	elseif command == "Character" then
		-- Cambiar MI personaje: se recuerda y reaparezco con él (y con su arma).
		if type(value) == "string" and table.find(FighterStats.Roster, value) then
			player:SetAttribute("FighterChoice", value)
			player:SetAttribute("PreferredWeapon", nil)
			player:LoadCharacter()
		end
	elseif command == "CpuCharacter" then
		-- Cambiar el personaje de la CPU: se recrea con su aspecto y su arma.
		if type(value) == "string" and table.find(FighterStats.Roster, value) and value ~= cpuFighterId then
			cpuFighterId = value
			cpuWeapon = CharacterStyles[value].defaultWeapon
			fighter.model:Destroy() -- FighterService y CpuService la dan de baja solos
			cpuFighter = nil
			TrainingService.SetActive(true) -- crea la nueva
		end
	end
end

function TrainingService.GetCpuFighter(): FighterService.Fighter?
	if cpuFighter and cpuFighter.model.Parent then
		return cpuFighter
	end
	return nil
end

-- MatchService registra aquí qué hacer cuando el menú pide "pelear contra la CPU".
function TrainingService.OnStartVsCpu(callback: (Player) -> ())
	startVsCpuCallback = callback
end

-- true  = la CPU entra en una partida "VsCpu": modo Pelear, sin menú, sin auto-reset.
-- false = vuelve a la práctica con el comportamiento que tenía, en su sitio y a 0 %.
function TrainingService.SetMatchControl(enabled: boolean)
	matchControl = enabled
	local fighter = cpuFighter
	if not fighter or not fighter.model.Parent then
		return
	end
	if enabled then
		workspace:SetAttribute("PracticeActive", false)
		CpuService.SetBehavior(fighter, CpuConfig.VsCpuBehavior)
	else
		CpuService.SetBehavior(fighter, currentBehavior)
		resetCpu(fighter)
		workspace:SetAttribute("CpuBehavior", currentBehavior)
		workspace:SetAttribute("PracticeActive", true)
	end
end

-- true = debe haber CPU de práctica; false = se quita.
function TrainingService.SetActive(active: boolean)
	wantActive = active

	if not active then
		matchControl = false
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
