# Inicio Rápido - VS Code Remote SSH para Jetson Nano

## 🎯 Objetivo

Conectar VS Code desde tu PC Windows a las Jetson Nano que tienen GLIBC 2.27 (incompatible con servidores modernos).

## ⚡ Pasos Rápidos

### 1. En la Jetson (Servidor)

```bash
# Clonar repositorio (si no lo has hecho)
cd ~
git clone https://github.com/alejandrolmeida/minicluster.git

# Instalar servidor compatible
cd ~/minicluster/jetson-01
chmod +x scripts/*.sh
./scripts/install-vscode-server.sh
```

### 2. En tu PC Windows (Cliente)

#### A. Configura VS Code Settings

1. Abre VS Code
2. Presiona `Ctrl+Shift+P`
3. Escribe: `Preferences: Open User Settings (JSON)`
4. Añade esta configuración:

```json
{
  "remote.SSH.serverInstallPath": {
    "jetson-01": "/home/alejandrolmeida/.vscode-server-legacy",
    "jetson-02": "/home/alejandrolmeida/.vscode-server-legacy",
    "jetson-03": "/home/alejandrolmeida/.vscode-server-legacy"
  },
  "remote.SSH.remotePlatform": {
    "jetson-01": "linux",
    "jetson-02": "linux",
    "jetson-03": "linux"
  }
}
```

(Puedes copiar desde `jetson-01/configs/vscode-settings-example.json`)

#### B. Crear Symlink (Si es necesario)

Si VS Code espera un commit diferente, ejecuta desde PowerShell:

```powershell
cd C:\Users\aleja\minicluster\jetson-01\scripts
.\create-symlinks.ps1
```

### 3. Conectar

1. En VS Code: `F1`
2. Escribe: `Remote-SSH: Connect to Host`
3. Selecciona: `jetson-01`
4. ¡Listo! 🎉

## 🐛 ¿No funciona?

### Verificar en la Jetson

```bash
cd ~/minicluster/jetson-01
./scripts/verify-setup.sh
```

### Ver Troubleshooting

- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- [docs/VSCODE_REMOTE_SSH.md](docs/VSCODE_REMOTE_SSH.md)

## 📚 Documentación Completa

| Archivo | Descripción |
|---------|-------------|
| [README.md](../README.md) | Información general |
| [docs/VSCODE_REMOTE_SSH.md](docs/VSCODE_REMOTE_SSH.md) | Guía completa del problema y solución |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Solución de problemas comunes |

## 🔧 Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `scripts/install-vscode-server.sh` | Instala servidor compatible |
| `scripts/verify-setup.sh` | Verifica la configuración |
| `scripts/create-symlinks.ps1` | Crea symlinks (Windows PowerShell) |

---

💡 **Tip**: Ejecuta `verify-setup.sh` periódicamente para asegurarte de que todo esté configurado correctamente.
