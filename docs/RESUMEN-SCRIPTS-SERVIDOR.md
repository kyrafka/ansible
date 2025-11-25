# 📋 RESUMEN: SCRIPTS PARA DEMOSTRAR EL SERVIDOR

## Guía rápida de uso

---

## 🎯 OBJETIVO

Demostrar que TODOS los servicios del servidor funcionan correctamente para la rúbrica.

---

## 📦 SCRIPTS DISPONIBLES

### 1. **show-server-config.sh** - Mostrar Configuraciones

**Ubicación:** `scripts/diagnostics/show-server-config.sh`

**Qué hace:**
- Muestra TODAS las configuraciones del servidor
- Archivos de configuración de cada servicio
- Estado de servicios
- Usuarios y permisos
- Logs recientes

**Cómo ejecutar:**
```bash
cd ~/ansible-gestion-despliegue
bash scripts/diagnostics/show-server-config.sh
```

**Duración:** ~5 minutos (con pausas)

**Secciones que muestra:**
1. ✅ Información del sistema
2. ✅ Configuración de red IPv6
3. ✅ Servidor DNS (BIND9)
4. ✅ Servidor DHCP IPv6
5. ✅ Servidor Web (Nginx)
6. ✅ Firewall (UFW)
7. ✅ fail2ban
8. ✅ SSH
9. ✅ NFS
10. ✅ Usuarios del servidor
11. ✅ Resumen de servicios
12. ✅ Logs recientes

---

### 2. **test-server-functionality.sh** - Probar Funcionamiento

**Ubicación:** `scripts/diagnostics/test-server-functionality.sh`

**Qué hace:**
- Prueba que cada servicio FUNCIONA
- Verifica conectividad
- Prueba DNS, DHCP, Web, SSH
- Genera reporte de éxito/fallo
- Calcula porcentaje de éxito

**Cómo ejecutar:**
```bash
bash scripts/diagnostics/test-server-functionality.sh
```

**Duración:** ~3 minutos

**Pruebas que realiza:**
1. ✅ Red IPv6 (3 pruebas)
2. ✅ DNS (6 pruebas)
3. ✅ DHCP (4 pruebas)
4. ✅ Servidor Web (4 pruebas)
5. ✅ Firewall (4 pruebas)
6. ✅ fail2ban (2 pruebas)
7. ✅ SSH (3 pruebas)
8. ✅ NFS (2 pruebas)
9. ✅ Usuarios (4 pruebas)
10. ✅ Conectividad (2 pruebas)

**Total:** ~34 pruebas automáticas

---

## 🚀 FLUJO DE TRABAJO RECOMENDADO

### Paso 1: Mostrar Configuraciones (5 min)

```bash
bash scripts/diagnostics/show-server-config.sh
```

**Qué hacer:**
- Ejecutar el script
- Ir presionando ENTER en cada pausa
- Tomar capturas de las secciones importantes
- Mostrar archivos de configuración

**Capturas necesarias:**
- Estado de cada servicio
- Configuraciones de DNS, DHCP, Nginx
- Reglas de firewall
- Usuarios y permisos

---

### Paso 2: Probar Funcionamiento (3 min)

```bash
bash scripts/diagnostics/test-server-functionality.sh
```

**Qué hacer:**
- Ejecutar el script
- Ver resultados de cada prueba
- Tomar captura del resumen final
- Mostrar porcentaje de éxito

**Capturas necesarias:**
- Pruebas de DNS funcionando
- Pruebas de Web funcionando
- Resumen final con porcentaje

---

### Paso 3: Demostraciones Manuales (7 min)

Ver: `docs/DEMOSTRACION-MANUAL-SERVIDOR.md`

**Demostraciones clave:**

1. **DNS en tiempo real** (1 min)
   ```bash
   # Terminal 1
   sudo journalctl -u bind9 -f
   
   # Terminal 2
   dig @localhost gamecenter.lan AAAA
   ```

2. **Web desde navegador** (1 min)
   - Abrir navegador
   - Ir a: `http://gamecenter.lan`
   - Mostrar página funcionando

3. **DHCP asignando IPs** (1 min)
   ```bash
   sudo cat /var/lib/dhcp/dhcpd6.leases
   ```

4. **Firewall protegiendo** (1 min)
   ```bash
   sudo ufw status verbose
   ```

5. **SSH con permisos por rol** (2 min)
   ```bash
   # Como admin (funciona)
   ssh ubuntu@2025:db8:10::2
   
   # Como auditor (bloqueado)
   ssh ubuntu@2025:db8:10::2
   ```

6. **fail2ban activo** (1 min)
   ```bash
   sudo fail2ban-client status sshd
   ```

---

## 📸 CAPTURAS OBLIGATORIAS

### Del Script 1 (show-server-config.sh):

1. ✅ Información del sistema
2. ✅ Interfaces IPv6
3. ✅ Estado de BIND9
4. ✅ Zona DNS
5. ✅ Estado de DHCP
6. ✅ Configuración DHCP
7. ✅ Estado de Nginx
8. ✅ Configuración Nginx
9. ✅ Reglas de firewall
10. ✅ Estado de fail2ban
11. ✅ Configuración SSH
12. ✅ Usuarios y grupos
13. ✅ Resumen de servicios

### Del Script 2 (test-server-functionality.sh):

1. ✅ Pruebas de red
2. ✅ Pruebas de DNS
3. ✅ Pruebas de DHCP
4. ✅ Pruebas de Web
5. ✅ Pruebas de Firewall
6. ✅ Pruebas de SSH
7. ✅ Resumen final con porcentaje

### Demostraciones Manuales:

1. ✅ DNS resolviendo en tiempo real
2. ✅ Navegador mostrando página web
3. ✅ DHCP con leases asignados
4. ✅ SSH funcionando para admin
5. ✅ SSH bloqueado para auditor/cliente

**Total:** ~25 capturas

---

## 🎯 PARA LA RÚBRICA

### Criterio: Configuración de red y servicios (Nivel 4)

**Evidencias que proporcionan los scripts:**

1. ✅ **Servicios configurados:**
   - DNS (BIND9) ✅
   - DHCP IPv6 ✅
   - Servidor Web (Nginx) ✅
   - Firewall (UFW) ✅
   - fail2ban ✅
   - SSH ✅

2. ✅ **Servicios funcionando:**
   - Pruebas automáticas de cada servicio
   - Porcentaje de éxito
   - Logs en tiempo real

3. ✅ **Configuraciones documentadas:**
   - Archivos de configuración mostrados
   - Parámetros importantes resaltados
   - Explicación de cada servicio

4. ✅ **Evidencia visual:**
   - Capturas de pantalla
   - Logs de funcionamiento
   - Pruebas exitosas

---

## ⚡ COMANDOS RÁPIDOS

### Ejecutar ambos scripts seguidos:

```bash
cd ~/ansible-gestion-despliegue

# Mostrar configuraciones
bash scripts/diagnostics/show-server-config.sh

# Probar funcionamiento
bash scripts/diagnostics/test-server-functionality.sh
```

### Ver solo un servicio específico:

```bash
# DNS
sudo systemctl status bind9
dig @localhost gamecenter.lan AAAA

# DHCP
sudo systemctl status isc-dhcp-server6
sudo cat /var/lib/dhcp/dhcpd6.leases

# Web
sudo systemctl status nginx
curl http://gamecenter.lan

# Firewall
sudo ufw status verbose

# SSH
sudo systemctl status ssh
```

---

## 🔧 TROUBLESHOOTING

### Si un script falla:

1. **Verificar permisos:**
   ```bash
   chmod +x scripts/diagnostics/*.sh
   ```

2. **Ejecutar con bash explícitamente:**
   ```bash
   bash scripts/diagnostics/show-server-config.sh
   ```

3. **Ver errores:**
   ```bash
   bash -x scripts/diagnostics/show-server-config.sh
   ```

### Si un servicio no funciona:

1. **Reiniciar el servicio:**
   ```bash
   sudo systemctl restart bind9
   sudo systemctl restart isc-dhcp-server6
   sudo systemctl restart nginx
   ```

2. **Ver logs de error:**
   ```bash
   sudo journalctl -u bind9 -n 50
   sudo journalctl -u isc-dhcp-server6 -n 50
   sudo journalctl -u nginx -n 50
   ```

3. **Verificar configuración:**
   ```bash
   sudo named-checkconf
   sudo nginx -t
   ```

---

## 📊 RESULTADO ESPERADO

### Script 1 (show-server-config.sh):

```
✅ CONFIGURACIONES MOSTRADAS EXITOSAMENTE

Configuraciones mostradas:
  1. ✅ Información del sistema
  2. ✅ Red IPv6
  3. ✅ DNS (BIND9)
  4. ✅ DHCP IPv6
  5. ✅ Servidor Web (Nginx)
  6. ✅ Firewall (UFW)
  7. ✅ fail2ban
  8. ✅ SSH
  9. ✅ NFS
 10. ✅ Usuarios y permisos
 11. ✅ Resumen de servicios
 12. ✅ Logs recientes
```

### Script 2 (test-server-functionality.sh):

```
📊 RESUMEN DE PRUEBAS

Resultados:
  Pruebas exitosas: 32 / 34

✅ EXCELENTE - Todos los servicios funcionan correctamente
   Nivel alcanzado: NIVEL 4
```

---

## ✅ CHECKLIST FINAL

Antes de la demostración:

- [ ] Scripts ejecutados sin errores
- [ ] Todos los servicios activos
- [ ] Capturas tomadas
- [ ] Porcentaje de éxito > 90%
- [ ] Demostraciones manuales preparadas
- [ ] Navegador listo para mostrar web
- [ ] Cliente conectado para pruebas

---

## 🎓 TIPS FINALES

1. **Practica antes:** Ejecuta los scripts 2-3 veces antes de la presentación

2. **Ten un plan B:** Si algo falla, ten capturas de respaldo

3. **Explica mientras ejecutas:** No solo muestres, explica qué hace cada parte

4. **Usa los colores:** Los scripts tienen colores para mejor visualización

5. **Muestra los logs:** Los logs en tiempo real son muy impresionantes

6. **Demuestra la integración:** Muestra cómo todo funciona junto

---

**¡Con estos scripts tienes TODO para demostrar Nivel 4! 🚀**

**Tiempo total:** 15 minutos (5 + 3 + 7)  
**Capturas:** ~25 capturas  
**Nivel alcanzado:** NIVEL 4 ✅
