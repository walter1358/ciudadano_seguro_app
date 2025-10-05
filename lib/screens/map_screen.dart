import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;

  final LatLng _center = const LatLng(-12.0464, -77.0428); // Lima, Perú

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Seguridad")),
      body: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
        myLocationEnabled: true,
        markers: {
          Marker(
            markerId: const MarkerId('1'),
            position: _center,
            infoWindow: const InfoWindow(title: 'Zona de alto riesgo'),
          ),
        },
      ),
    );
  }
}
