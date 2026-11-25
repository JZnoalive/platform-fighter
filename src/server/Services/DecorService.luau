-- ServerScriptService.Server.Services.DecorService
-- Escenario de la demo por código, estilo 2D de "platform fighter" de día:
--   • Luz PLANA (sin sombras, ambiente alto, colores vivos) → se ve como un dibujo 2D.
--   • Isla principal: hierba verde viva arriba, tierra y roca marrón debajo.
--   • Plataformas flotantes de piedra clara (se atraviesan desde abajo).
--   • Fondo en CAPAS planas (parallax): islas cercanas, montañas pálidas, nubes blancas.
-- Diseño propio (no copia ningún escenario existente).
-- Solo se monta si GameConfig.BuildDecor = true y no existe ya Workspace.Decor
-- (si algún día se decora a mano en Studio, se respeta lo hecho a mano).
--
-- Reglas: NO mueve ni cambia el tamaño de nada en Arena (solo color/material);
-- todo lo nuevo va DETRÁS (Z negativo) o pegado a la cara delantera, sin colisión.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DecorService = {}

-- Paleta (60-30-10): verde hierba / tierra cálida / acentos de piedra clara
local GRASS = Color3.fromRGB(116, 206, 84)
local GRASS_DARK = Color3.fromRGB(70, 150, 60)
local DIRT = Color3.fromRGB(150, 98, 62)
local DIRT_DARK = Color3.fromRGB(104, 66, 44)
local STONE_LIGHT = Color3.fromRGB(222, 210, 186)
local STONE_EDGE = Color3.fromRGB(150, 135, 115)
local CLOUD = Color3.fromRGB(255, 255, 255)

local function makePart(folder: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = folder
	return part
end

local function setupLighting()
	-- Mediodía, luz plana: sin sombras y con mucho ambiente → colores "de dibujo".
	Lighting.ClockTime = 13
	Lighting.Brightness = 1.6
	Lighting.GlobalShadows = false
	Lighting.Ambient = Color3.fromRGB(165, 165, 175)
	Lighting.OutdoorAmbient = Color3.fromRGB(185, 185, 195)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.18 -- un poco de bruma azul: separa el fondo del plano de pelea
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(205, 228, 255)
	atmosphere.Decay = Color3.fromRGB(150, 195, 255)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.6
	atmosphere.Parent = Lighting

	local correction = Lighting:FindFirstChild("DemoColor") or Instance.new("ColorCorrectionEffect")
	correction.Name = "DemoColor"
	correction.Saturation = 0.28 -- colores vivos
	correction.Contrast = 0.1
	correction.Brightness = 0.02
	correction.TintColor = Color3.new(1, 1, 1)
	correction.Parent = Lighting

	local bloom = Lighting:FindFirstChild("DemoBloom") or Instance.new("BloomEffect")
	bloom.Name = "DemoBloom"
	bloom.Intensity = 0.5 -- solo brillan las chispas y el neón
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = Lighting

	-- Efectos que ya traía el place: se apagan para no DUPLICARLOS (doble bloom = brillo
	-- quemado; el desenfoque de fondo lo pone CameraController). Los rayos de sol son de
	-- look "cinematográfico 3D": fuera.
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("SunRaysEffect") then
			effect.Enabled = false
		elseif effect:IsA("BloomEffect") and effect ~= bloom then
			effect.Enabled = false
		elseif effect:IsA("DepthOfFieldEffect") then
			effect.Enabled = false
		elseif effect:IsA("ColorCorrectionEffect") and effect ~= correction then
			effect.Enabled = false
		end
	end
end

local function styleArena(decor: Folder)
	local platforms = workspace:FindFirstChild("Arena") and workspace.Arena:FindFirstChild("Platforms")
	if not platforms then
		return
	end
	for _, platform in platforms:GetChildren() do
		if not platform:IsA("BasePart") then
			continue
		end
		local size, cf = platform.Size, platform.CFrame
		platform.Material = Enum.Material.SmoothPlastic
		if platform.Name == "MainStage" then
			-- Isla principal: tierra + manto de hierba con borde que cuelga por delante.
			platform.Color = DIRT
			makePart(decor, {
				Name = "MainGrass",
				Size = Vector3.new(size.X + 0.4, 0.9, size.Z + 0.4),
				CFrame = cf * CFrame.new(0, size.Y / 2 - 0.35, 0), -- asoma 0,1 por encima: los pies no se hunden
				Color = GRASS,
			})
			makePart(decor, {
				Name = "MainGrassLip",
				Size = Vector3.new(size.X + 0.6, 0.7, 0.6),
				CFrame = cf * CFrame.new(0, size.Y / 2 - 0.55, size.Z / 2 + 0.25),
				Color = GRASS_DARK,
			})
		else
			-- Plataformas flotantes: losas de piedra clara con canto oscuro.
			platform.Color = STONE_LIGHT
			makePart(decor, {
				Name = platform.Name .. "_Edge",
				Size = Vector3.new(size.X + 0.2, size.Y * 0.45, size.Z + 0.2),
				CFrame = cf * CFrame.new(0, -size.Y * 0.35, 0),
				Color = STONE_EDGE,
			})
		end
	end

	-- Roca/tierra que cuelga bajo la isla principal, en escalones (silueta de isla flotante).
	local main = platforms:FindFirstChild("MainStage")
	if main and main:IsA("BasePart") then
		local x, y = main.Position.X, main.Position.Y - main.Size.Y / 2
		local tiers = {
			{ 0.92, 7, DIRT, -1 },
			{ 0.7, 8, DIRT_DARK, -2 },
			{ 0.45, 8, DIRT_DARK, -3 },
			{ 0.2, 7, DIRT_DARK, -4 },
		}
		local top = y
		for i, t in tiers do
			local h = t[2]
			makePart(decor, {
				Name = `StageRock{i}`,
				Size = Vector3.new(main.Size.X * t[1], h, main.Size.Z - 1),
				CFrame = CFrame.new(x, top - h / 2, t[4]),
				Color = t[3],
			})
			top -= h
		end
		-- Unas raíces colgando (detalle de dibujo)
		for i, rx in { -0.38, -0.12, 0.2, 0.36 } do
			makePart(decor, {
				Name = `Root{i}`,
				Size = Vector3.new(0.5, 5 + i, 0.5),
				CFrame = CFrame.new(x + main.Size.X * rx, y - 9 - i, main.Size.Z / 2 - 1),
				Color = DIRT_DARK,
			})
		end
	end
end

-- Nube "plana": discos blancos de cara a la cámara (sin sombreado de bola) + base
-- recta, como una nube dibujada.
local function cloud(decor: Folder, x: number, y: number, z: number, s: number)
	for j, off in { { -0.5, 0, 0.55 }, { -0.1, 0.18, 0.75 }, { 0.35, 0.08, 0.6 }, { 0.7, -0.02, 0.4 } } do
		local d = s * off[3]
		makePart(decor, {
			Name = "Cloud",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, d, d), -- disco: el eje X mira a la cámara tras girarlo
			CFrame = CFrame.new(x + off[1] * s, y + off[2] * s, z - j * 0.2) * CFrame.Angles(0, math.rad(90), 0),
			Color = CLOUD,
		})
	end
	-- base plana de la nube
	makePart(decor, {
		Name = "CloudBase",
		Size = Vector3.new(s * 1.35, s * 0.22, 0.4),
		CFrame = CFrame.new(x + 0.1 * s, y - s * 0.12, z - 1),
		Color = CLOUD,
	})
end

-- Isla flotante de fondo: losa de hierba + cono de tierra.
local function backIsland(decor: Folder, x: number, y: number, z: number, w: number, tint: number)
	local function shade(c: Color3): Color3
		return c:Lerp(Color3.fromRGB(170, 205, 245), tint) -- más azulada cuanto más lejos
	end
	makePart(decor, {
		Name = "BackIslandGrass",
		Size = Vector3.new(w, w * 0.08, w * 0.25),
		CFrame = CFrame.new(x, y, z),
		Color = shade(GRASS),
	})
	local top = y - w * 0.04
	for k, f in { 0.9, 0.62, 0.34 } do
		local h = w * 0.13
		makePart(decor, {
			Name = "BackIslandRock",
			Size = Vector3.new(w * f, h, w * 0.22),
			CFrame = CFrame.new(x, top - h / 2, z - k * 0.2),
			Color = shade(if k == 1 then DIRT else DIRT_DARK),
		})
		top -= h
	end
end

local function buildBackdrop(decor: Folder)
	-- Capa lejana: montañas pálidas (casi color cielo)
	-- (picos girados 45°: solo asoma la punta por debajo del horizonte)
	for i, m in { { -230, 110 }, { -120, 150 }, { 10, 120 }, { 140, 160 }, { 260, 115 } } do
		makePart(decor, {
			Name = `Mountain{i}`,
			Size = Vector3.new(m[2], m[2], 10),
			CFrame = CFrame.new(m[1], -95, -900) * CFrame.Angles(0, 0, math.rad(45)),
			Color = Color3.fromRGB(185, 212, 245),
		})
	end

	-- Capa media: islas flotantes azuladas
	backIsland(decor, -150, 25, -520, 70, 0.55)
	backIsland(decor, 170, 55, -560, 60, 0.6)
	backIsland(decor, 20, 85, -620, 45, 0.65)

	-- Capa cercana: islas más grandes y nítidas a los lados (no tapan la pelea)
	backIsland(decor, -95, -18, -230, 40, 0.25)
	backIsland(decor, 105, 8, -260, 34, 0.3)

	-- Nubes a varias distancias
	cloud(decor, -120, 70, -400, 40)
	cloud(decor, 60, 95, -450, 50)
	cloud(decor, 170, 40, -380, 34)
	cloud(decor, -150, -55, -420, 34) -- nubes bajas lejos, por debajo de la isla
	cloud(decor, 140, -60, -440, 40)
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
	print("[DecorService] escenario de isla (estilo 2D de día) montado")
end

return DecorService
