#!/bin/bash
# Script para instalar servidor de Minecraft en Ubuntu Desktop

# Auto-permisos
[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null

set -e

echo "════════════════════════════════════════════════════════"
echo "🎮 Instalando Servidor de Minecraft"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "1️⃣  Instalando Java..."
apt update
apt install -y openjdk-21-jre-headless screen wget

echo ""
echo "2️⃣  Creando usuario para Minecraft..."
if ! id -u minecraft > /dev/null 2>&1; then
    useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
    echo "  ✓ Usuario minecraft creado"
else
    echo "  ✓ Usuario minecraft ya existe"
fi

echo ""
echo "3️⃣  Descargando servidor de Minecraft..."
cd /opt/minecraft

# Descargar última versión del servidor
MINECRAFT_VERSION="1.20.1"
if [ ! -f "server.jar" ]; then
    wget -O server.jar https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar
    echo "  ✓ Servidor descargado"
else
    echo "  ✓ Servidor ya existe"
fi

echo ""
echo "4️⃣  Configurando servidor..."

# Aceptar EULA
echo "eula=true" > eula.txt

# Crear configuración del servidor
cat > server.properties << 'EOF'
# Configuración del servidor Minecraft
server-port=25565
gamemode=survival
difficulty=easy
max-players=10
online-mode=false
pvp=true
enable-command-block=true
motd=Servidor GameCenter LAN
white-list=false
spawn-protection=0
max-world-size=10000
view-distance=10
simulation-distance=10
EOF

echo "  ✓ Configuración creada"

# Cambiar permisos
chown -R minecraft:minecraft /opt/minecraft

echo ""
echo "5️⃣  Creando script de inicio..."
cat > /opt/minecraft/start.sh << 'EOF'
#!/bin/bash
cd /opt/minecraft
java -Xmx2G -Xms1G -jar server.jar nogui
EOF

chmod +x /opt/minecraft/start.sh
chown minecraft:minecraft /opt/minecraft/start.sh

echo "  ✓ Script de inicio creado"

echo ""
echo "6️⃣  Creando servicio systemd..."
cat > /etc/systemd/system/minecraft.service << 'EOF'
[Unit]
Description=Minecraft Server
After=network.target

[Service]
Type=forking
User=minecraft
WorkingDirectory=/opt/minecraft
ExecStart=/usr/bin/screen -dmS minecraft /opt/minecraft/start.sh
ExecStop=/usr/bin/screen -S minecraft -X quit
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "  ✓ Servicio creado"

echo ""
echo "7️⃣  Configurando firewall..."
ufw allow 25565/tcp comment 'Minecraft Server'
echo "  ✓ Puerto 25565 abierto"

echo ""
echo "8️⃣  Iniciando servidor por primera vez..."
echo "   (Esto generará el mundo, puede tardar 1-2 minutos)"
echo ""

# Iniciar como usuario minecraft para generar mundo
su - minecraft -c "cd /opt/minecraft && timeout 120 java -Xmx2G -Xms1G -jar server.jar nogui" || true

echo ""
echo "9️⃣  Habilitando servicio..."
systemctl enable minecraft
systemctl start minecraft

sleep 5

if systemctl is-active --quiet minecraft; then
    echo "  ✓ Servidor iniciado correctamente"
else
    echo "  ⚠️  Servidor no se inició, verificando logs..."
    journalctl -xeu minecraft --no-pager | tail -20
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Servidor de Minecraft instalado"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Información del servidor:"
echo ""
echo "  IP del servidor: $(ip -6 addr show ens33 | grep 'scope global' | awk '{print $2}' | cut -d'/' -f1 | head -1)"
echo "  Puerto: 25565"
echo "  Versión: $MINECRAFT_VERSION"
echo "  Modo: Survival"
echo "  Max jugadores: 10"
echo ""
echo "🎮 Comandos útiles:"
echo ""
echo "  Ver logs en tiempo real:"
echo "    sudo journalctl -fu minecraft"
echo ""
echo "  Conectarse a la consola:"
echo "    sudo screen -r minecraft"
echo "    (Para salir: Ctrl+A, luego D)"
echo ""
echo "  Reiniciar servidor:"
echo "    sudo systemctl restart minecraft"
echo ""
echo "  Detener servidor:"
echo "    sudo systemctl stop minecraft"
echo ""
echo "  Ver estado:"
echo "    sudo systemctl status minecraft"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo "🔗 Para conectarte desde VirtualBox:"
echo ""
echo "  1. Instala Minecraft Java Edition"
echo "  2. Ve a Multijugador → Servidor Directo"
echo "  3. Dirección: [$(ip -6 addr show ens33 | grep 'scope global' | awk '{print $2}' | cut -d'/' -f1 | head -1)]:25565"
echo ""
echo "  O si tienes IPv4 en VirtualBox:"
echo "  - Configura port forwarding en el router/switch"
echo "  - O usa la IP del servidor"
echo ""
echo "════════════════════════════════════════════════════════"
