# Comprobación antes de cada commit

## Qué hace

Antes de dejarte hacer un commit, saca todo el JavaScript que hay dentro de
`index.html` y comprueba que compila. Si no compila, el commit no sale.

## Por qué

Toda la app va en un solo `index.html` con el JavaScript dentro. Una llave de
más no da error en ningún sitio: ni al guardar, ni al hacer commit, ni al
desplegar. El fallo aparece cuando el navegador carga la página, y entonces
**no se ejecuta absolutamente nada** — la app se queda en «Conectando…» para
todo el equipo.

Ya ocurrió una vez, en producción.

Un `console.log` filtrado tampoco lo detecta: si el archivo no compila, no hay
ningún log que leer. Lo único que sirve es que un motor de JavaScript intente
parsearlo. Eso es lo que hace este hook.

## Instalación

Una sola vez, en cada ordenador que clone el repositorio:

```
git config core.hooksPath .githooks
```

`core.hooksPath` es configuración local de git: **no viaja con el clon**. Si tu
compañero clona el repo y no ejecuta esa línea, el hook no le corre a él.

## Cómo saber si está puesto

```
git config core.hooksPath      # debe responder: .githooks
```

## Saltárselo

```
git commit --no-verify
```

Solo si sabes exactamente por qué.

## Requisitos

Ninguno. Usa `python3` y `osascript`, que vienen con macOS. No hace falta
instalar Node.

Si algún día instaláis Node, `node --check` hace lo mismo y es más rápido; en
ese caso se puede simplificar el hook a dos líneas.

## Lo que NO comprueba

Solo la sintaxis. No comprueba que la app funcione, ni que una función exista,
ni que una vista pinte bien. Para eso hay que abrirla.

La regla que va con esto: **antes de subir a `publicado`, abrir la app y
comprobar que la pantalla de acceso aparece.** Es la comprobación más barata
que existe y detecta el 90% de lo que este hook no ve.
