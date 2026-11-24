-- StarterPlayer.StarterPlayerScripts.Client.Controllers.EffectsController
-- "Jugo" del combate, solo visual y en cada cliente:
--   • Golpe: chispa en el punto de impacto + destello blanco en el golpeado
--            + sacudida de cámara (más fuerte cuanto más vuela).
--   • KO: explosión grande donde salió + destello de pantalla + sacudida fuerte.
--   • Sonidos (si hay IDs en Shared.Config.AudioConfig) y música de fondo.
-- El servidor solo avisa (HitEvent, MatchEvent); no hay lógica de juego aquí.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioConfig = require(ReplicatedStorage.Shared.Config.AudioConfig)
local CameraController = require(script.Parent.CameraController)

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

local function onHit(targetModel: Model?, position: Vector3, force: number)
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
end

return EffectsController
