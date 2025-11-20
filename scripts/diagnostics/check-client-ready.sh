#!/bin/bash

echo "════════════════════════════════════════════════════════════════"
echo "🔍 VERIFICACIÓN DEL CLIENTE UBUNTU DESKTOP"
echo "════════════════════════════════════════════════════════════════"
echo ""

ERRORS=0

echo "1️⃣  CONECTIVIDAD AL SERVIDOR:"
if ping6 -c 2 -W 3 2025:db8:10::2 &>/dev/null; then
    echo "   ✅ Ping al servidor funciona"
else
    echo "   ❌ No hay conectividad al servidor"
    echo "   → Verifica que estés en la red M_vm's"
    ((ERRORS++))
fi

echo ""
echo "2️⃣  IPv6 ASIGNADA:"
if ip -6 addr show | grep -q "2025:db8:10"; then
    IPV6=$(ip -6 addr show | grep "2025:db8:10" | grep "scope global" | awk '{print $2}' | head -1)
    echo "   ✅ IPv6 asignada: $IPV6"
else
    echo "   ❌ No tiene IPv6 de la red"
    echo "   → Verifica DHCP/RADVD en el servidor"
    ((ERRORS++))
fi

echo ""
echo "3️⃣  DNS CONFIGURADO:"
if [ -f /etc/resolv.conf ]; then
    if grep -q "2025:db8:10::2" /etc/resolv.conf; then
        echo "   ✅ DNS del servidor configurado"
    else
        echo "   ❌ DNS no apunta al servidor"
        echo "   → Ejecuta: sudo bash scripts/client/setup-client-with-proxy.sh"
        ((ERRORS++))
    fi
else
    echo "   ❌ /etc/resolv.conf no existe"
    ((ERRORS++))
fi

echo ""
echo "4️⃣  DNS FUNCIONA:"
if dig google.com AAAA +short | head -1 | grep -q ":"; then
    echo "   ✅ DNS resuelve nombres"
else
    echo "   ❌ DNS no funciona"
    ((ERRORS++))
fi

echo ""
echo "5️⃣  PROXY CONFIGURADO:"
if [ -n "$http_proxy" ]; then
    echo "   ✅ Variable http_proxy configurada: $http_proxy"
else
    echo "   ❌ Variable http_proxy no configurada"
    echo "   → Ejecuta: sudo bash scripts/client/setup-client-with-proxy.sh"
    ((ERRORS++))
fi

if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then
    echo "   ✅ Proxy APT configurado"
else
    echo "   ❌ Proxy APT no configurado"
    ((ERRORS++))
fi

echo ""
echo "6️⃣  PROXY FUNCIONA:"
if curl -x http://[2025:db8:10::2]:3128 -s -m 5 http://google.com &>/dev/null; then
    echo "   ✅ Proxy responde"
else
    echo "   ❌ Proxy no responde"
    echo "   → Verifica Squid en el servidor"
    ((ERRORS++))
fi

echo ""
echo "7️⃣  systemd-resolved:"
if systemctl is-active --quiet systemd-resolved; then
    echo "   ⚠️  systemd-resolved activo (puede interferir)"
    echo "   → Debería estar deshabilitado"
else
    echo "   ✅ systemd-resolved deshabilitado"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ CLIENTE LISTO - Puedes navegar"
    echo ""
    echo "Prueba:"
    echo "  curl http://google.com"
    echo "  firefox http://www.google.com"
else
    echo "❌ ERRORES ENCONTRADOS: $ERRORS"
    echo ""
    echo "Configura el cliente:"
    echo "  sudo bash scripts/client/setup-client-with-proxy.sh"
fi
echo "════════════════════════════════════════════════════════════════"
