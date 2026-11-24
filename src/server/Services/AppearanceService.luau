-- ServerScriptService.Server.Services.AppearanceService
-- Viste a los luchadores en estilo "bloque estilizado" (M6, Opción A):
--   1. Cuerpo R15 básico con los colores de su paleta (sin ropa ni accesorios del avatar).
--   2. Piezas pegadas al cuerpo (guanteletes, gafas, espada...) según CharacterStyles.
-- Jugadores = Brawler. La CPU = Blade (la crea TrainingService con GetDescription).
-- Las piezas no chocan ni cuentan para las hitboxes: el combate no cambia nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local CharacterStyles = require(ReplicatedStorage.Shared.Config.CharacterStyles)

local AppearanceService = {}

local PLAYER_FIGHTER_ID = "Brawler"
local APPEARANCE_WAIT = 3 -- segundos máximos esperando a que Roblox cargue el avatar

-- Si el juego usa avatares R6, estas partes R15 no existen: se usa la equivalente.
local R6_FALLBACK = {
	Head = "Head",
	UpperTorso = "Torso",
	LowerTorso = "Torso",
	RightUpperArm = "Right Arm",
	RightLowerArm = "Right Arm",
	RightHand = "Right Arm",
	LeftUpperArm = "Left Arm",
	LeftLowerArm = "Left Arm",
	LeftHand = "Left Arm",
	RightUpperLeg = "Right Leg",
	RightLowerLeg = "Right Leg",
	RightFoot = "Right Leg",
	LeftUpperLeg = "Left Leg",
	LeftLowerLeg = "Left Leg",
	LeftFoot = "Left Leg",
}

local function findBodyPart(character: Model, name: string): BasePart?
	local part = character:FindFirstChild(name)
	if not part and R6_FALLBACK[name] then
		part = character:FindFirstChild(R6_FALLBACK[name])
	end
	return if part and part:IsA("BasePart") then part else nil
end

-- Descripción de avatar "limpia": cuerpo básico + colores de la paleta.
function AppearanceService.GetDescription(fighterId: string): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	local style = CharacterStyles[fighterId]
	if style then
		local colors = style.bodyColors
		desc.HeadColor = Color3.fromHex(colors.head)
		desc.TorsoColor = Color3.fromHex(colors.torso)
		desc.LeftArmColor = Color3.fromHex(colors.arms)
		desc.RightArmColor = Color3.fromHex(colors.arms)
		desc.LeftLegColor = Color3.fromHex(colors.legs)
		desc.RightLegColor = Color3.fromHex(colors.legs)
	end
	return desc
end

-- Pega las piezas del estilo al cuerpo. Se puede llamar otra vez: borra las anteriores.
function AppearanceService.AddGear(character: Model, fighterId: string)
	local style = CharacterStyles[fighterId]
	if not style then
		return
	end

	local old = character:FindFirstChild("Gear")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Model")
	folder.Name = "Gear"

	for _, piece in style.gear do
		local bodyPart = findBodyPart(character, piece.part)
		if bodyPart then
			local part = Instance.new("Part")
			part.Name = piece.name
			part.Size = bodyPart.Size * piece.size.scale + piece.size.add
			part.CFrame = bodyPart.CFrame * CFrame.new(bodyPart.Size * piece.offset.scale + piece.offset.add)
			part.Color = Color3.fromHex(piece.color)
			part.Material = Enum.Material[piece.material] or Enum.Material.SmoothPlastic
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false -- las hitboxes la ignoran
			part.CanTouch = false
			part.Massless = true -- no cambia la física del luchador
			part.CastShadow = false
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bodyPart
			weld.Part1 = part
			weld.Parent = part

			part.Parent = folder
		end
	end

	folder.Parent = character
end

-- Espera (como mucho APPEARANCE_WAIT s) a que Roblox termine de cargar el avatar,
-- para que no pise nuestros colores después.
local function waitForAppearance(player: Player)
	if player:HasAppearanceLoaded() then
		return
	end
	local loaded = false
	local connection = player.CharacterAppearanceLoaded:Connect(function()
		loaded = true
	end)
	local deadline = os.clock() + APPEARANCE_WAIT
	while not loaded and os.clock() < deadline do
		task.wait(0.1)
	end
	connection:Disconnect()
end

local function dressPlayerCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- ya hay etiqueta de %

	waitForAppearance(player)
	if not character.Parent then
		return
	end

	local ok, err = pcall(function()
		humanoid:ApplyDescription(AppearanceService.GetDescription(PLAYER_FIGHTER_ID))
	end)
	if not ok then
		warn("[AppearanceService] no se pudo aplicar el aspecto a", player.Name, err)
	end
	if character.Parent then
		AppearanceService.AddGear(character, PLAYER_FIGHTER_ID)
	end
end

function AppearanceService.Start()
	-- No cargar ropa ni accesorios del avatar de cada jugador: todos son el luchador.
	StarterPlayer.LoadCharacterAppearance = false

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			task.spawn(dressPlayerCharacter, player, character)
		end)
		if player.Character then
			task.spawn(dressPlayerCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return AppearanceService
