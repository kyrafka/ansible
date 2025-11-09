# Rol: Common

Configuración base del sistema Ubuntu Server.

## ¿Qué hace?

- Instala paquetes esenciales (ufw, fail2ban, net-tools, curl, wget, vim, git)
- Crea directorios de logs del proyecto (/var/log/dns, /var/log/dhcp, etc.)
- Configura rsyslog para logging centralizado
- Configura logrotate para rotación automática de logs
- Crea script de monitoreo de logs (`/usr/local/bin/logs`)

## Variables importantes

```yaml
# En group_vars/all.yml
cron_time: "0 3 * * *"                    # Hora para tareas programadas
cron_restart_service: game_updater.service # Servicio a reiniciar (opcional)
```

## Tareas opcionales (se saltan si no están configuradas)

- **Crear usuarios personalizados:** Requiere variable `users` definida
- **Configurar cron jobs:** Requiere `cron_time` y servicio existente
- **ACLs avanzados:** Requiere colección `ansible.posix`

## Ejecutar solo este rol

```bash
ansible-playbook site.yml --connection=local --become --vault-password-file .vault_pass -e "ansible_become_password={{ vault_sudo_password }}" --tags common
```

O con el script:

```bash
./run.sh common
```

## Archivos creados

- `/var/log/dns/` - Logs de BIND9
- `/var/log/dhcp/` - Logs de DHCPv6
- `/var/log/security/` - Logs de seguridad
- `/var/log/ansible/` - Logs de Ansible
- `/usr/local/bin/logs` - Script de monitoreo
- `/etc/rsyslog.d/30-proyecto-ipv6.conf` - Configuración de rsyslog
- `/etc/logrotate.d/proyecto-ipv6` - Configuración de logrotate
