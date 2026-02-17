#!/bin/bash
# WAN Failover Script for RPI-02 Gateway
# Minicluster - Automatic WAN failover between eth1 (primary) and wlan0 (backup)
# Última actualización: Febrero 2026

# Configuración
PRIMARY_IF="eth1"           # Interfaz WAN primaria (cable)
BACKUP_IF="wlan0"          # Interfaz WAN backup (WiFi)
CHECK_INTERVAL=10          # Segundos entre comprobaciones
PING_TARGET="8.8.8.8"      # Host para comprobar conectividad
PING_COUNT=3               # Número de pings por comprobación
PING_TIMEOUT=5             # Timeout por ping (segundos)
MIN_FAILURES=3             # Fallos consecutivos antes de cambiar

# Métricas de ruta (menor = mayor preferencia)
PRIMARY_METRIC=100
BACKUP_METRIC=200

# Estado actual
CURRENT_WAN=""
FAILURE_COUNT=0

# Archivo de log
LOG_FILE="/var/log/wan-failover.log"

# Función de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para comprobar si una interfaz está UP
interface_is_up() {
    local interface=$1
    ip link show "$interface" 2>/dev/null | grep -q "state UP"
}

# Función para comprobar conectividad a través de una interfaz
check_connectivity() {
    local interface=$1
    
    # Verificar que la interfaz está UP
    if ! interface_is_up "$interface"; then
        log "  └─ Interfaz $interface está DOWN"
        return 1
    fi
    
    # Verificar que tiene IP
    local has_ip=$(ip addr show "$interface" | grep -c "inet ")
    if [ "$has_ip" -eq 0 ]; then
        log "  └─ Interfaz $interface no tiene dirección IP"
        return 1
    fi
    
    # Ping a través de la interfaz
    if ping -I "$interface" -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_TARGET" &>/dev/null; then
        log "  └─ Interfaz $interface: Conectividad OK"
        return 0
    else
        log "  └─ Interfaz $interface: Sin conectividad"
        return 1
    fi
}

# Función para obtener la gateway de una interfaz
get_gateway() {
    local interface=$1
    ip route show dev "$interface" | grep default | awk '{print $3}' | head -n 1
}

# Función para activar una interfaz como WAN
activate_wan() {
    local interface=$1
    local metric=$2
    
    log "Activando $interface como WAN..."
    
    # Obtener gateway de la interfaz
    local gateway=$(get_gateway "$interface")
    
    if [ -z "$gateway" ]; then
        log "  └─ ERROR: No se pudo obtener gateway para $interface"
        return 1
    fi
    
    # Eliminar rutas default existentes
    while ip route del default 2>/dev/null; do
        sleep 0.1
    done
    
    # Añadir nueva ruta default
    if ip route add default via "$gateway" dev "$interface" metric "$metric"; then
        log "  └─ Ruta default añadida: $interface vía $gateway (metric $metric)"
        CURRENT_WAN="$interface"
        FAILURE_COUNT=0
        return 0
    else
        log "  └─ ERROR: No se pudo añadir ruta default para $interface"
        return 1
    fi
}

# Función para configurar ambas interfaces con métricas
setup_dual_wan() {
    log "Configurando dual WAN con métricas..."
    
    # Eliminar rutas default existentes
    while ip route del default 2>/dev/null; do
        sleep 0.1
    done
    
    # Añadir ruta primary
    local primary_gw=$(get_gateway "$PRIMARY_IF")
    if [ -n "$primary_gw" ]; then
        ip route add default via "$primary_gw" dev "$PRIMARY_IF" metric "$PRIMARY_METRIC"
        log "  └─ Ruta primaria: $PRIMARY_IF vía $primary_gw (metric $PRIMARY_METRIC)"
    fi
    
    # Añadir ruta backup
    local backup_gw=$(get_gateway "$BACKUP_IF")
    if [ -n "$backup_gw" ]; then
        ip route add default via "$backup_gw" dev "$BACKUP_IF" metric "$BACKUP_METRIC"
        log "  └─ Ruta backup: $BACKUP_IF vía $backup_gw (metric $BACKUP_METRIC)"
    fi
}

# Función principal de monitoreo
monitor_wan() {
    log "=== Iniciando monitoreo WAN ==="
    log "PRIMARY: $PRIMARY_IF (metric $PRIMARY_METRIC)"
    log "BACKUP:  $BACKUP_IF (metric $BACKUP_METRIC)"
    log "Check cada $CHECK_INTERVAL segundos"
    log "Cambio tras $MIN_FAILURES fallos consecutivos"
    
    # Configuración inicial
    setup_dual_wan
    CURRENT_WAN="$PRIMARY_IF"
    
    while true; do
        sleep "$CHECK_INTERVAL"
        
        log "--- Comprobando conectividad ---"
        
        # Comprobar interfaz primaria
        if check_connectivity "$PRIMARY_IF"; then
            # Primary OK
            if [ "$CURRENT_WAN" != "$PRIMARY_IF" ]; then
                log "▲ Primary WAN restaurada, volviendo a $PRIMARY_IF"
                activate_wan "$PRIMARY_IF" "$PRIMARY_METRIC"
            else
                FAILURE_COUNT=0
            fi
        else
            # Primary FAIL
            if [ "$CURRENT_WAN" = "$PRIMARY_IF" ]; then
                FAILURE_COUNT=$((FAILURE_COUNT + 1))
                log "⚠ Primary WAN fallo $FAILURE_COUNT/$MIN_FAILURES"
                
                if [ "$FAILURE_COUNT" -ge "$MIN_FAILURES" ]; then
                    log "⚠ Primary WAN caída, cambiando a backup"
                    
                    # Verificar que backup tiene conectividad
                    if check_connectivity "$BACKUP_IF"; then
                        activate_wan "$BACKUP_IF" "$BACKUP_METRIC"
                        log "✓ Failover completado: ahora usando $BACKUP_IF"
                    else
                        log "✗ ERROR: Backup WAN también sin conectividad!"
                        FAILURE_COUNT=0
                    fi
                fi
            fi
        fi
        
        # Mostrar estado actual
        log "Estado: WAN=$CURRENT_WAN, Fallos=$FAILURE_COUNT"
    done
}

# Manejo de señales
cleanup() {
    log "=== Deteniendo monitoreo WAN ==="
    exit 0
}

trap cleanup SIGTERM SIGINT

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Verificar que las interfaces existen
for iface in "$PRIMARY_IF" "$BACKUP_IF"; do
    if ! ip link show "$iface" &>/dev/null; then
        log "ERROR: Interfaz $iface no existe"
        exit 1
    fi
done

# Iniciar monitoreo
monitor_wan
