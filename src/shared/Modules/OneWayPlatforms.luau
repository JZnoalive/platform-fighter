-- ReplicatedStorage.Shared.Modules.OneWayPlatforms
-- Plataformas flotantes de "un solo sentido" (como en Smash y Brawlhalla):
--   · desde ABAJO se atraviesan (saltando, o saliendo lanzado por un golpe)
--   · cayendo desde arriba te sostienen
--   · manteniendo S encima de una, te dejas caer a través de ella
-- Cómo funciona: las plataformas van en el grupo de colisión "SoftPlatform". Cada
-- luchador cambia sus piezas entre "Fighter" (choca) y "FighterThrough" (atraviesa).
-- Lo llama QUIEN MUEVE el cuerpo: el cliente para su personaje y CpuService para la CPU.

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local OneWayPlatforms = {}

OneWayPlatforms.PLATFORM_GROUP = "SoftPlatform"
OneWayPlatforms.SOLID_GROUP = "Fighter"
OneWayPlatforms.THROUGH_GROUP = "FighterThrough"
OneWayPlatforms.TAG = "SoftPlatform"
OneWayPlatforms.DROP_TIME = 0.35 -- segundos atravesando al dejarse caer

-- Servidor: crea los grupos y marca las plataformas flotantes (las piezas de
-- Arena.Platforms cuyo nombre empieza por "Platform"; el suelo principal sigue sólido).
function OneWayPlatforms.SetupServer()
	assert(RunService:IsServer(), "solo en el servidor")
	for _, name in { OneWayPlatforms.PLATFORM_GROUP, OneWayPlatforms.SOLID_GROUP, OneWayPlatforms.THROUGH_GROUP } do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(OneWayPlatforms.PLATFORM_GROUP, OneWayPlatforms.THROUGH_GROUP, false)
	-- Los luchadores no se empujan entre sí (como en el género: se atraviesan).
	for _, a in { OneWayPlatforms.SOLID_GROUP, OneWayPlatforms.THROUGH_GROUP } do
		for _, b in { OneWayPlatforms.SOLID_GROUP, OneWayPlatforms.THROUGH_GROUP } do
			PhysicsService:CollisionGroupSetCollidable(a, b, false)
		end
	end

	local arena = workspace:FindFirstChild("Arena")
	local platforms = arena and arena:FindFirstChild("Platforms")
	if platforms then
		for _, part in platforms:GetDescendants() do
			if part:IsA("BasePart") and string.sub(part.Name, 1, 8) == "Platform" then
				part.CollisionGroup = OneWayPlatforms.PLATFORM_GROUP
				CollectionService:AddTag(part, OneWayPlatforms.TAG)
			end
		end
	end
end

local watched: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function setGroup(model: Model, group: string)
	if not watched[model] then
		-- Piezas que se añadan después (armas, accesorios) heredan el grupo actual.
		watched[model] = true
		model.DescendantAdded:Connect(function(part)
			local mode = model:GetAttribute("CollisionMode")
			if part:IsA("BasePart") and type(mode) == "string" then
				part.CollisionGroup = mode
			end
		end)
	end
	if model:GetAttribute("CollisionMode") == group then
		return
	end
	model:SetAttribute("CollisionMode", group)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
end

-- ¿Está el cuerpo DENTRO o DEBAJO de alguna plataforma (por su anchura)?
-- Entonces debe atravesarla aunque esté cayendo (si no, Roblox lo empujaría raro).
local function overlapsFromBelow(root: BasePart, feetY: number): (boolean, boolean)
	local inside, standingOn = false, false
	for _, platform in CollectionService:GetTagged(OneWayPlatforms.TAG) do
		if platform:IsA("BasePart") then
			local half = platform.Size / 2
			local dx = math.abs(root.Position.X - platform.Position.X)
			if dx <= half.X + 1 then
				local top = platform.Position.Y + half.Y
				if feetY < top - 0.3 and root.Position.Y + 3 > platform.Position.Y - half.Y then
					inside = true
				elseif math.abs(feetY - top) < 0.8 then
					standingOn = true
				end
			end
		end
	end
	return inside, standingOn
end

-- Llamar cada frame. wantsDrop = mantiene S sin atacar.
-- state guarda el temporizador de "dejarse caer" de este luchador.
function OneWayPlatforms.Update(model: Model, root: BasePart, humanoid: Humanoid, wantsDrop: boolean, state: { dropUntil: number })
	local feetY = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
	local inside, standingOn = overlapsFromBelow(root, feetY)
	local now = os.clock()
	if wantsDrop and standingOn then
		state.dropUntil = now + OneWayPlatforms.DROP_TIME
	end
	local through = root.AssemblyLinearVelocity.Y > 1 or inside or now < state.dropUntil
	setGroup(model, if through then OneWayPlatforms.THROUGH_GROUP else OneWayPlatforms.SOLID_GROUP)
end

return OneWayPlatforms
