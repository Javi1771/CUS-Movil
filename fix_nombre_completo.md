# 🔧 SOLUCIÓN PARA MOSTRAR NOMBRE COMPLETO CON APELLIDOS

## 📋 **Problema Identificado:**
El perfil del ciudadano solo muestra el nombre sin los apellidos porque el API probablemente solo envía el campo `nombre` sin `nombreCompleto` o los apellidos por separado.

## ✅ **Solución Implementada:**

### 1. **Función Mejorada en `perfil_ciudadano_screen.dart`**

Reemplaza la función `_getNombreCompleto()` existente con esta versión mejorada:

```dart
String _getNombreCompleto() {
  if (usuario == null) return 'Sin nombre';

  print('[PerfilCiudadano] 🔍 CONSTRUYENDO NOMBRE COMPLETO:');
  print('[PerfilCiudadano] - nombre: ${usuario!.nombre}');
  print('[PerfilCiudadano] - nombreCompleto: ${usuario!.nombreCompleto}');

  // 1. Priorizar nombreCompleto si existe y es diferente al nombre básico
  if (usuario!.nombreCompleto != null &&
      usuario!.nombreCompleto!.isNotEmpty &&
      usuario!.nombreCompleto!.trim().length > usuario!.nombre.trim().length) {
    print('[PerfilCiudadano] ✅ Usando nombreCompleto: ${usuario!.nombreCompleto}');
    return usuario!.nombreCompleto!;
  }

  // 2. Si solo tenemos el nombre básico, verificar si parece incompleto
  String nombreFinal = usuario!.nombre;
  
  if (nombreFinal.isNotEmpty && nombreFinal != 'Usuario Sin Nombre') {
    // Si el nombre no contiene espacios, probablemente solo es el primer nombre
    if (!nombreFinal.contains(' ')) {
      print('[PerfilCiudadano] ⚠️ Nombre parece incompleto (sin apellidos): $nombreFinal');
      // Mostrar advertencia de que faltan apellidos
      return '$nombreFinal [Apellidos no disponibles]';
    }
    
    // Si ya contiene espacios, probablemente es completo
    print('[PerfilCiudadano] ✅ Nombre parece completo: $nombreFinal');
    return nombreFinal;
  }

  print('[PerfilCiudadano] ❌ No hay nombre disponible');
  return 'Sin nombre completo';
}
```

### 2. **Mejoras en `user_data_service.dart`**

Se agregó una función para construir el nombre completo buscando apellidos en múltiples campos del JSON:

```dart
/// Construye el nombre completo combinando nombre y apellidos
static String? _buildFullName(Map<String, dynamic> data) {
  // Buscar nombre completo directo
  final nombreCompleto = _getField(data, [
    'nombreCompleto', 'nombre_completo', 'fullName', 'full_name',
    'displayName', 'display_name'
  ]);
  
  if (nombreCompleto != null && nombreCompleto.isNotEmpty) {
    debugPrint('[UserDataService] 👤 Nombre completo directo encontrado: $nombreCompleto');
    return nombreCompleto;
  }

  // Si no hay nombre completo, construirlo
  final nombre = _getField(data, ['nombre', 'name', 'firstName']);
  final apellidoPaterno = _getField(data, [
    'apellidoPaterno', 'apellido_paterno', 'lastName', 'last_name',
    'apellidoP', 'apellido1'
  ]);
  final apellidoMaterno = _getField(data, [
    'apellidoMaterno', 'apellido_materno', 'middleName', 'middle_name',
    'apellidoM', 'apellido2'
  ]);

  if (nombre != null && nombre.isNotEmpty) {
    final partes = <String>[nombre];
    if (apellidoPaterno != null && apellidoPaterno.isNotEmpty) {
      partes.add(apellidoPaterno);
    }
    if (apellidoMaterno != null && apellidoMaterno.isNotEmpty) {
      partes.add(apellidoMaterno);
    }
    
    final nombreConstruido = partes.join(' ');
    debugPrint('[UserDataService] 👤 Nombre completo construido: $nombreConstruido');
    return nombreConstruido;
  }

  return null;
}
```

## 🎯 **Resultado Esperado:**

1. **Si el API envía `nombreCompleto`**: Se mostrará tal como viene
2. **Si el API envía `apellidoPaterno` y `apellidoMaterno`**: Se construirá "Nombre ApellidoPaterno ApellidoMaterno"
3. **Si solo envía `nombre`**: Se mostrará "Nombre [Apellidos no disponibles]"

## 🔍 **Para Debugging:**

Los logs mostrarán exactamente qué campos están disponibles y cómo se construye el nombre:

```
[PerfilCiudadano] 🔍 CONSTRUYENDO NOMBRE COMPLETO:
[PerfilCiudadano] - nombre: Juan
[PerfilCiudadano] - nombreCompleto: null
[PerfilCiudadano] ⚠️ Nombre parece incompleto (sin apellidos): Juan
```

## 📱 **Implementación:**

1. Copia la función `_getNombreCompleto()` mejorada
2. Reemplázala en `lib/screens/perfiles/perfil_ciudadano_screen.dart`
3. Ejecuta la app y verifica los logs para ver qué campos están disponibles
4. Si el API tiene los apellidos en campos separados, se construirá automáticamente el nombre completo

## 🚀 **Próximos Pasos:**

Si después de implementar esto sigues viendo solo el nombre, significa que el API realmente no está enviando los apellidos. En ese caso, necesitarías:

1. **Verificar la respuesta del API** para ver qué campos están disponibles
2. **Contactar al backend** para que incluya los apellidos en la respuesta
3. **Usar el CURP** como fuente alternativa (más complejo)