# Platform Fighter (nombre en clave)

Juego de lucha de plataformas 2D **original** para Roblox. Inspirado en el género
(porcentaje de daño, knockback, expulsar al rival del escenario), con personajes,
nombres, arte y código **propios**.

> **Estado:** M0–M3 terminados (proyecto, arena/cámara, movimiento, combate).
> M4 (KO, vidas y partida) en pruebas. Ver [DECISIONES.md](DECISIONES.md).
> **Meta actual:** una mini demo jugable (1 personaje jugable vs 1 CPU, 1 arena)
> para grabar un tráiler de mecánicas y una partida con handcam.

## Documentación

| Documento | Para qué sirve |
|---|---|
| [docs/VISION_Y_METAS.md](docs/VISION_Y_METAS.md) | Qué es la demo, qué entra y qué no, hitos paso a paso |
| [docs/REGLAS.md](docs/REGLAS.md) | Reglas legales y de trabajo en equipo (leer antes de tocar nada) |
| [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) | Estructura de carpetas, cliente vs servidor, contratos entre módulos |
| [DECISIONES.md](DECISIONES.md) | Registro de decisiones, sistemas terminados y problemas pendientes |

## Instalación (una sola vez por persona)

1. Instala **Roblox Studio**, **Git**, **GitHub Desktop** (Git con botones, ideal
   si nunca has usado la terminal) y **Visual Studio Code**.
2. Instala **Rokit** (gestor de herramientas): https://github.com/rojo-rbx/rokit
3. Clona el repositorio y, dentro de la carpeta, instala las herramientas:
   ```powershell
   git clone <URL-del-repo>
   cd <carpeta-del-repo>
   rokit install
   ```
4. En VS Code instala la extensión **Rojo** (y opcionalmente **Luau Language Server**).
5. En Roblox Studio instala el **plugin de Rojo** (la extensión de VS Code lo ofrece,
   o ejecuta `rojo plugin install`).

## Cómo trabajar cada día

1. Abre el **place del proyecto** en Roblox Studio (el mapa vive allí, no en Git).
2. En la carpeta del repo:
   ```powershell
   rojo serve
   ```
3. En Studio: pestaña **Plugins → Rojo → Connect**.
4. Edita el código en VS Code (`src/`). Los cambios aparecen solos en Studio.
5. Prueba en Studio con 2 jugadores: menú **Test → Start Test Session** (o el
   desplegable junto a ▶) → modo servidor + clientes → **2** jugadores.
   Si no hay errores, el Output dice `[Server] listo` y `[Client] listo` con la versión.

### Controles actuales

| Acción | Teclas |
|---|---|
| Moverse | A/D o ←/→ |
| Saltar (1 en suelo + 2 en el aire) | Space, W o ↑ (en M4b: solo Space) |
| Ligero (Jab / lateral con A/D / aéreo) | J o clic izquierdo |
| Pesado | K o clic derecho |

### Qué está en Git y qué no

- **En Git:** todo el código (`src/`), configuración y documentación.
- **En el place de Studio (Team Create):** la arena, plataformas, spawns, modelos.
  Responsable del mapa: **JZnoalive**. Nadie más cambia el mapa sin avisar.

## Flujo de Git

- `main` siempre funciona.
- **Fase actual:** mientras solo programa JZnoalive (con Claude), los cambios van
  directo a `main`, uno por hito, y se prueban antes del siguiente.
- **Cuando entren más programadores:** nunca directo a `main`; una rama por tarea:
  `m2/movimiento-salto`, `m3/hitbox-jab`, etc.
- Pull Request → otra persona prueba en Studio → merge.
- Un módulo, una persona a la vez (ver [docs/REGLAS.md](docs/REGLAS.md)).

## Aviso legal

Proyecto original. No contiene ni usa código, personajes, nombres, modelos,
animaciones, música ni escenarios de otros juegos. Ver [docs/REGLAS.md](docs/REGLAS.md).
