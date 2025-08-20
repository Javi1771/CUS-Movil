// models/secretaria.dart

class DireccionDepartamento {
  final String nombre;
  final String objetivo;
  final String? ubicacion;
  final List<String> servicios;

  DireccionDepartamento({
    required this.nombre,
    required this.objetivo,
    this.ubicacion,
    this.servicios = const [],
  });

  factory DireccionDepartamento.fromJson(Map<String, dynamic> json) {
    return DireccionDepartamento(
      nombre: json['nombre'] ?? '',
      objetivo: json['objetivo'] ?? '',
      ubicacion: json['ubicacion'],
      servicios: List<String>.from(json['servicios'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'objetivo': objetivo,
      'ubicacion': ubicacion,
      'servicios': servicios,
    };
  }
}

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
  final String secretario;
  final List<DireccionDepartamento> direcciones;
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
    required this.secretario,
    required this.direcciones,
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
      secretario: json['secretario'] ?? '',
      direcciones: (json['direcciones'] as List<dynamic>?)
              ?.map((e) => DireccionDepartamento.fromJson(e))
              .toList() ??
          [],
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
      'secretario': secretario,
      'direcciones': direcciones.map((e) => e.toJson()).toList(),
      'imagen': imagen,
      'servicios': servicios,
      'color': color,
    };
  }
}

// Datos reales de las Secretarías de San Juan del Río, Querétaro
class SecretariasData {
  static List<Secretaria> getSecretariasEjemplo() {
    return [
      Secretaria(
        id: '1',
        nombre: 'Secretaría Particular',
        descripcion:
            'Organizar las actividades particulares de la persona titular de la Presidencia Municipal y sus relaciones particulares, coordinando la agenda particular con las actividades de la Administración Pública.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'contacto@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Miguel Ángel Subias Constandce',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Atención Ciudadana',
            objetivo:
                'Ser el contacto directo con los ciudadanos para brindar atención, seguimiento y desahogo a todas las solicitudes, en todos los trámites y servicios que presta esta administración a la ciudadanía.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Relaciones Públicas',
            objetivo:
                'Vincular con los sectores educativo, empresarial y turístico con las autoridades de distintos niveles y ciudadanía en general.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/0B3B60/FFFFFF?text=Particular',
        servicios: [
          'Atención Ciudadana',
          'Relaciones Públicas',
          'Desarrollo Político',
          'Comunicación Social'
        ],
        color: '#0B3B60',
      ),
      Secretaria(
        id: '2',
        nombre: 'Secretaría de Gobierno',
        descripcion:
            'Promover e instrumentar los mecanismos institucionales que garanticen la gobernabilidad, el estado de derecho y la paz social en el municipio.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'gobierno@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Abel Espinoza Suárez',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Juzgados Cívicos',
            objetivo:
                'Planear, dirigir y coordinar las políticas y acciones del Juzgado, así como representar a la persona titular de la Presidencia Municipal en actos de cualquier autoridad administrativa y de la ciudadanía cuando lo soliciten.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Registro Civil',
            objetivo:
                'Organizar y controlar la inscripción de todos los actos referentes al estado civil de las personas que habitan en el municipio, así como la compilación y emisión de actas a su cargo.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Protección Civil',
            objetivo:
                'Es un órgano dentro del Sistema Municipal de Protección Civil y le compete ejecutar las acciones de prevención, auxilio y recuperación o restablecimiento conforme a este Reglamento, y a los programas y acuerdos que autorice el Consejo de Protección Civil Municipal.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Capacitación Civil y Enlace Bomberos',
            objetivo:
                'Fomentar la cultura de protección civil y de la autoprotección a la población del municipio a través de la promoción, coordinación e impartición de cursos básicos, así como la programación de capacitación y eventos que promuevan en la población trabajar en las acciones preventivas.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Gobierno',
        servicios: [
          'Registro Civil',
          'Protección Civil',
          'Juzgados Cívicos',
          'Capacitación Civil',
          'Enlace Bomberos'
        ],
        color: '#2196F3',
      ),
      Secretaria(
        id: '3',
        nombre: 'Secretaría de Administración',
        descripcion:
            'Administrar los recursos humanos, materiales y técnicos, así como los servicios internos de la Administración Pública Municipal.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'administracion@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'José Miguel Valencia Molina',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Informática',
            objetivo:
                'Administrar el Sistema Automatizado de Información Municipal, aplicando y desarrollando tecnologías informáticas; que redunde en el fortalecimiento de las tareas de planeación, programación, control y evaluación de la gestión municipal.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Adquisiciones',
            objetivo:
                'Programar, controlar y supervisar, con base en las disposiciones legales, reglamentarias y administrativas, el Sistema de Adquisiciones, Enajenaciones y Arrendamiento de bienes y servicios del Municipio y establecer los mecanismos que permitan el control de los bienes muebles, inmuebles y derechos patrimoniales.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Recursos Humanos',
            objetivo:
                'Administrar los recursos humanos de la Administración Pública Municipal, a través de programas de modernización administrativa y la profesionalización de los servidores públicos municipales.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Infraestructura y Mantenimiento Interno',
            objetivo:
                'Planear, coordinar, analizar, evaluar y realizar las acciones necesarias para mantener la funcionalidad de las instalaciones eléctricas, evitar fallas y contribuir a la protección de sistemas, así como de los propios trabajadores.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Administracion',
        servicios: [
          'Recursos Humanos',
          'Adquisiciones',
          'Informática',
          'Infraestructura y Mantenimiento'
        ],
        color: '#FF9800',
      ),
      Secretaria(
        id: '4',
        nombre: 'Secretaría de Seguridad Pública Municipal',
        descripcion:
            'Preservar y garantizar el orden y la seguridad pública en el territorio municipal, con base en las leyes, reglamentos, planes y programas establecidos.',
        direccion:
            'Calle Río Moctezuma No. 199, Col. Nuevo San Juan, San Juan del Río, Qro.',
        latitud: 20.3850,
        longitud: -99.9900,
        telefono: '(427) 274 7964',
        email: 'seguridad@sanjuandelrio.gob.mx',
        horarioAtencion: '24 horas, 7 días a la semana',
        secretario: 'Orlando Chávez Landaverde',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Seguridad Pública',
            objetivo:
                'Planificar, dirigir y coordinar la operación del personal, para prevención de conductas antisociales y protección de las personas en sus bienes y derechos; bajo la conducción de la Persona Titular de la Secretaria de Seguridad Pública.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Prevención del Delito',
            objetivo:
                'Diseñar, implementar y evaluar los programas para la prevención del delito en el Municipio de San Juan del Río, fomentando la participación ciudadana y la atención a víctimas del delito.',
          ),
          DireccionDepartamento(
            nombre: 'Coordinación de Seguridad Pública',
            objetivo:
                'Disminuir la incidencia delictiva, así como las zonas de riesgo en favor de los habitantes del municipio, mediante la atención oportuna a reportes hechos por la ciudadanía y acciones de prevención del delito.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección Administrativa',
            objetivo:
                'Garantizar el cumplimiento en la Secretaría de Seguridad Pública Municipal de las políticas y procedimientos establecidos en materia de administración interna. Además de la correcta gestión, uso, destino y comprobación de recursos y servicios en la misma.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/F44336/FFFFFF?text=Seguridad',
        servicios: [
          'Seguridad Pública',
          'Prevención del Delito',
          'Coordinación de Seguridad',
          'Administración'
        ],
        color: '#F44336',
      ),
      Secretaria(
        id: '5',
        nombre: 'Secretaría de Obras Públicas y Desarrollo Urbano',
        descripcion:
            'Formular, dirigir, ejecutar y evaluar los planes, programas, proyectos y obras públicas municipales, bajo principios de legalidad, eficiencia, transparencia y congruencia social.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'obras@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Edith Álvarez Flores',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Estudios y Proyectos',
            objetivo:
                'Participar en los procesos de planeación del desarrollo municipal y en la integración de los programas de obra anual, de infraestructura y de las diferentes dependencias municipales, así como realizar los procesos que conllevan la integración del expediente técnico inicial de las obras autorizadas en el programa de obra anual.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Administración',
            objetivo:
                'Realizar los procesos de presupuestación, adjudicación y contratación de la obra pública a ejecutar en estricto apego a lo establecido en las leyes y reglamentos aplicables.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Supervisión',
            objetivo:
                'Dirigir y controlar la ejecución de las obras públicas municipales de acuerdo a lo ordenado por las leyes y reglamentos aplicables y con base en los requerimientos establecidos en los contratos correspondientes.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Obra Institucional',
            objetivo:
                'Atender en forma directa las necesidades de obras menores y servicios en las comunidades y colonias.',
          ),
          DireccionDepartamento(
            nombre: 'Regulación de Asentamientos Humanos',
            objetivo:
                'Regula los Asentamientos Humanos Irregulares en el municipio de San Juan del Río, así como revisar que se realice diligentemente las funciones del Jefe de Regularización de Asentamientos Humanos, del Auxiliar técnico-jurídico-administrativo y Auxiliar Administrativo.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Planeación y Desarrollo Urbano',
            objetivo:
                'Dirigir los procesos técnicos relativos a la ejecución, control y supervisión de los planes y programas para la planeación y el desarrollo municipal.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Medio Ambiente y Ecología',
            objetivo:
                'Establecer los principios, normas y acciones para contribuir a la preservación, protección, mejoramiento, restauración o rehabilitación del ambiente; así como las que sean necesarias para controlar, corregir, prevenir y restringir las causas y procesos que originan el deterioro o afecten al equilibrio ecológico del ambiente.',
          ),
        ],
        imagen: 'https://via.placeholder.com/300x200/795548/FFFFFF?text=Obras',
        servicios: [
          'Estudios y Proyectos',
          'Supervisión',
          'Desarrollo Urbano',
          'Medio Ambiente y Ecología'
        ],
        color: '#795548',
      ),
      Secretaria(
        id: '6',
        nombre: 'Secretaría de Desarrollo Social',
        descripcion:
            'Reducir la desigualdad social a través del combate a la pobreza, facilitar el acceso a bienes, servicios y oportunidades básicas para el mejoramiento de la calidad de vida.',
        direccion:
            'Av. Benito Juárez Ote. 36, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3888,
        longitud: -99.9956,
        telefono: '(427) 689 0012',
        email: 'desarrollo@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Bibiana Rodríguez Montes',
        direcciones: [
          DireccionDepartamento(
            nombre:
                'Dirección de Programas, Proyectos, Evaluación y Conclusión',
            objetivo:
                'Promover la participación social democrática en la administración de programas y proyectos que coadyuven a elevar el nivel de vida de los sectores sociales más vulnerables del Municipio.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Participación Ciudadana',
            objetivo:
                'Impulsar y facilitar la Participación Ciudadana corresponsable e incluyente en el quehacer público del municipio, contribuyendo al fortalecimiento del tejido social en San Juan del Río.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Desarrollo',
        servicios: [
          'Programas Sociales',
          'Participación Ciudadana',
          'Proyectos de Evaluación',
          'Combate a la Pobreza'
        ],
        color: '#4CAF50',
      ),
      Secretaria(
        id: '7',
        nombre: 'Secretaría de la Mujer',
        descripcion:
            'Dirigir, coordinar, gestionar y ejecutar políticas públicas, programas y acciones que garanticen los derechos humanos de las mujeres.',
        direccion: 'C. Corregidora 162, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3890,
        longitud: -99.9950,
        telefono: '427 264 0190',
        email: 'mujer@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Judith Ortíz Monroy',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Programación, Calidad y Transversalidad',
            objetivo:
                'Desarrollar y coordinar de manera eficaz y eficiente los procesos generales de programación y transversalización que permitan el logro de la Institucionalidad de la Perspectiva de Género, la igualdad sustantiva, la no discriminación y la violencia de género, de igual manera generar un eficiente sistema que genere información estadística e indicadores.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección Especializada a la Mujer',
            objetivo:
                'Dirigir, coordinar, gestionar y ejecutar políticas públicas, programas y acciones que garanticen los derechos humanos de las mujeres, así como promover y fomentar la igualdad sustantiva, la transversalización de la perspectiva de género en la administración pública, la erradicación de la discriminación y todo tipo de violencia contra las mujeres.',
          ),
        ],
        imagen: 'https://via.placeholder.com/300x200/E91E63/FFFFFF?text=Mujer',
        servicios: [
          'Igualdad de Género',
          'Prevención de Violencia',
          'Programación y Calidad',
          'Atención Especializada'
        ],
        color: '#E91E63',
      ),
      Secretaria(
        id: '8',
        nombre: 'Secretaría del Ayuntamiento',
        descripcion:
            'Contribuir a la eficaz organización y desarrollo de las Sesiones de Cabildo, así como de las Comisiones Permanentes de Dictamen.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'ayuntamiento@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Óscar Alcántara Peña',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Asuntos de Cabildo',
            objetivo:
                'Contribuir a la eficaz organización y desarrollo de las Sesiones de Cabildo, así como de las Comisiones Permanentes de Dictamen.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Proyectos',
            objetivo:
                'Administrar y planificar todos aquellos proyectos que contribuyan jurídicamente a la mejora de la Administración Pública Municipal.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección Jurídica',
            objetivo:
                'Atender y dar seguimiento a los asuntos de carácter litigioso que involucren al Gobierno Municipal, para la eficaz y legítima defensa de sus intereses.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/607D8B/FFFFFF?text=Ayuntamiento',
        servicios: [
          'Asuntos de Cabildo',
          'Proyectos',
          'Dirección Jurídica',
          'Sesiones de Cabildo'
        ],
        color: '#607D8B',
      ),
      Secretaria(
        id: '9',
        nombre: 'Secretaría de Finanzas',
        descripcion:
            'Recaudar los ingresos y administrar los egresos municipales, con base en las disposiciones y normas jurídicas, reglamentarias y administrativas aplicables.',
        direccion: 'Av. Paso de los Guzmán, No. 24, Barrio de la Concepción',
        latitud: 20.3895,
        longitud: -99.9967,
        telefono: '(427) 689 0012',
        email: 'finanzas@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Fernando Damián Oceguera',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Ingresos',
            objetivo:
                'Aplicar las normas y procedimientos recaudatorios de ingresos fiscales municipales.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Egresos',
            objetivo:
                'Administrar y controlar, con base en el presupuesto autorizado, así como en las políticas.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/009688/FFFFFF?text=Finanzas',
        servicios: [
          'Ingresos',
          'Egresos',
          'Administración Financiera',
          'Recaudación'
        ],
        color: '#009688',
      ),
      Secretaria(
        id: '10',
        nombre: 'Secretaría de Desarrollo Integral y Económico',
        descripcion:
            'Programar, gestionar, coordinar y ejecutar los programas institucionales para el desarrollo sustentable, económico, empresarial y de fomento integral.',
        direccion:
            'Av. Benito Juárez Ote. 36, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3888,
        longitud: -99.9956,
        telefono: '(427) 186 2882',
        email: 'desarrollo.economico@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'María Guadalupe Gómez Rodríguez',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección del Deporte',
            objetivo:
                'Fomentar la cultura física y el deporte en el municipio.',
            ubicacion:
                'Acuática Gómez Morin, Alfonso Pasiño s/n, Centro, 76807 San Juan del Río, Qro.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de la Juventud',
            objetivo:
                'Procurar el desarrollo integral de la juventud con equidad de oportunidades.',
            ubicacion:
                'Ciudad Vive Oriente, Av. de las Garzas 57, Indeco, San Juan del Río, Qro.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Bellas Artes',
            objetivo:
                'Promover y dar seguimiento a las actividades artísticas y culturales del municipio.',
            ubicacion:
                'Portal de Diezmo, Av. Benito Juárez No.15 Ote., San Juan del Río, Qro.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Desarrollo Empresarial',
            objetivo: 'Apoyar el crecimiento empresarial del municipio.',
            ubicacion:
                'Carretera Panamericana a Querétaro No.232, La Venta, Plaza Punta Victoria, San Juan del Río, Qro.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Desarrollo Mipymes y Regional',
            objetivo:
                'Beneficiar mediante la gestión, asesoría y ejecución de programas a las micro, pequeñas y medianas empresas del municipio para su operación, capacitación y regulación.',
            ubicacion:
                'Carretera Panamericana a Querétaro No.232, La Venta, Plaza Punta Victoria, San Juan del Río, Qro.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Desarrollo Turismo',
            objetivo:
                'Favorecer el desarrollo y cultura turística mediante el impulso de mecanismos e instrumentos de política pública que contribuyan al crecimiento del sector turístico; así como la capacitación, promoción de eventos, congresos y convenciones para difundir la riqueza histórica, cultural, natural y turística del municipio.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Economico',
        servicios: [
          'Deporte',
          'Juventud',
          'Bellas Artes',
          'Desarrollo Empresarial',
          'Turismo',
          'MIPYMES'
        ],
        color: '#9C27B0',
      ),
      Secretaria(
        id: '11',
        nombre: 'Secretaría de Desarrollo Agropecuario',
        descripcion:
            'Organizar, promover, coordinar, gestionar programas, proyectos y actividades tendientes a un mejor aprovechamiento de los recursos naturales del Municipio.',
        direccion: 'C. Miguel Hidalgo 99, Centro, 76807 San Juan del Río, Qro.',
        latitud: 20.3892,
        longitud: -99.9960,
        telefono: '(427) 186 2882',
        email: 'agropecuario@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Adrián Miranda Bárcenas',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Desarrollo Agropecuario',
            objetivo:
                'Promover, formular, gestionar, dirigir y ejecutar proyectos y programas que favorezcan el bienestar social y económico de los productores agropecuarios del municipio mediante el manejo sostenible y regenerativo de recursos naturales.',
            servicios: [
              'Proyecto de trazabilidad para aretado SINIIGA en ganado bovino, ovino y caprino',
              'Apoyo en manejo zoosanitario y medicina preventiva en ganado bovino, ovino y caprino',
              'Asesoría y capacitación en ganado bovino, ovino y caprino',
              'Rehabilitación y desazolve de bordos',
              'Registro de patente ganadera en bovinos carne',
              'Asesoría en sanidad vegetal y jurídica en asuntos agrarios',
            ],
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Agronegocios',
            objetivo:
                'Desarrollar, generar, contribuir a la inserción de los productos agropecuarios municipales en los mercados formales, así como el acceso a los mercados locales, regionales e internacionales a través de modelos de negocio, valor agregado, esquemas de financiamiento y política pública.',
            servicios: [
              'Registro y desarrollo de marcas',
              'Programa municipalizado',
              'Asesoría y capacitación en desarrollo de MIPYMES',
              'Apoyo para la comercialización de productos agropecuarios y agroindustriales',
              'Asesoría y capacitación en agricultura sustentable y cultivos alternativos',
            ],
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Infraestructura',
            objetivo:
                'Regular a las instalaciones que permitan el desarrollo de la actividad agropecuaria para la crianza de animales, almacenamiento de productos, siembra de cultivos y las demás de su competencia en términos de la norma jurídica aplicable. Así como recibir solicitudes para realización y mantenimiento de bordos y caminos de saca.',
            servicios: [
              'Asesoría y capacitación en huertos biointensivos',
              'Proyecto piloto para la producción de huertos biointensivos en escuelas',
              'Asesoría y capacitación en ganado menor',
            ],
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Integración Regenerativa',
            objetivo:
                'Promover, formular, gestionar, dirigir, coordinar, diseñar y ejecutar proyectos, programas, políticas, planes de desarrollo rural, agro emprendimiento, y desarrollo integral de micro cuencas con enfoque municipal y, encaminado a la provisión bienes públicos rurales, que inciden en el bienestar social y económico.',
            servicios: [
              'Rehabilitación de caminos de saca',
            ],
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/8BC34A/FFFFFF?text=Agropecuario',
        servicios: [
          'Desarrollo Agropecuario',
          'Agronegocios',
          'Infraestructura Rural',
          'Integración Regenerativa'
        ],
        color: '#8BC34A',
      ),
      Secretaria(
        id: '12',
        nombre: 'Secretaría de Órgano Interno de Control',
        descripcion:
            'Vigilar que los servidores públicos del Municipio se desempeñen bajo los principios de legalidad, honestidad, imparcialidad, responsabilidad, eficiencia y eficacia.',
        direccion:
            'Av. Benito Juárez Ote. 36, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3888,
        longitud: -99.9956,
        telefono: '427 427 1425',
        email: 'control@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'M. Nelly Martinez Trejo',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Prevención y Atención',
            objetivo:
                'Es la unidad administrativa de consulta para las áreas de la administración pública municipal, para verificar si las conductas próximas a realizar o realizadas conllevar responsabilidad administrativa.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Investigación y Control',
            objetivo:
                'Investigación de conductas probablemente constitutivas de responsabilidad administrativa en términos de la Ley General de Responsabilidades Administrativas, derivadas de denuncias, quejas o de los procesos de fiscalización realizados por los diversos órganos fiscalizadores del orden municipal, estatal y federal.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Substanciación',
            objetivo:
                'Substanciar y resolver los Procedimientos de Responsabilidad Administrativa por faltas no graves y substanciar y remitir, en su caso, aquellos Procedimientos de Responsabilidad Administrativa por faltas graves. Asimismo, substanciar y resolver los Procedimientos de Responsabilidad Patrimonial del Estado y Recursos de Revocación en coadyuvancia con el Titular del Órgano Interno de Control.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/FF5722/FFFFFF?text=Control',
        servicios: [
          'Prevención y Atención',
          'Investigación y Control',
          'Substanciación',
          'Auditorías'
        ],
        color: '#FF5722',
      ),
      Secretaria(
        id: '13',
        nombre: 'Secretaría de Servicios Públicos Municipales',
        descripcion:
            'Planear y proporcionar de manera oportuna y con calidad, los servicios públicos que presta el Gobierno Municipal a la sociedad.',
        direccion:
            'Av. Benito Juárez Ote. 36, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3888,
        longitud: -99.9956,
        telefono: '(427) 689 0012',
        email: 'servicios@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Ernesto Mora Rico',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Limpieza y Recolección',
            objetivo:
                'Programar y coordinar la prestación de los servicios públicos, apegándose a las disposiciones legales, reglamentarias, técnicas y administrativas aplicables.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Cuidado y Control Animal',
            objetivo:
                'Formular, conducir e instrumentar la política municipal sobre conservación y aprovechamiento sustentable de la fauna silvestre y doméstica, en forma congruente con la política nacional en la materia, así como participar en el diseño y aplicación de ésta. Tiene a su cargo el lugar y funciones para el sacrificio de animales para consumo humano.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Infraestructura y Mantenimiento',
            objetivo:
                'Planear y proporcionar la conservación urbana del Municipio de San Juan del Río.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/3F51B5/FFFFFF?text=Servicios',
        servicios: [
          'Limpieza y Recolección',
          'Control Animal',
          'Infraestructura y Mantenimiento',
          'Conservación Urbana'
        ],
        color: '#3F51B5',
      ),
      Secretaria(
        id: '14',
        nombre: 'Secretaría de Centro de Atención Municipal',
        descripcion:
            'Atender y dar un mejor servicio a la ciudadanía de manera óptima, eficaz, eficiente y transparente, con la finalidad de generar un beneficio integral.',
        direccion:
            'Av. Benito Juárez Ote. 36, Centro, 76800 San Juan del Río, Qro.',
        latitud: 20.3888,
        longitud: -99.9956,
        telefono: '(427) 689 0012',
        email: 'atencion@sanjuandelrio.gob.mx',
        horarioAtencion: 'Lunes a Viernes: 8:00 AM - 4:00 PM',
        secretario: 'Roberto Jiménez Salinas',
        direcciones: [
          DireccionDepartamento(
            nombre: 'Dirección de Salud Comunitaria',
            objetivo:
                'Acercar y otorgar servicio médico de primer nivel, y entregar medicamentos en la medida del presupuesto asignado, para beneficio de los sanjuanenses.',
          ),
          DireccionDepartamento(
            nombre: 'Dirección de Trámites Administrativos',
            objetivo:
                'Acercar los trámites que realiza la administración pública, a la población para simplificar su acceso a los mismos y colaborar para la instalación de cobros de derechos, contribuciones, impuestos o cualquier otro que sea objeto de la administración pública.',
          ),
        ],
        imagen:
            'https://via.placeholder.com/300x200/00BCD4/FFFFFF?text=Atencion',
        servicios: [
          'Salud Comunitaria',
          'Trámites Administrativos',
          'Atención Ciudadana',
          'Servicios Integrales'
        ],
        color: '#00BCD4',
      ),
    ];
  }
}
