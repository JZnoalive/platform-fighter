-- ReplicatedStorage.Shared.Config.Weapons.Scythe
-- Moveset del arma "Guadaña": mucho alcance y golpes en arco.
-- Su seña de identidad es el GANCHO con ACTIVE INPUT (como la guadaña de Brawlhalla):
-- Jab, SideLight, AirLight y AirDownLight ENGANCHAN al rival (campo hook), lo arrastran
-- delante de ti con una cadena y, al soltar, sale lanzado hacia donde mantengas:
-- adelante, o ATRÁS (por detrás de ti). Casi no tiene combos verdaderos: vive de leer
-- la esquiva del rival. String típica: SideLight (atrás) > Jab > AirDownLight > AirLight.
--   hook = { damage = daño del enganche, pullTime = s arrastrando, holdTime = s sujetando,
--            holdOffset = Vector2 delante/arriba del atacante donde queda el rival }
--   (damage/baseKnockback/angle del ataque son los del LANZAMIENTO)
-- Mismos 12 ataques y campos que Gauntlets.luau (ver su cabecera).

return {
	---------------------------------------------------------------- LIGEROS EN EL SUELO
	-- GANCHO por arriba (NLight): la hoja baja desde arriba, engancha, atrae al rival
	-- delante de ti y lo lanzas hacia donde mantengas (adelante o ATRÁS).
	Jab = {
		startup = 0.09,
		active = 0.1,
		recovery = 0.14,
		damage = 4, -- daño del lanzamiento
		baseKnockback = 22,
		knockbackScale = 0.18,
		angle = 50,
		activeInput = true,
		hook = { damage = 2, pullTime = 0.08, holdTime = 0.1, holdOffset = Vector2.new(2.6, 0.6) },
		hitbox = { offset = Vector2.new(4, 1), size = Vector3.new(7, 5, 6) },
	},

	-- GANCHO lateral (SLight): estira la guadaña MUY lejos, engancha y lo arrastra hasta
	-- ti; al soltar, lo lanzas adelante o por detrás (como en el vídeo: fuera del borde).
	SideLight = {
		startup = 0.12, -- arco pesado: da tiempo a elegir la dirección (active input)
		active = 0.12,
		recovery = 0.19,
		damage = 5, -- daño del lanzamiento
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 32,
		activeInput = true,
		hook = { damage = 3, pullTime = 0.1, holdTime = 0.1, holdOffset = Vector2.new(2.6, 0.3) },
		hitbox = { offset = Vector2.new(6, 0.3), size = Vector3.new(10, 4, 6) },
	},

	-- Arco por encima de la cabeza
	UpLight = {
		startup = 0.07,
		active = 0.14,
		recovery = 0.18,
		damage = 7,
		baseKnockback = 24,
		knockbackScale = 0.3,
		angle = 95,
		hitbox = { offset = Vector2.new(1, 5), size = Vector3.new(8, 5, 6) },
	},

	DownLight = {
		startup = 0.07,
		active = 0.12,
		recovery = 0.19,
		damage = 6,
		baseKnockback = 32, -- levanta algo menos que la espada: string, no combo seguro
		knockbackScale = 0.14,
		angle = 68,
		hitbox = { offset = Vector2.new(5, -2), size = Vector3.new(9, 2, 6) },
	},

	---------------------------------------------------------------- LIGEROS EN EL AIRE
	-- GANCHO aéreo (NAir): molinete que engancha alrededor; lo lanzas adelante o atrás
	-- (la base de los arrastres fuera del mapa: NAir atrás > SAir > DAir).
	AirLight = {
		startup = 0.06,
		active = 0.16,
		recovery = 0.16,
		damage = 4,
		baseKnockback = 22,
		knockbackScale = 0.28,
		angle = 45,
		activeInput = true,
		hook = { damage = 3, pullTime = 0.08, holdTime = 0.08, holdOffset = Vector2.new(2.4, 0) },
		hitbox = { offset = Vector2.new(3, 0), size = Vector3.new(8, 7, 6) },
	},

	AirUpLight = {
		startup = 0.06,
		active = 0.16,
		recovery = 0.16,
		damage = 7,
		baseKnockback = 22,
		knockbackScale = 0.3,
		angle = 85,
		hitbox = { offset = Vector2.new(0, 4.5), size = Vector3.new(8, 5, 6) },
	},

	-- GANCHO hacia abajo (DAir): engancha por debajo y lo clava hacia abajo-adelante o
	-- abajo-atrás (ideal para echarlo fuera cuando vuelve por el borde).
	AirDownLight = {
		startup = 0.08,
		active = 0.14,
		recovery = 0.19,
		damage = 5,
		baseKnockback = 20,
		knockbackScale = 0.3,
		angle = -60,
		activeInput = true,
		hook = { damage = 3, pullTime = 0.08, holdTime = 0.08, holdOffset = Vector2.new(1.8, -2) },
		hitbox = { offset = Vector2.new(1.5, -4), size = Vector3.new(6, 5, 6) },
	},

	---------------------------------------------------------------- PESADOS
	-- FIRMA "Siega del alma": se lanza hacia delante con una siega enorme
	Heavy = {
		startup = 0.3,
		active = 0.22,
		recovery = 0.45,
		damage = 15,
		baseKnockback = 44,
		knockbackScale = 1.0,
		angle = 40,
		selfImpulse = Vector2.new(55, 3),
		impulseAtStartup = true,
		hitbox = { offset = Vector2.new(5.5, 0.5), size = Vector3.new(9, 5, 6) },
	},

	-- FIRMA "Rueda celeste": la guadaña gira por encima de la cabeza (3 impactos)
	UpHeavy = {
		startup = 0.3,
		active = 0.36,
		recovery = 0.45,
		hits = 3,
		damage = 5,
		baseKnockback = 44,
		knockbackScale = 0.98,
		angle = 88,
		linkKnockback = 14,
		linkAngle = 90,
		hitbox = { offset = Vector2.new(0, 5.5), size = Vector3.new(10, 8, 6) },
	},

	-- FIRMA "Trampa del abismo" (control de borde): barrido giratorio con 3 tajos a los
	-- dos lados; el último lanza RASO (casi horizontal), ideal para echar al rival fuera
	-- cuando intenta volver por el borde.
	DownHeavy = {
		startup = 0.28,
		active = 0.36,
		recovery = 0.5,
		hits = 3,
		damage = 5,
		baseKnockback = 44,
		knockbackScale = 0.92,
		angle = 14,
		awayFromAttacker = true,
		hitbox = { offset = Vector2.new(0, -1.5), size = Vector3.new(15, 3, 6) },
	},

	Recovery = {
		startup = 0.06,
		active = 0.3,
		recovery = 0.4,
		damage = 9,
		baseKnockback = 34,
		knockbackScale = 0.5,
		angle = 80,
		selfImpulse = Vector2.new(4, 80),
		hitbox = { offset = Vector2.new(2, 2), size = Vector3.new(7, 7, 6) },
	},

	GroundPound = {
		startup = 0.14,
		active = 0.35,
		recovery = 0.35,
		damage = 11,
		baseKnockback = 34,
		knockbackScale = 0.62,
		angle = 45,
		awayFromAttacker = true,
		selfImpulse = Vector2.new(0, -85),
		hitbox = { offset = Vector2.new(0, -3), size = Vector3.new(8, 4, 6) },
	},
}
