# 🪟 COMANDOS PARA WINDOWS 11 HOME

## ⚡ VALIDACIÓN RÁPIDA (10 minutos)

### 1️⃣ CONECTIVIDAD (2 min)

**Abrir PowerShell como Administrador:**

```powershell
# Ping al servidor (IPv6)
ping 2025:db8:10::2

# Ping a Internet
ping google.com

# Ver configuración de red
ipconfig /all

# Ver solo IPv6
ipconfig | findstr "IPv6"

# Ver ruta por defecto
route print -6
```

### 2️⃣ DNS (1 min)
```powershell
# Resolver nombre del servidor
nslookup gamecenter.lan

# Resolver nombre externo
nslookup google.com

# Ver servidor DNS configurado
ipconfig /all | findstr "DNS"
```

### 3️⃣ NAVEGACIÓN WEB (1 min)
```powershell
# Abrir navegador
start microsoft-edge:http://google.com

# O Chrome
start chrome http://google.com

# O Firefox
start firefox http://google.com
```

### 4️⃣ SAMBA - Conectar recursos compartidos (3 min)

**Opción A: Explorador de archivos (GUI)**

1. Abrir Explorador de archivos
2. En la barra de direcciones escribir:
   ```
   \\gamecenter.lan
   ```
   O por IP:
   ```
   \\2025:db8:10::2
   ```

3. Verás los recursos compartidos:
   - **Publico** - Acceso total
   - **Juegos** - Requiere usuario
   - **Compartido** - Solo lectura

4. Hacer doble clic en **Publico**

5. Crear archivo de prueba:
   - Clic derecho → Nuevo → Documento de texto
   - Nombrar: `test-windows.txt`
   - Abrir y escribir: "Prueba desde Windows 11"

**Opción B: Línea de comandos (PowerShell)**

```powershell
# Ver recursos compartidos disponibles
net view \\gamecenter.lan

# Montar recurso Publico en unidad Z:
net use Z: \\gamecenter.lan\Publico

# Ver contenido
dir Z:

# Crear archivo de prueba
echo "Prueba desde Windows 11" > Z:\test-windows.txt

# Leer archivo
type Z:\test-windows.txt

# Ver unidades montadas
net use

# Desmontar (cuando termines)
net use Z: /delete
```

**Opción C: Mapear unidad de red (permanente)**

1. Explorador de archivos
2. Clic derecho en "Este equipo"
3. "Conectar a unidad de red"
4. Unidad: `Z:`
5. Carpeta: `\\gamecenter.lan\Publico`
6. ✅ Reconectar al iniciar sesión
7. Finalizar

### 5️⃣ FTP (2 min)

**Opción A: Navegador**
```
ftp://gamecenter.lan
```

**Opción B: PowerShell**
```powershell
# Conectar por FTP
ftp gamecenter.lan
# Usuario: anonymous
# Password: (Enter)
# Comandos: dir, pwd, quit
```

**Opción C: FileZilla (si está instalado)**
1. Abrir FileZilla
2. Host: `ftp://gamecenter.lan` o `ftp://2025:db8:10::2`
3. Usuario: `anonymous`
4. Contraseña: (vacía)
5. Puerto: `21`
6. Conectar

### 6️⃣ SSH AL SERVIDOR (1 min)

**Windows 11 tiene SSH integrado:**

```powershell
# Conectar por SSH
ssh ubuntu@gamecenter.lan

# O por IP
ssh ubuntu@2025:db8:10::2

# Salir
exit
```

### 7️⃣ INFORMACIÓN DEL SISTEMA (1 min)
```powershell
# Ver información del sistema
systeminfo | findstr /C:"Nombre de host" /C:"Nombre del sistema"

# Ver discos
wmic logicaldisk get name,size,freespace

# Ver particiones
diskpart
# Luego: list disk, list volume, exit

# Usuario actual
whoami

# Ver adaptadores de red
Get-NetAdapter

# Ver configuración IPv6
Get-NetIPAddress -AddressFamily IPv6
```

---

## 📸 CAPTURAS PARA LA RÚBRICA (15 total)

### CONECTIVIDAD (5 capturas)
```powershell
# 1. Ping al servidor
ping 2025:db8:10::2

# 2. Ping a Internet
ping google.com

# 3. DNS local
nslookup gamecenter.lan

# 4. DNS externo
nslookup google.com

# 5. Navegador mostrando Google
start microsoft-edge:http://google.com
```

### SERVICIOS (5 capturas)
```powershell
# 6. Recursos Samba disponibles
net view \\gamecenter.lan

# 7. Explorador mostrando \\gamecenter.lan\Publico

# 8. Crear archivo en Samba
echo "Prueba Windows" > Z:\test-windows.txt

# 9. FTP en navegador
# Abrir: ftp://gamecenter.lan

# 10. SSH conectado
ssh ubuntu@gamecenter.lan
```

### SISTEMA (5 capturas)
```powershell
# 11. Configuración de red
ipconfig /all

# 12. Discos y particiones
wmic logicaldisk get name,size,freespace

# 13. Unidades montadas
net use

# 14. Usuario actual
whoami

# 15. Información del sistema
systeminfo | findstr /C:"Nombre" /C:"Sistema"
```

---

## 🚀 SCRIPT AUTOMÁTICO DE VALIDACIÓN

**Guardar como: `validar-windows.ps1`**

```powershell
# Validación Windows 11 - Rúbrica Nivel 4

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     VALIDACIÓN WINDOWS 11 - RÚBRICA NIVEL 4                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n1️⃣  CONECTIVIDAD AL SERVIDOR" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$ping1 = Test-Connection -ComputerName "2025:db8:10::2" -Count 2 -Quiet
if ($ping1) { Write-Host "✅ Servidor alcanzable" -ForegroundColor Green } 
else { Write-Host "❌ Servidor no responde" -ForegroundColor Red }

Write-Host "`n2️⃣  CONECTIVIDAD A INTERNET" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$ping2 = Test-Connection -ComputerName "google.com" -Count 2 -Quiet
if ($ping2) { Write-Host "✅ Internet funciona" -ForegroundColor Green } 
else { Write-Host "❌ Sin Internet" -ForegroundColor Red }

Write-Host "`n3️⃣  RESOLUCIÓN DNS LOCAL" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$dns1 = Resolve-DnsName -Name "gamecenter.lan" -ErrorAction SilentlyContinue
if ($dns1) { Write-Host "✅ DNS local funciona" -ForegroundColor Green } 
else { Write-Host "❌ DNS local falla" -ForegroundColor Red }

Write-Host "`n4️⃣  RESOLUCIÓN DNS EXTERNA" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$dns2 = Resolve-DnsName -Name "google.com" -ErrorAction SilentlyContinue
if ($dns2) { Write-Host "✅ DNS externo funciona" -ForegroundColor Green } 
else { Write-Host "❌ DNS externo falla" -ForegroundColor Red }

Write-Host "`n5️⃣  CONFIGURACIÓN IPv6" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$ipv6 = Get-NetIPAddress -AddressFamily IPv6 | Where-Object {$_.IPAddress -like "2025:*"}
if ($ipv6) { 
    Write-Host "✅ IPv6 configurado: $($ipv6.IPAddress)" -ForegroundColor Green 
} else { 
    Write-Host "❌ Sin IPv6" -ForegroundColor Red 
}

Write-Host "`n6️⃣  RECURSOS SAMBA" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$samba = net view \\gamecenter.lan 2>$null
if ($LASTEXITCODE -eq 0) { Write-Host "✅ Samba disponible" -ForegroundColor Green } 
else { Write-Host "❌ Samba no responde" -ForegroundColor Red }

Write-Host "`n7️⃣  USUARIO ACTUAL" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "Usuario: $env:USERNAME"
Write-Host "Computadora: $env:COMPUTERNAME"

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  ✅ VALIDACIÓN COMPLETA                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
```

**Ejecutar:**
```powershell
# Permitir ejecución de scripts (solo primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ejecutar script
.\validar-windows.ps1
```

---

## 📋 CHECKLIST PARA LA DEMOSTRACIÓN

- [ ] Servidor encendido
- [ ] Windows 11 encendido
- [ ] IP obtenida por DHCP
- [ ] Ping al servidor funciona
- [ ] Ping a Internet funciona
- [ ] DNS resuelve `gamecenter.lan`
- [ ] DNS resuelve `google.com`
- [ ] Navegador accede a Internet
- [ ] `\\gamecenter.lan` muestra recursos
- [ ] Puede abrir `\\gamecenter.lan\Publico`
- [ ] Puede crear archivos en Samba
- [ ] FTP conecta al servidor
- [ ] SSH conecta al servidor
- [ ] `ipconfig /all` muestra IPv6
- [ ] `net use` muestra unidades

---

## 🎯 ATAJOS RÁPIDOS

### Abrir PowerShell como Admin
- `Win + X` → `Windows PowerShell (Admin)`

### Abrir Explorador de archivos
- `Win + E`

### Conectar a Samba rápido
- `Win + R` → `\\gamecenter.lan` → Enter

### Ver configuración de red
- `Win + R` → `ncpa.cpl` → Enter

---

## ⏱️ TIEMPO ESTIMADO: 10-12 minutos

**¡Todo listo para demostrar Nivel 4 desde Windows!** 🚀
