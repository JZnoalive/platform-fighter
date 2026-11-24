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
| 2026-11-24 | Controles M2: A/D o flechas = mover, Space/W/↑ = saltar, S/↓ = abajo | Controles de Roblox desactivados; todo pasa por InputController |
| 2026-11-24 | Input con ContextActionService (prioridad alta + Sink), sin PlayerModule | PlayerModule no existe en este place y bloqueaba el cliente |
| 2026-11-24 | El dummy se crea por código (TrainingService), no a mano | Evita el bug de golpear a varios dummies; nada que crear en Studio |
| 2026-11-24 | Hitlag se mueve de M3 a M7 | M3 se centra en que los golpes conecten bien; el "feeling" va en el pulido |
| 2026-11-24 | Hitboxes visibles en rojo (`GameConfig.DebugHitboxes`) | Para ver y ajustar los ataques antes de tener animaciones |
| 2026-11-24 | Cada ataque tiene un hueco `animationId` en su tabla | Cuando existan los modelos y animaciones se enchufan sin cambiar código |
| 2026-11-24 | Plano de juego: X = izquierda/derecha, Y = arriba/abajo, Z siempre 0 | Una sola convención para cámara, movimiento y hitboxes |

## Sistemas terminados

| Fecha | Hito | Prueba superada |
|---|---|---|
| 2026-11-24 | M0 Proyecto | Rojo 7.7.1 conectado; con 2 jugadores salen `[Server] listo` y `[Client] listo` |
| 2026-11-24 | M1 Arena y cámara | Cámara lateral encuadra a 2 jugadores; Z fijo en 0; se puede caer por el borde |
| 2026-11-24 | M2 Movimiento | Correr, salto, 2 saltos aéreos, 2 jugadores. Pendiente: verificar la aceleración al mantener la tecla |

## Problemas pendientes

- [ ] Nombre definitivo del juego
- [ ] Diseño final de Brawler y Blade
- [ ] Reparto de tareas entre los 4 integrantes
