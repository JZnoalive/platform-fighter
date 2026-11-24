-- ReplicatedStorage.Shared.Config.MovementConfig
-- Cómo se mueve un luchador. Solo datos, sin lógica.
-- Unidades: studs y segundos. La gravedad es la de Roblox por defecto (196.2).

local MovementConfig = {
	-- Suelo
	GroundSpeed = 26, -- velocidad máxima corriendo
	GroundAcceleration = 220, -- qué tan rápido llega a la velocidad máxima
	GroundDeceleration = 300, -- qué tan rápido frena al soltar la tecla

	-- Aire
	AirSpeed = 22,
	AirAcceleration = 110,
	AirDeceleration = 40, -- bajo = conserva el impulso en el aire

	-- Saltos
	JumpVelocity = 75, -- salto desde el suelo (~14 studs de altura)
	AirJumpVelocity = 65, -- salto aéreo (~11 studs de altura)
	MaxAirJumps = 2,
	MaxFallSpeed = 90,

	-- Caída rápida (mantener S en el aire)
	FastFallSpeed = 115,
	FastFallTrigger = 10, -- se activa cuando ya no subes rápido (velocidad vertical < 10)

	-- Ayudas para que los controles se sientan justos
	CoyoteTime = 0.08, -- puedes saltar desde el suelo un instante después de dejarlo
	JumpBuffer = 0.1, -- si pulsas saltar justo antes de aterrizar, cuenta
	-- W también salta, pero espera este instante: si en ese tiempo pulsas un
	-- ataque, sale el ataque hacia arriba en vez de saltar. Space salta al instante.
	TapJumpWindow = 0.05,
}

return MovementConfig
