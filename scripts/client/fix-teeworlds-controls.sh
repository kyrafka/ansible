#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🎮 CONFIGURAR CONTROLES WASD PARA TEEWORLDS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Detectar usuario actual
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Ejecuta este script como usuario normal (sin sudo)"
    echo "   Usa: bash $0"
    exit 1
fi

echo "Configurando controles para usuario: $USER"
echo ""

# Crear directorio si no existe
mkdir -p ~/.teeworlds

# Crear configuración completa
cat > ~/.teeworlds/settings.cfg << 'EOF'
# ═══════════════════════════════════════════════════════════
# CONFIGURACIÓN OPTIMIZADA DE TEEWORLDS
# ═══════════════════════════════════════════════════════════

# GRÁFICOS - MÍNIMO PARA MÁXIMO FPS
gfx_fullscreen 1
gfx_screen_width 800
gfx_screen_height 600
gfx_vsync 0
gfx_refresh_rate 0
gfx_fsaa_samples 0
gfx_texture_quality 0
gfx_texture_compression 1
gfx_high_detail 0
gfx_clear 0
gfx_asyncrender 1

# MOUSE - CAPTURADO Y MEJORADO
inp_grab 1
inp_mousesens 150
cl_mouse_deadzone 0
cl_mouse_followfactor 60
cl_mouse_max_distance 800

# CONTROLES WASD
bind w +jump
bind a +left
bind s +hook
bind d +right
bind space +fire
bind mouse1 +fire

# APUNTAR CON FLECHAS (alternativa al mouse)
bind up +aimup
bind down +aimdown
bind left +aimleft
bind right +aimright

# OTROS CONTROLES
bind 1 +weapon1
bind 2 +weapon2
bind 3 +weapon3
bind 4 +weapon4
bind 5 +weapon5
bind tab +scoreboard
bind escape quit

# RENDIMIENTO
cl_cpu_throttle 0
cl_refresh_rate 60
cl_predict 1
cl_predict_players 1

# AUDIO DESACTIVADO (mejor rendimiento)
snd_enable 0
snd_volume 0

# MOSTRAR FPS
cl_showfps 1

# RED
cl_showping 1
EOF

echo "✓ Configuración creada en ~/.teeworlds/settings.cfg"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ CONTROLES CONFIGURADOS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🎮 CONTROLES DEL JUEGO:"
echo ""
echo "  Movimiento:"
echo "    W - Saltar"
echo "    A - Mover izquierda"
echo "    D - Mover derecha"
echo "    S - Gancho (hook)"
echo ""
echo "  Combate:"
echo "    Espacio - Disparar"
echo "    Mouse - Apuntar"
echo "    Click izquierdo - Disparar"
echo ""
echo "  Apuntar sin mouse (alternativa):"
echo "    Flechas - Apuntar en esa dirección"
echo ""
echo "  Armas:"
echo "    1, 2, 3, 4, 5 - Cambiar arma"
echo ""
echo "  Otros:"
echo "    Tab - Ver puntuaciones"
echo "    Esc - Menú / Salir"
echo ""
echo "🚀 PARA JUGAR:"
echo "   teeworlds-optimized"
echo ""
echo "💡 TIPS:"
echo "  - El mouse está capturado en pantalla completa"
echo "  - Si el mouse falla, usa las flechas para apuntar"
echo "  - Presiona Esc varias veces para salir"
echo ""
echo "════════════════════════════════════════════════════════════════"
