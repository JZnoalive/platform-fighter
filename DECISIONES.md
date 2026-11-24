# Decisiones, avances y pendientes

## Decisiones tomadas

| Fecha | Decisión | Motivo |
|---|---|---|
| 2026-11-24 | Base de combate estilo Brawlhalla (ligeros/pesados por dirección, saltos limitados) + % visible | Menos sistemas para una primera versión jugable |
| 2026-11-24 | Un solo proyecto: demo básica que luego crece a avanzada | 4 personas no pueden mantener dos juegos |
| 2026-11-24 | Rojo + Git para el código; el mapa vive en el place de Studio | Git no puede fusionar archivos `.rbxl` |
| 2026-11-24 | Meta inmediata: mini demo 1 jugable (Brawler) vs 1 CPU (Blade) | Tráiler + partida handcam para atraer comunidad |
| 2026-11-24 | Personajes 100 % originales; sin versiones "falsas" de personajes existentes | Riesgo de retirada del juego y de la cuenta |
| 2026-11-24 | No se usa código decompilado de juegos comerciales como referencia | Ese código no tiene licencia; solo se estudian mecánicas públicas |
| 2026-11-24 | Tiempos de ataque en segundos, no en frames | El servidor de Roblox no garantiza FPS fijos |
| 2026-11-24 | KOService queda dentro de MatchService | Se separa solo si crece |
| 2026-11-24 | Movimiento horizontal con aceleración propia, aplicado vía `Humanoid:Move` + `WalkSpeed` | El Humanoid sigue gestionando suelo y animaciones |
| 2026-11-24 | Controles M2: A/D o flechas = mover, Space/W/↑ = saltar, S/↓ = abajo (cambiado en M4b) | Controles de Roblox desactivados; todo pasa por InputController |
| 2026-11-24 | Input con ContextActionService (prioridad alta + Sink), sin PlayerModule | PlayerModule no existe en este place y bloqueaba el cliente |
| 2026-11-24 | El dummy se crea por código (TrainingService), no a mano | Evita el bug de golpear a varios dummies; nada que crear en Studio |
| 2026-11-24 | Hitlag se mueve de M3 a M7 | M3 se centra en que los golpes conecten bien; el "feeling" va en el pulido |
| 2026-11-24 | Hitboxes visibles en rojo (`GameConfig.DebugHitboxes`) | Para ver y ajustar los ataques antes de tener animaciones |
| 2026-11-24 | Cada ataque tiene un hueco `animationId` en su tabla | Cuando existan los modelos y animaciones se enchufan sin cambiar código |
| 2026-11-24 | KO por posición fuera de la BlastZone (Heartbeat), nunca con Touched | Fiable a cualquier velocidad |
| 2026-11-24 | Respawn = anclar arriba (RespawnTop) 1 s + invulnerable con brillo blanco; sin LoadCharacter | Rápido, sin recargar scripts; se ve claro quién es invulnerable |
| 2026-11-24 | Con menos de 2 jugadores: modo libre (KO sin perder vidas) | Se puede entrenar solo contra el dummy |
| 2026-11-24 | El dummy solo existe en modo libre; se retira al empezar una partida | Revisión: aparecía en Spawn2 encima del jugador 2 y estorbaba en el 1v1 |
| 2026-11-24 | M4b: 12 ataques por luchador (7 ligeros, 5 pesados) elegidos por dirección y suelo/aire | Estructura del género; un luchador nuevo = solo un archivo de datos |
| 2026-11-24 | Saltar = solo Space; W/↑ = dirección arriba | Sin esto no se pueden hacer ataques hacia arriba |
| 2026-11-24 | Recovery 1 vez por vuelo; recibir un golpe recarga saltos aéreos y Recovery | Convención del género; da opciones para volver al escenario |
| 2026-11-24 | El impulso de Recovery/GroundPound lo aplica el cliente | El jugador es dueño de su física. Riesgo aceptado para la demo: el servidor no lo valida |
| 2026-11-24 | Física y ritmo estilo Brawlhalla (no Smash); de Smash solo el % visible | Menos sistemas (sin escudo, agarres ni bordes), más fácil en Roblox, combate rápido para tráiler |
| 2026-11-24 | Combos: hitstun mín. 0.25 s, recovery ×0.5 al acertar, búfer de ataques 0.2 s en el servidor | Antes el rival se recuperaba antes que el atacante: combos imposibles |
| 2026-11-24 | Ligeros con poco knockback; los pesados son los que mandan lejos | Los ligeros encadenan, los pesados rematan (estructura del género) |
| 2026-11-24 | W salta Y apunta arriba ("tap-jump"): espera 0.05 s por si llega un ataque; Space salta al instante | Bloquear W restaba velocidad; así se combinan según la situación |
| 2026-11-24 | Caída rápida con S en el aire | Física estilo Brawlhalla |
| 2026-11-24 | Datos de Blade creados ya (12 ataques) | Para que las animaciones se puedan hacer en paralelo con sus tiempos |
| 2026-11-24 | Arte en paralelo con otra IA; nunca toca `src/` | Avanzar más rápido sin pisar el código |
| 2026-11-24 | Una especialidad por IA: Claude = código; Gemini = todo lo creativo; ChatGPT fuera (como mucho textos de redes). Ver `docs/EQUIPO.md` | Evitar dos "arquitectos" y versiones contradictorias |
| 2026-11-24 | Todos los IDs (animaciones, audio) se apuntan solo en `docs/ENTREGAS.md` | Un único lugar; nada de IDs inventados o sueltos |
| 2026-11-24 | Animaciones y audios se publican con el mismo dueño que el juego (recomendado: Grupo de Roblox) | Si el dueño es distinto, Roblox no los reproduce en el juego |
| 2026-11-24 | Sonidos propios (jsfxr) o catálogo con licencia de Roblox; herramientas gratis solo si su licencia permite uso comercial | El juego tendrá ingresos |
| 2026-11-24 | Esquiva: Shift/L, 0.3 s invulnerable (State `Dodging`), enfriamiento 1 s; esquiva aérea 1 por vuelo | Física estilo Brawlhalla; el movimiento lo pone quien controla el cuerpo (cliente o CpuService) |
| 2026-11-24 | El dummy pasa a ser la CPU `CPU_Blade` con 6 comportamientos (CpuService) | Base para la partida contra la IA de la demo |
| 2026-11-24 | Menú de práctica: comportamiento de la CPU, % (0/50/100/150), reiniciar, hitboxes; solo en modo libre | Recupera la idea del "mod menu" del prototipo viejo |
| 2026-11-24 | La CPU usa el mismo combate que el jugador (PerformAttack, TryStartDodge) | Sin trampas; un solo sistema que mantener |
| 2026-11-24 | M4b–M5 se programaron seguidos y se prueban juntos al final | Petición de JZnoalive para avanzar más rápido |
| 2026-11-24 | Demo con personajes de bloque estilizado hechos por código (Opción A), sin modelos 3D | JZnoalive trabaja solo y el rig 3D (Mixamo, escala 100x) frenaba la demo. Fecha límite: 4 de diciembre |
| 2026-11-24 | Jugadores sin ropa/accesorios de su avatar (`LoadCharacterAppearance = false`) | Todos se ven como el luchador, como en un juego de pelea |
| 2026-11-24 | Animaciones de ataque desde el servidor, solo si hay `animationId` | Se ven en todos los clientes; sin ID no pasa nada |
| 2026-11-24 | Partida contra la CPU (VsCpu) desde el menú de práctica; la CPU juega en modo Pelear con 3 vidas | La handcam de la demo es contra la IA |
| 2026-11-24 | Animaciones por código (Motor6D.Transform en Stepped) con poses en `Poses.luau` | No hay tiempo para animar y subir 24 animaciones; funciona también con la CPU |
| 2026-11-24 | HUD abajo con tarjetas; etiqueta de % sobre la cabeza desactivada (`ShowOverheadPercent`) | Estilo del género, pantalla limpia para el tráiler |
| 2026-11-24 | Escenario "templo al atardecer" generado por código (`DecorService`) | JZnoalive trabaja solo; se puede sustituir decorando a mano (crear Workspace.Decor) |
| 2026-11-24 | Armas, poderes y personajes 2D/temáticos quedan para después de la demo | Fecha límite 4 de diciembre; personajes de franquicias ajenas no se usan |
| 2026-11-24 | Armas estilo Brawlhalla: el moveset lo da el ARMA (atributo `Weapon`); 4 armas: Puños, Espada, Guadaña, Pistolas | Variedad para el tráiler sin hacer más personajes; cada arma = 1 archivo de datos + su aspecto |
| 2026-11-24 | Cambio de arma solo en práctica (menú); se recuerda al reaparecer | Para mostrar los combos de cada arma |
| 2026-11-24 | Pistolas con proyectiles decididos por el servidor (campo `projectile`) | Ataques a distancia sin trampas |
| 2026-11-24 | Cajas rojas ocultas por defecto (se activan en el menú) | Imagen limpia para el tráiler |
| 2026-11-24 | Poses estilo Smash: anticipación, giros de todo el cuerpo (Root), muñecas para apuntar, estelas en las armas | Que se vea mejor sin animaciones subidas |
| 2026-11-24 | Contador de combo en el HUD ("COMBO x4 · 23%") | Los combos los crean los jugadores; así se ven en el tráiler |
| 2026-11-24 | Mientras solo programa JZnoalive, commits directos a `main` | Rama + PR cuando entren más programadores |
| 2026-11-24 | Arriba/abajo y recovery se hacen en M4b, después de M4 | Petición de JZnoalive; M4 primero para cerrar el ciclo de partida |
| 2026-11-24 | Plano de juego: X = izquierda/derecha, Y = arriba/abajo, Z siempre 0 | Una sola convención para cámara, movimiento y hitboxes |

## Sistemas terminados

| Fecha | Hito | Prueba superada |
|---|---|---|
| 2026-11-24 | M0 Proyecto | Rojo 7.7.1 conectado; con 2 jugadores salen `[Server] listo` y `[Client] listo` |
| 2026-11-24 | M1 Arena y cámara | Cámara lateral encuadra a 2 jugadores; Z fijo en 0; se puede caer por el borde |
| 2026-11-24 | M2 Movimiento | Correr, salto, 2 saltos aéreos, 2 jugadores. Pendiente: verificar la aceleración al mantener la tecla |
| 2026-11-24 | M3 Combate vs dummy | Golpes conectan, % sube, knockback, dummy por código; probado con avatar y dummy |
| 2026-11-24 | M4 KO y partida | 2 jugadores: dummy se retira, partida, ganador y reinicio automático sin errores |

## Problemas pendientes

- [ ] M4b–M7 subidos; en Studio solo se vio funcionando lo básico de M5/M6 (menú, golpes, aspecto). Falta prueba completa
- [ ] Sonidos y música: faltan los IDs (AudioConfig.luau vacío = silencio)
- [ ] Recomendado en Studio: Workspace.StreamingEnabled = false (arena pequeña)

- [ ] Un 3er jugador que entra a mitad de partida no tiene vidas (la demo es 1v1; se revisa si hace falta)

- [ ] Nombre definitivo del juego
- [ ] Diseño final de Brawler y Blade
- [ ] Reparto de tareas entre los 4 integrantes
