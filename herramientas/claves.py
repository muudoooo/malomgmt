# -*- coding: utf-8 -*-
"""Lee las credenciales de MALO del Keychain de macOS.

POR QUE: vivian en ~/.royalties-keys en texto plano. Los permisos 600 protegen de
OTROS usuarios del Mac, no del codigo que ejecutas tu: un paquete de npm
malicioso en cualquier proyecto, un script que te pasen o un backup que
sincronice el home leen ese fichero sin pedir nada.

Y una de ellas es la SUPABASE_KEY con rol service_role, que se salta RLS por
completo: quien la tenga es dueno de la base entera, con independencia de las
politicas.

En el Keychain siguen siendo legibles por procesos que corran como tu, pero:
  · estan cifradas en reposo
  · no aparecen en un `cat`, un `grep -r` ni en un backup de ficheros
  · macOS registra los accesos y puede pedir confirmacion
  · no se cuelan por accidente en un commit

Uso:
    from claves import clave
    url = clave("SUPABASE_URL")
    key = clave("SUPABASE_KEY")

Guardar una nueva:
    security add-generic-password -U -a "$USER" -s malo-lo-que-sea -w
    (sin -w pide el valor por teclado y no queda en el historial del shell)
"""

import os
import subprocess

# nombre logico -> servicio en el Keychain
SERVICIOS = {
    "ADA_EMAIL":    "malo-ada-email",
    "ADA_PASSWORD": "malo-ada-password",
    "GITHUB_TOKEN": "malo-github-token",
    "SUPABASE_KEY": "malo-supabase-key",
    "SUPABASE_URL": "malo-supabase-url",
}


def clave(nombre, obligatoria=True):
    """Devuelve la credencial, o None si no esta y no es obligatoria.

    Orden de busqueda:
      1. variable de entorno (para CI o para sobreescribir en una prueba)
      2. Keychain de macOS
    """
    v = os.environ.get(nombre)
    if v:
        return v

    svc = SERVICIOS.get(nombre, "malo-" + nombre.lower().replace("_", "-"))
    r = subprocess.run(
        ["security", "find-generic-password", "-a", os.environ.get("USER", ""),
         "-s", svc, "-w"],
        capture_output=True, text=True)
    if r.returncode == 0:
        return r.stdout.strip()

    if obligatoria:
        raise SystemExit(
            "No se encontro %s.\n"
            "  Deberia estar en el Keychain como «%s».\n"
            "  Guardala con:  security add-generic-password -U -a \"$USER\" -s %s -w"
            % (nombre, svc, svc))
    return None
