# Troubleshooting - VS Code Remote SSH en Jetson Nano

## Problemas Comunes

### 1. Error: "This machine does not meet Visual Studio Code Server's prerequisites"

**Causa**: VS Code intenta instalar un servidor moderno incompatible con GLIBC 2.27.

**Solución**:
```bash
# En la Jetson
cd ~/minicluster/jetson-01
chmod +x scripts/install-vscode-server.sh
./scripts/install-vscode-server.sh
```

Luego configura `settings.json` en tu VS Code local (ver [VSCODE_REMOTE_SSH.md](VSCODE_REMOTE_SSH.md)).

---

### 2. VS Code ignora la configuración y sigue intentando instalar servidor nuevo

**Causa**: Instalaciones antiguas conflictivas o caché.

**Solución**:

1. **En la Jetson**, elimina instalaciones antiguas:
   ```bash
   rm -rf ~/.vscode-server
   rm -rf ~/.vscode-server-insiders
   ```

2. **En tu PC**, mata el servidor:
   - `F1` → `Remote-SSH: Kill VS Code Server on Host` → `jetson-01`

3. **Verifica tu settings.json** tenga:
   ```json
   {
     "remote.SSH.serverInstallPath": {
       "jetson-01": "/home/alejandrolmeida/.vscode-server-legacy"
     }
   }
   ```

4. **Reconecta** desde VS Code.

---

### 3. Error: "Could not establish connection"

**Causas posibles**:
- No hay SSH keys configuradas
- Firewall bloqueando la conexión
- Servidor SSH no está corriendo

**Solución**:

1. **Verifica conectividad SSH básica**:
   ```powershell
   # Desde Windows
   ssh jetson-01 "echo 'Conexión OK'"
   ```

2. **Configura SSH keys** si no lo has hecho:
   ```powershell
   # Generar key (si no tienes)
   ssh-keygen -t ed25519 -C "tu_email@example.com"
   
   # Copiar a jetson
   ssh-copy-id -i ~/.ssh/id_ed25519.pub alejandrolmeida@192.168.50.11
   ```

3. **En la Jetson**, verifica servicio SSH:
   ```bash
   sudo systemctl status ssh
   ```

---

### 4. Symlink incorrecto - VS Code espera otro commit

**Síntoma**: En los logs ves que VS Code espera un commit diferente al instalado.

**Ejemplo del log**:
```
Using commit id "c3a26841a84f20dfe0850d0a5a9bd01da4f003ea"
```

**Solución**:

1. **En la Jetson**, crea el symlink:
   ```bash
   cd ~/.vscode-server-legacy/bin
   ln -sf 8b3775030ed1a69b13e4f4c628c612102e30a681 c3a26841a84f20dfe0850d0a5a9bd01da4f003ea
   ```

2. **O usa el script PowerShell** (desde Windows):
   ```powershell
   cd C:\Users\aleja\minicluster\jetson-01\scripts
   .\create-symlinks.ps1
   ```
   
   (Actualiza `$expectedCommit` en el script si es necesario)

---

### 5. Error: "Permission denied" al ejecutar servidor

**Solución**:
```bash
# En la Jetson
chmod +x ~/.vscode-server-legacy/bin/*/bin/code-server
chmod +x ~/.vscode-server-legacy/bin/*/bin/helpers/check-requirements.sh
```

---

### 6. Conexión muy lenta o timeouts

**Solución**:

1. **Aumenta los timeouts** en `settings.json`:
   ```json
   {
     "remote.SSH.connectTimeout": 60,
     "remote.SSH.serverInstallPath": {
       "jetson-01": "/home/alejandrolmeida/.vscode-server-legacy"
     }
   }
   ```

2. **Configura SSH keepalive** en `~/.ssh/config`:
   ```
   Host jetson-01
       HostName 192.168.50.11
       User alejandrolmeida
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

---

### 7. Error: "command not found: bc"

Al ejecutar el script de verificación.

**Solución**:
```bash
sudo apt install bc
```

---

### 8. VS Code se actualiza y rompe la compatibilidad

**Síntoma**: Funcionaba antes pero después de actualizar VS Code local, dejó de funcionar.

**Solución**:

1. **Opción A**: Crear nuevo symlink para el commit esperado (ver solución #4)

2. **Opción B**: Congelar tu versión de VS Code local
   - Desactiva actualizaciones automáticas:
   ```json
   {
     "update.mode": "manual"
   }
   ```

---

## Verificación del Estado

Usa el script de verificación para diagnosticar problemas:

```bash
# En la Jetson
cd ~/minicluster/jetson-01
chmod +x scripts/verify-setup.sh
./scripts/verify-setup.sh
```

Esto mostrará:
- Versión de GLIBC
- Servidores instalados
- Symlinks configurados
- Estado de SSH
- Recomendaciones

---

## Ver Logs de VS Code

Para entender qué está pasando:

1. **En VS Code**:
   - `F1` → `Remote-SSH: Show Log`
   - Busca errores relacionados con:
     - Commit ID
     - GLIBC version
     - Installation path

2. **Logs útiles**:
   ```
   [02:43:35.679] remote.SSH.serverInstallPath = {...}
   [02:43:35.733] Using commit id "c3a26841a84f20dfe0850d0a5a9bd01da4f003ea"
   [02:43:37.872] error This machine does not meet Visual Studio Code Server's prerequisites
   ```

---

## Limpieza Completa

Si nada funciona, empieza de cero:

```bash
# En la Jetson
rm -rf ~/.vscode-server*

# Reinstalar
cd ~/minicluster/jetson-01
./scripts/install-vscode-server.sh
```

Luego verifica tu `settings.json` en VS Code local.

---

## Obtener Ayuda

1. **Ver documentación**:
   - `~/minicluster/jetson-01/docs/VSCODE_REMOTE_SSH.md`
   - `~/minicluster/jetson-01/README.md`

2. **Ejecutar verificación**:
   ```bash
   ~/minicluster/jetson-01/scripts/verify-setup.sh
   ```

3. **Logs detallados** en VS Code:
   ```json
   {
     "remote.SSH.loglevel": 3
   }
   ```

---

## Comandos Útiles

```bash
# Ver versión de GLIBC
ldd --version

# Ver servidores instalados
ls -la ~/.vscode-server-legacy/bin/

# Ver procesos de VS Code Server
ps aux | grep code-server

# Matar servidor manualmente
pkill -f code-server

# Ver logs del sistema
journalctl -xe | grep ssh
```

---

Última actualización: Febrero 2026
