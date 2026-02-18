# Script para añadir hosts del MiniCluster al archivo hosts de Windows
# Ejecutar como Administrador

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Configurar archivo hosts - MiniCluster" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar permisos de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: Este script debe ejecutarse como Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "Click derecho en PowerShell → 'Ejecutar como administrador'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona ENTER para salir"
    exit 1
}

Write-Host "✓ Permisos de administrador verificados" -ForegroundColor Green
Write-Host ""

# Ruta del archivo hosts
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

# Backup del archivo hosts
$backupPath = "C:\Windows\System32\drivers\etc\hosts.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "Creando backup del archivo hosts..." -ForegroundColor Yellow
Copy-Item -Path $hostsPath -Destination $backupPath
Write-Host "  ✓ Backup creado: $backupPath" -ForegroundColor Green
Write-Host ""

# Entradas a añadir
$entries = @"

# ================================================
# MiniCluster - Configurado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ================================================

# Nodos Jetson Nano (GPU)
192.168.50.11   jetson-01
192.168.50.12   jetson-02
192.168.50.13   jetson-03

# Nodos Raspberry Pi
192.168.50.1    rpi-02 gateway
192.168.50.23   rpi-03
192.168.50.25   rpi-05

# Switch del cluster
192.168.50.2    cluster-switch

# Fin MiniCluster
# ================================================

"@

# Leer archivo actual
$currentHosts = Get-Content $hostsPath -Raw

# Verificar si ya están las entradas
if ($currentHosts -match "# MiniCluster") {
    Write-Host "⚠️  AVISO: Ya existen entradas del MiniCluster en el archivo hosts" -ForegroundColor Yellow
    Write-Host ""
    $overwrite = Read-Host "¿Quieres sobrescribirlas? (S/N)"
    
    if ($overwrite -eq "S" -or $overwrite -eq "s") {
        # Eliminar entradas antiguas
        $pattern = "(?s)# ={40,}\r?\n# MiniCluster.*?# ={40,}\r?\n"
        $currentHosts = $currentHosts -replace $pattern, ""
        Write-Host "  ✓ Entradas antiguas eliminadas" -ForegroundColor Green
    } else {
        Write-Host "Operación cancelada" -ForegroundColor Yellow
        Read-Host "Presiona ENTER para salir"
        exit 0
    }
}

# Añadir nuevas entradas
$newHosts = $currentHosts.TrimEnd() + "`n" + $entries

# Guardar
Write-Host "Actualizando archivo hosts..." -ForegroundColor Yellow
Set-Content -Path $hostsPath -Value $newHosts -NoNewline
Write-Host "  ✓ Archivo hosts actualizado" -ForegroundColor Green
Write-Host ""

# Limpiar cache DNS
Write-Host "Limpiando cache DNS..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
Write-Host "  ✓ Cache DNS limpiada" -ForegroundColor Green
Write-Host ""

Write-Host "================================================================" -ForegroundColor Green
Write-Host "¡Configuración completada!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Entradas añadidas al archivo hosts:" -ForegroundColor Yellow
Write-Host $entries
Write-Host ""

Write-Host "Ahora puedes usar los nombres directamente:" -ForegroundColor Yellow
Write-Host "  ping jetson-01" -ForegroundColor Cyan
Write-Host "  ssh jetson-01" -ForegroundColor Cyan
Write-Host "  ssh rpi-03" -ForegroundColor Cyan
Write-Host ""

$test = Read-Host "¿Quieres probar ahora? (S/N)"
if ($test -eq "S" -or $test -eq "s") {
    Write-Host ""
    Write-Host "=== Test 1: Ping a jetson-01 ===" -ForegroundColor Cyan
    ping -n 2 jetson-01
    
    Write-Host ""
    Write-Host "=== Test 2: Ping a jetson-02 ===" -ForegroundColor Cyan
    ping -n 2 jetson-02
    
    Write-Host ""
    Write-Host "=== Test 3: Ping a rpi-03 ===" -ForegroundColor Cyan
    ping -n 2 rpi-03
    
    Write-Host ""
    Write-Host "=== Test 4: Resolución de nombres ===" -ForegroundColor Cyan
    Write-Host "jetson-01:" -ForegroundColor Yellow -NoNewline
    Write-Host " $(Test-NetConnection -ComputerName jetson-01 -InformationLevel Quiet)"
    Write-Host "jetson-02:" -ForegroundColor Yellow -NoNewline
    Write-Host " $(Test-NetConnection -ComputerName jetson-02 -InformationLevel Quiet)"
    Write-Host "rpi-03:" -ForegroundColor Yellow -NoNewline
    Write-Host " $(Test-NetConnection -ComputerName rpi-03 -InformationLevel Quiet)"
}

Write-Host ""
Write-Host "NOTA: Si necesitas revertir los cambios:" -ForegroundColor Yellow
Write-Host "  Se creó un backup en: $backupPath" -ForegroundColor White
Write-Host ""

Read-Host "Presiona ENTER para salir"
