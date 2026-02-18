# Script PowerShell para crear symlinks del servidor VS Code en todas las Jetsons
# Ejecutar desde Windows (PowerShell)
# Última actualización: Febrero 2026

# Configuración
$jetsons = @('jetson-01', 'jetson-02', 'jetson-03')
$compatibleCommit = '8b3775030ed1a69b13e4f4c628c612102e30a681'
$expectedCommit = 'c3a26841a84f20dfe0850d0a5a9bd01da4f003ea'  # Actualizar según tu versión de VS Code

Write-Host "`n=== Creando symlinks del servidor VS Code ===" -ForegroundColor Cyan
Write-Host "Commit compatible: $compatibleCommit" -ForegroundColor Green
Write-Host "Commit esperado:   $expectedCommit" -ForegroundColor Yellow
Write-Host ""

foreach ($jetson in $jetsons) {
    Write-Host "[$jetson] Procesando..." -ForegroundColor Cyan
    
    # Crear symlink del servidor compatible al esperado
    $sshCommand = @"
cd ~/.vscode-server-legacy/bin && \
ln -sf $compatibleCommit $expectedCommit && \
ls -la | grep -E '${compatibleCommit:0:7}|${expectedCommit:0:7}'
"@
    
    try {
        ssh $jetson $sshCommand 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$jetson] ✓ Symlink creado correctamente" -ForegroundColor Green
        } else {
            Write-Host "[$jetson] ⚠ Error al crear symlink" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[$jetson] ✗ Error de conexión: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=== Proceso completado ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora puedes intentar conectarte desde VS Code:" -ForegroundColor Yellow
Write-Host "  F1 -> Remote-SSH: Connect to Host -> jetson-01" -ForegroundColor White
Write-Host ""
