// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:confetti/confetti.dart';
import '../services/user_data_service.dart';
import '../models/usuario_cus.dart';

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
          color: const Color(0xFF0B3B60), // govBlue
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 300),
        showDuration: const Duration(seconds: 3),
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
  static const govBlueLight = Color(0xFF085184);
  static const govBlueDark = Color(0xFF045EA0);
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
    'Acta de Nacimiento': 'assets/Acta_nacimiento.png',
    'CURP': 'assets/Curp.png',
    'Comprobante Domicilio': 'assets/Comprobante_domicilio.png',
    'Acta de Matrimonio': 'assets/Acta_matrimonio.png',
    'Acta de Concubinato': 'assets/Acta_concubinato.png',
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
      final docs = await UserDataService.getUserDocuments();
      print('Documentos recibidos de la API:');
      for (final doc in docs) {
        print('  - ${doc.nombreDocumento} | ${doc.urlDocumento}');
      }
      // Mapear los documentos de la API al mapa local
      for (final doc in docs) {
        // Mapeo flexible por palabra clave
        String nombreApi = doc.nombreDocumento.toLowerCase();
        String? key;
        if (nombreApi.contains('ine')) {
          key = 'INE';
        } else if (nombreApi.contains('nacimiento')) {
          key = 'Acta de Nacimiento';
        } else if (nombreApi.contains('curp')) {
          key = 'CURP';
        } else if (nombreApi.contains('domicilio')) {
          key = 'Comprobante Domicilio';
        } else if (nombreApi.contains('matrimonio')) {
          key = 'Acta de Matrimonio';
        } else if (nombreApi.contains('concubinato')) {
          key = 'Acta de Concubinato';
        }
        if (key != null && _documentos.containsKey(key)) {
          print('Asignando documento ${doc.nombreDocumento} a slot $key');
          _documentos[key] = DocumentoItem(
            nombre: doc.nombreDocumento,
            ruta: doc.urlDocumento,
            fechaSubida:
                DateTime.tryParse(doc.uploadDate ?? '') ?? DateTime.now(),
            tamano: 0,
            extension: 'pdf',
          );
        }
      }
    } catch (e) {
      // Puedes mostrar un error si lo deseas
    } finally {
      setState(() => _isLoading = false);
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

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => _PDFViewerScreen(documento: documento),
      ),
    )
        .then((_) {
      _vistaPreviaAbierta = false;
    });
  }

  void _mostrarVistaPreviaDialog(DocumentoItem documento) {
    if (_vistaPreviaAbierta) return;
    _vistaPreviaAbierta = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mejorado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: govBlue,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vista Previa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      documento.nombre,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Contenido del PDF
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: documento.ruta.startsWith('http')
                          ? SfPdfViewer.network(
                              documento.ruta,
                              enableDoubleTapZooming: true,
                              enableTextSelection: false,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              canShowPaginationDialog: false,
                            )
                          : SfPdfViewer.file(
                              File(documento.ruta),
                              enableDoubleTapZooming: true,
                              enableTextSelection: false,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              canShowPaginationDialog: false,
                            ),
                    ),
                  ),
                ),
              ),

              // Información del documento
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRowCompact(
                      Icons.insert_drive_file_rounded,
                      'Archivo',
                      documento.nombre,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRowCompact(
                            Icons.calendar_today_rounded,
                            'Fecha',
                            documento.fechaSubida
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoRowCompact(
                            Icons.storage_rounded,
                            'Tamaño',
                            _formatearTamano(documento.tamano),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _mostrarVistaPrevia(documento);
                        },
                        icon: const Icon(Icons.fullscreen_rounded, size: 18),
                        label: const Text(
                          'Ver Completo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: govBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: govBlue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text(
                          'Cerrar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: govBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _vistaPreviaAbierta = false;
    });
  }

  Widget _buildInfoRowCompact(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: govBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: govBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [govBlue, govBlueLight, govBlueDark],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '¡Documento Subido!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFDC2626),
                            Color(0xFFEF4444),
                            Color(0xFFF87171),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No se pudo subir',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: govBlue, size: 18),
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6B7280),
                            Color(0xFF9CA3AF),
                            Color(0xFFD1D5DB),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Documento eliminado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: item != null ? () => _mostrarVistaPreviaDialog(item) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            gradient: item != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      govBlue.withOpacity(0.02),
                    ],
                  )
                : estaBloquedo
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: item != null
                  ? govBlue.withOpacity(0.2)
                  : estaBloquedo
                      ? Colors.grey.shade300
                      : Colors.grey.shade200,
              width: item != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: item != null
                    ? govBlue.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                blurRadius: item != null ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Status indicator mejorado
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item != null
                              ? govBlue.withOpacity(0.1)
                              : estaBloquedo
                                  ? Colors.grey.shade200
                                  : Colors.grey.shade100,
                          border: Border.all(
                            color: item != null
                                ? govBlue.withOpacity(0.3)
                                : estaBloquedo
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          item != null
                              ? Icons.check_circle_rounded
                              : estaBloquedo
                                  ? Icons.block_rounded
                                  : Icons.add_circle_outline_rounded,
                          color: item != null
                              ? govBlue
                              : estaBloquedo
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Document icon mejorado
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            imagenPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.description_rounded,
                                color: govBlue,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Document info expandido
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: estaBloquedo && item == null
                                    ? Colors.grey.shade600
                                    : const Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item != null
                                        ? govBlue.withOpacity(0.1)
                                        : estaBloquedo
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item != null
                                        ? 'Subido'
                                        : estaBloquedo
                                            ? 'Bloqueado'
                                            : 'Pendiente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: item != null
                                          ? govBlue
                                          : estaBloquedo
                                              ? Colors.red.shade700
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                if (item != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: govBlue,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                            if (item != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Subido el ${item.fechaSubida.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Action buttons mejorados
                      if (item == null && !estaBloquedo)
                        Container(
                          decoration: BoxDecoration(
                            color: govBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => _seleccionarDocumento(tipo),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: govBlue,
                              size: 24,
                            ),
                            tooltip: "Agregar documento PDF",
                          ),
                        )
                      else if (item != null)
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _seleccionarDocumento(tipo),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                tooltip: "Reemplazar documento",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _eliminarDocumento(tipo),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: "Eliminar documento",
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Mostrar información adicional si el documento está subido
                  if (item != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: govBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: govBlue.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: govBlue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Toca para ver vista previa del documento',
                              style: TextStyle(
                                fontSize: 13,
                                color: govBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: govBlue,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mostrar anuncio si está bloqueado
                  if (estaBloquedo && item == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              razonBloqueo,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
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
          ),
        ),
      ),
    );
  }

  @override
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
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: govBlue,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Decorative circles in background
                    Positioned(
                      top: -50,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: -40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Main content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(0, 40, 0, 40),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            "Mis documentos",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Subtitle
                          Text(
                            "Gestiona tus documentos de forma segura",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    // Progress circle positioned at bottom
                    Positioned(
                      bottom: -60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFF8FAFC),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0B3B60).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 4,
                                color: govBlue,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                LiquidCircularProgressIndicator(
                                  value: progreso,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    govBlue,
                                  ),
                                  backgroundColor: Colors.white,
                                  borderColor: Colors.transparent,
                                  borderWidth: 0.0,
                                  direction: Axis.vertical,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${(progreso * 100).toStringAsFixed(0)}%",
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: govBlue,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      "Completado",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 70),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CustomTooltip(
                          message: 'Cargando documento, por favor espera...',
                          child: CircularProgressIndicator(
                            color: govBlue,
                          ),
                        ),
                      )
                    : (documentosSubidos == 0
                        ? Center(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: govBlue, size: 48),
                                  SizedBox(height: 16),
                                  Text(
                                    'No tienes documentos cargados',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: govBlue,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Agrega tus documentos tocando el botón + en cada sección.',
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                            itemCount: _documentosRequeridos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final doc = _documentosRequeridos[index];
                              final item = _documentos[doc];
                              final imagen = item == null
                                  ? _imagenesDocumentos[doc]!
                                  : 'assets/documentoscorrectos.png';
                              return AnimatedContainer(
                                duration:
                                    Duration(milliseconds: 300 + (index * 100)),
                                curve: Curves.easeOutBack,
                                child: _buildItem(doc, item, imagen),
                              );
                            },
                          )),
              ),
            ],
          ),
          // Confetti effect
          if (progreso >= 1.0)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2, // Down
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  govBlue,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                ],
                numberOfParticles: 30,
                gravity: 0.3,
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

// Pantalla completa para visualizar PDFs
class _PDFViewerScreen extends StatefulWidget {
  final DocumentoItem documento;

  const _PDFViewerScreen({required this.documento});

  @override
  State<_PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<_PDFViewerScreen> {
  static const govBlue = Color(0xFF0B3B60);
  static const govBlueLight = Color(0xFF085184);
  static const govBlueDark = Color(0xFF045EA0);
  late PdfViewerController _pdfViewerController;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String _searchText = '';
  final bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar en el documento'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchText = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'Ingresa el texto a buscar...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_searchText.isNotEmpty) {
                _pdfViewerController.searchText(_searchText);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: govBlue),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: govBlue),
            SizedBox(width: 8),
            Text('Información del documento'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                Icons.insert_drive_file, 'Nombre', widget.documento.nombre),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.date_range,
                'Fecha de subida',
                widget.documento.fechaSubida
                    .toLocal()
                    .toString()
                    .split(' ')[0]),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.sd_storage, 'Tamaño',
                _formatearTamano(widget.documento.tamano)),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.extension, 'Formato', widget.documento.extension),
            if (_totalPages > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.pages, 'Total de páginas', _totalPages.toString()),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: govBlue),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: govBlue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: govBlue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documento.nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Página $_currentPageNumber de $_totalPages',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Buscar en el documento',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDocumentInfo,
            tooltip: 'Información del documento',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'zoom_in':
                  _pdfViewerController.zoomLevel =
                      _pdfViewerController.zoomLevel + 0.25;
                  break;
                case 'zoom_out':
                  _pdfViewerController.zoomLevel =
                      _pdfViewerController.zoomLevel - 0.25;
                  break;
                case 'fit_width':
                  _pdfViewerController.zoomLevel = 1.0;
                  break;
                case 'first_page':
                  _pdfViewerController.jumpToPage(1);
                  break;
                case 'last_page':
                  if (_totalPages > 0) {
                    _pdfViewerController.jumpToPage(_totalPages);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'zoom_in',
                child: Row(
                  children: [
                    Icon(Icons.zoom_in),
                    SizedBox(width: 8),
                    Text('Acercar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'zoom_out',
                child: Row(
                  children: [
                    Icon(Icons.zoom_out),
                    SizedBox(width: 8),
                    Text('Alejar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fit_width',
                child: Row(
                  children: [
                    Icon(Icons.fit_screen),
                    SizedBox(width: 8),
                    Text('Ajustar'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'first_page',
                child: Row(
                  children: [
                    Icon(Icons.first_page),
                    SizedBox(width: 8),
                    Text('Primera página'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'last_page',
                child: Row(
                  children: [
                    Icon(Icons.last_page),
                    SizedBox(width: 8),
                    Text('Última página'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Visor de PDF principal
          widget.documento.ruta.startsWith('http')
              ? SfPdfViewer.network(
                  widget.documento.ruta,
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  canShowPaginationDialog: true,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPageNumber = details.newPageNumber;
                    });
                  },
                )
              : SfPdfViewer.file(
                  File(widget.documento.ruta),
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  canShowPaginationDialog: true,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPageNumber = details.newPageNumber;
                    });
                  },
                ),

          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: govBlue),
                    SizedBox(height: 16),
                    Text(
                      'Cargando documento...',
                      style: TextStyle(
                        color: govBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Barra de navegación inferior
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _currentPageNumber > 1
                    ? () => _pdfViewerController.previousPage()
                    : null,
                icon: const Icon(Icons.navigate_before),
                tooltip: 'Página anterior',
                color: _currentPageNumber > 1 ? govBlue : Colors.grey,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: govBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentPageNumber / $_totalPages',
                  style: const TextStyle(
                    color: govBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPageNumber < _totalPages
                    ? () => _pdfViewerController.nextPage()
                    : null,
                icon: const Icon(Icons.navigate_next),
                tooltip: 'Página siguiente',
                color: _currentPageNumber < _totalPages ? govBlue : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
