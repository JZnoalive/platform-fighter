-- StarterPlayer.StarterPlayerScripts.Client.Controllers.CameraController
-- Cámara lateral que encuadra a todos los luchadores.
-- Mira desde Z positivo hacia Z negativo: +X es la derecha de la pantalla.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CameraConfig = require(ReplicatedStorage.Shared.Config.CameraConfig)

local CameraController = {}

local function getFighterPositions(): { Vector3 }
	local positions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- Los eliminados (sin vidas) no cuentan para el encuadre.
		if root and character:GetAttribute("State") ~= "Eliminated" then
			table.insert(positions, root.Position)
		end
	end
	-- Luchadores que no son jugadores (la CPU): el servidor les pone la etiqueta "CameraTarget".
	for _, model in CollectionService:GetTagged("CameraTarget") do
		local root = model:FindFirstChild("HumanoidRootPart")
		if root and model:IsDescendantOf(workspace) then
			table.insert(positions, root.Position)
		end
	end
	return positions
end

local function computeTarget(camera: Camera): CFrame
	local positions = getFighterPositions()
	if #positions == 0 then
		local focus = CameraConfig.EmptyFocus
		local pitch = math.rad(CameraConfig.Pitch or 0)
		local d = CameraConfig.MinDistance
		return CFrame.lookAt(focus + Vector3.new(0, math.sin(pitch) * d, math.cos(pitch) * d), focus)
	end

	local minX, maxX = math.huge, -math.huge
	local minY, maxY = math.huge, -math.huge
	for _, pos in positions do
		minX = math.min(minX, pos.X)
		maxX = math.max(maxX, pos.X)
		minY = math.min(minY, pos.Y)
		maxY = math.max(maxY, pos.Y)
	end

	local padding = CameraConfig.Padding
	local width = (maxX - minX) + padding * 2
	local height = (maxY - minY) + padding * 2

	local viewport = camera.ViewportSize
	local aspect = viewport.X / math.max(viewport.Y, 1)
	local tanHalfV = math.tan(math.rad(CameraConfig.FieldOfView) / 2)

	local distForHeight = (height / 2) / tanHalfV
	local distForWidth = (width / 2) / (tanHalfV * aspect)
	local distance = math.clamp(
		math.max(distForHeight, distForWidth),
		CameraConfig.MinDistance,
		CameraConfig.MaxDistance
	)

	local center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2 + CameraConfig.HeightOffset, 0)
	-- Un poco desde arriba (estilo Smash): se ve la parte de arriba de las plataformas.
	local pitch = math.rad(CameraConfig.Pitch or 0)
	local offset = Vector3.new(0, math.sin(pitch) * distance, math.cos(pitch) * distance)
	return CFrame.lookAt(center + offset, center)
end

-- Sacudida de cámara (golpes fuertes, KO). intensity en studs, duration en segundos.
local shakeIntensity = 0
local shakeUntil = 0
local shakeDuration = 1

function CameraController.Shake(intensity: number, duration: number)
	local now = os.clock()
	-- Si ya hay una sacudida más fuerte en curso, se respeta.
	if now < shakeUntil and shakeIntensity >= intensity then
		return
	end
	shakeIntensity = intensity
	shakeDuration = math.max(duration, 0.01)
	shakeUntil = now + shakeDuration
end

function CameraController.Start()
	local camera = workspace.CurrentCamera
	local baseCFrame = camera.CFrame -- posición sin sacudida (la que se suaviza)

	RunService:BindToRenderStep("PlatformFighterCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		-- Roblox puede devolver la cámara a modo normal al reaparecer; se fuerza cada frame.
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = CameraConfig.FieldOfView

		local target = computeTarget(camera)
		local alpha = 1 - math.exp(-CameraConfig.Smoothing * dt)
		baseCFrame = baseCFrame:Lerp(target, alpha)

		local offset = Vector3.zero
		local remaining = shakeUntil - os.clock()
		if remaining > 0 then
			local strength = shakeIntensity * (remaining / shakeDuration)
			offset = Vector3.new((math.random() * 2 - 1) * strength, (math.random() * 2 - 1) * strength, 0)
		end
		camera.CFrame = baseCFrame + offset
	end)
end

return CameraController
