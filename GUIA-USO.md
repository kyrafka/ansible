# ════════════════════════════════════════════════════════════════
# GUÍA DE USO - Ansible Gestión y Despliegue GameCenter
# ════════════════════════════════════════════════════════════════

# ────────────────────────────────────────────────────────────────
# 1. CONFIGURACIÓN INICIAL (Solo primera vez)
# ────────────────────────────────────────────────────────────────

# Encriptar credenciales (opcional):
bash scripts/encrypt-vault.sh

# Instalar Ansible:
bash scripts/setup/setup-ansible-env.sh --auto    # Automático


# ────────────────────────────────────────────────────────────────
# 2. CONFIGURACIÓN DEL SERVIDOR (Desde el servidor Ubuntu)
# ────────────────────────────────────────────────────────────────

# Opción 1: Configuración completa
bash scripts/server/setup-server.sh

# Opción 2: Por componentes (recomendado)
bash scripts/run/run-common.sh      # Paquetes base
bash scripts/run/run-network.sh     # Red IPv6 + NAT
bash scripts/run/run-dns.sh         # BIND9 DNS + DNS64
bash scripts/run/run-dhcp.sh        # DHCPv6 + DDNS
bash scripts/run/run-firewall.sh    # UFW
bash scripts/run/run-storage.sh     # NFS

# ⚠️ NUEVO: Configurar NAT64 + Squid Proxy
sudo bash scripts/nat64/install-nat64-tayga.sh    # NAT64 (Tayga)
sudo bash scripts/install-squid-proxy.sh          # Proxy HTTP
sudo bash scripts/configure-dns64-simple.sh       # DNS64 en BIND9

# ────────────────────────────────────────────────────────────────
# 3. CREAR VMs (Desde el servidor o WSL)
# ────────────────────────────────────────────────────────────────

# Crear VM Ubuntu Desktop:
cd ~/ansible
bash scripts/vms/crear-vm.sh

# Durante instalación de Ubuntu Desktop:
# - Nombre: Administrador
# - Hostname: ubuntu123 (o el que prefieras)
# - Usuario: administrador
# - Contraseña: 123
# - Red: IPv6 Automatic (DHCP) en adaptador M_vm's

# ────────────────────────────────────────────────────────────────
# 4. CONFIGURAR UBUNTU DESKTOP (Primera vez - Manual)
# ────────────────────────────────────────────────────────────────

# ⚠️ IMPORTANTE: La VM necesita internet temporal para configurarse

# Opción A: Agregar adaptador de red temporal (VM Network)
# 1. En vSphere, agrega un segundo adaptador de red (VM Network)
# 2. Enciende la VM
# 3. Instala paquetes necesarios:
sudo apt update
sudo apt install -y git openssh-server

# 4. Clona el repositorio:
cd ~
git clone <https://github.com/kyrafka/ansible.git> ansible

# 5. Ejecuta el script de bootstrap:
cd ~/ansible
sudo bash scripts/vm-setup-complete.sh

# 6. Apaga la VM y quita el adaptador temporal
# 7. Enciende la VM (ahora funciona solo con IPv6 + NAT64)

# Opción B: Configurar desde el servidor (requiere SSH)
# 1. Obtener IP de la VM:
#    En la VM: ip -6 addr show ens33 | grep "scope global"
# 2. Agregar al inventario (inventory/hosts.ini):
[ubuntu_desktops]
ubuntu123 ansible_host=2025:db8:10::dce9 ansible_user=administrador ansible_password=123 ansible_become_password=123

# 3. Ejecutar configuración:
bash scripts/vms/configure-ubuntu-desktop-interactive.sh

# ────────────────────────────────────────────────────────────────
# 5. PERSONALIZAR UBUNTU DESKTOP (Dentro de la VM)
# ────────────────────────────────────────────────────────────────

# Ejecutar script de configuración local:
cd ~/ansible
bash scripts/vm-local-setup.sh

# Mejorar apariencia visual:
bash scripts/beautify-ubuntu-desktop.sh

# Arreglar icono de red:
gsettings set org.gnome.nm-applet disable-connected-notifications true
sudo systemctl restart NetworkManager

# Configurar solo 3 roles (eliminar admin duplicado):
sudo bash scripts/fix-3-roles-only.sh

# ────────────────────────────────────────────────────────────────
# 6. USUARIOS Y ROLES EN UBUNTU DESKTOP
# ────────────────────────────────────────────────────────────────

# Usuarios configurados:
# 1. administrador - Admin completo (sudo, SSH, escritura en /srv/games)
#    Contraseña: 123
#
# 2. auditor - Solo lectura (logs, /srv/audits, lectura en /srv/games)
#    Contraseña: 123456
#
# 3. gamer01 - Cliente/Gamer (sin sudo, sin SSH, lectura en /srv/games)
#    Contraseña: 123456

# Probar roles:
sudo bash scripts/test-user-roles.sh

# Estructura de carpetas:
# /srv/admin        → Privada de administrador
# /srv/audits       → Privada de auditor
# /srv/games        → Compartida (grupo pcgamers)
# /mnt/games        → Montaje NFS (juegos del servidor)

# ────────────────────────────────────────────────────────────────
# 7. CONFIGURAR NFS (Juegos Compartidos)
# ────────────────────────────────────────────────────────────────

# En el SERVIDOR:
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/nfs/games
sudo chmod 777 /srv/nfs/games
echo '/srv/nfs/games 2025:db8:10::/64(rw,sync,no_subtree_check)' | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server

# En la VM Ubuntu Desktop:
sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games

# Para montaje automático, agregar a /etc/fstab:
[2025:db8:10::2]:/srv/nfs/games /mnt/games nfs defaults,_netdev 0 0

# ────────────────────────────────────────────────────────────────
# 8. INSTALAR SERVIDOR DE MINECRAFT (Para pruebas LAN)
# ────────────────────────────────────────────────────────────────

# En Ubuntu Desktop:
cd ~/ansible
sudo bash scripts/install-minecraft-server.sh

# Comandos útiles:
sudo systemctl status minecraft          # Ver estado
sudo systemctl restart minecraft         # Reiniciar
sudo journalctl -fu minecraft           # Ver logs
sudo screen -r minecraft                # Consola (Ctrl+A, D para salir)

# Conectarse desde otro PC:
# Minecraft Java → Multijugador → Servidor Directo
# Dirección: [2025:db8:10::dce9]:25565

# ────────────────────────────────────────────────────────────────
# 9. VALIDACIONES Y DIAGNÓSTICO
# ────────────────────────────────────────────────────────────────

# Validar servidor:
bash scripts/run/validate-all.sh

# Validar componentes individuales:
bash scripts/run/validate-network.sh
bash scripts/run/validate-dns.sh
bash scripts/run/validate-dhcp.sh

# Probar conectividad desde VM:
ping6 google.com                        # Internet (NAT64)
dig ubuntu123.gamecenter.lan AAAA       # DNS local
ping6 2025:db8:10::2                    # Servidor
ssh ubuntu@2025:db8:10::2               # SSH al servidor

# Ver configuraciones de GNOME:
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface enable-animations

# ────────────────────────────────────────────────────────────────
# 10. ARQUITECTURA DE RED
# ────────────────────────────────────────────────────────────────

# Flujo de red:
# Internet (IPv4) → ens33 servidor → NAT64 (Tayga) → ens34 servidor (IPv6)
#                                                   ↓
#                                          Switch M_vm's (IPv6)
#                                                   ↓
#                                          VMs Ubuntu Desktop (IPv6)

# Componentes:
# - BIND9: DNS + DNS64 (traduce nombres IPv4 a IPv6)
# - Tayga: NAT64 (traduce paquetes IPv6 → IPv4)
# - Squid: Proxy HTTP (para apt y navegadores)
# - DHCPv6: Asigna IPs automáticamente
# - DDNS: Registra VMs en DNS automáticamente

# Prefijos:
# - Red interna: 2025:db8:10::/64
# - NAT64: 64:ff9b::/96
# - Servidor: 2025:db8:10::2
# - Gateway: 2025:db8:10::1
# - DHCP range: 2025:db8:10::10 - 2025:db8:10::FFFF

# ────────────────────────────────────────────────────────────────
# 11. COMANDOS ÚTILES
# ────────────────────────────────────────────────────────────────

# Ver IPs IPv6:
ip -6 addr show

# Ver rutas IPv6:
ip -6 route

# Ver estado de servicios:
sudo systemctl status named              # DNS
sudo systemctl status isc-dhcp-server6   # DHCP
sudo systemctl status tayga              # NAT64
sudo systemctl status squid              # Proxy
sudo systemctl status nfs-kernel-server  # NFS

# Ver logs:
sudo journalctl -fu named
sudo journalctl -fu isc-dhcp-server6
sudo journalctl -fu tayga

# Probar DNS64:
dig @localhost google.com AAAA           # Debe mostrar 64:ff9b::...

# Probar NAT64:
ping6 64:ff9b::808:808                   # Ping a 8.8.8.8 vía NAT64

# Ver reglas de firewall:
sudo ufw status verbose
sudo ip6tables -t nat -L -v -n

# ────────────────────────────────────────────────────────────────
# 12. TROUBLESHOOTING
# ────────────────────────────────────────────────────────────────

# VM sin internet:
# 1. Verificar NAT64: ping6 64:ff9b::808:808
# 2. Verificar DNS64: dig google.com AAAA
# 3. Verificar proxy: echo $http_proxy
# 4. Reinstalar NAT64: sudo bash scripts/nat64/install-nat64-tayga.sh

# DNS no resuelve:
# 1. Verificar BIND9: sudo systemctl status named
# 2. Ver logs: sudo journalctl -xeu named
# 3. Probar: dig @2025:db8:10::2 ubuntu123.gamecenter.lan AAAA
# 4. Recargar: sudo bash scripts/dns-clean-and-reload.sh

# DHCP no asigna IPs:
# 1. Ver logs: sudo journalctl -xeu isc-dhcp-server6
# 2. Verificar interfaz: ip -6 addr show ens34
# 3. Reiniciar: sudo systemctl restart isc-dhcp-server6

# NFS no monta:
# 1. Verificar servidor: sudo systemctl status nfs-kernel-server
# 2. Ver exports: sudo exportfs -v
# 3. Probar montaje: sudo mount -t nfs [2025:db8:10::2]:/srv/nfs/games /mnt/games

# Roles no funcionan:
# 1. Ejecutar: sudo bash scripts/fix-3-roles-only.sh
# 2. Verificar: sudo bash scripts/test-user-roles.sh
# 3. Cerrar sesión y volver a entrar

# ────────────────────────────────────────────────────────────────
# 13. SCRIPTS IMPORTANTES
# ────────────────────────────────────────────────────────────────

# Servidor:
scripts/nat64/install-nat64-tayga.sh           # Instalar NAT64
scripts/install-squid-proxy.sh                 # Instalar proxy
scripts/configure-dns64-simple.sh              # Configurar DNS64
scripts/dns-clean-and-reload.sh                # Limpiar DNS

# VMs:
scripts/vms/crear-vm.sh                        # Crear VM
scripts/vms/configure-ubuntu-desktop-interactive.sh  # Configurar VM
scripts/vm-setup-complete.sh                   # Bootstrap inicial
scripts/vm-local-setup.sh                      # Configuración local
scripts/beautify-ubuntu-desktop.sh             # Mejorar apariencia
scripts/fix-3-roles-only.sh                    # Arreglar roles
scripts/test-user-roles.sh                     # Probar roles
scripts/install-minecraft-server.sh            # Servidor Minecraft

# ════════════════════════════════════════════════════════════════
# FIN DE LA GUÍA
# ════════════════════════════════════════════════════════════════
