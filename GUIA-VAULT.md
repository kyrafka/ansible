# 🔐 GUÍA DE USO DEL ANSIBLE VAULT

## ✅ Configuración Actual

Tu proyecto ya está configurado para usar Ansible Vault automáticamente:

- **Archivo de contraseña**: `.vault_pass` (contiene: `ubuntu123`)
- **Archivo encriptado**: `group_vars/all.vault.yml`
- **Configuración**: `ansible.cfg` ya tiene `vault_password_file = .vault_pass`

---

## 🚀 USO AUTOMÁTICO

Todos los scripts `run-*.sh` ya están configurados para usar el vault automáticamente:

```bash
# Estos comandos YA NO necesitan --ask-vault-pass
bash scripts/run/run-network.sh
bash scripts/run/run-dns.sh
bash scripts/run/run-dhcp.sh
bash scripts/run/run-all-services.sh
```

---

## 📝 COMANDOS MANUALES CON VAULT

### Ejecutar playbooks manualmente:

```bash
# Opción 1: Usar el archivo de contraseña (RECOMENDADO)
ansible-playbook site.yml --vault-password-file .vault_pass

# Opción 2: Pedir contraseña interactivamente
ansible-playbook site.yml --ask-vault-pass

# Opción 3: Usar variable de entorno
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass
ansible-playbook site.yml
```

### Ver contenido del vault:

```bash
# Ver archivo encriptado
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass

# O interactivamente
ansible-vault view group_vars/all.vault.yml
```

### Editar el vault:

```bash
# Editar archivo encriptado
ansible-vault edit group_vars/all.vault.yml --vault-password-file .vault_pass

# O interactivamente
ansible-vault edit group_vars/all.vault.yml
```

### Encriptar nuevos archivos:

```bash
# Encriptar un archivo
ansible-vault encrypt archivo.yml --vault-password-file .vault_pass

# Encriptar con contraseña interactiva
ansible-vault encrypt archivo.yml
```

### Desencriptar archivos:

```bash
# Desencriptar (CUIDADO: quedará en texto plano)
ansible-vault decrypt group_vars/all.vault.yml --vault-password-file .vault_pass

# Mejor: ver temporalmente sin desencriptar
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass
```

---

## 🔧 ESTRUCTURA DE ARCHIVOS

```
ansible-gestion-despliegue/
├── .vault_pass                    # Contraseña del vault (NO subir a git)
├── ansible.cfg                    # Configuración con vault_password_file
├── group_vars/
│   ├── all.yml                   # Variables públicas (sin encriptar)
│   └── all.vault.yml             # Variables secretas (ENCRIPTADO)
└── scripts/run/
    ├── run-dns.sh                # Ya usa --vault-password-file
    ├── run-dhcp.sh               # Ya usa --vault-password-file
    └── ...
```

---

## 🔐 CONTENIDO DEL VAULT

Tu archivo `group_vars/all.vault.yml` contiene:

```yaml
# Contraseñas de usuarios
vault_user_password: "123"
vault_admin_password: "123"
vault_gamer_password: "123"
vault_auditor_password: "123"

# Contraseñas de servicios
vault_mysql_root_password: "ubuntu123"
vault_samba_password: "ubuntu123"

# Claves SSH
vault_ssh_public_key: "ssh-rsa AAAA..."
vault_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

---

## 🛡️ SEGURIDAD

### ✅ Buenas prácticas:

1. **NO subir `.vault_pass` a git**
   ```bash
   # Ya está en .gitignore
   echo ".vault_pass" >> .gitignore
   ```

2. **Usar permisos restrictivos**
   ```bash
   chmod 600 .vault_pass
   chmod 600 group_vars/all.vault.yml
   ```

3. **Cambiar la contraseña del vault**
   ```bash
   # Cambiar contraseña
   ansible-vault rekey group_vars/all.vault.yml
   
   # Actualizar .vault_pass con la nueva contraseña
   echo "nueva_contraseña" > .vault_pass
   ```

4. **Usar diferentes contraseñas por entorno**
   ```bash
   # Producción
   .vault_pass.prod
   
   # Desarrollo
   .vault_pass.dev
   ```

---

## 🔍 VERIFICAR QUE FUNCIONA

```bash
# 1. Ver que el vault está encriptado
cat group_vars/all.vault.yml
# Debe mostrar: $ANSIBLE_VAULT;1.1;AES256...

# 2. Ver contenido desencriptado
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass

# 3. Probar un playbook
bash scripts/run/run-network.sh
# NO debe pedir contraseña del vault
```

---

## ❌ SOLUCIÓN DE PROBLEMAS

### Error: "Attempting to decrypt but no vault secrets found"

```bash
# Solución 1: Verificar que .vault_pass existe
ls -la .vault_pass

# Solución 2: Verificar contenido
cat .vault_pass

# Solución 3: Usar explícitamente
ansible-playbook site.yml --vault-password-file .vault_pass
```

### Error: "Decryption failed"

```bash
# La contraseña en .vault_pass es incorrecta
# Verificar contraseña correcta:
ansible-vault view group_vars/all.vault.yml
# Ingresa la contraseña correcta y actualiza .vault_pass
```

### Error: "vault_password_file not found"

```bash
# Verificar ansible.cfg
grep vault_password_file ansible.cfg

# Debe mostrar:
# vault_password_file = .vault_pass
```

---

## 📚 COMANDOS ÚTILES

```bash
# Ver todas las variables (incluyendo vault)
ansible localhost -m debug -a "var=hostvars[inventory_hostname]" --vault-password-file .vault_pass

# Probar que el vault se desencripta correctamente
ansible-playbook site.yml --vault-password-file .vault_pass --syntax-check

# Ver qué variables vienen del vault
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass | grep "^vault_"

# Crear backup del vault
cp group_vars/all.vault.yml group_vars/all.vault.yml.backup
```

---

## 🎯 RESUMEN RÁPIDO

```bash
# ✅ TODO ESTÁ CONFIGURADO, solo usa:
bash scripts/run/run-dns.sh
bash scripts/run/run-dhcp.sh
bash scripts/run/run-network.sh

# ✅ Si ejecutas manualmente:
ansible-playbook site.yml --vault-password-file .vault_pass

# ✅ Ver secretos:
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass

# ✅ Editar secretos:
ansible-vault edit group_vars/all.vault.yml --vault-password-file .vault_pass
```

---

## 🔄 CAMBIAR CONTRASEÑA DEL VAULT

```bash
# 1. Cambiar contraseña del vault
ansible-vault rekey group_vars/all.vault.yml

# 2. Actualizar .vault_pass
echo "nueva_contraseña_segura" > .vault_pass

# 3. Verificar
ansible-vault view group_vars/all.vault.yml --vault-password-file .vault_pass
```

---

## 📋 CHECKLIST DE SEGURIDAD

- [x] `.vault_pass` está en `.gitignore`
- [x] `group_vars/all.vault.yml` está encriptado
- [x] `ansible.cfg` tiene `vault_password_file = .vault_pass`
- [x] Todos los scripts `run-*.sh` usan `--vault-password-file`
- [ ] Cambiar contraseña por defecto `ubuntu123` a algo más seguro
- [ ] Usar permisos 600 en archivos sensibles
- [ ] NO compartir `.vault_pass` por email/chat

```bash
# Aplicar permisos seguros
chmod 600 .vault_pass
chmod 600 group_vars/all.vault.yml
```
