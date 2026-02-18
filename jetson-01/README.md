# Jetson-01 - Nodo de Computación

## 📋 Descripción

Jetson Nano configurado para computación edge en el minicluster.

## ⚠️ Problema Conocido: VS Code Remote SSH

### El Problema

Las Jetson Nano con Ubuntu 18.04/20.04 tienen GLIBC 2.27, pero las versiones modernas de VS Code Server requieren GLIBC >= 2.28. Esto causa el error:

```
This machine does not meet Visual Studio Code Server's prerequisites, 
expected GLIBC >= v2.28.0 (but found v2.27.0 instead)
```

### Solución

Usar una versión antigua compatible del servidor VS Code que funcione con GLIBC 2.27.

## 🚀 Instalación del Servidor VS Code Compatible

### Método 1: Script Automático (Recomendado)

```bash
# Desde esta misma jetson
cd ~/minicluster/jetson-01
chmod +x scripts/install-vscode-server.sh
./scripts/install-vscode-server.sh
```

### Método 2: Manual

Ver [docs/VSCODE_REMOTE_SSH.md](docs/VSCODE_REMOTE_SSH.md) para instrucciones detalladas.

## 📊 Especificaciones

- **IP Cluster LAN**: 192.168.50.11
- **Hostname**: jetson-01
- **OS**: Ubuntu 20.04 (ARM64)
- **GLIBC**: 2.27
- **Rol**: Nodo de computación (GPU)

## 🔧 Uso y Mantenimiento

### Conectar con VS Code Remote

1. Asegúrate de tener configurado el `settings.json` (ver docs)
2. En VS Code: `F1` → `Remote-SSH: Connect to Host` → `jetson-01`
3. VS Code usará automáticamente el servidor legacy instalado

### Verificar Estado

```bash
# Ver servidor instalado
ls -la ~/.vscode-server-legacy/bin/

# Ver version de GLIBC
ldd --version
```

## 🔗 Enlaces

- [Documentación completa VS Code Remote](docs/VSCODE_REMOTE_SSH.md)
- [Repositorio del proyecto](https://github.com/alejandrolmeida/minicluster)

---

**Última actualización**: Febrero 2026
