@echo off
REM ════════════════════════════════════════════════════════════════
REM 📋 MOSTRAR CONFIGURACIÓN DE WINDOWS 11
REM ════════════════════════════════════════════════════════════════

cls
echo ════════════════════════════════════════════════════════════════
echo 📋 CONFIGURACIÓN DE WINDOWS 11
echo ════════════════════════════════════════════════════════════════
echo.

echo 1️⃣  USUARIOS DEL SISTEMA
echo ────────────────────────────────────────────────────────────────
net user
echo.

echo 2️⃣  CARPETAS CREADAS POR ANSIBLE
echo ────────────────────────────────────────────────────────────────
dir C:\ | findstr "Compartido Dev"
echo.

echo 3️⃣  CONFIGURACIÓN DE RED (IPv6)
echo ────────────────────────────────────────────────────────────────
ipconfig | findstr "IPv6"
echo.

echo 4️⃣  REGLAS DE FIREWALL (WinRM, Ping, Compartir)
echo ────────────────────────────────────────────────────────────────
netsh advfirewall firewall show rule name=all | findstr /C:"WinRM" /C:"ICMPv6" /C:"File and Printer"
echo.

echo 5️⃣  SERVICIO WINRM
echo ────────────────────────────────────────────────────────────────
sc query WinRM
echo.

echo 6️⃣  INFORMACIÓN DEL SISTEMA
echo ────────────────────────────────────────────────────────────────
systeminfo | findstr /C:"Nombre de host" /C:"Nombre del sistema"
echo.

echo ════════════════════════════════════════════════════════════════
echo ✅ CONFIGURACIÓN MOSTRADA
echo ════════════════════════════════════════════════════════════════
echo.
pause
