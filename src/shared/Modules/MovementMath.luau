-- ReplicatedStorage.Shared.Modules.MovementMath
-- Cálculos PUROS del movimiento (sin Roblox: solo números). Los usa MovementController
-- y los comprueban las pruebas automáticas (src/shared/Tests).
-- cfg = Shared.Config.MovementConfig (o una tabla con los mismos campos).

local MovementMath = {}

-- Velocidad vertical del siguiente frame EN EL AIRE. La gravedad base ya la aplica
-- Roblox (workspace.Gravity = cfg.Gravity); aquí se suma la diferencia de cada fase:
--   punto alto (|vy| < ApexThreshold): pesa menos (ApexGravityMultiplier < 1)
--   bajando (vy < 0):                  pesa más (FallGravityMultiplier > 1)
--   caída rápida:                      acelera hacia FastFallSpeed (gradual, con tope)
-- hovering = true durante el arranque/golpe de un ataque aéreo: gravedad reducida y
-- caída limitada (manda sobre las demás fases y sobre la caída rápida).
function MovementMath.VerticalStep(vy: number, dt: number, cfg, fastFalling: boolean, hovering: boolean?): number
	local g = cfg.Gravity
	if hovering then
		vy += g * (1 - cfg.AirAttackGravityMultiplier) * dt
		return math.max(vy, -cfg.AirAttackMaxFallSpeed)
	end
	if math.abs(vy) < cfg.ApexThreshold then
		vy += g * (1 - cfg.ApexGravityMultiplier) * dt -- quita parte de la gravedad
	elseif vy < 0 then
		vy -= g * (cfg.FallGravityMultiplier - 1) * dt -- añade gravedad al bajar
	end
	if fastFalling then
		vy = math.max(vy - cfg.FastFallAcceleration * dt, -cfg.FastFallSpeed)
	end
	local cap = if fastFalling then cfg.FastFallSpeed else cfg.MaxFallSpeed
	return math.max(vy, -cap)
end

-- ¿Se puede empezar la caída rápida? Solo bajando o en el punto alto.
function MovementMath.CanStartFastFall(vy: number, cfg): boolean
	return vy < cfg.FastFallTrigger
end

-- Fase de un ataque según el tiempo desde que empezó.
function MovementMath.AttackPhase(elapsed: number, data): string
	if elapsed < data.startup then
		return "startup"
	elseif elapsed < data.startup + data.active then
		return "active"
	elseif elapsed < data.startup + data.active + data.recovery then
		return "recovery"
	end
	return "done"
end

-- Cuánto control horizontal hay (0..1) según la fase del ataque.
-- Suelo: sin control en arranque/golpe, parcial en la recuperación. Aire: reducido.
function MovementMath.ControlFactor(phase: string?, grounded: boolean, cfg): number
	if phase == nil or phase == "done" then
		return 1
	end
	if not grounded then
		return cfg.AirControlWhileAttacking
	end
	if phase == "recovery" then
		return cfg.GroundControlInRecovery
	end
	return 0
end

-- ¿Queda salto aéreo?
function MovementMath.CanAirJump(jumpsLeft: number): boolean
	return jumpsLeft > 0
end

-- Recursos aéreos (saltos, recovery, esquiva aérea). Se recargan al ATERRIZAR y al
-- RECIBIR UN GOLPE (como en el género). La esquiva aérea gasta la suya.
export type AirResources = { jumps: number, recovery: boolean, airDodge: boolean }

function MovementMath.FullResources(cfg): AirResources
	return { jumps = cfg.MaxAirJumps, recovery = true, airDodge = true }
end

function MovementMath.ConsumeAirDodge(res: AirResources): AirResources
	return { jumps = res.jumps, recovery = res.recovery, airDodge = false }
end

function MovementMath.ConsumeAirJump(res: AirResources): AirResources
	return { jumps = math.max(res.jumps - 1, 0), recovery = res.recovery, airDodge = res.airDodge }
end

return MovementMath
