#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "👥 AGREGAR USUARIOS A SAMBA"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Creando usuario 'jose' para Windows"
echo "────────────────────────────────────────────────────────"

# Crear usuario jose si no existe
if ! id jose &>/dev/null; then
    useradd -M -s /usr/sbin/nologin jose
    echo "✓ Usuario jose creado"
else
    echo "✓ Usuario jose ya existe"
fi

# Agregar a grupo pcgamers
usermod -aG pcgamers jose
echo "✓ jose agregado a grupo pcgamers"

# Configurar contraseña de Samba
(echo "123"; echo "123") | smbpasswd -a jose
smbpasswd -e jose

echo "✓ Contraseña de Samba configurada para jose: 123"

echo ""
echo "Paso 2: Configurando usuario 'administrador' para Ubuntu"
echo "────────────────────────────────────────────────────────"

# El usuario administrador ya existe en el sistema
# Solo agregamos a Samba

# Agregar a grupo pcgamers si no está
usermod -aG pcgamers administrador
echo "✓ administrador agregado a grupo pcgamers"

# Configurar contraseña de Samba
(echo "123"; echo "123") | smbpasswd -a administrador
smbpasswd -e administrador

echo "✓ Contraseña de Samba configurada para administrador: 123"

echo ""
echo "Paso 3: Verificando usuarios de Samba"
echo "────────────────────────────────────────────────────────"

echo "Usuarios en Samba:"
pdbedit -L

echo ""
echo "Paso 4: Reiniciando Samba"
echo "────────────────────────────────────────────────────────"

systemctl restart smbd nmbd

echo "✓ Samba reiniciado"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ USUARIOS CONFIGURADOS EN SAMBA"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "👥 USUARIOS CREADOS:"
echo ""
echo "  1. jose (para Windows)"
echo "     Usuario: jose"
echo "     Contraseña: 123"
echo "     Grupos: pcgamers"
echo ""
echo "  2. administrador (para Ubuntu)"
echo "     Usuario: administrador"
echo "     Contraseña: 123"
echo "     Grupos: pcgamers"
echo ""
echo "🪟 CONECTAR DESDE WINDOWS (usuario: jose):"
echo ""
echo "  1. Explorador de archivos"
echo "  2. Barra de dirección: \\\\2025:db8:10::1"
echo "  3. Cuando pida credenciales:"
echo "     Usuario: jose"
echo "     Contraseña: 123"
echo ""
echo "🐧 CONECTAR DESDE UBUNTU (usuario: administrador):"
echo ""
echo "  1. Nautilus (Archivos)"
echo "  2. Ctrl+L"
echo "  3. smb://2025:db8:10::1"
echo "  4. Cuando pida credenciales:"
echo "     Usuario: administrador"
echo "     Contraseña: 123"
echo ""
echo "📁 CARPETAS DISPONIBLES:"
echo "  - Publico (lectura/escritura para todos)"
echo "  - Juegos (lectura/escritura para pcgamers)"
echo "  - Compartido (solo lectura)"
echo ""
echo "════════════════════════════════════════════════════════════════"
