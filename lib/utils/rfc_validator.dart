// Utilidad para validar RFC con diferentes formatos

class RFCValidator {
  
  // Valida RFC con formato flexible
  static bool isValidRFC(String input) {
    final cleanInput = input.trim().toUpperCase();
    
    // RFC debe tener entre 10 y 13 caracteres
    if (cleanInput.length < 10 || cleanInput.length > 13) {
      return false;
    }
    
    // Patrón flexible para RFC
    // 3-4 letras iniciales + 6 dígitos + 0-3 caracteres adicionales
    final rfcPattern = RegExp(r'^[A-ZÑ&]{3,4}[0-9]{6}([A-Z0-9]{0,3})?$');
    return rfcPattern.hasMatch(cleanInput);
  }
  
  // Ejemplos de RFC válidos para testing
  static List<String> getValidRFCExamples() {
    return [
      // RFC Persona Física (13 caracteres)
      'ABCD123456EFG',
      'XAXX010101000',
      'VECJ880326XXX',
      
      // RFC Persona Moral (12 caracteres)
      'ABC123456789',
      'XYZ010101ABC',
      'EMP880326123',
      
      // RFC sin homoclave (10-11 caracteres)
      'ABCD123456',
      'ABC123456',
      'XAXX010101',
      'XYZ010101',
    ];
  }
  
  // Ejemplos de RFC inválidos para testing
  static List<String> getInvalidRFCExamples() {
    return [
      // Muy corto
      'ABC12345',
      'AB123456',
      
      // Muy largo
      'ABCD123456EFGH',
      'ABC123456789ABC',
      
      // Formato incorrecto
      '123456789ABC',
      'ABCD12345A',
      'ABC12345A',
      
      // Caracteres inválidos
      'ABC@123456',
      'ABC 123456',
      'ABC-123456',
    ];
  }
  
  // Función de prueba para verificar la validación
  static void testRFCValidation() {
    print('=== TESTING RFC VALIDATION ===');
    
    print('\n--- RFC VÁLIDOS ---');
    for (String rfc in getValidRFCExamples()) {
      bool isValid = isValidRFC(rfc);
      print('$rfc (${rfc.length} chars): ${isValid ? "✅ VÁLIDO" : "❌ INVÁLIDO"}');
    }
    
    print('\n--- RFC INVÁLIDOS ---');
    for (String rfc in getInvalidRFCExamples()) {
      bool isValid = isValidRFC(rfc);
      print('$rfc (${rfc.length} chars): ${isValid ? "❌ FALSO POSITIVO" : "✅ CORRECTAMENTE INVÁLIDO"}');
    }
  }
}