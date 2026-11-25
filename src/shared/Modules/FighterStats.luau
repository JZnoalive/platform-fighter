-- ReplicatedStorage.Shared.Modules.FighterStats
-- Stats estilo "leyenda" (Fuerza / Destreza / Defensa / Velocidad, de 3 a 9; 5 = normal).
-- Los datos de cada personaje están en Config/CharacterStyles.luau (campo stats).
-- Lo usan servidor y cliente, así el ritmo de los ataques nunca se desincroniza.
--
--   Fuerza    → más daño y knockback al golpear
--   Destreza  → ataques LIGEROS más rápidos (startup y recovery)
--   Defensa   → recibes menos daño y knockback
--   Velocidad → corres y te mueves en el aire más rápido

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterStyles = require(ReplicatedStorage.Shared.Config.CharacterStyles)
local Movesets = require(ReplicatedStorage.Shared.Modules.Movesets)

local FighterStats = {}

-- Cuánto cambia cada punto por encima/debajo de 5
local PER_POINT = {
	strengthKnockback = 0.04,
	strengthDamage = 0.03,
	defenseKnockback = 0.035,
	defenseDamage = 0.03,
	dexterityTiming = 0.03,
	speedMove = 0.03,
}

local LIGHT_MOVES = {
	Jab = true,
	SideLight = true,
	UpLight = true,
	DownLight = true,
	AirLight = true,
	AirUpLight = true,
	AirDownLight = true,
}

local DEFAULT = { strength = 5, dexterity = 5, defense = 5, speed = 5 }

function FighterStats.Get(fighterId: string?)
	local style = fighterId and CharacterStyles[fighterId]
	return (style and style.stats) or DEFAULT
end

-- Multiplicador de daño/knockback de un golpe (atacante → objetivo).
function FighterStats.HitMultipliers(attackerId: string?, targetId: string?): (number, number)
	local a, t = FighterStats.Get(attackerId), FighterStats.Get(targetId)
	local knockback = (1 + (a.strength - 5) * PER_POINT.strengthKnockback)
		* (1 - (t.defense - 5) * PER_POINT.defenseKnockback)
	local damage = (1 + (a.strength - 5) * PER_POINT.strengthDamage)
		* (1 - (t.defense - 5) * PER_POINT.defenseDamage)
	return damage, knockback
end

function FighterStats.SpeedMultiplier(fighterId: string?): number
	return 1 + (FighterStats.Get(fighterId).speed - 5) * PER_POINT.speedMove
end

-- Moveset de un arma YA ajustado a la Destreza del personaje (con caché).
local cache: { [string]: any } = {}

function FighterStats.Moveset(weapon: string?, fighterId: string?)
	local base = weapon and Movesets[weapon]
	if not base then
		return nil
	end
	local key = `{weapon}|{fighterId or "-"}`
	local cached = cache[key]
	if cached then
		return cached
	end
	local factor = 1 - (FighterStats.Get(fighterId).dexterity - 5) * PER_POINT.dexterityTiming
	local scaled = {}
	for moveName, data in base do
		if LIGHT_MOVES[moveName] and factor ~= 1 then
			local copy = table.clone(data)
			copy.startup = data.startup * factor
			copy.recovery = data.recovery * factor
			scaled[moveName] = copy
		else
			scaled[moveName] = data
		end
	end
	cache[key] = scaled
	return scaled
end

-- Personajes elegibles, en orden (para menús).
FighterStats.Roster = { "Brawler", "Blade", "Umbra", "Volta" }

return FighterStats
