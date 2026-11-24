-- ReplicatedStorage.Shared.Config.CpuConfig
-- Comportamientos de la CPU y cómo de "lista" es. Solo datos, sin lógica.
-- Lo usan CpuService (servidor) y el menú de práctica (cliente).

return {
	DefaultBehavior = "Idle",
	VsCpuBehavior = "Fight", -- comportamiento en la partida "contra la CPU"

	-- Orden en el que salen en el menú de práctica.
	Behaviors = { "Idle", "Walk", "Jump", "Dodge", "Attack", "Fight" },
	Labels = {
		Idle = "Quieta",
		Walk = "Caminar",
		Jump = "Saltar",
		Dodge = "Esquivar",
		Attack = "Atacar",
		Fight = "Pelear",
	},

	-- Porcentajes rápidos del menú
	PercentPresets = { 0, 50, 100, 150 },

	-- Movimiento
	SpeedMultiplier = 0.8, -- la CPU corre al 80 % de la velocidad del jugador
	PatrolHalfWidth = 20, -- "Caminar": va y viene entre X = -20 y X = 20
	JumpInterval = 1.2, -- "Saltar": segundos entre saltos

	-- Combate
	AttackRange = 6, -- distancia (studs) a la que empieza a atacar
	AttackInterval = 1.0, -- "Atacar": segundos entre ataques
	AttackCooldown = 0.55, -- "Pelear": pausa mínima entre ataques
	ReactionJitter = 0.4, -- "Pelear": pausa extra aleatoria (0 a este valor)
	DodgeReactRange = 9, -- esquiva si un jugador ataca más cerca que esto
	DodgeChance = 0.35, -- "Pelear": probabilidad de esquivar un ataque
	KillPercent = 90, -- "Pelear": desde este % del rival intenta rematar con pesados

	-- Escenario (para saber cuándo está fuera y tiene que volver)
	StageHalfWidth = 38, -- la plataforma principal va de X = -40 a 40
	StageTopY = 2, -- la parte de arriba de la plataforma principal
}
