# Equipo: quién hace qué

Regla principal: **cada IA tiene UNA especialidad y no se mete en la de otra.**
Así nadie pisa el trabajo de nadie y no hay versiones contradictorias.

## Roles

| Quién | Especialidad | Nunca hace |
|---|---|---|
| **Claude** | Todo el **código** (`src/`), la arquitectura, la documentación del repo, integrar los IDs y modelos que llegan, revisar que todo encaje | Arte, modelos, animaciones |
| **Gemini** | Todo lo **creativo**: diseño de personajes, imágenes, miniatura e icono, tutor paso a paso en Blender y en el Animation Editor de Studio, decoración del escenario, sonidos y música, guion del tráiler | Escribir o cambiar código Luau / archivos de `src/` |
| **JZnoalive** | Decide el diseño final, trabaja en Studio y Blender, prueba, sube a GitHub, lleva las entregas de una IA a otra | — |
| **Amigos** | Se reparten el trabajo de Gemini: modelado, animación, escenario, sonido/redes | Tocar `src/` sin pasar por Claude |

> **ChatGPT** queda fuera para no tener dos "arquitectos". Si se usa, que sea solo
> para textos de redes sociales o descripciones, nunca para código ni diseño del juego.

## Cómo viaja el trabajo

```text
Gemini (o un amigo) crea algo
        │
        ▼
JZnoalive lo sube a Roblox (modelo, animación, audio) y obtiene su ID
        │
        ▼
Apunta el ID en docs/ENTREGAS.md  ──►  se lo dice a Claude
        │
        ▼
Claude lo conecta al código, lo sube a GitHub y da una tabla de prueba
```

**Un solo lugar para los IDs:** [`docs/ENTREGAS.md`](ENTREGAS.md). Si un ID no está
ahí, para Claude no existe. Nunca se pegan IDs sueltos en el código a mano.

## Reglas que evitan problemas

1. **Dueño único en Roblox.** Las animaciones y los audios solo funcionan en el
   juego si los publicó **el mismo dueño que el juego**. Recomendado:
   - Crear un **Grupo de Roblox** del equipo.
   - Pasar el juego al grupo (o publicarlo en él).
   - Todos publican animaciones y audios **en el grupo**, no en su cuenta personal.
   - Si se queda en la cuenta de JZnoalive, entonces todo se publica desde su cuenta.
2. **IDs reales, nunca inventados.** Una IA no puede buscar en la tienda de Roblox
   por ti: si te da un ID sin que lo hayas visto en Studio, no lo uses.
   Los IDs válidos son los que **tú** obtienes al publicar o al insertar desde el Toolbox.
3. **Todo original y con licencia clara.** Antes de usar algo generado con una
   herramienta gratis, revisa sus términos (ver tabla de abajo).
4. **Nombres exactos.** Modelos, carpetas y animaciones se llaman como dice
   [`ARQUITECTURA.md`](ARQUITECTURA.md) y [`ENTREGAS.md`](ENTREGAS.md).
5. **Un tema por chat.** Un chat de Gemini para personajes, otro para animación, otro
   para sonido. Así no se mezclan instrucciones.

## Herramientas creativas gratis (y qué revisar)

| Para | Herramienta | Ojo con |
|---|---|---|
| Concept art, miniatura, icono | Gemini (imágenes), Ideogram, Leonardo.ai | Revisar que el resultado no se parezca a un personaje existente |
| Malla 3D base desde imagen | Meshy.ai, Tripo3D | Los planes gratis pueden pedir atribución o no permitir uso comercial: leer sus términos antes de publicar. Siempre retopología a < 10k triángulos y rig R15 en Blender |
| Modelado, retopología, rig | Blender (gratis, sin restricciones) | — |
| Animación | Animation Editor de Roblox Studio (o Moon Animator) | Ninguna IA mete keyframes por ti: Gemini te guía, tú animas |
| Texturas/materiales del escenario | Material Generator y Assistant de Roblox Studio | — |
| Efectos de sonido | jsfxr (gratis, en el navegador) | Los sonidos que generas son tuyos |
| Efectos de sonido realistas | ElevenLabs Sound Effects | El plan gratis puede pedir atribución y limitar el uso comercial: leer términos |
| Música | Catálogo de música con licencia de Roblox (Toolbox → Audio, publicado por Roblox) | Libre para usar dentro de Roblox |
| Música propia con IA | Suno | El plan gratis normalmente **no** permite uso comercial: si el juego tendrá ingresos, usar el catálogo de Roblox o un plan de pago |

Si una herramienta no deja claro que puedes usarlo en un juego con ingresos, **no lo uses en la versión pública**.
