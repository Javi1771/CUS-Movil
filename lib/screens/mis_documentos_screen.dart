// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:confetti/confetti.dart';
import '../services/user_data_service.dart';

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

  // Mapa para recordar qué tipo de documento se subió con cada nombre
  final Map<String, String> _documentoTipoMap = {};

  final Map<String, IconData> _iconosDocumentos = {
    'INE': Icons.credit_card,
    'Acta de Nacimiento': Icons.child_care,
    'CURP': Icons.fingerprint,
    'Comprobante Domicilio': Icons.home,
    'Acta de Matrimonio': Icons.favorite,
    'Acta de Concubinato': Icons.people,
  };

  bool _isLoading = false;
  bool _vistaPreviaAbierta = false;
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

  Future<void> _cargarDocumentosDesdeAPI() async {
    debugPrint('[MisDocumentosScreen] 📥 Iniciando carga de documentos desde API...');
    setState(() => _isLoading = true);
    try {
      final docs = await UserDataService.getUserDocuments();
      debugPrint('[MisDocumentosScreen] 📥 Documentos obtenidos de la API: ${docs.length}');

      //* Limpiar mapa (para no dejar residuos de sesiones previas)
      for (final k in _documentos.keys.toList()) {
        _documentos[k] = null;
      }
      debugPrint('[MisDocumentosScreen] 📥 Mapa de documentos limpiado');

      int documentosProcesados = 0;
      for (final doc in docs) {
        final nombreApi = (doc.nombreDocumento).toLowerCase();
        debugPrint('[MisDocumentosScreen] 📥 Procesando documento: ${doc.nombreDocumento}');
        debugPrint('[MisDocumentosScreen] 📥 URL del documento: ${doc.urlDocumento}');
        
        String? key;
        
        // Primero, verificar si tenemos una relación guardada para este documento
        if (_documentoTipoMap.containsKey(doc.nombreDocumento)) {
          key = _documentoTipoMap[doc.nombreDocumento];
          debugPrint('[MisDocumentosScreen] 📥 🎯 Usando relación guardada: ${doc.nombreDocumento} -> $key');
        } else {
          // Si no, usar el mapeo por nombre como antes
          if (nombreApi.contains('ine')) {
            key = 'INE';
          } else if (nombreApi.contains('nacimiento')) {
            key = 'Acta de Nacimiento';
          } else if (nombreApi.contains('curp')) {
            key = 'CURP';
          } else if (nombreApi.contains('domicilio') ||
              nombreApi.contains('comprobante')) {
            key = 'Comprobante Domicilio';
          } else if (nombreApi.contains('matrimonio')) {
            key = 'Acta de Matrimonio';
          } else if (nombreApi.contains('concubinato')) {
            key = 'Acta de Concubinato';
          }
        }

        if (key != null && _documentos.containsKey(key)) {
          debugPrint('[MisDocumentosScreen] 📥 Documento mapeado a categoría: $key');
          
          // Validar que la URL no esté vacía
          if (doc.urlDocumento.isEmpty) {
            debugPrint('[MisDocumentosScreen] ⚠️ Documento sin URL válida, omitiendo: ${doc.nombreDocumento}');
            continue;
          }
          
          //* Renderiza usando la URL que llegue (Cloudinary u otra)
          _documentos[key] = DocumentoItem(
            nombre: doc.nombreDocumento,
            ruta: doc.urlDocumento, //* <<--- URL remota para renderizar
            fechaSubida:
                DateTime.tryParse(doc.uploadDate ?? '') ?? DateTime.now(),
            tamano: 0, //! Desconocido desde API
            extension: 'pdf',
          );
          documentosProcesados++;
          debugPrint('[MisDocumentosScreen] 📥 ✅ Documento procesado correctamente: $key');
        } else {
          debugPrint('[MisDocumentosScreen] 📥 ⚠️ Documento no reconocido o categoría no válida: ${doc.nombreDocumento}');
        }
      }
      
      debugPrint('[MisDocumentosScreen] 📥 Total documentos procesados: $documentosProcesados');
      setState(() {});
    } catch (e) {
      debugPrint('[MisDocumentosScreen] ❌ Error cargando documentos desde API: $e');
      // Mostrar un mensaje de error al usuario si es necesario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar documentos: ${e.toString()}'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[MisDocumentosScreen] 📥 Carga de documentos finalizada');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarDocumento(String tipo) async {
    try {
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

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result != null && result.files.single.path != null) {
        final file = result.files.first;
        final selectedFile = File(file.path!);

        if (!await selectedFile.exists()) {
          throw Exception('El archivo no existe');
        }
        if (file.size > 10 * 1024 * 1024) {
          throw Exception('Archivo demasiado grande (>10MB)');
        }

        debugPrint('[MisDocumentosScreen] 📤 Iniciando subida de documento: $tipo');
        debugPrint('[MisDocumentosScreen] 📤 Archivo: ${file.name} (${file.size} bytes)');

        //* Sube a la API (usa la URL pública de SJR configurada en UserDataService)
        final uploadRes = await UserDataService.uploadDocument(tipo, file.path!);
        
        debugPrint('[MisDocumentosScreen] 📤 Respuesta de subida: $uploadRes');
        
        final success = uploadRes['success'] == true;
        if (!success) {
          throw Exception('Error en la subida: ${uploadRes['message'] ?? 'Error desconocido'}');
        }

        final url = (uploadRes['url'] as String?) ?? '';
        final nombreSrv = (uploadRes['name'] as String?) ?? file.name;

        debugPrint('[MisDocumentosScreen] 📤 URL obtenida: $url');
        debugPrint('[MisDocumentosScreen] 📤 Nombre del servidor: $nombreSrv');

        final documento = DocumentoItem(
          nombre: nombreSrv,
          ruta: url.isNotEmpty
              ? url
              : file.path!, //* fallback local si no hay URL
          fechaSubida: DateTime.now(),
          tamano: file.size,
          extension: (file.extension?.isNotEmpty ?? false)
              ? file.extension!.toUpperCase()
              : "PDF",
        );

        setState(() {
          _documentos[tipo] = documento;
          // Guardar la relación nombre -> tipo para futuras cargas
          _documentoTipoMap[nombreSrv] = tipo;
        });
        
        debugPrint('[MisDocumentosScreen] 📤 Documento guardado localmente');
        debugPrint('[MisDocumentosScreen] 📤 Relación guardada: $nombreSrv -> $tipo');
        
        if (progreso == 1.0) _confettiController.play();

        _mostrarAlertaExito(tipo, documento);

        //! Refrescar lista desde API para asegurar persistencia y estados
        debugPrint('[MisDocumentosScreen] 📤 Refrescando documentos desde API...');
        await _cargarDocumentosDesdeAPI();
        debugPrint('[MisDocumentosScreen] 📤 Proceso de subida completado');
      } else {
        debugPrint('[MisDocumentosScreen] ❌ Usuario canceló la selección de archivo');
      }
    } catch (e) {
      debugPrint('[MisDocumentosScreen] ❌ Error en _seleccionarDocumento: $e');
      if (!mounted) return;
      _mostrarAlertaError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editarDocumento(String tipo) async {
    //* Reaprovecha el flujo de selección para reemplazarlo
    await _seleccionarDocumento(tipo);
  }

  void _eliminarDocumento(String tipo) async {
    //* Nota: Aquí eliminamos SOLO en la app.
    //* Si tienes un endpoint para borrar en el servidor, podrías llamarlo aquí.
    setState(() => _documentos[tipo] = null);
    _mostrarAlertaEliminacion(tipo);
  }

  void _mostrarVistaPreviaDialog(DocumentoItem documento) {
    if (_vistaPreviaAbierta) return;
    _vistaPreviaAbierta = true;

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
              //* Header minimalista
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
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: textSecondary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),

              //* Contenido del PDF (si ruta es URL la renderiza por red)
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
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
                                horizontal: 8,
                                vertical: 4,
                              ),
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

              //* Información del documento
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildDocumentInfo(
                      'Formato',
                      documento.extension.toUpperCase(),
                      Icons.insert_drive_file,
                    ),
                    const SizedBox(width: 20),
                    _buildDocumentInfo(
                      'Tamaño',
                      _formatFileSize(documento.tamano),
                      Icons.storage,
                    ),
                    const SizedBox(width: 20),
                    _buildDocumentInfo(
                      'Subido',
                      _formatDate(documento.fechaSubida),
                      Icons.schedule,
                    ),
                  ],
                ),
              ),

              //* Acciones rápidas en la vista previa
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMinimalButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _editarDocumento(
                              _tipoDesdeNombre(documento.nombre));
                        },
                        icon: Icons.edit_outlined,
                        label: 'Reemplazar',
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ).then((_) {
      _vistaPreviaAbierta = false;
    });
  }

  //* Dado un nombre de archivo, intenta inferir su tipo en nuestra lista
  String _tipoDesdeNombre(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('ine')) return 'INE';
    if (n.contains('nacimiento')) return 'Acta de Nacimiento';
    if (n.contains('curp')) return 'CURP';
    if (n.contains('domicilio') || n.contains('comprobante')) {
      return 'Comprobante Domicilio';
    }
    if (n.contains('matrimonio')) return 'Acta de Matrimonio';
    if (n.contains('concubinato')) return 'Acta de Concubinato';
    //! fallback: el primero requerido
    return _documentosRequeridos.first;
  }

  //* Hoja inferior con opciones Ver / Editar / Eliminar
  void _mostrarOpcionesDocumento(String tipo, DocumentoItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading:
                      const Icon(Icons.visibility_outlined, color: govBlue),
                  title: const Text('Ver documento'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarVistaPreviaDialog(item);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: govBlue),
                  title: const Text('Reemplazar (editar)'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _editarDocumento(tipo);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: errorColor),
                  title: const Text('Eliminar'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final ok = await _confirmar(
                      title: 'Eliminar documento',
                      message:
                          '¿Seguro que deseas eliminar “${item.nombre}” de $tipo en esta app?',
                    );
                    if (ok == true) {
                      _eliminarDocumento(tipo);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmar({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
  }

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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
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
            : Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
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
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : textSecondary,
                  size: 16,
                ),
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
                        colors: [successColor, Color(0xFF10B981)],
                      ),
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
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'El documento se ha guardado correctamente.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
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
                        colors: [errorColor, Color(0xFFEF4444)],
                      ),
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
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _obtenerMensajeError(error),
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
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

  void _mostrarAlertaEliminacion(String tipo) {
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
                        colors: [textSecondary, Color(0xFF9CA3AF)],
                      ),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Documento eliminado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Puedes volver a cargarlo cuando sea necesario.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
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
            onTap: item != null ? () => _mostrarVistaPreviaDialog(item) : null,
            onLongPress: item != null
                ? () => _mostrarOpcionesDocumento(tipo, item)
                : null,
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
                      //* Icono del documento
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

                      //* Información del documento
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

                            //* Estado
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
                              if (item.ruta.startsWith('http')) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.ruta,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ]
                            ],
                          ],
                        ),
                      ),

                      //* Botones de acción
                      if (item == null && !estaBloquedo)
                        _buildActionButton(
                          icon: Icons.add_rounded,
                          color: govBlue,
                          onPressed: () => _seleccionarDocumento(tipo),
                        )
                      else if (item != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionButton(
                              icon: Icons.more_horiz_rounded,
                              color: govBlue,
                              onPressed: () =>
                                  _mostrarOpcionesDocumento(tipo, item),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              icon: Icons.refresh_rounded,
                              color: govBlueLight,
                              onPressed: () => _editarDocumento(tipo),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            _buildActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: errorColor,
                              onPressed: () => _eliminarDocumento(tipo),
                              size: 18,
                            ),
                          ],
                        ),
                    ],
                  ),

                  //* Información adicional
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
                          const Icon(
                            Icons.visibility_outlined,
                            color: successColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Toca para ver vista previa',
                              style: TextStyle(
                                fontSize: 12,
                                color: successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: successColor.withOpacity(0.7),
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],

                  //* Mensaje de bloqueo
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
                          const Icon(
                            Icons.info_outline_rounded,
                            color: errorColor,
                            size: 14,
                          ),
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
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          child: Center(
            child: Icon(icon, color: color, size: size),
          ),
        ),
      ),
    );
  }

  //* Banner header widget - Sin círculo de progreso
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
            //* Title
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

            //* Subtitle
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

            //* Estadísticas de documentos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
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

  @override
  Widget build(BuildContext context) {
    //* Cálculo dinámico de documentos subidos
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

    //* Cálculo del total necesario
    int calcularTotalEsperado(Map<String, DocumentoItem?> docs) {
      final matrimonioSubido = docs['Acta de Matrimonio'] != null;
      final concubinatoSubido = docs['Acta de Concubinato'] != null;
      int total = _documentosRequeridos.length;

      if (matrimonioSubido || concubinatoSubido) {
        total -= 1;
      }

      return total;
    }

    final docsSubidos = calcularDocumentosSubidos(_documentos);
    final totalDocs = calcularTotalEsperado(_documentos);
    final prog = totalDocs == 0 ? 0.0 : docsSubidos / totalDocs;

    return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildBannerHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    if (docsSubidos == 0)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: govBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.folder_open_rounded,
                                  color: govBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No tienes documentos cargados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Agrega tus documentos tocando el botón + en cada sección.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
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
            ],
          ),
        ),
        floatingActionButton: prog >= 1.0
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

//* Pantalla de visualización de PDF mejorada
class _PDFViewerScreen extends StatefulWidget {
  final DocumentoItem documento;

  const _PDFViewerScreen({required this.documento});

  @override
  State<_PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<_PDFViewerScreen> {
  static const govBlue = Color(0xFF0B3B60);
  late PdfViewerController _pdfViewerController;
  int _currentPageNumber = 1;
  int _totalPages = 0;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: govBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documento.nombre,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Página $_currentPageNumber de $_totalPages',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
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
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: govBlue, strokeWidth: 2.5),
                    SizedBox(height: 16),
                    Text(
                      'Cargando documento...',
                      style: TextStyle(
                        color: govBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
