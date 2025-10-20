# memato2 - Despliegue y Gestión de Servicios

Este proyecto está pensado para:

- Desplegar y configurar componentes en distintos entornos:
  - Ubuntu (común y DHCP)
  - ESXi (VMware)
  - VirtualBox
  - Windows (post-configuración)
- Gestionar procesos y servicios críticos en hosts Linux, con verificación, aseguramiento y resumen de diagnóstico.

## Estructura

- `site.yml`: orquesta los roles por grupo de hosts.
- `inventory/hosts.ini`: inventario de hosts y grupos.
- `group_vars/all.yml`: variables globales (usuarios, DHCP, VMware, VirtualBox, WinRM, servicios necesarios, etc.).
- `roles/`:
  - `common`: gestión de usuarios, directorios y cron.
  - `dhcp`: instalación y configuración de `isc-dhcp-server`.
  - `vmware`: tareas de ESXi/VMware.
  - `virtualbox`: tareas de VirtualBox.
  - `windows`: post-configuración de VMs Windows.
  - `procesos`: gestión de procesos y servicios necesarios en Linux.
- `collections/requirements.yml`: colecciones requeridas.
- `ansible.cfg`: configuración de Ansible (inventario, rutas, escalado de privilegios, etc.).

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
- Los plays de `esxi_host`, `vbox_host` y `windows_vms` ejecutan sus roles respectivos.

## Notas

- Ajusta `ansible_user`, autenticación (clave/contraseña), y WinRM según tu entorno.
- Si no deseas gestionar algún servicio, elimínalo de `servicios_necesarios`.
