import 'package:intl/intl.dart';

Map<String, String> estadosCurp = {
  'AS': 'Aguascalientes',
  'BC': 'Baja California',
  'BS': 'Baja California Sur',
  'CC': 'Campeche',
  'CL': 'Coahuila',
  'CM': 'Colima',
  'CS': 'Chiapas',
  'CH': 'Chihuahua',
  'DF': 'CDMX',
  'DG': 'Durango',
  'GT': 'Guanajuato',
  'GR': 'Guerrero',
  'HG': 'Hidalgo',
  'JC': 'Jalisco',
  'MC': 'México',
  'MN': 'Michoacán',
  'MS': 'Morelos',
  'NT': 'Nayarit',
  'NL': 'Nuevo León',
  'OC': 'Oaxaca',
  'PL': 'Puebla',
  'QT': 'Querétaro',
  'QR': 'Quintana Roo',
  'SP': 'San Luis Potosí',
  'SL': 'Sinaloa',
  'SR': 'Sonora',
  'TC': 'Tabasco',
  'TS': 'Tamaulipas',
  'TL': 'Tlaxcala',
  'VZ': 'Veracruz',
  'YN': 'Yucatán',
  'ZS': 'Zacatecas',
  'NE': 'Extranjero',
};

String? obtenerEstadoDeCurp(String curp) {
  if (curp.length < 13) return null;
  String codigoEstado = curp.substring(11, 13).toUpperCase();
  return estadosCurp[codigoEstado];
}

String? obtenerGeneroDeCurp(String curp) {
  if (curp.length < 11) return null;
  final genero = curp[10].toUpperCase();
  if (genero == 'H') return 'H';
  if (genero == 'M') return 'M';
  return null;
}

String? obtenerFechaNacimientoDeCurp(String curp) {
  if (curp.length < 10) return null;

  final year = int.parse(curp.substring(4, 6));
  final month = int.parse(curp.substring(6, 8));
  final day = int.parse(curp.substring(8, 10));
  final currentYear = DateTime.now().year % 100;
  final century = year > currentYear ? 1900 : 2000;

  try {
    final date = DateTime(century + year, month, day);
    return DateFormat('yyyy-MM-dd').format(date);
  } catch (_) {
    return null;
  }
}
