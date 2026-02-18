# Solución: jetson-01 no puede acceder a internet

## Problema Original

Al intentar ejecutar `curl https://code-server.dev/install.sh` en jetson-01, se producía el error:
```
Could not resolve host: code-server.dev
```

## Diagnóstico

### Lo que funcionaba ✅
- Conectividad IP: `ping 8.8.8.8` funcionaba correctamente
- Red LAN: `ping 192.168.50.1` (gateway rpi-02) funcionaba
- NAT en rpi-02: Configurado correctamente
- Routing: jetson-01 tenía la ruta default correcta

### El problema real ❌
**DNS mal configurado en jetson-01**

jetson-01 tenía dos servidores DNS:
1. **100.100.100.100** (Tailscale DNS) - Primera prioridad, **NO funciona**
2. **192.168.50.1** (rpi-02 DNS) - Segunda prioridad, funciona correctamente

El sistema intentaba usar primero el DNS de Tailscale que no podía resolver nombres públicos.

## Causa Raíz

### Arquitectura de red del cluster

```
Internet
   ↓
rpi-02 (WAN: eth1/wlan0)
   ↓ NAT
rpi-02 (LAN: eth0 - 192.168.50.1)
   ↓
Switch
   ↓
jetson-01 (192.168.50.11)
jetson-02 (192.168.50.12)
jetson-03 (192.168.50.13)
```

**Todos los nodos dependen de rpi-02 para:**
- Salir a internet (NAT)
- Resolución DNS (dnsmasq)
- DHCP

### ¿Por qué Tailscale estaba en todos los nodos?

Configuración inicial incorrecta que asumía que tener Tailscale en cada nodo proporcionaría:
- Conexión directa peer-to-peer ❌ (imposible, todo pasa por rpi-02)
- Mejor rendimiento ❌ (no hay diferencia)
- Resiliencia ❌ (si rpi-02 cae, no hay internet de todas formas)

**Realidad**: Solo añadía complejidad y problemas de DNS.

## Solución Implementada

### Arquitectura simplificada

```
Internet
   ↓
Tailscale VPN
   ↓
rpi-02 (Subnet Router)
   ├─ Tailscale: 100.93.211.124
   ├─ Anuncia: 192.168.50.0/24
   └─ DNS: cluster.local via dnsmasq
   ↓
Cluster LAN (192.168.50.0/24)
   ├─ jetson-01 (sin Tailscale)
   ├─ jetson-02 (sin Tailscale)
   └─ jetson-03 (sin Tailscale)
```

### Cambios realizados

1. **Tailscale removido de workers**
   - jetson-01, jetson-02, jetson-03: `tailscaled` detenido y deshabilitado
   - rpi-03, rpi-05: `tailscaled` detenido y deshabilitado
   - Eliminado problema de DNS de Tailscale

2. **rpi-02 configurado como Subnet Router**
   - Anuncia `192.168.50.0/24` a la red Tailscale
   - Proporciona acceso VPN a todos los nodos del cluster

3. **DNS unificado**
   - Workers usan solo el DNS de rpi-02 (192.168.50.1)
   - dnsmasq en rpi-02 resuelve nombres locales y externos

4. **Documentación creada**
   - [TAILSCALE_SUBNET_ROUTER.md](rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)
   - [INSTRUCCIONES-REMOVER-TAILSCALE.md](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)
   - Script automatizado: [simplify-tailscale.ps1](scripts/simplify-tailscale.ps1)

## Pasos para ejecutar el plan

### Opción A: Script automatizado (PowerShell)

```powershell
# Desde C:\Users\aleja\minicluster
.\scripts\simplify-tailscale.ps1
```

### Opción B: Manual

Seguir las instrucciones en: [scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)

## Verificación final

Después de aplicar los cambios, jetson-01 debería poder:

```bash
# SSH a jetson-01
ssh jetson-01

# Verificar DNS
cat /etc/resolv.conf
# Debería mostrar solo 127.0.0.53 (systemd-resolved)

systemd-resolve --status | grep "DNS Servers" -A 2
# Debería mostrar 192.168.50.1 como único DNS para eth0

# Probar resolución
ping -c 2 google.com
# Debería funcionar ✅

# Probar curl
curl -I https://code-server.dev
# Debería funcionar ✅
```

## Beneficios

✅ **Simplicidad**: Un solo punto de gestión VPN  
✅ **Sin problemas DNS**: Workers usan directamente el DNS de rpi-02  
✅ **Menos recursos**: No consume memoria/CPU en cada nodo  
✅ **Mismo acceso remoto**: Via Tailscale llegar a `192.168.50.x`  
✅ **Arquitectura clara**: Refleja la realidad física de la red  

## Lecciones aprendidas

1. **Analizar la topología antes de configurar servicios**: Tailscale en todos los nodos no aportaba valor real dada la arquitectura física
2. **DNS tiene prioridad**: El orden de servidores DNS importa
3. **KISS (Keep It Simple)**: Simplicidad > Feature bloat
4. **Documentar arquitectura**: Ayuda a identificar configuraciones innecesarias

---

**Fecha**: 2026-02-18  
**Problema resuelto**: DNS / Conectividad a internet  
**Solución**: Simplificación de Tailscale a subnet routing solo en rpi-02
