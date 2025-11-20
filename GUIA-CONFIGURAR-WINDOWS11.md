# 🪟 GUÍA: CONFIGURAR WINDOWS 11 EN RED IPv6-ONLY CON NAT64

## 📋 CONFIGURACIÓN DE RED

### 1️⃣ Configurar DHCP Automático (Recomendado)

**Pasos:**
1. Click derecho en el icono de red (esquina inferior derecha)
2. **"Abrir configuración de red e Internet"**
3. Click en **"Ethernet"** o **"Wi-Fi"** (según tu conexión)
4. Click en **"Propiedades"**
5. En **"Asignación de IP"** → **"Automática (DHCP)"**
6. En **"Asignación de servidor DNS"** → **"Automática (DHCP)"**
7. Click **"Guardar"**

✅ **Resultado esperado:**
- IP IPv6: `2025:db8:10::XXX/64` (asignada automáticamente por DHCP)
- Gateway: `2025:db8:10::1`
- DNS: `2025:db8:10::1`

---

### 2️⃣ Verificar Conectividad IPv6

**Abrir PowerShell y ejecutar:**

```powershell
# Ver configuración de red
ipconfig /all

# Verificar que tienes IPv6
# Debes ver algo como: 2025:db8:10::XXX

# Hacer ping al gateway (tu servidor)
ping 2025:db8:10::1

# Hacer ping a Google DNS64
ping 2001:4860:4860::6464
```

✅ **Si todo funciona:** Verás respuestas de los pings

❌ **Si no funciona:** Revisa que el cable esté conectado y que RADVD esté corriendo en el servidor

---

## 🌐 CONFIGURACIÓN DE PROXY SQUID

Windows 11 **NO soporta DNS64/NAT64 nativamente**, así que **NECESITAS configurar el proxy** para acceder a internet.

### 3️⃣ Configurar Proxy Manual

**Pasos:**
1. Presiona `Win + I` (Configuración)
2. Ve a **"Red e Internet"**
3. Click en **"Proxy"**
4. Activa **"Usar un servidor proxy"**
5. Configura:
   - **Dirección:** `2025:db8:10::1` (IP del servidor)
   - **Puerto:** `3128`
6. En **"No usar el servidor proxy para"** agrega:
   ```
   localhost;127.0.0.1;[::1];*.local;2025:db8:10::*
   ```
7. Click **"Guardar"**

---

### 4️⃣ Configurar Proxy en Navegadores

#### 🦊 Firefox
1. Menú → **Configuración**
2. Busca **"Proxy"**
3. **"Configuración manual del proxy"**
4. HTTP Proxy: `2025:db8:10::1` Puerto: `3128`
5. ✅ Marcar **"Usar este proxy para HTTPS"**
6. No proxy para: `localhost, 127.0.0.1, ::1, 2025:db8:10::1`

#### 🌐 Chrome/Edge
1. Configuración → **Sistema**
2. **"Abrir la configuración de proxy del equipo"**
3. (Usa la configuración de Windows del paso 3)

---

## 🧪 VERIFICAR QUE TODO FUNCIONA

### 5️⃣ Pruebas de Conectividad

**En PowerShell:**

```powershell
# 1. Verificar IPv6
ipconfig | findstr "IPv6"

# 2. Ping al servidor
ping 2025:db8:10::1

# 3. Verificar DNS
nslookup google.com 2025:db8:10::1

# 4. Probar conexión HTTP (con proxy configurado)
curl http://google.com
```

**En el navegador:**
1. Abre: `http://google.com`
2. Abre: `https://youtube.com`
3. Abre: `http://example.com`

✅ **Si funciona:** Verás las páginas web normalmente

---

## ⚙️ CONFIGURACIÓN AVANZADA (Opcional)

### 6️⃣ Configurar DNS Manualmente (Si DHCP no funciona)

**PowerShell como Administrador:**

```powershell
# Ver interfaces de red
Get-NetAdapter

# Configurar DNS (reemplaza "Ethernet" con tu interfaz)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "2025:db8:10::1"

# Verificar
Get-DnsClientServerAddress
```

---

### 7️⃣ Deshabilitar IPv4 (Opcional, para forzar IPv6)

**Pasos:**
1. Panel de Control → **Centro de redes y recursos compartidos**
2. Click en tu conexión
3. **"Propiedades"**
4. ❌ Desmarcar **"Protocolo de Internet versión 4 (TCP/IPv4)"**
5. ✅ Dejar marcado **"Protocolo de Internet versión 6 (TCP/IPv6)"**
6. **"Aceptar"**

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### ❌ No tengo IPv6
```powershell
# Reiniciar adaptador de red
Disable-NetAdapter -Name "Ethernet" -Confirm:$false
Enable-NetAdapter -Name "Ethernet"

# Renovar IPv6
ipconfig /release6
ipconfig /renew6
```

### ❌ No puedo navegar (con proxy configurado)
1. Verifica que el proxy esté en `2001:db8:acad:1::1:3128`
2. Verifica que Squid esté corriendo en el servidor:
   ```bash
   sudo systemctl status squid
   ```
3. Verifica el firewall del servidor:
   ```bash
   sudo ufw status | grep 3128
   ```

### ❌ DNS no resuelve
```powershell
# Limpiar caché DNS
ipconfig /flushdns

# Verificar servidor DNS
nslookup google.com 2001:db8:acad:1::1
```

---

## 📊 RESUMEN DE CONFIGURACIÓN

| Parámetro | Valor |
|-----------|-------|
| **IP** | Automática (DHCP) - Rango: `2025:db8:10::100-200` |
| **Gateway** | `2025:db8:10::1` |
| **DNS** | `2025:db8:10::1` |
| **Proxy HTTP** | `2025:db8:10::1:3128` |
| **Proxy HTTPS** | `2025:db8:10::1:3128` |
| **Dominio** | `gamecenter.lan` |

---

## ✅ CHECKLIST FINAL

- [ ] Windows 11 instalado
- [ ] Cable de red conectado
- [ ] IPv6 asignada automáticamente
- [ ] Ping al gateway funciona
- [ ] DNS resuelve nombres
- [ ] Proxy configurado en Windows
- [ ] Navegador puede abrir sitios web
- [ ] YouTube funciona
- [ ] Google funciona

---

## 🆘 SI NADA FUNCIONA

**Desde Ubuntu Server, verifica:**

```bash
# 1. RADVD corriendo
sudo systemctl status radvd

# 2. DNS64 funcionando
dig @localhost google.com AAAA

# 3. Squid corriendo
sudo systemctl status squid

# 4. Firewall permite proxy
sudo ufw status | grep 3128

# 5. Ver logs de Squid
sudo tail -f /var/log/squid/access.log
```

**Ejecuta el diagnóstico completo:**
```bash
sudo bash scripts/diagnostics/check-server-ready.sh
```

---

## 📝 NOTAS IMPORTANTES

⚠️ **Windows 11 NO soporta DNS64/NAT64 nativamente**
- Necesitas el proxy Squid para navegar
- Sin proxy, solo funcionarán aplicaciones que soporten IPv6 puro

⚠️ **Algunas aplicaciones pueden no funcionar**
- Apps de Microsoft Store pueden tener problemas
- Juegos online pueden necesitar configuración adicional
- VPNs pueden no funcionar correctamente

✅ **Funcionará correctamente:**
- Navegadores web (con proxy)
- Office 365
- YouTube, Netflix, streaming
- Descargas HTTP/HTTPS
- Email (Outlook, Gmail)

---

**¿Necesitas ayuda?** Ejecuta los diagnósticos en el servidor Ubuntu y revisa los logs.
