# Rol: http_web

## Descripción
Instala y configura Nginx como servidor web con una página de bienvenida personalizada.

## Características
- ✅ Instalación de Nginx
- ✅ Configuración optimizada para IPv6
- ✅ Página de bienvenida moderna y responsive
- ✅ Headers de seguridad básicos
- ✅ Logs configurados

## Servicios instalados
- **Nginx**: Servidor web en puerto 80

## Archivos importantes
- `/var/www/html/index.html` - Página principal
- `/etc/nginx/sites-available/default` - Configuración del sitio
- `/var/log/nginx/access.log` - Log de accesos
- `/var/log/nginx/error.log` - Log de errores

## Uso
```yaml
- role: http_web
  tags: web
```

## Verificación
```bash
# Ver estado
systemctl status nginx

# Probar configuración
nginx -t

# Ver logs
tail -f /var/log/nginx/access.log
```

## Acceso
Abre en tu navegador: `http://[IP-de-la-VM]`
