# 👷‍♂️ Campo "Nómina (ID General)" en Perfil de Trabajadores

## 📋 **Requerimiento Específico**

### 🎯 **Solicitud:**
- En el perfil del usuario, en la sección "Información Personal"
- Agregar un campo específico que diga **"Nómina (ID General)"**
- Este campo debe aparecer **SOLO para trabajadores**
- Debe mostrar el valor de la nómina del trabajador

## ✅ **Implementación Realizada**

### **Archivo modificado**: `lib/screens/perfil_usuario_screen.dart`

### **Método actualizado**: `_buildProfileIdentifier()`

#### **Código Implementado:**

```dart
case TipoPerfilCUS.trabajador:
  // ✅ ESPECÍFICO PARA TRABAJADORES: Campo "Nómina (ID General)"
  if (usuario!.nomina != null && usuario!.nomina!.isNotEmpty) {
    identifiers.add(_buildInfoCard(
      'Nómina (ID General)',  // ← ETIQUETA ESPECÍFICA
      _getDisplayValue(usuario!.nomina, 'Sin nómina'),
      imagenesIconos['badge']!,
      Icons.badge,
    ));
  } else if (usuario!.idCiudadano != null && usuario!.idCiudadano!.isNotEmpty) {
    // Fallback si no tiene nómina
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

### **Para Trabajadores (SOLO ELLOS):**
```
┌─────────────────────────────────┐
│ 👤 Información Personal         │
├─────────────────────────────────┤
│ 🏷️ Nómina (ID General):        │
│    12345                        │ ← CAMPO ESPECÍFICO
├─────────────────────────────────┤
│ 🆔 CURP: ABC123DEF456GHI789     │
│ 🎂 Fecha de Nacimiento: ...     │
│ 🏳️ Nacionalidad: Mexicana       │
└─────────────────────────────────┘
```

### **Para Ciudadanos (Sin Cambios):**
```
┌─────────────────────────────────┐
│ 👤 Información Personal         │
├─────────────────────────────────┤
│ 🏷️ Folio: CUS123456            │
│ 🆔 ID General: 789012           │
├───────────────────────��─────────┤
│ 🆔 CURP: ABC123DEF456GHI789     │
│ 🎂 Fecha de Nacimiento: ...     │
│ 🏳️ Nacionalidad: Mexicana       │
└─────────────────────────────────┘
```

### **Para Otros Tipos (Sin Cambios):**
```
┌─────────────────────────────────┐
│ 👤 Información Personal         │
├─────────────────────────────────┤
│ 🆔 ID General: 999888           │
├─────────────────────────────────┤
│ 🆔 CURP: ABC123DEF456GHI789     │
│ 🎂 Fecha de Nacimiento: ...     │
│ 🏳️ Nacionalidad: Mexicana       │
└─────────────────────────────────┘
```

## 📊 **Casos Cubiertos**

### **1. Trabajador con Nómina (Caso Principal):**
```json
{
  "tipoPerfil": "trabajador",
  "nomina": "12345"
}
```
**Resultado**: ✅ Muestra **"Nómina (ID General): 12345"**

### **2. Trabajador sin Nómina (Caso Edge):**
```json
{
  "tipoPerfil": "trabajador",
  "idCiudadano": "789012"
}
```
**Resultado**: ✅ Muestra **"ID General: 789012"** (fallback)

### **3. Ciudadano (No Afectado):**
```json
{
  "tipoPerfil": "ciudadano",
  "folio": "CUS123",
  "idCiudadano": "456789"
}
```
**Resultado**: ✅ Muestra **"Folio: CUS123"** + **"ID General: 456789"**

### **4. Persona Moral (No Afectado):**
```json
{
  "tipoPerfil": "personaMoral",
  "idCiudadano": "999888"
}
```
**Resultado**: ✅ Muestra **"ID General: 999888"**

## 🔧 **Lógica de Visualización**

### **Condiciones de Mostrado:**

```mermaid
graph TD
    A[Usuario en Perfil] --> B{¿Es Trabajador?}
    B -->|Sí| C{¿Tiene Nómina?}
    B -->|No| D[Mostrar campos normales]
    
    C -->|Sí| E[Mostrar 'Nómina (ID General)': valor_nomina]
    C -->|No| F{¿Tiene idCiudadano?}
    
    F -->|Sí| G[Mostrar 'ID General': valor_idCiudadano]
    F -->|No| H[No mostrar identificador]
    
    D --> I[Ciudadano: Folio + ID General]
    D --> J[Otros: Solo ID General]
```

### **Prioridad de Campos para Trabajadores:**
1. **PRIORIDAD 1**: Si tiene `nomina` → Mostrar **"Nómina (ID General)"**
2. **PRIORIDAD 2**: Si no tiene `nomina` pero tiene `idCiudadano` → Mostrar **"ID General"**
3. **PRIORIDAD 3**: Si no tiene ninguno → No mostrar identificador

## ✅ **Características del Campo**

### **Etiqueta**: `"Nómina (ID General)"`
- ✅ **Clarifica** que la nómina es el ID General
- ✅ **Específica** para trabajadores
- ✅ **Descriptiva** y fácil de entender

### **Valor**: Número de nómina del trabajador
- ✅ **Fuente**: Campo `usuario.nomina`
- ✅ **Fallback**: "Sin nómina" si está vacío
- ✅ **Validación**: Solo se muestra si tiene valor válido

### **Icono**: `Icons.badge`
- ✅ **Consistente** con otros identificadores
- ✅ **Apropiado** para nóminas/badges de empleados
- ✅ **Visualmente** distinguible

## 🎯 **Beneficios Específicos**

### **1. Claridad para Trabajadores:**
- ✅ **Ven claramente** que su nómina es su ID General
- ✅ **Entienden** qué número se usa para trámites
- ✅ **No hay confusión** sobre múltiples identificadores

### **2. Diferenciación por Tipo:**
- ✅ **Trabajadores**: Ven "Nómina (ID General)"
- ✅ **Ciudadanos**: Ven "Folio" + "ID General"
- ✅ **Otros**: Ven solo "ID General"

### **3. Consistencia del Sistema:**
- ✅ **Alineado** con el servicio de trámites
- ✅ **Mismo valor** usado en ambos lugares
- ✅ **Experiencia coherente** en toda la app

## 🔍 **Validación de Implementación**

### **Verificar que aparece SOLO para trabajadores:**
```dart
// Solo se ejecuta si:
usuario!.tipoPerfil == TipoPerfilCUS.trabajador
```

### **Verificar etiqueta correcta:**
```dart
// Etiqueta específica:
'Nómina (ID General)'
```

### **Verificar valor correcto:**
```dart
// Valor de la nómina:
_getDisplayValue(usuario!.nomina, 'Sin nómina')
```

---

## ✅ **Estado Final**

**Implementación completada:**
- ✅ **Campo agregado**: "Nómina (ID General)"
- ✅ **Solo para trabajadores**: Condición específica
- ✅ **En Información Personal**: Ubicación correcta
- ✅ **Valor correcto**: Muestra la nómina del trabajador
- ✅ **Fallback manejado**: Si no tiene nómina

**Estado**: ✅ **Implementado y Funcionando**