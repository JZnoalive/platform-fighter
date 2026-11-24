-- StarterPlayer.StarterPlayerScripts.Client.Controllers.CameraController
-- Cámara lateral que encuadra a todos los luchadores.
-- Mira desde Z positivo hacia Z negativo: +X es la derecha de la pantalla.

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
	return positions
end

local function computeTarget(camera: Camera): CFrame
	local positions = getFighterPositions()
	if #positions == 0 then
		local focus = CameraConfig.EmptyFocus
		return CFrame.lookAt(focus + Vector3.new(0, 0, CameraConfig.MinDistance), focus)
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
	return CFrame.lookAt(center + Vector3.new(0, 0, distance), center)
end

function CameraController.Start()
	local camera = workspace.CurrentCamera

	RunService:BindToRenderStep("PlatformFighterCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		-- Roblox puede devolver la cámara a modo normal al reaparecer; se fuerza cada frame.
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = CameraConfig.FieldOfView

		local target = computeTarget(camera)
		local alpha = 1 - math.exp(-CameraConfig.Smoothing * dt)
		camera.CFrame = camera.CFrame:Lerp(target, alpha)
	end)
end

return CameraController
