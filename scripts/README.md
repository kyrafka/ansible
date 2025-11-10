# 📜 Scripts de Ansible

Scripts organizados por funcionalidad para facilitar el uso de Ansible y la gestión de la infraestructura.

---

## 📋 Orden de Ejecución de Scripts

### 🚀 1. Configuración Inicial (Una sola vez)

```bash
# 1.1 Configurar entorno de Ansible
bash scripts/setup/setup-ansible-env.sh

# 1.2 Activar entorno virtual (siempre antes de usar Ansible)
source scripts/activate-ansible.sh
```

---

### 🖥️ 2. Configuración del Servidor

#### Opción A: Scripts de Ejecución Rápida (run/)

```bash
# 2.1 Configurar red (NAT64, Squid, radvd)
bash scripts/run/run-network.sh

# 2.2 Configurar DHCP IPv6
bash scripts/run/run-dhcp.sh

# 2.3 Configurar DNS + DNS64
bash scripts/run/run-dns.sh

# 2.4 Configurar Firewall
bash scripts/run/run-firewall.sh

# 2.5 (Opcional) Configurar almacenamiento
bash scripts/run/run-storage.sh
```

#### Opción B: Script Completo del Servidor

```bash
# Configura TODO el servidor de una vez
bash scripts/server/setup-server.sh
```

---

### 🔍 3. Verificación del Servidor

```bash
# 3.1 Verificar estado de NAT64
sudo bash scripts/diagnostics/check-nat64-status.sh

# 3.2 Verificar conectividad de red
bash scripts/diagnostics/test-network-connectivity.sh

# 3.3 Verificar conexión SSH
bash scripts/diagnostics/test-ssh-ubpc.sh

# 3.4 (Si usas ESXi) Verificar conexión con ESXi
bash scripts/diagnostics/test-govc-connection.sh
```

---

### 🖥️ 4. Gestión de VMs

```bash
# 4.1 Listar VMs existentes
bash scripts/vms/list-vms.sh

# 4.2 Crear VM interactivamente
bash scripts/vms/create-vm-interactive.sh

# 4.3 Gestionar VMs (menú interactivo)
bash scripts/vms/vm-manager.sh
```

---

### 🔧 5. Scripts de Corrección (Si algo falla)

#### DHCP no funciona:

```bash
# Corrección rápida
sudo bash scripts/dhcp/fix-dhcp-quick.sh

# Corrección completa
sudo bash scripts/dhcp/fix-dhcp-permissions.sh

# Verificar estado
sudo bash scripts/dhcp/check-dhcp.sh
```

#### NAT64 no funciona:

```bash
# Corregir rutas
sudo bash scripts/nat64/fix-nat64-routes.sh

# Reinstalar Tayga
sudo bash scripts/nat64/install-nat64-tayga.sh

# Instalar Squid Proxy (alternativa)
sudo bash scripts/nat64/install-squid-proxy.sh

# Configurar NAT64 + DNS64
sudo bash scripts/nat64/configure-nat64-dns64.sh

# (Alternativa) Instalar Jool NAT64
sudo bash scripts/nat64/install-jool-nat64.sh
```

---

### ⚡ 6. Despliegue Rápido

```bash
# Despliega toda la infraestructura automáticamente
bash scripts/quick-deploy/quick-deploy.sh
```

---

## 📁 Estructura de Carpetas

```
scripts/
├── setup/              # Configuración inicial
│   └── setup-ansible-env.sh
│
├── run/                # Ejecución de playbooks
│   ├── run-network.sh
│   ├── run-dhcp.sh
│   ├── run-dns.sh
│   ├── run-firewall.sh
│   ├── run-storage.sh
│   ├── run-common.sh
│   ├── run-role.sh
│   └── run.sh
│
├── server/             # Configuración del servidor
│   └── setup-server.sh
│
├── diagnostics/        # Verificación y diagnóstico
│   ├── check-nat64-status.sh
│   ├── test-network-connectivity.sh
│   ├── test-ssh-ubpc.sh
│   └── test-govc-connection.sh
│
├── nat64/              # NAT64 y traducción IPv6→IPv4
│   ├── install-nat64-tayga.sh
│   ├── install-squid-proxy.sh
│   ├── install-jool-nat64.sh
│   ├── fix-nat64-routes.sh
│   └── configure-nat64-dns64.sh
│
├── dhcp/               # DHCP IPv6
│   ├── fix-dhcp-quick.sh
│   ├── fix-dhcp-permissions.sh
│   └── check-dhcp.sh
│
├── vms/                # Gestión de VMs
│   ├── create-vm-interactive.sh
│   ├── list-vms.sh
│   └── vm-manager.sh
│
├── quick-deploy/       # Despliegue rápido
│   └── quick-deploy.sh
│
├── activate-ansible.sh # Activar entorno virtual
└── encrypt-vault.sh    # Encriptar contraseñas
```

---

## 🎯 Flujo Completo Recomendado

### Primera vez (Configuración desde cero):

```bash
# 1. Setup inicial
bash scripts/setup/setup-ansible-env.sh
source scripts/activate-ansible.sh

# 2. Configurar servidor
bash scripts/run/run-network.sh
bash scripts/run/run-dhcp.sh
bash scripts/run/run-dns.sh
bash scripts/run/run-firewall.sh

# 3. Verificar
sudo bash scripts/diagnostics/check-nat64-status.sh

# 4. Crear VMs
bash scripts/vms/create-vm-interactive.sh
```

### Después de reiniciar el servidor:

```bash
# 1. Activar entorno
source scripts/activate-ansible.sh

# 2. Verificar servicios
sudo bash scripts/diagnostics/check-nat64-status.sh

# 3. Si algo falló, corregir
sudo bash scripts/nat64/fix-nat64-routes.sh
sudo bash scripts/dhcp/fix-dhcp-quick.sh
```

---

## 🔐 Scripts de Utilidad

### Activar entorno de Ansible:

```bash
source scripts/activate-ansible.sh
```

**Úsalo siempre antes de ejecutar playbooks de Ansible.**

### Encriptar contraseñas:

```bash
bash scripts/encrypt-vault.sh
```

**Úsalo para encriptar `group_vars/all.vault.yml`.**

---

## 💡 Consejos

1. **Siempre activa el entorno virtual** antes de usar scripts que ejecutan Ansible
2. **Ejecuta scripts desde el directorio raíz** del proyecto
3. **Usa `sudo`** solo cuando el script lo requiera (NAT64, DHCP, diagnósticos)
4. **Verifica después de cada paso** con los scripts de diagnóstico
5. **Si algo falla**, usa los scripts de corrección antes de reinstalar

---

## 🆘 Scripts de Emergencia

### Reiniciar todos los servicios:

```bash
sudo systemctl restart isc-dhcp-server6
sudo systemctl restart bind9
sudo systemctl restart radvd
sudo systemctl restart squid
sudo bash scripts/nat64/fix-nat64-routes.sh
```

### Ver logs:

```bash
# DHCP
sudo journalctl -u isc-dhcp-server6 -n 50

# DNS
sudo journalctl -u bind9 -n 50

# Squid
sudo tail -f /var/log/squid/access.log
```

---

**Para más detalles, consulta `ORDEN-DE-USO.md` en la raíz del proyecto.** 📚
