# Rol: Storage

Configuración de almacenamiento, NFS y monitoreo de discos.

## ¿Qué hace?

- Instala servidor NFS
- Crea directorios compartidos
- Configura exportaciones NFS
- Monitorea uso de disco
- Alerta sobre particiones llenas

## Directorios compartidos

```yaml
# En group_vars/all.yml
nfs_exports:
  - path: "/srv/nfs/games"
    clients: "2025:db8:10::/64"
    options: "rw,sync,no_subtree_check,no_root_squash"
  
  - path: "/srv/nfs/shared"
    clients: "2025:db8:10::/64"
    options: "rw,sync,no_subtree_check"
```

## Estructura de directorios

```
/srv/nfs/
├── games/          # Juegos compartidos (lectura/escritura)
├── shared/         # Archivos compartidos
└── backups/        # Backups (solo lectura)
```

## Monitoreo de disco

Monitorea automáticamente:
- `/var/log` - Logs del sistema
- `/var` - Datos variables
- `/tmp` - Archivos temporales
- `/home` - Directorios de usuarios
- `/boot` - Kernel y bootloader
- `/etc` - Configuración del sistema

### Umbrales de alerta

```yaml
storage:
  disk_usage_warning: 80%      # Advertencia
  disk_usage_critical: 90%     # Crítico
  inode_usage_warning: 85%     # Advertencia inodos
  inode_usage_critical: 95%    # Crítico inodos
```

## Ejecutar solo este rol

```bash
./run.sh storage
```

## Verificar funcionamiento

```bash
# Ver exportaciones NFS
showmount -e localhost

# Ver estado del servicio
systemctl status nfs-server

# Ver uso de disco
df -h

# Ver uso de inodos
df -i

# Monitoreo completo
sudo /usr/local/bin/storage-monitor
```

## Montar NFS desde una VM

```bash
# En la VM cliente
sudo apt install nfs-common

# Crear punto de montaje
sudo mkdir -p /mnt/games

# Montar
sudo mount -t nfs -o vers=4 [2025:db8:10::2]:/srv/nfs/games /mnt/games

# Montar permanente (agregar a /etc/fstab)
echo "[2025:db8:10::2]:/srv/nfs/games /mnt/games nfs4 defaults 0 0" | sudo tee -a /etc/fstab
```

## Archivos creados

- `/etc/exports` - Configuración de NFS
- `/srv/nfs/games/` - Directorio de juegos
- `/srv/nfs/shared/` - Directorio compartido
- `/srv/nfs/backups/` - Directorio de backups
- `/usr/local/bin/storage-monitor` - Script de monitoreo

## Puertos abiertos

- **2049/tcp** - NFS
- **111/tcp** - Portmapper
- **20048/tcp** - Mountd

## Retención de logs

```yaml
journald_retention_days: 30      # Logs del sistema
syslog_retention_days: 14        # Syslog
dhcp_log_retention_days: 7       # Logs DHCP
dns_log_retention_days: 14       # Logs DNS
security_log_retention_days: 30  # Logs de seguridad
```

## Troubleshooting

```bash
# Ver logs de NFS
journalctl -u nfs-server -n 50

# Verificar permisos
ls -la /srv/nfs/

# Recargar exportaciones
sudo exportfs -ra

# Ver clientes conectados
sudo nfsstat -c
```
