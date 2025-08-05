import 'package:cus_movil/widgets/alert_helper.dart';
import 'package:flutter/material.dart';
import 'package:cus_movil/models/weather_data.dart';
import 'package:cus_movil/services/weather_service.dart';

class WeatherCard extends StatefulWidget {
  final WeatherData? weatherData;
  final bool isLoading;
  final VoidCallback onRefresh;
  final double? latitude;
  final double? longitude;

  const WeatherCard({
    super.key,
    required this.weatherData,
    required this.isLoading,
    required this.onRefresh,
    this.latitude,
    this.longitude,
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showWeatherDetails() {
    if (widget.weatherData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeatherDetailsModal(
        weatherData: widget.weatherData!,
        onRefresh: widget.onRefresh,
      ),
    );
  }

  void _showWeeklyForecast() {
    debugPrint(
        '[WeatherCard] _showWeeklyForecast lat=${widget.latitude} lon=${widget.longitude}');
    if (widget.latitude == null || widget.longitude == null) {
      AlertHelper.showAlert(
        'Esperando ubicación para pronóstico semanal',
        type: AlertType.warning,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeeklyForecastModal(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
      ),
    );
  }

  Widget _buildShimmerEffect({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthNames = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];

    final color = widget.weatherData?.weatherColor ?? const Color(0xFF667eea);
    final gradient = widget.weatherData?.weatherGradient ??
        [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
        ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          //* Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          //* Main content con Material para InkWell funcionando bien
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  //? 1) Zona clicable para detalles del clima
                  Expanded(
                    child: InkWell(
                      onTap: _showWeatherDetails,
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        children: [
                          //* Icono animado
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: widget.isLoading
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  width: 65,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 600),
                                    switchInCurve: Curves.elasticOut,
                                    child: widget.isLoading
                                        ? _buildShimmerEffect(
                                            child: const SizedBox(
                                              key: ValueKey('loading'),
                                              width: 32,
                                              height: 32,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            widget.weatherData?.weatherIcon ??
                                                Icons.wb_sunny_rounded,
                                            key: ValueKey(
                                                'weather_${widget.weatherData?.conditionCode ?? 'default'}'),
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(width: 20),

                          //? Info del clima (temp, descripción, métricas rápidas)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          widget.weatherData
                                                  ?.temperatureString ??
                                              '--°',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w300,
                                            height: 0.9,
                                            shadows: [
                                              Shadow(
                                                  blurRadius: 3,
                                                  color: Colors.black26,
                                                  offset: Offset(1, 1)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    if (widget.weatherData?.feelsLike != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Se sienten ${widget.weatherData!.feelsLike!.round()}°',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.weatherData?.capitalizedDescription ??
                                      'Cargando clima...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildQuickMetric(Icons.opacity,
                                        '${widget.weatherData?.humidity ?? '--'}%'),
                                    const SizedBox(width: 16),
                                    _buildQuickMetric(Icons.air,
                                        '${widget.weatherData?.windSpeed.round() ?? '--'} km/h'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  //? 2) Zona clicable para pronóstico semanal
                  InkWell(
                    onTap: _showWeeklyForecast,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 55,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 22,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                monthNames[now.month - 1],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${now.day}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildQuickMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

//* Weather Details Modal
class WeatherDetailsModal extends StatelessWidget {
  final WeatherData weatherData;
  final VoidCallback onRefresh;

  const WeatherDetailsModal({
    super.key,
    required this.weatherData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = weatherData.weatherGradient;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              //* Handle bar
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              //* Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalles del Clima Actual',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      //* Main weather info
                      Container(
                        //? 1) Le damos todo el ancho posible
                        width: double.infinity,

                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, //* Centrar contenido
                          children: [
                            Icon(
                              weatherData.weatherIcon,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              weatherData.temperatureString,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              weatherData.capitalizedDescription,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      //* Weather metrics grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 11.0;
                          final availableWidth = constraints.maxWidth;
                          //* Calcula ancho para dos columnas con espacio intermedio
                          final itemWidth = (availableWidth - spacing) / 2;
                          //* Relación ancho/alto = 1.3 
                          const aspectRatio = 1.3;

                          final metrics = <Widget>[
                            _buildDetailMetric(Icons.opacity, 'Humedad', '${weatherData.humidity}%'),
                            _buildDetailMetric(Icons.air, 'Viento', '${weatherData.windSpeed.round()} km/h'),
                            if (weatherData.feelsLike != null)
                              _buildDetailMetric(Icons.thermostat, 'Sensación Térmica', '${weatherData.feelsLike!.round()}°C'),
                            if (weatherData.pressure != null)
                              _buildDetailMetric(Icons.speed, 'Presión', '${weatherData.pressure!.round()} hPa'),
                            if (weatherData.uvIndex != null)
                              _buildDetailMetric(Icons.light_mode, 'Índice UV', '${weatherData.uvIndex}'),
                            if (weatherData.cloudCover != null)
                              _buildDetailMetric(Icons.cloud, 'Nubosidad', '${weatherData.cloudCover}%'),
                            if (weatherData.dewPoint != null)
                              _buildDetailMetric(Icons.water_drop, 'Punto de Rocío', '${weatherData.dewPoint!.round()}°C'),
                          ];

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: metrics.map((metric) {
                              return SizedBox(
                                width: itemWidth,
                                //* AspectRatio hace que la altura nunca exceda el cálculo
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: metric,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),


                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailMetric(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//* Weekly Forecast Modal
class WeeklyForecastModal extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeeklyForecastModal({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeeklyForecastModal> createState() => _WeeklyForecastModalState();
}

class _WeeklyForecastModalState extends State<WeeklyForecastModal> {
  List<dynamic>? forecastData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final forecast = await WeatherService.getWeeklyForecast(
        lat: widget.latitude,
        lon: widget.longitude,
        days: 7,
      );

      setState(() {
        forecastData = forecast;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B3B60),
                Color.fromARGB(255, 5, 165, 174),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              //* Handle bar
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              //* Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pronóstico Semanal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadForecast,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.white, size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Error al cargar el pronóstico',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error!,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: forecastData?.length ?? 0,
                            itemBuilder: (context, index) {
                              final day = forecastData![index];
                              return _buildForecastDay(day, index);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForecastDay(dynamic dayData, int index) {
    //? 1) Parseo de la fecha
    final disp = dayData['displayDate'] as Map<String, dynamic>;
    final date = DateTime(
      disp['year'] as int,
      disp['month'] as int,
      disp['day'] as int,
    );
    final dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final dayName = index == 0 ? 'Hoy' : dayNames[date.weekday % 7];

    //? 2) Temperaturas
    final maxTemp =
        (dayData['maxTemperature']?['degrees'] as num?)?.round() ?? 0;
    final minTemp =
        (dayData['minTemperature']?['degrees'] as num?)?.round() ?? 0;

    //? 3) Condición diurna
    final daytime = dayData['daytimeForecast'] as Map<String, dynamic>;
    final cond = daytime['weatherCondition'] as Map<String, dynamic>;
    final description =
        (cond['description'] as Map<String, dynamic>)['text'] as String? ?? '…';
    final type = cond['type'] as String? ?? '';

    //? 4) Icono según tu modelo
    final iconData = WeatherData(
      city: '',
      temperature: 0,
      description: '',
      conditionCode: type,
      humidity: 0,
      windSpeed: 0,
    ).weatherIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(iconData, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          //* Aquí mostramos max/min con iconos y grados
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '$maxTemp°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_downward,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '$minTemp°',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
