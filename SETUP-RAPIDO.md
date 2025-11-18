# 🚀 SETUP RÁPIDO EN SERVIDOR NUEVO

## Después de hacer `git pull` en tu servidor:

### 1️⃣ Crear archivo de contraseña del vault

```bash
bash scripts/setup-vault-pass.sh
```

Te pedirá la contraseña del vault (por defecto: `ubuntu123`)

### 2️⃣ Ejecutar scripts normalmente

```bash
# Ahora funcionarán sin pedir contraseña del vault
bash scripts/run/run-network.sh
bash scripts/run/run-dns.sh
bash scripts/run/run-dhcp.sh
```

---

## ¿Por qué no está el `.vault_pass` en GitHub?

Por **seguridad**. El archivo `.vault_pass` contiene la contraseña para desencriptar secretos, por eso está en `.gitignore` y NO se sube al repositorio.

---

## Alternativa: Sin crear `.vault_pass`

Si no quieres crear el archivo, los scripts te pedirán la contraseña cada vez:

```bash
bash scripts/run/run-dns.sh
# Te preguntará: "Vault password:"
# Ingresa: ubuntu123
```

---

## ¿Qué hace `setup-vault-pass.sh`?

1. Te pide la contraseña del vault
2. Crea el archivo `.vault_pass` con esa contraseña
3. Le pone permisos seguros (600)
4. Verifica que la contraseña sea correcta

---

## Resumen

```bash
# En tu PC (donde desarrollas)
git add .
git commit -m "Actualizar configuración"
git push

# En tu servidor Ubuntu
git pull
bash scripts/setup-vault-pass.sh  # Solo la primera vez
bash scripts/run/run-dns.sh       # Ya no pide contraseña del vault
```

---

## Contraseña por defecto del vault

```
ubuntu123
```

(Cámbiala en producción con: `ansible-vault rekey group_vars/all.vault.yml`)
