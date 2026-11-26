-- ReplicatedStorage.Shared.Config.MovementConfig
-- Cómo se mueve un luchador. Solo datos, sin lógica.
-- Unidades: studs y segundos. La gravedad es la de Roblox por defecto (196.2).

local MovementConfig = {
	-- GAME FEEL (prueba 1): gravedad más fuerte + salto más bajo = saltos cortos y rápidos
	-- (~1,3 cuerpos), como en el género. Antes: gravedad 196 y salto de ~14 studs (3 cuerpos).
	-- NÚCLEO DE COMBATE (iteración 2): TODOS los números del movimiento están aquí.
	Gravity = 200, -- (antes 250: caían demasiado rápido) gravedad base al SUBIR (la pone el servidor en workspace.Gravity)
	ApexThreshold = 9, -- |velocidad vertical| < esto = "punto alto" del salto
	ApexGravityMultiplier = 0.6, -- en el punto alto pesa menos (un instante de "flotar")
	FallGravityMultiplier = 1.05, -- al BAJAR pesa un poco más (antes 1.3)

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
	-- El avance de un ataque (lunge) se para si el rival está delante a menos de esto:
	-- así el atacante no atraviesa al rival y el siguiente golpe sigue a buena distancia.
	LungeStopDistance = 3,
	GroundControlInRecovery = 0.5, -- en el suelo: control durante la RECUPERACIÓN del ataque
	-- (durante el arranque y el golpe del ataque en el suelo no hay control: solo esa ventana)

	-- Saltos (altura ≈ v² / (2·gravedad))
	JumpVelocity = 54, -- ~7 studs con gravedad 200
	AirJumpVelocity = 47, -- ~5,5 studs
	MaxAirJumps = 2,
	MaxFallSpeed = 40, -- (antes 72: caían demasiado rápido)

	-- Caída rápida (mantener S en el aire). GRADUAL: acelera hacia FastFallSpeed, no se
	-- teletransporta. Solo empieza cuando ya bajas o estás en el punto alto.
	FastFallSpeed = 62, -- velocidad máxima de la caída rápida (antes 105: bajaba de golpe)
	FastFallAcceleration = 160, -- studs/s² extra mientras dura (antes 480)
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
