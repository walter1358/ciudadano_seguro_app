import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firestore_service.dart';
import '../models/incident.dart'; // Asegúrate de tener tu modelo importado

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  final FirestoreService _firestoreService = FirestoreService();

  // Marcadores manuales
  final LatLng _center = const LatLng(-12.0464, -77.0428); // Lima, Perú
  final LatLng _zonaSegura = const LatLng(-12.1211, -77.0290); // Miraflores
  final LatLng _barrio5Esquinas = const LatLng(
    -12.051759248294209,
    -77.02456426783024,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Obtiene la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 16.0),
      ),
    );
  }

  /// Genera marcadores manuales + de Firestore
  Set<Marker> _createIncidentMarkers(List<Incident> incidents) {
    Set<Marker> markers = {
      // Marcadores fijos
      Marker(
        markerId: const MarkerId('center_risk'),
        position: _center,
        infoWindow: const InfoWindow(title: 'Zona de alto riesgo - Lima'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      Marker(
        markerId: const MarkerId('zona_segura_1'),
        position: _zonaSegura,
        infoWindow: const InfoWindow(title: 'Zona segura - Miraflores'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('barrio_risk'),
        position: _barrio5Esquinas,
        infoWindow: const InfoWindow(title: 'Zona de alto riesgo - 5 Esquinas'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Agregar marcadores dinámicos desde Firestore
    for (var incident in incidents) {
      if (incident.latitude != null && incident.longitude != null) {
        final markerHue = incident.nivel == 'Alto'
            ? BitmapDescriptor.hueRed
            : incident.nivel == 'Medio'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueYellow;

        markers.add(
          Marker(
            markerId: MarkerId('incident_${incident.id}'),
            position: LatLng(incident.latitude!, incident.longitude!),
            infoWindow: InfoWindow(
              title: incident.tipoIncidente,
              snippet: '${incident.direccion} (${incident.nivel})',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Seguridad")),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Incident>>(
              stream: _firestoreService.incidentsWithCoordsStream(),
              builder: (context, snapshot) {
                Set<Marker> allMarkers = _createIncidentMarkers(
                  snapshot.data ?? [],
                );

                return GoogleMap(
                  onMapCreated: (controller) => _controller = controller,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 16.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: allMarkers,
                );
              },
            ),
    );
  }
}
