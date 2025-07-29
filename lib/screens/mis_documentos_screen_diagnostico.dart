// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
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

  final Map<String, String> _imagenesDocumentos = {
    'INE': 'assets/ine.png',
    'Acta de Nacimiento': 'assets/Acta_nacimiento.png',
    'CURP': 'assets/Curp.png',
    'Comprobante Domicilio': 'assets/Comprobante_domicilio.png',
    'Acta de Matrimonio': 'assets/Acta_matrimonio.png',
    'Acta de Concubinato': 'assets/Acta_concubinato.png',
  };

  bool _isLoading = false;
  bool _vistaPreviaAbierta = false;
  late ConfettiController _confettiController;
  String _diagnosticoInfo = '';

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
    setState(() {
      _isLoading = true;
      _diagnosticoInfo = 'Iniciando carga de documentos...';
    });
    
    try {
      print('[DIAGNOSTICO] 🔍 Iniciando carga de documentos del servidor municipal...');
      
      // Intentar obtener documentos
      final docs = await UserDataService.getUserDocuments();
      
      print('[DIAGNOSTICO] 🔍 Respuesta recibida: ${docs.length} documentos');
      
      setState(() {
        _diagnosticoInfo = 'Documentos recibidos del servidor: ${docs.length}';
      });
      
      // Mostrar información detallada de cada documento
      List<String> detallesDocumentos = [];
      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        print('[DIAGNOSTICO] 🔍 Documento ${i + 1}:');
        print('[DIAGNOSTICO] 🔍   - Nombre: "${doc.nombreDocumento}"');
        print('[DIAGNOSTICO] 🔍   - URL: "${doc.urlDocumento}"');
        print('[DIAGNOSTICO] ���   - Fecha: "${doc.uploadDate}"');
        print('[DIAGNOSTICO] 🔍   - URL válida: ${doc.urlDocumento.startsWith('http')}');
        
        detallesDocumentos.add('${i + 1}. ${doc.nombreDocumento}');
        detallesDocumentos.add('   URL: ${doc.urlDocumento.isEmpty ? "VACÍA" : "OK"}');
        detallesDocumentos.add('   Válida: ${doc.urlDocumento.startsWith('http') ? "SÍ" : "NO"}');
      }
      
      setState(() {
        _diagnosticoInfo = 'Documentos encontrados: ${docs.length}\n\n${detallesDocumentos.join('\n')}';
      });
      
      // Mostrar notificación al usuario
      if (mounted) {
        if (docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${docs.length} documentos encontrados'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ No se encontraron documentos'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Procesar y mapear cada documento
      int documentosMapeados = 0;
      List<String> procesamientoLog = [];
      
      for (final doc in docs) {
        String nombreApi = doc.nombreDocumento.toLowerCase();
        String? key;
        
        print('[DIAGNOSTICO] 🔍 Procesando: "$nombreApi"');
        procesamientoLog.add('Procesando: "$nombreApi"');
        
        // Mapeo de documentos
        if (nombreApi.contains('ine') || 
            nombreApi.contains('credencial') || 
            nombreApi.contains('identificacion')) {
          key = 'INE';
        } else if (nombreApi.contains('nacimiento') || 
                   nombreApi.contains('birth')) {
          key = 'Acta de Nacimiento';
        } else if (nombreApi.contains('curp')) {
          key = 'CURP';
        } else if (nombreApi.contains('domicilio') || 
                   nombreApi.contains('comprobante') || 
                   nombreApi.contains('address')) {
          key = 'Comprobante Domicilio';
        } else if (nombreApi.contains('matrimonio') || 
                   nombreApi.contains('marriage')) {
          key = 'Acta de Matrimonio';
        } else if (nombreApi.contains('concubinato') || 
                   nombreApi.contains('concubinage')) {
          key = 'Acta de Concubinato';
        }
        
        print('[DIAGNOSTICO] 🔍 Mapeado a: ${key ?? "NO MAPEADO"}');
        procesamientoLog.add('  → Mapeado a: ${key ?? "NO MAPEADO"}');
        
        if (key != null && _documentos.containsKey(key)) {
          // Validar URL
          if (doc.urlDocumento.isNotEmpty && doc.urlDocumento.startsWith('http')) {
            _documentos[key] = DocumentoItem(
              nombre: doc.nombreDocumento,
              ruta: doc.urlDocumento,
              fechaSubida: DateTime.tryParse(doc.uploadDate ?? '') ?? DateTime.now(),
              tamano: 0,
              extension: 'pdf',
            );
            documentosMapeados++;
            print('[DIAGNOSTICO] 🔍 ✅ Asignado correctamente a $key');
            procesamientoLog.add('  ✅ Asignado correctamente');
          } else {
            print('[DIAGNOSTICO] 🔍 ❌ URL inválida: "${doc.urlDocumento}"');
            procesamientoLog.add('  ❌ URL inválida');
          }
        } else {
          print('[DIAGNOSTICO] 🔍 ❌ No se pudo mapear');
          procesamientoLog.add('  ❌ No se pudo mapear');
        }
      }
      
      // Actualizar diagnóstico con procesamiento
      setState(() {
        _diagnosticoInfo += '\n\nProcesamiento:\n${procesamientoLog.join('\n')}';
      });
      
      // Mostrar resumen final
      final documentosCargados = _documentos.values.where((doc) => doc != null).length;
      print('[DIAGNOSTICO] 🔍 🎯 RESUMEN FINAL:');
      print('[DIAGNOSTICO] 🔍   - Documentos recibidos: ${docs.length}');
      print('[DIAGNOSTICO] 🔍   - Documentos mapeados: $documentosMapeados');
      print('[DIAGNOSTICO] 🔍   - Documentos cargados en UI: $documentosCargados');
      
      // Estado de cada tipo
      List<String> estadoFinal = [];
      _documentos.forEach((tipo, documento) {
        final estado = documento != null ? "✅ CARGADO" : "❌ NO CARGADO";
        print('[DIAGNOSTICO] 🔍   - $tipo: $estado');
        estadoFinal.add('$tipo: $estado');
      });
      
      setState(() {
        _diagnosticoInfo += '\n\nEstado final:\n${estadoFinal.join('\n')}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📄 $documentosCargados de ${_documentosRequeridos.length} documentos cargados'),
            backgroundColor: documentosCargados > 0 ? Colors.blue : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
    } catch (e) {
      print('[DIAGNOSTICO] 🔍 ❌ ERROR: $e');
      setState(() {
        _diagnosticoInfo = 'ERROR: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _cargarDocumentosDesdeAPI(),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDiagnostico() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diagnóstico de Documentos'),
        content: SingleChildScrollView(
          child: Text(_diagnosticoInfo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cargarDocumentosDesdeAPI();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
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
              // Header
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

              // Contenido del PDF
              Flexible(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      height: 320,
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

              // Botón de cerrar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: govBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cerrar'),
                  ),
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

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Desconocido';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
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
                    error,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: InkWell(
          onTap: item != null ? () => _mostrarVistaPreviaDialog(item) : null,
          borderRadius: BorderRadius.circular(16),
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
                    // Imagen del documento
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          _imagenesDocumentos[tipo] ?? 'assets/ine.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: statusColor.withOpacity(0.1),
                            child: Icon(
                              Icons.description_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Información del documento
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

                          // Estado
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
                          ],
                        ],
                      ),
                    ),

                    // Botones de acción
                    if (item == null && !estaBloquedo)
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        color: govBlue,
                        onPressed: () => _seleccionarDocumento(tipo),
                      )
                    else if (item != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            color: govBlueLight,
                            onPressed: () => _seleccionarDocumento(tipo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: errorColor,
                            onPressed: () => _eliminarDocumento(tipo),
                          ),
                        ],
                      ),
                  ],
                ),

                // Información adicional
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
                    child: const Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: successColor,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Toca para ver vista previa',
                            style: TextStyle(
                              fontSize: 12,
                              color: successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Mensaje de bloqueo
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mis Documentos'),
        backgroundColor: govBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarDiagnostico,
            tooltip: 'Ver diagnóstico',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (documentosSubidos == 0)
                    Container(
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
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Los documentos del servidor aparecerán aquí automáticamente.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _cargarDocumentosDesdeAPI,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Recargar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: govBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _mostrarDiagnostico,
                                  icon: const Icon(Icons.info),
                                  label: const Text('Diagnóstico'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _documentosRequeridos
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final item = _documentos[doc];
                        return _buildDocumentCard(doc, item, index);
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}