#!/bin/bash
# Script de verificación del servidor VS Code en Jetson Nano
# Última actualización: Febrero 2026

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║ Verificación de VS Code Server - Jetson   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 1. Información del sistema
echo -e "${BLUE}1. Información del Sistema${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Hostname:      $(hostname)"
echo "Usuario:       $(whoami)"
echo "Arquitectura:  $(uname -m)"
echo "Kernel:        $(uname -r)"
echo "OS:            $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo ""

# 2. Versión de GLIBC
echo -e "${BLUE}2. Versión de GLIBC${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
GLIBC_VERSION=$(ldd --version | head -n1 | grep -oP '\d+\.\d+' | head -n1)
echo "GLIBC: $GLIBC_VERSION"

if (( $(echo "$GLIBC_VERSION < 2.28" | bc -l) )); then
    echo -e "${YELLOW}⚠ GLIBC < 2.28: Se requiere servidor legacy${NC}"
else
    echo -e "${GREEN}✓ GLIBC >= 2.28: Compatible con servidores modernos${NC}"
fi
echo ""

# 3. Directorios de VS Code Server
echo -e "${BLUE}3. Directorios de VS Code Server${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LEGACY_DIR="$HOME/.vscode-server-legacy"
NORMAL_DIR="$HOME/.vscode-server"

if [ -d "$LEGACY_DIR" ]; then
    echo -e "${GREEN}✓${NC} Existe: $LEGACY_DIR"
    if [ -d "$LEGACY_DIR/bin" ]; then
        echo "  Servidores instalados:"
        ls -1 "$LEGACY_DIR/bin" 2>/dev/null | grep -v "\.tar\.gz" | head -n 10 | while read dir; do
            if [ -d "$LEGACY_DIR/bin/$dir" ]; then
                SIZE=$(du -sh "$LEGACY_DIR/bin/$dir" 2>/dev/null | cut -f1)
                echo "    - $dir ($SIZE)"
            fi
        done
    else
        echo -e "${YELLOW}⚠${NC} No existe: $LEGACY_DIR/bin"
    fi
else
    echo -e "${RED}✗${NC} No existe: $LEGACY_DIR"
fi

echo ""

if [ -d "$NORMAL_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Existe: $NORMAL_DIR (puede causar conflictos)"
    echo "  Considera eliminarlo: rm -rf $NORMAL_DIR"
else
    echo -e "${GREEN}✓${NC} No existe: $NORMAL_DIR (correcto)"
fi

echo ""

# 4. Verificar servidor compatible
echo -e "${BLUE}4. Servidor Compatible${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
COMPATIBLE_COMMIT="8b3775030ed1a69b13e4f4c628c612102e30a681"

if [ -d "$LEGACY_DIR/bin/$COMPATIBLE_COMMIT" ]; then
    echo -e "${GREEN}✓${NC} Servidor compatible instalado"
    echo "  Commit: $COMPATIBLE_COMMIT"
    echo "  Ubicación: $LEGACY_DIR/bin/$COMPATIBLE_COMMIT"
    
    # Verificar ejecutable
    if [ -x "$LEGACY_DIR/bin/$COMPATIBLE_COMMIT/bin/code-server" ]; then
        echo -e "  ${GREEN}✓${NC} Ejecutable encontrado y tiene permisos"
    else
        echo -e "  ${RED}✗${NC} Ejecutable no encontrado o sin permisos"
    fi
else
    echo -e "${RED}✗${NC} Servidor compatible NO instalado"
    echo "  Ejecuta: ~/minicluster/jetson-01/scripts/install-vscode-server.sh"
fi

echo ""

# 5. Symlinks
echo -e "${BLUE}5. Symlinks${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "$LEGACY_DIR/bin" ]; then
    SYMLINKS=$(find "$LEGACY_DIR/bin" -maxdepth 1 -type l 2>/dev/null)
    if [ -n "$SYMLINKS" ]; then
        echo "Symlinks encontrados:"
        echo "$SYMLINKS" | while read link; do
            TARGET=$(readlink "$link")
            BASENAME=$(basename "$link")
            echo "  $BASENAME -> $TARGET"
        done
    else
        echo -e "${YELLOW}⚠${NC} No hay symlinks configurados"
        echo "  Puede que necesites crear uno si VS Code espera un commit diferente"
    fi
else
    echo -e "${YELLOW}⚠${NC} Directorio bin no existe"
fi

echo ""

# 6. Conectividad SSH
echo -e "${BLUE}6. Conectividad SSH${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$SSH_CONNECTION" ]; then
    echo -e "${GREEN}✓${NC} Conectado vía SSH"
    echo "  Conexión: $SSH_CONNECTION"
else
    echo -e "${YELLOW}⚠${NC} No conectado vía SSH (ejecución local)"
fi

# Verificar servicio SSH
if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}✓${NC} Servicio SSH activo"
else
    echo -e "${RED}✗${NC} Servicio SSH inactivo"
fi

echo ""

# 7. Resumen y recomendaciones
echo -e "${BLUE}7. Resumen${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUES=0

# Verificar GLIBC
if (( $(echo "$GLIBC_VERSION < 2.28" | bc -l) )); then
    if [ ! -d "$LEGACY_DIR/bin/$COMPATIBLE_COMMIT" ]; then
        echo -e "${RED}✗${NC} Necesitas instalar el servidor legacy"
        echo "  Comando: ~/minicluster/jetson-01/scripts/install-vscode-server.sh"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo -e "${GREEN}✓${NC} Tu sistema es compatible con servidores modernos"
fi

# Verificar directorio legacy
if [ ! -d "$LEGACY_DIR" ]; then
    echo -e "${RED}✗${NC} Directorio legacy no existe"
    ISSUES=$((ISSUES + 1))
fi

# Verificar conflictos
if [ -d "$NORMAL_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Existe directorio .vscode-server (puede causar conflictos)"
    echo "  Considera: rm -rf $NORMAL_DIR"
    ISSUES=$((ISSUES + 1))
fi

echo ""

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Sistema configurado correctamente      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠ Se encontraron $ISSUES problema(s)              ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
fi

echo ""
echo "Para más información consulta:"
echo "  ~/minicluster/jetson-01/docs/VSCODE_REMOTE_SSH.md"
echo ""
