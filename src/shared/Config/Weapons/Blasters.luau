-- ReplicatedStorage.Shared.Config.Weapons.Blasters
-- Moveset del arma "Pistolas": los ligeros DISPARAN (proyectiles), los pesados
-- mezclan un disparo cargado con golpes cuerpo a cuerpo.
-- Mismos 12 ataques y campos que Gauntlets.luau (ver su cabecera), más:
--   projectile = {
--     speed = studs/segundo, range = studs que recorre antes de desaparecer,
--     angle = dirección del disparo (0 = adelante, 90 = arriba, -90 = abajo),
--     size  = Vector3 (el largo va en Z, en la dirección del disparo),
--     color = HEX, count = disparos a la vez, spread = grados entre ellos (abanico),
--   }
--   Con projectile, hitbox.offset es desde dónde sale el disparo.

local function shot(speed: number, range: number, angle: number, size: Vector3?, count: number?, spread: number?)
	return {
		speed = speed,
		range = range,
		angle = angle,
		size = size or Vector3.new(0.8, 0.8, 3),
		color = "7DF9FF",
		count = count or 1, -- varios disparos a la vez (abanico)
		spread = spread or 0, -- grados entre disparos del abanico
	}
end

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	-- Disparo rápido hacia delante
	Jab = {
		startup = 0.06,
		active = 0.05,
		recovery = 0.16,
		damage = 3,
		baseKnockback = 10,
		knockbackScale = 0.08,
		angle = 15,
		projectile = shot(150, 22, 0), -- alcance corto (estilo Brawlhalla)
		hitbox = { offset = Vector2.new(2, 0.5), size = Vector3.new(1, 1, 3) },
	},

	-- Disparo fuerte de largo alcance
	SideLight = {
		startup = 0.08,
		active = 0.05,
		recovery = 0.22,
		damage = 5,
		baseKnockback = 18,
		knockbackScale = 0.25,
		angle = 20,
		projectile = shot(170, 28, 0, Vector3.new(1, 1, 4)),
		hitbox = { offset = Vector2.new(2, 0.5), size = Vector3.new(1, 1, 4) },
	},

	-- Disparo en diagonal hacia arriba (anti-aéreo)
	UpLight = {
		startup = 0.07,
		active = 0.05,
		recovery = 0.19,
		damage = 4,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 85,
		projectile = shot(140, 20, 65),
		hitbox = { offset = Vector2.new(1, 2), size = Vector3.new(1, 1, 3) },
	},

	-- Patada baja (cuerpo a cuerpo)
	DownLight = {
		startup = 0.05,
		active = 0.1,
		recovery = 0.16,
		damage = 5,
		baseKnockback = 18,
		knockbackScale = 0.16,
		angle = 55,
		hitbox = { offset = Vector2.new(3, -2), size = Vector3.new(5, 2, 6) },
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	AirLight = {
		startup = 0.06,
		active = 0.05,
		recovery = 0.16,
		damage = 3,
		baseKnockback = 12,
		knockbackScale = 0.1,
		angle = 30,
		projectile = shot(150, 20, 0),
		hitbox = { offset = Vector2.new(2, 0), size = Vector3.new(1, 1, 3) },
	},

	AirUpLight = {
		startup = 0.06,
		active = 0.05,
		recovery = 0.16,
		damage = 4,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 85,
		projectile = shot(140, 18, 90),
		hitbox = { offset = Vector2.new(0, 2.5), size = Vector3.new(1, 1, 3) },
	},

	-- Disparo hacia abajo (castiga desde arriba)
	AirDownLight = {
		startup = 0.07,
		active = 0.05,
		recovery = 0.19,
		damage = 5,
		baseKnockback = 18,
		knockbackScale = 0.28,
		angle = -60,
		projectile = shot(140, 18, -90),
		hitbox = { offset = Vector2.new(0, -2.5), size = Vector3.new(1, 1, 3) },
	},

	---------------------------------------------------------------- PESADOS
	-- Disparo cargado grande: el que hace KO
	Heavy = {
		startup = 0.4,
		active = 0.06,
		recovery = 0.45,
		damage = 9, -- por disparo (abanico de 3)
		baseKnockback = 42,
		knockbackScale = 0.95,
		angle = 35,
		projectile = shot(130, 26, 0, Vector3.new(1.6, 1.6, 3.5), 3, 14), -- RÁFAGA: 3 disparos en abanico
		hitbox = { offset = Vector2.new(2.5, 0.5), size = Vector3.new(2.6, 2.6, 4) },
	},

	-- FIRMA "Cometa oblicuo": un disparo cargado enorme en DIAGONAL hacia arriba.
	-- Cubre el ángulo por donde vuelve el rival y lo castiga cuando salta.
	UpHeavy = {
		startup = 0.32,
		active = 0.06,
		recovery = 0.42,
		damage = 13,
		baseKnockback = 42,
		knockbackScale = 0.95,
		angle = 55,
		projectile = shot(115, 36, 45, Vector3.new(2.4, 2.4, 4)),
		hitbox = { offset = Vector2.new(2, 2), size = Vector3.new(2.4, 2.4, 4) },
	},

	-- Giro a ras de suelo a los dos lados
	-- FIRMA "Lluvia de balas": gira disparando a los dos lados (3 impactos)
	DownHeavy = {
		startup = 0.26,
		active = 0.3,
		recovery = 0.45,
		hits = 3,
		damage = 4,
		baseKnockback = 38,
		knockbackScale = 0.88,
		angle = 30,
		awayFromAttacker = true,
		hitbox = { offset = Vector2.new(0, -1), size = Vector3.new(12, 3, 6) },
	},

	-- Dispara hacia abajo y sale impulsado hacia arriba
	Recovery = {
		startup = 0.05,
		active = 0.25,
		recovery = 0.35,
		damage = 7,
		baseKnockback = 30,
		knockbackScale = 0.45,
		angle = -80,
		selfImpulse = Vector2.new(0, 85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(5, 5, 6) },
	},

	GroundPound = {
		startup = 0.12,
		active = 0.35,
		recovery = 0.3,
		damage = 10,
		baseKnockback = 34,
		knockbackScale = 0.6,
		angle = 45,
		awayFromAttacker = true,
		selfImpulse = Vector2.new(0, -85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(6, 4, 6) },
	},
}
