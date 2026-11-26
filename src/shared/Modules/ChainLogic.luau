-- ReplicatedStorage.Shared.Modules.ChainLogic
-- Cadena de ataques ligeros (golpe 1 → 2 → 3). Lógica PURA, comprobada por las pruebas.
--   Cada pulsación dentro de la ventana avanza al siguiente golpe; si pasa demasiado
--   tiempo, o ya se hizo el último, vuelve a empezar por el primero (nunca en bucle).

local ChainLogic = {}

-- prevIndex: golpe anterior (0 = ninguno). lastAt: cuándo se pulsó. window: segundos.
-- Devuelve el número de golpe que toca ahora (1..length).
function ChainLogic.NextIndex(prevIndex: number, lastAt: number, now: number, window: number, length: number): number
	if prevIndex >= 1 and prevIndex < length and now - lastAt <= window then
		return prevIndex + 1
	end
	return 1
end

return ChainLogic
