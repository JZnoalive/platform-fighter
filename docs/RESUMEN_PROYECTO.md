# Platform fighter en Roblox — resumen del proyecto

> **⏸ PROYECTO EN PAUSA (27-nov-2026).** Retomar desde aquí: leer este resumen, `rojo serve` en esta carpeta y Connect en Studio.

**Fecha:** 27 de noviembre de 2026
**Repositorio:** github.com/JZnoalive/platform-fighter
**Herramientas:** Roblox Studio + Luau, Rojo (sincroniza el código con Studio), Git y GitHub.
**Equipo:** Jesús (idea, pruebas y criterio de juego) + Claude (programación).

---

## 1. Qué queremos

- Un juego de peleas de plataformas en Roblox, en 2D lateral. Lo describimos como **"platform fighter original"**: la referencia son las mecánicas del género (como Brawlhalla), no su contenido.
- Se usan **ideas de mecánica** del género: saltos múltiples, caída rápida, esquiva, recovery, combos, knockback y plataformas que se atraviesan.
- **No se copia** nada concreto de otro juego: ni personajes, ni nombres, ni arte, música, sonidos, HUD o código.
- **Meta:** una demo jugable antes del **4 de diciembre de 2026**, con tráiler y partida grabada contra la CPU.
- **Prioridad actual:** que **un personaje con un arma** (Vórtice con espada) se sienta bien antes de añadir más contenido.

---

## 2. Lo que hay hecho

### Contenido
- **4 personajes:** Forja, Vórtice, Umbra y Volta.
- **4 armas:** Espada, Puños, Guadaña y Pistolas.
- **Escenario:** isla con escenario principal, 2 plataformas atravesables y zona de KO en los bordes.
- **HUD:** retrato, % de daño, vidas y contador de combo.
- **Sonidos de golpe y de swing:** IDs reales de la Creator Store.

### Modos
- **Práctica:** CPU configurable (quieta, caminar, saltar, esquivar, atacar o pelear), % fijo, cambiar personaje y arma, y botón **"Reiniciar posiciones"**.
- **Partida contra la CPU:** 3 vidas, cuenta atrás "3, 2, 1", KO al salir del escenario, reaparición, victoria y vuelta a práctica. Funciona de principio a fin.

### Movimiento
- **Suelo:** caminar, correr y dash (doble toque de A/D); el impulso del dash se conserva al saltar.
- **Saltos:** 3 en total (suelo + 2 aéreos), que se recargan al aterrizar o al recibir un golpe.
- **Gravedad:** separada para subir y bajar; caída rápida con S que acelera poco a poco.
- **Plataformas:** se atraviesan desde abajo; manteniendo S bajas a través de ellas.
- **Esquiva:** en el suelo y en el aire (1 por vuelo).
- **Recovery:** W + K en el aire.
- **Todos los números** están en un solo archivo (`MovementConfig`).

### Combate
- **Cadena de ligeros:** J, J, J = golpe 1 → 2 → 3 (también manteniendo J). Tiene ventana de 0,55 s y búfer de entrada.
- **Ataques por dirección, distintos entre sí:**
  - Ligero en el suelo: lateral, abajo y arriba (lanzador).
  - Ligeros aéreos: neutro, lateral, abajo y arriba.
  - Fuertes: neutro, abajo y arriba.
- **Cada golpe tiene sus propios valores:** tiempos (arranque, golpe y recuperación), daño, aturdimiento, parón al impactar (hitstop) y empuje horizontal y vertical.
- **Combos aéreos:** el lanzado flota mientras está aturdido.
  - Probado: W+J → salto + W+J → salto + W+J → salto + J = **combo x4**.
- **Reacción al golpe:** el rival se dobla, sale despedido y, si el golpe es fuerte, gira. Hay chispa, sonido y parón.
- **El servidor manda:** el daño y los golpes los decide el servidor (anti-trampas).

### Animación y cámara
- **Poses por código en 7 fases:** anticipación, inicio, extensión, impacto, seguimiento, recuperación y guardia.
- **Personaje:** guardia con respiración, carrera animada y postura aérea.
- **Cámara:** lateral, cercana, y sigue a los dos luchadores.

### Herramientas de prueba
- **Panel ENTRADA (F2):** muestra cada tecla, el ataque elegido, el paso de la cadena, la ventana restante y el **motivo** si no sale el combo.
- **Panel de depuración (F2):** estado, velocidad vertical, saltos y últimos ataques con sus tiempos.
- **Recuadro de controles (F2).**
- **19 pruebas automáticas** de la lógica, todas correctas.

---

## 3. Controles

| Tecla | Acción |
|---|---|
| A / D | Moverse (doble toque = dash y correr) |
| Espacio (o W) | Saltar (2 saltos más en el aire) |
| S bajando | Caída rápida · mantener S = bajar de una plataforma |
| J / clic izquierdo | Ataque ligero · J J J = cadena |
| A/D, S o W + J | Ataque ligero lateral, abajo o arriba |
| K / clic derecho | Ataque fuerte (+ dirección) |
| W + K en el aire | Recovery |
| Shift / L | Esquiva (+ dirección en el aire) |
| F2 | Mostrar u ocultar paneles |
| P | Mostrar u ocultar el menú de práctica |

---

## 4. Problemas y errores que tuvimos (y cómo se arreglaron)

### Técnicos
| Problema | Causa | Solución |
|---|---|---|
| La carpeta del proyecto se dañó (faltaban archivos de Git) | Archivos perdidos en Documentos | Se reconstruyó desde una copia limpia de GitHub |
| Un golpe pegaba infinitas veces | El contador de golpes iba hacia atrás por el parón | Contador que solo avanza |
| El salto tardaba en salir | El salto de Roblox empuja con retraso | Velocidad de salto aplicada al instante |
| Las plataformas bloqueaban a quien salía lanzado desde abajo | Colisión normal | Plataformas de un solo sentido |
| La CPU parecía bugueada: volvía sola a su sitio cada pocos segundos | Reinicio automático de la sala de prueba | Reinicio automático quitado |
| El personaje se quedaba pegado en el aire junto a las plataformas | El Humanoid de Roblox entraba en modo "escalar" | Modo escalar desactivado |
| El rival congelado se veía flotando, pero el servidor lo tenía en el suelo | Roblox no reenvía la posición de una pieza anclada | Se fuerza a reenviar la posición |
| Al golpear al rival, el atacante lo atravesaba y quedaba detrás | El avance del golpe no se detenía | El avance se para a 3 studs del rival |
| La captura de Studio salía en negro | Fallo de Studio tras muchas partidas | Reiniciar Studio |
| Rojo se desconectaba | Se cerraba el proceso | Reiniciar Rojo y volver a conectar en Studio |

### De sensación de juego (detectados por Jesús al jugar)
| Problema | Causa | Solución |
|---|---|---|
| Las animaciones hechas con IA "no se parecían en nada" | Animaciones genéricas | Poses diseñadas a mano a partir de vídeos de referencia |
| **No se podía hacer el combo J J J a mano** aunque las pruebas decían que sí | Las pruebas solo comprobaban la lógica, no la entrada real. Además: teclas que se quedaban "pegadas", la cadena contaba pulsaciones en vez de golpes reales y el atacante atravesaba al rival | Lectura real del teclado, cadena basada en lo que ejecuta el servidor y panel ENTRADA para ver cada paso |
| "Todo se queda quieto, no hay animaciones" | El botón de reinicio dejaba al rival **congelado** (no reaccionaba) y la carrera dependía de una animación que no cargaba | Rival sin congelar y carrera animada por código |
| En el aire caía de golpe y no daba tiempo a encadenar | Gravedad completa durante los ataques aéreos | Durante un ataque aéreo casi flotas |
| Caían demasiado rápido y con S bajaban de golpe | Gravedad 250 y caída rápida 105 | Gravedad 200, caída máxima 40 y caída rápida gradual hasta 62 |
| No había combos aéreos ni forma de lanzar arriba | El rival subía y bajaba en 0,6 s y el lanzador lo empujaba de lado | El lanzado flota en hitstun y el lanzamiento sale recto hacia arriba |

### Lecciones
- **Que pasen las pruebas automáticas no significa que funcione:** hay que probar con teclado real y mirar el juego.
- **Lo que hace que se parezca al género son las mecánicas y cómo se siente**, no los nombres de los sistemas.
- **Primero un personaje y un arma que se sientan bien**, después más contenido.

---

## 5. Estado actual (honesto)

- Es **jugable**: moverse, combos en el suelo y en el aire, partida a 3 vidas contra una CPU que pelea.
- **Opinión de Jesús:** funciona, pero aún **no tiene algo propio** que lo haga destacar. Las animaciones se pueden mejorar mucho y todavía le falta "sensación" para competir con lo que hay en Roblox.
- **Siguiente paso:** que **un amigo lo pruebe** y dé su opinión, para decidir qué mejorar.

## 6. Pendiente / ideas

- Mejorar las animaciones (más expresivas y limpias).
- Algo **original** que lo distinga: una mecánica propia, un modo o un estilo visual.
- Repasar los otros 3 personajes y armas con el sistema nuevo (hasta ahora solo se afinó la espada).
- Equilibrar la CPU (ahora puede ser muy agresiva).
- **Publicar para que otros lo prueben:** en Studio, Archivo → Publicar en Roblox, y después hacerlo público o dar acceso.

## 7. Documentos del repositorio
- `docs/ESTADO_Y_PLAN.md`: plan y metas.
- `docs/NUCLEO_COMBATE.md`: cambios del sistema de combate con sus valores.
- `docs/ENTRADA_Y_CADENA.md`: cómo hacer el combo y el diagnóstico de entrada.
- `docs/PERSONAJES.md` y `docs/COMBOS.md`: personajes y combos.
