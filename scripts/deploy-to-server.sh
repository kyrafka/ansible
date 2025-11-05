#!/bin/bash
# Script para desplegar el proyecto al servidor real

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 DESPLIEGUE AL SERVIDOR REAL${NC}"
echo "================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "site.yml" ]; then
    echo -e "${RED}❌ Error: No se encuentra site.yml. Ejecuta desde el directorio del proyecto.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Pasos del despliegue:${NC}"
echo "1. Verificar conectividad al servidor"
echo "2. Verificar sintaxis de playbooks"
echo "3. Ejecutar despliegue por roles"
echo "4. Verificar servicios"
echo ""

# Paso 1: Verificar conectividad
echo -e "${BLUE}1️⃣ Verificando conectividad...${NC}"
if ansible servidores_ubuntu -m ping; then
    echo -e "${GREEN}✅ Conectividad OK${NC}"
else
    echo -e "${RED}❌ Error de conectividad. Verifica:${NC}"
    echo "   - IP del servidor en inventory/hosts.ini"
    echo "   - Usuario y claves SSH"
    echo "   - Conectividad de red"
    exit 1
fi

echo ""

# Paso 2: Verificar sintaxis
echo -e "${BLUE}2️⃣ Verificando sintaxis de playbooks...${NC}"
if ansible-playbook --syntax-check site.yml; then
    echo -e "${GREEN}✅ Sintaxis OK${NC}"
else
    echo -e "${RED}❌ Error de sintaxis${NC}"
    exit 1
fi

echo ""

# Paso 3: Despliegue por etapas
echo -e "${BLUE}3️⃣ Iniciando despliegue por etapas...${NC}"
echo ""

# Etapa 1: Configuración básica
echo -e "${YELLOW}📦 Etapa 1: Configuración básica (common)${NC}"
read -p "¿Continuar con configuración básica? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ansible-playbook site.yml --tags common --limit servidores_ubuntu
    echo -e "${GREEN}✅ Configuración básica completada${NC}"
else
    echo -e "${YELLOW}⏭️ Saltando configuración básica${NC}"
fi

echo ""

# Etapa 2: Servicios de red
echo -e "${YELLOW}🌐 Etapa 2: Servicios de red (DNS, DHCP)${NC}"
read -p "¿Continuar con servicios de red? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ansible-playbook site.yml --tags dns,dhcp --limit servidores_ubuntu
    echo -e "${GREEN}✅ Servicios de red completados${NC}"
else
    echo -e "${YELLOW}⏭️ Saltando servicios de red${NC}"
fi

echo ""

# Etapa 3: Seguridad
echo -e "${YELLOW}🔒 Etapa 3: Configuración de seguridad${NC}"
read -p "¿Continuar con seguridad? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ansible-playbook site.yml --tags firewall,security --limit servidores_ubuntu
    echo -e "${GREEN}✅ Seguridad completada${NC}"
else
    echo -e "${YELLOW}⏭️ Saltando seguridad${NC}"
fi

echo ""

# Etapa 4: Monitoreo
echo -e "${YELLOW}📊 Etapa 4: Monitoreo y logging${NC}"
read -p "¿Continuar con monitoreo? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ansible-playbook site.yml --tags monitoring,storage --limit servidores_ubuntu
    echo -e "${GREEN}✅ Monitoreo completado${NC}"
else
    echo -e "${YELLOW}⏭️ Saltando monitoreo${NC}"
fi

echo ""

# Paso 4: Verificación final
echo -e "${BLUE}4️⃣ Verificación de servicios...${NC}"
echo ""

echo "🔍 Verificando servicios instalados:"
ansible servidores_ubuntu -m shell -a "systemctl status bind9 --no-pager -l" || true
ansible servidores_ubuntu -m shell -a "systemctl status isc-dhcp-server6 --no-pager -l" || true
ansible servidores_ubuntu -m shell -a "systemctl status fail2ban --no-pager -l" || true

echo ""
echo -e "${GREEN}🎉 DESPLIEGUE COMPLETADO${NC}"
echo ""
echo -e "${BLUE}📋 Próximos pasos:${NC}"
echo "1. Verificar logs: ssh usuario@servidor 'tail -f /var/log/syslog'"
echo "2. Probar DNS: dig @servidor-ip gamecenter.local"
echo "3. Verificar DHCP: journalctl -u isc-dhcp-server6 -f"
echo "4. Revisar firewall: ufw status verbose"