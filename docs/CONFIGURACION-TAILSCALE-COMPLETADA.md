# ✅ Configuración Tailscale Completada

**Fecha**: 2026-02-18  
**Configuración**: Subnet Router solo en rpi-02

---

## 📊 Estado Final

### Nodo con Tailscale activo

| Nodo | IP Tailscale | IP LAN | Rol | Estado |
|------|--------------|---------|-----|--------|
| **rpi-02** | 100.93.211.124 | 192.168.50.1 | Subnet Router | ✅ Activo |

**Subnet anunciada**: `192.168.50.0/24` ✅ Aprobada en panel web

### Nodos sin Tailscale (accesibles via subnet routing)

| Nodo | IP LAN | Tailscale | Conectividad | Internet |
|------|---------|-----------|--------------|----------|
| **jetson-01** | 192.168.50.11 | ❌ Detenido | ✅ 10-15ms | ✅ Funciona |
| **jetson-02** | 192.168.50.12 | ❌ Detenido | ✅ 9-12ms | ✅ Funciona |
| **jetson-03** | 192.168.50.13 | ❌ Detenido | ✅ 18-19ms | ✅ Funciona |
| **rpi-03** | 192.168.50.23 | ❌ Detenido | ✅ 11ms | ✅ Funciona |
| **rpi-05** | 192.168.50.25 | ❌ Detenido | ✅ 14-19ms | ✅ Funciona |

---

## ✅ Verificaciones realizadas

### Conectividad desde PC (Windows) via Tailscale

```powershell
✅ ping 192.168.50.11  # jetson-01: 10-15ms, 0% pérdida
✅ ping 192.168.50.12  # jetson-02: 9-12ms, 0% pérdida
✅ ping 192.168.50.13  # jetson-03: 18-19ms, 0% pérdida
✅ ping 192.168.50.23  # rpi-03: 11ms, 0% pérdida
✅ ping 192.168.50.25  # rpi-05: 14-19ms, 0% pérdida
```

### Internet y DNS en jetson-01

```bash
✅ ping 8.8.8.8                    # Conectividad IP
✅ ping google.com                 # Resolución DNS
✅ curl -I https://code-server.dev # HTTPS funciona
```

---

## 🎯 Problema Resuelto

**Problema original**: jetson-01 no podía acceder a internet
- **Causa**: DNS de Tailscale (100.100.100.100) no funcionaba
- **Solución**: Remover Tailscale de workers, usar solo rpi-02 como subnet router
- **Resultado**: Internet y DNS funcionando en todos los nodos ✅

---

## 📁 Documentación

- [SOLUCION-INTERNET-JETSON.md](SOLUCION-INTERNET-JETSON.md) - Análisis completo del problema
- [rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md](rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md) - Documentación técnica
- [scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md](scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md) - Instrucciones paso a paso
- [scripts/simplify-tailscale.ps1](scripts/simplify-tailscale.ps1) - Script automatizado

---

## 🔧 Configuración de rpi-02

```bash
# Ver estado
sudo tailscale status

# Debe mostrar:
# - IP: 100.93.211.124
# - Subnet routes: 192.168.50.0/24 (aprobada)
# - Estado: Conectado

# Verificar rutas anunciadas
sudo tailscale debug prefs | grep "AdvertiseRoutes"
# Debe mostrar: "192.168.50.0/24"
```

---

## ✅ Resolución de Nombres Configurada

### Problema Solucionado
MagicDNS de Tailscale mantenía entradas antiguas de los dispositivos eliminados, causando que Windows resolviera a IPs 100.x.x.x inexistentes.

### Solución Implementada

1. **Eliminar dispositivos del panel Tailscale**:
   - Eliminados: jetson-01, jetson-02, jetson-03, rpi-03, rpi-05
   - Panel: https://login.tailscale.com/admin/machines
   - Cada dispositivo: tres puntos → "Delete device"

2. **Configurar archivo hosts en Windows**:
   ```
   C:\Windows\System32\drivers\etc\hosts
   
   # Mini-cluster
   192.168.50.11  jetson-01
   192.168.50.12  jetson-02
   192.168.50.13  jetson-03
   100.93.211.124 rpi-02
   192.168.50.23  rpi-03
   192.168.50.25  rpi-05
   ```

3. **Limpiar y validar**:
   ```powershell
   Restart-Service Tailscale
   ipconfig /flushdns
   
   ping jetson-01  # ✓ 192.168.50.11
   ssh jetson-01   # ✓ Funciona
   ```

### Resultado
✅ Todos los nodos resuelven correctamente por nombre desde Windows

---

## 💡 Próximos pasos opcionales

### Configurar DNS en Tailscale (opcional)

1. Ir a: https://login.tailscale.com/admin/dns
2. Añadir nameserver: `100.93.211.124` (rpi-02)
3. Añadir search domain: `cluster.local`

**Nota**: No necesario si usas archivo hosts como se configuró arriba.

### Reautenticar rpi-02 (warning de key expiry)

El panel muestra un warning sobre "Key expiry". Para reauntenticar:

```bash
ssh rpi-02
sudo tailscale up --advertise-routes=192.168.50.0/24 --accept-routes --accept-dns=false --ssh
# Seguir el enlace que aparece para renovar autenticación
```

### Habilitar IPv6 forwarding (opcional)

Si quieres eliminar la advertencia sobre IPv6:

```bash
ssh rpi-02
sudo vim /etc/sysctl.conf
# Añadir o descomentar:
net.ipv6.conf.all.forwarding=1

# Aplicar
sudo sysctl -p
sudo systemctl restart tailscaled
```

---

## 🎉 Resumen

**Arquitectura simplificada y funcionando correctamente**

- ✅ Tailscale solo en rpi-02
- ✅ Acceso remoto a todos los nodos via subnet routing
- ✅ DNS funcionando correctamente
- ✅ Internet en todos los nodos
- ✅ Latencias excelentes (9-19ms)
- ✅ 0% pérdida de paquetes

**Total de nodos configurados**: 6  
**Nodos con Tailscale**: 1 (rpi-02)  
**Nodos accesibles via subnet**: 5 (jetson-01, jetson-02, jetson-03, rpi-03, rpi-05)

---

**Configuración completada exitosamente** ✅
