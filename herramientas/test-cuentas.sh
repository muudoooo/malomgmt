#!/bin/zsh
# Comprobaciones de las CUENTAS de dinero. Monta el mismo bundle que la prueba
# de humo (los <script> de index.html) y le añade los asserts de test-cuentas.js.
#
# La prueba de humo dice si una vista revienta; esto dice si un número está mal,
# que no se ve a simple vista y acaba en una factura. Lo llama el pre-commit.
set -e
cd "$(git rev-parse --show-toplevel)"

DIR=$(mktemp -d "${TMPDIR:-/tmp}/malo-cuentas.XXXXXX")
trap 'rm -rf "$DIR"' EXIT INT TERM

python3 - "$DIR/app.js" <<'PY'
import re, sys, io
h = io.open("index.html", encoding="utf-8").read()
bloques = re.findall(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', h, re.S)
io.open(sys.argv[1], "w", encoding="utf-8").write("\n".join(bloques))
PY

JSC=/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc
if command -v node >/dev/null 2>&1; then MOTOR=node
elif [ -x "$JSC" ]; then MOTOR="$JSC"
else echo "  !!  sin node ni jsc: me salto las cuentas"; exit 0; fi

RUN="$DIR/run.js"
cat > "$RUN" <<'SHIM'
if (typeof globalThis.print !== "function") {
  globalThis.print = function () {
    console.log(Array.prototype.map.call(arguments, String).join(" "));
  };
}
SHIM
cat herramientas/humo.js >> "$RUN"
cat "$DIR/app.js" >> "$RUN"
cat herramientas/test-cuentas.js >> "$RUN"

RES=$("$MOTOR" "$RUN" 2>&1) || true
echo "$RES"
echo "$RES" | grep -q "  X " && exit 1
exit 0
