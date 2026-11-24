-- ServerScriptService.Server.Services.MatchService
-- Reglas de la partida: BlastZone, KO, vidas (stocks), respawn, victoria y reinicio.
--
-- Estados de la partida:
--   "Waiting" : modo libre (práctica). KO sin perder vidas.
--   "Playing" : partida en curso, cada KO resta una vida
--   "Ended"   : hay ganador; tras VictoryDelay se reinicia
--
-- Modos de partida:
--   "PvP"   : 2+ jugadores. Empieza sola cuando hay MinPlayersForMatch jugadores.
--   "VsCpu" : 1 jugador contra la CPU (Blade en modo Pelear). Se pide desde el
--             menú de práctica (TrainingService avisa con OnStartVsCpu).
--
-- Estados del luchador que usa este servicio (atributo State):
--   "KO" → "Respawning" (congelado arriba) → "Idle"
--   "Eliminated" (sin vidas: congelado fuera de cámara hasta la próxima partida)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local FighterService = require(script.Parent.FighterService)
local TrainingService = require(script.Parent.TrainingService)
local CpuService = require(script.Parent.CpuService)
local Remotes = require(script.Parent.Parent.Remotes)

local MatchService = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)
local ELIMINATED_PARK = CFrame.new(0, 500, 0) -- lejos de todo; la cámara lo ignora

local matchState = "Waiting"
local matchMode: string? = nil -- "PvP" | "VsCpu" mientras hay partida
local busy: { [Model]: boolean } = {} -- luchadores en medio de un KO/respawn
local invulnerableTokens: { [Model]: number } = {}

local blastZone: BasePart
local spawnCFrames: { CFrame } = {}
local respawnCFrame: CFrame

local function isInside(position: Vector3, zone: BasePart): boolean
	local half = zone.Size / 2
	local center = zone.Position
	return math.abs(position.X - center.X) <= half.X and math.abs(position.Y - center.Y) <= half.Y
end

local function getName(fighter: FighterService.Fighter): string
	return fighter.model:GetAttribute("DisplayName") or fighter.model.Name
end

-- Luchadores de jugadores.
local function playerFighters(excluded: Player?): { FighterService.Fighter }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player ~= excluded then
			local fighter = FighterService.Get(player.Character)
			if fighter then
				table.insert(list, fighter)
			end
		end
	end
	return list
end

-- Quienes juegan la partida: jugadores, y la CPU si es "VsCpu".
-- En modo libre la CPU la gestiona TrainingService (no está aquí).
local function participants(excluded: Player?): { FighterService.Fighter }
	local list = playerFighters(excluded)
	if matchMode == "VsCpu" then
		local cpu = TrainingService.GetCpuFighter()
		if cpu and cpu.model.Parent then
			table.insert(list, cpu)
		end
	end
	return list
end

local function broadcast(kind: string, data: { [string]: any })
	Remotes.MatchEvent:FireAllClients(kind, data)
end

local function setInvulnerable(fighter: FighterService.Fighter, seconds: number)
	local model = fighter.model
	invulnerableTokens[model] = (invulnerableTokens[model] or 0) + 1
	local token = invulnerableTokens[model]

	model:SetAttribute("Invulnerable", true)
	local highlight = model:FindFirstChild("InvulnerableHighlight") :: Highlight?
	if not highlight then
		local newHighlight = Instance.new("Highlight")
		newHighlight.Name = "InvulnerableHighlight"
		newHighlight.FillColor = Color3.new(1, 1, 1)
		newHighlight.FillTransparency = 0.5
		newHighlight.OutlineColor = Color3.new(1, 1, 1)
		newHighlight.Parent = model
		highlight = newHighlight
	end

	task.delay(seconds, function()
		if invulnerableTokens[model] ~= token or not model.Parent then
			return -- otra invulnerabilidad más nueva manda
		end
		model:SetAttribute("Invulnerable", false)
		if highlight then
			highlight:Destroy()
		end
	end)
end

-- Congela al luchador en un punto, espera y lo suelta devolviéndole el control.
local function placeAt(fighter: FighterService.Fighter, cframe: CFrame, freezeSeconds: number)
	local root = fighter.root
	root.Anchored = true
	fighter.model:PivotTo(cframe)

	if freezeSeconds > 0 then
		task.wait(freezeSeconds)
	end
	if not fighter.model.Parent then
		return
	end

	root.Anchored = false
	root.AssemblyLinearVelocity = Vector3.zero
	if fighter.player then
		pcall(function()
			root:SetNetworkOwner(fighter.player)
		end)
		Remotes.FighterReset:FireClient(fighter.player)
	else
		-- CPU: el servidor vuelve a ser dueño de su física.
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		fighter.humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		CpuService.ResetState(fighter)
	end
end

local function respawn(fighter: FighterService.Fighter, cframe: CFrame)
	FighterService.Reset(fighter)
	FighterService.SetState(fighter, "Respawning")
	setInvulnerable(fighter, GameConfig.RespawnDelay + GameConfig.RespawnInvulnerability)
	placeAt(fighter, cframe, GameConfig.RespawnDelay)
	if fighter.model.Parent and FighterService.GetState(fighter) == "Respawning" then
		FighterService.SetState(fighter, "Idle")
	end
end

-- Vuelve al modo libre (práctica) cuando termina una partida o se cancela.
local function returnToFreeMode()
	local previousMode = matchMode
	matchState = "Waiting"
	matchMode = nil

	for _, fighter in playerFighters() do
		fighter.model:SetAttribute("Stocks", nil)
		if FighterService.GetState(fighter) == "Eliminated" then
			task.spawn(respawn, fighter, respawnCFrame)
		end
	end

	if previousMode == "VsCpu" then
		local cpu = TrainingService.GetCpuFighter()
		if cpu then
			cpu.model:SetAttribute("Stocks", nil)
		end
		TrainingService.SetMatchControl(false) -- la CPU vuelve a la práctica
	elseif #playerFighters() < GameConfig.MinPlayersForMatch then
		TrainingService.SetActive(true)
	end
	-- Si hay 2+ jugadores, el Heartbeat arrancará una partida PvP nueva.
end

local function checkVictory(excluded: Player?)
	if matchState ~= "Playing" then
		return
	end

	local alive = {}
	for _, fighter in participants(excluded) do
		if (fighter.model:GetAttribute("Stocks") or 0) > 0 then
			table.insert(alive, fighter)
		end
	end
	if #alive > 1 then
		return
	end

	matchState = "Ended"
	local winner = alive[1]
	broadcast("Victory", { name = if winner then getName(winner) else nil })
	print(`[MatchService] fin de partida — ganador: {if winner then getName(winner) else "nadie"}`)

	task.delay(GameConfig.VictoryDelay, returnToFreeMode)
end

local function knockOut(fighter: FighterService.Fighter)
	local model = fighter.model
	busy[model] = true
	local position = fighter.root.Position
	FighterService.CancelTimers(fighter)
	FighterService.SetState(fighter, "KO")
	model:SetAttribute("Invulnerable", true)

	-- Solo pierde vida quien está en la partida (tiene Stocks).
	local stocks = model:GetAttribute("Stocks")
	if matchState == "Playing" and stocks ~= nil then
		stocks -= 1
		model:SetAttribute("Stocks", stocks)
		broadcast("KO", { name = getName(fighter), stocks = stocks, position = position })

		if stocks <= 0 then
			FighterService.SetState(fighter, "Eliminated")
			fighter.root.Anchored = true
			model:PivotTo(ELIMINATED_PARK)
			busy[model] = nil
			checkVictory()
			return
		end
	else
		broadcast("KO", { name = getName(fighter), position = position })
	end

	task.spawn(function()
		respawn(fighter, respawnCFrame)
		busy[model] = nil
	end)
end

local function startMatch(mode: string, fighters: { FighterService.Fighter })
	matchState = "Playing"
	matchMode = mode
	print(`[MatchService] empieza la partida ({mode}) con {#fighters} luchadores`)

	for index, fighter in fighters do
		fighter.model:SetAttribute("Stocks", GameConfig.Stocks)
		local spawnCFrame = spawnCFrames[((index - 1) % #spawnCFrames) + 1]
		busy[fighter.model] = true
		task.spawn(function()
			respawn(fighter, spawnCFrame)
			busy[fighter.model] = nil
		end)
	end
	broadcast("Start", { mode = mode })
end

-- Pedido desde el menú de práctica: el jugador contra la CPU.
local function startVsCpu(player: Player)
	if matchState ~= "Waiting" then
		return
	end
	local playerFighter = FighterService.Get(player.Character)
	local cpu = TrainingService.GetCpuFighter()
	if not playerFighter or not cpu or #playerFighters() >= GameConfig.MinPlayersForMatch then
		return
	end
	TrainingService.SetMatchControl(true) -- la CPU pasa a "Pelear" y deja de resetearse sola
	startMatch("VsCpu", { playerFighter, cpu })
end

local function onHeartbeat()
	for _, fighter in participants() do
		if not busy[fighter.model] then
			local state = FighterService.GetState(fighter)
			local canBeKnockedOut = state ~= "KO" and state ~= "Respawning" and state ~= "Eliminated"
			if canBeKnockedOut and not isInside(fighter.root.Position, blastZone) then
				knockOut(fighter)
			end
		end
	end

	if matchState == "Waiting" and #playerFighters() >= GameConfig.MinPlayersForMatch then
		TrainingService.SetActive(false) -- sin CPU en una partida entre jugadores
		startMatch("PvP", playerFighters())
	end
end

function MatchService.Start()
	local arena = workspace:FindFirstChild("Arena")
	local spawnPoints = arena and arena:FindFirstChild("SpawnPoints")
	local zone = arena and arena:FindFirstChild("BlastZone")
	local spawn1 = spawnPoints and spawnPoints:FindFirstChild("Spawn1")
	local spawn2 = spawnPoints and spawnPoints:FindFirstChild("Spawn2")
	local top = spawnPoints and spawnPoints:FindFirstChild("RespawnTop")
	if not (zone and spawn1 and spawn2 and top) then
		warn("[MatchService] falta algo en Workspace.Arena (BlastZone, Spawn1, Spawn2 o RespawnTop); no hay partida")
		return
	end

	blastZone = zone
	spawnCFrames = {
		CFrame.new(spawn1.Position.X, spawn1.Position.Y + 3, 0) * FACE_RIGHT,
		CFrame.new(spawn2.Position.X, spawn2.Position.Y + 3, 0) * FACE_LEFT,
	}
	respawnCFrame = CFrame.new(top.Position.X, top.Position.Y, 0) * FACE_RIGHT

	TrainingService.OnStartVsCpu(startVsCpu)
	Players.PlayerRemoving:Connect(function(player)
		checkVictory(player)
	end)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return MatchService
