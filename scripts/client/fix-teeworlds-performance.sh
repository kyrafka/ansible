#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🚀 OPTIMIZAR TEEWORLDS PARA MÁXIMO RENDIMIENTO"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo "❌ Este script debe ejecutarse como root"
    echo "   Usa: sudo bash $0"
    exit 1
fi

echo "Paso 1: Instalando herramientas"
echo "────────────────────────────────────────────────────────"

apt install -y xdotool cpufrequtils

echo "✓ Herramientas instaladas"

echo ""
echo "Paso 2: Configurando CPU para máximo rendimiento"
echo "────────────────────────────────────────────────────────"

# Cambiar gobernador de CPU a performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > $cpu 2>/dev/null
done

echo "✓ CPU en modo performance"

echo ""
echo "Paso 3: Desactivando servicios innecesarios"
echo "────────────────────────────────────────────────────────"

# Detener servicios que consumen recursos
systemctl stop snapd snapd.socket 2>/dev/null
systemctl stop packagekit 2>/dev/null
systemctl stop unattended-upgrades 2>/dev/null

echo "✓ Servicios detenidos"

echo ""
echo "Paso 4: Configurando Teeworlds para bajo rendimiento"
echo "────────────────────────────────────────────────────────"

# Crear configuración optimizada para TODOS los usuarios
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        
        mkdir -p "$user_home/.teeworlds"
        
        cat > "$user_home/.teeworlds/settings.cfg" << 'EOF'
# Gráficos - MÍNIMO para máximo FPS
gfx_fullscreen 0
gfx_screen_width 800
gfx_screen_height 600
gfx_vsync 0
gfx_refresh_rate 0
gfx_fsaa_samples 0
gfx_texture_quality 0
gfx_texture_compression 1
gfx_high_detail 0
gfx_clear 0

# Mouse - MEJORADO
inp_mousesens 200
cl_mouse_deadzone 0
cl_mouse_followfactor 60
cl_mouse_max_distance 800
cl_mouse_min_distance 0

# Rendimiento
cl_cpu_throttle 0
cl_refresh_rate 60
gfx_asyncrender 1

# Red
cl_predict 1
cl_predict_players 1

# Audio - DESACTIVADO para mejor rendimiento
snd_enable 0
snd_volume 0

# Otros
cl_showfps 1
EOF

        chown -R $username:$username "$user_home/.teeworlds"
        echo "✓ Configuración creada para $username"
    fi
done

echo ""
echo "Paso 5: Creando script de inicio optimizado"
echo "────────────────────────────────────────────────────────"

cat > /usr/local/bin/teeworlds-optimized << 'EOF'
#!/bin/bash

# Matar procesos innecesarios
killall -9 update-notifier 2>/dev/null
killall -9 gnome-software 2>/dev/null

# Limpiar caché
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null

# Prioridad alta para Teeworlds
nice -n -10 teeworlds &

# Esperar a que inicie
sleep 2

# Mensaje
notify-send "Teeworlds Optimizado" "Juego iniciado con máximo rendimiento" -i applications-games

echo "Teeworlds iniciado con prioridad alta"
echo "Usa el teclado para navegar:"
echo "  - Flechas: Mover entre opciones"
echo "  - Enter: Seleccionar"
echo "  - Esc: Volver"
EOF

chmod +x /usr/local/bin/teeworlds-optimized

echo "✓ Script de inicio creado"

echo ""
echo "Paso 6: Optimizando sistema gráfico"
echo "────────────────────────────────────────────────────────"

# Desactivar compositing (efectos visuales)
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        username=$(basename "$user_home")
        sudo -u $username DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $username)/bus" \
            gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
        sudo -u $username DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $username)/bus" \
            gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null || true
    fi
done

echo "✓ Efectos visuales desactivados"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ TEEWORLDS OPTIMIZADO AL MÁXIMO"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🎮 PARA INICIAR TEEWORLDS OPTIMIZADO:"
echo "   teeworlds-optimized"
echo ""
echo "⌨️  CONTROLES (usa el teclado):"
echo "   Menú:"
echo "     - Flechas arriba/abajo: Navegar"
echo "     - Enter: Seleccionar"
echo "     - Esc: Volver"
echo ""
echo "   En el juego:"
echo "     - A/D o Flechas: Mover"
echo "     - Espacio: Saltar"
echo "     - Mouse: Apuntar (si funciona)"
echo "     - Click izquierdo: Disparar"
echo ""
echo "⚡ OPTIMIZACIONES APLICADAS:"
echo "   ✓ CPU en modo performance"
echo "   ✓ Gráficos en calidad mínima (800x600)"
echo "   ✓ VSync desactivado"
echo "   ✓ Audio desactivado"
echo "   ✓ Efectos visuales desactivados"
echo "   ✓ Prioridad alta de CPU"
echo "   ✓ Mouse mejorado"
echo ""
echo "💡 SI SIGUE LENTO:"
echo "   1. Aumenta RAM de la VM (mínimo 2GB)"
echo "   2. Aumenta CPUs de la VM (mínimo 2 cores)"
echo "   3. Habilita aceleración 3D en ESXi"
echo "   4. Aumenta memoria de video (128MB+)"
echo ""
echo "🚀 INICIA EL JUEGO:"
echo "   teeworlds-optimized"
echo ""
echo "════════════════════════════════════════════════════════════════"
