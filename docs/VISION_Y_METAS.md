# Visión y metas

## La idea en una frase

Un platform fighter 2D original en Roblox: acumulas daño en %, cuanto más % más
lejos vuelas, y ganas sacando al rival del escenario.

## Meta actual: la MINI DEMO

No es el juego. Es una prueba jugable que sirve para:

1. Grabar un **tráiler de mecánicas** (estilo presentación de un juego de lucha:
   "así se mueve, así se ataca, así se hace KO").
2. Grabar una **partida con handcam** contra la CPU.
3. Atraer gente y empezar a construir comunidad antes del lanzamiento.

### Contenido exacto de la demo

| Elemento | Cantidad |
|---|---|
| Personaje jugable | 1 — **"Brawler"** (nombre en clave): equilibrado, puños, rápido |
| Personaje CPU | 1 — **"Blade"** (nombre en clave): espada, más alcance, más lento |
| Arena | 1 — plataforma principal + 2 plataformas flotantes sólidas |
| Modo | 1v1, 3 stocks |

Los dos personajes son **originales**. Los nombres son provisionales; el diseño
final lo define JZnoalive. No se hacen versiones "falsas" de personajes existentes.

### Mecánicas que DEBEN verse en el tráiler

- [ ] Correr y cambiar de dirección
- [ ] Salto + salto aéreo
- [ ] Ataques ligeros en tierra (neutral, lateral) y en el aire
- [ ] Ataque pesado (smash cargado o golpe fuerte)
- [ ] El % sube con cada golpe y se ve en pantalla
- [ ] El knockback crece con el % (mismo golpe al 20 % vs al 120 %)
- [ ] Hitlag + sacudida de cámara en golpes fuertes
- [ ] KO espectacular al cruzar la blast zone (destello / explosión)
- [ ] Stocks, respawn con invulnerabilidad, pantalla de victoria
- [ ] La CPU se mueve, ataca y vuelve al escenario

### Fuera de la demo (después)

Esquiva, escudo, agarres, dash, plataformas atravesables, bordes, armas recogibles,
más personajes, 4 jugadores, selección de personaje, online público, móvil,
monetización.

## Hitos paso a paso

Regla: **no se empieza un hito hasta que el anterior pasa su prueba.**

| Hito | Qué se construye | Hecho cuando |
|---|---|---|
| **M0 Proyecto** | Repo, Rojo, place nuevo, scripts de prueba | Con 2 clientes, Output muestra `[Server] listo` y `[Client] listo` ×2 |
| **M1 Arena y cámara** | Arena, plano 2D (Z bloqueado), cámara lateral | 60 s corriendo y saltando: Z siempre ≈ 0, la cámara encuadra bien |
| **M2 Movimiento** | Correr, salto, salto aéreo, gravedad, control aéreo | Dos jugadores se mueven a la vez sin tirones; el movimiento "se siente bien" |
| **M3 Combate vs dummy** | 4 ataques de Brawler, hitbox, %, knockback, hitstun | 10 golpes al dummy: % exacto, 1 impacto por ataque, KB crece con el % |
| **M4 KO y partida** | Blast zone, KO, stocks, respawn, victoria, reinicio | 5 partidas seguidas sin errores ni estados pegados |
| **M5 Segundo luchador** | Moveset de Blade (solo datos + modelo provisional) | Blade jugable por un 2º jugador; sus ataques usan su propia tabla |
| **M6 CPU** | IA simple que controla a Blade | La CPU acerca, ataca en rango, vuelve al escenario; gana a veces |
| **M7 Pulido para tráiler** | HUD de %, animaciones, hitlag, VFX de golpe/KO, sonido | Checklist del tráiler completa |
| **M8 Grabación** | Arena decorada, cámara de grabación, build estable | Tráiler + partida handcam grabados |

## Cómo se ve el éxito

Una persona que no conoce el proyecto ve 60 segundos del tráiler y entiende
cómo se juega y que quiere probarlo.
