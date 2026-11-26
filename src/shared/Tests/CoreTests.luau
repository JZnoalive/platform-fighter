-- ReplicatedStorage.Shared.Tests.CoreTests
-- PRUEBAS AUTOMÁTICAS del núcleo de combate (lógica pura, sin abrir el juego).
-- Se ejecutan desde Studio (barra de comandos o el MCP):
--     require(game.ReplicatedStorage.Shared.Tests.CoreTests).Run()
-- Devuelve { passed, failed, lines } y lo imprime en el Output.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MovementConfig = require(Shared.Config.MovementConfig)
local GameConfig = require(Shared.Config.GameConfig)
local MovementMath = require(Shared.Modules.MovementMath)
local ChainLogic = require(Shared.Modules.ChainLogic)
local Knockback = require(Shared.Modules.Knockback)
local Movesets = require(Shared.Modules.Movesets)

local CoreTests = {}

local DT = 1 / 60

local tests: { { name: string, fn: () -> () } } = {}
local function test(name: string, fn: () -> ())
	table.insert(tests, { name = name, fn = fn })
end
local function check(condition: boolean, message: string)
	if not condition then
		error(message, 0)
	end
end

local sword = Movesets.Sword

---------------------------------------------------------------- SALTOS Y CAÍDA
test("No se pueden hacer más saltos aéreos que MaxAirJumps", function()
	local res = MovementMath.FullResources(MovementConfig)
	local done = 0
	for _ = 1, 10 do
		if MovementMath.CanAirJump(res.jumps) then
			res = MovementMath.ConsumeAirJump(res)
			done += 1
		end
	end
	check(done == MovementConfig.MaxAirJumps, `hizo {done} saltos, máximo {MovementConfig.MaxAirJumps}`)
end)

test("La caída rápida NO teletransporta (un frame no llega al tope)", function()
	local vy = MovementMath.VerticalStep(0, DT, MovementConfig, true)
	check(vy > -MovementConfig.FastFallSpeed, `en 1 frame bajó a {vy} (tope {-MovementConfig.FastFallSpeed})`)
	check(vy > -25, `cambio demasiado brusco en 1 frame: {vy}`)
end)

test("La caída rápida tiene velocidad máxima", function()
	local vy = 0
	local lowest = 0
	for _ = 1, 240 do
		vy = MovementMath.VerticalStep(vy, DT, MovementConfig, true)
		lowest = math.min(lowest, vy)
	end
	check(lowest >= -MovementConfig.FastFallSpeed - 1e-6, `superó el tope: {lowest}`)
	check(math.abs(vy + MovementConfig.FastFallSpeed) < 1e-3, `no llegó al tope: {vy}`)
end)

test("La caída rápida no empieza mientras subes rápido", function()
	check(not MovementMath.CanStartFastFall(30, MovementConfig), "permitió caída rápida subiendo a 30")
	check(MovementMath.CanStartFastFall(-5, MovementConfig), "no permitió caída rápida bajando")
end)

test("La caída rápida no gasta el recovery ni los saltos", function()
	local res = MovementMath.FullResources(MovementConfig)
	local before = table.clone(res)
	local vy = 0
	for _ = 1, 60 do
		vy = MovementMath.VerticalStep(vy, DT, MovementConfig, true)
	end
	check(res.recovery == before.recovery and res.jumps == before.jumps and res.airDodge == before.airDodge,
		"la caída rápida cambió los recursos aéreos")
end)

test("Al bajar se cae más rápido que al subir (gravedad separada)", function()
	local up = MovementMath.VerticalStep(30, DT, MovementConfig, false) - 30
	local down = MovementMath.VerticalStep(-30, DT, MovementConfig, false) + 30
	check(down < up, `bajando suma {down}, subiendo {up}: debería pesar más al bajar`)
end)

test("Un ataque aéreo no te hace caer de golpe (se puede encadenar en el aire)", function()
	-- Simula el ataque aéreo lateral entero empezando en el punto alto de un salto.
	local data = sword.AirSideLight
	local duration = data.startup + data.active + data.recovery
	local vy, y = 0, 0
	for _ = 1, math.ceil(duration / DT) do
		vy -= MovementConfig.Gravity * DT -- gravedad base (la pone Roblox)
		vy = MovementMath.VerticalStep(vy, DT, MovementConfig, false, true)
		y += vy * DT
	end
	check(vy >= -MovementConfig.AirAttackMaxFallSpeed - 1e-6, `cae a {vy}, más que el tope`)
	check(y > -5, `cayó {-y} studs durante el ataque (máx. 5)`)
end)

---------------------------------------------------------------- CADENA DE LIGEROS
test("La cadena pasa del golpe 1 al 2 y al 3", function()
	local w = GameConfig.LightChain.Window
	local i = ChainLogic.NextIndex(0, 0, 0, w, 3)
	check(i == 1, `primer golpe = {i}`)
	i = ChainLogic.NextIndex(i, 0, 0.3, w, 3)
	check(i == 2, `segundo golpe = {i}`)
	i = ChainLogic.NextIndex(i, 0.3, 0.6, w, 3)
	check(i == 3, `tercer golpe = {i}`)
end)

test("La cadena se reinicia si pasa la ventana", function()
	local w = GameConfig.LightChain.Window
	local i = ChainLogic.NextIndex(1, 0, w + 0.1, w, 3)
	check(i == 1, `tras la ventana volvió a {i} (esperado 1)`)
end)

test("La cadena termina: después del 3 vuelve al 1 (sin bucle)", function()
	local i = ChainLogic.NextIndex(3, 0, 0.1, GameConfig.LightChain.Window, 3)
	check(i == 1, `después del 3 salió {i}`)
end)

test("La espada tiene los 3 golpes de la cadena", function()
	for _, name in GameConfig.LightChain.Moves do
		check(sword[name] ~= nil, `falta el ataque {name}`)
	end
end)

---------------------------------------------------------------- ATAQUES Y GOLPES
test("Los ataques direccionales son ataques distintos", function()
	local names = { "Jab", "SideLight", "DownLight", "UpLight", "AirLight", "AirSideLight", "AirDownLight", "AirUpLight" }
	local seen = {}
	for _, name in names do
		local data = sword[name]
		check(data ~= nil, `falta {name}`)
		local v = Knockback.Compute(data, 0, 1)
		local key = string.format("%.1f|%.1f|%.2f", v.X, v.Y, data.hitbox.offset.X)
		check(not seen[key], `{name} es igual que {seen[key]}`)
		seen[key] = name
	end
end)

test("El ataque hacia arriba lanza en vertical", function()
	local v = Knockback.Compute(sword.UpLight, 0, 1)
	check(v.Y > math.abs(v.X) * 3, `UpLight lanza a ({v.X}, {v.Y}): no es vertical`)
end)

test("Un golpe da hitstun y knockback visibles (incluso con poco daño)", function()
	local v, hitstun = Knockback.Compute(sword.Jab, sword.Jab.damage, 1)
	check(hitstun >= GameConfig.MinHitstun, `hitstun {hitstun}`)
	check(v.Magnitude >= 10, `knockback demasiado pequeño: {v.Magnitude}`)
end)

test("Mirar a la izquierda invierte el empuje horizontal", function()
	local right = Knockback.Compute(sword.SideLight, 0, 1)
	local left = Knockback.Compute(sword.SideLight, 0, -1)
	check(math.abs(right.X + left.X) < 1e-6 and right.X > 0, "el empuje no se invierte con la orientación")
end)

---------------------------------------------------------------- RECURSOS AÉREOS
test("La esquiva aérea gasta su recurso y se recarga al aterrizar", function()
	local res = MovementMath.ConsumeAirDodge(MovementMath.FullResources(MovementConfig))
	check(res.airDodge == false, "la esquiva no gastó el recurso")
	res = MovementMath.FullResources(MovementConfig) -- aterrizar
	check(res.airDodge == true, "no se recargó al aterrizar")
end)

test("El recovery vuelve a estar disponible al aterrizar", function()
	local res = MovementMath.FullResources(MovementConfig)
	check(res.recovery == true and res.jumps == MovementConfig.MaxAirJumps, "aterrizar no recargó recovery/saltos")
end)

---------------------------------------------------------------- BLOQUEOS
test("Ningún ataque bloquea para siempre (al terminar hay control total)", function()
	for name, data in sword do
		local phase = MovementMath.AttackPhase(data.startup + data.active + data.recovery + 0.01, data)
		check(phase == "done", `{name} sigue en {phase} al terminar`)
		check(MovementMath.ControlFactor(phase, true, MovementConfig) == 1, `{name} no devuelve el control`)
	end
end)

test("El control solo se bloquea en arranque/golpe en el suelo", function()
	check(MovementMath.ControlFactor("startup", true, MovementConfig) == 0, "arranque en suelo debería bloquear")
	check(MovementMath.ControlFactor("recovery", true, MovementConfig) > 0, "recuperación en suelo debería dar control")
	check(MovementMath.ControlFactor("active", false, MovementConfig) > 0, "en el aire debería haber control reducido")
end)

function CoreTests.Run()
	local passed, failed = 0, 0
	local lines = {}
	for _, t in tests do
		local ok, err = pcall(t.fn)
		if ok then
			passed += 1
			table.insert(lines, "  ✔ " .. t.name)
		else
			failed += 1
			table.insert(lines, "  ✘ " .. t.name .. " → " .. tostring(err))
		end
	end
	table.insert(lines, 1, string.format("[CoreTests] %d correctas, %d fallidas", passed, failed))
	print(table.concat(lines, "\n"))
	return { passed = passed, failed = failed, lines = lines }
end

return CoreTests
