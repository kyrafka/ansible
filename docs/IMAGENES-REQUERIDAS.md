# 📸 Imágenes Requeridas para la Documentación

## Estructura de Carpetas

```
docs/images/
├── topologia/
├── configuracion/
├── servicios/
├── pruebas/
└── monitoreo/
```

---

## 📁 Topología (docs/images/topologia/)

1. **topologia-general.png** - Diagrama completo de la red
2. **servidor-gaming-1.png** - Esquema del Servidor Gaming 1 (Ubuntu + VMs)
3. **servidor-gaming-2.png** - Esquema del Servidor Gaming 2 (Debian + VMs)
4. **red-ipv6.png** - Diagrama de direccionamiento IPv6
5. **vmware-esxi.png** - Captura de VMware ESXi con las VMs

---

## ⚙️ Configuración (docs/images/configuracion/)

1. **ansible-estructura.png** - Estructura de carpetas del proyecto Ansible
2. **inventario-hosts.png** - Archivo de inventario configurado
3. **variables-configuracion.png** - Variables principales (group_vars)
4. **netplan-servidor.png** - Configuración de red del servidor
5. **interfaces-red.png** - Interfaces de red configuradas (ip addr show)

---

## 🔧 Servicios (docs/images/servicios/)

1. **bind9-configuracion.png** - Archivo de configuración de BIND9
2. **bind9-zona-directa.png** - Archivo de zona directa (db.gamecenter.local)
3. **dhcpv6-configuracion.png** - Configuración de DHCPv6
4. **nginx-configuracion.png** - Configuración de Nginx
5. **nginx-pagina-web.png** - Página web funcionando en navegador
6. **firewall-reglas.png** - Reglas de UFW (sudo ufw status verbose)
7. **fail2ban-jails.png** - Jails de fail2ban configurados
8. **servicios-activos.png** - Lista de servicios activos (systemctl list-units)

---

## 🧪 Pruebas (docs/images/pruebas/)

1. **ping-ipv6.png** - Prueba de ping6 entre servidor y cliente
2. **dns-resolucion.png** - Prueba de resolución DNS (dig/nslookup)
3. **dhcp-asignacion.png** - IP asignada por DHCPv6 en cliente
4. **web-acceso-nombre.png** - Acceso a http://gamecenter.local desde navegador
5. **web-acceso-www.png** - Acceso a http://www.gamecenter.local
6. **ssh-conexion.png** - Conexión SSH al servidor
7. **validacion-network.png** - Salida de validate-network.sh
8. **validacion-dns.png** - Salida de validate-dns.sh
9. **validacion-web.png** - Salida de validate-web.sh
10. **diagnostico-dns.png** - Salida de diagnose-dns.sh

---

## 📊 Monitoreo (docs/images/monitoreo/)

1. **top-servidor.png** - Monitoreo de recursos con top/htop
2. **logs-sistema.png** - Logs del sistema (journalctl)
3. **uso-disco.png** - Uso de disco (df -h)
4. **puertos-abiertos.png** - Puertos abiertos (ss -tulnp)
5. **procesos-activos.png** - Procesos activos (ps aux)

---

## 📝 Notas

- **Formato recomendado:** PNG o JPG
- **Resolución mínima:** 1280x720
- **Nombrar archivos:** Usar los nombres exactos listados arriba
- **Capturas de terminal:** Asegurarse de que el texto sea legible
- **Capturas de navegador:** Incluir la barra de direcciones

---

## ✅ Checklist

- [ ] Topología (5 imágenes)
- [ ] Configuración (5 imágenes)
- [ ] Servicios (8 imágenes)
- [ ] Pruebas (10 imágenes)
- [ ] Monitoreo (5 imágenes)

**Total:** 33 imágenes
