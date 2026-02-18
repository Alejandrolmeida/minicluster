# Configuración de VS Code Remote SSH para Jetson Nano

## 📋 Problema

Las Jetson Nano ejecutan Ubuntu 18.04/20.04 con GLIBC 2.27, pero las versiones modernas de VS Code Server (desde ~2024) requieren GLIBC >= 2.28.

Cuando intentas conectarte por Remote-SSH, VS Code intenta instalar la última versión del servidor y falla con:

```
[error] This machine does not meet Visual Studio Code Server's prerequisites, 
expected either...
  - find GLIBC >= v2.28.0 (but found v2.27.0 instead) for GNU environments
```

## ✅ Solución

Usar una versión antigua específica del servidor VS Code que sea compatible con GLIBC 2.27.

### Versión Compatible

**Commit ID del servidor**: `8b3775030ed1a69b13e4f4c628c612102e30a681`

Esta es la última versión conocida que funciona con GLIBC 2.27 en sistemas ARM64.

## 🚀 Instalación

### Paso 1: En la Jetson (Servidor)

Ejecuta el script de instalación:

```bash
cd ~/minicluster/jetson-01
chmod +x scripts/install-vscode-server.sh
./scripts/install-vscode-server.sh
```

O manualmente:

```bash
# Crear directorio
mkdir -p ~/.vscode-server-legacy/bin

# Descargar servidor compatible
cd ~/.vscode-server-legacy/bin
wget -O vscode-server.tar.gz \
  "https://update.code.visualstudio.com/commit:8b3775030ed1a69b13e4f4c628c612102e30a681/server-linux-arm64/stable"

# Extraer
tar -xzf vscode-server.tar.gz
rm vscode-server.tar.gz

# Renombrar al commit ID
mv vscode-server-linux-arm64 8b3775030ed1a69b13e4f4c628c612102e30a681

# Crear symlink al commit actual que VS Code espera (si es necesario)
# Esto puede variar según tu versión de VS Code local
# ln -sf 8b3775030ed1a69b13e4f4c628c612102e30a681 c3a26841a84f20dfe0850d0a5a9bd01da4f003ea

# Verificar
ls -la ~/.vscode-server-legacy/bin/
```

### Paso 2: En tu PC Windows (Cliente)

Configura VS Code para usar el servidor legacy.

#### A. Configurar settings.json

Abre `settings.json` en VS Code (`Ctrl+Shift+P` → `Preferences: Open User Settings (JSON)`) y añade:

```json
{
  "remote.SSH.serverInstallPath": {
    "jetson-01": "/home/alejandrolmeida/.vscode-server-legacy",
    "jetson-02": "/home/alejandrolmeida/.vscode-server-legacy",
    "jetson-03": "/home/alejandrolmeida/.vscode-server-legacy"
  },
  "remote.SSH.useLocalServer": false,
  "remote.SSH.useExecServer": true,
  "remote.SSH.remotePlatform": {
    "jetson-01": "linux",
    "jetson-02": "linux",
    "jetson-03": "linux"
  }
}
```

#### B. Configurar SSH Config (Opcional pero recomendado)

Edita `~/.ssh/config` o `C:\Users\<usuario>\.ssh\config`:

```
Host jetson-01
    HostName 192.168.50.11
    User alejandrolmeida
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host jetson-02
    HostName 192.168.50.12
    User alejandrolmeida
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host jetson-03
    HostName 192.168.50.13
    User alejandrolmeida
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

## 🔧 Uso

1. En VS Code, presiona `F1`
2. Escribe `Remote-SSH: Connect to Host`
3. Selecciona `jetson-01` (o jetson-02/jetson-03)
4. VS Code se conectará usando el servidor legacy

## 🐛 Troubleshooting

### Error: Sigue intentando instalar servidor nuevo

Si VS Code ignora la configuración y sigue intentando instalar una versión nueva:

1. **Limpia instalaciones antiguas**:
   ```bash
   # En la jetson
   rm -rf ~/.vscode-server
   rm -rf ~/.vscode-server-insiders
   ```

2. **Reconecta desde VS Code**:
   - `F1` → `Remote-SSH: Kill VS Code Server on Host` → `jetson-01`
   - Luego reconecta

3. **Verifica settings.json**: Asegúrate de que `remote.SSH.serverInstallPath` está configurado correctamente.

### Verificar versión de GLIBC

```bash
ldd --version
```

Debería mostrar algo como:

```
ldd (Ubuntu GLIBC 2.27-3ubuntu1.6) 2.27
```

### Ver logs de conexión

En VS Code:
- `F1` → `Remote-SSH: Show Log`
- Busca errores en el proceso de instalación

### Actualizar el symlink manualmente

Si tienes una versión más nueva de VS Code local que espera un commit diferente:

```bash
# En la jetson
cd ~/.vscode-server-legacy/bin

# Ver qué commit espera VS Code (revisa los logs)
# Luego crea el symlink:
ln -sf 8b3775030ed1a69b13e4f4c628c612102e30a681 <COMMIT_ID_ESPERADO>

# Ejemplo (del error que viste):
ln -sf 8b3775030ed1a69b13e4f4c628c612102e30a681 c3a26841a84f20dfe0850d0a5a9bd01da4f003ea
```

### Script para crear symlink automático

Ya lo hiciste con PowerShell:

```powershell
$jetsons = @('jetson-01', 'jetson-02', 'jetson-03')
foreach ($j in $jetsons) {
    ssh $j "cd ~/.vscode-server-legacy/bin && ln -sf 8b3775030ed1a69b13e4f4c628c612102e30a681 c3a26841a84f20dfe0850d0a5a9bd01da4f003ea && ls -la"
}
```

## 📚 Referencias

- [VS Code Server Prerequisites](https://code.visualstudio.com/docs/remote/linux#_remote-host-container-wsl-linux-prerequisites)
- [Issue: GLIBC compatibility](https://github.com/microsoft/vscode-remote-release/issues)
- [Old VS Code Server Versions](https://code.visualstudio.com/updates/)

## 💡 Notas

- **No actualices** el sistema operativo de las Jetson Nano a Ubuntu 22.04 si quieres mantener la estabilidad del hardware NVIDIA.
- Esta solución usa un servidor VS Code de ~2023 que es estable pero no tendrá las últimas características.
- Si Microsoft cambia la arquitectura del servidor en futuras versiones de VS Code, puede que necesites congelar tu versión de VS Code local.

## 🔄 Alternativas

Si esta solución no funciona a largo plazo:

1. **Code Server**: Instalar [code-server](https://github.com/coder/code-server) en la Jetson y acceder vía navegador
2. **Docker Dev Container**: Usar un contenedor con una versión compatible de GLIBC
3. **SSHFS + VS Code local**: Montar el sistema de archivos remotamente y editar localmente
4. **Actualizar a Ubuntu 22.04**: Último recurso (puede romper drivers NVIDIA)

---

**Última actualización**: Febrero 2026
