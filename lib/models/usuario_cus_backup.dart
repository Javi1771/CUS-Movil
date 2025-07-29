// models/usuario_cus.dart

// ignore_for_file: avoid_print

// Enum para definir los tipos de perfil
enum TipoPerfilCUS {
  ciudadano,
  trabajador,
  personaMoral,
  usuario,
  organizacion, // Alias para personaMoral
}

class DocumentoCUS {
  // ... (Tu clase DocumentoCUS está bien, no necesita cambios)
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
      nombreDocumento:
          json['nombreDocumento']?.toString() ?? 'Documento sin nombre',
      urlDocumento: json['urlDocumento']?.toString() ?? '',
      uploadDate: json['uploadDate']?.toString(),
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

  // Identificadores
  final String? usuarioId;
  final String? folio; // Para ciudadanos
  final String? nomina; // Para trabajadores
  final String? idCiudadano;
  final String? rfc; // CORRECIÓN: Campo RFC agregado

  // Información básica
  final String nombre;
  final String? nombreCompleto;
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
    }

    return UsuarioCUS(
      tipoPerfil: tipoPerfil,
      usuarioId: getStringValue(['usuarioId', 'usuario_id', 'userId', 'id']),
      folio: folio,
      nomina: nomina,
      idCiudadano: idCiudadano,
      nombre: nombre.isNotEmpty ? nombre : 'Usuario Sin Nombre',
      nombreCompleto: getStringValue(['nombreCompleto', 'fullName']),
      curp: curp ?? 'Sin CURP',
      fechaNacimiento: getStringValue(['fechaNacimiento', 'birthDate']),
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

  String get nombreDisplay {
    if (tipoPerfil == TipoPerfilCUS.personaMoral) {
      return razonSocial ?? nombre; // Prioriza razón social para organizaciones
    }
    return nombreCompleto ?? nombre;
  }

  String get nacionalidadDisplay {
    return nacionalidad ?? 'Mexicana';
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
      'nombreCompleto': nombreCompleto,
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