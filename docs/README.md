# 📚 Documentación del MiniCluster

Esta carpeta contiene la documentación técnica completa sobre la configuración y resolución de problemas del cluster.

## 📖 Guías Disponibles

### Configuración y Estado Actual

- **[RESOLUCION-COMPLETA.md](RESOLUCION-COMPLETA.md)** - Resumen completo de la resolución del problema de internet en jetson-01
  - Diagnóstico del problema original
  - Solución implementada (Tailscale subnet routing)
  - Arquitectura final del cluster
  - Comandos de referencia y troubleshooting

- **[CONFIGURACION-TAILSCALE-COMPLETADA.md](CONFIGURACION-TAILSCALE-COMPLETADA.md)** - Estado completo de la configuración Tailscale
  - Tabla de nodos con Tailscale activo/inactivo
  - Verificaciones de conectividad
  - Configuración de resolución de nombres
  - Próximos pasos opcionales

### Análisis Técnico

- **[SOLUCION-INTERNET-JETSON.md](SOLUCION-INTERNET-JETSON.md)** - Análisis detallado del problema de DNS
  - Causa raíz del problema
  - DNS de Tailscale vs DNS local
  - Decisiones de arquitectura tomadas
  - Justificación técnica

- **[COMO-FUNCIONA-EL-ROUTING.md](COMO-FUNCIONA-EL-ROUTING.md)** - Explicación completa del routing del cluster
  - Tabla de rutas en Windows
  - Flujo completo de paquetes
  - Verificación práctica
  - Comparación con alternativas

## 🎯 ¿Por Dónde Empezar?

### Si eres nuevo en el proyecto
👉 Lee primero [../README.md](../README.md) en la raíz del repositorio

### Si quieres entender la arquitectura Tailscale
👉 Lee [COMO-FUNCIONA-EL-ROUTING.md](COMO-FUNCIONA-EL-ROUTING.md)

### Si tienes problemas de conectividad
👉 Consulta [RESOLUCION-COMPLETA.md](RESOLUCION-COMPLETA.md) sección "Troubleshooting"

### Si quieres ver el estado actual
👉 Revisa [CONFIGURACION-TAILSCALE-COMPLETADA.md](CONFIGURACION-TAILSCALE-COMPLETADA.md)

## 🔗 Otras Documentaciones

- **Raspberry Pi rpi-02**: [../rpi-02/README.md](../rpi-02/README.md)
  - [Instalación desde cero](../rpi-02/docs/INSTALACION_DESDE_CERO.md)
  - [Tailscale Subnet Router](../rpi-02/docs/TAILSCALE_SUBNET_ROUTER.md)

- **Jetson Nano jetson-01**: [../jetson-01/README.md](../jetson-01/README.md)
  - [VS Code Remote SSH](../jetson-01/docs/VSCODE_REMOTE_SSH.md)
  - [Guía rápida](../jetson-01/docs/QUICKSTART.md)
  - [Troubleshooting](../jetson-01/docs/TROUBLESHOOTING.md)

- **Scripts**: [../scripts/](../scripts/)
  - [Instrucciones para remover Tailscale](../scripts/INSTRUCCIONES-REMOVER-TAILSCALE.md)

## 📅 Historial

- **2026-02-18**: Resolución del problema de internet en jetson-01
  - Simplificación de arquitectura Tailscale
  - Configuración de subnet routing en rpi-02
  - Remoción de Tailscale de workers
  - Configuración de resolución de nombres (hosts file)
  - Documentación completa creada

---

**Mantenido por**: Alejandro Almeida  
**Última actualización**: Febrero 2026
