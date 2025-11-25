# 📚 DOCUMENTACIÓN PARA LA RÚBRICA

## Índice de Documentos

---

## 🎯 DOCUMENTOS PRINCIPALES

### 1. **RESUMEN-RUBRICA.md** ⭐
**Empieza aquí**

Análisis completo de cumplimiento de la rúbrica:
- Nivel alcanzado en cada criterio
- Qué tienes y qué falta
- Plan de acción rápido (30 minutos)
- Checklist final

**Cuándo usarlo:** Antes de empezar, para saber qué hacer

---

### 2. **GUIA-DEMOSTRACION-RUBRICA.md** 📋
**Guía paso a paso**

Instrucciones detalladas para demostrar cada criterio:
- Conectividad entre SO
- Configuración de red y servicios
- Toma de decisiones técnicas
- Diseño y documentación
- Capturas obligatorias
- Orden de demostración

**Cuándo usarlo:** Durante la preparación de evidencias

---

### 3. **EVIDENCIAS-RUBRICA.md** 📸
**Plantilla de evidencias**

Documento completo con:
- Topología de red
- Tablas de conectividad
- Configuración de servicios
- Particiones y almacenamiento
- Gestión de usuarios
- Seguridad y firewall
- Automatización con Ansible
- Comandos para generar evidencias

**Cuándo usarlo:** Como referencia durante la demostración

---

### 4. **TABLAS-RED-COMPLETAS.md** 📊
**Todas las tablas de red**

12 tablas completas:
1. Tabla general de red
2. Tabla de hosts y direcciones IP
3. Tabla de interfaces de red
4. Tabla de servicios y puertos
5. Tabla de reglas de firewall
6. Tabla de rutas IPv6
7. Tabla de registros DNS
8. Tabla de configuración DHCP
9. Tabla de conectividad entre hosts
10. Tabla de ancho de banda y latencia
11. Comandos de verificación
12. Diagrama de red ASCII

**Cuándo usarlo:** Para copiar tablas al informe final

---

### 5. **INSTRUCCIONES-WINDOWS.md** 🪟
**Guía específica para Windows 11**

Demostración completa en Windows:
- Script de evidencias
- Seguridad (firewall, usuarios, permisos)
- Particiones (discos, volúmenes)
- Roles (Admin, Auditor, Cliente)
- Automatización con Ansible
- Comandos PowerShell
- Troubleshooting

**Cuándo usarlo:** Al demostrar en Windows 11

---

## 🚀 SCRIPTS DISPONIBLES

### Scripts de Diagnóstico

| Script | Ubicación | Descripción |
|--------|-----------|-------------|
| **test-connectivity-full.sh** | `scripts/diagnostics/` | Prueba completa de conectividad |
| **show-partitions.sh** | `scripts/diagnostics/` | Muestra esquema de particiones |
| **generate-full-evidence.sh** | `scripts/diagnostics/` | Genera reporte completo |
| **check-user-permissions.sh** | `scripts/diagnostics/` | Verifica permisos de usuarios |
| **Test-WindowsEvidence.ps1** | `scripts/windows/` | Evidencias en Windows 11 |

### Cómo ejecutar:

#### En Linux (Servidor o Ubuntu Desktop):
```bash
cd ~/ansible-gestion-despliegue

# Conectividad
bash scripts/diagnostics/test-connectivity-full.sh

# Particiones
bash scripts/diagnostics/show-partitions.sh

# Reporte completo
bash scripts/diagnostics/generate-full-evidence.sh

# Usuarios y permisos
bash scripts/diagnostics/check-user-permissions.sh
```

#### En Windows 11:
```powershell
cd C:\ansible-gestion-despliegue

# Evidencias completas
PowerShell -ExecutionPolicy Bypass -File scripts\windows\Test-WindowsEvidence.ps1
```

---

## 📋 FLUJO DE TRABAJO RECOMENDADO

### Paso 1: Leer el resumen (5 min)
```
docs/RESUMEN-RUBRICA.md
```
- Entender qué tienes
- Identificar qué falta
- Ver plan de acción

### Paso 2: Generar evidencias (30 min)

#### En el Servidor:
```bash
bash scripts/diagnostics/generate-full-evidence.sh
bash scripts/diagnostics/show-partitions.sh
bash scripts/diagnostics/check-user-permissions.sh
```

#### En Ubuntu Desktop:
```bash
bash scripts/diagnostics/test-connectivity-full.sh
```

#### En Windows 11:
```powershell
PowerShell -ExecutionPolicy Bypass -File scripts\windows\Test-WindowsEvidence.ps1
```

### Paso 3: Tomar capturas (20 min)
```
docs/GUIA-DEMOSTRACION-RUBRICA.md
Sección: "CAPTURAS OBLIGATORIAS"
```

### Paso 4: Organizar evidencias (10 min)
```
evidencias-rubrica/
├── 01-conectividad/
├── 02-servicios/
├── 03-particiones/
├── 04-usuarios/
├── 05-seguridad/
└── 06-automatizacion/
```

### Paso 5: Revisar tablas (5 min)
```
docs/TABLAS-RED-COMPLETAS.md
```
- Copiar tablas necesarias
- Verificar datos correctos

### Paso 6: Practicar demostración (10 min)
```
docs/GUIA-DEMOSTRACION-RUBRICA.md
Sección: "ORDEN SUGERIDO DE DEMOSTRACIÓN"
```

---

## 📊 TABLAS OBLIGATORIAS

Todas las tablas están en: `docs/TABLAS-RED-COMPLETAS.md`

### Tablas mínimas requeridas:

1. ✅ **Tabla de Red** (IPs, máscaras, gateway)
2. ✅ **Tabla de Servicios** (puertos, protocolos, estado)
3. ✅ **Tabla de Usuarios** (permisos, grupos, roles)
4. ✅ **Tabla de Particiones** (discos, tamaños, tipos)
5. ✅ **Tabla de Firewall** (reglas, puertos, acciones)
6. ✅ **Tabla de Conectividad** (matriz de conexiones)

---

## 🎯 CRITERIOS DE LA RÚBRICA

### Nivel 4 (Objetivo):

| Criterio | Documento de Referencia |
|----------|-------------------------|
| **Conectividad entre SO** | `EVIDENCIAS-RUBRICA.md` sección 1 |
| **Configuración de red** | `TABLAS-RED-COMPLETAS.md` |
| **Decisiones técnicas** | `EVIDENCIAS-RUBRICA.md` sección 7 |
| **Documentación** | Todos los docs en `docs/` |

---

## 📸 CAPTURAS NECESARIAS

### Mínimo 40 capturas:

- **Conectividad:** 10 capturas
- **Servicios:** 8 capturas
- **Particiones:** 5 capturas
- **Usuarios:** 10 capturas
- **Seguridad:** 5 capturas
- **Automatización:** 2 capturas

**Ver lista completa en:**
```
docs/GUIA-DEMOSTRACION-RUBRICA.md
Sección: "CAPTURAS OBLIGATORIAS"
```

---

## 🔧 COMANDOS RÁPIDOS

### Verificar todo funciona:

```bash
# Servidor
sudo systemctl status bind9 isc-dhcp-server6 nginx ssh
sudo ufw status verbose
ip -6 addr show
ip -6 route show

# Cliente
ping6 2025:db8:10::2
dig @2025:db8:10::2 gamecenter.lan AAAA
curl http://gamecenter.lan
ssh ubuntu@2025:db8:10::2
```

### Generar reportes:

```bash
# Reporte completo
bash scripts/diagnostics/generate-full-evidence.sh

# Ver reporte
cat ~/evidencias-rubrica/reporte_*.txt
```

---

## 📦 ESTRUCTURA DE ENTREGA

```
proyecto-so/
├── docs/
│   ├── RESUMEN-RUBRICA.md
│   ├── GUIA-DEMOSTRACION-RUBRICA.md
│   ├── EVIDENCIAS-RUBRICA.md
│   ├── TABLAS-RED-COMPLETAS.md
│   └── INSTRUCCIONES-WINDOWS.md
├── evidencias-rubrica/
│   ├── 01-conectividad/
│   ├── 02-servicios/
│   ├── 03-particiones/
│   ├── 04-usuarios/
│   ├── 05-seguridad/
│   └── 06-automatizacion/
├── README.md
├── POLITICAS-FIREWALL.md
└── scripts/
    ├── diagnostics/
    └── windows/
```

---

## ✅ CHECKLIST FINAL

### Antes de presentar:

- [ ] Leído `RESUMEN-RUBRICA.md`
- [ ] Ejecutados todos los scripts
- [ ] Tomadas todas las capturas
- [ ] Organizadas evidencias en carpetas
- [ ] Revisadas todas las tablas
- [ ] Practicada la demostración
- [ ] Servidor funcionando
- [ ] Clientes funcionando
- [ ] Servicios activos
- [ ] Documentación completa

---

## 🎓 TIPS FINALES

1. **Empieza por el resumen:** `RESUMEN-RUBRICA.md`
2. **Usa los scripts:** Automatizan la generación de evidencias
3. **Toma capturas claras:** Con fecha/hora visible
4. **Organiza por carpetas:** Facilita encontrar evidencias
5. **Practica la demo:** 10 minutos de práctica evitan errores
6. **Ten backup:** Guarda evidencias en múltiples lugares

---

## 📞 AYUDA RÁPIDA

### Si algo falla:

1. **Servicios no funcionan:**
   ```bash
   sudo systemctl restart bind9 isc-dhcp-server6 nginx
   ```

2. **No hay conectividad:**
   ```bash
   ping6 2025:db8:10::2
   ip -6 route show
   ```

3. **DNS no resuelve:**
   ```bash
   dig @2025:db8:10::2 gamecenter.lan AAAA
   sudo systemctl restart bind9
   ```

4. **Firewall bloqueando:**
   ```bash
   sudo ufw status verbose
   sudo ufw reload
   ```

---

## 🎯 OBJETIVO FINAL

**Demostrar NIVEL 4 en todos los criterios:**

- ✅ Conectividad estable y funcional
- ✅ Servicios configurados correctamente
- ✅ Decisiones técnicas justificadas
- ✅ Documentación profesional y completa

**Tiempo estimado:** 30 minutos de preparación + 15 minutos de demostración

---

**¡Éxito en tu presentación! 🚀**

**Fecha:** Noviembre 2025  
**Proyecto:** Game Center con IPv6  
**Curso:** Sistemas Operativos
