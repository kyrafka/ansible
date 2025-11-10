# Documentación de Scripts y Playbooks

Guía detallada del funcionamiento de cada script y playbook del proyecto.

---

## 📑 Índice

1. [Scripts de Utilidad](#scripts-de-utilidad)
2. [Scripts de Ejecución de Roles](#scripts-de-ejecución-de-roles)
3. [Playbooks Principales](#playbooks-principales)
4. [Playbooks Individuales](#playbooks-individuales)
5. [Flujo de Ejecución Completo](#flujo-de-ejecución-completo)

---

## 🛠️ Scripts de Utilidad

### `activate-ansible.sh`

**Propósito:** Activar el entorno virtual de Python con Ansible instalado.

**Funcionamiento:**
```bash
#!/bin/bash
source ~/.ansible-venv/bin/activate
echo "✓ Entorno Ansible activado"
```

**Flujo:**
1. Activa el virtualenv de Python ubicado en `~/.ansible-venv/`
2. Muestra mensaje de confirmación
3. Deja el shell con Ansible disponible

**Uso:**
```bash
source activate-ansible.sh
# O
. activate-ansible.sh
```

**Cuándo usarlo:**
- Antes de ejecutar cualquier comando de Ansible manualmente
- Si quieres usar `ansible-playbook` directamente
- Para verificar la versión de Ansible: `ansible --version`

---

### `encrypt-vault.sh`

**Propósito:** Encriptar el archivo de variables sensibles con Ansible Vault.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-vault encrypt group_vars/all.vault.yml --vault-password-file .vault_pass
```

**Flujo:**
1. Cambia al directorio del proyecto (`~/ansible`)
2. Activa el entorno virtual de Ansible
3. Encripta `group_vars/all.vault.yml` usando la contraseña en `.vault_pass`
4. Muestra instrucciones para editar el archivo encriptado

**Variables encriptadas:**
- `vault_sudo_password` - Contraseña de sudo
- `vault_vcenter_password` - Contraseña de vCenter/ESXi
- `vault_ubuntu_password` - Contraseña de usuarios Ubuntu
- Todas las contraseñas de VMs (admin, auditor, cliente)

**Uso:**
```bash
chmod +x encrypt-vault.sh
./encrypt-vault.sh
```

**Para editar después de encriptar:**
```bash
ansible-vault edit group_vars/all.vault.yml --vault-password-file .vault_pass
```

**Cuándo usarlo:**
- Cuando quieras proteger las contraseñas antes de subir a git
- En producción para mayor seguridad
- NO lo uses mientras estés desarrollando/debuggeando

---

### `run.sh` (Script Maestro)

**Propósito:** Script principal para ejecutar el playbook completo o roles individuales.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

if [ -z "$1" ]; then
    # Sin argumentos: ejecuta TODO
    ansible-playbook site.yml --connection=local --become \
        --vault-password-file .vault_pass \
        -e "ansible_become_password={{ vault_sudo_password }}"
else
    # Con argumento: ejecuta solo ese rol
    ansible-playbook site.yml --connection=local --become \
        --vault-password-file .vault_pass \
        -e "ansible_become_password={{ vault_sudo_password }}" \
        --tags "$1"
fi
```

**Flujo:**
1. Cambia al directorio del proyecto
2. Activa el entorno virtual
3. Verifica si recibió un argumento:
   - **Sin argumento:** Ejecuta todos los roles en orden
   - **Con argumento:** Ejecuta solo el rol especificado

**Parámetros de Ansible:**
- `--connection=local` - Ejecuta en el servidor local (no SSH)
- `--become` - Usa sudo para privilegios de root
- `--vault-password-file .vault_pass` - Desencripta variables sensibles
- `-e "ansible_become_password={{ vault_sudo_password }}"` - Contraseña de sudo desde vault
- `--tags "$1"` - Filtra por tag (rol específico)

**Uso:**
```bash
# Ejecutar TODO el playbook
./run.sh

# Ejecutar solo un rol
./run.sh common      # Solo configuración base
./run.sh network     # Solo red IPv6
./run.sh dns         # Solo DNS
./run.sh dhcp        # Solo DHCP
./run.sh firewall    # Solo firewall
./run.sh storage     # Solo almacenamiento
```

**Orden de ejecución (sin argumentos):**
1. common → Paquetes base, logs, usuarios
2. network → IPv6, NAT66, interfaces
3. dns → BIND9, zonas DNS
4. dhcp → DHCPv6 server
5. firewall → UFW, fail2ban
6. storage → NFS, monitoreo

---

## 🎯 Scripts de Ejecución de Roles

### `run-common.sh`

**Propósito:** Ejecutar solo el rol `common`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook site.yml --connection=local --become \
    --ask-become-pass --tags common \
    -e "ansible_python_interpreter=/usr/bin/python3"
```

**Lo que ejecuta:**
- Instalación de paquetes base (vim, git, curl, wget, net-tools)
- Creación de directorios de logs
- Configuración de rsyslog
- Configuración de logrotate
- Scripts de monitoreo

**Uso:**
```bash
./run-common.sh
```

**Nota:** Este script pide la contraseña de sudo (`--ask-become-pass`). Usa `./run.sh common` para no pedirla.

---

### `run-network.sh`

**Propósito:** Ejecutar solo el rol `network`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

# Crea un playbook temporal
cat > /tmp/run-network.yml <<EOF
---
- name: Ejecutar solo rol network
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: network
EOF

# Ejecuta el playbook temporal
ansible-playbook /tmp/run-network.yml --become --ask-become-pass

# Limpia el archivo temporal
rm /tmp/run-network.yml
```

**Lo que ejecuta:**
- Configuración de interfaz ens33 (IPv4 DHCP)
- Configuración de interfaz ens34 (IPv6 2025:db8:10::2/64)
- Habilitación de IP forwarding
- Configuración de NAT66
- Aplicación de netplan

**Uso:**
```bash
./run-network.sh
```

**⚠️ IMPORTANTE:** Este rol reinicia la red. Asegúrate de tener acceso físico o consola.

---

### `run-dns.sh`

**Propósito:** Ejecutar solo el rol `dns_bind`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-dns.yml <<EOF
---
- name: Ejecutar solo rol dns_bind
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: dns_bind
EOF

ansible-playbook /tmp/run-dns.yml --become --ask-become-pass
rm /tmp/run-dns.yml
```

**Lo que ejecuta:**
- Instalación de BIND9
- Creación de zona directa (gamecenter.local)
- Creación de zona inversa (IPv6)
- Configuración de forwarders
- Habilitación de logs de consultas

**Archivos creados:**
- `/etc/bind/named.conf.options`
- `/etc/bind/named.conf.local`
- `/etc/bind/zones/db.gamecenter.local`
- `/etc/bind/zones/db.2025.db8.10`

**Uso:**
```bash
./run-dns.sh
```

---

### `run-dhcp.sh`

**Propósito:** Ejecutar solo el rol `dhcpv6`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-dhcp.yml <<EOF
---
- name: Ejecutar solo rol dhcpv6
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: dhcpv6
EOF

ansible-playbook /tmp/run-dhcp.yml --become --ask-become-pass
rm /tmp/run-dhcp.yml
```

**Lo que ejecuta:**
- Instalación de ISC DHCP Server (IPv6)
- Configuración de rango de IPs (2025:db8:10::100-200)
- Configuración de DNS automático
- Configuración de gateway
- Inicio del servicio

**Archivos creados:**
- `/etc/dhcp/dhcpd6.conf`
- `/var/lib/dhcp/dhcpd6.leases`

**Uso:**
```bash
./run-dhcp.sh
```

---

### `run-firewall.sh`

**Propósito:** Ejecutar solo el rol `firewall`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate
ansible-playbook site.yml --connection=local --become \
    --vault-password-file .vault_pass \
    -e "ansible_become_password={{ vault_sudo_password }}" \
    --tags firewall
```

**Lo que ejecuta:**
- Instalación de UFW
- Instalación de fail2ban
- Configuración de reglas de firewall
- Habilitación de rate limiting en SSH
- Apertura de puertos (22, 53, 546, 547, 21000-21010)
- Configuración de fail2ban

**Puertos abiertos:**
- 22/tcp - SSH (con rate limiting)
- 53/tcp+udp - DNS
- 546/udp - DHCPv6 Client
- 547/udp - DHCPv6 Server
- 21000-21010/tcp - FTP Pasivo

**Uso:**
```bash
./run-firewall.sh
```

---

### `run-storage.sh`

**Propósito:** Ejecutar solo el rol `storage`.

**Funcionamiento:**
```bash
#!/bin/bash
cd ~/ansible
source ~/.ansible-venv/bin/activate

cat > /tmp/run-storage.yml <<EOF
---
- name: Ejecutar solo rol storage
  hosts: localhost
  connection: local
  become: true
  roles:
    - role: storage
EOF

ansible-playbook /tmp/run-storage.yml --become --ask-become-pass
rm /tmp/run-storage.yml
```

**Lo que ejecuta:**
- Instalación de servidor NFS
- Creación de directorios compartidos
- Configuración de exportaciones NFS
- Monitoreo de uso de disco
- Configuración de alertas

**Directorios creados:**
- `/srv/nfs/games` - Juegos compartidos
- `/srv/nfs/shared` - Archivos compartidos
- `/srv/nfs/backups` - Backups

**Uso:**
```bash
./run-storage.sh
```

---

## 📘 Playbooks Principales

### `site.yml` (Playbook Principal)

**Propósito:** Playbook maestro que ejecuta todos los roles en orden.

**Estructura:**
```yaml
- name: Configurar servidor Ubuntu con servicios de red
  hosts: localhost
  connection: local
  become: true
  
  tasks:
    - name: Mostrar información de la configuración
      debug: [...]
  
  roles:
    - role: common      (tags: common)
    - role: network     (tags: network)
    - role: dns_bind    (tags: dns)
    - role: dhcpv6      (tags: dhcp)
    - role: firewall    (tags: firewall)
    - role: storage     (tags: storage)
```

**Flujo de ejecución:**

1. **Inicio:**
   - Se conecta a localhost
   - Muestra banner con configuración

2. **Rol: common**
   - Instala paquetes base
   - Crea directorios de logs
   - Configura rsyslog y logrotate

3. **Rol: network**
   - Configura ens33 (IPv4 DHCP)
   - Configura ens34 (IPv6 2025:db8:10::2/64)
   - Habilita IP forwarding
   - Configura NAT66

4. **Rol: dns_bind**
   - Instala BIND9
   - Crea zonas DNS
   - Inicia servicio

5. **Rol: dhcpv6**
   - Instala ISC DHCP Server
   - Configura rango de IPs
   - Inicia servicio

6. **Rol: firewall**
   - Instala UFW y fail2ban
   - Configura reglas
   - Habilita firewall

7. **Rol: storage**
   - Instala NFS
   - Crea directorios compartidos
   - Configura exportaciones

**Variables utilizadas:**
```yaml
network_config:
  ipv6_network: "2025:db8:10::/64"
  ipv6_gateway: "2025:db8:10::1"
  server_ipv6: "2025:db8:10::2"
  domain_name: "gamecenter.local"
  dhcp_range_start: "2025:db8:10::100"
  dhcp_range_end: "2025:db8:10::200"
```

**Uso:**
```bash
# Ejecutar todo
ansible-playbook site.yml --connection=local --become --vault-password-file .vault_pass -e "ansible_become_password={{ vault_sudo_password }}"

# O simplemente
./run.sh

# Ejecutar solo un rol
./run.sh network
```

**Tiempo estimado:** 5-10 minutos (depende de la velocidad de internet para descargar paquetes)

---

### `site-interactive.yml` (Playbook Interactivo)

**Propósito:** Versión interactiva del playbook principal con pausas entre cada paso.

**Diferencias con `site.yml`:**
- Muestra banners decorados para cada paso
- Pausa antes de ejecutar cada rol
- Muestra información detallada de lo que hará
- Muestra comandos de verificación después de cada paso
- Ideal para aprendizaje o primera ejecución

**Estructura:**
```yaml
- name: Configurar servidor Ubuntu (Modo Interactivo)
  hosts: localhost
  connection: local
  become: true
  
  vars:
    interactive_mode: true
  
  tasks:
    - name: Bienvenida
    - name: Pausa inicial
    
    # Para cada rol:
    - name: Mostrar información del paso
    - name: Pausa antes de ejecutar
    - name: Ejecutar rol
    - name: Mostrar resultado
    
    - name: Resumen final
```

**Flujo interactivo:**

1. **Bienvenida:**
```
╔═══════════════════════════════════════════════════════════════╗
║        🎮 GameCenter - Configuración del Servidor           ║
╚═══════════════════════════════════════════════════════════════╝

Este playbook configurará:
  1. Paquetes comunes del sistema
  2. Red IPv6 en ens34
  3. Servidor DNS (BIND9)
  4. Servidor DHCP IPv6
  5. Firewall (UFW + fail2ban)
  6. Almacenamiento NFS

Presiona ENTER para comenzar...
```

2. **Cada paso muestra:**
   - Qué va a hacer
   - Qué archivos creará
   - Qué servicios iniciará
   - Advertencias importantes

3. **Después de cada paso:**
   - Confirmación de éxito
   - Comandos para verificar
   - Pausa antes del siguiente paso

4. **Resumen final:**
```
╔═══════════════════════════════════════════════════════════════╗
║              ✅ CONFIGURACIÓN COMPLETADA                     ║
╚═══════════════════════════════════════════════════════════════╝

Servicios configurados:
  ✅ Paquetes comunes instalados
  ✅ Red IPv6 en ens34 (2025:db8:10::2/64)
  ✅ DNS (BIND9) funcionando
  ✅ DHCP IPv6 asignando IPs
  ✅ Firewall activo y configurado
  ✅ Almacenamiento NFS disponible

El servidor está listo para crear VMs! 🚀
```

**Uso:**
```bash
ansible-playbook site-interactive.yml --connection=local --become --ask-become-pass
```

**Cuándo usarlo:**
- Primera vez que configuras el servidor
- Para entender qué hace cada paso
- Para debugging (puedes verificar después de cada paso)
- Para demostración o capacitación

---

### `create-vm-gamecenter.yml`

**Propósito:** Crear una VM Ubuntu en ESXi/vCenter para usar como servidor.

**⚠️ IMPORTANTE:** Este playbook es para crear la VM inicial. Una vez creada, usas `site.yml` DENTRO de la VM.

**Funcionamiento:**

1. **Verificación de conexión:**
```yaml
- name: Verificar conexión con vCenter / ESXi
  uri:
    url: "https://{{ vault_vcenter_hostname }}:{{ vault_vcenter_port }}/ui/"
    validate_certs: no
```

2. **Creación de VM:**
```yaml
- name: Crear la VM Ubuntu GameCenter
  community.vmware.vmware_guest:
    hostname: "{{ vault_vcenter_hostname }}"
    username: "{{ vault_vcenter_username }}"
    password: "{{ vault_vcenter_password }}"
    name: "{{ vmware.vm_name }}"
    state: poweredon
    hardware:
      memory_mb: "{{ vmware.memory }}"
      num_cpus: "{{ vmware.cpus }}"
    networks:
      - name: "{{ vmware.network_name }}"          # ens33 - Internet
      - name: "{{ vmware.internal_network_name }}" # ens34 - Red interna
    disk:
      - size_gb: "{{ vmware.disk_size_mb | int // 1024 }}"
    cdrom:
      - iso_path: "{{ vmware.iso_path }}"
```

**Variables necesarias:**
```yaml
# En group_vars/all.vault.yml
vault_vcenter_hostname: "168.121.48.254"
vault_vcenter_port: "10111"
vault_vcenter_username: "root"
vault_vcenter_password: "qwe123$"

# En group_vars/ubpc.yml
vmware:
  vm_name: "Ubuntu-GameCenter-Server"
  memory: 4096
  cpus: 2
  disk_size_mb: 51200
  network_name: "VM Network"           # Red para ens33
  internal_network_name: "Internal"    # Red para ens34
  iso_path: "[datastore1] ISOs/ubuntu-22.04.iso"
```

**Flujo:**
1. Verifica conexión a ESXi/vCenter
2. Crea VM con 2 adaptadores de red
3. Monta ISO de Ubuntu
4. Enciende la VM
5. Muestra resumen

**Uso:**
```bash
source activate-ansible.sh
ansible-playbook create-vm-gamecenter.yml
```

**Después de crear la VM:**
1. Instala Ubuntu manualmente desde la consola de vSphere
2. Configura SSH
3. Clona este repositorio dentro de la VM
4. Ejecuta `./run.sh` DENTRO de la VM

---

## 📄 Playbooks Individuales

Estos playbooks ejecutan un solo rol. Son equivalentes a usar `./run.sh [rol]`.

### `playbook-common.yml`
```yaml
- name: Configurar servicios comunes
  hosts: localhost
  connection: local
  become: true
  roles:
    - common
```

### `playbook-dns.yml`
```yaml
- name: Configurar DNS/BIND9
  hosts: localhost
  connection: local
  become: true
  roles:
    - dns_bind
```

### `playbook-dhcp.yml`
```yaml
- name: Configurar DHCPv6
  hosts: localhost
  connection: local
  become: true
  roles:
    - dhcpv6
```

### `playbook-firewall.yml`
```yaml
- name: Configurar Firewall
  hosts: localhost
  connection: local
  become: true
  roles:
    - firewall
```

### `playbook-storage.yml`
```yaml
- name: Configurar almacenamiento
  hosts: localhost
  connection: local
  become: true
  roles:
    - storage
```

**Uso:**
```bash
ansible-playbook playbook-common.yml --connection=local --become --ask-become-pass
ansible-playbook playbook-dns.yml --connection=local --become --ask-become-pass
# etc...
```

**Nota:** Es más fácil usar `./run.sh [rol]` que estos playbooks individuales.

---

## 🔄 Flujo de Ejecución Completo

### Escenario 1: Primera instalación completa

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd ansible-gestion-despliegue

# 2. Activar entorno Ansible
source activate-ansible.sh

# 3. Configurar contraseña
echo "ubuntu123" > .vault_pass
chmod 600 .vault_pass

# 4. Ejecutar configuración completa
./run.sh

# 5. Verificar servicios
systemctl status named
systemctl status isc-dhcp-server6
sudo ufw status verbose
```

**Tiempo total:** ~10 minutos

**Resultado:**
- ✅ Servidor configurado con todos los servicios
- ✅ Red IPv6 funcionando
- ✅ DNS resolviendo nombres
- ✅ DHCP asignando IPs
- ✅ Firewall protegiendo el servidor
- ✅ NFS compartiendo directorios

---

### Escenario 2: Reconfigurar solo un servicio

```bash
# Ejemplo: Reconfigurar solo el firewall
./run.sh firewall

# O reconfigurar DNS
./run.sh dns
```

**Tiempo:** ~1-2 minutos por rol

---

### Escenario 3: Debugging paso a paso

```bash
# Usar el playbook interactivo
ansible-playbook site-interactive.yml --connection=local --become --ask-become-pass

# Pausará antes de cada paso
# Podrás verificar cada servicio antes de continuar
```

---

### Escenario 4: Crear VM inicial en ESXi

```bash
# 1. Desde tu PC (no desde el servidor)
source activate-ansible.sh

# 2. Editar variables de vCenter
vim group_vars/all.vault.yml

# 3. Crear VM
ansible-playbook create-vm-gamecenter.yml

# 4. Instalar Ubuntu en la VM desde vSphere

# 5. Dentro de la VM, ejecutar site.yml
./run.sh
```

---

## 📊 Resumen de Scripts

| Script | Propósito | Uso | Tiempo |
|--------|-----------|-----|--------|
| `activate-ansible.sh` | Activar entorno | `source activate-ansible.sh` | Instantáneo |
| `encrypt-vault.sh` | Encriptar contraseñas | `./encrypt-vault.sh` | Instantáneo |
| `run.sh` | Ejecutar todo o un rol | `./run.sh [rol]` | 5-10 min |
| `run-common.sh` | Solo rol common | `./run-common.sh` | 1-2 min |
| `run-network.sh` | Solo rol network | `./run-network.sh` | 30 seg |
| `run-dns.sh` | Solo rol DNS | `./run-dns.sh` | 1 min |
| `run-dhcp.sh` | Solo rol DHCP | `./run-dhcp.sh` | 30 seg |
| `run-firewall.sh` | Solo rol firewall | `./run-firewall.sh` | 1 min |
| `run-storage.sh` | Solo rol storage | `./run-storage.sh` | 1 min |

## 📊 Resumen de Playbooks

| Playbook | Propósito | Cuándo usarlo |
|----------|-----------|---------------|
| `site.yml` | Configuración completa | Primera instalación o reconfiguración total |
| `site-interactive.yml` | Configuración paso a paso | Aprendizaje, debugging, demostración |
| `create-vm-gamecenter.yml` | Crear VM en ESXi | Solo una vez, antes de instalar Ubuntu |
| `playbook-*.yml` | Roles individuales | Alternativa a `./run.sh [rol]` |

---

## 🎯 Recomendaciones

1. **Primera vez:** Usa `site-interactive.yml` para entender cada paso
2. **Producción:** Usa `./run.sh` para ejecución rápida
3. **Debugging:** Usa `./run.sh [rol]` para probar un servicio específico
4. **Seguridad:** Ejecuta `./encrypt-vault.sh` antes de subir a git
5. **Mantenimiento:** Usa `./run.sh [rol]` para actualizar servicios individuales

---

## ❓ Troubleshooting

### Error: "ansible-playbook: command not found"
```bash
source activate-ansible.sh
```

### Error: "Permission denied"
```bash
chmod +x run.sh
chmod +x run-*.sh
chmod +x *.sh
```

### Error: "Vault password incorrect"
```bash
# Verificar contenido de .vault_pass
cat .vault_pass

# Debe contener: ubuntu123
```

### Error: "Connection refused" al crear VM
```bash
# Verificar conexión a ESXi
ping 168.121.48.254

# Verificar credenciales en group_vars/all.vault.yml
```

---

**Última actualización:** 2024
**Versión:** 1.0
