# 🔄 Flujo Completo del Proyecto

## 📋 **Escenario actual:**

```
Servidor Ubuntu existente (2025:db8:10::2)
├── Servicios IPv6 configurados
├── DHCPv6 server activo
└── Se conecta a ESXi (172.17.25.11)
    └── Crea VM "UBPC"
        └── Obtiene IP automáticamente (2025:db8:10::10+)
```

## 🎯 **Dos flujos de trabajo:**

### **FLUJO 1: Solo configurar servidor actual**
```bash
./scripts/configurar-servidor.sh
```

**¿Qué hace?**
1. ✅ Configura DNS/BIND9 en tu servidor (`2025:db8:10::2`)
2. ✅ Configura DHCPv6 server (asigna IPs desde `::10`)
3. ✅ Configura Apache2 web server
4. ✅ Configura firewall + fail2ban
5. ✅ Servicios de monitoreo

**Resultado:** Tu servidor Ubuntu actual queda completamente configurado como servidor de red IPv6.

---

### **FLUJO 2: Crear VM Ubuntu + Configurar**

#### **Paso 1: Crear VM vacía**
```bash
./scripts/crear-vm-ubuntu.sh
```

**¿Qué hace?**
1. 🔌 Se conecta a ESXi (172.17.25.11)
2. 🖥️ Crea VM "UBPC" (2GB RAM, 1 CPU, 20GB disco)
3. 💿 Monta ISO Ubuntu 24.04
4. ⚡ Enciende la VM
5. 📋 Te dice qué hacer después

#### **Paso 2: Instalar Ubuntu (MANUAL)**
**En la consola de ESXi:**
1. 🖥️ Abrir consola de la VM "UBPC"
2. 💿 Instalar Ubuntu 24.04 normalmente
3. 👤 Crear usuario "ubuntu"
4. 🌐 **Red se configura automáticamente** (DHCPv6 desde tu servidor)
5. 🔧 Instalar SSH: `sudo apt install openssh-server`

#### **Paso 3: Configurar servicios automáticamente**
```bash
# Agregar IP de la VM al inventario
echo "ubpc ansible_host=2025:db8:10::10 ansible_user=ubuntu" >> inventory/hosts.ini

# Configurar servicios
ansible-playbook site.yml --limit nueva_vm_ubpc
```

**¿Qué hace?**
1. ✅ Configura los mismos servicios IPv6 en la nueva VM
2. ✅ DNS, Web, DHCPv6, Firewall, etc.
3. ✅ La VM queda como servidor secundario

---

## 🌐 **Configuración de red automática:**

### **¿Por qué no necesitas configurar red manualmente?**

1. **Tu servidor actual** (`2025:db8:10::2`) ya tiene **DHCPv6 server**
2. **La nueva VM** se conecta a la misma red (`VM Network`)
3. **DHCPv6 asigna automáticamente** IP del rango `2025:db8:10::10` en adelante
4. **No necesitas configuración manual** de IP, gateway, DNS

### **Flujo de red:**
```
ESXi Network "VM Network"
├── Servidor Ubuntu (2025:db8:10::2) ← DHCPv6 Server
└── Nueva VM UBPC (2025:db8:10::10+) ← Cliente DHCP
```

---

## 🎯 **Resultado final:**

### **Con FLUJO 1:**
- 1 servidor Ubuntu con servicios IPv6 completos

### **Con FLUJO 2:**
- 2 servidores Ubuntu con servicios IPv6 completos
- Redundancia de servicios
- Balanceo de carga posible

---

## 🚀 **¿Cuál elegir?**

### **Elige FLUJO 1 si:**
- Solo necesitas un servidor
- Quieres simplicidad
- Recursos limitados

### **Elige FLUJO 2 si:**
- Quieres redundancia
- Necesitas separar servicios
- Tienes recursos suficientes en ESXi
- Quieres practicar automatización completa

---

## 💡 **Comandos útiles:**

```bash
# Ver servicios en servidor actual
systemctl status bind9 apache2 isc-dhcp-server6

# Ver IPs asignadas por DHCP
journalctl -u isc-dhcp-server6 -f

# Verificar conectividad IPv6
ping6 2025:db8:10::1

# Ver todas las IPs de la red
ip -6 neigh show
```