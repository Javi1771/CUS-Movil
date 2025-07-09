// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  LatLng? _markerPosition;

  @override
  void initState() {
    super.initState();
    _markerPosition = widget.initialLocation;
  }

  @override
  void didUpdateWidget(MapSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    //? cuando cambie initialLocation, centramos el mapa
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation &&
        _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(widget.initialLocation!),
      );
      setState(() => _markerPosition = widget.initialLocation);
    }
  }

  void _centerMap() {
    if (_controller != null && _markerPosition != null) {
      _controller!
          .animateCamera(CameraUpdate.newLatLngZoom(_markerPosition!, 17));
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          MapType.values[(_currentMapType.index + 1) % MapType.values.length];
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
            onMapCreated: (c) => _controller = c,
            mapType: _currentMapType,
            zoomControlsEnabled: true,
            myLocationEnabled: true,
            mapToolbarEnabled: true,

            //! deshabilitamos el paneo estándar con un dedo:
            scrollGesturesEnabled: false,
            //? y dejamos sólo zoom y paneo mediante ScaleGestureRecognizer:
            zoomGesturesEnabled: true,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => ScaleGestureRecognizer(),
              ),
            },

            markers: _markerPosition == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('pin'),
                      position: _markerPosition!,
                      draggable: true,
                      onDragEnd: (pos) {
                        setState(() => _markerPosition = pos);
                        widget.onLocationSelected(pos);
                      },
                    ),
                  },

            onTap: (pos) {
              setState(() => _markerPosition = pos);
              widget.onLocationSelected(pos);
            },
          ),
        ),

        //? Botones de centrar y cambiar tipo de mapa
        if (_markerPosition != null)
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'center',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _centerMap,
                  tooltip: 'Centrar',
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'toggle',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _toggleMapType,
                  tooltip: 'Tipo de mapa',
                  child: const Icon(Icons.layers, color: Colors.blue),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
