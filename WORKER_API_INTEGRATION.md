# Integración API de Registro de Trabajadores

## 📋 Resumen

Se ha integrado exitosamente la API de registro de trabajadores de San Juan del Río en el formulario de registro de trabajadores de la aplicación móvil.

## 🔗 Detalles de la API

- **URL**: `https://www.sanjuandelrio.gob.mx/tramites-sjr/Api/principal/insert full trabajador data mobile`
- **Método**: `POST`
- **API Key**: `8f26cd375a2e57fde8052e127974779eace180135bb64d456176a6c7b399fa6e`
- **Content-Type**: `application/json`

## 📁 Archivos Creados/Modificados

### Nuevos Archivos:
1. **`lib/services/worker_registration_service.dart`** - Servicio para comunicación con la API
2. **`lib/screens/work_screens/work_confirmation_screen.dart`** - Pantalla de confirmación y envío

### Archivos Modificados:
1. **`lib/screens/work_screens/work_preview_screen.dart`** - Actualizada navegación
2. **`lib/routes/routes.dart`** - Agregada nueva ruta

## 🔄 Flujo de Registro

1. **Datos del Trabajador** (`/work-data`)
   - Nómina, puesto, departamento
   - CURP y verificación
   - Nombre completo
   - Fecha de nacimiento (auto-extraída del CURP)
   - Contraseña

2. **Dirección** (`/work-direccion`)
   - Código postal, colonia, calle
   - Números exterior e interior
   - Coordenadas GPS

3. **Contacto** (`/work-contact`)
   - Email (opcional)
   - Teléfono (requerido)
   - Verificación SMS

4. **Términos y Condiciones** (`/work-terms`)
   - Aceptación de políticas

5. **Vista Previa** (`/work-preview`)
   - Revisión de todos los datos

6. **Confirmación** (`/work-confirmation`) ⭐ **NUEVO**
   - Envío automático a la API
   - Pantalla de resultado (éxito/error)

## 📤 Formato de Datos Enviados

```json
{
  "no_nomina": "0055",
  "departamento": "SECRETARIA DE ADMINISTRACION",
  "puesto": "PROGRAMADOR",
  "sexo": "MASCULINO",
  "estado": "QUERETARO",
  "nombre": "JUAN",
  "primer_apellido": "PEREZ",
  "segundo_apellido": "LOPEZ",
  "curp_trabajador": "PELJ900101HQTRZN01",
  "nombre_completo": "JUAN PEREZ LOPEZ",
  "fecha_nacimiento": "1990-01-01",
  "password": "MiPassword123@",
  "acepto_terminos_condiciones": 1,
  "tipo_asentamiento": false,
  "asentamiento": "CENTRO",
  "calle": "CALLE PRINCIPAL",
  "numero_exterior": "123",
  "numero_interior": "A",
  "codigo_postal": "76800",
  "latitud": "20.3881",
  "longitud": "-99.9737",
  "telefono": "4271234567",
  "email": "juan.perez@email.com",
  "tipo_telefono": true
}
```

## 🛠️ Características Implementadas

### ✅ Validación de Datos
- Validación de campos requeridos antes del envío
- Formato correcto de fecha de nacimiento (YYYY-MM-DD)
- Construcción automática del nombre completo

### ✅ Manejo de Errores
- Captura de errores de red
- Manejo de respuestas de error del servidor
- Pantalla de error con opción de reintentar

### ✅ Experiencia de Usuario
- Pantalla de carga durante el envío
- Animaciones de éxito/error
- Navegación automática al login tras registro exitoso
- Opción de volver atrás en caso de error

### ✅ Logging y Debugging
- Logs detallados en modo debug
- Información de request/response para troubleshooting

## 🔧 Configuración

### Headers de la API:
```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer 8f26cd375a2e57fde8052e127974779eace180135bb64d456176a6c7b399fa6e',
  'Accept': 'application/json',
}
```

### Mapeo de Datos:
El servicio `WorkerRegistrationService.formatDataForAPI()` se encarga de mapear automáticamente los datos del formulario al formato requerido por la API.

## 🧪 Testing

Para probar la integración:

1. Ejecutar la app en modo debug
2. Navegar al registro de trabajador
3. Completar todos los pasos del formulario
4. Verificar los logs en la consola durante el envío
5. Confirmar la respuesta de la API

## 📱 Estados de la Pantalla de Confirmación

1. **Loading**: Muestra spinner mientras se envían los datos
2. **Success**: Animación de éxito + botón para ir al login
3. **Error**: Mensaje de error + opciones para volver o reintentar

## 🔍 Troubleshooting

### Errores Comunes:
- **400 Bad Request**: Verificar formato de datos
- **401 Unauthorized**: Verificar API key
- **500 Server Error**: Problema en el servidor de la API
- **Network Error**: Problemas de conectividad

### Logs a Revisar:
```
[WorkerRegistrationService] 📤 Enviando datos a: [URL]
[WorkerRegistrationService] 📋 Datos: [JSON]
[WorkerRegistrationService] 📥 Status Code: [CODE]
[WorkerRegistrationService] 📥 Response: [RESPONSE]
```

## 🚀 Próximos Pasos

1. Probar con datos reales en el servidor de producción
2. Implementar manejo de respuestas específicas de la API
3. Agregar validaciones adicionales según requerimientos del servidor
4. Considerar implementar retry automático en caso de errores temporales

---

**Nota**: La integración está lista para usar. Solo asegúrate de que el servidor de la API esté disponible y configurado correctamente para recibir las peticiones.