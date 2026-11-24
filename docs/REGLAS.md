# Reglas del proyecto

## A. Reglas legales (no negociables)

1. **Mecánicas sí, contenido no.** Podemos estudiar cómo funciona el género
   (porcentaje, knockback, frame data, stocks) y programarlo a nuestra manera.
   No usamos personajes, nombres, modelos, animaciones, sonidos, música,
   escenarios ni logos de otros juegos.
2. **Nada de personajes "falsos".** Un personaje que se reconoce como otro
   (mismo traje, mismo arma icónica, mismos colores, nombre parecido) sigue
   siendo una copia. Todos los diseños son originales.
3. **Nada de código ajeno sin licencia.** No se copia, traduce ni "se usa como
   guía línea por línea" código decompilado o filtrado de juegos comerciales
   (por ejemplo, proyectos de decompilación de juegos de consola).
   Si se usa código abierto, debe tener licencia compatible y se anota en
   `DECISIONES.md` de dónde viene.
4. **Fuentes de referencia permitidas:** wikis y guías públicas que describen
   mecánicas, vídeos de partidas, charlas de diseño, motores open source con
   licencia (solo conceptos), nuestra propia observación.
5. El nombre del juego, las descripciones y miniaturas **no mencionan** otros
   juegos.

## B. Reglas de trabajo

1. **Un hito a la vez.** No se pasa al siguiente sin que el actual pase su prueba.
2. **Primero se explica, luego se programa.** Cada tarea dice qué objetos deben
   existir en Studio y en qué ruta exacta.
3. **Cambios pequeños.** Un PR toca pocos archivos y hace una sola cosa.
4. **Un módulo, una persona.** Antes de tocar un módulo, avisa en el grupo.
   Nunca dos personas (ni dos asistentes de IA) editan el mismo módulo a la vez.
5. **Si algo falla:** primero se encuentra la causa y el archivo responsable.
   No se reescribe todo como primera reacción.
6. **No inventar nombres.** Los objetos, rutas, atributos y remotes se llaman
   exactamente como dice `docs/ARQUITECTURA.md`. Si hace falta uno nuevo,
   se añade primero allí.
7. **Cliente y servidor separados.** Cada script vive en `client/`, `server/`
   o `shared/`. Si algo cruza, se explica por qué.
8. **El servidor decide.** El cliente nunca decide cuánto daño hace ni a quién golpea.
9. **Números en Config.** Velocidades, daños, tiempos: en `src/shared/Config`,
   nunca escritos sueltos dentro de la lógica.
10. **Cada PR incluye su prueba:** qué hiciste en Studio y qué resultado viste.
11. **`DECISIONES.md` se actualiza** cuando se decide algo, se termina un sistema
    o aparece un problema.

## C. Reglas de Git

- `main` siempre funciona.
- Ramas: `m<hito>/<tarea-corta>` → ejemplo `m3/hitbox-jab`.
- Commits en español, en presente: "Añade salto aéreo".
- PR revisado y probado por otra persona antes del merge.
- No se suben archivos `.rbxl` / `.rbxlx` (el mapa vive en el place de Studio).
