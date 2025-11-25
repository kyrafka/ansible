#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 👥 CREAR USUARIOS EN WINDOWS 11
# ════════════════════════════════════════════════════════════════

echo "👥 Creando usuarios en Windows 11..."
echo ""

# Crear usuario 'cliente'
echo "1️⃣  Creando usuario 'cliente'..."
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user cliente 123!123 /add"

echo ""
echo "2️⃣  Verificando usuarios creados..."
ansible win11 -i inventory/windows.ini -m ansible.windows.win_shell -a "net user"

echo ""
echo "✅ Usuarios configurados:"
echo "  - dev (contraseña: 123!123)"
echo "  - cliente (contraseña: 123!123)"
echo ""
