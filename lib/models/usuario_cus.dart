// models/usuario_cus.dart

// Enum para definir los tipos de perfil
enum TipoPerfilCUS {
  ciudadano,
  trabajador,
  personaMoral,
  usuario, // Tipo genérico o de fallback
}

class DocumentoCUS {
  final String nombreDocumento;
  final String urlDocumento;
  final String? uploadDate;

  DocumentoCUS({
    required this.nombreDocumento,
    required this.urlDocumento,
    this.uploadDate,
  });

  factory DocumentoCUS.fromJson(Map<String, dynamic> json) {
    return DocumentoCUS(
      nombreDocumento: json['nombreDocumento']?.toString() ??
          json['nombre_documento']?.toString() ??
          json['name']?.toString() ??
          json['documento']?.toString() ??
          'Documento sin nombre',
      urlDocumento: json['urlDocumento']?.toString() ??
          json['url_documento']?.toString() ??
          json['url']?.toString() ??
          json['link']?.toString() ??
          '',
      uploadDate: json['uploadDate']?.toString() ??
          json['upload_date']?.toString() ??
          json['fecha_subida']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreDocumento': nombreDocumento,
      'urlDocumento': urlDocumento,
      'uploadDate': uploadDate,
    };
  }
}

class UsuarioCUS {
  // Tipo de perfil
  final TipoPerfilCUS tipoPerfil;

  // Identificadores específicos por tipo
  final String? folio; // Solo para ciudadanos
  final String? nomina; // Solo para trabajadores
  final String? idCiudadano; // ID del ciudadano

  // Información básica común
  final String? usuarioId;
  final String nombre;
  final String? nombreCompleto;

  // Información Personal común
  final String curp;
  final String? fechaNacimiento;
  final String? nacionalidad;

  // Información de Contacto común
  final String email;
  final String? telefono;
  final String? calle;
  final String? asentamiento;
  final String? codigoPostal;
  final String? direccion;

  // Información Laboral
  final String? ocupacion;
  final String? razonSocial;
  final String? estado;
  final String? estadoCivil;

  // Documentos y foto
  final List<DocumentoCUS>? documentos;
  final String? foto;

  UsuarioCUS({
    required this.tipoPerfil,
    this.usuarioId,
    this.folio,
    this.nomina,
    this.idCiudadano,
    required this.nombre,
    this.nombreCompleto,
    required this.curp,
    this.fechaNacimiento,
    this.nacionalidad,
    required this.email,
    this.telefono,
    this.calle,
    this.asentamiento,
    this.codigoPostal,
    this.direccion,
    this.ocupacion,
    this.razonSocial,
    this.estado,
    this.estadoCivil,
    this.documentos,
    this.foto,
  });

  factory UsuarioCUS.fromJson(Map<String, dynamic> json) {
    // Función helper para obtener valores de múltiples claves posibles
    String? getStringValue(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          return value.toString().trim();
        }
      }
      return null;
    }

    // Obtener identificadores para determinar el tipo de perfil
    final folio = getStringValue(['folio', 'folioCUS', 'folio_cus']);
    final nomina = getStringValue(['nomina', 'nómina', 'numeroNomina']);
    final idCiudadano = getStringValue([
      'id_ciudadano', 
      'idCiudadano', 
      'ciudadano_id',
      'id_usuario_general',
      'idUsuarioGeneral',
      'usuario_general_id',
      'subGeneral',
      'sub'
    ]);

    // Obtener el tipo de perfil explícito si viene en los datos
    final tipoPerfilExplicito = getStringValue([
      'tipoPerfil', 
      'tipo_perfil', 
      'tipoUsuario', 
      'tipo_usuario',
      'userType',
      'user_type'
    ]);

    // Debug logging
    print('[UsuarioCUS] Determinando tipo de perfil...');
    print('[UsuarioCUS] Folio: $folio');
    print('[UsuarioCUS] Nómina: $nomina');
    print('[UsuarioCUS] ID Ciudadano: $idCiudadano');
    print('[UsuarioCUS] Tipo perfil explícito: $tipoPerfilExplicito');

    // Determinar tipo de perfil basado en identificadores y datos disponibles
    TipoPerfilCUS tipoPerfil;
    
    // Primero verificar si viene explícitamente en los datos
    if (tipoPerfilExplicito != null) {
      print('[UsuarioCUS] Usando tipo de perfil explícito: $tipoPerfilExplicito');
      switch (tipoPerfilExplicito.toLowerCase()) {
        case 'ciudadano':
        case 'persona_fisica':
        case 'fisica':
        case 'citizen':
          tipoPerfil = TipoPerfilCUS.ciudadano;
          break;
        case 'trabajador':
        case 'employee':
        case 'worker':
          tipoPerfil = TipoPerfilCUS.trabajador;
          break;
        case 'persona_moral':
        case 'moral':
        case 'empresa':
        case 'company':
          tipoPerfil = TipoPerfilCUS.personaMoral;
          break;
        default:
          tipoPerfil = TipoPerfilCUS.usuario;
      }
    }
    // Si no viene explícito, determinar por identificadores
    else if (folio != null && folio.isNotEmpty) {
      print('[UsuarioCUS] Tipo determinado por folio: ciudadano');
      tipoPerfil = TipoPerfilCUS.ciudadano;
    } else if (nomina != null && nomina.isNotEmpty) {
      print('[UsuarioCUS] Tipo determinado por nómina: trabajador');
      tipoPerfil = TipoPerfilCUS.trabajador;
    } else if (idCiudadano != null && idCiudadano.isNotEmpty) {
      // Si tiene ID ciudadano, es una persona física (ciudadano)
      print('[UsuarioCUS] Tipo determinado por ID ciudadano: ciudadano');
      tipoPerfil = TipoPerfilCUS.ciudadano;
    } else {
      // Verificar otros indicadores de persona física vs moral
      final razonSocial = getStringValue(['razonSocial', 'razon_social', 'empresa']);
      final curp = getStringValue(['curp', 'CURP']);
      final rfc = getStringValue(['rfc', 'RFC']);
      
      print('[UsuarioCUS] Verificando otros indicadores...');
      print('[UsuarioCUS] Razón social: $razonSocial');
      print('[UsuarioCUS] CURP: $curp');
      
      if (razonSocial != null && razonSocial.isNotEmpty) {
        print('[UsuarioCUS] Tipo determinado por razón social: persona moral');
        tipoPerfil = TipoPerfilCUS.personaMoral;
      } else if (curp != null && curp.isNotEmpty && curp != 'Sin CURP') {
        // Si tiene CURP, es persona física
        print('[UsuarioCUS] Tipo determinado por CURP: ciudadano');
        tipoPerfil = TipoPerfilCUS.ciudadano;
      } else {
        // Por defecto, asumir ciudadano si no hay indicadores claros de persona moral
        print('[UsuarioCUS] Tipo determinado por defecto: ciudadano');
        tipoPerfil = TipoPerfilCUS.ciudadano;
      }
    }

    print('[UsuarioCUS] Tipo de perfil final: $tipoPerfil');

    // Extraer documentos si existen
    List<DocumentoCUS>? documentosList;
    final documentosData = json['documentos'] ?? json['documents'];
    if (documentosData != null && documentosData is List) {
      documentosList = documentosData
          .map((doc) =>
              DocumentoCUS.fromJson(doc is Map<String, dynamic> ? doc : {}))
          .toList();
    }

    return UsuarioCUS(
      tipoPerfil: tipoPerfil,
      usuarioId: getStringValue(
          ['usuarioId', 'usuario_id', 'userId', 'id', 'user_id']),
      folio: folio,
      nomina: nomina,
      idCiudadano: idCiudadano,
      nombre: getStringValue(['nombre', 'name', 'firstName', 'first_name']) ??
          'Usuario Sin Nombre',
      nombreCompleto: getStringValue(
          ['nombreCompleto', 'nombre_completo', 'fullName', 'full_name']),
      curp: getStringValue(['curp', 'CURP', 'rfc', 'RFC']) ?? 'Sin CURP',
      fechaNacimiento: getStringValue(
          ['fechaNacimiento', 'fecha_nacimiento', 'birthDate', 'birth_date']),
      nacionalidad:
          getStringValue(['nacionalidad', 'nationality']) ?? 'Mexicana',
      email: getStringValue(['email', 'correo', 'mail']) ??
          'sin-email@ejemplo.com',
      telefono: getStringValue(['telefono', 'phone', 'celular']),
      calle: getStringValue(['calle', 'street']),
      asentamiento: getStringValue(['asentamiento', 'colonia']),
      codigoPostal: getStringValue(['codigoPostal', 'codigo_postal', 'cp']),
      direccion: getStringValue(['direccion', 'address']),
      ocupacion: getStringValue(['ocupacion', 'job', 'position']),
      razonSocial: getStringValue(['razonSocial', 'razon_social', 'empresa']),
      estado: getStringValue(['estado', 'status', 'state']),
      estadoCivil: getStringValue(['estadoCivil', 'estado_civil']),
      documentos: documentosList,
      foto: getStringValue(['foto', 'photo', 'avatar', 'profilePicture']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipoPerfil': tipoPerfil.toString().split('.').last,
      'usuarioId': usuarioId,
      'folio': folio,
      'nomina': nomina,
      'idCiudadano': idCiudadano,
      'nombre': nombre,
      'nombreCompleto': nombreCompleto,
      'curp': curp,
      'fechaNacimiento': fechaNacimiento,
      'nacionalidad': nacionalidad,
      'email': email,
      'telefono': telefono,
      'calle': calle,
      'asentamiento': asentamiento,
      'codigoPostal': codigoPostal,
      'direccion': direccion,
      'ocupacion': ocupacion,
      'razonSocial': razonSocial,
      'estado': estado,
      'estadoCivil': estadoCivil,
      'foto': foto,
      'documentos': documentos?.map((doc) => doc.toJson()).toList(),
    };
  }

  // --- GETTERS PARA LA UI ---

  // Obtener el identificador principal según el tipo de perfil
  String? get identificadorPrincipal {
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return folio;
      case TipoPerfilCUS.trabajador:
        return nomina;
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.usuario:
        return null;
    }
  }

  // Obtener la etiqueta del identificador
  String get etiquetaIdentificador {
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return 'Folio';
      case TipoPerfilCUS.trabajador:
        return 'Nómina';
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.usuario:
        return 'Sin identificador';
    }
  }

  // Validar si el perfil tiene los campos requeridos
  bool get esPerfilValido {
    if (nombre.isEmpty || curp.isEmpty || email.isEmpty) return false;

    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return folio != null && folio!.isNotEmpty;
      case TipoPerfilCUS.trabajador:
        return nomina != null && nomina!.isNotEmpty;
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.usuario:
        return true; // No requieren identificador específico
    }
  }

  // Getters de display para usar en la UI y evitar lógica en la vista
  String get nombreDisplay => nombreCompleto ?? nombre;

  String get curpDisplay =>
      (curp.isEmpty || curp == 'Sin CURP') ? 'No especificado' : curp;

  String get fechaNacimientoDisplay => fechaNacimiento ?? 'No especificada';

  String get nacionalidadDisplay => nacionalidad ?? 'Mexicana';

  String get emailDisplay => (email.isEmpty || email == 'sin-email@ejemplo.com')
      ? 'No especificado'
      : email;

  String get telefonoDisplay => telefono ?? 'No especificado';

  String get direccionCompleta {
    final partes = [calle, asentamiento, codigoPostal]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    if (partes.isNotEmpty) return partes.join(', ');
    return direccion ?? 'No especificada';
  }

  // Genera la lista de campos para la sección "Información Personal"
  List<Map<String, String>> get camposEspecificos {
    final campos = <Map<String, String>>[];

    // Agrega el identificador principal (Folio o Nómina) solo si existe
    if (identificadorPrincipal != null) {
      campos.add({
        'etiqueta': etiquetaIdentificador,
        'valor': identificadorPrincipal!,
        'icono': 'badge', // Ícono genérico para identificadores
      });
    }

    campos.addAll([
      {'etiqueta': 'CURP', 'valor': curpDisplay, 'icono': 'badge'},
      {
        'etiqueta': 'Fecha de Nacimiento',
        'valor': fechaNacimientoDisplay,
        'icono': 'cake'
      },
      {
        'etiqueta': 'Nacionalidad',
        'valor': nacionalidadDisplay,
        'icono': 'flag'
      },
    ]);

    return campos;
  }

  // Genera la lista de campos para la sección "Información de Contacto"
  List<Map<String, String>> get camposContacto {
    return [
      {
        'etiqueta': 'Correo Electrónico',
        'valor': emailDisplay,
        'icono': 'email'
      },
      {'etiqueta': 'Teléfono', 'valor': telefonoDisplay, 'icono': 'phone'},
      {'etiqueta': 'Dirección', 'valor': direccionCompleta, 'icono': 'home'},
    ];
  }

  // Getter para mostrar el tipo de perfil como String legible
  String get tipoPerfilDisplay {
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return 'Ciudadano';
      case TipoPerfilCUS.trabajador:
        return 'Trabajador';
      case TipoPerfilCUS.personaMoral:
        return 'Persona Moral';
      case TipoPerfilCUS.usuario:
        return 'Usuario';
    }
  }

  get rfc => null;

  get apellidoPaterno => null;

  get primerApellido => null;

  get segundoApellido => null;
}
