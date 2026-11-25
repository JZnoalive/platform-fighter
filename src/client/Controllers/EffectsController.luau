-- StarterPlayer.StarterPlayerScripts.Client.Controllers.EffectsController
-- "Jugo" del combate, solo visual y en cada cliente:
--   • Golpe: chispa en el punto de impacto + destello blanco en el golpeado
--            + sacudida de cámara (más fuerte cuanto más vuela).
--   • KO: explosión grande donde salió + destello de pantalla + sacudida fuerte.
--   • Sonidos (si hay IDs en Shared.Config.AudioConfig) y música de fondo.
-- El servidor solo avisa (HitEvent, MatchEvent); no hay lógica de juego aquí.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioConfig = require(ReplicatedStorage.Shared.Config.AudioConfig)
local CameraController = require(script.Parent.CameraController)
local MovementController = require(script.Parent.MovementController)

local EffectsController = {}

local HEAVY_FORCE = 70 -- desde esta fuerza de knockback el golpe se considera fuerte

local effectsFolder: Folder
local flashFrame: Frame

local function playSound(id: string)
	if id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{id}`
	sound.Volume = AudioConfig.Volume
	SoundService:PlayLocalSound(sound)
	task.delay(5, function()
		sound:Destroy()
	end)
end

-- Esfera de neón que crece y se desvanece.
local function burst(position: Vector3, color: Color3, startSize: number, endSize: number, duration: number)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Size = Vector3.one * startSize
	part.Position = Vector3.new(position.X, position.Y, 1) -- un poco hacia la cámara
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 0.1
	part.Parent = effectsFolder
	local tween = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.one * endSize, Transparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
	end)
end

-- Tinte de golpe (como Brawlhalla): BLANCO un instante y luego celeste pálido durante
-- todo el aturdimiento, para que se lea "no puede actuar". Reutiliza el Highlight del
-- contorno (Roblox limita cuántos Highlights se ven a la vez).
local HIT_WHITE = Color3.new(1, 1, 1)
local HITSTUN_TINT = Color3.fromRGB(190, 230, 255)
local tintTokens: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local function ensureOutline(model: Model): Highlight
	local existing = model:FindFirstChild("Outline")
	if existing and existing:IsA("Highlight") then
		return existing
	end
	local outline = Instance.new("Highlight")
	outline.Name = "Outline"
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(15, 10, 20)
	outline.OutlineTransparency = 0.1
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
	return outline
end

local function flashModel(model: Model, hitstun: number)
	local outline = ensureOutline(model)
	local token = (tintTokens[model] or 0) + 1
	tintTokens[model] = token
	outline.FillColor = HIT_WHITE
	outline.FillTransparency = 0.05
	task.delay(0.07, function()
		if tintTokens[model] ~= token then
			return
		end
		outline.FillColor = HITSTUN_TINT
		outline.FillTransparency = 0.55
	end)
	task.delay(math.max(hitstun, 0.1), function()
		if tintTokens[model] ~= token then
			return -- otro golpe lo renovó (combo)
		end
		TweenService:Create(outline, TweenInfo.new(0.12), { FillTransparency = 1 }):Play()
	end)
end

local function makeFx(): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Parent = effectsFolder
	return part
end

-- Chispa de impacto (referencia: vídeos de Brawlhalla + doc. de gráficos, sección 5):
--   núcleo blanco (dispara el bloom) + estrella de rayos amarillos orientada según el
--   golpe + fragmentos eléctricos que saltan y caen + luz puntual breve que ilumina
--   a los dos luchadores.
local SPARK_YELLOW = Color3.fromRGB(255, 214, 64)
local SPARK_ORANGE = Color3.fromRGB(255, 140, 40)

local function hitSpark(position: Vector3, direction: Vector3, strength: number)
	local pos = Vector3.new(position.X, position.Y, 1.5) -- delante de los luchadores
	local scale = 0.8 + strength * 0.9 -- 0..1 → tamaño

	-- 1. Núcleo blanco
	local core = makeFx()
	core.Shape = Enum.PartType.Ball
	core.Color = Color3.new(1, 1, 1)
	core.Size = Vector3.one * (1.2 * scale)
	core.Position = pos
	TweenService:Create(core, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * (4 * scale),
		Transparency = 1,
	}):Play()
	task.delay(0.12, function()
		core:Destroy()
	end)

	-- 2. Estrella de rayos: el más largo sigue la dirección del golpe
	local baseAngle = math.atan2(direction.Y, direction.X)
	local rays = 5 + math.floor(strength * 3)
	for i = 1, rays do
		local angle = baseAngle + (i - 1) * (2 * math.pi / rays) + (math.random() - 0.5) * 0.3
		local length = (if i == 1 then 6 else 2.5 + math.random() * 2) * scale
		local ray = makeFx()
		ray.Color = if i % 2 == 0 then SPARK_ORANGE else SPARK_YELLOW
		ray.Size = Vector3.new(0.35 * scale, 0.35 * scale, length)
		local dir = Vector3.new(math.cos(angle), math.sin(angle), 0)
		ray.CFrame = CFrame.lookAt(pos + dir * (length / 2), pos + dir * length)
		TweenService:Create(ray, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.05, 0.05, length * 1.5),
			CFrame = CFrame.lookAt(pos + dir * length, pos + dir * length * 2),
			Transparency = 1,
		}):Play()
		task.delay(0.18, function()
			ray:Destroy()
		end)
	end

	-- 3. Fragmentos eléctricos (partículas con gravedad)
	local holder = makeFx()
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.2
	holder.Position = pos
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 0.8), SPARK_YELLOW)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0, 0.3)
	emitter.Lifetime = NumberRange.new(0.25, 0.5)
	emitter.Speed = NumberRange.new(20 * scale, 45 * scale)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -90, 0)
	emitter.Drag = 4
	emitter.Rate = 0
	emitter.Parent = holder
	emitter:Emit(10 + math.floor(strength * 14))

	-- 4. Luz puntual de impacto
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 225, 150)
	light.Range = 10 + 10 * strength
	light.Brightness = 4 + 4 * strength
	light.Shadows = false
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(0.12), { Brightness = 0 }):Play()
	task.delay(0.6, function()
		holder:Destroy()
	end)
end

local function flashScreen(color: Color3, duration: number)
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 0.35
	TweenService:Create(flashFrame, TweenInfo.new(duration), { BackgroundTransparency = 1 }):Play()
end

-- Estela de humo detrás de quien sale volando fuerte (estilo Smash).
local LAUNCH_TRAIL_FORCE = 55
local function launchTrail(model: Model, duration: number)
	task.spawn(function()
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local untilTime = os.clock() + math.min(duration, 1.2)
		while root and root.Parent and os.clock() < untilTime do
			if root.AssemblyLinearVelocity.Magnitude > 8 then
				local puff = Instance.new("Part")
				puff.Shape = Enum.PartType.Ball
				puff.Material = Enum.Material.SmoothPlastic
				puff.Color = Color3.fromRGB(235, 230, 240)
				puff.Size = Vector3.one * 1.6
				puff.Position = Vector3.new(root.Position.X, root.Position.Y, -0.5)
				puff.Anchored = true
				puff.CanCollide = false
				puff.CanQuery = false
				puff.CanTouch = false
				puff.CastShadow = false
				puff.Transparency = 0.2
				puff.Parent = effectsFolder
				local tween = TweenService:Create(puff, TweenInfo.new(0.5), { Size = Vector3.one * 3.5, Transparency = 1 })
				tween:Play()
				tween.Completed:Connect(function()
					puff:Destroy()
				end)
			end
			task.wait(0.04)
		end
	end)
end

local function onHit(targetModel: Model?, position: Vector3, force: number, duration: number?, attackerModel: Model?)
	-- Si el golpe lo di yo: activa la chase dodge (esquiva recargada antes).
	if attackerModel and attackerModel == Players.LocalPlayer.Character then
		MovementController.NotifyLandedHit()
	end
	if targetModel and force >= LAUNCH_TRAIL_FORCE then
		launchTrail(targetModel, duration or 0.5)
	end
	local heavy = force >= HEAVY_FORCE
	-- Dirección del golpe: del atacante hacia el golpeado (para orientar la chispa).
	local direction = Vector3.new(1, 0.3, 0)
	local attackerRoot = attackerModel and attackerModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	if attackerRoot then
		local d = position - attackerRoot.Position
		if d.Magnitude > 0.1 then
			direction = Vector3.new(d.X, d.Y + 1, 0).Unit
		end
	end
	local strength = math.clamp(force / 110, 0, 1)
	hitSpark(position, direction, strength)
	if heavy then
		hitSpark(position, -direction, strength * 0.6) -- segunda estrella cruzada en los fuertes
		CameraController.Shake(0.7, 0.25)
		playSound(AudioConfig.HitHeavy)
	else
		CameraController.Shake(0.15, 0.08)
		playSound(AudioConfig.HitLight)
	end
	if targetModel and targetModel.Parent then
		flashModel(targetModel, duration or 0.3)
	end
end

local function onMatchEvent(kind: string, data: { [string]: any })
	if kind == "KO" and typeof(data.position) == "Vector3" then
		-- Explosión en el borde de la pantalla por donde salió.
		local pos = data.position :: Vector3
		local clamped = Vector3.new(math.clamp(pos.X, -95, 95), math.clamp(pos.Y, -35, 95), 0)
		-- Rayo de KO estilo Smash: haz de luz desde el borde hacia el centro del escenario.
		local toCenter = (Vector3.new(0, 15, 0) - clamped)
		if toCenter.Magnitude > 1 then
			local dir = toCenter.Unit
			local length = 70
			local beam = Instance.new("Part")
			beam.Anchored = true
			beam.CanCollide = false
			beam.CanQuery = false
			beam.CanTouch = false
			beam.CastShadow = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(255, 200, 90)
			beam.Size = Vector3.new(7, 7, length)
			beam.CFrame = CFrame.lookAt(clamped + dir * (length / 2), clamped + dir * length)
			beam.Parent = effectsFolder
			local tween = TweenService:Create(
				beam,
				TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Size = Vector3.new(0.2, 0.2, length * 1.3), Transparency = 1 }
			)
			tween:Play()
			tween.Completed:Connect(function()
				beam:Destroy()
			end)
		end
		burst(clamped, Color3.fromRGB(255, 120, 40), 4, 40, 0.6)
		burst(clamped, Color3.fromRGB(255, 255, 200), 2, 18, 0.35)
		flashScreen(Color3.new(1, 1, 1), 0.3)
		CameraController.Shake(1.4, 0.45)
		playSound(AudioConfig.KO)
	elseif kind == "Start" then
		playSound(AudioConfig.FightStart)
	elseif kind == "Victory" then
		playSound(AudioConfig.Victory)
	end
end

-- Contorno negro en los luchadores (estilo cartoon): se leen mejor sobre el fondo.
-- (ensureOutline está arriba: el tinte de golpe usa el mismo Highlight)
local function outlineLoop()
	while true do
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character and character:GetAttribute("FighterId") then
				ensureOutline(character)
			end
		end
		for _, model in CollectionService:GetTagged("CameraTarget") do
			if model:IsA("Model") and model:IsDescendantOf(workspace) then
				ensureOutline(model)
			end
		end
		task.wait(0.5)
	end
end

local function startMusic()
	if AudioConfig.MusicBattle == "" then
		return
	end
	local music = Instance.new("Sound")
	music.Name = "BattleMusic"
	music.SoundId = `rbxassetid://{AudioConfig.MusicBattle}`
	music.Volume = AudioConfig.MusicVolume
	music.Looped = true
	music.Parent = SoundService
	music:Play()
end

function EffectsController.Start()
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "LocalEffects"
	effectsFolder.Parent = workspace

	-- Capa blanca para el destello de pantalla del KO.
	task.spawn(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "ScreenFlash"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 10
		flashFrame = Instance.new("Frame")
		flashFrame.Size = UDim2.fromScale(1, 1)
		flashFrame.BackgroundTransparency = 1
		flashFrame.BorderSizePixel = 0
		flashFrame.Parent = gui
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

		local remotes = ReplicatedStorage.Shared:WaitForChild("Remotes")
		local hitEvent = remotes:WaitForChild("HitEvent") :: RemoteEvent
		hitEvent.OnClientEvent:Connect(onHit)
		local matchEvent = remotes:WaitForChild("MatchEvent") :: RemoteEvent
		matchEvent.OnClientEvent:Connect(onMatchEvent)
	end)

	startMusic()
	task.spawn(outlineLoop)
end

return EffectsController
