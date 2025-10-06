import 'package:flutter/material.dart';
import 'dart:async'; // Necesario para usar Timer

// 1. Convertimos a StatefulWidget para manejar el estado de la alerta y la animación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 2. Variable de estado para controlar la visibilidad de los detalles.
  bool _isSosActivated = false;
  // Variable de estado para controlar la animación del pulso del botón
  bool _isPulsing = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    // 3. Inicializar el timer del pulso al cargar la pantalla.
    _startPulsingAnimation();
  }

  @override
  void dispose() {
    // 4. Asegurarse de cancelar el timer cuando el widget se destruye.
    _pulseTimer?.cancel();
    super.dispose();
  }

  // Función para iniciar la animación de aureola parpadeante
  void _startPulsingAnimation() {
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          // Cambia el estado del pulso para alternar la sombra
          _isPulsing = !_isPulsing;
        });
      }
    });
  }

  // Función que se ejecuta al presionar el botón SOS
  void _onSosPressed() {
    if (!_isSosActivated) {
      // Si la alerta se activa por primera vez
      setState(() {
        _isSosActivated = true;
      });
      // Detiene la animación de pulso cuando se activa el SOS para mantener el estado de "Alerta Activada"
      _pulseTimer?.cancel();
    }
    debugPrint("¡Alerta SOS enviada! (SOS Activated: $_isSosActivated)");
    // Lógica real de envío de alerta o reenvío aquí
  }

  // Widget auxiliar para construir las líneas de detalle debajo del botón SOS
  Widget _buildAlertDetail(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ocupa el menor espacio posible
        children: [
          // Usamos Icons.location_on, Icons.call y Icons.person_add para mejor referencia visual
          Icon(
            text.contains("Llamada")
                ? Icons.call_end
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

  @override
  Widget build(BuildContext context) {
    // Definimos el color y el tamaño de la sombra que parpadea
    final Color pulseColor = Colors.red.withOpacity(0.8);
    final double pulseSpreadRadius = _isPulsing && !_isSosActivated
        ? 15.0
        : 8.0;

    // Usamos Scaffold para tener la estructura básica de una pantalla (barra, cuerpo, etc.)
    return Scaffold(
      body: SafeArea(
        // SingleChildScrollView permite que la pantalla sea desplazable si el contenido es muy largo.
        child: SingleChildScrollView(
          child: Column(
            // Alineamos todos los elementos del Column al centro horizontalmente
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Cabecera (Buenas tardes Ciudadano Seguro)
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
                    // Ícono de campana (Notificaciones)
                    Icon(Icons.notifications_none, color: Colors.red, size: 28),
                  ],
                ),
              ),

              // 2. Contenedor de Nivel de Riesgo (Verde)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    30,
                    130,
                    120,
                  ), // Color verde oscuro/teal
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
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
                    SizedBox(height: 4),
                    Text(
                      "Bajo",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Zona relativamente segura en este momento.",
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Actualizado: 5:47:49 p. m.",
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),

              // 3. Título de Emergencia
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

              // 4. Botón de Emergencia (SOS) con animación de aureola
              // Usamos un Builder para aplicar la sombra animada al botón
              Builder(
                builder: (context) {
                  // Creamos la sombra pulsante
                  final List<BoxShadow> pulseShadow = [
                    BoxShadow(
                      color: pulseColor,
                      blurRadius: 15.0,
                      spreadRadius:
                          pulseSpreadRadius, // Esto cambia con _isPulsing
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
                      boxShadow: _isSosActivated
                          ? null // Sin pulso si ya está activado
                          : pulseShadow,
                      border: Border.all(
                        color: _isSosActivated
                            ? Colors.grey.shade400
                            : Colors.red.shade900, // Borde interior rojo oscuro
                        width: 5,
                      ),
                    ),
                    child: ElevatedButton(
                      // Estilo para hacerlo un círculo grande de color rojo con sombra
                      style: ElevatedButton.styleFrom(
                        // El color de fondo es fijo, la aureola es la sombra del AnimatedContainer
                        backgroundColor: Colors.red.shade600,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(65), // Tamaño del círculo
                        elevation: 0, // Quitamos la elevación del botón interno
                      ),
                      onPressed: _onSosPressed, // Llama a la nueva función
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSosActivated
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          const Text(
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
                },
              ),
              const SizedBox(height: 30),

              // 5. Detalles de la Alerta: Usamos Visibility para controlar cuándo se muestran.
              Visibility(
                visible: _isSosActivated,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildAlertDetail(
                        "Llamada automática a 911",
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/*
// Puedes añadir este widget para previsualizar HomeScreen en el main.dart
import 'package:flutter/material.dart';
import 'package:tu_proyecto/home_screen.dart'; // Asegúrate de ajustar el path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ciudadano Seguro Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto', // Puedes cambiar la fuente si lo deseas
      ),
      home: const HomeScreen(),
    );
  }
}
*/
