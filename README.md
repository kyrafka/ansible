# memato2 - Despliegue y Gestión de Servicios

Este proyecto está pensado para:

- Desplegar y configurar componentes en distintos entornos:
  - Ubuntu (común y DHCP)
  - VirtualBox
  - Windows (post-configuración)
- Gestionar procesos y servicios críticos en hosts Linux, con verificación, aseguramiento y resumen de diagnóstico.

## Estructura

- `site.yml`: orquesta los roles por grupo de hosts.
- `inventory/hosts.ini`: inventario de hosts y grupos.
- `group_vars/all.yml`: variables globales (usuarios, DHCP, VirtualBox, WinRM, servicios necesarios, etc.).
- `roles/`:
  - `common`: gestión de usuarios, directorios y cron.
  - `dhcp`: instalación y configuración de `isc-dhcp-server`.
  - `dhcp`: instalación y configuración de `isc-dhcp-server` (IPv4/IPv6).
  - `virtualbox`: tareas de VirtualBox.
  - `windows`: post-configuración de VMs Windows.
  - `procesos`: gestión de procesos y servicios necesarios en Linux.
- `collections/requirements.yml`: colecciones requeridas.
- `ansible.cfg`: configuración de Ansible (inventario, rutas, escalado de privilegios, etc.).

## Mapa de entorno e IPs

- **Inventario (`inventory/hosts.ini`)**
  - `ubuntu_server`: ubuntu1 → `fd10:10::10` (ansible_user=`salamaleca`)
  - `vmware_host`: vcenter1 → `168.121.48.254` (ansible_user=`root`, ansible_password=`qwe123$`)
  - `windows_vms`: winvm1 → `[IP_asignada_por_DHCP]`. Vars del grupo:
    - `ansible_connection=winrm`
    - `ansible_winrm_transport=ntlm`
    - `ansible_winrm_server_cert_validation=ignore`
  - `all:vars`: `ansible_python_interpreter=/usr/bin/python3`

- **Variables globales (`group_vars/all.yml`)**
  - `dhcp`:
    - IPv4 Subred `192.168.10.0/24`: rango `192.168.10.10-192.168.10.200`, router `192.168.10.1`
    - IPv4 Subred `192.168.30.0/24`: rango `192.168.30.10-192.168.30.200`, router `192.168.30.1`
    - DNS: `[8.8.8.8, 1.1.1.1]`, `domain_name=localdomain`, lease por defecto `600`, máximo `7200`
  - `winrm`:
    - `win_admin_user`: `gamepc1`
    - `win_admin_password`: `123456`
  - `vmware`:
    - `vcenter_hostname=168.121.48.254`, `vm_name=Win11-GamePC`, `guest_id=windows9_64Guest`
    - `memory=4096`, `cpus=2`, `disk_size_mb=65536`, `datastore=datastore1`
    - `iso_path=ubuntu-24.04.3-desktop-amd64.iso`, `network_name=VM Network`

- **Plays activos (`site.yml`)**
  - `ubuntu_server`: roles `common`, `dhcp`, `radvd`, `procesos`, `storage` (con `become: true`)
  - `vmware_host`: rol `vmware` (crea VM y configura Windows automáticamente)
  - `windows_vms`: rol `windows` (configuración adicional post-instalación)

## DHCPv6 (plan y parámetros)

- **Subredes IPv6 previstas**
  - `fd10:10::/64` (red 10)
  - `fd30:30::/64` (red 30)

- **Ejemplo de parámetros (se pueden añadir a `group_vars/all.yml` como `dhcp_v6`)**

```yaml
dhcp_v6:
  interfaces:
    - enp0s3
  subnets:
    - network: fd10:10::/64
      range_start: fd10:10::100
      range_end: fd10:10::1fff
      routers: fd10:10::1
    - network: fd30:30::/64
      range_start: fd30:30::100
      range_end: fd30:30::1fff
      routers: fd30:30::1
```

- **Nota**: si el rol `dhcp` aún gestiona solo IPv4, habrá que extenderlo para leer `dhcp_v6` y generar la configuración de `dhcpd6` (o unificar en `dhcpd` si corresponde según la distro). Puedo implementarlo si lo indicas.

## Gestión de procesos y servicios (rol `procesos`)

El rol `roles/procesos` realiza:

- Recolección de `service_facts`.
- Lectura de `uptime`, Top 5 por CPU y por MEM.
- Listado del estado de servicios necesarios definidos en `servicios_necesarios`.
- Asegura que dichos servicios estén `started` y `enabled`.
- Reintenta servicios fallidos detectados por `systemctl --failed`.
- Emite un resumen legible con uptime y tops.

Variable requerida (en `group_vars/all.yml` o específicas de grupo/host):

```yaml
servicios_necesarios:
  - ssh
  - cron
  - NetworkManager
```

## Ejecución

1. Instalar colecciones (opcional según módulos usados):

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

2. Revisar/ajustar `inventory/hosts.ini` y credenciales.

3. Ejecutar el playbook principal:

```bash
ansible-playbook -i inventory/hosts.ini site.yml
```

- El play `ubuntu_server` ejecuta `common`, `dhcp` y `procesos`.
- Los plays de `vbox_host` y `windows_vms` ejecutan sus roles respectivos.

## Notas

- Ajusta `ansible_user`, autenticación (clave/contraseña), y WinRM según tu entorno.
- Si no deseas gestionar algún servicio, elimínalo de `servicios_necesarios`.

## Seguridad: uso de Ansible Vault

- Secretos en `group_vars/all.vault.yml` (cifrado), referenciados desde `group_vars/all.yml` (por ejemplo `win_admin_password: {{ vault_win_admin_password }}`).
- Crear/editar cifrado:
  ```bash
  ansible-vault create group_vars/all.vault.yml
  # o para editar
  ansible-vault edit group_vars/all.vault.yml
  # si ya existe en claro
  ansible-vault encrypt group_vars/all.vault.yml
  ```
- Ejecutar playbooks con vault:
  ```bash
  ansible-playbook -i inventory/hosts.ini site.yml --ask-vault-pass
  ```

## RDP: variable y tags

- Estado base controlado por `enable_rdp` en `group_vars/all.yml`.
- Tareas RDP etiquetadas con `tags: [rdp]` en `roles/windows/tasks/main.yml`.
- Ejecutar solo RDP cuando lo necesites:
  ```bash
  ansible-playbook -i inventory/hosts.ini site.yml --tags rdp --limit windows_vms
  ```

## Mantenimiento Windows programado

- Variables en `group_vars/all.yml` bajo `windows_maintenance` controlan tareas programadas (updates, cleanup, antivirus, reboot).
- Crear/actualizar tareas:
  ```bash
  ansible-playbook -i inventory/hosts.ini site.yml --limit windows_vms --tags windows_maintenance
  ```

## Monitoreo y almacenamiento (rol `storage`)

- Reporte generado en `/var/tmp/ansible_storage_report.txt` con uso de disco/inodos y tamaños de rutas monitoreadas.
- Ajustes en `group_vars/all.yml` bajo `storage` (umbrales y retención).
  - Limpieza de journal: `journalctl --vacuum-time=<dias>` gestionado por el rol.
