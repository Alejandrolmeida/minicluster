# Instalación desde Cero - RPI-02 Gateway

Esta guía documenta cómo configurar rpi-02 como gateway del minicluster partiendo de una imagen limpia de **Raspberry Pi OS (Legacy) Lite** basado en Debian Bookworm.

## 📋 Requisitos Previos

- Raspberry Pi (modelo 3B+ o superior recomendado)
- Tarjeta microSD (16GB mínimo, 32GB recomendado)
- Acceso a Internet (cable Ethernet y/o WiFi)
- Computadora para preparar la SD card
- Acceso SSH configurado

### Hardware Necesario

- 1x Raspberry Pi
- 1x Tarjeta microSD
- 2x Interfaz de red:
  - `eth0`: Conexión a la red del cluster (LAN)
  - `eth1`: Conexión a Internet (WAN primaria)
  - `wlan0`: WiFi para failover (WAN secundaria)

> **Nota**: La mayoría de Raspberry Pi 3B+ y superiores tienen una sola interfaz Ethernet física (eth0). Para tener eth1, necesitarás un adaptador USB-Ethernet.

## 🚀 Pasos de Instalación

### 1. Preparar la Imagen Base

#### 1.1 Descargar Raspberry Pi OS (Legacy) Lite

```bash
# Descargar desde:
# https://www.raspberrypi.com/software/operating-systems/
# Elegir: "Raspberry Pi OS (Legacy) Lite" - versión Debian Bookworm
```

#### 1.2 Flashear la SD Card

Usar Raspberry Pi Imager o similar:

```bash
# Opción 1: Raspberry Pi Imager (recomendado)
# - Descargar de https://www.raspberrypi.com/software/
# - Seleccionar el OS: Raspberry Pi OS (Legacy) Lite
# - Configurar:
#   - Hostname: rpi-02
#   - Usuario: pi (o el que prefieras)
#   - Habilitar SSH
#   - Configurar WiFi (opcional, para primera conexión)
#   - Locale: es_ES / UTF-8 / Europe/Madrid (o tu zona)

# Opción 2: dd (Linux)
sudo dd if=raspios-bookworm-lite.img of=/dev/sdX bs=4M status=progress
```

#### 1.3 Primera Conexión

Inserta la SD card en la Raspberry Pi, conecta por Ethernet y arranca:

```bash
# Encontrar la IP asignada por tu router
nmap -sn 192.168.18.0/24  # Ajusta a tu red local

# Conectar por SSH
ssh pi@<IP_ASIGNADA>
# Contraseña que configuraste en Pi Imager
```

### 2. Configuración Inicial del Sistema

#### 2.1 Actualizar el Sistema

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

#### 2.2 Instalar Paquetes Básicos

```bash
sudo apt install -y \
    vim \
    git \
    curl \
    wget \
    htop \
    iotop \
    net-tools \
    dnsutils \
    tcpdump \
    iperf3 \
    ethtool \
    rsync
```

#### 2.3 Configurar Hostname

```bash
sudo hostnamectl set-hostname rpi-02
sudo sed -i 's/127.0.1.1.*/127.0.1.1\trpi-02/' /etc/hosts
```

#### 2.4 Configurar Timezone y Locale

```bash
sudo timedatectl set-timezone Europe/Madrid  # Ajusta a tu zona
sudo localectl set-locale LANG=es_ES.UTF-8
```

### 3. Configuración de Red

#### 3.1 Desactivar dhcpcd (usar systemd-networkd)

```bash
sudo systemctl disable dhcpcd
sudo systemctl stop dhcpcd
```

#### 3.2 Habilitar systemd-networkd

```bash
sudo systemctl enable systemd-networkd
sudo systemctl enable systemd-resolved
```

#### 3.3 Crear Configuraciones de Red

Copiar los archivos de configuración del repositorio:

```bash
# Asumiendo que ya clonaste el repositorio
cd ~/minicluster/rpi-02

# Copiar configuraciones de red
sudo cp configs/network/10-eth0-lan.network /etc/systemd/network/
sudo cp configs/network/20-eth1-wan.network /etc/systemd/network/
sudo cp configs/network/30-wlan0-wan-backup.network /etc/systemd/network/
```

O crearlos manualmente (ver sección [Archivos de Configuración](#archivos-de-configuración)).

#### 3.4 Configurar WiFi WPA

```bash
# Editar credenciales WiFi
sudo vim /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Contenido:
ctrl_interface=/run/wpa_supplicant
update_config=1
country=ES

network={
    ssid="TU_SSID_WIFI"
    psk="TU_PASSWORD_WIFI"
    priority=1
}
```

```bash
# Habilitar el servicio
sudo systemctl enable wpa_supplicant@wlan0
sudo systemctl start wpa_supplicant@wlan0
```

#### 3.5 Habilitar IP Forwarding

```bash
# Editar /etc/sysctl.conf
sudo vim /etc/sysctl.conf

# Descomentar o añadir:
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Aplicar cambios
sudo sysctl -p
```

#### 3.6 Reiniciar Network Services

```bash
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved
```

### 4. Configuración de DHCP/DNS (dnsmasq)

#### 4.1 Instalar dnsmasq

```bash
sudo apt install -y dnsmasq
```

#### 4.2 Configurar dnsmasq

```bash
# Backup de configuración original
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup

# Copiar configuración del repositorio
sudo cp ~/minicluster/rpi-02/configs/dnsmasq/dnsmasq.conf /etc/dnsmasq.conf
```

#### 4.3 Crear archivo de hosts estáticos

```bash
sudo cp ~/minicluster/rpi-02/configs/dnsmasq/cluster.hosts /etc/dnsmasq.d/
```

#### 4.4 Habilitar y reiniciar dnsmasq

```bash
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq
```

#### 4.5 Verificar

```bash
# Ver estado
sudo systemctl status dnsmasq

# Ver logs
sudo journalctl -u dnsmasq -f

# Probar DHCP (desde otro nodo conectado a eth0)
# Debería obtener una IP en el rango 192.168.50.50-150
```

### 5. Configuración del Firewall (nftables)

#### 5.1 Instalar nftables

```bash
sudo apt install -y nftables
```

#### 5.2 Crear reglas de firewall

```bash
# Copiar configuración
sudo cp ~/minicluster/rpi-02/configs/firewall/nftables.conf /etc/nftables.conf
```

#### 5.3 Habilitar el firewall

```bash
sudo systemctl enable nftables
sudo systemctl restart nftables
```

#### 5.4 Verificar reglas

```bash
sudo nft list ruleset
```

### 6. Script de Failover WAN

#### 6.1 Instalar el script

```bash
# Copiar script
sudo cp ~/minicluster/rpi-02/scripts/wan-failover.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wan-failover.sh
```

#### 6.2 Crear servicio systemd

```bash
sudo cp ~/minicluster/rpi-02/configs/systemd/wan-failover.service /etc/systemd/system/
```

#### 6.3 Habilitar el servicio

```bash
sudo systemctl daemon-reload
sudo systemctl enable wan-failover
sudo systemctl start wan-failover
```

#### 6.4 Verificar funcionamiento

```bash
# Ver estado
sudo systemctl status wan-failover

# Ver logs
sudo journalctl -u wan-failover -f

# Probar desconectando el cable eth1
# Debería cambiar a wlan0 en ~31 segundos
```

### 7. Configuración de Tailscale VPN

#### 7.1 Instalar Tailscale

```bash
# Añadir repositorio oficial
curl -fsSL https://tailscale.com/install.sh | sh
```

#### 7.2 Autenticar con Tailscale

```bash
sudo tailscale up --accept-routes --advertise-routes=192.168.50.0/24
```

Esto abrirá un enlace en el navegador para autenticar con tu cuenta de Tailscale.

#### 7.3 Habilitar subnet routes (en el panel de Tailscale)

1. Ve a https://login.tailscale.com/admin/machines
2. Encuentra rpi-02 en la lista
3. Clic en los tres puntos → "Edit route settings"
4. Aprobar la ruta 192.168.50.0/24

#### 7.4 Verificar

```bash
# Ver estado
sudo tailscale status

# Ver IP de Tailscale
sudo tailscale ip
```

### 8. Configuración de SSH

#### 8.1 Configurar claves SSH (recomendado)

```bash
# En tu computadora local, genera una clave (si no tienes una)
ssh-keygen -t ed25519 -C "tu_email@example.com"

# Copiar clave pública a rpi-02
ssh-copy-id pi@<IP_RPI02>
```

#### 8.2 Endurecer configuración SSH

```bash
# Editar /etc/ssh/sshd_config
sudo vim /etc/ssh/sshd_config

# Configuración recomendada:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
MaxSessions 5

# Reiniciar SSH
sudo systemctl restart ssh
```

### 9. Configuración de Logs y Monitoreo

#### 9.1 Configurar journald

```bash
# Editar /etc/systemd/journald.conf
sudo vim /etc/systemd/journald.conf

# Configuración recomendada:
Storage=persistent
SystemMaxUse=500M
SystemKeepFree=1G
RuntimeMaxUse=100M

# Reiniciar journald
sudo systemctl restart systemd-journald
```

#### 9.2 Instalar y configurar logrotate (ya viene instalado)

```bash
# Verificar configuración
cat /etc/logrotate.conf
ls /etc/logrotate.d/
```

### 10. Optimizaciones Opcionales

#### 10.1 Deshabilitar servicios innecesarios

```bash
# Bluetooth (si no lo usas)
sudo systemctl disable bluetooth
sudo systemctl disable hciuart

# Servicios de audio (si no los usas)
sudo systemctl disable alsa-state
```

#### 10.2 Reducir uso de memoria GPU

Si no usas interfaz gráfica:

```bash
sudo vim /boot/config.txt

# Añadir:
gpu_mem=16
```

#### 10.3 Configurar límites de swap

```bash
# Ver swap actual
free -h

# Editar configuración
sudo vim /etc/dphys-swapfile

# Configuración recomendada:
CONF_SWAPSIZE=1024  # 1GB

# Reiniciar swap
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### 11. Verificación Final

#### 11.1 Checklist de Configuración

```bash
# Red eth0 (LAN) - debe tener IP estática 192.168.50.1
ip addr show eth0

# Red eth1 (WAN primaria) - debe obtener IP por DHCP del router
ip addr show eth1

# Red wlan0 (WAN backup) - debe obtener IP por DHCP del router
ip addr show wlan0

# Rutas
ip route show

# DNS
resolvectl status

# DHCP/DNS Server
sudo systemctl status dnsmasq

# Firewall
sudo nft list ruleset

# WAN Failover
sudo systemctl status wan-failover

# Tailscale
sudo tailscale status

# SSH
sudo systemctl status ssh
```

#### 11.2 Pruebas de Conectividad

```bash
# Desde rpi-02
ping -c 3 8.8.8.8          # Internet
ping -c 3 192.168.50.1     # LAN (a sí mismo)

# Desde otro nodo del cluster conectado a eth0
ping -c 3 192.168.50.1     # Gateway
ping -c 3 8.8.8.8          # Internet a través del gateway

# DNS
nslookup google.com 192.168.50.1
```

#### 11.3 Prueba de Failover WAN

```bash
# Monitorear logs
sudo journalctl -u wan-failover -f

# Desconectar eth1 (cable Ethernet WAN)
# Debería cambiar a wlan0 en ~31 segundos

# Reconectar eth1
# Debería volver a eth1 en ~31 segundos
```

## 📁 Archivos de Configuración

Todos los archivos de configuración se encuentran en las siguientes ubicaciones:

### Network (systemd-networkd)
- `/etc/systemd/network/10-eth0-lan.network`
- `/etc/systemd/network/20-eth1-wan.network`
- `/etc/systemd/network/30-wlan0-wan-backup.network`

### DHCP/DNS (dnsmasq)
- `/etc/dnsmasq.conf`
- `/etc/dnsmasq.d/cluster.hosts`

### Firewall (nftables)
- `/etc/nftables.conf`

### WAN Failover
- `/usr/local/bin/wan-failover.sh`
- `/etc/systemd/system/wan-failover.service`

### WiFi
- `/etc/wpa_supplicant/wpa_supplicant-wlan0.conf`

## 🔧 Mantenimiento

### Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo reboot
```

### Ver logs del sistema

```bash
# Todos los logs del sistema
sudo journalctl -xe

# Logs de un servicio específico
sudo journalctl -u dnsmasq -f
sudo journalctl -u wan-failover -f
sudo journalctl -u nftables -f
```

### Backup de configuraciones

```bash
# Crear directorio de backup
mkdir -p ~/backups/$(date +%Y%m%d)

# Backup de configuraciones críticas
sudo cp /etc/systemd/network/* ~/backups/$(date +%Y%m%d)/
sudo cp /etc/dnsmasq.conf ~/backups/$(date +%Y%m%d)/
sudo cp /etc/nftables.conf ~/backups/$(date +%Y%m%d)/
sudo cp /usr/local/bin/wan-failover.sh ~/backups/$(date +%Y%m%d)/
```

## 🐛 Troubleshooting

### No hay conexión a Internet desde el cluster

```bash
# Verificar IP forwarding
sysctl net.ipv4.ip_forward

# Verificar NAT en firewall
sudo nft list ruleset | grep masquerade

# Verificar rutas
ip route show
```

### DHCP no funciona en el cluster

```bash
# Verificar que dnsmasq está escuchando en eth0
sudo ss -tulnp | grep dnsmasq

# Ver logs de dnsmasq
sudo journalctl -u dnsmasq -f

# Verificar configuración
sudo dnsmasq --test
```

### Failover no funciona

```bash
# Verificar que el servicio está corriendo
sudo systemctl status wan-failover

# Ver logs
sudo journalctl -u wan-failover -f

# Verificar conectividad de cada interfaz
ping -I eth1 -c 3 8.8.8.8
ping -I wlan0 -c 3 8.8.8.8
```

### WiFi no conecta

```bash
# Ver estado de wlan0
ip addr show wlan0

# Ver logs de wpa_supplicant
sudo journalctl -u wpa_supplicant@wlan0 -f

# Escanear redes disponibles
sudo iwlist wlan0 scan | grep ESSID

# Verificar archivo de configuración
sudo cat /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
```

## 📚 Referencias

- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [systemd-networkd](https://www.freedesktop.org/software/systemd/man/systemd.network.html)
- [dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html)
- [nftables wiki](https://wiki.nftables.org/)
- [Tailscale Docs](https://tailscale.com/kb/)

---

**Última actualización**: Febrero 2026
