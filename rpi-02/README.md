# RPI-02 - Gateway del Minicluster

## 📋 Descripción

**rpi-02** es el gateway principal del minicluster. Proporciona conectividad a Internet para todos los nodos y servicios de red críticos.

### Funciones Principales

- 🌐 **Gateway/Router**: Conectividad a Internet para el cluster
- 🔁 **DHCP Server**: Asignación automática de IPs a los nodos
- 📡 **DNS Server**: Resolución de nombres en `.cluster.local`
- 🔒 **Firewall**: NAT y filtrado de tráfico con nftables
- 🔄 **WAN Failover**: Cambio automático entre Ethernet y WiFi
- 🔐 **VPN Subnet Router**: Tailscale subnet router (anuncia 192.168.50.0/24)

## 🖧 Configuración de Red

### Interfaces

| Interfaz | Función | Red | IP |
|----------|---------|-----|-----|
| `eth0` | LAN (cluster) | `192.168.50.0/24` | `192.168.50.1` (estática) |
| `eth1` | WAN primaria (cable) | DHCP del router | Dinámica |
| `wlan0` | WAN backup (WiFi) | DHCP del router | Dinámica |
| `tailscale0` | VPN | `100.x.x.x/32` | Asignada por Tailscale |

### Rango DHCP

- **Pool dinámico**: `192.168.50.50` - `192.168.50.150`
- **IPs reservadas**: `192.168.50.1` - `192.168.50.49`
- **Lease time**: 12 horas

### Nodos del Cluster

Ver [configs/dnsmasq/cluster.hosts](configs/dnsmasq/cluster.hosts) para la lista completa de nodos y sus IPs estáticas.

## 🚀 Instalación

### Opción 1: Instalación Automatizada (Recomendada)

```bash
# Clonar el repositorio
git clone https://github.com/alejandrolmeida/minicluster.git
cd minicluster/rpi-02

# Ejecutar script de instalación
sudo ./scripts/install.sh
```

### Opción 2: Instalación Manual

Seguir la guía completa en [docs/INSTALACION_DESDE_CERO.md](docs/INSTALACION_DESDE_CERO.md)

## 📁 Estructura de Archivos

```
rpi-02/
├── README.md                          # Este archivo
├── configs/                           # Archivos de configuración
│   ├── network/                       # systemd-networkd
│   │   ├── 10-eth0-lan.network       # LAN del cluster
│   │   ├── 20-eth1-wan.network       # WAN primaria (cable)
│   │   └── 30-wlan0-wan-backup.network # WAN backup (WiFi)
│   ├── dnsmasq/                       # DHCP/DNS
│   │   ├── dnsmasq.conf              # Configuración principal
│   │   └── cluster.hosts             # Hosts estáticos del cluster
│   ├── firewall/                      # nftables
│   │   └── nftables.conf             # Reglas de firewall (referencia)
│   ├── nftables.d/                    # nftables modular
│   │   └── cluster-nat.conf          # NAT para cluster LAN
│   ├── systemd/                       # Servicios systemd
│   │   ├── cluster-nat.service       # Servicio NAT para cluster LAN
│   │   └── wan-failover.service      # Servicio de failover WAN
│   └── wpa_supplicant/                # WiFi
│       └── wpa_supplicant-wlan0.conf.template  # Template WiFi
├── scripts/                           # Scripts de automatización
│   ├── install.sh                    # Instalación automatizada
│   └── wan-failover.sh               # Script de failover WAN
└── docs/                              # Documentación
    └── INSTALACION_DESDE_CERO.md     # Guía completa de instalación
```

## 🔧 Uso y Mantenimiento

### Verificar Estado de Servicios

```bash
# Red
sudo systemctl status systemd-networkd
ip addr show

# DHCP/DNS
sudo systemctl status dnsmasq
sudo journalctl -u dnsmasq -f

# Firewall
sudo systemctl status nftables
sudo nft list ruleset

# WAN Failover
sudo systemctl status wan-failover
sudo journalctl -u wan-failover -f

# Tailscale VPN
sudo tailscale status
```

### Probar Failover WAN

```bash
# Monitorear logs
sudo journalctl -u wan-failover -f

# Desconectar cable eth1 (WAN)
# El sistema debería cambiar a wlan0 en ~31 segundos

# Reconectar cable eth1
# El sistema debería volver a eth1 en ~31 segundos
```

### Ver Leases DHCP

```bash
# Ver leases activos
cat /var/lib/misc/dnsmasq.leases

# O con dnsmasq en modo log
sudo journalctl -u dnsmasq | grep DHCP
```

### Actualizar Configuraciones

```bash
# Después de editar configuraciones, recargar servicios
sudo systemctl restart systemd-networkd  # Red
sudo systemctl restart dnsmasq          # DHCP/DNS
sudo systemctl reload nftables          # Firewall
sudo systemctl restart wan-failover     # Failover
```

## 🔍 Troubleshooting

### No hay Internet en los nodos del cluster

```bash
# 1. Verificar IP forwarding
sysctl net.ipv4.ip_forward  # Debe ser 1

# 2. Verificar NAT (debe mostrar regla para 192.168.50.0/24)
sudo nft list table ip nat

# 3. Verificar servicio cluster-nat
sudo systemctl status cluster-nat

# 4. Si falta la regla NAT, reiniciar el servicio
sudo systemctl restart cluster-nat

# 5. Verificar rutas
ip route show

# 6. Verificar conectividad del gateway
ping -c 3 8.8.8.8
```

### DHCP no funciona

```bash
# Verificar que dnsmasq está escuchando en eth0
sudo ss -tulnp | grep dnsmasq

# Ver logs de dnsmasq
sudo journalctl -u dnsmasq -f

# Verificar configuración
sudo dnsmasq --test
```

### Failover no cambia

```bash
# Ver logs del servicio
sudo journalctl -u wan-failover -f

# Verificar conectividad de cada interfaz
ping -I eth1 -c 3 8.8.8.8
ping -I wlan0 -c 3 8.8.8.8

# Verificar que las interfaces están UP
ip link show eth1
ip link show wlan0
```

### WiFi no conecta

```bash
# Ver estado de wlan0
ip addr show wlan0

# Ver logs de wpa_supplicant
sudo journalctl -u wpa_supplicant@wlan0 -f

# Escanear redes disponibles
sudo iwlist wlan0 scan | grep ESSID
```

## 📊 Monitoreo

### Recursos del Sistema

```bash
# CPU y memoria
htop

# Red
iftop -i eth0      # Tráfico LAN
iftop -i eth1      # Tráfico WAN

# Disco I/O
iotop
```

### Logs del Sistema

```bash
# journald
sudo journalctl -xe           # Todos los logs
sudo journalctl -u SERVICE    # Logs de un servicio
sudo journalctl -f            # Seguir logs en tiempo real
sudo journalctl --since "1 hour ago"  # Última hora
```

## 🔐 Seguridad

### Recomendaciones

- ✅ Usar autenticación SSH por clave pública
- ✅ Deshabilitar login root por SSH
- ✅ Mantener el sistema actualizado
- ✅ Revisar logs regularmente
- ✅ Backup de configuraciones importantes
- ✅ Limitar acceso SSH desde WAN (comentado por defecto en firewall)

### Puertos Abiertos

- **SSH (22)**: Desde LAN y Tailscale
- **DNS (53)**: Desde LAN
- **DHCP (67)**: Desde LAN
- **Tailscale (41641)**: Desde cualquier lugar

## 🔗 Enlaces Útiles

- [Documentación completa](docs/INSTALACION_DESDE_CERO.md)
- [Repositorio del proyecto](https://github.com/alejandrolmeida/minicluster)
- [systemd-networkd](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
- [dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html)
- [nftables](https://wiki.nftables.org/)
- [Tailscale](https://tailscale.com/kb/)

## 📝 Notas

- Este nodo requiere conexión permanente a Internet (WAN)
- Se recomienda UPS para evitar pérdidas de conectividad
- La SD card debería ser de buena calidad (clase 10 o superior)
- Considerar usar SSD vía USB para mayor durabilidad

---

**Última actualización**: Febrero 2026
