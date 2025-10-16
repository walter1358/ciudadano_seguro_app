import 'package:cloud_firestore/cloud_firestore.dart';

// Nuevo modelo de datos para incidente
class Incident {
  final String id;
  final String tipoIncidente;
  final String direccion;
  final DateTime fecha;
  final String nivel;
  final String distrito;
  final String userId;
  final String estado;
  final double? latitude; // Para el mapa
  final double? longitude; // Para el mapa

  Incident({
    required this.id,
    required this.tipoIncidente,
    required this.direccion,
    required this.fecha,
    required this.nivel,
    required this.distrito,
    required this.userId,
    required this.estado,
    this.latitude,
    this.longitude,
  });

  factory Incident.fromMap(Map<String, dynamic> data, String id) {
    return Incident(
      id: id,
      tipoIncidente: data['tipo_incidente'] ?? 'Desconocido',
      direccion: data['direccion'] ?? 'Sin dirección',
      // Convertir Timestamp a DateTime
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nivel: data['nivel'] ?? 'Bajo',
      distrito: data['distrito'] ?? '',
      userId: data['usuario_id'] ?? '',
      estado: data['estado'] ?? 'pendiente',
      latitude: data['latitude'] as double?,
      longitude: data['longitude'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo_incidente': tipoIncidente,
      'direccion': direccion,
      'fecha': FieldValue.serverTimestamp(), // Usar serverTimestamp al guardar
      'nivel': nivel,
      'distrito': distrito,
      'usuario_id': userId,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
      'tiene_coordenadas': latitude != null && longitude != null, // NUEVO
    };
  }
}
