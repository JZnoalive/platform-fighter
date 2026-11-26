# Núcleo de combate — iteraciones 1 y 2 (game feel)

Objetivo: que UN personaje (Vórtice, "Blade") con UNA arma (Espada) se sienta bien en la
sala de pruebas antes de añadir contenido. Es un **platform fighter original**: se copian
ideas de mecánica del género, no personajes, arte, sonidos, HUD ni código.

> **Estado: pendiente de la prueba de Jesús.** No está "terminado" hasta que Jesús lo
> juegue y grabe 30–60 s (ver checklist al final).

---

## Cómo probar

1. `rojo serve` conectado y **Play** en Studio (sala de pruebas: tú = Blade, CPU = Brawler).
2. **F2** abre el panel de depuración (estado, saltos, VY, recovery/esquiva, rival, últimos ataques con tiempos).
3. El menú de práctica tiene herramientas: Congelar rival, Hurtboxes, Flecha KB, Imprimir cadena.
4. Pruebas automáticas (barra de comandos de Studio, en Play o en Edit con Studio recién abierto):
   ```lua
   require(game.ReplicatedStorage.Shared.Tests.CoreTests).Run()
   ```
   **Resultado actual: 19 correctas, 0 fallidas.**

Controles: A/D moverse (doble toque = dash, luego corres), Space/W saltar, S caída rápida
(en el aire, bajando), J ligero, K pesado, esquiva con su tecla. Dirección + J/K = ataque direccional.

---

## Cambios (archivo → problema → antes/después → cómo se probó)

### P1 — Movimiento
**`src/shared/Config/MovementConfig.luau`** (todos los números del movimiento en un sitio)

| Valor | Antes | Ahora | Por qué |
|---|---|---|---|
| Gravity | 196 | 250 | saltos cortos y rápidos |
| JumpVelocity | 75 | 60 (~7 studs) | antes saltaba ~3 cuerpos |
| AirJumpVelocity | — | 52 | 2.º y 3.er salto algo más bajos |
| MaxAirJumps | 2 | 2 | (3 saltos en total con el del suelo) |
| ApexGravityMultiplier | — | 0.6 | un instante de "flotar" en el punto alto |
| FallGravityMultiplier | — | 1.3 | se cae más rápido que se sube |
| WalkSpeed / RunSpeed | 30 único | 20 / 32 | caminar y correr |
| DashSpeed / DashTime | — | 48 / 0.15 s | dash con doble toque |
| GroundAcceleration / Deceleration | — / 300 | 320 / 280 | respuesta inmediata |
| AirAcceleration / Deceleration | — | 230 / 70 | control aéreo; el dash jump conserva impulso |
| FastFallSpeed / Acceleration / Trigger | instantáneo | 105 / 480 / vy<6 | caída rápida GRADUAL y solo bajando |
| AirAttackGravityMultiplier | — | 0.15 | ver P4 |
| AirAttackMaxFallSpeed | — | 9 | ver P4 |

**`src/shared/Modules/MovementMath.luau`** (nuevo, solo matemáticas, con pruebas):
gravedad por fases, caída rápida, fase del ataque (arranque/golpe/recuperación), cuánto control
hay en cada fase y recursos aéreos (saltos, recovery, esquiva aérea).

**`src/client/Controllers/MovementController.luau`**: dash, correr, dash jump, gravedad por
fases, caída rápida gradual, control bloqueado **solo** en arranque/golpe en el suelo
(recuperación = 50 %, aire = 60 %), avance de los ataques (lunge) que se corta al acertar.

### P2 — Estados aéreos, esquiva y recovery
- Estados publicados para el panel: Grounded/Walking/Running/Jumping/Falling/FastFalling/
  Attacking/AirAttacking/Recovering/Dodging/AirDodging/Hitstun.
- Aterrizar o recibir un golpe recarga saltos, recovery y esquiva aérea.
- **Chase dodge**: tras acertar un golpe se puede esquivar cancelando el ataque
  (`FighterService.TryStartDodge`, `CombatController`).
- **Arreglo de hoy:** subiendo rápido ya no cuenta como "en el suelo" (antes, usar el Recovery
  cerca del suelo recargaba los saltos sin aterrizar).

### P3 — Cadena de ligeros y direccionales
- **`src/shared/Modules/ChainLogic.luau`** (nuevo) + `GameConfig.LightChain` = Jab → Jab2 → Jab3,
  ventana 0.55 s; si pasa la ventana vuelve al 1; tras el 3 vuelve al 1 (sin bucle).
- Buffer de ataque `GameConfig.AttackBufferWindow = 0.35`.
- Direccionales separados: neutral (cadena), lateral, abajo, arriba; aéreos neutral, lateral
  (**AirSideLight nuevo**), abajo, arriba; Recovery con arriba + pesado en el aire.

### P4 — Continuidad aérea (arreglo de hoy)
- **Problema:** en "salto 1 → salto 2 → aéreo lateral → aéreo arriba → recovery" el personaje
  caía ~8 studs durante el aéreo lateral y aterrizaba antes del siguiente ataque (salían
  UpLight/UpHeavy de suelo).
- **Arreglo:** durante un ataque aéreo (que no sea de bajada: picado, GroundPound, Recovery)
  la gravedad baja al 15 % y la caída se limita a 9 studs/s. Se aplica con una **fuerza física**
  (`HoverForce`), porque compensar la gravedad una vez por fotograma no bastaba: la física de
  Roblox va más rápido que la pantalla y el personaje seguía cayendo a −40. Flota desde que
  pulsas (no espera la confirmación del servidor).
- **Resultado medido en el juego:** salto 1 (y 13.4) → salto 2 (y 16.8) → AirSideLight (cae
  a −9 máx.) → AirUpLight en el aire (y 11.6) → Recovery sube hasta y 17.6. ✔

### P5 — Sensación del golpe
- **`src/shared/Modules/Knockback.luau`**: cada ataque puede definir `knockback` (horizontal,
  vertical) a 0 %, `knockbackGrowth`, `hitstun` y `hitstop` propios. Se invierte con la orientación.
- **`src/shared/Config/Weapons/Sword.luau`**: tiempos y empujes de todos los ataques.
  Cambio de hoy: hitstun Jab 0.3 → **0.42**, Jab2 0.32 → **0.44** (el rival salía del hitstun
  0.1 s antes del golpe siguiente y la cadena no era combo real).
- **Resultado medido:** Jab → Jab2 → Jab3 = **combo x3** (4 → 8 → 15 %), Jab3 empuja 11 studs.
- `FighterService`: hitstop por ataque, atributos HitAt/HitForce/HitDir para la reacción del cuerpo.
- `EffectsController`: sonido de golpe ligero/fuerte y de swing (IDs reales de la Creator Store), chispa, tinte en hitstun.

### P6 — Animación y cámara
- **`Poses.luau` / `PoseController.luau`**: 7 fases por ataque (anticipación, inicio, extensión,
  impacto, seguimiento, recuperación, guardia), guardia con respiración, reacción al golpe
  (flinch) y giro si el golpe es fuerte (tumble).
- **`CameraConfig`/`CameraController`**: cámara más cercana (FOV 20, distancia 62–160) y
  seguimiento vertical suave.

### Sala de pruebas
- `GameConfig.TestRoom`: Blade vs CPU Brawler, la CPU se reinicia sola a los 2.5 s.
- **`DebugController.luau`** (nuevo, F2) + herramientas del menú (`PracticeController`, `TrainingService`).

---

## Pruebas automáticas (`src/shared/Tests/CoreTests.luau`) — 19/19 ✔
Saltos máximos · caída rápida sin teletransporte y con tope · no empieza subiendo · no gasta
recursos · gravedad de bajada > subida · **aéreo no cae de golpe (nuevo)** · cadena 1→2→3 ·
reinicio por ventana · fin sin bucle · la espada tiene la cadena · direccionales distintos ·
UpLight vertical · hitstun y knockback visibles · knockback se invierte · esquiva aérea gasta y
recarga · recovery se recarga · ningún ataque bloquea para siempre · control solo bloqueado en
arranque/golpe en el suelo.

---

## Lo que falta / conocido
- Leve parpadeo suelo/aire en el borde de una plataforma (visual en el panel; no afecta al juego que se haya visto).
- Revisar si el rival "salta" en Y tras el primer Jab (se vio una vez en una captura del servidor; no se repitió).
- Los otros personajes/armas aún no usan todo el sistema nuevo (a propósito: primero el núcleo).

## Checklist para Jesús (antes de dar la iteración por buena)
- [ ] Caminar, dash (doble toque) y correr se sienten rápidos y responden al instante.
- [ ] Dash + salto conserva el impulso.
- [ ] 3 saltos (suelo + 2 aéreos), se recargan al aterrizar; el panel F2 lo muestra.
- [ ] Caída rápida (S bajando): acelera, no teletransporta; no funciona subiendo.
- [ ] Esquiva aérea con dirección, 1 por vuelo; chase dodge tras acertar.
- [ ] Jab → Jab2 → Jab3 sale como combo (el contador sube a x3).
- [ ] Cada dirección da un ataque distinto (suelo y aire).
- [ ] Salto 1 → salto 2 → aéreo lateral → aéreo arriba → recovery sin caer de golpe.
- [ ] El golpe se nota: parón (hitstop), sonido, chispa, el rival se dobla y sale empujado.
- [ ] El atacante no se queda pegado al rival.
- [ ] Grabar 30–60 s y decir qué se siente raro (valores concretos si puedes: "más rápido", "salta poco"...).
