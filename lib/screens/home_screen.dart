import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timeago/timeago.dart' as timeago;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/report_incident_screen.dart';
import '../models/incident.dart';

// --- Constantes de Colores ---
const Color redDanger = Color(0xFFDC3545);
const Color blueInfo = Color(0xFF007AFF);
const Color greenSuccess = Color(0xFF198754);
const Color primaryTeal = Color.fromARGB(255, 30, 130, 120);

// Colores para niveles de riesgo
const Color riskSafe = Color(0xFF198754); // Verde
const Color riskLow = Color(0xFFFFC107); // Amarillo
const Color riskMedium = Color(0xFFFF9800); // Naranja
const Color riskHigh = Color(0xFFDC3545); // Rojo

class RiskLevel {
  final String label;
  final Color color;
  final String description;
  final DateTime updatedAt;

  RiskLevel({
    required this.label,
    required this.color,
    required this.description,
    required this.updatedAt,
  });
}

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final WhatsAppService _whatsappService = WhatsAppService();
  bool _isSosActivated = false;
  Position? _currentPosition;
  RiskLevel? _currentRiskLevel;
  bool _isLoadingRisk = false;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _calculateRiskLevelIfNeeded();
  }

  Future<void> _calculateRiskLevelIfNeeded() async {
    if (_currentRiskLevel != null && _lastUpdate != null) {
      final difference = DateTime.now().difference(_lastUpdate!);
      if (difference.inMinutes < 5) {
        return;
      }
    }
    await _calculateRiskLevel();
  }

  Future<void> _calculateRiskLevel() async {
    if (!mounted) return;
    setState(() => _isLoadingRisk = true);

    try {
      final position = await _getCurrentPosition();
      if (!mounted) return;

      if (position == null) {
        if (!mounted) return;
        setState(() {
          _currentRiskLevel = RiskLevel(
            label: 'Sin Ubicación',
            color: Colors.grey,
            description: 'Activa tu ubicación para ver el nivel de riesgo.',
            updatedAt: DateTime.now(),
          );
          _isLoadingRisk = false;
          _lastUpdate = DateTime.now();
        });
        return;
      }

      if (!mounted) return;
      setState(() => _currentPosition = position);

      final incidents = await _firestoreService.getIncidentsWithCoords();
      if (!mounted) return;

      const double radiusInMeters = 1000; // ⭐ AJUSTA EL RADIO AQUÍ (en metros)
      final nearbyIncidents = incidents.where((incident) {
        if (incident.latitude == null || incident.longitude == null) {
          return false;
        }
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          incident.latitude!,
          incident.longitude!,
        );
        return distance <= radiusInMeters;
      }).toList();

      final riskLevel = _determineRiskLevel(nearbyIncidents);

      if (!mounted) return;
      setState(() {
        _currentRiskLevel = riskLevel;
        _isLoadingRisk = false;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      print('Error calculando nivel de riesgo: $e');
      if (!mounted) return;
      setState(() {
        _currentRiskLevel = RiskLevel(
          label: 'Error',
          color: Colors.grey,
          description: 'No se pudo calcular el nivel de riesgo.',
          updatedAt: DateTime.now(),
        );
        _isLoadingRisk = false;
        _lastUpdate = DateTime.now();
      });
    }
  }

  RiskLevel _determineRiskLevel(List<Incident> nearbyIncidents) {
    if (nearbyIncidents.isEmpty) {
      return RiskLevel(
        label: 'Sin Incidentes',
        color: riskSafe,
        description: 'No hay incidentes reportados en tu zona.',
        updatedAt: DateTime.now(),
      );
    }

    int lowCount = 0;
    int mediumCount = 0;
    int highCount = 0;

    for (var incident in nearbyIncidents) {
      switch (incident.nivel.toLowerCase()) {
        case 'bajo':
          lowCount++;
          break;
        case 'medio':
          mediumCount++;
          break;
        case 'alto':
          highCount++;
          break;
      }
    }

    if (highCount > 0 && highCount >= mediumCount && highCount >= lowCount) {
      return RiskLevel(
        label: 'Alto',
        color: riskHigh,
        description:
            'Se han reportado $highCount incidente(s) de alto riesgo en tu zona.',
        updatedAt: DateTime.now(),
      );
    } else if (mediumCount > 0 && mediumCount >= lowCount) {
      return RiskLevel(
        label: 'Medio',
        color: riskMedium,
        description:
            'Se han reportado $mediumCount incidente(s) de riesgo medio en tu zona.',
        updatedAt: DateTime.now(),
      );
    } else if (lowCount > 0) {
      return RiskLevel(
        label: 'Bajo',
        color: riskLow,
        description:
            'Se han reportado $lowCount incidente(s) de bajo riesgo en tu zona.',
        updatedAt: DateTime.now(),
      );
    }

    return RiskLevel(
      label: 'Sin Incidentes',
      color: riskSafe,
      description: 'No hay incidentes reportados en tu zona.',
      updatedAt: DateTime.now(),
    );
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  // ⭐ FUNCIÓN SOS CON WHATSAPP BUSINESS API
  void _onSosPressed() async {
    if (_isSosActivated) return;

    setState(() {
      _isSosActivated = true;
    });

    debugPrint("¡Alerta SOS activada!");

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Enviando alertas de emergencia...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }

    try {
      // 1. Obtener ubicación actual
      Position? position = _currentPosition;
      if (position == null) {
        position = await _getCurrentPosition();
      }

      // 2. Obtener contacto de emergencia
      final emergencyContact = await _firestoreService.getEmergencyContact();

      if (emergencyContact.phone.isEmpty) {
        if (mounted) {
          _showNoContactDialog();
        }
        return;
      }

      // 3. Preparar datos
      final userName = widget.userName;
      //emergencyContact.name.isNotEmpty ? emergencyContact.name : 'Usuario';

      final locationUrl = position != null
          ? 'https://www.google.com/maps?q=${position.latitude},${position.longitude}'
          : 'Ubicación no disponible';

      final timestamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      // 4. Enviar alertas (contacto de emergencia + policía)
      final results = await _whatsappService.sendMultipleAlerts(
        emergencyContactPhone: emergencyContact.phone,
        userName: userName,
        locationUrl: locationUrl,
        timestamp: timestamp,
        sendToPolice: true, // ⭐ Cambiar a false si no quieres enviar a policía
      );

      // 5. Mostrar resultado
      if (mounted) {
        final emergencySuccess = results['emergency_contact'] ?? false;
        final policeSuccess = results['police'] ?? false;

        if (emergencySuccess && policeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('✅ Alertas enviadas a contacto de emergencia y policía'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (emergencySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✅ Alerta enviada a contacto de emergencia\n⚠️ Error al enviar a policía'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('❌ Error al enviar alertas. Verifica tu configuración.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _isSosActivated = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error en SOS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isSosActivated = false;
        });
      }
    }
  }

  void _showNoContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Sin Contacto de Emergencia'),
        content: const Text(
          'No has configurado un contacto de emergencia.\n\n'
          'Ve a tu Perfil y agrega un contacto para usar esta función.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isSosActivated = false;
              });
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _navigateToReportIncident() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportIncidentScreen(),
      ),
    );
    if (result == true) {
      _calculateRiskLevel();
    }
  }

  Widget _buildAlertDetail(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            text.contains("WhatsApp")
                ? Icons.phone
                : text.contains("Ubicación")
                    ? Icons.location_on
                    : Icons.person_pin_circle,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
          child: Text(
            "Acciones Rápidas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                icon: Icons.notifications_active_outlined,
                label: "Reportar Incidente",
                color: redDanger,
                onTap: _navigateToReportIncident,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIncidentItem(Incident incident) {
    IconData icon;
    Color iconColor;

    switch (incident.tipoIncidente) {
      case 'Robo':
        icon = Icons.local_police_outlined;
        iconColor = Colors.orange.shade700;
        break;
      case 'Accidente':
        icon = Icons.car_crash_outlined;
        iconColor = Colors.blue.shade700;
        break;
      case 'Homicidio':
        icon = Icons.person_off_outlined;
        iconColor = Colors.black;
        break;
      case 'Actividad Sospechosa':
        icon = Icons.visibility_outlined;
        iconColor = Colors.purple.shade700;
        break;
      case 'Disturbio':
      default:
        icon = Icons.campaign_outlined;
        iconColor = Colors.red.shade700;
        break;
    }

    final timeAgo = timeago.format(incident.fecha, locale: 'es');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.tipoIncidente,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF495057),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${incident.direccion} (${incident.distrito})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          height: 40,
          thickness: 1,
          color: Color(0xFFF1F1F1),
          indent: 16,
          endIndent: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0, top: 10.0, bottom: 10.0),
          child: Text(
            "Incidentes Recientes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StreamBuilder<List<Incident>>(
            stream: _firestoreService.recentIncidentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        textAlign: TextAlign.center));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No hay incidentes recientes.'),
                  ),
                );
              }

              final incidents = snapshot.data!;
              return Column(
                children: incidents
                    .map((incident) => _buildRecentIncidentItem(incident))
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelCard() {
    if (_isLoadingRisk) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final riskLevel = _currentRiskLevel ??
        RiskLevel(
          label: 'Desconocido',
          color: Colors.grey,
          description: 'No se pudo determinar el nivel de riesgo.',
          updatedAt: DateTime.now(),
        );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskLevel.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    "Nivel de Riesgo",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _calculateRiskLevel,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            riskLevel.label,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            riskLevel.description,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            "Actualizado: ${TimeOfDay.fromDateTime(riskLevel.updatedAt).format(context)}",
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Buenas tardes",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          "Ciudadano Seguro",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.notifications_none, color: Colors.red, size: 28),
                  ],
                ),
              ),
              _buildRiskLevelCard(),
              const SizedBox(height: 16),
              const Text(
                "Emergencia",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isSosActivated
                    ? "Alerta Activada. Ayuda en camino."
                    : "Presiona en caso de emergencia inmediata",
                style: TextStyle(
                  color: _isSosActivated ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              PulsingSosButton(
                isActivated: _isSosActivated,
                onPressed: _onSosPressed,
              ),
              const SizedBox(height: 30),
              Visibility(
                visible: _isSosActivated,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildAlertDetail(
                        "Mensaje enviado por WhatsApp",
                        Colors.red.shade600,
                      ),
                      _buildAlertDetail(
                        "Ubicación compartida",
                        Colors.red.shade600,
                      ),
                      _buildAlertDetail(
                        "Contacto de emergencia notificado",
                        Colors.red.shade600,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSosActivated = false;
                          });
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Cancelar Alerta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: !_isSosActivated,
                child: _buildQuickActionsGrid(),
              ),
              Visibility(
                visible: !_isSosActivated,
                child: _buildCurrentStatusSection(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class PulsingSosButton extends StatefulWidget {
  final bool isActivated;
  final VoidCallback onPressed;

  const PulsingSosButton({
    super.key,
    required this.isActivated,
    required this.onPressed,
  });

  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton> {
  bool _isPulsing = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _startPulsingAnimation();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _startPulsingAnimation() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted && !widget.isActivated) {
        setState(() {
          _isPulsing = !_isPulsing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color pulseColor = Colors.red.withOpacity(0.8);
    final double pulseSpreadRadius =
        _isPulsing && !widget.isActivated ? 15.0 : 8.0;

    final List<BoxShadow> pulseShadow = [
      BoxShadow(
        color: pulseColor,
        blurRadius: 15.0,
        spreadRadius: pulseSpreadRadius,
      ),
      BoxShadow(
        color: Colors.red.withOpacity(0.6),
        blurRadius: 10.0,
        spreadRadius: 5.0,
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: widget.isActivated ? null : pulseShadow,
        border: Border.all(
          color:
              widget.isActivated ? Colors.grey.shade400 : Colors.red.shade900,
          width: 5,
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(65),
          elevation: 0,
        ),
        onPressed: widget.onPressed,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              "SOS",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
