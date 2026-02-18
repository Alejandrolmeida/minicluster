# Instrucciones: Remover Tailscale de Nodos Workers

## Objetivo
Simplificar la arquitectura dejando Tailscale **solo en rpi-02** como subnet router.

## Pasos a ejecutar

### 1. En jetson-01

```bash
ssh jetson-01

# Una vez conectado, ejecutar:
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Verificar que está detenido:
sudo systemctl status tailscaled

# Salir
exit
```

### 2. En jetson-02

```bash
ssh jetson-02

# Una vez conectado, ejecutar:
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Verificar que está detenido:
sudo systemctl status tailscaled

# Salir
exit
```

### 3. En jetson-03

```bash
ssh jetson-03

# Una vez conectado, ejecutar:
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Verificar que está detenido:
sudo systemctl status tailscaled

# Salir
exit
```

### 4. En rpi-03

```bash
ssh rpi-03

# Una vez conectado, ejecutar:
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Verificar que está detenido:
sudo systemctl status tailscaled

# Salir
exit
```

### 5. En rpi-05

```bash
ssh rpi-05

# Una vez conectado, ejecutar:
sudo tailscale down
sudo systemctl stop tailscaled
sudo systemctl disable tailscaled

# Verificar que está detenido:
sudo systemctl status tailscaled

# Salir
exit
```

### 6. Verificar configuración de rpi-02

```bash
ssh rpi-02

# Verificar que está anunciando la subnet del cluster
sudo tailscale status
# Debería mostrar "100.93.211.124" y estar activo

# Verificar que está anunciando rutas
sudo tailscale status --json | grep -i advertis

# Si NO está anunciando la subnet 192.168.50.0/24, ejecutar:
sudo tailscale up --accept-routes --advertise-routes=192.168.50.0/24

exit
```

### 7. Aprobar subnet routes en el panel de Tailscale

1. Ir a: https://login.tailscale.com/admin/machines
2. Buscar **rpi-02** en la lista
3. Clic en los tres puntos → **"Edit route settings"**
4. **Aprobar** la ruta `192.168.50.0/24`
5. Guardar cambios

### 8. Configurar DNS en tu PC Windows

Para poder resolver los nombres del cluster (jetson-01, jetson-02, etc.) desde tu PC:

#### Opción A: Configurar DNS en Tailscale (recomendado)

1. Ir a: https://login.tailscale.com/admin/dns
2. En **"Nameservers"** → Añadir → **"Custom"**
3. Añadir IP de Tailscale de rpi-02: `100.93.211.124`
4. En **"Search domains"** → Añadir: `cluster.local`
5. Guardar

#### Opción B: Configurar en tu PC manualmente

En PowerShell:

```powershell
# Añadir servidor DNS personalizado para Tailscale
# (Esto se hace en la configuración del adaptador de red de Tailscale)

# 1. Abrir "Configuración de red y redes"
# 2. Buscar adaptador "Tailscale"
# 3. Propiedades → TCP/IPv4 → Propiedades
# 4. Usar los siguientes servidores DNS:
#    - Preferido: 100.93.211.124 (rpi-02 a través de Tailscale)
#    - Alternativo: 8.8.8.8
```

### 9. Verificar que todo funciona

Desde tu PC Windows (conectado a Tailscale):

```powershell
# Probar que llegas a rpi-02
ping 100.93.211.124

# Probar que llegas a los nodos del cluster a través de la subnet
ping 192.168.50.11  # jetson-01
ping 192.168.50.12  # jetson-02
ping 192.168.50.13  # jetson-03
ping 192.168.50.23  # rpi-03
ping 192.168.50.25  # rpi-05

# Probar resolución DNS (si configuraste DNS)
nslookup jetson-01.cluster.local 100.93.211.124

# SSH debería funcionar
ssh alejandrolmeida@192.168.50.11
```

## Resultado final

- ✅ Tailscale solo en rpi-02 (subnet router)
- ✅ rpi-02 anuncia la red 192.168.50.0/24 a Tailscale
- ✅ Acceso a todos los nodos desde tu PC via `192.168.50.x`
- ✅ Resolución DNS de nombres del cluster
- ✅ Sin problemas de DNS en los workers
- ✅ Arquitectura más simple y eficiente

**Nodos configurados:**
- jetson-01 (192.168.50.11) - Tailscale removido ✓
- jetson-02 (192.168.50.12) - Tailscale removido ✓
- jetson-03 (192.168.50.13) - Tailscale removido ✓
- rpi-03 (192.168.50.23) - Tailscale removido ✓
- rpi-05 (192.168.50.25) - Tailscale removido ✓

## Troubleshooting

### No puedo llegar a 192.168.50.x desde mi PC

1. Verificar que rpi-02 está anunciando la subnet:
   ```bash
   ssh rpi-02 'sudo tailscale status'
   ```

2. Verificar que aprobaste las rutas en el panel web

3. Verificar rutas en tu PC:
   ```powershell
   route print -4 | Select-String "192.168.50"
   ```

### DNS no resuelve nombres del cluster

1. Verificar que dnsmasq está funcionando en rpi-02:
   ```bash
   ssh rpi-02 'sudo systemctl status dnsmasq'
   ```

2. Probar resolución directa:
   ```powershell
   nslookup jetson-01 100.93.211.124
   ```

3. Si funciona directamente pero no automáticamente, configurar DNS en Tailscale (ver paso 6)
