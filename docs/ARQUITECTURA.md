# Arquitectura

Pequeña, modular y fácil de depurar. **Crece solo cuando un hito lo necesita.**
Cada archivo indica el hito en que aparece. Hoy existen los de M0 a M4;
los marcados *(M5)*, *(M6)* o *(M7)* todavía no existen.

## Estructura del repositorio → Roblox

```text
repo/
├── default.project.json          mapeo de Rojo
├── rokit.toml                    versión de Rojo
├── DECISIONES.md
├── docs/
└── src/
    ├── shared/   → ReplicatedStorage.Shared
    │   ├── Config/
    │   │   ├── GameConfig.luau        reglas generales (stocks, tiempos de respawn)
    │   │   ├── CameraConfig.luau      (M1) zoom y suavidad de la cámara
    │   │   ├── MovementConfig.luau    (M2) velocidades, gravedad, saltos
    │   │   └── Fighters/              (M3) un archivo de datos por luchador
    │   │       ├── Brawler.luau
    │   │       └── Blade.luau         (M4c datos; lo usa la CPU en M5)
    │   └── Modules/
    │       ├── Movement.luau          (M6) cálculo de movimiento compartido jugador/CPU
    │       ├── Movesets.luau          (M4b) lista FighterId → moveset (cliente y servidor)
    │       └── Knockback.luau         (M3) fórmula de knockback
    ├── server/   → ServerScriptService.Server
    │   ├── Main.server.luau           arranca los servicios en orden
    │   ├── Remotes.luau               (M3) crea Shared.Remotes al arrancar
    │   └── Services/
    │       ├── FighterService.luau    (M3) registro de luchadores, estado, daño
    │       ├── CombatService.luau     (M3) ataques, ventanas activas, hitboxes
    │       ├── TrainingService.luau   (M3) dummy por código; solo en modo libre (M4)
    │       ├── MatchService.luau      (M4) spawns, blast zone, KO, stocks, victoria
    │       └── CpuService.luau        (M6) IA de la CPU
    └── client/   → StarterPlayer.StarterPlayerScripts.Client
        ├── Main.client.luau           arranca los controladores
        └── Controllers/
            ├── CameraController.luau   (M1)
            ├── MovementController.luau (M1/M2/M3) plano 2D, saltos, knockback recibido
            ├── InputController.luau    (M2) teclas → acciones
            ├── CombatController.luau   (M3) elige el ataque y lo pide al servidor
            └── HudController.luau      (M4) mensajes de partida; HUD completo en M7
```

### Mundo (creado en Studio, NO en Git)

```text
Workspace
└── Arena
    ├── Platforms        (Folder) partes ancladas, sólidas
    ├── SpawnPoints      (Folder) Parts: Spawn1, Spawn2, RespawnTop
    └── BlastZone        (Part, anclada, invisible, CanCollide=false)
                         su tamaño define los límites; fuera = KO
└── Decor                (M6, opcional) decoración; nunca colisiona ni tapa la cámara
ServerStorage
└── FighterModels        (M6) modelos R15 importados
    ├── Brawler          (Model con Humanoid y HumanoidRootPart)
    └── Blade
```

Las tareas de arte (modelos, animaciones, decoración, sonidos) se hacen en paralelo
con los prompts de `docs/PROMPTS_OTRA_IA.md`; entregan IDs y modelos, nunca código.

### Medidas de la arena de la demo (M1)

Convención: **X = izquierda/derecha, Y = arriba/abajo, Z = 0 siempre.**
La cámara mira desde Z positivo hacia Z negativo.

| Objeto | Clase | Size | Position | Otras propiedades |
|---|---|---|---|---|
| `Platforms/MainStage` | Part | 80, 4, 12 | 0, 0, 0 | Anchored |
| `Platforms/PlatformLeft` | Part | 16, 1, 12 | -20, 14, 0 | Anchored |
| `Platforms/PlatformRight` | Part | 16, 1, 12 | 20, 14, 0 | Anchored |
| `SpawnPoints/Spawn1` | Part | 2, 1, 2 | -15, 6, 0 | Anchored, CanCollide off, Transparency 1 |
| `SpawnPoints/Spawn2` | Part | 2, 1, 2 | 15, 6, 0 | Anchored, CanCollide off, Transparency 1 |
| `SpawnPoints/RespawnTop` | Part | 2, 1, 2 | 0, 30, 0 | Anchored, CanCollide off, Transparency 1 |
| `BlastZone` | Part | 200, 140, 20 | 0, 30, 0 | Anchored, CanCollide/CanTouch/CanQuery off, Transparency 1 |

Límites resultantes de la BlastZone: X de -100 a 100, Y de -40 a 100.

Nunca hay dummies ni NPC colocados a mano en Workspace: los crea el servidor
por código (TrainingService) y los registra en FighterService.

## Quién hace qué

| Cliente | Servidor |
|---|---|
| Leer input | Validar acciones (¿puede atacar ahora?) |
| Mover su propio personaje (Roblox le da la física) | Crear hitboxes y decidir quién recibe el golpe |
| Mantener Z = 0 en su personaje | Calcular daño, knockback, hitstun |
| Aplicar el knockback que le envía el servidor | KO, stocks, respawn, victoria |
| Cámara, HUD, efectos visuales | Mover a la CPU (el servidor es su dueño físico) |

## Concepto central: el "Fighter"

Jugador, dummy y CPU son lo mismo para el combate: un **Fighter** registrado en
FighterService. Lo único que cambia es **quién lo controla**:

- `Player` → acciones llegan por el remote `ActionRequest`.
- `Cpu` → CpuService llama a las mismas funciones que el remote.
- `Dummy` → no hace nada.

Así el combate se programa una vez y sirve para todos. CombatService solo
busca objetivos **en el registro**, nunca recorriendo Workspace.

## Contratos (nombres exactos)

### Atributos en el modelo del personaje (replican solos)

| Atributo | Tipo | Quién lo escribe | Hito |
|---|---|---|---|
| `Percent` | number | servidor | M3 |
| `State` | string: `Idle`, `Attacking`, `Hitstun`, `KO`, `Respawning`, `Eliminated` | servidor | M3/M4 |
| `Stocks` | number | servidor | M4 |
| `Invulnerable` | boolean | servidor | M4 |
| `FighterId` | string: `Brawler`, `Blade`, `Dummy` | servidor | M3 |

### Remotes (en `ReplicatedStorage.Shared.Remotes`, los crea el servidor)

| Nombre | Tipo | Dirección | Datos | Hito |
|---|---|---|---|---|
| `ActionRequest` | RemoteEvent | cliente → servidor | `{ action = "Attack", move = "Jab" }` | M3 |
| `ApplyKnockback` | RemoteEvent | servidor → cliente víctima | `velocity: Vector3, hitstun: number` | M3 |
| `FighterReset` | RemoteEvent | servidor → cliente | (nada): reinicia velocidad y saltos tras un respawn | M4 |
| `MatchEvent` | RemoteEvent | servidor → todos | `kind: "Start" \| "KO" \| "Victory", data` | M4 |

### Formato de datos de un ataque *(M3)*

Tiempos en segundos (no en frames: el servidor de Roblox no garantiza 60 FPS exactos).

Ejemplo real: `src/shared/Config/Fighters/Brawler.luau`.

```lua
Jab = {
    startup  = 0.06,  -- antes de que la hitbox salga
    active   = 0.08,  -- hitbox activa
    recovery = 0.14,  -- después, sin poder actuar
    damage   = 4,     -- % que suma
    baseKnockback  = 28,
    knockbackScale = 0.25,  -- cuánto aumenta por cada % del rival
    angle    = 30,    -- grados, 0 = horizontal hacia delante, 90 = arriba
    -- offset: X = hacia delante (según hacia dónde mira), Y = arriba
    hitbox = { offset = Vector2.new(2.5, 0.5), size = Vector3.new(4, 4, 6) },
    animationId = nil, -- se rellena en M7
}
```

Campos opcionales *(M4b)*:
- `awayFromAttacker = true`: el knockback va hacia el lado donde está el rival
  (golpes que pegan a los dos lados, como `DownHeavy`).
- `selfImpulse = Vector2.new(adelante, arriba)`: impulso que se da el atacante
  (`Recovery`, `GroundPound`). Lo aplica su cliente, que es dueño de su física.

Nombres de ataques válidos: `Jab`, `SideLight`, `UpLight`, `DownLight`, `AirLight`,
`AirUpLight`, `AirDownLight`, `Heavy`, `UpHeavy`, `DownHeavy`, `Recovery`, `GroundPound`.
Cada luchador nuevo debe definir los 12.

### Fórmula de knockback de la demo *(M3)*

Código: `src/shared/Modules/Knockback.luau`.

```text
fuerza  = baseKnockback + (porcentajeDelRival * knockbackScale)
hitstun = fuerza * GameConfig.HitstunPerForce  (entre MinHitstun y MaxHitstun)
```

Simple a propósito. Se cambia por una más elaborada solo si la demo lo pide.

## Reglas técnicas clave de Roblox

1. El knockback de un **jugador** lo aplica su propio cliente (`ApplyKnockback`).
   El de un **dummy/CPU** lo aplica el servidor directamente.
2. KO por **posición** contra los límites de `BlastZone` en cada Heartbeat,
   nunca con `Touched`.
3. `Workspace.FallenPartsDestroyHeight` debe quedar por debajo de la BlastZone
   (el valor por defecto, -500, sirve: la BlastZone acaba en Y = -40). No cambiarlo.
4. Respawn = anclar, teletransportar y resetear atributos (MatchService). No usar `LoadCharacter`.
5. La vida (`Health`) nunca se toca; el daño es `Percent`. Nadie muere, solo hay KO.
6. Cada ataque guarda una lista `alreadyHit`: un objetivo, un golpe por ataque.
7. Para recolocar a un jugador, el servidor lo **ancla** primero, lo mueve y al soltarlo
   le devuelve la física (`SetNetworkOwner`) y avisa a su cliente (`FighterReset`).
8. Ningún `WaitForChild` sin garantía de que el objeto existe: los remotes se esperan
   dentro de `task.spawn` para no bloquear el arranque del cliente.
