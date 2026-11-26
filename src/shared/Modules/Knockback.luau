-- ReplicatedStorage.Shared.Modules.Knockback
-- Knockback y hitstun de un golpe. Dos formas de configurarlo en cada ataque:
--   A) Ángulo + fuerza (la clásica):
--        fuerza = baseKnockback + porcentaje * knockbackScale ; dirección = angle
--   B) Empuje SEPARADO horizontal/vertical (más fácil de ajustar a mano):
--        knockback = Vector2.new(horizontal, vertical)  -- studs/s al 0 %
--        knockbackGrowth = 0.01  -- +1 % de empuje por cada punto de % del rival
-- Opcional en ambas: hitstun = segundos fijos (si no, sale de la fuerza).
-- El hitstop (congelación al impactar) se configura con hitstop = segundos (FighterService).
-- Sin Roblox: se puede probar con las pruebas automáticas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Knockback = {}

-- attack: datos del ataque. percent: % del objetivo YA sumado el daño de este golpe.
-- facing: 1 si el atacante mira a la derecha, -1 si mira a la izquierda.
-- multiplier (opcional): stats de Fuerza del atacante y Defensa del objetivo (FighterStats).
function Knockback.Compute(attack, percent: number, facing: number, multiplier: number?): (Vector3, number)
	local velocity
	if attack.knockback then
		local growth = 1 + percent * (attack.knockbackGrowth or 0.01)
		local kb: Vector2 = attack.knockback
		velocity = Vector3.new(kb.X * facing, kb.Y, 0) * growth * (multiplier or 1)
	else
		local force = (attack.baseKnockback + percent * attack.knockbackScale) * (multiplier or 1)
		local angle = math.rad(attack.angle)
		velocity = Vector3.new(math.cos(angle) * force * facing, math.sin(angle) * force, 0)
	end
	local hitstun = attack.hitstun
		or math.clamp(velocity.Magnitude * GameConfig.HitstunPerForce, GameConfig.MinHitstun, GameConfig.MaxHitstun)
	return velocity, hitstun
end

return Knockback
