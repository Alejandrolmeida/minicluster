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

| Dispositivo | IP Cluster LAN | Rol | Estado |
|-------------|----------------|-----|--------|
| **rpi-02** | 192.168.50.1 | Gateway/DHCP/DNS | 🟢 Configurado |
| **rpi-03** | 192.168.50.23 | Worker | ⚪ Pendiente |
| **rpi-05** | 192.168.50.25 | Worker | ⚪ Pendiente |
| **jetson-01** | 192.168.50.11 | Compute | ⚪ Pendiente |
| **jetson-02** | 192.168.50.12 | Compute | ⚪ Pendiente |
| **jetson-03** | 192.168.50.13 | Compute | ⚪ Pendiente |

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

### VPN (Tailscale)
- **Red**: 100.64.0.0/10
- **Acceso remoto**: Habilitado en todos los nodos
- **Exit node**: No configurado

## 🔧 Servicios del Cluster

### rpi-02 (Gateway)
- ✅ DHCP Server (dnsmasq)
- ✅ DNS Server (dnsmasq)
- ✅ WAN Failover (eth1 ⟷ wlan0)
- ✅ Tailscale VPN
- ✅ SSH Server
- ⏳ Kubernetes Master (planificado)

### Otros Nodos
- ⏳ Kubernetes Workers (planificado)
- ⏳ Container Runtime (planificado)
- ⏳ Monitoring (planificado)

## 📂 Estructura del Repositorio

```
minicluster/
├── README.md                 # Este archivo
├── rpi-02/                   # Raspberry Pi 02 (Gateway)
│   ├── README.md            # Documentación específica
│   ├── configs/             # Archivos de configuración
│   ├── scripts/             # Scripts de instalación
│   └── docs/                # Documentación adicional
├── rpi-03/                   # Raspberry Pi 03
├── rpi-05/                   # Raspberry Pi 05
├── jetson-01/                # Jetson Nano 01
├── jetson-02/                # Jetson Nano 02
└── jetson-03/                # Jetson Nano 03
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

Cada dispositivo tiene su propia carpeta con:
- **README.md**: Guía específica de configuración
- **configs/**: Archivos de configuración del sistema
- **scripts/**: Scripts de instalación y mantenimiento
- **docs/**: Documentación adicional y notas

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

- [x] Nodo Gateway (rpi-02) configurado
  - [x] Dual WAN con failover automático
  - [x] DHCP/DNS Server
  - [x] Tailscale VPN
- [ ] Nodos worker configurados
- [ ] Kubernetes desplegado
- [ ] Almacenamiento distribuido
- [ ] Monitoring stack
- [ ] CI/CD pipeline

## 🤝 Contribuciones

Este es un proyecto personal de aprendizaje, pero las sugerencias y mejoras son bienvenidas.

## 📜 Licencia

MIT License - Siéntete libre de usar y modificar este código.

## 👤 Autor

**Alejandro Almeida**
- GitHub: [@alejandrolmeida](https://github.com/alejandrolmeida)

## 🔗 Enlaces Útiles

- [Documentación Raspberry Pi](https://www.raspberrypi.org/documentation/)
- [Documentación Jetson Nano](https://developer.nvidia.com/embedded/jetson-nano)
- [Tailscale Docs](https://tailscale.com/kb/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

---

**Última actualización**: Febrero 2026
