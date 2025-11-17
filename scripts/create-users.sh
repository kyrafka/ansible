#!/bin/bash
# Script para crear usuarios en Ubuntu Desktop

echo "════════════════════════════════════════"
echo "👥 Creando usuarios del sistema"
echo "════════════════════════════════════════"
echo ""

# Contraseñas (cambiar según vault)
AUDITOR_PASS="auditor123"
GAMER_PASS="gamer123"

echo "1️⃣  Creando usuario 'auditor'..."
if id "auditor" &>/dev/null; then
    echo "   ℹ️  Usuario auditor ya existe"
else
    sudo useradd -m -s /bin/bash -c "Usuario Auditor" auditor
    echo "auditor:$AUDITOR_PASS" | sudo chpasswd
    echo "   ✅ Usuario auditor creado"
fi

echo "2️⃣  Creando usuario 'gamer01'..."
if id "gamer01" &>/dev/null; then
    echo "   ℹ️  Usuario gamer01 ya existe"
else
    sudo useradd -m -s /bin/bash -c "Usuario Gamer" gamer01
    echo "gamer01:$GAMER_PASS" | sudo chpasswd
    # Agregar a grupo de juegos si existe
    sudo usermod -aG audio,video,games gamer01 2>/dev/null || true
    echo "   ✅ Usuario gamer01 creado"
fi

echo ""
echo "3️⃣  Configurando permisos SSH..."

# Configurar SSH para permitir solo administrador
if [ -f /etc/ssh/sshd_config ]; then
    # Backup
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Eliminar AllowUsers anteriores
    sudo sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
    
    # Agregar nueva configuración
    echo "" | sudo tee -a /etc/ssh/sshd_config
    echo "# Restricción de usuarios SSH" | sudo tee -a /etc/ssh/sshd_config
    echo "AllowUsers administrador" | sudo tee -a /etc/ssh/sshd_config
    
    # Reiniciar SSH
    sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null
    
    echo "   ✅ SSH configurado (solo administrador puede conectarse)"
else
    echo "   ⚠️  SSH no instalado"
fi

echo ""
echo "4️⃣  Configurando permisos de lectura..."

# Auditor: solo lectura en /var/log
sudo usermod -aG adm auditor

# Gamer: acceso a juegos y multimedia
sudo usermod -aG audio,video gamer01

echo "   ✅ Permisos configurados"

echo ""
echo "════════════════════════════════════════"
echo "✅ Usuarios creados"
echo "════════════════════════════════════════"
echo ""
echo "📋 Usuarios del sistema:"
echo ""
echo "👤 administrador"
echo "   - Rol: Administrador"
echo "   - SSH: ✅ Permitido"
echo "   - Permisos: sudo, administración completa"
echo ""
echo "👤 auditor"
echo "   - Rol: Auditor"
echo "   - SSH: ❌ Bloqueado"
echo "   - Permisos: Lectura de logs (/var/log)"
echo "   - Contraseña: $AUDITOR_PASS"
echo ""
echo "👤 gamer01"
echo "   - Rol: Cliente/Gamer"
echo "   - SSH: ❌ Bloqueado"
echo "   - Permisos: Audio, video, juegos"
echo "   - Contraseña: $GAMER_PASS"
echo ""
echo "════════════════════════════════════════"
echo ""
echo "🔐 Para cambiar contraseñas:"
echo "   sudo passwd auditor"
echo "   sudo passwd gamer01"
echo ""
echo "🧪 Para probar SSH:"
echo "   ssh administrador@2025:db8:10::200  # ✅ Debe funcionar"
echo "   ssh auditor@2025:db8:10::200        # ❌ Debe fallar"
echo ""
