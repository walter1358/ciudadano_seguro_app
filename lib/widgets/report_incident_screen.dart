import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Para ubicación opcional
import '../services/firestore_service.dart';
import '../models/incident.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  // Valores del formulario
  String? _selectedType;
  String _address = '';
  String? _selectedLevel = 'Bajo'; // Default: Bajo
  String _district = '';
  bool _isLocating = false;

  // Opciones predeterminadas
  List<String> _incidentTypes = [
    'Robo',
    'Accidente',
    'Disturbio',
    'Actividad Sospechosa',
    'Homicidio',
    'Otro'
  ];
  final List<String> _incidentLevels = ['Bajo', 'Medio', 'Alto'];

  // Propiedades para geolocalización
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _loadIncidentTypes();
  }

  Future<void> _loadIncidentTypes() async {
    final types = await _firestoreService.getIncidentTypes();
    setState(() {
      _incidentTypes = types;
      if (!_incidentTypes.contains(_selectedType)) {
        _selectedType = null;
      }
    });
  }

  // Intenta obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Manejar el caso de permiso denegado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de ubicación denegado.')),
            );
          }
          setState(() {
            _isLocating = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        // Opcional: Usar geocoding para obtener la dirección (no implementado aquí)
        _address = 'Ubicación actual (Lat: ${_currentLat!.toStringAsFixed(4)})';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación obtenida.')),
        );
      }
    } catch (e) {
      print('Error al obtener ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación.')),
        );
      }
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate() &&
        _selectedType != null &&
        _selectedLevel != null) {
      _formKey.currentState!.save();

      // Intenta obtener el distrito de la dirección, si es necesario.

      final newIncident = Incident(
        id: '', // Se generará en Firestore
        tipoIncidente: _selectedType!,
        direccion: _address,
        fecha: DateTime.now(),
        nivel: _selectedLevel!,
        distrito: _district.isNotEmpty ? _district : 'Desconocido',
        userId: _firestoreService.currentUserId!,
        estado: 'pendiente',
        latitude: _currentLat, // Coordenadas opcionales
        longitude: _currentLng, // Coordenadas opcionales
      );

      try {
        await _firestoreService.saveIncident(newIncident);
        if (mounted) {
          Navigator.pop(context, true); // Retorna 'true' para indicar éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Incidente reportado con éxito!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al guardar incidente.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Incidente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Tipo de Incidente
              const Text('Tipo de Incidente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  hintText: 'Selecciona el tipo',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                items: _incidentTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Nivel de Incidente
              const Text('Nivel de Incidente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              DropdownButtonFormField<String>(
                value: _selectedLevel,
                decoration: const InputDecoration(
                  hintText: 'Selecciona el nivel',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                items: _incidentLevels.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLevel = newValue;
                  });
                },
                validator: (value) => value == null ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 20),

              // Dirección
              const Text('Dirección del Incidente',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextFormField(
                initialValue: _address,
                decoration: const InputDecoration(
                  labelText: 'Ej: Av. Principal 123',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _address = value ?? '',
                validator: (value) =>
                    value!.isEmpty ? 'La dirección es obligatoria' : null,
              ),
              const SizedBox(height: 10),

              // Botón para usar ubicación actual
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_isLocating
                      ? 'Obteniendo Ubicación...'
                      : 'Usar Ubicación Actual (con Coordenadas)'),
                ),
              ),
              const SizedBox(height: 20),

              // Distrito
              const Text('Distrito',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ej: Miraflores',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _district = value ?? '',
                validator: (value) =>
                    value!.isEmpty ? 'El distrito es obligatorio' : null,
              ),
              const SizedBox(height: 30),

              // Botón de Guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Reportar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
