#!/bin/bash
# Script para agregar auto-permisos a todos los scripts del proyecto

# Auto-otorgar permisos a sí mismo
chmod +x "$0" 2>/dev/null || true

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔧 Agregando auto-permisos a todos los scripts             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Línea a agregar después del shebang
AUTO_PERM_LINE='[ ! -x "$0" ] && chmod +x "$0" 2>/dev/null'

count=0

# Procesar todos los scripts .sh
while IFS= read -r -d '' script; do
    # Verificar si ya tiene la línea de auto-permisos
    if ! grep -q 'chmod +x "$0"' "$script"; then
        # Crear archivo temporal
        temp_file=$(mktemp)
        
        # Leer el archivo línea por línea
        first_line=true
        while IFS= read -r line; do
            echo "$line" >> "$temp_file"
            
            # Si es la primera línea (shebang), agregar auto-permisos
            if $first_line && [[ "$line" == "#!/bin/bash"* ]]; then
                echo "" >> "$temp_file"
                echo "# Auto-otorgar permisos de ejecución" >> "$temp_file"
                echo "$AUTO_PERM_LINE" >> "$temp_file"
                first_line=false
            fi
        done < "$script"
        
        # Reemplazar el archivo original
        mv "$temp_file" "$script"
        chmod +x "$script"
        
        echo -e "${GREEN}✓${NC} $script"
        ((count++))
    else
        echo -e "${BLUE}→${NC} $script (ya tiene auto-permisos)"
    fi
done < <(find scripts -name "*.sh" -type f -print0 2>/dev/null)

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Auto-permisos agregados a $count scripts                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
