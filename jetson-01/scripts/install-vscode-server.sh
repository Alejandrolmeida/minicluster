#!/bin/bash
# Script de instalación de VS Code Server compatible con GLIBC 2.27
# Para Jetson Nano con Ubuntu 18.04/20.04
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

# Configuración
VSCODE_SERVER_DIR="$HOME/.vscode-server-legacy"
BIN_DIR="$VSCODE_SERVER_DIR/bin"
# Versión compatible con GLIBC 2.27
COMPATIBLE_COMMIT="8b3775030ed1a69b13e4f4c628c612102e30a681"
DOWNLOAD_URL="https://update.code.visualstudio.com/commit:${COMPATIBLE_COMMIT}/server-linux-arm64/stable"

print_header "Instalación de VS Code Server para Jetson Nano"

echo "Hostname: $(hostname)"
echo "Usuario: $(whoami)"
echo "Arquitectura: $(uname -m)"
echo ""

# Verificar arquitectura
if [ "$(uname -m)" != "aarch64" ]; then
    print_error "Este script es para arquitectura ARM64 (aarch64)"
    print_info "Detectado: $(uname -m)"
    exit 1
fi

# Verificar versión de GLIBC
print_header "1. Verificando versión de GLIBC"
GLIBC_VERSION=$(ldd --version | head -n1 | grep -oP '\d+\.\d+' | head -n1)
print_info "GLIBC versión detectada: $GLIBC_VERSION"

if [ "$(echo "$GLIBC_VERSION < 2.28" | bc)" -eq 1 ]; then
    print_warning "GLIBC $GLIBC_VERSION < 2.28 (se necesita servidor legacy)"
else
    print_warning "Tu sistema tiene GLIBC $GLIBC_VERSION, podrías usar un servidor más reciente"
    print_info "Este script instalará la versión legacy de todas formas"
fi

# Crear directorio
print_header "2. Creando directorios"
mkdir -p "$BIN_DIR"
print_success "Directorio creado: $BIN_DIR"

# Limpiar instalaciones antiguas en el directorio legacy
if [ -d "$BIN_DIR/$COMPATIBLE_COMMIT" ]; then
    print_warning "Ya existe instalación del commit $COMPATIBLE_COMMIT"
    read -p "¿Reinstalar? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        rm -rf "$BIN_DIR/$COMPATIBLE_COMMIT"
        print_info "Instalación anterior eliminada"
    else
        print_info "Manteniendo instalación existente"
        print_success "Script completado (sin cambios)"
        exit 0
    fi
fi

# Descargar servidor
print_header "3. Descargando VS Code Server compatible"
print_info "Commit: $COMPATIBLE_COMMIT"
print_info "URL: $DOWNLOAD_URL"
print_info "Esto puede tardar varios minutos..."

cd "$BIN_DIR"

if ! wget -O vscode-server.tar.gz "$DOWNLOAD_URL"; then
    print_error "Error al descargar el servidor"
    print_info "Verifica tu conexión a Internet"
    exit 1
fi

print_success "Descarga completada"

# Extraer
print_header "4. Extrayendo servidor"
tar -xzf vscode-server.tar.gz
rm vscode-server.tar.gz

# Renombrar al commit ID
mv vscode-server-linux-* "$COMPATIBLE_COMMIT"
print_success "Servidor extraído en: $BIN_DIR/$COMPATIBLE_COMMIT"

# Crear archivo marker (para que VS Code sepa que está instalado)
touch "$BIN_DIR/$COMPATIBLE_COMMIT/0"

# Listar contenido
print_header "5. Verificando instalación"
if [ -d "$BIN_DIR/$COMPATIBLE_COMMIT" ]; then
    print_success "Servidor instalado correctamente"
    ls -lh "$BIN_DIR/$COMPATIBLE_COMMIT" | head -n 10
    echo "..."
else
    print_error "Error: Directorio no encontrado"
    exit 1
fi

# Información sobre symlinks
print_header "6. Resumen"
print_success "VS Code Server instalado en: $BIN_DIR/$COMPATIBLE_COMMIT"
echo ""
print_info "IMPORTANTE: Configuración de VS Code en tu PC Windows"
print_info ""
print_info "1. Abre VS Code settings.json (Ctrl+Shift+P → Preferences: Open User Settings (JSON))"
print_info ""
print_info "2. Añade esta configuración:"
echo ""
echo -e "${YELLOW}  {${NC}"
echo -e "${YELLOW}    \"remote.SSH.serverInstallPath\": {${NC}"
echo -e "${YELLOW}      \"$(hostname)\": \"$VSCODE_SERVER_DIR\"${NC}"
echo -e "${YELLOW}    }${NC}"
echo -e "${YELLOW}  }${NC}"
echo ""
print_info "3. Si VS Code espera un commit diferente, crea un symlink:"
echo ""
echo -e "${YELLOW}  cd $BIN_DIR${NC}"
echo -e "${YELLOW}  ln -sf $COMPATIBLE_COMMIT <COMMIT_ID_ESPERADO>${NC}"
echo ""
print_info "   (Revisa los logs de Remote-SSH para ver qué commit espera)"
echo ""
print_success "Instalación completada!"
echo ""
