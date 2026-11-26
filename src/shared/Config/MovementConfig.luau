-- ReplicatedStorage.Shared.Config.MovementConfig
-- Cómo se mueve un luchador. Solo datos, sin lógica.
-- Unidades: studs y segundos. La gravedad es la de Roblox por defecto (196.2).

local MovementConfig = {
	-- GAME FEEL (prueba 1): gravedad más fuerte + salto más bajo = saltos cortos y rápidos
	-- (~1,3 cuerpos), como en el género. Antes: gravedad 196 y salto de ~14 studs (3 cuerpos).
	-- NÚCLEO DE COMBATE (iteración 2): TODOS los números del movimiento están aquí.
	Gravity = 250, -- gravedad base al SUBIR (la pone el servidor en workspace.Gravity)
	ApexThreshold = 9, -- |velocidad vertical| < esto = "punto alto" del salto
	ApexGravityMultiplier = 0.6, -- en el punto alto pesa menos (un instante de "flotar")
	FallGravityMultiplier = 1.3, -- al BAJAR pesa más (caída clara, no flotante)

	-- Suelo
	WalkSpeed = 20, -- caminar (mantener A/D)
	RunSpeed = 32, -- correr (después de un dash; se mantiene mientras sigas pulsando)
	GroundSpeed = 30, -- (lo usa la CPU)
	GroundAcceleration = 320, -- qué tan rápido llega a la velocidad máxima
	GroundDeceleration = 280, -- qué tan rápido frena al soltar la tecla (antes 300)
	DashSpeed = 48, -- dash: doble toque de A/D en el suelo
	DashTime = 0.15, -- duración del impulso del dash
	DashDoubleTapWindow = 0.25, -- tiempo máximo entre los dos toques

	-- Aire
	AirSpeed = 26,
	AirAcceleration = 230, -- control aéreo
	AirDeceleration = 70, -- frena algo al soltar (conserva parte del impulso)
	AirControlWhileAttacking = 0.6, -- control horizontal durante un ataque aéreo (reducido, no cero)
	-- Ataques aéreos: durante su arranque y golpe el personaje casi FLOTA (para poder
	-- encadenar en el aire sin caer de golpe). No afecta a los que bajan a propósito.
	AirAttackGravityMultiplier = 0.15,
	AirAttackMaxFallSpeed = 9,
	GroundControlInRecovery = 0.5, -- en el suelo: control durante la RECUPERACIÓN del ataque
	-- (durante el arranque y el golpe del ataque en el suelo no hay control: solo esa ventana)

	-- Saltos (altura ≈ v² / (2·gravedad))
	JumpVelocity = 60, -- ~7 studs
	AirJumpVelocity = 52, -- ~5,4 studs
	MaxAirJumps = 2,
	MaxFallSpeed = 72,

	-- Caída rápida (mantener S en el aire). GRADUAL: acelera hacia FastFallSpeed, no se
	-- teletransporta. Solo empieza cuando ya bajas o estás en el punto alto.
	FastFallSpeed = 105, -- velocidad máxima de la caída rápida
	FastFallAcceleration = 480, -- studs/s² extra hacia abajo mientras dura
	FastFallTrigger = 6, -- se puede activar cuando la velocidad vertical es menor que esto

	-- Esquiva (tiempos en GameConfig)
	DodgeSpeed = 55, -- esquiva con dirección en el suelo (rodar)
	AirDodgeSpeed = 45, -- esquiva en el aire (1 por vuelo)

	-- Ayudas para que los controles se sientan justos
	CoyoteTime = 0.08, -- puedes saltar desde el suelo un instante después de dejarlo
	JumpBuffer = 0.1, -- si pulsas saltar justo antes de aterrizar, cuenta
	-- W también salta, pero espera este instante: si en ese tiempo pulsas un
	-- ataque, sale el ataque hacia arriba en vez de saltar. Space salta al instante.
	TapJumpWindow = 0.05,
}

return MovementConfig
