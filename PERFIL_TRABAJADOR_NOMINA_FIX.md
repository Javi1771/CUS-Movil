# 👷‍♂️ Corrección: Mostrar Nómina como ID General para Trabajadores

## 📋 **Problema Identificado**

### ❌ **Situación Anterior:**
- Para trabajadores se mostraban **DOS campos separados**:
  - "Nómina: 12345"
  - "ID General: 789012"
- Esto era **confuso** porque para trabajadores, **la nómina ES el ID General**
- No debían mostrarse como campos separados

### 🔍 **Análisis del Problema:**
```dart
// ANTES - Incorrecto para trabajadores:
case TipoPerfilCUS.trabajador:
  // Mostraba nómina
  identifiers.add(_buildInfoCard('Nómina', nomina, ...));
  
  // Y TAMBIÉN mostraba ID General por separado ❌
  identifiers.add(_buildInfoCard('ID General', idCiudadano, ...));
```

**Resultado visual incorrecto:**
```
👤 Información Personal
├─ 🏷️ Nómina: 12345          ← Campo 1
├─ 🆔 ID General: 789012     ← Campo 2 (DUPLICADO)
├─ 🆔 CURP: ABC123...
└─ ...
```

## ✅ **Solución Implementada**

### **Archivo corregido**: `lib/screens/perfil_usuario_screen.dart`

### **Lógica Corregida para Trabajadores:**

```dart
case TipoPerfilCUS.trabajador:
  // ✅ CORRECCIÓN: Para trabajadores, la nómina ES el ID General
  if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'ID General (Nómina)',  // ✅ Un solo campo que clarifica que es lo mismo
      _getDisplayValue(usuario!.nomina, 'Sin nómina'),
      imagenesIconos['badge']!,
      Icons.badge,
    ));
  } else if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
    // ✅ Solo si NO tiene nómina, usar idCiudadano como fallback
    identifiers.add(_buildInfoCard(
      'ID General',
      _getDisplayValue(usuario!.idCiudadano, 'Sin ID General'),
      imagenesIconos['badge']!,
      Icons.person_pin,
    ));
  }
  break;
```

## 🎯 **Resultado Visual Corregido**

### **Ahora para trabajadores:**
```
┌─────────────────────────────┐
│ 👤 Información Personal     │
├─────────────────────────────┤
│ 🏷️ ID General (Nómina):    │
│    12345                    │ ✅ UN SOLO CAMPO
├─────────────────────────────┤
│ 🆔 CURP: ABC123...         │
│ 🎂 Fecha de Nacimiento...  │
│ 🏳️ Nacionalidad: Mexicana  │
└─────────────────────────────┘
```

## 📊 **Casos Cubiertos**

### **1. Trabajador con Nómina (Caso Normal):**
```json
{
  "tipoPerfil": "trabajador",
  "nomina": "12345"
}
```
**Resultado**: ✅ Muestra "ID General (Nómina): 12345"

### **2. Trabajador sin Nómina (Caso Edge):**
```json
{
  "tipoPerfil": "trabajador",
  "idCiudadano": "789012"
}
```
**Resultado**: ✅ Muestra "ID General: 789012" (fallback)

### **3. Ciudadano (Sin Cambios):**
```json
{
  "tipoPerfil": "ciudadano",
  "folio": "CUS123",
  "idCiudadano": "456789"
}
```
**Resultado**: ✅ Muestra "Folio: CUS123" + "ID General: 456789"

### **4. Otros Tipos (Sin Cambios):**
```json
{
  "tipoPerfil": "personaMoral",
  "idCiudadano": "999888"
}
```
**Resultado**: ✅ Muestra "ID General: 999888"

## 🔧 **Lógica de Prioridad para Trabajadores**

### **Flujo de Decisión:**
```mermaid
graph TD
    A[Usuario es Trabajador] --> B{¿Tiene nómina?}
    B -->|Sí| C[Mostrar 'ID General (Nómina)': valor_nomina]
    B -->|No| D{¿Tiene idCiudadano?}
    D -->|Sí| E[Mostrar 'ID General': valor_idCiudadano]
    D -->|No| F[No mostrar identificador]
```

### **Código Implementado:**
```dart
if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty) {
  // PRIORIDAD 1: Usar nómina como ID General
  identifiers.add(_buildInfoCard('ID General (Nómina)', nomina, ...));
} else if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
  // PRIORIDAD 2: Fallback a idCiudadano
  identifiers.add(_buildInfoCard('ID General', idCiudadano, ...));
}
// Si no tiene ninguno, no muestra identificador
```

## ✅ **Beneficios de la Corrección**

### **1. Claridad Conceptual:**
- ✅ **Elimina confusión**: Ya no hay dos campos que parecen diferentes
- ✅ **Clarifica relación**: "ID General (Nómina)" explica que son lo mismo
- ✅ **Consistencia**: Alineado con el servicio de trámites

### **2. Experiencia de Usuario:**
- ✅ **Menos información redundante**: Un solo campo en lugar de dos
- ✅ **Más claro**: El usuario entiende que su nómina es su ID General
- ✅ **Consistente**: Mismo valor que se usa en trámites

### **3. Mantenimiento:**
- ✅ **Lógica simplificada**: Menos casos edge que manejar
- ✅ **Código más limpio**: Eliminación de duplicación
- ✅ **Fácil debugging**: Un solo punto de verdad para trabajadores

## 🔍 **Validación de Consistencia**

### **En el Servicio de Trámites:**
```dart
// TramitesService._extractIdGeneral()
if (esTrabajador && nomina != null && nomina.isNotEmpty) {
  return nomina; // ✅ Usa nómina como ID
}
```

### **En la Pantalla de Perfil:**
```dart
// PerfilUsuarioScreen._buildProfileIdentifier()
if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty) {
  // ✅ Muestra nómina como "ID General (Nómina)"
}
```

**✅ CONSISTENCIA TOTAL**: El mismo valor se usa en ambos lugares.

## 🎯 **Comparación Antes vs Después**

### **❌ ANTES (Confuso):**
```
Trabajador ve:
├─ Nómina: 12345
├─ ID General: 789012    ← ¿Cuál se usa para trámites?
```

### **✅ DESPUÉS (Claro):**
```
Trabajador ve:
├─ ID General (Nómina): 12345    ← Claro que es lo mismo
```

---

## ✅ **Estado Final**

**Ahora para trabajadores:**
- ✅ **Un solo campo**: "ID General (Nómina)"
- ✅ **Valor correcto**: Su número de nómina
- ✅ **Consistencia**: Mismo valor usado en trámites
- ✅ **Claridad**: Entienden que nómina = ID General

**Estado**: ✅ **Corregido y Funcionando**