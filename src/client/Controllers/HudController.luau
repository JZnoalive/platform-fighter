-- StarterPlayer.StarterPlayerScripts.Client.Controllers.HudController
-- HUD de combate:
--   • Abajo: una tarjeta por luchador con su color, nombre, % grande (cambia de
--     blanco a rojo según el daño y "salta" al recibir golpes) y vidas (●●●).
--   • Centro: mensajes grandes de partida ("¡A pelear!", "¡KO!", "¡X gana!").
-- Solo lee atributos que pone el servidor: no decide nada.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CharacterStyles = require(ReplicatedStorage.Shared.Config.CharacterStyles)

local HudController = {}

local messageLabel: TextLabel
local messageScale: UIScale
local cardsFrame: Frame
local showToken = 0

-- Contador de combo (arriba a la derecha): "COMBO x4 · 23%"
local comboLabel: TextLabel
local comboScale: UIScale
local comboShownUntil = 0
local lastComboHits = 0

type Card = {
	frame: Frame,
	nameLabel: TextLabel,
	percentLabel: TextLabel,
	stocksLabel: TextLabel,
	portrait: Frame, -- círculo del retrato (se sacude al recibir golpes)
	ring: UIStroke, -- aro de color según el daño (estilo Brawlhalla)
	viewport: ViewportFrame,
	portraitKey: string?, -- personaje+arma del retrato actual (para rehacerlo si cambia)
	stripe: Frame,
	scale: UIScale,
	lastPercent: number,
	shakeUntil: number,
}
local cards: { [Model]: Card } = {}

-- Color del daño (aro del retrato y %): blanco → amarillo → naranja → rojo → rojo oscuro.
local PERCENT_COLORS = {
	{ 0, Color3.fromRGB(255, 255, 255) },
	{ 40, Color3.fromRGB(255, 232, 80) },
	{ 80, Color3.fromRGB(255, 150, 40) },
	{ 120, Color3.fromRGB(235, 40, 30) },
	{ 170, Color3.fromRGB(120, 10, 20) },
}

local function percentColor(percent: number): Color3
	for i = 1, #PERCENT_COLORS - 1 do
		local a, b = PERCENT_COLORS[i], PERCENT_COLORS[i + 1]
		if percent <= b[1] then
			return a[2]:Lerp(b[2], (percent - a[1]) / (b[1] - a[1]))
		end
	end
	return PERCENT_COLORS[#PERCENT_COLORS][2]
end

local function makeText(parent: Instance, font: Enum.Font, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Size = size
	label.Position = position
	label.Parent = parent
	return label
end

local PORTRAIT = 86 -- tamaño del retrato (px)

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

-- Tarjeta estilo Brawlhalla: retrato redondo con aro de color según el daño,
-- medalla con las vidas, nombre debajo y el % pequeño.
local function createCard(model: Model): Card
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(PORTRAIT + 34, PORTRAIT + 46)
	frame.BackgroundTransparency = 1
	frame.Parent = cardsFrame

	-- Franja del color del personaje detrás del retrato
	local stripe = Instance.new("Frame")
	stripe.AnchorPoint = Vector2.new(0.5, 0)
	stripe.Position = UDim2.new(0.5, 0, 0, PORTRAIT * 0.55)
	stripe.Size = UDim2.new(1, 0, 0, PORTRAIT * 0.45 + 40)
	stripe.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	stripe.BackgroundTransparency = 0.15
	stripe.BorderSizePixel = 0
	stripe.Parent = frame
	corner(stripe, UDim.new(0, 12))

	local portrait = Instance.new("Frame")
	portrait.AnchorPoint = Vector2.new(0.5, 0)
	portrait.Position = UDim2.new(0.5, 0, 0, 2)
	portrait.Size = UDim2.fromOffset(PORTRAIT, PORTRAIT)
	portrait.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
	portrait.Parent = frame
	corner(portrait, UDim.new(1, 0))
	local ring = Instance.new("UIStroke")
	ring.Thickness = 5
	ring.Color = Color3.new(1, 1, 1)
	ring.Parent = portrait

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	viewport.Parent = portrait
	corner(viewport, UDim.new(1, 0))

	-- Medalla de vidas (arriba a la derecha del retrato)
	local badge = Instance.new("Frame")
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(0.5, PORTRAIT * 0.42, 0, PORTRAIT * 0.16)
	badge.Size = UDim2.fromOffset(30, 30)
	badge.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	badge.ZIndex = 3
	badge.Parent = frame
	corner(badge, UDim.new(1, 0))
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Thickness = 2
	badgeStroke.Color = Color3.new(1, 1, 1)
	badgeStroke.Parent = badge
	local stocksLabel = makeText(badge, Enum.Font.GothamBlack, UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1))
	stocksLabel.ZIndex = 4

	local nameLabel = makeText(frame, Enum.Font.GothamBold, UDim2.new(1, -8, 0, 16), UDim2.new(0, 4, 0, PORTRAIT + 6))
	local percentLabel = makeText(frame, Enum.Font.GothamBlack, UDim2.new(1, -8, 0, 20), UDim2.new(0, 4, 0, PORTRAIT + 22))
	local scale = Instance.new("UIScale")
	scale.Parent = percentLabel

	return {
		frame = frame,
		nameLabel = nameLabel,
		percentLabel = percentLabel,
		stocksLabel = stocksLabel,
		portrait = portrait,
		ring = ring,
		viewport = viewport,
		portraitKey = nil,
		stripe = stripe,
		scale = scale,
		lastPercent = 0,
		shakeUntil = 0,
	}
end

-- Retrato: copia estática del personaje (cabeza, pelo/capucha) dentro del ViewportFrame.
local function rebuildPortrait(model: Model, card: Card)
	card.viewport:ClearAllChildren()
	local wasArchivable = model.Archivable
	model.Archivable = true
	local ok, copy = pcall(function()
		return model:Clone()
	end)
	model.Archivable = wasArchivable
	if not ok or not copy then
		return
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Highlight") or d:IsA("BillboardGui") or d:IsA("Sound") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local world = Instance.new("WorldModel")
	world.Parent = card.viewport
	copy.Parent = world
	local head = copy:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	-- De frente y un poco de lado, encuadrando la cabeza
	local look = head.CFrame.LookVector
	local eye = head.Position + look * 6 + head.CFrame.RightVector * 1.5 + Vector3.new(0, 0.6, 0)
	camera.CFrame = CFrame.lookAt(eye, head.Position + Vector3.new(0, -0.2, 0))
	camera.Parent = card.viewport
	card.viewport.CurrentCamera = camera
end

local function updateCard(model: Model, card: Card)
	local style = CharacterStyles[model:GetAttribute("FighterId")]
	local teamColor = if style and style.hudColor then Color3.fromHex(style.hudColor) else Color3.fromRGB(150, 150, 150)
	card.stripe.BackgroundColor3 = Color3.fromRGB(18, 18, 26):Lerp(teamColor, 0.25)
	card.portrait.BackgroundColor3 = Color3.fromRGB(26, 28, 40):Lerp(teamColor, 0.35)
	card.nameLabel.Text = model:GetAttribute("DisplayName") or model.Name

	-- Rehacer el retrato si cambió el personaje o el arma (y cuando ya cargó el aspecto)
	local key = `{model:GetAttribute("FighterId")}|{model:GetAttribute("Weapon")}`
	if card.portraitKey ~= key and model:FindFirstChild("Head") then
		card.portraitKey = key
		task.delay(0.6, function() -- deja que se peguen pelo/capucha/arma
			if cards[model] == card then
				rebuildPortrait(model, card)
			end
		end)
	end

	local percent = math.floor(model:GetAttribute("Percent") or 0)
	local damageColor = percentColor(percent)
	card.percentLabel.Text = `{percent}%`
	card.percentLabel.TextColor3 = damageColor
	card.ring.Color = damageColor
	if percent > card.lastPercent then
		-- Golpe recibido: el número "salta" y el retrato tiembla
		card.scale.Scale = 1.35
		TweenService:Create(card.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		card.shakeUntil = os.clock() + 0.25
	end
	card.lastPercent = percent
	if os.clock() < card.shakeUntil then
		card.portrait.Position = UDim2.new(0.5, math.random(-4, 4), 0, 2 + math.random(-3, 3))
	else
		card.portrait.Position = UDim2.new(0.5, 0, 0, 2)
	end

	local stocks = model:GetAttribute("Stocks")
	card.stocksLabel.Text = if stocks then tostring(math.max(stocks, 0)) else "∞"
	card.frame.Visible = model:GetAttribute("State") ~= "Eliminated" or stocks ~= nil
end

-- Luchadores a mostrar: jugadores registrados + CPU (etiqueta CameraTarget).
local function currentFighters(): { Model }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character:GetAttribute("FighterId") then
			table.insert(list, character)
		end
	end
	for _, model in CollectionService:GetTagged("CameraTarget") do
		if model:IsA("Model") and model:IsDescendantOf(workspace) and model:GetAttribute("FighterId") then
			table.insert(list, model)
		end
	end
	return list
end

local function syncCards()
	local alive = {}
	for order, model in currentFighters() do
		alive[model] = true
		local card = cards[model]
		if not card then
			card = createCard(model)
			cards[model] = card
		end
		card.frame.LayoutOrder = order
		updateCard(model, card)
	end
	for model, card in cards do
		if not alive[model] then
			card.frame:Destroy()
			cards[model] = nil
		end
	end

	-- Combo: se muestra mientras alguien encadena golpes (2 o más) sin salir del hitstun.
	local comboModel = nil
	for model in alive do
		if model:GetAttribute("State") == "Hitstun" and (model:GetAttribute("ComboHits") or 0) >= 2 then
			comboModel = model
			break
		end
	end
	if comboModel then
		local hits = comboModel:GetAttribute("ComboHits")
		comboLabel.Text = `COMBO x{hits}  ·  {math.floor(comboModel:GetAttribute("ComboDamage") or 0)}%`
		comboLabel.Visible = true
		comboShownUntil = os.clock() + 1.2
		if hits > lastComboHits then
			comboScale.Scale = 1.3
			TweenService:Create(comboScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		lastComboHits = hits
	elseif os.clock() > comboShownUntil then
		comboLabel.Visible = false
		lastComboHits = 0
	end
end

local function createGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MatchHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	messageLabel = Instance.new("TextLabel")
	messageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	messageLabel.Position = UDim2.fromScale(0.5, 0.3)
	messageLabel.Size = UDim2.fromScale(0.6, 0.12)
	messageLabel.BackgroundTransparency = 1
	messageLabel.TextScaled = true
	messageLabel.Font = Enum.Font.GothamBlack
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextStrokeTransparency = 0
	messageLabel.Visible = false
	messageLabel.Parent = gui
	messageScale = Instance.new("UIScale")
	messageScale.Parent = messageLabel

	comboLabel = Instance.new("TextLabel")
	comboLabel.AnchorPoint = Vector2.new(1, 0)
	comboLabel.Position = UDim2.new(1, -24, 0, 170) -- debajo de las tarjetas
	comboLabel.Size = UDim2.fromOffset(320, 50)
	comboLabel.BackgroundTransparency = 1
	comboLabel.TextScaled = true
	comboLabel.Font = Enum.Font.GothamBlack
	comboLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
	comboLabel.TextStrokeTransparency = 0
	comboLabel.TextXAlignment = Enum.TextXAlignment.Right
	comboLabel.Visible = false
	comboLabel.Parent = gui
	comboScale = Instance.new("UIScale")
	comboScale.Parent = comboLabel

	-- Tarjetas arriba a la derecha (estilo Brawlhalla)
	cardsFrame = Instance.new("Frame")
	cardsFrame.Name = "Cards"
	cardsFrame.AnchorPoint = Vector2.new(1, 0)
	cardsFrame.Position = UDim2.new(1, -16, 0, 14)
	cardsFrame.Size = UDim2.new(0.7, 0, 0, 140)
	cardsFrame.BackgroundTransparency = 1
	cardsFrame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 16)
	layout.Parent = cardsFrame

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- duration = nil → se queda hasta el próximo mensaje.
-- big = true → texto enorme que entra con un "golpe" (cuenta atrás, ¡GAME!).
local function show(text: string, duration: number?, big: boolean?)
	showToken += 1
	local token = showToken
	messageLabel.Text = text
	messageLabel.Visible = true
	messageLabel.Size = if big then UDim2.fromScale(0.7, 0.22) else UDim2.fromScale(0.6, 0.12)
	messageScale.Scale = if big then 1.6 else 1
	if big then
		TweenService:Create(messageScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	if duration then
		task.delay(duration, function()
			if showToken == token then
				messageLabel.Visible = false
			end
		end)
	end
	return token
end

local function onMatchEvent(kind: string, data: { [string]: any })
	if kind == "Countdown" then
		-- "3, 2, 1" (el "¡YA!" llega con Start)
		task.spawn(function()
			for n = data.seconds or 3, 1, -1 do
				show(tostring(n), 0.9, true)
				task.wait(1)
			end
		end)
	elseif kind == "Start" then
		show("¡YA!", 0.9, true)
	elseif kind == "KO" then
		local text = `¡KO! {data.name}`
		if data.stocks ~= nil then
			text ..= ` — quedan {data.stocks}`
		end
		show(text, 1.5)
	elseif kind == "Victory" then
		-- "¡GAME!" y luego el ganador
		local token = show("¡GAME!", nil, true)
		task.delay(1.6, function()
			if showToken == token then
				show(if data.name then `¡{data.name} gana!` else "Sin ganador", nil)
			end
		end)
	end
end

function HudController.Start()
	-- En segundo plano para no bloquear a nadie.
	task.spawn(function()
		createGui()
		RunService.RenderStepped:Connect(syncCards)
		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local matchEvent = remotes:WaitForChild("MatchEvent") :: RemoteEvent
		matchEvent.OnClientEvent:Connect(onMatchEvent)
	end)
end

return HudController
