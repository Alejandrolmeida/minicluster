# Configuración Tailscale - Subnet Router en rpi-02

## Arquitectura

```
Internet
   ↓
Tailscale Network (100.x.x.x/10)
   ↓
rpi-02 (Subnet Router)
   ├─ Tailscale IP: 100.93.211.124
   ├─ Anuncia subnet: 192.168.50.0/24
   └─ DNS: cluster.local
   ↓
Cluster LAN (192.168.50.0/24)
   ├─ jetson-01 (192.168.50.11)
   ├─ jetson-02 (192.168.50.12)
   ├─ jetson-03 (192.168.50.13)
   ├─ rpi-03 (192.168.50.23)
   └─ rpi-05 (192.168.50.25)
```

## ¿Por qué solo Tailscale en rpi-02?

### Razones técnicas

1. **Arquitectura de red**: Todos los dispositivos del cluster dependen de rpi-02 para salir a internet (NAT/gateway)
2. **Sin beneficio real**: Tailscale en cada nodo no proporciona conexión directa porque todo el tráfico pasa por rpi-02 de todas formas
3. **Problema de DNS**: Tailscale introduce su propio DNS (100.100.100.100) que interfiere con el DNS local de dnsmasq

### Ventajas de subnet routing

✅ **Simplicidad**: Un solo punto de gestión VPN  
✅ **Menos recursos**: No consume memoria/CPU en cada nodo  
✅ **Sin problemas DNS**: Los workers usan directamente el DNS de rpi-02  
✅ **Mismo acceso**: Puedes llegar a todos los nodos via `192.168.50.x`  
✅ **Resolución de nombres**: MagicDNS puede resolver nombres del cluster  

### Desventajas (menores)

❌ **rpi-02 es SPOF**: Si rpi-02 cae, pierdes acceso remoto (pero ya era así para internet)  
❌ **Todo el tráfico pasa por rpi-02**: Pero esto ya ocurría por la topología de red  

## Configuración en rpi-02

### Estado actual

```bash
# Ver estado de Tailscale
sudo tailscale status

# Debería mostrar:
# 100.93.211.124   rpi-02               alejandrolmeida@ linux   -
#   offering subnet routes: 192.168.50.0/24
```

### Comandos útiles

```bash
# Verificar configuración
sudo tailscale status --json | jq '.Self'

# Ver rutas anunciadas
sudo tailscale status --json | jq '.Self.AllowedIPs'

# Reconfigurar (si es necesario)
sudo tailscale up --accept-routes --advertise-routes=192.168.50.0/24

# Ver logs
sudo journalctl -u tailscaled -f
```

## Configuración en el Panel Web de Tailscale

### 1. Aprobar Subnet Routes

**Crítico**: Debes aprobar manualmente las subnet routes en el panel web.

1. Ir a: https://login.tailscale.com/admin/machines
2. Buscar **rpi-02**
3. Clic en `⋯` → **Edit route settings**
4. En "Subnets" aparecer `192.168.50.0/24`
5. Hacer clic en **"Enable"** o **"Approve"**
6. Guardar

Sin este paso, **no podrás acceder a los nodos del cluster**.

### 2. Configurar DNS (Opcional pero recomendado)

Para resolver nombres como `jetson-01.cluster.local`:

1. Ir a: https://login.tailscale.com/admin/dns
2. En **"Nameservers"**:
   - Clic en **"Add nameserver"**
   - Seleccionar **"Custom"**
   - Añadir: `100.93.211.124` (IP de Tailscale de rpi-02)
3. En **"Search domains"**:
   - Añadir: `cluster.local`
4. Guardar cambios

Ahora desde cualquier dispositivo en la VPN podrás hacer:
```bash
ping jetson-01.cluster.local
ssh alejandrolmeida@jetson-01.cluster.local
```

## Uso desde dispositivos cliente

### Windows (tu PC)

#### Verificar conectividad

```powershell
# Ping a rpi-02 via Tailscale
ping 100.93.211.124

# Ping a jetson-01 via subnet route
ping 192.168.50.11

# SSH a jetson-01
ssh alejandrolmeida@192.168.50.11

# Si configuraste DNS:
ping jetson-01.cluster.local
ssh alejandrolmeida@jetson-01.cluster.local
```

#### Ver rutas

```powershell
# Ver todas las rutas IPv4
route print -4

# Buscar rutas de Tailscale
route print -4 | Select-String "192.168.50"

# Deberías ver algo como:
# 192.168.50.0    255.255.255.0     100.93.211.124   (via Tailscale)
```

### Linux/Mac

```bash
# Ping a nodos
ping 192.168.50.11

# Ver rutas
ip route | grep 192.168.50

# Deberías ver:
# 192.168.50.0/24 via 100.93.211.124 dev tailscale0
```

## Troubleshooting

### No puedo llegar a 192.168.50.x desde mi PC

**Diagnóstico paso a paso:**

1. ¿Está Tailscale conectado en tu PC?
   ```powershell
   tailscale status
   ```

2. ¿Puedes llegar a rpi-02?
   ```powershell
   ping 100.93.211.124
   ```

3. ¿Están aprobadas las subnet routes?
   - Revisar en: https://login.tailscale.com/admin/machines
   - Debe aparecer `192.168.50.0/24` como **aprobada**

4. ¿Están las rutas en tu tabla de enrutamiento?
   ```powershell
   route print -4 | Select-String "192.168.50"
   ```
   
   Si no aparece, reinicia Tailscale en tu PC:
   ```powershell
   # En PowerShell como Admin
   Restart-Service Tailscale
   ```

5. ¿Firewall bloqueando?
   - Probar temporalmente: `Test-NetConnection -ComputerName 192.168.50.11 -Port 22`

### DNS no resuelve nombres del cluster

1. Verificar que dnsmasq funciona en rpi-02:
   ```bash
   ssh rpi-02 'sudo systemctl status dnsmasq'
   ```

2. Probar resolución directa:
   ```powershell
   nslookup jetson-01.cluster.local 100.93.211.124
   ```

3. Si funciona directamente:
   - Configurar DNS en Tailscale (ver arriba)
   - O configurar DNS manualmente en tu PC

### rpi-02 no anuncia la subnet

```bash
# SSH a rpi-02
ssh rpi-02

# Verificar estado
sudo tailscale status

# Si no aparece "offering subnet routes", reconfigurar:
sudo tailscale up --accept-routes --advertise-routes=192.168.50.0/24

# Verificar de nuevo
sudo tailscale status
```

Luego verificar en el panel web que la ruta está **aprobada**.

### Conectividad lenta o intermitente

1. Verificar que rpi-02 tiene buena conexión a internet:
   ```bash
   ssh rpi-02 'ping -c 5 8.8.8.8'
   ```

2. Ver latencia de Tailscale:
   ```bash
   tailscale ping 100.93.211.124
   ```

3. Verificar que el WAN failover está funcionando:
   ```bash
   ssh rpi-02 'sudo systemctl status wan-failover'
   ssh rpi-02 'ip route show'
   ```

## Migración de Tailscale individual a subnet routing

Si tenías Tailscale en cada nodo y quieres migrar:

### En cada worker (jetson-01, jetson-02, jetson-03, rpi-03, rpi-05)

```bash
# Detener y deshabilitar Tailscale
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Opcional: Desinstalar completamente
sudo apt remove tailscale -y
```

Ver guía completa: [scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md](../scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)

## Referencias

- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets/)
- [Tailscale DNS](https://tailscale.com/kb/1054/dns/)
- [Troubleshooting subnet routes](https://tailscale.com/kb/1019/subnets/#troubleshooting)
