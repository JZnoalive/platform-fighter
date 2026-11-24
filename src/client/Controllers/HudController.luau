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
	stripe: Frame,
	scale: UIScale,
	lastPercent: number,
}
local cards: { [Model]: Card } = {}

-- Color del % según el daño: blanco → amarillo → naranja → rojo.
local PERCENT_COLORS = {
	{ 0, Color3.fromRGB(255, 255, 255) },
	{ 50, Color3.fromRGB(255, 230, 90) },
	{ 100, Color3.fromRGB(255, 140, 40) },
	{ 150, Color3.fromRGB(230, 30, 30) },
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

local function createCard(model: Model): Card
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(190, 84)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	frame.BackgroundTransparency = 0.25
	frame.Parent = cardsFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stripe = Instance.new("Frame")
	stripe.Size = UDim2.new(0, 8, 1, 0)
	stripe.BorderSizePixel = 0
	stripe.Parent = frame
	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 10)
	stripeCorner.Parent = stripe

	local nameLabel = makeText(frame, Enum.Font.GothamBold, UDim2.new(1, -20, 0, 18), UDim2.fromOffset(16, 4))
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	local percentLabel = makeText(frame, Enum.Font.GothamBlack, UDim2.new(0, 120, 0, 44), UDim2.fromOffset(16, 22))
	percentLabel.TextXAlignment = Enum.TextXAlignment.Left
	local scale = Instance.new("UIScale")
	scale.Parent = percentLabel

	local stocksLabel = makeText(frame, Enum.Font.GothamBold, UDim2.new(0, 60, 0, 20), UDim2.new(1, -66, 1, -26))
	stocksLabel.TextXAlignment = Enum.TextXAlignment.Right

	return {
		frame = frame,
		nameLabel = nameLabel,
		percentLabel = percentLabel,
		stocksLabel = stocksLabel,
		stripe = stripe,
		scale = scale,
		lastPercent = 0,
	}
end

local function updateCard(model: Model, card: Card)
	local style = CharacterStyles[model:GetAttribute("FighterId")]
	card.stripe.BackgroundColor3 = if style and style.hudColor
		then Color3.fromHex(style.hudColor)
		else Color3.fromRGB(150, 150, 150)
	card.nameLabel.Text = model:GetAttribute("DisplayName") or model.Name

	local percent = math.floor(model:GetAttribute("Percent") or 0)
	card.percentLabel.Text = `{percent}%`
	card.percentLabel.TextColor3 = percentColor(percent)
	if percent > card.lastPercent then
		-- "Salto" del número al recibir daño
		card.scale.Scale = 1.35
		TweenService:Create(card.scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	card.lastPercent = percent

	local stocks = model:GetAttribute("Stocks")
	card.stocksLabel.Text = if stocks then string.rep("●", math.max(stocks, 0)) else ""
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

	comboLabel = Instance.new("TextLabel")
	comboLabel.AnchorPoint = Vector2.new(1, 0)
	comboLabel.Position = UDim2.new(1, -24, 0, 90)
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

	cardsFrame = Instance.new("Frame")
	cardsFrame.Name = "Cards"
	cardsFrame.AnchorPoint = Vector2.new(0.5, 1)
	cardsFrame.Position = UDim2.new(0.5, 0, 1, -16)
	cardsFrame.Size = UDim2.new(1, -32, 0, 84)
	cardsFrame.BackgroundTransparency = 1
	cardsFrame.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 16)
	layout.Parent = cardsFrame

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- duration = nil → se queda hasta el próximo mensaje.
local function show(text: string, duration: number?)
	showToken += 1
	local token = showToken
	messageLabel.Text = text
	messageLabel.Visible = true
	if duration then
		task.delay(duration, function()
			if showToken == token then
				messageLabel.Visible = false
			end
		end)
	end
end

local function onMatchEvent(kind: string, data: { [string]: any })
	if kind == "Start" then
		show(if data.mode == "VsCpu" then "¡Contra la CPU! ¡A pelear!" else "¡A pelear!", 1.5)
	elseif kind == "KO" then
		local text = `¡KO! {data.name}`
		if data.stocks ~= nil then
			text ..= ` — quedan {data.stocks}`
		end
		show(text, 1.5)
	elseif kind == "Victory" then
		show(if data.name then `¡{data.name} gana!` else "Sin ganador", nil)
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
