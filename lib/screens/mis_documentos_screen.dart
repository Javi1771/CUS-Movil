// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:confetti/confetti.dart';
import 'package:cus_movil/services/user_data_service.dart';

class MisDocumentosScreen extends StatefulWidget {
  const MisDocumentosScreen({super.key});

  @override
  State<MisDocumentosScreen> createState() => _MisDocumentosScreenState();
}

class CustomTooltip extends StatelessWidget {
  final Widget child;
  final String message;

  const CustomTooltip({
    super.key,
    required this.child,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return TooltipTheme(
      data: TooltipThemeData(
        decoration: BoxDecoration(
          color: Color(0xFF0B3B60), // govBlue
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: Duration(milliseconds: 300),
        showDuration: Duration(seconds: 3),
      ),
      child: Tooltip(
        message: message,
        child: child,
      ),
    );
  }
}

class DocumentoItem {
  final String nombre;
  final String ruta;
  final DateTime fechaSubida;
  final int tamano;
  final String extension;

  DocumentoItem({
    required this.nombre,
    required this.ruta,
    required this.fechaSubida,
    required this.tamano,
    required this.extension,
  });
}

class _MisDocumentosScreenState extends State<MisDocumentosScreen>
    with SingleTickerProviderStateMixin {
  static const govBlue = Color(0xFF0B3B60);
  static const backgroundGray = Color(0xFFF0F2F5);

  final List<String> _documentosRequeridos = [
    'INE',
    'Acta de Nacimiento',
    'CURP',
    'Comprobante Domicilio',
    'Acta de Matrimonio',
    'Acta de Concubinato',
  ];

  final Map<String, DocumentoItem?> _documentos = {
    'INE': null,
    'Acta de Nacimiento': null,
    'CURP': null,
    'Comprobante Domicilio': null,
    'Acta de Matrimonio': null,
    'Acta de Concubinato': null,
  };

  final Map<String, String> _imagenesDocumentos = {
    'INE': 'assets/ine.png',
    'Acta de Nacimiento': 'assets/acta_nacimiento.png',
    'CURP': 'assets/curp.png',
    'Comprobante Domicilio': 'assets/comprobante_domicilio.png',
    'Acta de Matrimonio': 'assets/acta_matrimonio.png',
    'Acta de Concubinato': 'assets/acta_concubinato.png',
  };

  // Mapa de tooltips informativos para cada documento
  final Map<String, String> _tooltipsDocumentos = {
    'INE': 'Credencial para votar',
    'Acta de Nacimiento': 'Acta de nacimiento certificada',
    'CURP': 'CURP',
    'Comprobante Domicilio': 'Recibo de servicios',
    'Acta de Matrimonio': 'Acta de matrimonio',
    'Acta de Concubinato': 'Acta de concubinato',
  };

  bool _isLoading = false;
  bool _vistaPreviaAbierta = false;
  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;
  late ConfettiController _confettiController;
  final Random _random = Random();

  int get documentosSubidos =>
      _documentos.values.where((item) => item != null).length;
  int get totalDocumentos => _documentosRequeridos.length;
  double get progreso =>
      totalDocumentos == 0 ? 0 : documentosSubidos / totalDocumentos;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _bubbleAnimation = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.linear),
    );

    _cargarDocumentosDesdeAPI();
  }

  Future<void> _cargarDocumentosDesdeAPI() async {
    setState(() => _isLoading = true);
    try {
      // Intentar cargar documentos usando el nuevo método específico
      final documentos = await UserDataService.getUserDocuments();
      
      if (documentos.isNotEmpty) {
        for (final doc in documentos) {
          final nombre = doc.nombreDocumento.toLowerCase();
          if (nombre.contains('ine')) {
            _documentos['INE'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          } else if (nombre.contains('acta') || nombre.contains('nacimiento')) {
            _documentos['Acta de Nacimiento'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          } else if (nombre.contains('curp')) {
            _documentos['CURP'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          } else if (nombre.contains('comprobante')) {
            _documentos['Comprobante Domicilio'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          } else if (nombre.contains('matrimonio')) {
            _documentos['Acta de Matrimonio'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          } else if (nombre.contains('concubinato')) {
            _documentos['Acta de Concubinato'] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.now(),
              tamano: 0,
              extension: 'PDF',
            );
          }
        }
      }
    } catch (e) {
      // Si falla la carga de documentos específicos, intentar con getUserData como fallback
      try {
        final user = await UserDataService.getUserData();
        if (user != null && user.documentos != null && user.documentos!.isNotEmpty) {
          for (final doc in user.documentos!) {
            final nombre = doc.nombreDocumento.toLowerCase();
            if (nombre.contains('ine')) {
              _documentos['INE'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            } else if (nombre.contains('acta') || nombre.contains('nacimiento')) {
              _documentos['Acta de Nacimiento'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            } else if (nombre.contains('curp')) {
              _documentos['CURP'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            } else if (nombre.contains('comprobante')) {
              _documentos['Comprobante Domicilio'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            } else if (nombre.contains('matrimonio')) {
              _documentos['Acta de Matrimonio'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            } else if (nombre.contains('concubinato')) {
              _documentos['Acta de Concubinato'] = DocumentoItem(
                nombre: doc.nombreDocumento,
                ruta: doc.urlDocumento,
                fechaSubida: DateTime.now(),
                tamano: 0,
                extension: 'PDF',
              );
            }
          }
        }
      } catch (e2) {
        debugPrint('[MisDocumentosScreen] Error al cargar documentos: $e2');
        // Mostrar error si es necesario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar documentos: ${_getErrorMessage(e2.toString())}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Usuario no autenticado')) {
      return 'Sesión expirada';
    } else if (error.contains('Sesión expirada')) {
      return 'Tu sesión ha expirado';
    } else if (error.contains('Tiempo de espera agotado')) {
      return 'Conexión lenta';
    } else if (error.contains('Error de conexión')) {
      return 'Sin conexión a internet';
    } else {
      return 'Error del servidor';
    }
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarDocumento(String tipo) async {
    try {
      // ✅ Validación cruzada entre Matrimonio y Concubinato
      if (tipo == 'Acta de Matrimonio' &&
          _documentos['Acta de Concubinato'] != null) {
        _mostrarAlertaError(
            "Ya se ha subido un acta de concubinato. No puedes subir ambas.");
        return;
      }

      if (tipo == 'Acta de Concubinato' &&
          _documentos['Acta de Matrimonio'] != null) {
        _mostrarAlertaError(
            "Ya se ha subido un acta de matrimonio. No puedes subir ambas.");
        return;
      }

      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.first;
        File selectedFile = File(file.path!);

        if (!await selectedFile.exists()) {
          throw Exception('El archivo no existe');
        }
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('Archivo demasiado grande (>10MB)');
        }

        // Subir el documento a la API
        final uploadSuccess = await UserDataService.uploadDocument(tipo, file.path!);
        
        if (uploadSuccess) {
          final documento = DocumentoItem(
            nombre: file.name,
            ruta: file.path!,
            fechaSubida: DateTime.now(),
            tamano: file.size,
            extension: file.extension?.toUpperCase() ?? "PDF",
          );

          setState(() => _documentos[tipo] = documento);
          if (progreso == 1.0) _confettiController.play();

          _mostrarAlertaExito(tipo, documento);
        } else {
          throw Exception('No se pudo subir el documento al servidor');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarAlertaError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _eliminarDocumento(String tipo) {
    setState(() => _documentos[tipo] = null);
    _mostrarAlertaEliminacion(tipo);
  }

  void _mostrarVistaPrevia(DocumentoItem documento) {
    if (_vistaPreviaAbierta) return;
    _vistaPreviaAbierta = true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.all(0),
            contentPadding: const EdgeInsets.all(20),
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF0B3B60),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTooltip(
                    message: 'Vista previa del documento PDF',
                    child: Icon(Icons.picture_as_pdf,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      documento.nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTooltip(
                  message: 'Desliza para navegar por las páginas del PDF',
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PDFView(
                        filePath: documento.ruta,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: false,
                        pageSnap: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file_rounded,
                              color: govBlue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTooltip(
                              message: 'Información del archivo seleccionado',
                              child: Text(
                                documento.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.date_range, color: govBlue),
                          const SizedBox(width: 10),
                          CustomTooltip(
                            message: 'Fecha en que se subió el documento',
                            child: Text(
                                'Subido: ${documento.fechaSubida.toLocal().toString().split(' ')[0]}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.sd_storage, color: govBlue),
                          const SizedBox(width: 10),
                          CustomTooltip(
                            message: 'Tamaño del archivo en disco',
                            child: Text(
                                'Tamaño: ${_formatearTamano(documento.tamano)}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: CustomTooltip(
                  message: 'Cerrar vista previa',
                  child: Text("CANCELAR"),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: govBlue),
                child: CustomTooltip(
                  message: 'Confirmar y cerrar',
                  child: Text("ACEPTAR"),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _vistaPreviaAbierta = false;
    });
  }

  void _mostrarAlertaExito(String tipo, DocumentoItem documento) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 300),
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF0B3B60),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '¡Documento Subido!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3B60),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'El documento "${documento.nombre}" se ha subido correctamente.',
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    });
  }

  void _mostrarAlertaError(String error) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Center(
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 300),
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF0B3B60),
                      child: const Icon(Icons.error_outline,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No se pudo subir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3B60),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _obtenerMensajeError(error),
                      style:
                          const TextStyle(fontSize: 15, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline,
                              color: Color(0xFF0B3B60), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Verifica que el archivo sea un PDF válido y menor a 10MB.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    });
  }

  void _mostrarAlertaEliminacion(String tipo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 300),
            child: Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 40),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF0B3B60),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Documento eliminado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3B60),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Puedes volver a cargarlo cuando sea necesario.',
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    });
  }

  String _obtenerMensajeError(String error) {
    if (error.contains('demasiado grande')) {
      return 'El archivo es demasiado grande. Debe ser menor a 10MB.';
    } else if (error.contains('no existe')) {
      return 'No se pudo acceder al archivo seleccionado.';
    } else if (error.contains('PDF')) {
      return 'Solo se permiten archivos en formato PDF.';
    } else {
      return 'Ocurrió un error inesperado. Intenta nuevamente.';
    }
  }

  Widget _iconButton(IconData icon, String label, VoidCallback onPressed) {
    return CustomTooltip(
      message: label,
      child: GestureDetector(
        onTap: onPressed,
        child: CircleAvatar(
          backgroundColor: backgroundGray,
          radius: 18,
          child: Icon(icon, size: 20, color: govBlue),
        ),
      ),
    );
  }

  Widget _buildItem(String tipo, DocumentoItem? item, String imagenPath) {
    // Verificar si este documento está bloqueado por el otro tipo
    bool estaBloquedo = false;
    String razonBloqueo = '';

    if (tipo == 'Acta de Matrimonio' &&
        _documentos['Acta de Concubinato'] != null) {
      estaBloquedo = true;
      razonBloqueo =
          'Ya tienes un Acta de Concubinato subida. Solo puedes tener uno de los dos documentos.';
    } else if (tipo == 'Acta de Concubinato' &&
        _documentos['Acta de Matrimonio'] != null) {
      estaBloquedo = true;
      razonBloqueo =
          'Ya tienes un Acta de Matrimonio subida. Solo puedes tener uno de los dos documentos.';
    }

    return GestureDetector(
      onTap: item != null ? () => _mostrarVistaPrevia(item) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color:
              estaBloquedo && item == null ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: estaBloquedo && item == null
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomTooltip(
                  message: item != null
                      ? 'Documento subido correctamente'
                      : estaBloquedo
                          ? 'Documento bloqueado'
                          : 'Documento pendiente por subir',
                  child: Icon(
                    item != null
                        ? Icons.check_circle
                        : estaBloquedo
                            ? Icons.block
                            : Icons.radio_button_unchecked,
                    color: item != null
                        ? govBlue
                        : estaBloquedo
                            ? Colors.grey.shade400
                            : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                CustomTooltip(
                  message: _tooltipsDocumentos[tipo] ?? 'Documento requerido',
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    backgroundImage: AssetImage(imagenPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTooltip(
                    message: item != null ? 'Toca para mostrar: $tipo' : tipo,
                    child: Container(
                      padding: const EdgeInsets.only(right: 8),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tipo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: estaBloquedo && item == null
                              ? Colors.grey.shade500
                              : Colors.black,
                        ),
                        maxLines: 3,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                if (item == null && !estaBloquedo)
                  _iconButton(Icons.add, "Agregar documento PDF",
                      () => _seleccionarDocumento(tipo))
                else if (item != null)
                  Row(
                    children: [
                      _iconButton(Icons.refresh, "Reemplazar documento",
                          () => _seleccionarDocumento(tipo)),
                      const SizedBox(width: 10),
                      _iconButton(Icons.delete_outline, "Eliminar documento",
                          () => _eliminarDocumento(tipo)),
                    ],
                  ),
              ],
            ),
            // Mostrar anuncio si está bloqueado
            if (estaBloquedo && item == null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 225, 225),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color.fromARGB(255, 255, 141, 141),
                      width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color.fromARGB(255, 221, 3, 3),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        razonBloqueo,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color.fromARGB(255, 243, 2, 2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    // Cálculo dinámico de documentos subidos
    int calcularDocumentosSubidos(Map<String, DocumentoItem?> docs) {
      int count = 0;
      bool matrimonioContado = false;

      docs.forEach((key, value) {
        if (value != null) {
          if ((key == 'Acta de Matrimonio' || key == 'Acta de Concubinato') &&
              !matrimonioContado) {
            count++;
            matrimonioContado = true;
          } else if (key != 'Acta de Matrimonio' &&
              key != 'Acta de Concubinato') {
            count++;
          }
        }
      });

      return count;
    }

    // Cálculo del total necesario
    int calcularTotalEsperado(Map<String, DocumentoItem?> docs) {
      bool matrimonioSubido = docs['Acta de Matrimonio'] != null;
      bool concubinatoSubido = docs['Acta de Concubinato'] != null;
      int total = _documentosRequeridos.length;

      // Si se sube uno de los dos excluyentes, se reduce el total
      if (matrimonioSubido || concubinatoSubido) {
        total -= 1;
      }

      return total;
    }

    final documentosSubidos = calcularDocumentosSubidos(_documentos);
    final totalDocumentos = calcularTotalEsperado(_documentos);
    final progreso =
        totalDocumentos == 0 ? 0.0 : documentosSubidos / totalDocumentos;

    return Scaffold(
      backgroundColor: backgroundGray,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 80),
                decoration: const BoxDecoration(
                  color: govBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Mis documentos",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomTooltip(
                      message:
                          'Progreso de documentos: $documentosSubidos de $totalDocumentos completados',
                      child: Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF0B3B60),
                                  Color(0xFF145DA0),
                                  Color(0xFF1D7CC1),
                                ],
                              ).createShader(bounds),
                              blendMode: BlendMode.srcIn,
                              child: LiquidCircularProgressIndicator(
                                value: progreso,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                backgroundColor: Colors.white,
                                borderColor: Colors.transparent,
                                borderWidth: 0.0,
                                direction: Axis.vertical,
                              ),
                            ),
                            Text(
                              "${(progreso * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B3B60),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _bubbleAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            children: List.generate(6, (index) {
                              double left = 10 + index * 18;
                              double size = 8 + _random.nextDouble() * 8;
                              return Positioned(
                                bottom: _bubbleAnimation.value - index * 10,
                                left: left,
                                child: Icon(
                                  Icons.circle,
                                  color: govBlue.withOpacity(0.25),
                                  size: size,
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        colors: const [
                          Colors.blue,
                          Colors.lightBlue,
                          Colors.white
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CustomTooltip(
                      message: 'Cargando documento, por favor espera...',
                      child: CircularProgressIndicator(
                        color: govBlue,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    itemCount: _documentosRequeridos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final doc = _documentosRequeridos[index];
                      final item = _documentos[doc];
                      final imagen = item == null
                          ? _imagenesDocumentos[doc]!
                          : 'assets/documentoscorrectos.png';
                      return _buildItem(doc, item, imagen);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatearTamano(int bytes) {
    const unidades = ['B', 'KB', 'MB', 'GB', 'TB'];
    double tamano = bytes.toDouble();
    int i = 0;
    while (tamano >= 1024 && i < unidades.length - 1) {
      tamano /= 1024;
      i++;
    }
    return '${tamano.toStringAsFixed(2)} ${unidades[i]}';
  }
}
