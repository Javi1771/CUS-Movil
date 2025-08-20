import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/secretaria.dart';
import 'secretaria_detalle_screen.dart';

// OPTIMIZACIÓN: Constantes movidas fuera de la clase State para que no se reinicialicen.
const Map<String, IconData> _secretariaIcons = {
  'Secretaría Particular': Icons.perm_contact_calendar_rounded,
  'Secretaría de Gobierno': Icons.assured_workload_rounded,
  'Secretaría de Administración': Icons.admin_panel_settings_rounded,
  'Secretaría de Seguridad Pública': Icons.security_rounded,
  'Secretaría de Desarrollo Social': Icons.diversity_3,
  'Secretaría de la Mujer': Icons.woman_rounded,
  'Secretaría del Ayuntamiento': Icons.location_city_rounded,
  'Secretaría de Desarrollo Integral': Icons.hub_rounded,
  'Secretaría de Desarrollo Agropecuario': Icons.agriculture_rounded,
  'Órgano Interno de Control': Icons.list_alt_rounded,
};

const List<IconData> _uniqueIcons = [
  Icons.volunteer_activism_rounded,
  Icons.engineering_rounded,
  Icons.shield_rounded,
  Icons.savings_rounded,
  Icons.menu_book_rounded,
  Icons.medical_services_rounded,
  Icons.forest_rounded,
  Icons.landscape_rounded,
  Icons.business_center_rounded,
  Icons.theater_comedy_rounded,
  Icons.fitness_center_rounded,
  Icons.handyman_rounded,
  Icons.groups_rounded,
  Icons.woman_rounded,
  Icons.agriculture_rounded,
  Icons.computer_rounded,
  Icons.home_work_rounded,
  Icons.architecture_rounded,
  Icons.gavel_rounded,
  Icons.local_library_rounded,
  Icons.science_rounded,
  Icons.restaurant_rounded,
  Icons.pets_rounded,
];

class SecretariasScreen extends StatefulWidget {
  const SecretariasScreen({super.key});

  @override
  State<SecretariasScreen> createState() => _SecretariasScreenState();
}

class _SecretariasScreenState extends State<SecretariasScreen> {
  List<Secretaria> secretarias = [];
  List<Secretaria> secretariasFiltradas = [];
  String filtroTexto = '';
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSecretarias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSecretarias() async {
    // Simulación de carga
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      secretarias = SecretariasData.getSecretariasEjemplo();
      secretariasFiltradas = secretarias;
      isLoading = false;
    });
  }

  void _filtrarSecretarias(String query) {
    // OPTIMIZACIÓN: Se convierte el query a minúsculas una sola vez.
    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      filtroTexto = query;
      if (query.isEmpty) {
        secretariasFiltradas = secretarias;
      } else {
        secretariasFiltradas = secretarias.where((secretaria) {
          final nombre = secretaria.nombre.toLowerCase();
          final descripcion = secretaria.descripcion.toLowerCase();
          final servicios = secretaria.servicios
              .any((s) => s.toLowerCase().contains(lowerCaseQuery));

          return nombre.contains(lowerCaseQuery) ||
              descripcion.contains(lowerCaseQuery) ||
              servicios;
        }).toList();
      }
    });
  }

  IconData _getIconForSecretaria(String nombre, int index) {
    for (String key in _secretariaIcons.keys) {
      if (nombre.toLowerCase().contains(key.toLowerCase().split(' ').last)) {
        return _secretariaIcons[key]!;
      }
    }
    return _uniqueIcons[index % _uniqueIcons.length];
  }

  // OPTIMIZACIÓN: Método simplificado, ya que siempre retorna lo mismo.
  List<Color> _getCardColors() {
    return [const Color(0xFF0F96E8), const Color(0xFF0377C6)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildBannerHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: isLoading
                        ? _buildLoadingState()
                        : secretariasFiltradas.isEmpty
                            ? _buildEmptyState()
                            : _buildColorfulGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0B3B60),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
        child: Column(
          children: [
            const Text(
              "Secretarías",
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
              "Municipio de San Juan del Río",
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
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                "${secretarias.length} secretarías disponibles",
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar secretaría...',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF94A3B8), size: 20),
          suffixIcon: filtroTexto.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _filtrarSecretarias('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        onChanged: _filtrarSecretarias,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF0F96E8),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando secretarías...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: secretariasFiltradas.length,
        itemBuilder: (context, index) {
          final secretaria = secretariasFiltradas[index];
          final colors = _getCardColors();
          final icon = _getIconForSecretaria(secretaria.nombre, index);
          return _buildColorfulCard(secretaria, colors, icon);
        },
      ),
    );
  }

  Widget _buildColorfulCard(
      Secretaria secretaria, List<Color> colors, IconData icon) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SecretariaDetalleScreen(secretaria: secretaria),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                left: -10,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              secretaria.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${secretaria.servicios.length} servicios',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0F96E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF0F96E8),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No se encontraron secretarías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              _filtrarSecretarias('');
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Mostrar todas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F96E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
