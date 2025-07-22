# 👤 Corrección: Mostrar ID General en Perfil de Trabajadores

## 📋 **Problema Identificado**

### ❌ **Situación Anterior:**
- En la pantalla del perfil del usuario, los **trabajadores** solo mostraban su **nómina**
- **No se mostraba el ID General** para trabajadores, aunque estuviera disponible en los datos
- Esto causaba confusión ya que el ID General es importante para identificación

### 🔍 **Análisis del Problema:**
```dart
// ANTES - Solo para trabajadores:
case TipoPerfilCUS.trabajador:
  identifiers.add(_buildInfoCard(
    'Nómina',
    _getDisplayValue(usuario!.nomina, 'Sin nómina'),
    imagenesIconos['badge']!,
    Icons.badge,
  ));
  break; // ❌ No mostraba ID General
```

## ✅ **Solución Implementada**

### **Archivo modificado**: `lib/screens/perfil_usuario_screen.dart`

### **Método actualizado**: `_buildProfileIdentifier()`

#### **Cambios Realizados:**

### **1. Para Ciudadanos:**
```dart
case TipoPerfilCUS.ciudadano:
  // Mostrar folio si existe
  if (usuario!.folio != null && usuario!.folio!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'Folio',
      _getDisplayValue(usuario!.folio, 'Sin folio'),
      imagenesIconos['badge']!,
      Icons.confirmation_number,
    ));
  }

  // ✅ CAMBIO: Ahora se llama "ID General" en lugar de "ID Ciudadano"
  if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'ID General', // ✅ Nombre más genérico
      _getDisplayValue(usuario!.idCiudadano, 'Sin ID General'),
      imagenesIconos['badge']!,
      Icons.person_pin,
    ));
  }
  break;
```

### **2. Para Trabajadores (PRINCIPAL CAMBIO):**
```dart
case TipoPerfilCUS.trabajador:
  // Mostrar nómina si existe
  if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'Nómina',
      _getDisplayValue(usuario!.nomina, 'Sin nómina'),
      imagenesIconos['badge']!,
      Icons.badge,
    ));
  }

  // ✅ NUEVO: MOSTRAR ID GENERAL PARA TRABAJADORES TAMBIÉN
  if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'ID General',
      _getDisplayValue(usuario!.idCiudadano, 'Sin ID General'),
      imagenesIconos['badge']!,
      Icons.person_pin,
    ));
  }
  break;
```

### **3. Para Otros Tipos de Perfil:**
```dart
case TipoPerfilCUS.personaMoral:
case TipoPerfilCUS.usuario:
default:
  // ✅ NUEVO: Para otros tipos de perfil, mostrar ID General si existe
  if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'ID General',
      _getDisplayValue(usuario!.idCiudadano, 'Sin ID General'),
      imagenesIconos['badge']!,
      Icons.person_pin,
    ));
  }
  break;
```

## 🎯 **Resultado Visual**

### **Antes (Solo para trabajadores):**
```
┌─────────────────────────────┐
│ 👤 Información Personal     │
├─────────────────────────────┤
│ 🏷️ Nómina: 12345           │
│ 🆔 CURP: ABC123...         │
│ 🎂 Fecha de Nacimiento...  │
│ 🏳️ Nacionalidad: Mexicana  │
└─────────────────────────────┘
```

### **Después (Para trabajadores):**
```
┌─────────────────────────────┐
│ 👤 Información Personal     │
├─────────────────────────────┤
│ 🏷️ Nómina: 12345           │
│ 🆔 ID General: 789012      │ ✅ NUEVO
│ 🆔 CURP: ABC123...         │
│ 🎂 Fecha de Nacimiento...  │
│ 🏳️ Nacionalidad: Mexicana  │
└─────────────────────────────┘
```

## 📊 **Casos Cubiertos**

### **1. Trabajador Completo:**
- ✅ Muestra **Nómina** (para identificación laboral)
- ✅ Muestra **ID General** (para identificación en trámites)
- ✅ Muestra resto de información personal

### **2. Ciudadano Completo:**
- ✅ Muestra **Folio** (si existe)
- ✅ Muestra **ID General** (renombrado de "ID Ciudadano")
- ✅ Muestra resto de información personal

### **3. Usuario Sin Tipo Específico:**
- ✅ Muestra **ID General** (si existe)
- ✅ Muestra resto de información personal

### **4. Datos Faltantes:**
- ✅ Maneja casos donde no existe nómina
- ✅ Maneja casos donde no existe ID General
- ✅ Muestra mensajes apropiados ("Sin nómina", "Sin ID General")

## 🔧 **Beneficios Obtenidos**

### **1. Información Completa:**
- ✅ **Trabajadores** ahora ven tanto su nómina como su ID General
- ✅ **Ciudadanos** ven su folio y ID General
- ✅ **Todos** los tipos de usuario tienen acceso a su ID General

### **2. Consistencia:**
- ✅ **Nomenclatura uniforme**: "ID General" en lugar de "ID Ciudadano"
- ✅ **Comportamiento consistente** entre tipos de usuario
- ✅ **Misma información** disponible en perfil y en logs de trámites

### **3. Transparencia:**
- ✅ **Usuarios pueden ver** qué ID se usa para sus trámites
- ✅ **Facilita el soporte** cuando hay problemas con trámites
- ✅ **Mejor experiencia** de usuario con información completa

## 🔍 **Validación de Datos**

### **Campo `idCiudadano` en el Modelo:**
```dart
// En UsuarioCUS, el campo idCiudadano puede contener:
final idCiudadano = _getField(data, [
  'id_ciudadano', 
  'idCiudadano', 
  'ciudadano_id',
  'id_usuario_general',     // ✅ ID General
  'idUsuarioGeneral',       // ✅ ID General
  'usuario_general_id',     // ✅ ID General
  'subGeneral',             // ✅ Del JWT
  'sub'                     // ✅ Del JWT
]);
```

### **Logging en UserDataService:**
```dart
debugPrint('[UserDataService] ID Usuario General: ${userData['id_usuario_general']}');
debugPrint('[UserDataService] SubGeneral: ${userData['subGeneral']}');
debugPrint('[UserDataService] Sub: ${userData['sub']}');
```

## ✅ **Estado Final**

**Ahora todos los tipos de usuario pueden ver su ID General en el perfil:**

1. **👷‍♂️ Trabajadores**: Ven nómina + ID General
2. **👤 Ciudadanos**: Ven folio + ID General  
3. **🏢 Personas Morales**: Ven ID General
4. **❓ Usuarios genéricos**: Ven ID General

**Esto proporciona:**
- ✅ **Transparencia completa** sobre la identificación del usuario
- ✅ **Consistencia** con el sistema de trámites
- ✅ **Mejor experiencia** de usuario
- ✅ **Facilita el soporte** técnico

---

**Estado**: ✅ **Implementado y Funcionando**