#!/bin/bash

# ════════════════════════════════════════════════════════════════
# 🔧 SCRIPT PARA ARREGLAR CONFIGURACIÓN DE ANSIBLE PARA WINDOWS
# ════════════════════════════════════════════════════════════════

echo "🔧 Arreglando configuración de Ansible para Windows..."
echo ""

# 1. Crear archivo de configuración de Ansible
echo "1️⃣  Creando ansible.cfg..."
cat > ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
deprecation_warnings = False
interpreter_python = auto_silent

[privilege_escalation]
become = False
EOF

echo "   ✅ ansible.cfg creado"
echo ""

# 2. Crear inventario correcto para Windows
echo "2️⃣  Creando inventario de Windows..."
cat > inventory/windows.ini << 'EOF'
[windows]
win11 ansible_host=2025:db8:10::4f

[windows:vars]
ansible_connection=winrm
ansible_user=jose
ansible_password=123
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
ansible_become=no
ansible_become_method=runas
EOF

echo "   ✅ Inventario creado en inventory/windows.ini"
echo ""

# 3. Probar conexión
echo "3️⃣  Probando conexión..."
ansible win11 -i inventory/windows.ini -m win_ping

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ¡Conexión exitosa!"
    echo ""
    echo "4️⃣  Ejecutando comando de prueba..."
    ansible win11 -i inventory/windows.ini -m win_shell -a "ipconfig | findstr IPv6"
else
    echo ""
    echo "❌ Error en la conexión"
    echo ""
    echo "Verifica:"
    echo "  1. WinRM está activo en Windows: winrm get winrm/config"
    echo "  2. Puerto 5985 abierto: nc -zv 2025:db8:10::4f 5985"
    echo "  3. Usuario y contraseña correctos"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
