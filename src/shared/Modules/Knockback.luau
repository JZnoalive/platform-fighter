-- ReplicatedStorage.Shared.Modules.Knockback
-- Fórmula de knockback de la demo. Simple a propósito.
--   fuerza  = baseKnockback + porcentaje * knockbackScale
--   hitstun = fuerza * HitstunPerForce (con mínimo y máximo)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Knockback = {}

-- attack: datos del ataque. percent: % del objetivo YA sumado el daño de este golpe.
-- facing: 1 si el atacante mira a la derecha, -1 si mira a la izquierda.
-- multiplier (opcional): stats de Fuerza del atacante y Defensa del objetivo (FighterStats).
function Knockback.Compute(attack, percent: number, facing: number, multiplier: number?): (Vector3, number)
	local force = (attack.baseKnockback + percent * attack.knockbackScale) * (multiplier or 1)
	local angle = math.rad(attack.angle)
	local velocity = Vector3.new(math.cos(angle) * force * facing, math.sin(angle) * force, 0)
	local hitstun = math.clamp(force * GameConfig.HitstunPerForce, GameConfig.MinHitstun, GameConfig.MaxHitstun)
	return velocity, hitstun
end

return Knockback
