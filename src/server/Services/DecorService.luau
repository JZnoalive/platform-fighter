-- ServerScriptService.Server.Services.DecorService
-- Escenario de la demo por código: "templo flotante al atardecer".
--   • Iluminación de atardecer (Lighting, Atmosphere, color, brillo).
--   • Plataformas de Arena con material/color de piedra y borde de luz.
--   • Fondo (Workspace.Decor): sol, islas flotantes, columnas y roca bajo el escenario.
-- Solo se monta si GameConfig.BuildDecor = true y no existe ya Workspace.Decor
-- (si algún día se decora a mano en Studio, se respeta lo hecho a mano).
--
-- Reglas: NO mueve ni cambia el tamaño de nada en Arena (solo color/material);
-- todo lo nuevo va DETRÁS (Z negativo), sin colisión ni hitbox.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DecorService = {}

local STONE = Color3.fromRGB(118, 104, 128)
local STONE_DARK = Color3.fromRGB(70, 60, 82)
local TRIM = Color3.fromRGB(255, 170, 90)

local function makePart(folder: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = folder
	return part
end

local function setupLighting()
	Lighting.ClockTime = 17.6
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(90, 70, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 110, 120)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(255, 190, 160)
	atmosphere.Decay = Color3.fromRGB(150, 80, 120)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting

	local correction = Lighting:FindFirstChild("DemoColor") or Instance.new("ColorCorrectionEffect")
	correction.Name = "DemoColor"
	correction.Saturation = 0.15
	correction.Contrast = 0.08
	correction.TintColor = Color3.fromRGB(255, 244, 236)
	correction.Parent = Lighting

	local bloom = Lighting:FindFirstChild("DemoBloom") or Instance.new("BloomEffect")
	bloom.Name = "DemoBloom"
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.3
	bloom.Parent = Lighting
end

local function styleArena(decor: Folder)
	local platforms = workspace:FindFirstChild("Arena") and workspace.Arena:FindFirstChild("Platforms")
	if not platforms then
		return
	end
	for _, platform in platforms:GetChildren() do
		if platform:IsA("BasePart") then
			-- Solo color y material (permitido por las reglas del proyecto).
			platform.Material = Enum.Material.Slate
			platform.Color = STONE
			-- Borde de luz en la parte de arriba-delantera (decoración aparte).
			local size, cf = platform.Size, platform.CFrame
			makePart(decor, {
				Name = platform.Name .. "_Trim",
				Size = Vector3.new(size.X, 0.15, 0.15),
				CFrame = cf * CFrame.new(0, size.Y / 2 - 0.075, size.Z / 2 - 0.075),
				Material = Enum.Material.Neon,
				Color = TRIM,
			})
		end
	end
	-- Roca colgando bajo la plataforma principal (detrás, para no tapar a nadie).
	local main = platforms:FindFirstChild("MainStage")
	if main and main:IsA("BasePart") then
		local x, y = main.Position.X, main.Position.Y - main.Size.Y / 2
		makePart(decor, {
			Name = "StageRockA",
			Size = Vector3.new(main.Size.X * 0.85, 10, 8),
			CFrame = CFrame.new(x, y - 5, -6),
			Material = Enum.Material.Rock,
			Color = STONE_DARK,
		})
		makePart(decor, {
			Name = "StageRockB",
			Size = Vector3.new(main.Size.X * 0.5, 10, 7),
			CFrame = CFrame.new(x, y - 14, -7),
			Material = Enum.Material.Rock,
			Color = STONE_DARK,
		})
		makePart(decor, {
			Name = "StageRockC",
			Size = Vector3.new(main.Size.X * 0.2, 8, 6),
			CFrame = CFrame.new(x, y - 22, -8),
			Material = Enum.Material.Rock,
			Color = STONE_DARK,
		})
	end
end

local function buildBackdrop(decor: Folder)
	-- Sol enorme al fondo
	makePart(decor, {
		Name = "Sun",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 90,
		Position = Vector3.new(60, 45, -420),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 170, 100),
	})

	-- Columnas del templo detrás del escenario (pares, con dintel)
	for _, x in { -48, -16, 16, 48 } do
		makePart(decor, {
			Name = "Column",
			Size = Vector3.new(3.5, 34, 3.5),
			Position = Vector3.new(x, 15, -30),
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(215, 200, 210),
		})
	end
	makePart(decor, {
		Name = "Lintel",
		Size = Vector3.new(104, 3, 5),
		Position = Vector3.new(0, 33, -30),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(200, 185, 200),
	})

	-- Islas flotantes lejanas (posiciones fijas para que siempre se vea igual)
	local islands = {
		{ -120, 10, -160, 40 },
		{ 110, 30, -180, 34 },
		{ -60, 55, -260, 50 },
		{ 160, -10, -240, 46 },
		{ -190, 40, -300, 60 },
		{ 30, -30, -140, 26 },
	}
	for i, data in islands do
		local x, y, z, w = data[1], data[2], data[3], data[4]
		makePart(decor, {
			Name = `Island{i}`,
			Size = Vector3.new(w, w * 0.25, w * 0.6),
			Position = Vector3.new(x, y, z),
			Material = Enum.Material.Grass,
			Color = Color3.fromRGB(120, 140, 100),
		})
		makePart(decor, {
			Name = `Island{i}_Rock`,
			Size = Vector3.new(w * 0.7, w * 0.45, w * 0.45),
			Position = Vector3.new(x, y - w * 0.3, z),
			Material = Enum.Material.Rock,
			Color = STONE_DARK,
		})
	end
end

function DecorService.Start()
	if not GameConfig.BuildDecor or workspace:FindFirstChild("Decor") then
		return
	end
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	setupLighting()
	styleArena(decor)
	buildBackdrop(decor)
	decor.Parent = workspace
	print("[DecorService] escenario de atardecer montado")
end

return DecorService
