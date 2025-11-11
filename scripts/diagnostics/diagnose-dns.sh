#!/bin/bash
# Script de diagnóstico avanzado para DNS (BIND9)
# Ejecutar: bash scripts/diagnostics/diagnose-dns.sh

echo "════════════════════════════════════════════════════════"
echo "🔬 DIAGNÓSTICO AVANZADO DE DNS (BIND9)"
echo "════════════════════════════════════════════════════════"
echo ""

# 1. Probar DNS directamente
echo "🧪 1. Probando DNS directamente en el servidor:"
echo "→ dig @localhost gamecenter.local AAAA"
dig @localhost gamecenter.local AAAA
echo ""

# 2. Ver interfaces donde escucha BIND9
echo "🔌 2. Interfaces donde BIND9 está escuchando:"
echo "→ sudo ss -tulpn | grep :53"
sudo ss -tulpn | grep :53
echo ""

# 3. Ver logs de errores
echo "📋 3. Logs de BIND9 (últimos 50, solo errores):"
echo "→ sudo journalctl -u named -n 50 | grep -i error"
sudo journalctl -u named -n 50 | grep -i error
echo ""

# 4. Ver contenido del archivo de zona
echo "📄 4. Contenido del archivo de zona:"
echo "→ sudo cat /etc/bind/zones/db.gamecenter.local"
sudo cat /etc/bind/zones/db.gamecenter.local
echo ""

# 5. Verificar sintaxis del archivo de zona
echo "✔️  5. Verificando sintaxis del archivo de zona:"
echo "→ sudo named-checkzone gamecenter.local /etc/bind/zones/db.gamecenter.local"
sudo named-checkzone gamecenter.local /etc/bind/zones/db.gamecenter.local
echo ""

# 6. Verificar configuración de BIND9
echo "⚙️  6. Verificando configuración de BIND9:"
echo "→ sudo named-checkconf"
sudo named-checkconf && echo "✅ Configuración válida" || echo "❌ Configuración inválida"
echo ""

# 7. Ver estado del servicio
echo "🔧 7. Estado del servicio BIND9:"
echo "→ sudo systemctl status named --no-pager -l"
sudo systemctl status named --no-pager -l
echo ""

# 8. Ver named.conf.local
echo "📝 8. Configuración de zonas locales:"
echo "→ sudo cat /etc/bind/named.conf.local"
sudo cat /etc/bind/named.conf.local
echo ""

# 9. Probar resolución de otros registros
echo "🧪 9. Probando otros registros DNS:"
echo "→ servidor.gamecenter.local"
dig @localhost servidor.gamecenter.local AAAA +short
echo "→ www.gamecenter.local"
dig @localhost www.gamecenter.local AAAA +short
echo "→ web.gamecenter.local"
dig @localhost web.gamecenter.local AAAA +short
echo ""

echo "════════════════════════════════════════════════════════"
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "════════════════════════════════════════════════════════"
