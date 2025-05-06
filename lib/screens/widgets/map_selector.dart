// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelector extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const MapSelector({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapSelector> createState() => _MapSelectorState();
}

class _MapSelectorState extends State<MapSelector> {
  GoogleMapController? _controller;
  MapType _currentMapType = MapType.normal;

  @override
  void didUpdateWidget(MapSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation &&
        _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(widget.initialLocation!),
      );
    }
  }

  void _centerMap() {
    if (_controller != null && widget.initialLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.initialLocation!, 17),
      );
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : _currentMapType == MapType.satellite
              ? MapType.hybrid
              : _currentMapType == MapType.hybrid
                  ? MapType.terrain
                  : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade900.withOpacity(0.5)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation ?? const LatLng(19.4326, -99.1332),
              zoom: 14,
            ),
            onMapCreated: (controller) => _controller = controller,
            onTap: widget.onLocationSelected,
            markers: widget.initialLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('ubicacion'),
                      position: widget.initialLocation!,
                    ),
                  },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            mapType: _currentMapType,
          ),
        ),
        if (widget.initialLocation != null)
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "centerMapBtn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _centerMap,
                  tooltip: 'Centrar en ubicación',
                  elevation: 4,
                  child: const Icon(Icons.center_focus_strong, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "mapTypeToggleBtn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _toggleMapType,
                  tooltip: 'Cambiar tipo de mapa',
                  elevation: 4,
                  child: const Icon(Icons.layers, color: Colors.blue),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
