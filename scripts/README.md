# 🔧 Scripts del MiniCluster

Esta carpeta contiene scripts útiles para la configuración y mantenimiento del cluster.

## 📜 Scripts Disponibles

### Para Windows (PowerShell)

#### `configurar-hosts.ps1`
Configura automáticamente el archivo hosts de Windows para resolver nombres del cluster.

**Uso**:
```powershell
# Ejecutar como Administrador
.\scripts\configurar-hosts.ps1
```

**Qué hace**:
- Crea backup automático del archivo hosts
- Añade entradas para todos los nodos del cluster:
  - jetson-01, jetson-02, jetson-03
  - rpi-02, rpi-03, rpi-05
- Limpia cache DNS de Windows
- Permite acceder a los nodos por nombre: `ssh jetson-01`

**Requisitos**:
- PowerShell ejecutado como Administrador
- Tailscale conectado (para acceder vía subnet routing)

---

### Para Linux (Bash)

#### `remove-tailscale-workers.sh`
Detiene y deshabilita Tailscale en nodos workers del cluster.

**Uso**:
```bash
# Copiar a cada worker y ejecutar
scp scripts/remove-tailscale-workers.sh jetson-01:~
ssh jetson-01
./remove-tailscale-workers.sh
```

**Qué hace**:
- Detiene la conexión Tailscale (`tailscale down`)
- Para el servicio tailscaled
- Deshabilita el arranque automático
- Verifica el estado final

**Cuándo usarlo**:
- Cuando quieres que el nodo acceda a Tailscale solo vía subnet routing
- Para simplificar la arquitectura (un solo nodo con Tailscale activo)

**Nota**: No desinstala Tailscale, solo lo deja inactivo. Para desinstalar:
```bash
sudo apt remove tailscale -y
```

---

## 📄 Archivos de Configuración

### `hosts-minicluster.txt`
Template con todas las entradas del cluster para archivo hosts.

**Contenido**:
```
# Mini-cluster
192.168.50.11   jetson-01
192.168.50.12   jetson-02
192.168.50.13   jetson-03
192.168.50.1    rpi-02 gateway
192.168.50.23   rpi-03
192.168.50.25   rpi-05
```

**Cuándo usarlo**:
- Como referencia para configuración manual
- En sistemas que no sean Windows (Linux/macOS: añadir a `/etc/hosts`)

**En Linux/macOS**:
```bash
# Añadir al archivo hosts
sudo cat scripts/hosts-minicluster.txt >> /etc/hosts
```

---

## 📚 Documentación Relacionada

- **[INSTRUCCIONES-REMOVER-TAILSCALE.md](INSTRUCCIONES-REMOVER-TAILSCALE.md)** - Guía completa paso a paso para remover Tailscale de workers
  - Incluye todos los nodos (jetson-01/02/03, rpi-03, rpi-05)
  - Verificaciones post-remoción
  - Restauración de DNS local

## 🎯 Flujo de Trabajo Típico

### Configurar nuevo PC Windows para acceder al cluster

1. Instalar Tailscale y conectar
2. Ejecutar `configurar-hosts.ps1` como Administrador
3. Probar conectividad: `ping jetson-01`
4. Conectar por SSH: `ssh jetson-01`

### Simplificar arquitectura Tailscale en el cluster

1. Configurar rpi-02 como subnet router (ver [../rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md](../rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md))
2. Copiar `remove-tailscale-workers.sh` a cada worker
3. Ejecutar el script en cada worker
4. Verificar conectividad desde PC vía subnet routing
5. Configurar hosts en Windows con `configurar-hosts.ps1`

## ⚠️ Notas Importantes

### Sobre configurar-hosts.ps1
- **Requiere permisos de Administrador**: Click derecho → "Ejecutar como administrador"
- **Crea backups automáticos**: No perderás configuración anterior
- **Es idempotente**: Puedes ejecutarlo múltiples veces sin problemas

### Sobre remove-tailscale-workers.sh
- **No elimina Tailscale**: Solo lo desactiva
- **Reversible**: Puedes reactivar con `sudo systemctl enable --now tailscaled`
- **Requiere DNS alternativo**: Asegúrate que el nodo tenga DNS configurado (ej: 192.168.50.1)

## 🔗 Enlaces Útiles

- [Documentación principal del proyecto](../README.md)
- [Configuración Tailscale Subnet Router](../rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)
- [Cómo funciona el routing](../docs/COMO-FUNCIONA-EL-ROUTING.md)
- [Resolución completa del problema](../docs/RESOLUCION-COMPLETA.md)

---

**Mantenido por**: Alejandro Almeida  
**Última actualización**: Febrero 2026
