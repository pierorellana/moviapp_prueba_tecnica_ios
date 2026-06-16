# MoviApp

**MoviApp** es una aplicación iOS desarrollada para la prueba técnica. La app consume un API REST de movimientos, protege el acceso con biometría, permite buscar, filtrar, paginar, refrescar, archivar movimientos localmente y consultar el detalle de cada movimiento en un modal.

## Evidencia visual

### Video funcional

[![Video funcional de MoviApp](Evidencia%20Visual/video-funcional-preview.gif)](<Evidencia Visual/Video Funcional.mp4>)

[Ver video funcional](<Evidencia Visual/Video Funcional.mp4>)

### Caso sin biometría

Esta captura evidencia el estado que se presenta cuando el dispositivo no cuenta con biometría disponible o no tiene un método biométrico configurado.

![Caso sin biometría](Evidencia%20Visual/caso-sin-biometria.png)

## Cómo ejecutar el proyecto

1. Abrir `MoviApp.xcodeproj` en Xcode.
2. Seleccionar el scheme `MoviApp`.
3. Ejecutar la app en un simulador o dispositivo iOS.

La app inicia en la pantalla de autenticación biométrica. En simulador, se debe activar Face ID desde el menú del simulador antes de probar el flujo.

## URL del API

La URL base está centralizada en:

```text
MoviApp/Core/Config/AppConfig.swift
```

URL configurada:

```swift
https://w3qz8bsw-7217.use.devtunnels.ms
```

Para listar movimientos se consume:

```http
GET /api/movements?page=1&pageSize=30&fromDate=yyyy-MM-dd&toDate=yyyy-MM-dd&search=texto&sort=date_desc
```

Para consultar el detalle de un movimiento se consume:

```http
GET /api/Movements/{id}
```

## Funcionalidades implementadas

- Autenticación con `LocalAuthentication` usando Face ID, Touch ID u otro método biométrico disponible.
- Pantalla de autenticación en SwiftUI con estados visuales para carga, éxito, error y reintento.
- Cliente HTTP propio con `URLSession`, `async/await`, interceptor de requests y manejo centralizado de errores.
- Logs de red para ver request, status code, tiempo de respuesta y body de respuesta en consola.
- Pantalla de movimientos con búsqueda, filtros, rango de fechas, paginación e infinite scroll.
- Modal de detalle al tocar un movimiento, consumiendo el endpoint por `id`.
- Archivado/desarchivado local con Core Data.
- Toast visual para confirmar acciones sin interrumpir al usuario con alertas nativas.
- Componentes reutilizables para estados, tarjetas, resumen, detalle y notificaciones.

## Arquitectura

El proyecto está organizado siguiendo una separación por capas y responsabilidades:

- `Core`: configuración, networking, logging, DI y persistencia.
- `Domain`: modelos y protocolos.
- `Data`: DTOs y repositorios remotos.
- `Features`: pantallas y ViewModels por funcionalidad.
- `Shared`: componentes reutilizables.

Se usa MVVM en las pantallas principales. Las vistas solo renderizan estado y delegan acciones al ViewModel. Los repositorios y servicios dependen de protocolos para facilitar pruebas y cambios futuros.

## Biometría

`LocalAuthentication` está encapsulado detrás de `BiometricAuthenticating`. Con esto se evita que la vista conozca directamente `LAContext`.

Se manejan estos escenarios:

- biometría disponible
- biometría no configurada
- dispositivo sin biometría
- cancelación del usuario
- bloqueo temporal
- reintento

## Networking e interceptor

El consumo de servicios está centralizado en `APIClient`. Antes de enviar cada request, este pasa por `RequestInterceptor`, donde se agregan headers JSON, plataforma y timeout.

Los errores de transporte, HTTP, respuesta vacía y decodificación se transforman en `NetworkError`, para que la UI reciba mensajes controlados.

## Movimientos

En la pantalla principal se muestra:

- resumen neto y contadores de movimientos
- búsqueda con debounce
- filtros `Todos`, `Archivados` y `Desarchivados`
- filtro por rango de fechas
- lista agrupada por fecha
- scroll infinito
- pull to refresh
- acciones por swipe para archivar o desarchivar

Al tocar una tarjeta se consulta el detalle del movimiento y se presenta en un sheet con monto, estado, persona, descripción, referencia, fecha, categoría, canal, cuenta e ID del movimiento.

## Core Data

El backend no persiste archivados, por lo que esa información se guarda localmente en Core Data. Se usa un modelo programático para almacenar el `id` del movimiento y la fecha de archivado.

Cuando se reciben movimientos del API, esos IDs locales se cruzan con la respuesta remota para marcar cada movimiento como archivado o desarchivado.

## Decisiones de UI

La interfaz busca sentirse simple, clara y cuidada:

- La autenticación se muestra como una pantalla de seguridad clara y dinámica.
- La lista de movimientos usa tarjetas visuales con color según tipo de movimiento.
- El detalle se abre en un modal para no sacar al usuario del flujo principal.
- Las confirmaciones de archivar/desarchivar usan un toast animado en lugar de una alerta bloqueante.
- Los filtros y acciones se mantienen cerca del contexto donde se usan.

## Escalabilidad

Para escalar de 1.500 a 50.000 movimientos se mantendría la paginación server-side y se agregarían índices en fecha, referencia y campos de búsqueda.

En iOS se conservarían listas livianas, se evitaría cargar detalles hasta que el usuario los abra, se cachearían páginas recientes y se evaluaría paginación por cursor si la estabilidad del scroll se vuelve crítica.

## Pruebas

Las pruebas unitarias cubren:

- autenticación biométrica exitosa mockeada
- error de biometría
- carga inicial de movimientos
- carga de siguiente página
- bloqueo de doble carga
- agrupación por fecha
- archivar y desarchivar
- filtros de archivados/desarchivados
- pull to refresh reiniciando paginación
- consulta de detalle al seleccionar un movimiento

Se pueden ejecutar desde Xcode con:

```text
Product > Test
```
