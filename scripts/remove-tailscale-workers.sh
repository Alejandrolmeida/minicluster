#!/bin/bash
# Script para remover Tailscale de los nodos workers
# Ejecutar este script EN CADA NODO WORKER (jetson-01, jetson-02, jetson-03)

set -e

echo "================================================"
echo "Removiendo Tailscale de este nodo worker"
echo "================================================"
echo ""

# Detener Tailscale
echo "[1/4] Deteniendo conexión Tailscale..."
sudo tailscale down

# Detener servicio
echo "[2/4] Deteniendo servicio tailscaled..."
sudo systemctl stop tailscaled

# Deshabilitar servicio
echo "[3/4] Deshabilitando servicio tailscaled..."
sudo systemctl disable tailscaled

# Verificar estado
echo "[4/4] Verificando estado..."
echo ""
echo "Estado del servicio:"
sudo systemctl status tailscaled --no-pager || true

echo ""
echo "✓ Tailscale removido exitosamente de $(hostname)"
echo ""
echo "NOTA: Tailscale sigue instalado, solo está detenido y deshabilitado."
echo "      Para desinstalar completamente, ejecuta:"
echo "      sudo apt remove tailscale -y"
echo ""
