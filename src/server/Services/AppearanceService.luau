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
local WeaponStyles = require(ReplicatedStorage.Shared.Config.WeaponStyles)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)

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

-- Estela (Trail) a lo largo del eje más largo de la pieza: se ve al moverse rápido.
local function addTrail(part: BasePart, colorHex: string)
	local size = part.Size
	local axis
	if size.Z >= size.X and size.Z >= size.Y then
		axis = Vector3.new(0, 0, size.Z / 2)
	elseif size.Y >= size.X then
		axis = Vector3.new(0, size.Y / 2, 0)
	else
		axis = Vector3.new(size.X / 2, 0, 0)
	end
	local a0 = Instance.new("Attachment")
	a0.Position = axis
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = -axis
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(Color3.fromHex(colorHex))
	trail.Transparency = NumberSequence.new(0.3, 1)
	trail.Lifetime = 0.15
	trail.MinLength = 0.1
	trail.LightEmission = 0.8
	trail.FaceCamera = true
	trail.Parent = part
end

-- Crea un grupo de piezas pegadas al cuerpo dentro de un Model llamado folderName.
-- Si ya existía, lo borra y lo vuelve a crear.
local function buildPieces(character: Model, pieces, folderName: string)
	local old = character:FindFirstChild(folderName)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Model")
	folder.Name = folderName

	for _, piece in pieces do
		local bodyPart = findBodyPart(character, piece.part)
		if bodyPart then
			local part = Instance.new("Part")
			part.Name = piece.name
			part.Size = bodyPart.Size * piece.size.scale + piece.size.add
			local rotation = piece.rotation or Vector3.zero
			part.CFrame = bodyPart.CFrame
				* CFrame.new(bodyPart.Size * piece.offset.scale + piece.offset.add)
				* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
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

			if piece.trail then
				addTrail(part, piece.trail)
			end

			part.Parent = folder
		end
	end

	folder.Parent = character
end

-- Pega las piezas del PERSONAJE (pelo, gafas, botas...). Se puede llamar otra vez.
function AppearanceService.AddGear(character: Model, fighterId: string)
	local style = CharacterStyles[fighterId]
	if style then
		buildPieces(character, style.gear, "Gear")
	end
end

-- Cambia el ARMA: atributo "Weapon" (decide el moveset) + piezas del arma en las manos.
function AppearanceService.SetWeapon(character: Model, weaponId: string)
	local style = WeaponStyles[weaponId]
	if not style or not Movesets[weaponId] then
		warn("[AppearanceService] arma desconocida:", weaponId)
		return
	end
	character:SetAttribute("Weapon", weaponId)
	buildPieces(character, style.gear, "WeaponGear")
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
		-- Arma: la última que eligió en la práctica, o la de su personaje.
		local weapon = player:GetAttribute("PreferredWeapon")
		if type(weapon) ~= "string" or not WeaponStyles[weapon] then
			weapon = CharacterStyles[PLAYER_FIGHTER_ID].defaultWeapon
		end
		AppearanceService.SetWeapon(character, weapon)
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
