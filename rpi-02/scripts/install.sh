#!/bin/bash
# Script de instalación automatizada para RPI-02 Gateway
# Minicluster - Setup completo del gateway
# Última actualización: Febrero 2026

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    print_error "Este script debe ejecutarse como root (sudo)"
    exit 1
fi

# Obtener el directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

print_header "Instalación RPI-02 Gateway - Minicluster"
echo "Directorio del repositorio: $REPO_DIR"
echo "Hostname actual: $(hostname)"
echo ""

# Confirmación
read -p "¿Continuar con la instalación? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    print_warning "Instalación cancelada"
    exit 0
fi

# 1. Configurar hostname
print_header "1. Configurando hostname"
if [ "$(hostname)" != "rpi-02" ]; then
    hostnamectl set-hostname rpi-02
    sed -i 's/127.0.1.1.*/127.0.1.1\trpi-02/' /etc/hosts
    print_success "Hostname configurado: rpi-02"
else
    print_info "Hostname ya está configurado"
fi

# 2. Actualizar sistema
print_header "2. Actualizando sistema"
print_info "Esto puede tardar varios minutos..."
apt update
apt upgrade -y
apt autoremove -y
print_success "Sistema actualizado"

# 3. Instalar paquetes necesarios
print_header "3. Instalando paquetes necesarios"
PACKAGES=(
    vim git curl wget htop iotop
    net-tools dnsutils tcpdump iperf3 ethtool rsync
    dnsmasq nftables
)
apt install -y "${PACKAGES[@]}"
print_success "Paquetes instalados"

# 4. Configurar red (systemd-networkd)
print_header "4. Configurando red (systemd-networkd)"

# Desactivar dhcpcd
if systemctl is-enabled dhcpcd &>/dev/null; then
    systemctl disable dhcpcd
    systemctl stop dhcpcd
    print_success "dhcpcd desactivado"
fi

# Habilitar systemd-networkd
systemctl enable systemd-networkd
systemctl enable systemd-resolved
print_success "systemd-networkd habilitado"

# Copiar configuraciones de red
print_info "Copiando configuraciones de red..."
cp "$REPO_DIR/configs/network/"*.network /etc/systemd/network/
chmod 644 /etc/systemd/network/*.network
print_success "Configuraciones de red copiadas"

# 5. Habilitar IP Forwarding
print_header "5. Habilitando IP Forwarding"
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p
    print_success "IP Forwarding habilitado"
else
    print_info "IP Forwarding ya está habilitado"
fi

# 6. Configurar dnsmasq
print_header "6. Configurando dnsmasq"

# Backup de configuración original
if [ -f /etc/dnsmasq.conf ] && [ ! -f /etc/dnsmasq.conf.backup ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
    print_info "Backup de dnsmasq.conf creado"
fi

# Copiar configuraciones
cp "$REPO_DIR/configs/dnsmasq/dnsmasq.conf" /etc/dnsmasq.conf
mkdir -p /etc/dnsmasq.d
cp "$REPO_DIR/configs/dnsmasq/cluster.hosts" /etc/dnsmasq.d/
chmod 644 /etc/dnsmasq.conf
chmod 644 /etc/dnsmasq.d/cluster.hosts

systemctl enable dnsmasq
print_success "dnsmasq configurado"

# 7. Configurar firewall (nftables)
print_header "7. Configurando firewall (nftables)"

# Backup de configuración original
if [ -f /etc/nftables.conf ] && [ ! -f /etc/nftables.conf.backup ]; then
    cp /etc/nftables.conf /etc/nftables.conf.backup
    print_info "Backup de nftables.conf creado"
fi

cp "$REPO_DIR/configs/firewall/nftables.conf" /etc/nftables.conf
chmod 644 /etc/nftables.conf

systemctl enable nftables
print_success "Firewall configurado"

# 8. Instalar script de failover WAN
print_header "8. Instalando script de failover WAN"

cp "$REPO_DIR/scripts/wan-failover.sh" /usr/local/bin/
chmod +x /usr/local/bin/wan-failover.sh
print_success "Script de failover instalado"

cp "$REPO_DIR/configs/systemd/wan-failover.service" /etc/systemd/system/
chmod 644 /etc/systemd/system/wan-failover.service

systemctl daemon-reload
systemctl enable wan-failover
print_success "Servicio de failover habilitado"

# 9. Configurar WiFi (opcional)
print_header "9. Configuración WiFi (WAN Backup)"

if [ -f "$REPO_DIR/configs/wpa_supplicant/wpa_supplicant-wlan0.conf.template" ]; then
    print_warning "Configuración WiFi NO instalada automáticamente"
    print_info "Para configurar WiFi:"
    print_info "  1. Editar: $REPO_DIR/configs/wpa_supplicant/wpa_supplicant-wlan0.conf.template"
    print_info "  2. Añadir tu SSID y contraseña WiFi"
    print_info "  3. Copiar a: /etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
    print_info "  4. Ejecutar: sudo systemctl enable wpa_supplicant@wlan0"
    print_info "  5. Ejecutar: sudo systemctl start wpa_supplicant@wlan0"
else
    print_warning "Template de WiFi no encontrado"
fi

# 10. Resumen final
print_header "10. Resumen de instalación"

echo "Servicios configurados:"
print_success "systemd-networkd: Gestión de red"
print_success "dnsmasq: DHCP/DNS server"
print_success "nftables: Firewall y NAT"
print_success "wan-failover: Failover automático WAN"

echo ""
print_warning "IMPORTANTE: Pasos siguientes"
echo ""
print_info "1. Configurar WiFi (ver paso 9)" 
print_info "2. Instalar Tailscale VPN:"
print_info "     curl -fsSL https://tailscale.com/install.sh | sh"
print_info "     sudo tailscale up --accept-routes --advertise-routes=192.168.50.0/24"
print_info "3. Configurar SSH (claves, endurecer configuración)"
print_info "4. Reiniciar el sistema:"
print_info "     sudo reboot"
echo ""

# Preguntar si reiniciar ahora
read -p "¿Reiniciar el sistema ahora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    print_info "Reiniciando en 5 segundos..."
    sleep 5
    reboot
else
    print_warning "Recuerda reiniciar el sistema cuando sea conveniente"
fi

print_header "Instalación completada"
print_success "RPI-02 Gateway configurado correctamente"
