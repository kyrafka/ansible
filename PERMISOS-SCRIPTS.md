# 🔧 Permisos de Scripts

## Problema

En Linux, los scripts necesitan permisos de ejecución para poder ejecutarse directamente.

## Soluciones

### Opción 1: Usar `bash` (Siempre funciona)

```bash
bash scripts/run/run-common.sh
bash scripts/vms/configure-ubuntu-desktop.sh
```

**Ventaja:** No necesita permisos de ejecución

### Opción 2: Otorgar permisos manualmente

```bash
chmod +x scripts/run/run-common.sh
./scripts/run/run-common.sh
```

### Opción 3: Otorgar permisos a TODOS los scripts (RECOMENDADO)

```bash
bash scripts/fix-permissions.sh
```

Esto otorgará permisos de ejecución a todos los scripts del proyecto de una vez.

### Opción 4: Auto-permisos en cada script

Los scripts más nuevos tienen auto-permisos integrados. La primera vez que los ejecutes con `bash`, se otorgarán permisos automáticamente:

```bash
# Primera ejecución (sin permisos)
bash scripts/vms/configure-ubuntu-desktop.sh

# Segunda ejecución (ya con permisos)
./scripts/vms/configure-ubuntu-desktop.sh
```

## Agregar auto-permisos a scripts antiguos

Si quieres que TODOS los scripts tengan auto-permisos:

```bash
bash scripts/add-auto-permissions.sh
```

Esto modificará todos los scripts para que se auto-otorguen permisos.

## ¿Qué hace el auto-permiso?

Agrega esta línea al inicio de cada script:

```bash
#!/bin/bash

# Auto-otorgar permisos de ejecución
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null
```

Esto verifica si el script tiene permisos de ejecución (`-x`), y si no los tiene, se los otorga automáticamente.

## Recomendación

Para evitar problemas, siempre usa:

```bash
bash scripts/nombre-del-script.sh
```

Esto funciona sin importar si el script tiene permisos o no.

## ════════════════════════════════════════════════════════════════
