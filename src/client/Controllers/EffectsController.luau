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

local function flashModel(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.2
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	task.delay(0.08, function()
		highlight:Destroy()
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
	if heavy then
		burst(position, Color3.fromRGB(255, 150, 60), 1.5, 9, 0.22)
		burst(position, Color3.fromRGB(255, 255, 255), 1, 4, 0.12)
		CameraController.Shake(0.7, 0.25)
		playSound(AudioConfig.HitHeavy)
	else
		burst(position, Color3.fromRGB(255, 240, 170), 1, 4, 0.14)
		CameraController.Shake(0.15, 0.08)
		playSound(AudioConfig.HitLight)
	end
	if targetModel and targetModel.Parent then
		flashModel(targetModel)
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
local function ensureOutline(model: Model)
	if model:FindFirstChild("Outline") then
		return
	end
	local outline = Instance.new("Highlight")
	outline.Name = "Outline"
	outline.FillTransparency = 1
	outline.OutlineColor = Color3.fromRGB(15, 10, 20)
	outline.OutlineTransparency = 0.1
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = model
end

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
