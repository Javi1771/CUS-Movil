// models/secretaria.dart

class Secretaria {
  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final double latitud;
  final double longitud;
  final String telefono;
  final String email;
  final String horarioAtencion;
  final String responsable;
  final String imagen;
  final List<String> servicios;
  final String color; // Color representativo de la secretaría

  Secretaria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    required this.telefono,
    required this.email,
    required this.horarioAtencion,
    required this.responsable,
    required this.imagen,
    required this.servicios,
    required this.color,
  });

  factory Secretaria.fromJson(Map<String, dynamic> json) {
    return Secretaria(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      direccion: json['direccion'] ?? '',
      latitud: (json['latitud'] ?? 0.0).toDouble(),
      longitud: (json['longitud'] ?? 0.0).toDouble(),
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      horarioAtencion: json['horarioAtencion'] ?? '',
      responsable: json['responsable'] ?? '',
      imagen: json['imagen'] ?? '',
      servicios: List<String>.from(json['servicios'] ?? []),
      color: json['color'] ?? '#0B3B60',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'telefono': telefono,
      'email': email,
      'horarioAtencion': horarioAtencion,
      'responsable': responsable,
      'imagen': imagen,
      'servicios': servicios,
      'color': color,
    };
  }
}

// Datos de ejemplo
class SecretariasData {
  static List<Secretaria> getSecretariasEjemplo() {
    return [
      Secretaria(
        id: '1',
        nombre: 'Secretaría de Salud',
        descripcion: 'Encargada de la administración y coordinación de los servicios de salud pública en el estado.',
        direccion: 'Av. Constitución 1234, Centro, Guadalajara, Jalisco',
        latitud: 20.6597,
        longitud: -103.3496,
        telefono: '33-1234-5678',
        email: 'contacto@salud.jalisco.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        responsable: 'Dr. Fernando Petersen Aranguren',
        imagen: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Salud',
        servicios: ['Atención Médica', 'Vacunación', 'Programas de Prevención', 'Emergencias Sanitarias'],
        color: '#4CAF50',
      ),
      Secretaria(
        id: '2',
        nombre: 'Secretaría de Educación',
        descripcion: 'Responsable de la política educativa y la administración del sistema educativo estatal.',
        direccion: 'Av. Alcalde 1351, Guadalajara Centro, Guadalajara, Jalisco',
        latitud: 20.6736,
        longitud: -103.3370,
        telefono: '33-2345-6789',
        email: 'contacto@educacion.jalisco.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 9:00 AM - 5:00 PM',
        responsable: 'Mtro. Juan Carlos Flores Miramontes',
        imagen: 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Educacion',
        servicios: ['Becas Estudiantiles', 'Certificaciones', 'Programas Educativos', 'Infraestructura Escolar'],
        color: '#2196F3',
      ),
      Secretaria(
        id: '3',
        nombre: 'Secretaría de Desarrollo Social',
        descripcion: 'Promueve el desarrollo social y combate la pobreza mediante programas sociales.',
        direccion: 'Av. López Mateos Norte 755, Guadalajara, Jalisco',
        latitud: 20.6843,
        longitud: -103.3918,
        telefono: '33-3456-7890',
        email: 'contacto@desarrollo.jalisco.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:30 AM - 3:30 PM',
        responsable: 'Lic. Alberto Esquer Gutiérrez',
        imagen: 'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Desarrollo',
        servicios: ['Programas Sociales', 'Apoyo a Familias', 'Desarrollo Comunitario', 'Asistencia Social'],
        color: '#FF9800',
      ),
      Secretaria(
        id: '4',
        nombre: 'Secretaría de Seguridad',
        descripcion: 'Garantiza la seguridad pública y el orden en el territorio estatal.',
        direccion: 'Av. Federalismo Norte 700, Guadalajara, Jalisco',
        latitud: 20.6920,
        longitud: -103.3467,
        telefono: '33-4567-8901',
        email: 'contacto@seguridad.jalisco.gob.mx',
        horarioAtencion: '24 horas, 7 días a la semana',
        responsable: 'Gral. Luis Méndez Ruiz',
        imagen: 'https://via.placeholder.com/300x200/F44336/FFFFFF?text=Seguridad',
        servicios: ['Emergencias 911', 'Prevención del Delito', 'Protección Civil', 'Investigación Criminal'],
        color: '#F44336',
      ),
      Secretaria(
        id: '5',
        nombre: 'Secretaría de Turismo',
        descripcion: 'Fomenta el desarrollo turístico y promociona los destinos del estado.',
        direccion: 'Av. Vallarta 6503, Guadalajara, Jalisco',
        latitud: 20.6668,
        longitud: -103.3918,
        telefono: '33-5678-9012',
        email: 'contacto@turismo.jalisco.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 9:00 AM - 6:00 PM',
        responsable: 'Lic. Germán Ralis Cumplido',
        imagen: 'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Turismo',
        servicios: ['Promoción Turística', 'Certificación Hotelera', 'Eventos Culturales', 'Rutas Turísticas'],
        color: '#9C27B0',
      ),
      Secretaria(
        id: '6',
        nombre: 'Secretaría de Medio Ambiente',
        descripcion: 'Protege y conserva el medio ambiente y los recursos naturales del estado.',
        direccion: 'Av. Circunvalación Agustín Yáñez 2343, Guadalajara, Jalisco',
        latitud: 20.6580,
        longitud: -103.3890,
        telefono: '33-6789-0123',
        email: 'contacto@medioambiente.jalisco.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        responsable: 'Ing. Sergio Graf Montero',
        imagen: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Ambiente',
        servicios: ['Gestión Ambiental', 'Áreas Protegidas', 'Cambio Climático', 'Educación Ambiental'],
        color: '#4CAF50',
      ),
    ];
  }
}