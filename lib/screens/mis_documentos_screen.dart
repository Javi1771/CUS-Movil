// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:confetti/confetti.dart';
import '../services/user_data_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart'; // abrir no-PDF

class MisDocumentosScreen extends StatefulWidget {
  const MisDocumentosScreen({super.key});

  @override
  State<MisDocumentosScreen> createState() => _MisDocumentosScreenState();
}

class DocumentoItem {
  final String nombre;
  final String ruta; //* Puede ser URL (Cloudinary) o ruta local
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
  static const govBlueLight = Color(0xFF1E40AF);
  static const cardBackground = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const successColor = Color(0xFF059669);
  static const warningColor = Color(0xFFD97706);
  static const errorColor = Color(0xFFDC2626);

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

  //* (opcional) recordatorio de mapeos nombre->tipo si el backend devuelve otros nombres
  final Map<String, String> _documentoTipoMap = {};

  final Map<String, IconData> _iconosDocumentos = {
    'INE': Icons.credit_card,
    'Acta de Nacimiento': Icons.child_care,
    'CURP': Icons.fingerprint,
    'Comprobante Domicilio': Icons.home,
    'Acta de Matrimonio': Icons.favorite,
    'Acta de Concubinato': Icons.people,
  };

  //* Loader global
  bool _isLoading = false;

  //* Confetti
  late ConfettiController _confettiController;

  int get documentosSubidos =>
      _documentos.values.where((item) => item != null).length;
  int get totalDocumentos => _documentosRequeridos.length;
  double get progreso =>
      totalDocumentos == 0 ? 0 : documentosSubidos / totalDocumentos;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _cargarDocumentosDesdeAPI();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  //? ---- Canonicalización de tipos y nombres ----

  String _canonicalTypeId(String tipo) {
    final t = tipo.toLowerCase().trim();
    if (t.contains('ine')) return 'ine';
    if (t.contains('curp')) return 'curp';
    if (t.contains('nacimiento')) return 'actaNacimiento';
    if (t.contains('domicilio') || t.contains('comprobante')) {
      return 'comprobanteDomicilio';
    }
    if (t.contains('matrimonio')) return 'actaMatrimonio';
    if (t.contains('concubinato')) return 'actaConcubinato';
    return '';
  }

  String? _canonicalFilenameForTipo(String tipo) {
    switch (_canonicalTypeId(tipo)) {
      case 'ine':
        return 'ine.pdf';
      case 'curp':
        return 'curp.pdf';
      case 'actaNacimiento':
        return 'actaNacimiento.pdf';
      case 'comprobanteDomicilio':
        return 'comprobanteDomicilio.pdf';
      case 'actaMatrimonio':
        return 'actaMatrimonio.pdf';
      case 'actaConcubinato':
        return 'actaConcubinato.pdf';
      default:
        return null;
    }
  }

  //? ---- Utilidades UI ----

  void _mostrarInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  //? ---- Carga inicial desde API ----

  Future<void> _cargarDocumentosDesdeAPI() async {
    debugPrint('[MisDocumentos] Cargando documentos...');
    if (mounted) setState(() => _isLoading = true);
    try {
      final docs = await UserDataService.getUserDocuments();

      //* Limpia estado previo
      for (final k in _documentos.keys.toList()) {
        _documentos[k] = null;
      }

      for (final doc in docs) {
        final nombreApi = (doc.nombreDocumento).toLowerCase();
        String? key;

        if (_documentoTipoMap.containsKey(doc.nombreDocumento)) {
          key = _documentoTipoMap[doc.nombreDocumento];
        } else {
          if (nombreApi.contains('ine'))
            key = 'INE';
          else if (nombreApi.contains('nacimiento'))
            key = 'Acta de Nacimiento';
          else if (nombreApi.contains('curp'))
            key = 'CURP';
          else if (nombreApi.contains('domicilio') ||
              nombreApi.contains('comprobante')) {
            key = 'Comprobante Domicilio';
          } else if (nombreApi.contains('matrimonio'))
            key = 'Acta de Matrimonio';
          else if (nombreApi.contains('concubinato'))
            key = 'Acta de Concubinato';
        }

        if (key != null && _documentos.containsKey(key)) {
          if ((doc.urlDocumento).isEmpty) continue;

          _documentos[key] = DocumentoItem(
            nombre: doc.nombreDocumento,
            ruta: doc.urlDocumento, //* URL remota
            fechaSubida:
                DateTime.tryParse(doc.uploadDate ?? '') ?? DateTime.now(),
            tamano: 0, //! desconocido
            extension: 'pdf',
          );
        }
      }

      if (mounted) setState(() {}); //* refresca UI
    } catch (e) {
      debugPrint('[MisDocumentos] Error al cargar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentos: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //? ---- Helpers: abrir sin exponer URL ----

  bool _esPdf(DocumentoItem d) {
    final ext = d.extension.toLowerCase();
    if (ext == 'pdf') return true;
    final path =
        Uri.tryParse(d.ruta)?.path.toLowerCase() ?? d.ruta.toLowerCase();
    return path.endsWith('.pdf');
  }

  Future<void> _abrirDocumento(DocumentoItem d) async {
    try {
      if (_esPdf(d)) {
        // PDF → visor (network si URL, file si local)
        _mostrarVistaPreviaDialog(d);
      } else {
        final uri =
            d.ruta.startsWith('http') ? Uri.parse(d.ruta) : Uri.file(d.ruta);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el documento.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir el documento.')),
        );
      }
    }
  }

  //? ---- Subida (solo si no existe) con nombre canónico ----

  Future<void> _seleccionarDocumento(String tipoVisible) async {
    try {
      //! Bloquea si ya hay uno de ese tipo
      if (_documentos[tipoVisible] != null) {
        _mostrarInfo('Acción no permitida',
            'Ya existe un documento para "$tipoVisible". Solo puedes visualizarlo.');
        return;
      }

      //* Exclusión Matrimonio/Concubinato
      if (tipoVisible == 'Acta de Matrimonio' &&
          _documentos['Acta de Concubinato'] != null) {
        _mostrarInfo('Acción no permitida',
            'Ya se subió Acta de Concubinato. No puedes subir ambas.');
        return;
      }
      if (tipoVisible == 'Acta de Concubinato' &&
          _documentos['Acta de Matrimonio'] != null) {
        _mostrarInfo('Acción no permitida',
            'Ya se subió Acta de Matrimonio. No puedes subir ambas.');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        debugPrint('[MisDocumentos] Selección cancelada');
        return;
      }

      final picked = result.files.first;
      final pickedFile = File(picked.path!);

      if (!await pickedFile.exists()) {
        throw Exception('El archivo no existe');
      }
      if (picked.size > 10 * 1024 * 1024) {
        throw Exception('Archivo demasiado grande (>10MB)');
      }

      final desiredName = _canonicalFilenameForTipo(tipoVisible);
      if (desiredName == null) {
        _mostrarInfo(
            'Tipo no soportado', 'No hay nombre canónico para "$tipoVisible".');
        return;
      }

      //* Loader ON
      if (mounted) setState(() => _isLoading = true);

      //* Copia temporal con nombre canónico (sobrescribe si existe)
      final tmpDir = await getTemporaryDirectory();
      final tempPath = p.join(tmpDir.path, desiredName);
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final copied = await pickedFile.copy(tempPath);

      debugPrint(
          '[MisDocumentos] Subiendo "$desiredName" desde ${copied.path}');

      //* Sube al backend
      final uploadRes =
          await UserDataService.uploadDocument(tipoVisible, copied.path);

      final success = uploadRes['success'] == true;
      if (!success) {
        throw Exception(
            uploadRes['message'] ?? 'Error desconocido al subir el documento');
      }

      final url = (uploadRes['url'] as String?) ?? '';
      final documento = DocumentoItem(
        nombre: desiredName,
        ruta: url.isNotEmpty ? url : copied.path, //* fallback local
        fechaSubida: DateTime.now(),
        tamano: picked.size,
        extension: 'PDF',
      );

      //* Refleja inmediatamente en UI
      setState(() {
        _documentos[tipoVisible] = documento;
        _documentoTipoMap[desiredName] = _canonicalTypeId(tipoVisible);
      });

      if (progreso == 1.0) _confettiController.play();
      _mostrarAlertaExito(tipoVisible, documento);

      //* Refresca desde API (por si el backend modifica nombre/URL)
      await _cargarDocumentosDesdeAPI();
    } catch (e) {
      debugPrint('[MisDocumentos] Error al subir: $e');
      if (!mounted) return;
      _mostrarAlertaError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //? ---- Vista previa en diálogo (solo lectura) ----

  void _mostrarVistaPreviaDialog(DocumentoItem documento) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.92,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //* Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: govBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description,
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
                            documento.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vista previa del documento',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close,
                          size: 20, color: textSecondary),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              //* PDF
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          documento.ruta.startsWith('http')
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
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                documento.ruta.startsWith('http')
                                    ? 'Desde URL'
                                    : 'Local',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              //* Info y botón cerrar
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    _buildDocumentInfo(
                        'Formato',
                        documento.extension.toUpperCase(),
                        Icons.insert_drive_file),
                    const SizedBox(width: 20),
                    _buildDocumentInfo('Tamaño',
                        _formatFileSize(documento.tamano), Icons.storage),
                    const SizedBox(width: 20),
                    _buildDocumentInfo('Subido',
                        _formatDate(documento.fechaSubida), Icons.schedule),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMinimalButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icons.close,
                        label: 'Cerrar',
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  //? ---- Helpers UI ----

  Widget _buildDocumentInfo(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: textSecondary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isPrimary ? govBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isPrimary
            ? null
            : Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isPrimary ? Colors.white : textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Desconocido';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _mostrarAlertaExito(String tipo, DocumentoItem documento) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [successColor, Color(0xFF10B981)]),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Documento Subido!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El documento se ha guardado correctamente.',
                    style: TextStyle(
                        fontSize: 14, color: textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
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
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [errorColor, Color(0xFFEF4444)]),
                    ),
                    child: const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al subir',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _obtenerMensajeError(error),
                    style: const TextStyle(
                        fontSize: 14, color: textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
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

  String _obtenerMensajeError(String error) {
    if (error.contains('demasiado grande')) {
      return 'El archivo es demasiado grande. Debe ser menor a 10MB.';
    } else if (error.contains('no existe')) {
      return 'No se pudo acceder al archivo seleccionado.';
    } else if (error.toLowerCase().contains('pdf')) {
      return 'Solo se permiten archivos en formato PDF.';
    } else {
      return 'Ocurrió un error inesperado. Intenta nuevamente.';
    }
  }

  //? ---- Tarjeta por documento ----

  Widget _buildDocumentCard(String tipo, DocumentoItem? item, int index) {
    bool estaBloquedo = false;
    String razonBloqueo = '';

    if (tipo == 'Acta de Matrimonio' &&
        _documentos['Acta de Concubinato'] != null) {
      estaBloquedo = true;
      razonBloqueo = 'Ya tienes un Acta de Concubinato subida.';
    } else if (tipo == 'Acta de Concubinato' &&
        _documentos['Acta de Matrimonio'] != null) {
      estaBloquedo = true;
      razonBloqueo = 'Ya tienes un Acta de Matrimonio subida.';
    }

    Color statusColor = item != null
        ? successColor
        : estaBloquedo
            ? errorColor
            : warningColor;

    String statusText = item != null
        ? 'Completado'
        : estaBloquedo
            ? 'Bloqueado'
            : 'Pendiente';

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: InkWell(
            onTap: item != null
                ? () => _abrirDocumento(item)
                : null, // abre según tipo
            onLongPress: null, //! sin acciones de contexto
            borderRadius: BorderRadius.circular(16),
            splashColor: govBlue.withOpacity(0.05),
            highlightColor: govBlue.withOpacity(0.02),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item != null
                      ? successColor.withOpacity(0.2)
                      : estaBloquedo
                          ? errorColor.withOpacity(0.2)
                          : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item != null
                        ? successColor.withOpacity(0.06)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      //* Icono
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          _iconosDocumentos[tipo] ?? Icons.description_rounded,
                          color: govBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),

                      //* Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: estaBloquedo && item == null
                                    ? textSecondary
                                    : textPrimary,
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Subido el ${item.fechaSubida.toLocal().toString().split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // 🔒 No mostramos la URL en texto
                            ],
                          ],
                        ),
                      ),

                      //* Acción (solo Ver)
                      if (item == null && !estaBloquedo)
                        _buildActionButton(
                          icon: Icons.add_rounded,
                          color: govBlue,
                          onPressed: () => _seleccionarDocumento(tipo),
                        )
                      else if (item != null)
                        _buildActionButton(
                          icon: Icons.visibility_outlined,
                          color: govBlue,
                          onPressed: () => _abrirDocumento(item),
                          size: 18,
                        ),
                    ],
                  ),
                  if (item != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: successColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_outlined,
                              color: successColor, size: 14),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Toca para ver documento',
                              style: TextStyle(
                                fontSize: 12,
                                color: successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: successColor.withOpacity(0.7), size: 10),
                        ],
                      ),
                    ),
                  ],
                  if (estaBloquedo && item == null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: errorColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: errorColor, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              razonBloqueo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: errorColor,
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 20,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Center(child: Icon(icon, color: color, size: size)),
        ),
      ),
    );
  }

  //? ---- Header ----

  Widget _buildBannerHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B3B60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 40),
        child: Column(
          children: [
            const Text(
              "Mis Documentos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.10,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Gestiona tus documentos de forma segura",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Text(
                "$documentosSubidos de $totalDocumentos documentos",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //? ---- Build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildBannerHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      Column(
                        children:
                            _documentosRequeridos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final doc = entry.value;
                          final item = _documentos[doc];
                          return _buildDocumentCard(doc, item, index);
                        }).toList(),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          //* Overlay loader global
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: govBlue,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: progreso >= 1.0
          ? Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 3.14 / 2,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  govBlue,
                  govBlueLight,
                  successColor,
                  Color(0xFF10B981),
                  Color(0xFF3B82F6),
                ],
                numberOfParticles: 40,
                gravity: 0.3,
              ),
            )
          : null,
    );
  }
}
