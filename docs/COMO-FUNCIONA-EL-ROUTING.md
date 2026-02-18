# 🌐 Cómo Funciona el Routing del Mini-Cluster

**Pregunta**: ¿Cómo encuentra mi PC local el camino para ir a las IPs 192.168.50.X?  
**Respuesta**: Tailscale configura automáticamente las rutas cuando rpi-02 anuncia la subnet.

---

## 📊 Tabla de Rutas en tu PC Windows

```powershell
PS> Get-NetRoute -DestinationPrefix "192.168.50.0/24"

DestinationPrefix NextHop         RouteMetric ifIndex
----------------- -------         ----------- -------
192.168.50.0/24   100.100.100.100           0      16
                  ↑                               ↑
           Tailscale magic IP          Interfaz Tailscale
```

### Significado
- **DestinationPrefix**: `192.168.50.0/24` - Todo el rango del cluster
- **NextHop**: `100.100.100.100` - Dirección especial de Tailscale (coordinador interno)
- **ifIndex**: `16` - Interfaz de red Tailscale
- **RouteMetric**: `0` - Máxima prioridad

**Traducción**: "Para llegar a cualquier IP 192.168.50.X, envía los paquetes por Tailscale"

---

## 🔄 Flujo Completo de un Paquete

### Ejemplo: `ping jetson-01` (192.168.50.11)

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. TU PC (Windows)                                                  │
│    IP LAN: 192.168.18.45                                            │
│    IP Tailscale: 100.88.97.100                                      │
│                                                                      │
│    Ejecutas: ping jetson-01                                         │
│       ↓                                                              │
│    Windows resuelve: jetson-01 → 192.168.50.11 (archivo hosts)     │
│       ↓                                                              │
│    Busca en tabla de rutas:                                         │
│      "192.168.50.11 está en 192.168.50.0/24 → usar Tailscale"     │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ Paquete ICMP Echo Request
                       │ Dest: 192.168.50.11
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 2. TAILSCALE (VPN en tu PC)                                         │
│                                                                      │
│    Consulta su mapa de red:                                         │
│      "192.168.50.0/24 la anuncia rpi-02 (100.93.211.124)"          │
│       ↓                                                              │
│    Encapsula el paquete en túnel Tailscale                          │
│    Destino del túnel: 100.93.211.124 (rpi-02)                       │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ WireGuard encrypted packet
                       │ Outer: Tu PC → 192.168.18.112:41641
                       │ Inner: 192.168.50.11 (ICMP request)
                       ▼
          ═══════════════════════════════
          ║    INTERNET / RED LOCAL     ║
          ═══════════════════════════════
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 3. RPI-02 (Gateway + Subnet Router)                                 │
│    IP LAN: 192.168.50.1                                             │
│    IP Tailscale: 100.93.211.124                                     │
│                                                                      │
│    Recibe paquete encriptado de Tailscale                           │
│       ↓                                                              │
│    Desencripta y extrae: ICMP para 192.168.50.11                   │
│       ↓                                                              │
│    Consulta su tabla de rutas:                                      │
│      "192.168.50.11 está en mi red LAN (eth0)"                     │
│       ↓                                                              │
│    IP forwarding + NAT (nftables)                                   │
│    Reenvía paquete por eth0                                         │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ Paquete ICMP 
                       │ Source: 192.168.50.1 (NAT)
                       │ Dest: 192.168.50.11
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│ 4. JETSON-01 (Worker)                                               │
│    IP: 192.168.50.11                                                │
│    Gateway: 192.168.50.1 (rpi-02)                                   │
│                                                                      │
│    Recibe ICMP Echo Request                                         │
│       ↓                                                              │
│    Genera ICMP Echo Reply                                           │
│    Dest: 192.168.50.1 (que es rpi-02)                              │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ ICMP Reply
                       │
                       ▼
        ═══ CAMINO DE VUELTA (reverso) ═══
                       │
                       ▼
┌────────────────────────────────────────────┐
│ TU PC: "Respuesta desde 192.168.50.11:   │
│         bytes=32 tiempo=15ms TTL=63"       │
└────────────────────────────────────────────┘
```

---

## 🔍 Verificación Práctica

### 1. Ver la ruta configurada
```powershell
PS> Get-NetRoute -DestinationPrefix "192.168.50.0/24" | Format-Table

# Salida:
# 192.168.50.0/24   100.100.100.100         0      16
```

### 2. Ver quién anuncia la subnet
```powershell
PS> tailscale status | Select-String "rpi-02"

# Salida:
# 100.93.211.124  rpi-02  alejandro@  linux  active; direct 192.168.18.112:41641
```

### 3. Traceroute al destino
```powershell
PS> Test-NetConnection 192.168.50.11 -TraceRoute

# TraceRoute:
# 1. 100.93.211.124  <- rpi-02 (via Tailscale)
# 2. 192.168.50.11   <- jetson-01 (destino)
```

---

## ⚙️ Cómo se Configuró (Ya está hecho)

### En rpi-02
```bash
# Anunciar subnet 192.168.50.0/24
sudo tailscale up --advertise-routes=192.168.50.0/24

# Habilitar IP forwarding (ya estaba por NAT)
sysctl net.ipv4.ip_forward=1
```

### En Panel Web Tailscale
1. https://login.tailscale.com/admin/machines
2. rpi-02 → Edit route settings
3. ✅ Marcar checkbox: `192.168.50.0/24`

### En tu PC Windows
**NADA** - Tailscale configuró todo automáticamente:
- Agregó la ruta a 192.168.50.0/24
- La asoció con la interfaz Tailscale
- Sincronizó el mapa de red

---

## 🎯 Por Qué Funciona

### rpi-02 es el gateway perfecto porque:
1. **Ya tiene NAT configurado**: Todos los nodos del cluster usan rpi-02 para internet
2. **IP forwarding activo**: Reenvía paquetes entre interfaces
3. **Conectado a ambas redes**:
   - Tailscale VPN (100.93.211.124)
   - LAN del cluster (192.168.50.1)

### Tailscale hace el trabajo pesado:
- ✅ Crea túnel encriptado (WireGuard)
- ✅ Configura rutas automáticamente en todos los clientes
- ✅ Mantiene el mapa de red sincronizado
- ✅ Maneja NAT traversal (conexión directa cuando es posible)

---

## 📋 Comparación con Alternativas

### Opción 1: VPN tradicional (OpenVPN, WireGuard manual)
```
❌ Configurar servidor VPN
❌ Generar certificados para cada cliente
❌ Configurar rutas manualmente en cada PC
❌ Abrir puertos en router (port forwarding)
❌ Lidiar con NAT traversal
❌ Configurar DNS manualmente
```

### Opción 2: Tailscale Subnet Router (lo que tienes)
```
✅ sudo tailscale up --advertise-routes=192.168.50.0/24
✅ Aprobar checkbox en panel web
✅ Listo - todo funciona automáticamente
```

---

## 🚀 Beneficios de esta Arquitectura

### Simplicidad
- Un solo nodo con Tailscale (rpi-02)
- Workers sin complejidad VPN
- Configuración centralizada

### Rendimiento
```
Latencias medidas:
- jetson-01: 10-15ms
- jetson-02: 9-12ms
- jetson-03: 18-19ms
- rpi-03: 11ms
- rpi-05: 14-19ms

(Excelentes para VPN + salto de gateway)
```

### Seguridad
- ✅ Tráfico encriptado (WireGuard)
- ✅ Autenticación centralizada (Tailscale)
- ✅ Sin puertos abiertos en router
- ✅ NAT traversal automático
- ✅ Control de acceso por dispositivo

### Flexibilidad
- Funciona desde cualquier red (casa, trabajo, móvil)
- rpi-02 puede tener IP dinámica
- Acceso desde cualquier dispositivo (PC, móvil, tablet)

---

## 🔧 Troubleshooting

### Si no puedes alcanzar 192.168.50.X

**1. Verificar ruta está presente:**
```powershell
Get-NetRoute -DestinationPrefix "192.168.50.0/24"
```
- Si no existe: Reinicia Tailscale o reconecta VPN

**2. Verificar subnet aprobada:**
```powershell
tailscale status | Select-String "rpi-02"
```
- Si no muestra rpi-02: Verifica panel web

**3. Verificar IP forwarding en rpi-02:**
```bash
ssh rpi-02 sysctl net.ipv4.ip_forward
# Debe ser: net.ipv4.ip_forward = 1
```

**4. Verificar nftables en rpi-02:**
```bash
ssh rpi-02 sudo nft list ruleset | grep masquerade
# Debe mostrar: masquerade
```

---

## 📚 Comandos de Referencia

### Ver todas las rutas de Tailscale
```powershell
Get-NetRoute | Where-Object { $_.ifIndex -eq 16 } | Format-Table
```

### Ver estado completo de Tailscale
```powershell
tailscale status
```

### Ver qué subnets están disponibles
```powershell
tailscale status --json | ConvertFrom-Json | 
    Select-Object -ExpandProperty Peer | 
    Where-Object { $_.SubnetRoutes } |
    Select-Object HostName, SubnetRoutes
```

### Probar conectividad específica
```powershell
Test-NetConnection -ComputerName 192.168.50.11 -TraceRoute
```

---

## 💡 Resumen

**Tu pregunta**: ¿Cómo sabe mi PC que tiene que ir a rpi-02 para buscar 192.168.50.X?

**Respuesta corta**:
1. rpi-02 le dijo a Tailscale: "Yo gestiono 192.168.50.0/24"
2. Tailscale agregó automáticamente esta ruta en tu PC
3. Windows ve: "192.168.50.X → enviar por Tailscale"
4. Tailscale ve: "192.168.50.0/24 → enviar a rpi-02"
5. rpi-02 recibe y reenvía al nodo correcto

**Todo esto pasó automáticamente cuando**:
- ✅ Ejecutaste `--advertise-routes=192.168.50.0/24` en rpi-02
- ✅ Aprobaste la subnet en el panel web

**No configuraste nada manualmente en tu PC** - Tailscale se encargó de todo.

---

**Fecha**: 2026-02-18  
**Estado**: ✅ Funcionando perfectamente
