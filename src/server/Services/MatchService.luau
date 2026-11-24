-- ServerScriptService.Server.Services.MatchService
-- Reglas de la partida: BlastZone, KO, vidas (stocks), respawn, victoria y reinicio.
--
-- Estados de la partida:
--   "Waiting" : menos de MinPlayersForMatch jugadores → modo libre (KO sin perder vidas)
--   "Playing" : partida en curso, cada KO resta una vida
--   "Ended"   : hay ganador; tras VictoryDelay se reinicia
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
local Remotes = require(script.Parent.Parent.Remotes)

local MatchService = {}

local FACE_RIGHT = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_LEFT = CFrame.Angles(0, math.pi / 2, 0)
local ELIMINATED_PARK = CFrame.new(0, 500, 0) -- lejos de todo; la cámara lo ignora

local matchState = "Waiting"
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
	return if fighter.player then fighter.player.Name else fighter.model.Name
end

-- Solo los luchadores de jugadores (el dummy lo gestiona TrainingService).
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

local function checkVictory(excluded: Player?)
	if matchState ~= "Playing" then
		return
	end

	local alive = {}
	for _, fighter in playerFighters(excluded) do
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

	task.delay(GameConfig.VictoryDelay, function()
		matchState = "Waiting"
		-- Si ya no hay jugadores suficientes, los eliminados vuelven en modo libre.
		if #playerFighters() < GameConfig.MinPlayersForMatch then
			TrainingService.SetActive(true)
			for _, fighter in playerFighters() do
				fighter.model:SetAttribute("Stocks", nil)
				if FighterService.GetState(fighter) == "Eliminated" then
					task.spawn(respawn, fighter, respawnCFrame)
				end
			end
		end
		-- Si hay suficientes, el Heartbeat arranca una partida nueva.
	end)
end

local function knockOut(fighter: FighterService.Fighter)
	local model = fighter.model
	busy[model] = true
	FighterService.CancelTimers(fighter)
	FighterService.SetState(fighter, "KO")
	model:SetAttribute("Invulnerable", true)

	if matchState == "Playing" then
		local stocks = (model:GetAttribute("Stocks") or 1) - 1
		model:SetAttribute("Stocks", stocks)
		broadcast("KO", { name = getName(fighter), stocks = stocks })

		if stocks <= 0 then
			FighterService.SetState(fighter, "Eliminated")
			fighter.root.Anchored = true
			model:PivotTo(ELIMINATED_PARK)
			busy[model] = nil
			checkVictory()
			return
		end
	else
		broadcast("KO", { name = getName(fighter) })
	end

	task.spawn(function()
		respawn(fighter, respawnCFrame)
		busy[model] = nil
	end)
end

local function startMatch()
	local fighters = playerFighters()
	if #fighters < GameConfig.MinPlayersForMatch then
		return
	end
	matchState = "Playing"
	TrainingService.SetActive(false) -- sin dummy en una partida real
	print(`[MatchService] empieza la partida con {#fighters} jugadores`)

	for index, fighter in fighters do
		fighter.model:SetAttribute("Stocks", GameConfig.Stocks)
		local spawnCFrame = spawnCFrames[((index - 1) % #spawnCFrames) + 1]
		busy[fighter.model] = true
		task.spawn(function()
			respawn(fighter, spawnCFrame)
			busy[fighter.model] = nil
		end)
	end
	broadcast("Start", {})
end

local function onHeartbeat()
	for _, fighter in playerFighters() do
		if not busy[fighter.model] then
			local state = FighterService.GetState(fighter)
			local canBeKnockedOut = state ~= "KO" and state ~= "Respawning" and state ~= "Eliminated"
			if canBeKnockedOut and not isInside(fighter.root.Position, blastZone) then
				knockOut(fighter)
			end
		end
	end

	if matchState == "Waiting" and #playerFighters() >= GameConfig.MinPlayersForMatch then
		startMatch()
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

	Players.PlayerRemoving:Connect(function(player)
		checkVictory(player)
	end)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return MatchService
