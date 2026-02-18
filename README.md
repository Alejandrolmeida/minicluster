# MiniCluster - Raspberry Pi + Jetson Nano

Configuración y documentación completa de un mini cluster de computación edge compuesto por:
- 3x Raspberry Pi (rpi-02, rpi-03, rpi-05)
- 3x NVIDIA Jetson Nano (jetson-01, jetson-02, jetson-03)

## 📋 Arquitectura del Cluster

```
                        Internet
                           |
                    +------+------+
                    |   Router    |
                    | 192.168.18.1|
                    +------+------+
                           |
                    ┌──────┴──────┐
                    |             |
              ┌─────┴────┐   ┌───┴────┐
              |  rpi-02  |   |  WiFi  |
              | Gateway  |   | Backup |
              |  eth1    |   | wlan0  |
              └─────┬────┘   └────────┘
                    |
        ┌───────────┴────Cluster LAN (192.168.50.0/24)
        |           |
   ┌────┴───┐  ┌───┴────┐ 
   | Switch |  |  eth0  |
   |  .2    |  |  .1    |
   └────┬───┘  └────────┘
        |
   ┌────┴──────────────────────────┐
   |    |      |      |      |      |
.11   .12    .13    .23    .25     ...
jetson jetson jetson rpi   rpi
 -01   -02    -03   -03   -05
```

## 🖥️ Dispositivos

| Dispositivo | IP Cluster LAN | Rol | Tailscale | Estado |
|-------------|----------------|-----|-----------|--------|
| **rpi-02** | 192.168.50.1 | Gateway/DHCP/DNS/VPN | ✅ Subnet Router | 🟢 Operativo |
| **rpi-03** | 192.168.50.23 | Worker | ❌ Sin Tailscale | 🟢 Operativo |
| **rpi-05** | 192.168.50.25 | Worker | ❌ Sin Tailscale | 🟢 Operativo |
| **jetson-01** | 192.168.50.11 | Compute GPU | ❌ Sin Tailscale | 🟢 Operativo |
| **jetson-02** | 192.168.50.12 | Compute GPU | ❌ Sin Tailscale | 🟢 Operativo |
| **jetson-03** | 192.168.50.13 | Compute GPU | ❌ Sin Tailscale | 🟢 Operativo |

> **📡 Acceso Remoto**: Todos los nodos son accesibles vía Tailscale subnet routing a través de rpi-02. No necesitan Tailscale instalado individualmente.

> **⚠️ Nota sobre Jetson Nano**: Las Jetson Nano tienen GLIBC 2.27, incompatible con VS Code Server moderno. Ver [jetson-01/docs/VSCODE_REMOTE_SSH.md](jetson-01/docs/VSCODE_REMOTE_SSH.md) para configuración.

## 🌐 Red y Conectividad

### Red Principal (WAN)
- **Proveedor**: ISP doméstico
- **Router**: 192.168.18.1
- **Conexión primaria**: Cable (eth1)
- **Conexión backup**: WiFi (wlan0)
- **Failover**: Automático en ~31 segundos

### Red Cluster (LAN)
- **Rango**: 192.168.50.0/24
- **Gateway**: rpi-02 (192.168.50.1)
- **DHCP**: dnsmasq en rpi-02
- **DNS Local**: cluster.lan
- **DHCP Range**: .50 - .150

### VPN (Tailscale) - Subnet Routing

**Arquitectura Simplificada**:
- **Subnet Router**: Solo rpi-02 tiene Tailscale activo
- **Workers**: Accesibles vía subnet routing (192.168.50.0/24)
- **Red Tailscale**: 100.64.0.0/10
- **Subnet anunciada**: 192.168.50.0/24 (todo el cluster)
- **DNS**: Archivo hosts en clientes o MagicDNS apuntando a rpi-02

**Ventajas**:
- ✅ Un solo punto de configuración VPN
- ✅ Simplicidad: Workers sin Tailscale
- ✅ Aprovecha NAT existente de rpi-02
- ✅ Acceso remoto a todos los nodos
- ✅ Sin overhead VPN en workers

**Acceso desde PC/Móvil**:
```
PC con Tailscale → rpi-02 (subnet router) → 192.168.50.0/24 → Todos los nodos
```

📚 **Documentación completa**: [docs/COMO-FUNCIONA-EL-ROUTING.md](docs/COMO-FUNCIONA-EL-ROUTING.md)

## 🔧 Servicios del Cluster

### rpi-02 (Gateway)
- ✅ DHCP Server (dnsmasq)
- ✅ DNS Server (dnsmasq) para cluster.local
- ✅ WAN Failover (eth1 ⟷ wlan0) - ~31 segundos
- ✅ NAT/Firewall (nftables)
- ✅ Tailscale Subnet Router (anuncia 192.168.50.0/24)
- ✅ SSH Server
- ⏳ Kubernetes Master (planificado)

### Workers (jetson-01/02/03, rpi-03, rpi-05)
- ✅ SSH Server
- ✅ Conectividad completa (Internet + LAN)
- ✅ Accesibles vía Tailscale subnet routing
- ⏳ Kubernetes Workers (planificado)
- ⏳ Container Runtime (planificado)
- ⏳ Monitoring agents (planificado)

## 📂 Estructura del Repositorio

```
minicluster/
├── README.md                 # Este archivo
├── docs/                     # Documentación técnica del proyecto
│   ├── README.md            # Índice de documentación
│   ├── RESOLUCION-COMPLETA.md      # Solución completa problema internet
│   ├── COMO-FUNCIONA-EL-ROUTING.md # Explicación routing Tailscale
│   ├── CONFIGURACION-TAILSCALE-COMPLETADA.md  # Estado Tailscale
│   └── SOLUCION-INTERNET-JETSON.md # Análisis técnico DNS
├── scripts/                  # Scripts de configuración
│   ├── README.md            # Documentación de scripts
│   ├── configurar-hosts.ps1 # Configurar hosts en Windows
│   ├── remove-tailscale-workers.sh  # Remover Tailscale de workers
│   ├── hosts-minicluster.txt        # Template archivo hosts
│   └── INSTRUCCIONES-REMOVER-TAILSCALE.md  # Guía paso a paso
├── rpi-02/                   # Raspberry Pi 02 (Gateway)
│   ├── README.md            # Documentación específica
│   ├── configs/             # Archivos de configuración
│   ├── scripts/             # Scripts de instalación
│   └── docs/                # Documentación adicional
│       ├── INSTALACION_DESDE_CERO.md
│       └── TAILSCALE_SUBNET_ROUTER.md
├── jetson-01/                # Jetson Nano 01
│   ├── README.md            # Documentación específica
│   ├── configs/             # Configuraciones
│   ├── scripts/             # Scripts útiles
│   └── docs/                # Guías y documentación
│       ├── VSCODE_REMOTE_SSH.md
│       ├── QUICKSTART.md
│       └── TROUBLESHOOTING.md
├── jetson-02/                # Jetson Nano 02
├── jetson-03/                # Jetson Nano 03
├── rpi-03/                   # Raspberry Pi 03
└── rpi-05/                   # Raspberry Pi 05
```

## 🚀 Inicio Rápido

### Prerrequisitos
- Raspberry Pi OS Bookworm (64-bit) o Ubuntu 20.04+ para Jetson
- Acceso SSH configurado
- Conexión a internet

### Configurar un nodo

1. Clona este repositorio:
```bash
git clone https://github.com/alejandrolmeida/minicluster.git
cd minicluster
```

2. Ve al directorio del dispositivo:
```bash
cd rpi-02  # o cualquier otro nodo
```

3. Lee el README específico del dispositivo

4. Ejecuta el script de instalación:
```bash
sudo ./scripts/install.sh
```

## 📝 Documentación

### 📚 Documentación Principal
- **[docs/](docs/)** - Documentación técnica completa
  - [Resolución completa del problema de internet](docs/RESOLUCION-COMPLETA.md)
  - [Cómo funciona el routing con Tailscale](docs/COMO-FUNCIONA-EL-ROUTING.md)
  - [Estado de configuración Tailscale](docs/CONFIGURACION-TAILSCALE-COMPLETADA.md)
  - [Análisis técnico del problema DNS](docs/SOLUCION-INTERNET-JETSON.md)

### 🔧 Scripts y Herramientas
- **[scripts/](scripts/)** - Scripts de configuración y mantenimiento
  - [Configurar hosts en Windows](scripts/configurar-hosts.ps1)
  - [Remover Tailscale de workers](scripts/remove-tailscale-workers.sh)
  - [Instrucciones paso a paso](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)

### 📖 Documentación por Nodo

#### Raspberry Pi
- **rpi-02 (Gateway)**: [rpi-02/README.md](rpi-02/README.md)
  - [Instalación desde cero](rpi-02/docs/INSTALACION_DESDE_CERO.md)
  - [Configuración Tailscale Subnet Router](rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)

#### Jetson Nano
- **jetson-01**: [jetson-01/README.md](jetson-01/README.md)
  - [VS Code Remote SSH (GLIBC 2.27)](jetson-01/docs/VSCODE_REMOTE_SSH.md)
  - [Inicio Rápido](jetson-01/docs/QUICKSTART.md)
  - [Troubleshooting](jetson-01/docs/TROUBLESHOOTING.md)

## 💻 Desarrollo Remoto

### VS Code Remote SSH en Jetson Nano

Las Jetson Nano requieren configuración especial debido a incompatibilidad de GLIBC:

```bash
# En la Jetson
cd ~/minicluster/jetson-01
./scripts/install-vscode-server.sh
```

Luego configura tu `settings.json` en VS Code:

```json
{
  "remote.SSH.serverInstallPath": {
    "jetson-01": "/home/alejandrolmeida/.vscode-server-legacy"
  }
}
```

📚 **Ver guía completa**: [jetson-01/docs/VSCODE_REMOTE_SSH.md](jetson-01/docs/VSCODE_REMOTE_SSH.md)

## 🔐 Seguridad

- ✅ SSH con autenticación por clave pública únicamente
- ✅ Firewall (nftables) configurado
- ✅ VPN (Tailscale) para acceso remoto seguro
- ⏳ Fail2ban (planificado)
- ⏳ Certificados SSL (planificado)

## 🛠️ Tecnologías Utilizadas

- **OS**: Raspbian GNU/Linux 12 (bookworm) / Ubuntu 20.04
- **Networking**: systemd-networkd
- **DNS/DHCP**: dnsmasq
- **VPN**: Tailscale
- **Container Runtime**: Docker (planificado)
- **Orchestration**: Kubernetes (planificado)
- **Monitoring**: Prometheus + Grafana (planificado)

## 📊 Estado del Proyecto

### ✅ Completado
- [x] Nodo Gateway (rpi-02) completamente configurado
  - [x] Dual WAN con failover automático (~31s)
  - [x] DHCP/DNS Server para cluster.local
  - [x] NAT y firewall (nftables)
  - [x] Tailscale Subnet Router operativo
- [x] Red del Cluster funcional
  - [x] Todos los nodos con conectividad completa
  - [x] Internet funcionando en todos los workers
  - [x] Acceso remoto vía Tailscale
- [x] VS Code Remote SSH para Jetson Nano
  - [x] Servidor compatible instalado (GLIBC 2.27)
  - [x] Documentación completa
  - [x] Scripts de instalación automatizados
- [x] Documentación técnica
  - [x] Arquitectura de red documentada
  - [x] Troubleshooting y soluciones
  - [x] Scripts organizados y comentados

### 🚧 En Progreso / Planificado
- [ ] Kubernetes cluster
  - [ ] Master en rpi-02
  - [ ] Workers en todos los nodos
  - [ ] Almacenamiento distribuido (Longhorn/Ceph)
- [ ] Monitoring stack
  - [ ] Prometheus + Grafana
  - [ ] Node exporters
  - [ ] Alerting
- [ ] CI/CD pipeline
- [ ] Servicios adicionales (planificados)

### 📈 Métricas Actuales
- **Nodos operativos**: 6/6 (100%)
- **Conectividad**: 100% (9-19ms latencia vía Tailscale)
- **Pérdida de paquetes**: 0%
- **Internet**: Funcional en todos los nodos
- **DNS**: Resuelto (archivo hosts + dnsmasq)

## 🤝 Contribuciones

Este es un proyecto personal de aprendizaje, pero las sugerencias y mejoras son bienvenidas.

## 📜 Licencia

MIT License - Siéntete libre de usar y modificar este código.

## 👤 Autor

**Alejandro Almeida**
- GitHub: [@alejandrolmeida](https://github.com/alejandrolmeida)

## 🔗 Enlaces Útiles

### Documentación del Proyecto
- **General**:
  - [Documentación técnica completa](docs/)
  - [Resolución del problema de internet](docs/RESOLUCION-COMPLETA.md)
  - [Cómo funciona el routing](docs/COMO-FUNCIONA-EL-ROUTING.md)
  
- **rpi-02 (Gateway)**:
  - [README rpi-02](rpi-02/README.md)
  - [Instalación desde cero](rpi-02/docs/INSTALACION_DESDE_CERO.md)
  - [Tailscale Subnet Router](rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)

- **Jetson Nano**:
  - [README jetson-01](jetson-01/README.md)
  - [VS Code Remote SSH](jetson-01/docs/VSCODE_REMOTE_SSH.md)
  - [Troubleshooting Jetson](jetson-01/docs/TROUBLESHOOTING.md)

- **Scripts**:
  - [Documentación de scripts](scripts/)
  - [Remover Tailscale de workers](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)

### Referencias Externas
- [Documentación Raspberry Pi](https://www.raspberrypi.org/documentation/)
- [Documentación Jetson Nano](https://developer.nvidia.com/embedded/jetson-nano)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Última actualización**: Febrero 2026
