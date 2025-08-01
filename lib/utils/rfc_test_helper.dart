import 'package:flutter/foundation.dart';

class RFCTestHelper {
  /// Valida un RFC usando el validador estándar
  static bool validateRFC(String rfc) {
    return RFCValidator.isValid(rfc);
  }

  /// Analiza un RFC y devuelve información detallada
  static Map<String, dynamic> analyzeRFC(String rfc) {
    return RFCValidator.analyze(rfc);
  }

  /// Ejecuta pruebas de validación de RFC
  static void testRFCValidation() {
    RFCValidator.runTests();
  }
}

class RFCValidator {
  // Expresiones regulares para cada tipo de RFC
  static final RegExp _personaFisicaConHomoclave =
      RegExp(r'^[A-ZÑ&]{4}\d{6}[A-Z0-9]{3}$');
  static final RegExp _personaFisicaSinHomoclave = RegExp(r'^[A-ZÑ&]{4}\d{6}$');
  static final RegExp _personaMoralConHomoclave =
      RegExp(r'^[A-ZÑ&]{3}\d{6}[A-Z0-9]{3}$');
  static final RegExp _personaMoralSinHomoclave = RegExp(r'^[A-ZÑ&]{3}\d{6}$');

  /// RFCs especiales que deben ser aceptados aunque no cumplan el formato estándar
  static final Set<String> _excepcionesRFC = {
    'ORG1213456789', // RFC específico qLKLKKue requiere excepción
    // Agregar más excepciones aquí si es necesario
  };

  /// Valida un RFC de forma simple y eficiente
  static bool isValid(String rfc) {
    if (rfc.isEmpty) {
      if (kDebugMode) debugPrint('RFC vacío');
      return false;
    }

    final cleanRFC = rfc.trim().toUpperCase();

    if (kDebugMode) {
      debugPrint('Validando RFC: $cleanRFC');
      debugPrint('Excepciones registradas: $_excepcionesRFC');
    }

    // Primero verificar si es una excepción
    if (_excepcionesRFC.contains(cleanRFC)) {
      if (kDebugMode) debugPrint('✅ RFC encontrado en excepciones: $cleanRFC');
      return true;
    }

    // Verificaciones básicas
    if (cleanRFC.contains('@') || cleanRFC.contains(' ')) {
      if (kDebugMode) debugPrint('❌ RFC contiene caracteres inválidos');
      return false;
    }

    if (cleanRFC.length < 9 || cleanRFC.length > 13) {
      if (kDebugMode) debugPrint('❌ Longitud incorrecta: ${cleanRFC.length}');
      return false;
    }

    if (cleanRFC.length == 11) {
      if (kDebugMode) debugPrint('❌ Longitud 11 nunca es válida');
      return false;
    }

    // Validar según la longitud
    bool isValid = false;
    switch (cleanRFC.length) {
      case 9:
        isValid = _personaMoralSinHomoclave.hasMatch(cleanRFC);
        if (kDebugMode) debugPrint('📏 Longitud 9: ${isValid ? '✅' : '❌'}');
        return isValid;
      case 10:
        isValid = _personaFisicaSinHomoclave.hasMatch(cleanRFC);
        if (kDebugMode) debugPrint('📏 Longitud 10: ${isValid ? '✅' : '❌'}');
        return isValid;
      case 12:
        isValid = _personaMoralConHomoclave.hasMatch(cleanRFC);
        if (kDebugMode) debugPrint('📏 Longitud 12: ${isValid ? '✅' : '❌'}');
        return isValid;
      case 13:
        isValid = _personaFisicaConHomoclave.hasMatch(cleanRFC);
        if (kDebugMode) debugPrint('📏 Longitud 13: ${isValid ? '✅' : '❌'}');
        return isValid;
      default:
        if (kDebugMode) {
          debugPrint('❌ Longitud no reconocida: ${cleanRFC.length}');
        }
        return false;
    }
  }

  /// Obtiene el tipo de RFC
  static String getType(String rfc) {
    final cleanRFC = rfc.trim().toUpperCase();

    // Manejar excepciones primero
    if (_excepcionesRFC.contains(cleanRFC)) {
      if (kDebugMode) debugPrint('🔍 Tipo: Persona Moral (formato especial)');
      return 'Persona Moral (formato especial)';
    }

    if (!isValid(cleanRFC)) {
      return 'Inválido';
    }

    String type;
    switch (cleanRFC.length) {
      case 9:
        type = 'Persona Moral (sin homoclave)';
        break;
      case 10:
        type = 'Persona Física (sin homoclave)';
        break;
      case 12:
        type = 'Persona Moral (con homoclave)';
        break;
      case 13:
        type = 'Persona Física (con homoclave)';
        break;
      default:
        type = 'Inválido';
    }

    if (kDebugMode) debugPrint('🔍 Tipo: $type');
    return type;
  }

  /// Información completa del RFC
  static Map<String, dynamic> analyze(String rfc) {
    if (kDebugMode) debugPrint('\n=== ANALIZANDO RFC: $rfc ===');

    final cleanRFC = rfc.trim().toUpperCase();
    final isExcepcion = _excepcionesRFC.contains(cleanRFC);
    final valid = isExcepcion || isValid(cleanRFC);
    final type = getType(cleanRFC);

    if (kDebugMode) {
      debugPrint('📊 Resultado del análisis:');
      debugPrint('  - RFC: $cleanRFC');
      debugPrint('  - Válido: $valid');
      debugPrint('  - Tipo: $type');
      debugPrint('  - Longitud: ${cleanRFC.length}');
      debugPrint('  - Es excepción: $isExcepcion');
    }

    return {
      'rfc': cleanRFC,
      'valid': valid,
      'type': type,
      'length': cleanRFC.length,
      'isPersonaFisica':
          valid && (cleanRFC.length == 10 || cleanRFC.length == 13),
      'hasHomoclave': valid && (cleanRFC.length == 12 || cleanRFC.length == 13),
      'isExcepcion': isExcepcion,
    };
  }

  /// Ejemplos para testing
  static void runTests() {
    if (!kDebugMode) return;

    debugPrint('\n=== INICIO DE PRUEBAS UNITARIAS ===\n');

    final validRFCs = [
      'ABCD123456EFG', // Persona física con homoclave
      'VECJ880326XXX', // Persona física con homoclave
      'ABCD123456', // Persona física sin homoclave
      'XAXX010101', // Persona física sin homoclave
      'ABC123456789', // Persona moral con homoclave
      'ORG123456789', // Persona moral con homoclave
      'ABC123456', // Persona moral sin homoclave
      'ORG123456', // Persona moral sin homoclave
      'ORG1213456789', // RFC específico con excepción
    ];

    final invalidRFCs = [
      'ABC12345', // Muy corto
      'ABCD123456EFGH', // Muy largo
      '123456789ABC', // Inicia con números
      'ABC@123456', // Caracteres inválidos
      'ABCD1234567', // 11 caracteres (inválido)
      'ABC 123456', // Contiene espacios
    ];

    debugPrint('--- RFCs VÁLIDOS ---');
    for (final rfc in validRFCs) {
      final result = analyze(rfc);
      debugPrint('$rfc: ${result['valid'] ? '✅' : '❌'} ${result['type']}'
          '${result['isExcepcion'] ? ' (EXCEPCIÓN)' : ''}');
    }

    debugPrint('\n--- RFCs INVÁLIDOS ---');
    for (final rfc in invalidRFCs) {
      final result = analyze(rfc);
      debugPrint(
          '$rfc: ${result['valid'] ? '❌ FALSO POSITIVO' : '✅ CORRECTAMENTE INVÁLIDO'}');
    }

    // Prueba explícita del RFC de excepción
    const excepcionRFC = 'ORG1213456789';
    final resultExcepcion = analyze(excepcionRFC);
    debugPrint('\n--- PRUEBA EXPLÍCITA DE EXCEPCIÓN ---');
    debugPrint('$excepcionRFC: '
        '${resultExcepcion['valid'] ? '✅' : '❌'} '
        'Tipo: ${resultExcepcion['type']} '
        'Excepción: ${resultExcepcion['isExcepcion']}');

    debugPrint('\n=== FIN DE PRUEBAS UNITARIAS ===\n');
  }

  /// Valida y formatea un RFC
  static String? format(String rfc) {
    if (kDebugMode) debugPrint('Formateando RFC: $rfc');
    final cleanRFC = rfc.trim().toUpperCase();
    final isValidRFC = isValid(cleanRFC);
    if (kDebugMode) debugPrint('RFC ${isValidRFC ? 'válido' : 'inválido'}');
    return isValidRFC ? cleanRFC : null;
  }

  /// Verifica si es persona física
  static bool isPersonaFisica(String rfc) {
    final cleanRFC = rfc.trim().toUpperCase();
    if (!isValid(cleanRFC)) return false;
    final length = cleanRFC.length;
    final result = length == 10 || length == 13;
    if (kDebugMode) debugPrint('Es persona física: $result');
    return result;
  }

  /// Verifica si es persona moral
  static bool isPersonaMoral(String rfc) {
    final cleanRFC = rfc.trim().toUpperCase();
    if (!isValid(cleanRFC)) return false;
    final length = cleanRFC.length;
    final result = length == 9 || length == 12;
    if (kDebugMode) debugPrint('Es persona moral: $result');
    return result;
  }

  /// Agrega un RFC a la lista de excepciones
  static void agregarExcepcion(String rfc) {
    final cleanRFC = rfc.trim().toUpperCase();
    if (kDebugMode) debugPrint('Agregando excepción: $cleanRFC');
    _excepcionesRFC.add(cleanRFC);
  }

  /// Elimina un RFC de la lista de excepciones
  static void eliminarExcepcion(String rfc) {
    final cleanRFC = rfc.trim().toUpperCase();
    if (kDebugMode) debugPrint('Eliminando excepción: $cleanRFC');
    _excepcionesRFC.remove(cleanRFC);
  }

  /// Obtiene la lista de RFCs con excepción
  static Set<String> get excepciones {
    if (kDebugMode) debugPrint('Excepciones actuales: $_excepcionesRFC');
    return _excepcionesRFC;
  }
}
