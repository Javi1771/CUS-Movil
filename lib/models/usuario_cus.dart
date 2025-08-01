// models/usuario_cus.dart

// ignore_for_file: avoid_print

/// Enum para definir los tipos de perfil en el sistema CUS
enum TipoPerfilCUS {
  /// Perfil para ciudadanos con folio CUS
  ciudadano,
  
  /// Perfil para trabajadores del gobierno con nómina
  trabajador,
  
  /// Perfil para personas morales/organizaciones con RFC de 12 dígitos
  personaMoral,
  
  /// Perfil genérico para usuarios sin clasificación específica
  usuario,
  
  /// Alias para personaMoral (mantener compatibilidad)
  organizacion,
}

/// Extensión para obtener descripciones legibles de los tipos de perfil
extension TipoPerfilCUSExtension on TipoPerfilCUS {
  /// Obtiene la descripción en español del tipo de perfil
  String get descripcion {
    switch (this) {
      case TipoPerfilCUS.ciudadano:
        return 'Ciudadano';
      case TipoPerfilCUS.trabajador:
        return 'Trabajador del Gobierno';
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        return 'Organización/Empresa';
      case TipoPerfilCUS.usuario:
        return 'Usuario General';
    }
  }

  /// Indica si el perfil requiere folio CUS
  bool get requiereFolio {
    return this == TipoPerfilCUS.ciudadano;
  }

  /// Indica si el perfil requiere número de nómina
  bool get requiereNomina {
    return this == TipoPerfilCUS.trabajador;
  }

  /// Indica si el perfil requiere RFC
  bool get requiereRFC {
    return this == TipoPerfilCUS.personaMoral || this == TipoPerfilCUS.organizacion;
  }
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
    print('[DocumentoCUS] 🔍 PROCESANDO DOCUMENTO: $json');
    
    // Buscar el nombre del documento en múltiples campos posibles
    String nombreDoc = json['nombre_documento']?.toString() ?? 
                      json['nombreDocumento']?.toString() ?? 
                      json['nombre']?.toString() ?? 
                      json['name']?.toString() ?? 
                      json['title']?.toString() ?? 
                      json['filename']?.toString() ?? 
                      json['original_filename']?.toString() ?? 
                      json['display_name']?.toString() ?? 
                      'Documento sin nombre';

    // Buscar la URL del documento en múltiples campos posibles
    String urlDoc = json['url_documento']?.toString() ?? 
                   json['urlDocumento']?.toString() ?? 
                   json['url']?.toString() ?? 
                   json['secure_url']?.toString() ?? 
                   json['public_url']?.toString() ?? 
                   json['link']?.toString() ?? 
                   json['file_url']?.toString() ?? 
                   json['cloudinary_url']?.toString() ?? 
                   json['path']?.toString() ?? 
                   '';

    // Buscar la fecha en múltiples campos posibles
    String? fechaDoc = json['upload_date']?.toString() ?? 
                      json['uploadDate']?.toString() ?? 
                      json['fecha']?.toString() ?? 
                      json['created_at']?.toString() ?? 
                      json['fechaSubida']?.toString() ?? 
                      json['timestamp']?.toString() ?? 
                      json['date']?.toString();

    print('[DocumentoCUS] 📄 Nombre extraído: $nombreDoc');
    print('[DocumentoCUS] 🔗 URL extraída: $urlDoc');
    print('[DocumentoCUS] 📅 Fecha extraída: $fechaDoc');

    // Validar y procesar la URL de Cloudinary
    if (urlDoc.isNotEmpty) {
      // Si la URL ya es completa y válida, usarla tal como está
      if (urlDoc.startsWith('https://res.cloudinary.com/')) {
        print('[DocumentoCUS] ✅ URL de Cloudinary válida detectada');
      } 
      // Si no es completa pero contiene elementos de Cloudinary, intentar construirla
      else if (!urlDoc.startsWith('http') && (urlDoc.contains('/') || urlDoc.length > 10)) {
        print('[DocumentoCUS] 🔧 Intentando construir URL de Cloudinary...');
        // Formato típico de Cloudinary: https://res.cloudinary.com/cloud-name/image/upload/v1234567890/path/file.pdf
        urlDoc = 'https://res.cloudinary.com/dsngx5ckc/raw/upload/$urlDoc';
        print('[DocumentoCUS] 🔧 URL construida: $urlDoc');
      }
      
      // Validación final de URL
      if (urlDoc.startsWith('http')) {
        print('[DocumentoCUS] ✅ URL final válida: $urlDoc');
      } else {
        print('[DocumentoCUS] ⚠️ URL no válida después del procesamiento: $urlDoc');
      }
    } else {
      print('[DocumentoCUS] ❌ URL de documento vacía para $nombreDoc');
    }

    final documento = DocumentoCUS(
      nombreDocumento: nombreDoc,
      urlDocumento: urlDoc,
      uploadDate: fechaDoc,
    );
    
    print('[DocumentoCUS] 🎯 Documento creado: ${documento.nombreDocumento} -> ${documento.urlDocumento}');
    return documento;
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

  // Identificadores
  final String? usuarioId;
  final String? folio; // Para ciudadanos
  final String? nomina; // Para trabajadores
  final String? idCiudadano;
  final String? rfc; // CORRECIÓN: Campo RFC agregado

  // Información básica
  final String nombre;
  final String? nombre_completo;
  final String? razonSocial; // Para organizaciones

  // Información Personal (puede ser del representante legal)
  final String curp;
  final String? fechaNacimiento;
  final String? nacionalidad;
  final String? estadoCivil;

  // Información de Contacto
  final String email;
  final String? telefono;
  final String? calle;
  final String? asentamiento;
  final String? estado;
  final String? codigoPostal;
  final String? direccion;

  // Información Laboral (para trabajadores o info de la empresa)
  final String? ocupacion;
  final String? departamento;
  final String? puesto;

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
    this.nombre_completo,
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
    this.departamento,
    this.puesto,
    this.documentos,
    this.foto,
    this.rfc, // CORRECIÓN: Agregado al constructor
  });

  factory UsuarioCUS.fromJson(Map<String, dynamic> json) {
    print('[UsuarioCUS] ========== INICIANDO PARSEO DE DATOS ==========');

    String? getStringValue(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null &&
            value.toString().trim().isNotEmpty &&
            value.toString() != 'null') {
          print('[UsuarioCUS] ✅ Encontrado $key: $value');
          return value.toString().trim();
        }
      }
      return null;
    }

    // --- Extracción de Datos ---
    final folio = getStringValue(['folio', 'folioCUS']);
    final nomina = getStringValue(['no_nomina', 'nomina']);
    final idCiudadano = getStringValue(['id_ciudadano', 'idCiudadano', 'sub']);
    final razonSocial = getStringValue(
        ['razonSocial', 'razon_social', 'nombreEmpresa', 'businessName']);

    // CORRECIÓN: Se usa una variable dedicada para el RFC y se busca en múltiples claves
    final rfcValue = getStringValue(
        ['rfc', 'RFC', 'rfcOrganizacion', 'rfc_organizacion', 'rfcEmpresa']);

    final tipoPerfilExplicito =
        getStringValue(['tipoPerfil', 'tipo_perfil', 'userType']);
    final curp = getStringValue(['curp', 'CURP']);
    final nombre = getStringValue(['nombre', 'name', 'firstName']) ?? '';
    final email = getStringValue(['email', 'correo', 'mail']) ?? '';
    
    // DIAGNÓSTICO: Buscar fecha de nacimiento en múltiples campos
    final fechaNacimiento = getStringValue([
      'fechaNacimiento', 
      'fecha_nacimiento', 
      'birthDate', 
      'birth_date', 
      'dateOfBirth', 
      'date_of_birth',
      'nacimiento',
      'birthday',
      'fecha'
    ]);
    print('[UsuarioCUS] 🎂 Fecha de nacimiento encontrada: $fechaNacimiento');

    // --- Lógica de Detección de Perfil ---
    TipoPerfilCUS tipoPerfil;

    if (tipoPerfilExplicito != null) {
      print('[UsuarioCUS] ✅ Usando tipo explícito: $tipoPerfilExplicito');
      switch (tipoPerfilExplicito.toLowerCase()) {
        case 'ciudadano':
        case 'persona_fisica':
          tipoPerfil = TipoPerfilCUS.ciudadano;
          break;
        case 'trabajador':
          tipoPerfil = TipoPerfilCUS.trabajador;
          break;
        case 'persona_moral':
        case 'organizacion':
        case 'empresa':
          tipoPerfil = TipoPerfilCUS.personaMoral;
          break;
        default:
          tipoPerfil = TipoPerfilCUS.usuario;
      }
    } else if (razonSocial != null && razonSocial.isNotEmpty) {
      print(
          '[UsuarioCUS] ✅ ORGANIZACIÓN detectada por Razón Social: $razonSocial');
      tipoPerfil = TipoPerfilCUS.personaMoral;
    } else if (rfcValue != null && rfcValue.length == 12) {
      print(
          '[UsuarioCUS] ✅ ORGANIZACIÓN detectada por RFC de 12 caracteres: $rfcValue');
      tipoPerfil = TipoPerfilCUS.personaMoral;
    } else if (nomina != null && nomina.isNotEmpty) {
      print('[UsuarioCUS] ✅ TRABAJADOR detectado por nómina: $nomina');
      tipoPerfil = TipoPerfilCUS.trabajador;
    } else if (folio != null && folio.isNotEmpty) {
      print('[UsuarioCUS] ✅ CIUDADANO detectado por folio: $folio');
      tipoPerfil = TipoPerfilCUS.ciudadano;
    } else {
      print('[UsuarioCUS] ⚠️ Tipo determinado por defecto: USUARIO (Fallback)');
      tipoPerfil = (curp != null && curp.length == 18)
          ? TipoPerfilCUS.ciudadano
          : TipoPerfilCUS.usuario;
    }

    print('[UsuarioCUS] 🎯 TIPO DE PERFIL FINAL: $tipoPerfil');
    print('[UsuarioCUS] ==================================================');

    List<DocumentoCUS>? documentosList;
    final documentosData = json['documentos'] ?? json['documents'];
    if (documentosData != null && documentosData is List) {
      documentosList = documentosData
          .map((doc) => DocumentoCUS.fromJson(doc as Map<String, dynamic>))
          .toList();
      print('[UsuarioCUS] ✅ Documentos parseados: ${documentosList.length}');
      for (final doc in documentosList) {
        print('[UsuarioCUS] 📄 Documento: ${doc.nombreDocumento} -> ${doc.urlDocumento}');
      }
    }

    return UsuarioCUS(
      tipoPerfil: tipoPerfil,
      usuarioId: getStringValue(['usuarioId', 'usuario_id', 'userId', 'id']),
      folio: folio,
      nomina: nomina,
      idCiudadano: idCiudadano,
      nombre: nombre.isNotEmpty ? nombre : 'Usuario Sin Nombre',
      nombre_completo: getStringValue(['nombre_completo', 'fullName']),
      curp: curp ?? 'Sin CURP',
      fechaNacimiento: fechaNacimiento,
      nacionalidad:
          getStringValue(['nacionalidad', 'nationality']) ?? 'Mexicana',
      email: email.isNotEmpty ? email : 'sin-email@ejemplo.com',
      telefono: getStringValue(['telefono', 'phone']),
      calle: getStringValue(['calle', 'street']),
      asentamiento: getStringValue(['asentamiento', 'colonia']),
      codigoPostal: getStringValue(['codigoPostal', 'cp']),
      direccion: getStringValue(['direccion', 'address']),
      ocupacion: getStringValue(['ocupacion', 'job']),
      razonSocial: razonSocial,
      estado: getStringValue(['estado', 'state']),
      estadoCivil: getStringValue(['estadoCivil']),
      departamento: getStringValue(['departamento', 'area']),
      puesto: getStringValue(['puesto', 'position']),
      documentos: documentosList,
      foto: getStringValue(['foto', 'photo', 'avatar']),
      rfc: rfcValue, // CORRECIÓN: Asignando el valor de RFC parseado
    );
  }

  // --- GETTERS PARA LA UI (Mejorados) ---

  /// Obtiene el nombre a mostrar según el tipo de perfil
  String get nombreDisplay {
    if (tipoPerfil == TipoPerfilCUS.personaMoral || tipoPerfil == TipoPerfilCUS.organizacion) {
      return razonSocial ?? nombre; // Prioriza razón social para organizaciones
    }
    return nombre_completo ?? nombre;
  }

  /// Obtiene la nacionalidad con valor por defecto
  String get nacionalidadDisplay {
    return nacionalidad ?? 'Mexicana';
  }

  /// Obtiene la descripción del tipo de perfil
  String get tipoPerfilDescripcion {
    return tipoPerfil.descripcion;
  }

  /// Obtiene el identificador principal según el tipo de perfil
  String? get identificadorPrincipal {
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return folio ?? idCiudadano;
      case TipoPerfilCUS.trabajador:
        return nomina;
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        return rfc;
      case TipoPerfilCUS.usuario:
        return usuarioId ?? idCiudadano;
    }
  }

  /// Obtiene la etiqueta del identificador principal
  String get etiquetaIdentificador {
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return folio != null ? 'Folio CUS' : 'ID Ciudadano';
      case TipoPerfilCUS.trabajador:
        return 'Número de Nómina';
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        return 'RFC';
      case TipoPerfilCUS.usuario:
        return 'ID Usuario';
    }
  }

  /// Construye la dirección completa
  String get direccionCompleta {
    final partes = <String>[];
    
    if (calle?.isNotEmpty == true) partes.add(calle!);
    if (asentamiento?.isNotEmpty == true) partes.add(asentamiento!);
    if (estado?.isNotEmpty == true) partes.add(estado!);
    if (codigoPostal?.isNotEmpty == true) partes.add('CP $codigoPostal');
    
    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección registrada';
  }

  /// Verifica si el perfil está completo según su tipo
  bool get perfilCompleto {
    // Validaciones básicas para todos los perfiles
    if (nombre.isEmpty || email.isEmpty || curp.isEmpty) {
      return false;
    }

    // Validaciones específicas por tipo de perfil
    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        return folio?.isNotEmpty == true || idCiudadano?.isNotEmpty == true;
      case TipoPerfilCUS.trabajador:
        return nomina?.isNotEmpty == true;
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        return rfc?.isNotEmpty == true && razonSocial?.isNotEmpty == true;
      case TipoPerfilCUS.usuario:
        return true; // Usuario genérico no requiere campos específicos
    }
  }

  /// Obtiene una lista de campos faltantes para completar el perfil
  List<String> get camposFaltantes {
    final faltantes = <String>[];

    if (nombre.isEmpty) faltantes.add('Nombre');
    if (email.isEmpty) faltantes.add('Correo electrónico');
    if (curp.isEmpty) faltantes.add('CURP');

    switch (tipoPerfil) {
      case TipoPerfilCUS.ciudadano:
        if (folio?.isEmpty != false && idCiudadano?.isEmpty != false) {
          faltantes.add('Folio CUS o ID Ciudadano');
        }
        break;
      case TipoPerfilCUS.trabajador:
        if (nomina?.isEmpty != false) faltantes.add('Número de Nómina');
        break;
      case TipoPerfilCUS.personaMoral:
      case TipoPerfilCUS.organizacion:
        if (rfc?.isEmpty != false) faltantes.add('RFC');
        if (razonSocial?.isEmpty != false) faltantes.add('Razón Social');
        break;
      case TipoPerfilCUS.usuario:
        break; // No requiere campos adicionales
    }

    return faltantes;
  }

  /// Verifica si tiene documentos cargados
  bool get tieneDocumentos {
    return documentos?.isNotEmpty == true;
  }

  /// Obtiene el número de documentos cargados
  int get numeroDocumentos {
    return documentos?.length ?? 0;
  }

  // Método toJson para serializar el objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'tipoPerfil': tipoPerfil.toString().split('.').last,
      'usuarioId': usuarioId,
      'folio': folio,
      'nomina': nomina,
      'idCiudadano': idCiudadano,
      'rfc': rfc,
      'nombre': nombre,
      'nombre_completo': nombre_completo,
      'razonSocial': razonSocial,
      'curp': curp,
      'fechaNacimiento': fechaNacimiento,
      'nacionalidad': nacionalidad,
      'estadoCivil': estadoCivil,
      'email': email,
      'telefono': telefono,
      'calle': calle,
      'asentamiento': asentamiento,
      'estado': estado,
      'codigoPostal': codigoPostal,
      'direccion': direccion,
      'ocupacion': ocupacion,
      'departamento': departamento,
      'puesto': puesto,
      'documentos': documentos?.map((doc) => doc.toJson()).toList(),
      'foto': foto,
    };
  }

  // CORRECIÓN: Eliminado el getter `rfc` que devolvía null. Ahora es un campo de la clase.
}