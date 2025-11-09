# Ubuntu Desktop con Roles

## 🎯 Flujo de trabajo

### 1. Crear VM Ubuntu Desktop
```bash
ansible-playbook playbooks/create-ubuntu-desktop.yml
```

Te pedirá:
- **Nombre de la VM**: Ejemplo: `ubuntu-admin`, `ubuntu-cliente01`
- **Rol**: `admin`, `auditor` o `cliente`

La VM se creará con recursos optimizados según el rol:
- **Admin**: 2 CPU, 4GB RAM, 80GB disco
- **Auditor**: 2 CPU, 3GB RAM, 40GB disco
- **Cliente**: 2 CPU, 4GB RAM, 60GB disco

### 2. Instalar Ubuntu Desktop
1. La VM arrancará con la ISO de Ubuntu Desktop
2. Instalar Ubuntu normalmente
3. Configurar red (obtendrá IPv6 por DHCP del servidor)
4. Habilitar SSH: `sudo apt install openssh-server`

### 3. Agregar al inventario
Editar `inventory/hosts.ini` y agregar en `[ubuntu_desktops]`:

```ini
ubuntu-admin ansible_host=2025:db8:10::10 ansible_user=admin vm_role=admin
ubuntu-cliente01 ansible_host=2025:db8:10::12 ansible_user=gamer01 vm_role=cliente
```

### 4. Configurar rol
```bash
ansible-playbook playbooks/configure-ubuntu-role.yml --limit ubuntu-admin
```

## 🔐 Roles y Privilegios

### Admin
- **Usuario**: `admin`
- **Password**: `admin123` (en vault)
- **Grupos**: sudo, adm, systemd-journal
- **Carpetas**: 
  - `/srv/admin` (privada)
  - `/srv/games` (compartida, puede instalar juegos)
  - `/srv/instaladores` (puede subir instaladores)
- **Firewall**: Permite SSH (22), HTTP (80), HTTPS (443)
- **Acceso servidor**: ✅ Puede hacer SSH al servidor
- **Permisos**: Acceso total, puede instalar software

### Auditor
- **Usuario**: `auditor`
- **Password**: `audit123` (en vault)
- **Grupos**: adm, systemd-journal
- **Carpetas**:
  - `/srv/audits` (privada)
  - `/var/log` (solo lectura)
- **Firewall**: Solo SSH (22)
- **Acceso servidor**: ❌ NO puede hacer SSH al servidor
- **Permisos**: Solo lectura, puede ver logs con sudo

### Cliente
- **Usuario**: `gamer01`
- **Password**: `gamer123` (en vault)
- **Grupos**: pcgamers
- **Carpetas**:
  - `/home/gamer01` (privada)
  - `/srv/games` (compartida, solo lectura)
  - `/srv/instaladores` (solo lectura)
- **Firewall**: Solo salida (DNS, HTTP, HTTPS, DHCP)
- **Acceso servidor**: ❌ NO puede hacer SSH al servidor
- **Permisos**: Sin sudo, solo usar juegos instalados

## 🌐 Red

Todas las VMs se conectan a `M_vm's` (switch interno) y obtienen IPv6 por DHCP:
- Red: `2025:db8:10::/64`
- Gateway: `2025:db8:10::1`
- Servidor: `2025:db8:10::2`
- VMs: `2025:db8:10::10+` (asignadas por DHCP)

## 🔥 Firewall del Servidor

El servidor filtra acceso según rol:
- **Admin**: Puede SSH al servidor
- **Auditor**: NO puede SSH
- **Cliente**: NO puede SSH
- **Todos**: Pueden usar DNS y DHCP

Para aplicar reglas:
```bash
ansible-playbook playbook-firewall.yml
```

## 📝 Ejemplo completo

```bash
# 1. Crear VM admin
ansible-playbook playbooks/create-ubuntu-desktop.yml
# Nombre: ubuntu-admin
# Rol: admin

# 2. Instalar Ubuntu Desktop en la VM

# 3. Agregar a inventario
nano inventory/hosts.ini
# ubuntu-admin ansible_host=2025:db8:10::10 ansible_user=admin vm_role=admin

# 4. Configurar rol
ansible-playbook playbooks/configure-ubuntu-role.yml --limit ubuntu-admin

# 5. Actualizar firewall del servidor
ansible-playbook playbook-firewall.yml

# 6. Probar SSH desde admin al servidor
ssh admin@2025:db8:10::10
ssh ubuntu@2025:db8:10::2  # Debería funcionar

# 7. Crear cliente
ansible-playbook playbooks/create-ubuntu-desktop.yml
# Nombre: ubuntu-cliente01
# Rol: cliente

# 8. Configurar cliente
ansible-playbook playbooks/configure-ubuntu-role.yml --limit ubuntu-cliente01

# 9. Probar que cliente NO puede SSH al servidor
ssh gamer01@2025:db8:10::12
ssh ubuntu@2025:db8:10::2  # Debería ser bloqueado
```

## 🎮 Compartir juegos

El admin instala juegos en `/srv/games`:
```bash
# Desde VM admin
sudo cp -r /home/admin/juego /srv/games/
sudo chown -R root:pcgamers /srv/games/juego
sudo chmod -R 775 /srv/games/juego
```

Los clientes pueden acceder:
```bash
# Desde VM cliente
ls /srv/games/
./srv/games/juego/ejecutar.sh
```

## 🔑 Contraseñas

Todas las contraseñas están en `group_vars/all.vault.yml`:
```yaml
vault_ubuntu_desktop_admin_password: "admin123"
vault_ubuntu_desktop_auditor_password: "audit123"
vault_ubuntu_desktop_cliente_password: "gamer123"
```

Para encriptar:
```bash
ansible-vault encrypt group_vars/all.vault.yml
```
