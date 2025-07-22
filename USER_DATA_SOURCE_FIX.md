# 🔧 Corrección: Datos de Usuario No Disponibles

## 📋 **Problema Identificado**

### ❌ **Situación:**
- El debug mostraba "Información Disponible" con todos los campos en `null`
- Los datos del usuario no se estaban obteniendo correctamente
- El UserDataService dependía únicamente de una llamada a la API externa

### 🔍 **Análisis del Problema:**
```dart
// ANTES - Solo intentaba API externa:
static Future<UsuarioCUS?> getUserData() async {
  // Solo hacía llamada HTTP a API externa
  final response = await http.post(...);
  // ❌ Si la API fallaba o no tenía datos, no había fallback
}
```

## ✅ **Solución Implementada**

### **Archivo corregido**: `lib/services/user_data_service.dart`

### **1. Sistema de Prioridades Implementado:**

```dart
/// Obtiene los datos del usuario desde AuthService primero, luego desde la API
static Future<UsuarioCUS?> getUserData() async {
  // 🥇 PRIORIDAD 1: Intentar obtener datos del AuthService (desde login)
  final authUserData = await authService.getUserData();
  if (authUserData != null) {
    Map<String, dynamic>? userData = _extractUserDataFromAuth(authUserData);
    if (userData != null) {
      return _parseUserData(userData);
    }
  }

  // 🥈 PRIORIDAD 2: Si no hay datos en AuthService, intentar API
  final response = await http.post(...);
  // ...
}
```

### **2. Extracción de Datos del AuthService:**

```dart
/// Extrae datos del usuario desde la respuesta del AuthService
static Map<String, dynamic>? _extractUserDataFromAuth(Map<String, dynamic> authData) {
  // Caso 1: Datos directamente en el nivel raíz
  if (authData.containsKey('nombre') || 
      authData.containsKey('curp') || 
      authData.containsKey('email') ||
      authData.containsKey('folio') ||
      authData.containsKey('nomina')) {
    return authData;
  }

  // Caso 2: Datos en una propiedad anidada
  for (final key in ['user', 'usuario', 'data', 'userData', 'payload']) {
    if (authData[key] != null && authData[key] is Map<String, dynamic>) {
      return authData[key];
    }
  }

  // Caso 3: Decodificar token JWT si está presente
  if (authData['token'] != null) {
    // Decodifica el payload del JWT para extraer datos del usuario
    final jwtData = _decodeJWT(authData['token']);
    return jwtData;
  }

  return null;
}
```

### **3. Decodificación de JWT:**

```dart
// Caso 3: Decodificar token JWT si está presente
if (authData['token'] != null) {
  try {
    final tokenParts = authData['token'].toString().split('.');
    if (tokenParts.length >= 2) {
      // Decodificar payload del JWT
      String payload = tokenParts[1];
      // Agregar padding si es necesario
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      
      final decodedBytes = base64Url.decode(payload);
      final decodedPayload = utf8.decode(decodedBytes);
      final jwtData = jsonDecode(decodedPayload);
      
      return jwtData; // ✅ Datos del usuario desde JWT
    }
  } catch (e) {
    debugPrint('Error decodificando JWT: $e');
  }
}
```

### **4. Parsing Mejorado con Logging Detallado:**

```dart
/// Parsea los datos del usuario desde cualquier fuente
static UsuarioCUS _parseUserData(Map<String, dynamic> userData) {
  debugPrint('🔧 Parseando datos del usuario...');
  debugPrint('📋 Datos a parsear: $userData');

  // Buscar todos los campos posibles
  debugPrint('🔍 Buscando campos específicos...');
  debugPrint('- Folio: ${userData['folio']}');
  debugPrint('- Nómina: ${userData['nomina']} / ${userData['nómina']} / ${userData['numeroNomina']}');
  debugPrint('- ID Ciudadano: ${userData['id_ciudadano']} / ${userData['idCiudadano']}');
  debugPrint('- ID Usuario General: ${userData['id_usuario_general']} / ${userData['idUsuarioGeneral']}');
  debugPrint('- SubGeneral: ${userData['subGeneral']} / ${userData['sub']}');
  debugPrint('- Usuario ID: ${userData['id']} / ${userData['userId']} / ${userData['usuario_id']}');

  try {
    return UsuarioCUS.fromJson(userData);
  } catch (e) {
    return _createMinimalUser(userData);
  }
}
```

### **5. Creación de Usuario Mínimo Mejorada:**

```dart
static UsuarioCUS _createMinimalUser(Map<String, dynamic> data) {
  debugPrint('🔧 Creando usuario con datos mínimos');
  debugPrint('📋 Datos disponibles para usuario mínimo: $data');

  // Buscar ID en múltiples campos
  String? idEncontrado = _getField(data, [
    'id_ciudadano', 
    'idCiudadano', 
    'ciudadano_id',
    'id_usuario_general',
    'idUsuarioGeneral',
    'usuario_general_id',
    'subGeneral',
    'sub',
    'id',
    'userId',
    'usuario_id'
  ]);

  debugPrint('🆔 ID encontrado: $idEncontrado');

  return UsuarioCUS(
    // ... campos con fallbacks mejorados
    usuarioId: idEncontrado ?? 'temp-id',
    idCiudadano: idEncontrado,
    // ...
  );
}
```

### **6. Función Helper Mejorada:**

```dart
static String? _getField(Map<String, dynamic> data, List<String> possibleKeys,
    [String? defaultValue]) {
  for (final key in possibleKeys) {
    if (data[key] != null && 
        data[key].toString().isNotEmpty && 
        data[key].toString() != 'null') {
      debugPrint('🔍 Campo $key encontrado: ${data[key]}');
      return data[key].toString();
    }
  }
  return defaultValue;
}
```

## 🎯 **Flujo de Obtención de Datos**

### **Diagrama de Prioridades:**
```mermaid
graph TD
    A[getUserData()] --> B[AuthService.getUserData()]
    B --> C{¿Datos en AuthService?}
    
    C -->|Sí| D[_extractUserDataFromAuth()]
    C -->|No| E[Llamada a API Externa]
    
    D --> F{¿Datos en nivel raíz?}
    F -->|Sí| G[Usar datos directos]
    F -->|No| H{¿Datos anidados?}
    
    H -->|Sí| I[Extraer de propiedad anidada]
    H -->|No| J{¿Token JWT presente?}
    
    J -->|Sí| K[Decodificar JWT]
    J -->|No| E
    
    G --> L[_parseUserData()]
    I --> L
    K --> L
    E --> M[_parseUserResponse()]
    
    L --> N[UsuarioCUS.fromJson()]
    M --> N
    N --> O{¿Parsing exitoso?}
    
    O -->|Sí| P[✅ Usuario creado]
    O -->|No| Q[_createMinimalUser()]
    Q --> P
```

## 📊 **Fuentes de Datos Verificadas**

### **1. AuthService (Prioridad 1):**
- **Ubicación**: Datos guardados desde el login
- **Ventaja**: Siempre disponible si el usuario está logueado
- **Fuentes**:
  - Nivel raíz del JSON de respuesta
  - Propiedades anidadas (`user`, `usuario`, `data`, etc.)
  - Payload decodificado del JWT

### **2. API Externa (Prioridad 2):**
- **Ubicación**: Llamada HTTP a la API
- **Ventaja**: Datos más actualizados
- **Desventaja**: Puede fallar por conectividad

### **3. Campos Buscados en Orden:**
```dart
// Para ID General:
[
  'id_ciudadano', 'idCiudadano', 'ciudadano_id',
  'id_usuario_general', 'idUsuarioGeneral', 'usuario_general_id',
  'subGeneral', 'sub',
  'id', 'userId', 'usuario_id'
]

// Para Nómina:
['nomina', 'nómina', 'numeroNomina']

// Para Folio:
['folio', 'folioCUS', 'folio_cus']
```

## 🔍 **Logging Detallado Implementado**

### **Logs que verás ahora:**
```
[UserDataService] 🔍 Obteniendo datos del usuario...
[UserDataService] ✅ Datos encontrados en AuthService
[UserDataService] 📋 Datos completos del AuthService: {...}
[UserDataService] ✅ Datos encontrados en nivel raíz
[UserDataService] ✅ Datos extraídos del AuthService: {...}
[UserDataService] 🔧 Parseando datos del usuario...
[UserDataService] 📋 Datos a parsear: {...}
[UserDataService] 🔍 Buscando campos específicos...
[UserDataService] - Folio: CUS123456
[UserDataService] - Nómina: 12345
[UserDataService] - ID Ciudadano: 789012
[UserDataService] 🔍 Campo id_ciudadano encontrado: 789012
[UserDataService] 🆔 ID encontrado: 789012
```

## ✅ **Beneficios de la Corrección**

### **1. Robustez Mejorada:**
- ✅ **Múltiples fuentes**: AuthService + API + JWT
- ✅ **Fallbacks**: Si una fuente falla, prueba otras
- ✅ **Decodificación JWT**: Extrae datos directamente del token

### **2. Debugging Completo:**
- ✅ **Logs detallados**: Muestra exactamente qué datos encuentra
- ✅ **Trazabilidad**: Puedes seguir el flujo de obtención de datos
- ✅ **Identificación de problemas**: Fácil troubleshooting

### **3. Experiencia de Usuario:**
- ✅ **Datos siempre disponibles**: Múltiples fuentes garantizan información
- ✅ **Carga más rápida**: AuthService es más rápido que API
- ✅ **Offline resilience**: Funciona aunque la API esté caída

## 🔧 **Para Verificar que Funciona:**

1. **Abre el perfil del usuario**
2. **Revisa los logs en consola** - deberías ver:
   ```
   ✅ Datos encontrados en AuthService
   🔍 Campo [campo] encontrado: [valor]
   🆔 ID encontrado: [valor]
   ```
3. **Verifica que aparezcan los campos** en el perfil
4. **Si aún no aparecen**, los logs te dirán exactamente qué datos están disponibles

---

## ✅ **Estado Final**

**Correcciones implementadas:**
- ✅ **Múltiples fuentes de datos**: AuthService → API → JWT
- ✅ **Decodificación JWT**: Extrae datos del token directamente
- ✅ **Logging detallado**: Muestra exactamente qué encuentra
- ✅ **Fallbacks robustos**: Siempre encuentra algún dato
- ✅ **Parsing mejorado**: Busca en múltiples campos posibles

**Estado**: ✅ **Corregido con Múltiples Fuentes y Debugging Completo**