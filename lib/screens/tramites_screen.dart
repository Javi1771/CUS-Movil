import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/tramites_service.dart';

class TramitesScreen extends StatefulWidget {
  const TramitesScreen({super.key});

  @override
  State<TramitesScreen> createState() => _TramitesScreenState();
}

class _TramitesScreenState extends State<TramitesScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<TramiteEstado> _tramites = [];
  Map<String, int> _estadisticas = {};
  String _filtroEstado = 'TODOS';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;
  late AnimationController _animationController;

  final List<String> _estadosDisponibles = [
    'TODOS',
    'POR REVISAR',
    'FIRMADO',
    'RECHAZADO',
    'CORREGIR',
    'REQUIERE PAGO',
    'ENVIADO PARA FIRMAR',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _fetchTramites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTramites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[TramitesScreen] Iniciando carga de trámites...');

      final response = await TramitesService.getTramitesEstados();
      final estadisticas = await TramitesService.getEstadisticasTramites();

      debugPrint('[TramitesScreen] Trámites cargados: ${response.data.length}');

      setState(() {
        _tramites = response.data;
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[TramitesScreen] Error al cargar trámites: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TramiteEstado> get _tramitesFiltrados {
    var tramitesFiltrados = _tramites;

    // Filtrar por estado
    if (_filtroEstado != 'TODOS') {
      tramitesFiltrados = tramitesFiltrados
          .where(
              (tramite) => tramite.nombreEstado.toUpperCase() == _filtroEstado)
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      tramitesFiltrados = tramitesFiltrados.where((tramite) {
        final query = _searchQuery.toLowerCase();
        return tramite.nombreTramite.toLowerCase().contains(query) ||
            tramite.folio.toLowerCase().contains(query) ||
            tramite.nombreDependencia.toLowerCase().contains(query) ||
            tramite.nombreEstado.toLowerCase().contains(query);
      }).toList();
    }

    return tramitesFiltrados;
  }

  String _getResultsText() {
    final totalTramites = _tramites.length;
    final tramitesFiltrados = _tramitesFiltrados.length;

    if (_searchQuery.isNotEmpty || _filtroEstado != 'TODOS') {
      return '$tramitesFiltrados de $totalTramites trámites';
    } else {
      return '$totalTramites trámites encontrados';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _error != null ? _buildErrorView() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B3B60),
            Color(0xFF0E4A75),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            children: [
              // Header con información perfectamente centrada
              SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    // Botón refrescar posicionado a la derecha
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: 44,
                        child: IconButton(
                          onPressed: _fetchTramites,
                          icon: AnimatedRotation(
                            turns: _isLoading ? 1 : 0,
                            duration: const Duration(seconds: 1),
                            child: const Icon(Icons.refresh,
                                color: Colors.white, size: 18),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),

                    // Contenido centrado sin interferencia de botones
                    Positioned.fill(
                      left: 44,
                      right: 44,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Mis Trámites",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Flexible(
                              child: Text(
                                _getResultsText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tabs centrados con ancho fijo
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 80,
                  ),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSimpleTab(
                            index: 0,
                            title: "Lista",
                            isSelected: _selectedTabIndex == 0,
                          ),
                        ),
                        Expanded(
                          child: _buildSimpleTab(
                            index: 1,
                            title: "Estadísticas",
                            isSelected: _selectedTabIndex == 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child:
          _selectedTabIndex == 0 ? _buildTramitesList() : _buildEstadisticas(),
    );
  }

  Widget _buildTramitesList() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildNotificacionesImportantes(),
        Expanded(
          child: _tramitesFiltrados.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: _buildEmptyState(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: _tramitesFiltrados.length,
                  itemBuilder: (context, index) {
                    if (index >= _tramitesFiltrados.length) {
                      return const SizedBox.shrink();
                    }
                    final tramite = _tramitesFiltrados[index];
                    return _buildTramiteCard(tramite);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          // Barra de búsqueda expandida
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, folio, dependencia...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Botón de filtros
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showFilterBottomSheet,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.tune,
                        color: _filtroEstado != 'TODOS'
                            ? const Color(0xFF0B3B60)
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                      // Indicador de filtro activo
                      if (_filtroEstado != 'TODOS')
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B3B60),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionesImportantes() {
    // Alerta removida - ya no se muestra la notificación naranja
    return const SizedBox.shrink();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B3B60).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Color(0xFF0B3B60),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filtrar Trámites',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de filtros
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _estadosDisponibles.length,
                itemBuilder: (context, index) {
                  final estado = _estadosDisponibles[index];
                  final count = estado == 'TODOS'
                      ? _tramites.length
                      : _estadisticas[estado] ?? 0;
                  final color = _getEstadoColor(estado);
                  final isSelected = _filtroEstado == estado;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color.withOpacity(0.3)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getEstadoIcon(estado),
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        estado == 'TODOS' ? 'Todos los estados' : estado,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? color : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.1),
                              color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _filtroEstado = estado;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _filtroEstado = 'TODOS';
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar filtros'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B3B60),
                        side: const BorderSide(color: Color(0xFF0B3B60)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B3B60),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'TODOS':
        return const Color(0xFF0B3B60);
      case 'POR REVISAR':
        return const Color(0xFFFAA21B);
      case 'FIRMADO':
        return const Color(0xFF00AE6F);
      case 'RECHAZADO':
        return const Color(0xFFCE1D81);
      case 'CORREGIR':
        return const Color(0xFFE67425);
      case 'REQUIERE PAGO':
        return const Color(0xFF00B2E2);
      case 'ENVIADO PARA FIRMAR':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toUpperCase()) {
      case 'TODOS':
        return Icons.apps_rounded;
      case 'POR REVISAR':
        return Icons.pending_actions_rounded;
      case 'FIRMADO':
        return Icons.check_circle_rounded;
      case 'RECHAZADO':
        return Icons.cancel_rounded;
      case 'CORREGIR':
        return Icons.edit_rounded;
      case 'REQUIERE PAGO':
        return Icons.payment_rounded;
      case 'ENVIADO PARA FIRMAR':
        return Icons.draw_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildTramiteCard(TramiteEstado tramite) {
    final dateFormatShort = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTramiteDetails(tramite),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del trámite
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tramite.colorEstado.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tramite.colorEstado,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      tramite.iconoEstado,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: _formatTextWithCapitalization(
                              tramite.nombreTramite),
                          decoration: BoxDecoration(
                            color: tramite.colorEstado,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          child: Text(
                            _formatTextWithCapitalization(
                                tramite.nombreTramite),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Folio: ${tramite.folio}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Ver detalles',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tramite.colorEstado,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tramite.nombreEstado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del trámite
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: _formatTextWithCapitalization(
                        tramite.descripcionEstado),
                    decoration: BoxDecoration(
                      color: tramite.colorEstado,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(
                      _formatTextWithCapitalization(tramite.descripcionEstado),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información resumida
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: _formatTextWithCapitalization(
                              tramite.nombreDependencia),
                          decoration: BoxDecoration(
                            color: tramite.colorEstado,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          child: _buildInfoItem(
                            'Dependencia',
                            _formatTextWithCapitalization(
                                tramite.nombreDependencia),
                            Icons.business,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Fecha de Entrada',
                          dateFormatShort.format(tramite.fechaEntrada),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildInfoItem(
                          'Días transcurridos',
                          _calculateDaysElapsed(tramite.fechaEntrada),
                          Icons.schedule,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDaysElapsed(DateTime? fechaEntrada) {
    if (fechaEntrada == null) return 'Sin fecha';

    final now = DateTime.now();
    final difference = now.difference(fechaEntrada).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return '1 día';
    } else {
      return '$difference días';
    }
  }

  String _formatTextWithCapitalization(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showTramiteDetails(TramiteEstado tramite) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tramite.colorEstado.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tramite.colorEstado,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tramite.iconoEstado,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tramite.nombreTramite,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: tramite.colorEstado,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tramite.nombreEstado,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tramite.descripcionEstado,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Detalles
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Información General', [
                      _buildDetailItem(
                          'Folio', tramite.folio, Icons.confirmation_number),
                      _buildDetailItem('Dependencia', tramite.nombreDependencia,
                          Icons.business),
                      _buildDetailItem(
                          'Estado Actual', tramite.nombreEstado, Icons.info),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('Fechas Importantes', [
                      _buildDetailItem('Fecha de Entrada',
                          dateFormat.format(tramite.fechaEntrada), Icons.login),
                      _buildDetailItem(
                          'Última Modificación',
                          dateFormat.format(tramite.ultimaFechaModificacion),
                          Icons.update),
                      if (tramite.fechaSalida != null)
                        _buildDetailItem(
                            'Fecha de Salida',
                            dateFormat.format(tramite.fechaSalida!),
                            Icons.logout),
                      _buildDetailItem(
                          'Días Transcurridos',
                          _calculateDaysElapsed(tramite.fechaEntrada),
                          Icons.schedule),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF0B3B60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
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

  Widget _buildEstadisticas() {
    if (_estadisticas.isEmpty) {
      return const Center(
        child: Text(
          'No hay estadísticas disponibles',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _buildResumenCard(),
        const SizedBox(height: 20),
        _buildEstadisticasCard(),
      ],
    );
  }

  Widget _buildResumenCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3B60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF0B3B60),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Resumen General',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildClickableStatCard(
                  'Total de Trámites',
                  _tramites.length.toString(),
                  Icons.description,
                  const Color(0xFF0B3B60),
                  'TODOS',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildClickableStatCard(
                  'Completados',
                  (_estadisticas['FIRMADO'] ?? 0).toString(),
                  Icons.check_circle,
                  const Color(0xFF00AE6F),
                  'FIRMADO',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildClickableStatCard(
                  'En Proceso',
                  (_estadisticas['POR REVISAR'] ?? 0).toString(),
                  Icons.pending_actions,
                  const Color(0xFFFAA21B),
                  'POR REVISAR',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildClickableStatCard(
                  'Rechazados',
                  (_estadisticas['RECHAZADO'] ?? 0).toString(),
                  Icons.cancel,
                  const Color(0xFFCE1D81),
                  'RECHAZADO',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatCard(
      String title, String value, IconData icon, Color color, String estado) {
    return GestureDetector(
      onTap: () {
        _showTramitesList(title, estado, color, icon);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Icon(
              Icons.visibility,
              color: color.withOpacity(0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showTramitesList(
      String title, String estado, Color color, IconData icon) {
    List<TramiteEstado> tramitesFiltrados;

    if (estado == 'TODOS') {
      tramitesFiltrados = _tramites;
    } else {
      tramitesFiltrados = _tramites
          .where((tramite) => tramite.nombreEstado.toUpperCase() == estado)
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tramitesFiltrados.length} trámite${tramitesFiltrados.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de trámites
            Expanded(
              child: tramitesFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay trámites en esta categoría',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: tramitesFiltrados.length,
                      itemBuilder: (context, index) {
                        final tramite = tramitesFiltrados[index];
                        return _buildCompactTramiteCard(tramite);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTramiteCard(TramiteEstado tramite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tramite.colorEstado.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tramite.colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  tramite.iconoEstado,
                  color: tramite.colorEstado,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message:
                          _formatTextWithCapitalization(tramite.nombreTramite),
                      decoration: BoxDecoration(
                        color: tramite.colorEstado,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      child: Text(
                        _formatTextWithCapitalization(tramite.nombreTramite),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Folio: ${tramite.folio}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tramite.colorEstado,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tramite.nombreEstado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: _formatTextWithCapitalization(tramite.descripcionEstado),
            decoration: BoxDecoration(
              color: tramite.colorEstado,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            child: Text(
              _formatTextWithCapitalization(tramite.descripcionEstado),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3B60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Color(0xFF0B3B60),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detalle por Estado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._estadisticas.entries.map((entry) {
            final estado = entry.key;
            final count = entry.value;
            final percentage =
                (_tramites.isNotEmpty) ? (count / _tramites.length * 100) : 0.0;

            // Crear un TramiteEstado temporal para obtener color e icono
            final tempTramite = TramiteEstado(
              idCentralTram: 0,
              idCatalogoTramite: 0,
              idDependencia: 0,
              idTramite: 0,
              idSolicitante: 0,
              idEstado: 0,
              fechaEntrada: DateTime.now(),
              folio: '',
              fechaCreacion: DateTime.now(),
              ultimaFechaModificacion: DateTime.now(),
              nombreTramite: '',
              nombreDependencia: '',
              nombreEstado: estado,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tempTramite.colorEstado,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      tempTramite.iconoEstado,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                estado,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$count (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: tempTramite.colorEstado,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tempTramite.colorEstado,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'No se encontraron resultados';
      subtitle = 'No hay trámites que coincidan con "$_searchQuery"';
      icon = Icons.search_off;
    } else if (_filtroEstado != 'TODOS') {
      title = 'No hay trámites disponibles';
      subtitle = 'No hay trámites con el estado "$_filtroEstado"';
      icon = Icons.filter_list_off;
    } else {
      title = 'No hay trámites disponibles';
      subtitle = 'No tienes trámites registrados';
      icon = Icons.description_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _filtroEstado != 'TODOS') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filtroEstado = 'TODOS';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3B60),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(0xFFCE1D81).withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar trámites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFCE1D81).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFCE1D81).withOpacity(0.3)),
              ),
              child: Text(
                _error ?? 'Ha ocurrido un error inesperado',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFCE1D81),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fetchTramites,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B3B60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showDiagnostics,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Diagnóstico'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B3B60),
                      side: const BorderSide(color: Color(0xFF0B3B60)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Obteniendo información de diagnóstico...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Por favor espera...'),
          ],
        ),
      ),
    );

    try {
      final diagnostics = await TramitesService.getDiagnosticInfo();

      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Información de Diagnóstico'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDiagnosticItem('Usuario autenticado',
                      diagnostics['user_authenticated']?.toString() ?? 'No'),
                  _buildDiagnosticItem('ID de usuario',
                      diagnostics['user_id']?.toString() ?? 'No encontrado'),
                  _buildDiagnosticItem('Servidor accesible',
                      diagnostics['server_reachable']?.toString() ?? 'No'),
                  _buildDiagnosticItem('URL de API',
                      diagnostics['api_url']?.toString() ?? 'No configurada'),
                  _buildDiagnosticItem('API configurada',
                      diagnostics['api_configured']?.toString() ?? 'No'),
                  if (diagnostics['error'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${diagnostics['error']}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de carga
        AlertHelper.showAlert(
          'Error al obtener diagnóstico: $e',
          type: AlertType.error,
        );
      }
    }
  }

  Widget _buildDiagnosticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTab({
    required int index,
    required String title,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0B3B60)
                  : Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
