# ✅ Resolución Completa del Problema de Internet

**Fecha**: 2026-02-18  
**Problema Original**: jetson-01 no podía acceder a internet  
**Estado**: ✅ RESUELTO

---

## 🔍 Diagnóstico del Problema

### Síntomas
```bash
jetson-01$ curl https://code-server.dev
curl: (6) Could not resolve host: code-server.dev
```

### Causa Raíz
1. **DNS de Tailscale mal configurado**: 100.100.100.100 no respondía
2. **Arquitectura innecesariamente compleja**: Tailscale en todos los nodos
3. **Conflicto de MagicDNS**: Entradas antiguas interferían con resolución local

### Red Original
- ❌ Cada nodo con Tailscale independiente
- ❌ DNS de Tailscale (100.100.100.100) como primario
- ❌ Complejidad sin beneficio real

---

## ✅ Solución Implementada

### 1. Simplificación de Arquitectura Tailscale

**Decisión**: Subnet Router solo en rpi-02

**Justificación**:
- Todos los dispositivos pasan por rpi-02 para internet (NAT)
- rpi-02 ya es el gateway del cluster
- Tailscale en workers era redundante

**Configuración**:
```bash
# rpi-02 (único con Tailscale)
sudo tailscale up \
  --advertise-routes=192.168.50.0/24 \
  --accept-routes \
  --accept-dns=false \
  --ssh

# Aprobar subnet en: https://login.tailscale.com/admin/machines
```

### 2. Remoción de Tailscale de Workers

**Nodos donde se removió**:
- jetson-01 (192.168.50.11)
- jetson-02 (192.168.50.12)
- jetson-03 (192.168.50.13)
- rpi-03 (192.168.50.23)
- rpi-05 (192.168.50.25)

**Comandos ejecutados**:
```bash
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled
sudo systemctl mask tailscaled
```

**Restauración de DNS**:
```bash
# /etc/systemd/resolved.conf
[Resolve]
DNS=192.168.50.1
#FallbackDNS=
Domains=cluster.local
```

### 3. Configuración de Resolución de Nombres

**Problema**: MagicDNS cache mantenía entradas antiguas

**Solución**:
1. Eliminar dispositivos del panel Tailscale
2. Configurar archivo hosts en Windows
3. Reiniciar Tailscale y limpiar cache DNS

**Archivo hosts** (`C:\Windows\System32\drivers\etc\hosts`):
```
# Mini-cluster
192.168.50.11  jetson-01
192.168.50.12  jetson-02
192.168.50.13  jetson-03
100.93.211.124 rpi-02
192.168.50.23  rpi-03
192.168.50.25  rpi-05
```

**Script de configuración** (scripts/configurar-hosts.ps1):
```powershell
# Ejecutar con privilegios de administrador
.\scripts\configurar-hosts.ps1
```

---

## 📊 Resultado Final

### Internet Funcionando
```bash
jetson-01$ ping 8.8.8.8
✅ PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.

jetson-01$ ping google.com
✅ PING google.com (142.250.185.206)

jetson-01$ curl -I https://code-server.dev
✅ HTTP/2 200
```

### Conectividad desde Windows
```powershell
PS> ping jetson-01
✅ Haciendo ping a jetson-01 [192.168.50.11]
   Respuesta desde 192.168.50.11: bytes=32 tiempo=15ms TTL=63

PS> ssh jetson-01
✅ alejandrolmeida@jetson-01:~$
```

### Resolución DNS
| Nodo | Resuelve a | Estado |
|------|------------|--------|
| jetson-01 | 192.168.50.11 | ✅ |
| jetson-02 | 192.168.50.12 | ✅ |
| jetson-03 | 192.168.50.13 | ✅ |
| rpi-02 | 100.93.211.124 | ✅ |
| rpi-03 | 192.168.50.23 | ✅ |
| rpi-05 | 192.168.50.25 | ✅ |

---

## 🏗️ Arquitectura Final

```
Internet
   ↓
[eth1/wlan0] rpi-02 (Gateway + Tailscale Subnet Router)
   ├─ IP LAN: 192.168.50.1
   ├─ IP Tailscale: 100.93.211.124
   └─ [eth0] 192.168.50.0/24
        ├─ jetson-01 (192.168.50.11) - Sin Tailscale
        ├─ jetson-02 (192.168.50.12) - Sin Tailscale
        ├─ jetson-03 (192.168.50.13) - Sin Tailscale
        ├─ rpi-03 (192.168.50.23) - Sin Tailscale
        └─ rpi-05 (192.168.50.25) - Sin Tailscale

Acceso Remoto:
  PC → Tailscale VPN → rpi-02 → Subnet 192.168.50.0/24 → Todos los nodos
```

### Ventajas
- ✅ Simplicidad: Solo un nodo con Tailscale
- ✅ Mantenibilidad: Un solo punto de configuración VPN
- ✅ Rendimiento: Sin overhead de Tailscale en workers
- ✅ DNS: Sin conflictos de MagicDNS
- ✅ NAT: Aprovecha infraestructura existente

---

## 📚 Documentación Generada

1. **[SOLUCION-INTERNET-JETSON.md](SOLUCION-INTERNET-JETSON.md)**  
   Análisis técnico del problema original

2. **[CONFIGURACION-TAILSCALE-COMPLETADA.md](CONFIGURACION-TAILSCALE-COMPLETADA.md)**  
   Estado completo de la configuración Tailscale

3. **[rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md](rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)**  
   Guía técnica de subnet routing

4. **[scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)**  
   Procedimiento para remover Tailscale de nodos

5. **[scripts/configurar-hosts.ps1](scripts/configurar-hosts.ps1)**  
   Script automático para Windows hosts

---

## 🎯 Comandos de Referencia Rápida

### Validar Conectividad
```powershell
# Desde Windows
ping jetson-01
ssh jetson-01
tailscale status
```

### Verificar Internet en Workers
```bash
# Desde cualquier worker
ping 8.8.8.8
ping google.com
curl -I https://httpbin.org/ip
```

### Monitorear Tailscale
```bash
# Desde rpi-02
sudo tailscale status
sudo tailscale netcheck
sudo journalctl -u tailscaled -f
```

### Reiniciar DNS (si hay problemas)
```powershell
# Windows
Restart-Service Tailscale
ipconfig /flushdns
```

```bash
# rpi-02
sudo systemctl restart systemd-resolved
sudo systemctl restart dnsmasq
```

---

## ⚠️ Troubleshooting

### Si un nodo pierde internet

1. Verificar DNS:
   ```bash
   cat /etc/resolv.conf  # Debe ser: nameserver 192.168.50.1
   ```

2. Verificar gateway:
   ```bash
   ip route  # default via 192.168.50.1
   ```

3. Reiniciar resolved:
   ```bash
   sudo systemctl restart systemd-resolved
   ```

### Si no resuelve nombres desde Windows

1. Verificar archivo hosts:
   ```powershell
   Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "cluster"
   ```

2. Limpiar cache:
   ```powershell
   ipconfig /flushdns
   Restart-Service Tailscale
   ```

3. Verificar que dispositivos estén eliminados de Tailscale panel

### Si subnet routing no funciona

1. Verificar aprobación:
   - https://login.tailscale.com/admin/machines
   - rpi-02 → Edit route settings → Marcar checkbox

2. Verificar anuncio:
   ```bash
   sudo tailscale status
   # Debe mostrar: Subnet routes: 192.168.50.0/24
   ```

3. Verificar IP forwarding:
   ```bash
   sysctl net.ipv4.ip_forward  # = 1
   ```

---

## ✅ Checklist de Validación

- [x] jetson-01 puede hacer ping a 8.8.8.8
- [x] jetson-01 puede hacer ping a google.com
- [x] jetson-01 puede descargar con curl
- [x] Todos los workers accesibles desde PC via Tailscale
- [x] Resolución de nombres funciona (hosts file)
- [x] SSH por nombre funciona desde Windows
- [x] Latencias aceptables (< 20ms)
- [x] 0% pérdida de paquetes
- [x] Tailscale solo en rpi-02
- [x] Subnet route aprobada y funcionando

---

**PROBLEMA RESUELTO ✅**

La configuración está completa, documentada y funcionando correctamente.
