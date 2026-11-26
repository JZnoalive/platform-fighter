-- StarterPlayer.StarterPlayerScripts.Client.Controllers.DebugController
-- PANEL DE DEPURACIÓN de la sala de prueba (tecla F2 para mostrar/ocultar).
-- Muestra en vivo, para medir el "game feel":
--   · Estado de movimiento (Grounded, Running, Jumping, Falling, FastFalling,
--     AirAttacking, AirDodging, Recovering, Hitstun...) y fase del ataque
--   · Velocidad vertical, saltos aéreos que quedan, recovery y esquiva aérea
--   · Estado, % y combo del rival
--   · Registro de los últimos ataques: nombre, tiempos (arranque/golpe/recuperación),
--     si acertaron y cuánto pasó desde el anterior (para medir cadenas)
-- Extras opcionales (los activa el menú de práctica): hurtboxes y flecha de knockback.
-- Solo LEE datos: no cambia el juego.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local MovementConfig = require(ReplicatedStorage.Shared.Config.MovementConfig)
local FighterStats = require(ReplicatedStorage.Shared.Modules.FighterStats)

local DebugController = {}

local MAX_LOG = 8
local log: { { move: string, at: number, timing: string, hit: boolean, gap: number? } } = {}
local panel: TextLabel
local visible = false -- paneles ocultos al empezar (F2 los muestra): la pantalla es para jugar
local showHurtboxes = false
local showKnockback = true
local lastMoveId: any = nil

-- Registro de ENTRADA (siempre visible en la sala de prueba): cada pulsación, qué
-- ataque se eligió, el índice de la cadena y, si no encadena, el MOTIVO exacto.
local INPUT_LOG_MAX = 20
local inputLog: { string } = {}
local inputPanel: TextLabel? = nil

local inputStatus = ""

local function refreshInputPanel()
	if inputPanel then
		inputPanel.Text = "<b>ENTRADA</b> (J = ligero, K = pesado · mantener J = cadena)\n"
			.. inputStatus .. "\n"
			.. table.concat(inputLog, "\n")
	end
end

-- Línea de estado fija (arriba del registro): última tecla, ataque, cadena y ventana.
function DebugController.SetInputStatus(text: string)
	if text ~= inputStatus then
		inputStatus = text
		refreshInputPanel()
	end
end

-- Añade una línea al registro de entrada. kind: "input" | "ok" | "fail" | "info"
function DebugController.LogInput(text: string, kind: string?)
	if not (GameConfig.TestRoom and GameConfig.TestRoom.Enabled) then
		return -- solo en la sala de prueba
	end
	local color = if kind == "fail" then "#ff6b6b"
		elseif kind == "ok" then "#7CFC9A"
		elseif kind == "input" then "#ffd84d"
		else "#cfd8ff"
	local line = string.format('<font color="%s">%6.2f  %s</font>', color, os.clock() % 1000, text)
	table.insert(inputLog, line)
	while #inputLog > INPUT_LOG_MAX do
		table.remove(inputLog, 1)
	end
	refreshInputPanel()
	print("[Entrada] " .. text)
end

local function cpuModel(): Model?
	for _, model in CollectionService:GetTagged("CameraTarget") do
		if model:IsA("Model") and model:GetAttribute("FighterId") then
			return model
		end
	end
	return nil
end

local function yesNo(v: any): string
	return if v then "SÍ" else "no"
end

-- Registra cada ataque nuevo del jugador (cambia MoveId) con sus tiempos.
local function trackAttacks(character: Model)
	local moveId = character:GetAttribute("MoveId")
	if moveId == nil or moveId == lastMoveId then
		return
	end
	lastMoveId = moveId
	local move = character:GetAttribute("Move") or "?"
	local moveset = FighterStats.Moveset(character:GetAttribute("Weapon"), character:GetAttribute("FighterId"))
	local data = moveset and moveset[move]
	local timing = if data
		then string.format("%.0f/%.0f/%.0f ms", data.startup * 1000, data.active * 1000, data.recovery * 1000)
		else "?"
	local now = os.clock()
	local prev = log[1]
	table.insert(log, 1, { move = move, at = now, timing = timing, hit = false, gap = if prev then now - prev.at else nil })
	if #log > MAX_LOG then
		table.remove(log)
	end
end

local function render()
	local character = Players.LocalPlayer.Character
	if not character or not panel then
		return
	end
	trackAttacks(character)
	if not visible then
		panel.Visible = false
		return
	end
	panel.Visible = true
	local cpu = cpuModel()
	local lines = {
		"<b>SALA DE PRUEBA</b>  (F2 ocultar)",
		string.format("Estado: <b>%s</b>   Ataque: %s (%s)", tostring(character:GetAttribute("MoveState")),
			tostring(character:GetAttribute("Move") or "-"), tostring(character:GetAttribute("AttackPhase"))),
		string.format("Vel. vertical: <b>%s</b>   Saltos aéreos: <b>%s/%d</b>", tostring(character:GetAttribute("VY")),
			tostring(character:GetAttribute("JumpsLeft")), MovementConfig.MaxAirJumps),
		string.format("Recovery: <b>%s</b>   Esquiva aérea: <b>%s</b>", yesNo(character:GetAttribute("RecoveryReady")),
			yesNo(character:GetAttribute("AirDodgeReady"))),
	}
	if cpu then
		table.insert(lines, string.format("Rival: %s · %d%% · combo x%d%s", tostring(cpu:GetAttribute("State")),
			math.floor(cpu:GetAttribute("Percent") or 0), cpu:GetAttribute("ComboHits") or 0,
			if cpu:GetAttribute("Frozen") then " · CONGELADO" else ""))
	end
	table.insert(lines, "<b>Últimos ataques</b> (arranque/golpe/recuperación):")
	for _, entry in log do
		table.insert(lines, string.format("  %s %s · %s%s", if entry.hit then "OK" else " ·", entry.move, entry.timing,
			if entry.gap then string.format(" · +%.2f s", entry.gap) else ""))
	end
	panel.Text = table.concat(lines, "\n")
end

-- Hurtboxes: cajas de cada parte del cuerpo de los luchadores (lo que se puede golpear).
local hurtboxFolder: Folder
local function refreshHurtboxes()
	hurtboxFolder:ClearAllChildren()
	if not showHurtboxes then
		return
	end
	local models = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(models, player.Character)
		end
	end
	local cpu = cpuModel()
	if cpu then
		table.insert(models, cpu)
	end
	for _, model in models do
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local box = Instance.new("SelectionBox")
				box.Adornee = part
				box.Color3 = Color3.fromRGB(80, 200, 255)
				box.LineThickness = 0.03
				box.SurfaceTransparency = 0.85
				box.SurfaceColor3 = Color3.fromRGB(80, 200, 255)
				box.Parent = hurtboxFolder
			end
		end
	end
end

-- Flecha de knockback: dirección y fuerza del lanzamiento (0,6 s).
local function knockbackArrow(position: Vector3, velocity: Vector3)
	if not showKnockback or velocity.Magnitude < 1 then
		return
	end
	local length = math.clamp(velocity.Magnitude * 0.12, 1.5, 10)
	local from = Vector3.new(position.X, position.Y, 2)
	local to = from + Vector3.new(velocity.X, velocity.Y, 0).Unit * length
	local arrow = Instance.new("Part")
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CanQuery = false
	arrow.CanTouch = false
	arrow.CastShadow = false
	arrow.Material = Enum.Material.Neon
	arrow.Color = Color3.fromRGB(255, 80, 200)
	arrow.Size = Vector3.new(0.25, 0.25, length)
	arrow.CFrame = CFrame.lookAt((from + to) / 2, to)
	arrow.Parent = workspace
	task.delay(0.6, function()
		arrow:Destroy()
	end)
end

function DebugController.SetHurtboxes(on: boolean)
	showHurtboxes = on
	refreshHurtboxes()
end

function DebugController.IsShowingHurtboxes(): boolean
	return showHurtboxes
end

function DebugController.SetKnockbackArrow(on: boolean)
	showKnockback = on
end

function DebugController.IsShowingKnockbackArrow(): boolean
	return showKnockback
end

-- Imprime en la consola (Output) la última cadena de ataques, para copiarla.
function DebugController.PrintLastChain()
	print("[Sala de prueba] Últimos ataques (más reciente primero):")
	for _, entry in log do
		print(string.format("  %s %s · %s%s", if entry.hit then "ACIERTA" else "falla", entry.move, entry.timing,
			if entry.gap then string.format(" · +%.2f s desde el anterior", entry.gap) else ""))
	end
end

function DebugController.Start()
	if not (GameConfig.TestRoom and GameConfig.TestRoom.Enabled) then
		return
	end
	hurtboxFolder = Instance.new("Folder")
	hurtboxFolder.Name = "DebugHurtboxes"
	hurtboxFolder.Parent = workspace

	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugPanel"
	gui.ResetOnSpawn = false
	panel = Instance.new("TextLabel")
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 230, 1, -12)
	panel.Size = UDim2.fromOffset(430, 230)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	panel.BackgroundTransparency = 0.25
	panel.TextColor3 = Color3.new(1, 1, 1)
	panel.Font = Enum.Font.Code
	panel.TextSize = 14
	panel.RichText = true
	panel.TextXAlignment = Enum.TextXAlignment.Left
	panel.TextYAlignment = Enum.TextYAlignment.Top
	panel.Text = ""
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 6)
	padding.Parent = panel
	panel.Parent = gui

	-- Panel de ENTRADA (arriba a la derecha, siempre visible en la sala de prueba)
	local input = Instance.new("TextLabel")
	input.Name = "InputLog"
	input.AnchorPoint = Vector2.new(1, 0)
	input.Position = UDim2.new(1, -12, 0, 150)
	input.Size = UDim2.fromOffset(500, 320)
	input.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	input.BackgroundTransparency = 0.2
	input.TextColor3 = Color3.new(1, 1, 1)
	input.Font = Enum.Font.Code
	input.TextSize = 14
	input.RichText = true
	input.TextWrapped = true
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.TextYAlignment = Enum.TextYAlignment.Top
	local inputPadding = padding:Clone()
	inputPadding.Parent = input
	input.Parent = gui
	inputPanel = input
	refreshInputPanel()

	-- CONTROLES reales (los de InputController.BINDINGS), abajo a la derecha.
	local controls = Instance.new("TextLabel")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(1, 1)
	controls.Position = UDim2.new(1, -12, 1, -12)
	controls.Size = UDim2.fromOffset(480, 175)
	controls.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	controls.BackgroundTransparency = 0.25
	controls.TextColor3 = Color3.new(1, 1, 1)
	controls.Font = Enum.Font.Code
	controls.TextSize = 12
	controls.RichText = true
	controls.TextXAlignment = Enum.TextXAlignment.Left
	controls.TextYAlignment = Enum.TextYAlignment.Top
	controls.Text = table.concat({
		"<b>CONTROLES</b>",
		"A / D ......... moverse (doble toque = dash, luego corres)",
		"Espacio ....... saltar (W también) · 2 saltos en el aire",
		"S (bajando) ... caída rápida · mantener S = bajar plataforma",
		"J / clic izq .. ataque ligero",
		"  J J J ....... cadena Light 1 > 2 > 3 (o mantener J)",
		"  A/D + J ..... lateral · S + J abajo · W + J arriba",
		"K / clic der .. ataque fuerte (+ dirección)",
		"W + K (aire) .. recovery",
		"Shift / L ..... esquiva (+ dirección en el aire)",
		"F2 ............ ocultar/mostrar paneles",
	}, "\n")
	local controlsPadding = padding:Clone()
	controlsPadding.Parent = controls
	controls.Parent = gui

	-- Pista pequeña siempre visible
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -12, 1, -8)
	hint.Size = UDim2.fromOffset(260, 22)
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Color3.new(1, 1, 1)
	hint.TextStrokeTransparency = 0.4
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 14
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Text = "F2 = controles y depuración"
	hint.Parent = gui

	local function applyVisibility()
		input.Visible = visible
		controls.Visible = visible
		hint.Visible = not visible
	end
	applyVisibility()

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	RunService.RenderStepped:Connect(render)
	UserInputService.InputBegan:Connect(function(inputObject, processed)
		if not processed and inputObject.KeyCode == Enum.KeyCode.F2 then
			visible = not visible
			applyVisibility()
		end
	end)
	-- Los cuerpos cambian al reaparecer: refrescar las hurtboxes cada poco.
	task.spawn(function()
		while true do
			task.wait(1)
			if showHurtboxes then
				refreshHurtboxes()
			end
		end
	end)

	task.spawn(function()
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local hitEvent = remotes:WaitForChild("HitEvent") :: RemoteEvent
		hitEvent.OnClientEvent:Connect(function(_target, position, _force, _duration, attacker, velocity)
			if typeof(velocity) == "Vector3" then
				knockbackArrow(position, velocity)
			end
			if attacker == Players.LocalPlayer.Character and log[1] then
				log[1].hit = true -- el último ataque acertó
			end
		end)
	end)
end

return DebugController
