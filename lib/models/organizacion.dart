// models/organizacion.dart

class RepresentanteOrganizacion {
  final String nombreCompleto;
  final String curp;
  final String telefono;
  final String correoElectronico;

  RepresentanteOrganizacion({
    required this.nombreCompleto,
    required this.curp,
    required this.telefono,
    required this.correoElectronico,
  });

  factory RepresentanteOrganizacion.fromJson(Map<String, dynamic> json) {
    return RepresentanteOrganizacion(
      nombreCompleto: json['nombreCompleto']?.toString() ?? 
                     json['nombre_completo']?.toString() ?? 
                     json['nombre']?.toString() ?? '',
      curp: json['curp']?.toString() ?? 
            json['CURP']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? 
                json['phone']?.toString() ?? 
                json['celular']?.toString() ?? '',
      correoElectronico: json['correoElectronico']?.toString() ?? 
                        json['correo_electronico']?.toString() ?? 
                        json['email']?.toString() ?? 
                        json['correo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreCompleto': nombreCompleto,
      'curp': curp,
      'telefono': telefono,
      'correoElectronico': correoElectronico,
    };
  }

  // Getters para display en UI
  String get nombreCompletoDisplay => nombreCompleto.isEmpty ? 'No especificado' : nombreCompleto;
  String get curpDisplay => curp.isEmpty ? 'No especificado' : curp;
  String get telefonoDisplay => telefono.isEmpty ? 'No especificado' : telefono;
  String get correoElectronicoDisplay => correoElectronico.isEmpty ? 'No especificado' : correoElectronico;
}

class DireccionOrganizacion {
  final String estado;
  final String asentamientoColonia;
  final String calle;

  DireccionOrganizacion({
    required this.estado,
    required this.asentamientoColonia,
    required this.calle,
  });

  factory DireccionOrganizacion.fromJson(Map<String, dynamic> json) {
    return DireccionOrganizacion(
      estado: json['estado']?.toString() ?? 
              json['state']?.toString() ?? '',
      asentamientoColonia: json['asentamientoColonia']?.toString() ?? 
                          json['asentamiento_colonia']?.toString() ?? 
                          json['asentamiento']?.toString() ?? 
                          json['colonia']?.toString() ?? '',
      calle: json['calle']?.toString() ?? 
             json['street']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estado': estado,
      'asentamientoColonia': asentamientoColonia,
      'calle': calle,
    };
  }

  // Getter para dirección completa
  String get direccionCompleta {
    final partes = [calle, asentamientoColonia, estado]
        .where((p) => p.isNotEmpty)
        .toList();
    return partes.isNotEmpty ? partes.join(', ') : 'Dirección no especificada';
  }

  // Getters para display en UI
  String get estadoDisplay => estado.isEmpty ? 'No especificado' : estado;
  String get asentamientoColoniaDisplay => asentamientoColonia.isEmpty ? 'No especificado' : asentamientoColonia;
  String get calleDisplay => calle.isEmpty ? 'No especificado' : calle;
}

class Organizacion {
  final String idOrganizacion;
  final String razonSocial;
  final String rfc;
  final RepresentanteOrganizacion representante;
  final DireccionOrganizacion direccion;

  Organizacion({
    required this.idOrganizacion,
    required this.razonSocial,
    required this.rfc,
    required this.representante,
    required this.direccion,
  });

  factory Organizacion.fromJson(Map<String, dynamic> json) {
    return Organizacion(
      idOrganizacion: json['idOrganizacion']?.toString() ?? 
                     json['id_organizacion']?.toString() ?? 
                     json['id']?.toString() ?? '',
      razonSocial: json['razonSocial']?.toString() ?? 
                  json['razon_social']?.toString() ?? 
                  json['empresa']?.toString() ?? '',
      rfc: json['rfc']?.toString() ?? 
           json['RFC']?.toString() ?? '',
      representante: RepresentanteOrganizacion.fromJson(
        json['representante'] ?? json['representative'] ?? {}
      ),
      direccion: DireccionOrganizacion.fromJson(
        json['direccion'] ?? json['address'] ?? {}
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idOrganizacion': idOrganizacion,
      'razonSocial': razonSocial,
      'rfc': rfc,
      'representante': representante.toJson(),
      'direccion': direccion.toJson(),
    };
  }

  // Getters para display en UI
  String get idOrganizacionDisplay => idOrganizacion.isEmpty ? 'No especificado' : idOrganizacion;
  String get razonSocialDisplay => razonSocial.isEmpty ? 'No especificado' : razonSocial;
  String get rfcDisplay => rfc.isEmpty ? 'No especificado' : rfc;

  // Validar si la organización tiene los campos requeridos
  bool get esOrganizacionValida {
    return idOrganizacion.isNotEmpty && 
           razonSocial.isNotEmpty && 
           rfc.isNotEmpty &&
           representante.nombreCompleto.isNotEmpty &&
           representante.curp.isNotEmpty;
  }

  // Genera la lista de campos para la sección "Datos Generales"
  List<Map<String, String>> get datosGenerales {
    return [
      {
        'etiqueta': 'ID Organización',
        'valor': idOrganizacionDisplay,
        'icono': 'business'
      },
      {
        'etiqueta': 'Razón Social',
        'valor': razonSocialDisplay,
        'icono': 'informacion laboral'
      },
      {
        'etiqueta': 'RFC',
        'valor': rfcDisplay,
        'icono': 'rfc'
      },
    ];
  }

  // Genera la lista de campos para la sección "Representante"
  List<Map<String, String>> get datosRepresentante {
    return [
      {
        'etiqueta': 'Nombre Completo',
        'valor': representante.nombreCompletoDisplay,
        'icono': 'person'
      },
      {
        'etiqueta': 'CURP',
        'valor': representante.curpDisplay,
        'icono': 'Curp'
      },
      {
        'etiqueta': 'Teléfono',
        'valor': representante.telefonoDisplay,
        'icono': 'telefono'
      },
      {
        'etiqueta': 'Correo Electrónico',
        'valor': representante.correoElectronicoDisplay,
        'icono': 'Correo Electronico'
      },
    ];
  }

  // Genera la lista de campos para la sección "Dirección"
  List<Map<String, String>> get datosDireccion {
    return [
      {
        'etiqueta': 'Estado',
        'valor': direccion.estadoDisplay,
        'icono': 'Direccion'
      },
      {
        'etiqueta': 'Asentamiento / Colonia',
        'valor': direccion.asentamientoColoniaDisplay,
        'icono': 'asentamiento'
      },
      {
        'etiqueta': 'Calle',
        'valor': direccion.calleDisplay,
        'icono': 'Direccion'
      },
    ];
  }
}