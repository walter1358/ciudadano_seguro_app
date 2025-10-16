import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late GenerativeModel _model;
  late ChatSession _chat;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // 🧠 Inicializa el modelo Gemini y carga la API Key
  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    print('🔑 GEMINI_API_KEY: $apiKey');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        "No se encontró la clave GEMINI_API_KEY en el archivo .env",
      );
    }

    // Usa el modelo Gemini más reciente
    _model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: apiKey);
    _chat = _model.startChat();
  }

  // 🚨 Analiza el texto para identificar el tipo de emergencia
  String _detectarTipoEmergencia(String mensaje) {
    mensaje = mensaje.toLowerCase();
    if (mensaje.contains("robo") ||
        mensaje.contains("asalto") ||
        mensaje.contains("violencia")) {
      return "asalto";
    } else if (mensaje.contains("incendio") ||
        mensaje.contains("fuego") ||
        mensaje.contains("humo")) {
      return "incendio";
    } else if (mensaje.contains("accidente") ||
        mensaje.contains("choque") ||
        mensaje.contains("herido")) {
      return "accidente";
    }
    return "otro";
  }

  // 📡 Envía el mensaje del usuario a la IA, obtiene ubicación y responde
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "Tú", "text": text});
    });

    final tipo = _detectarTipoEmergencia(text);
    print("🚨 Tipo detectado: $tipo");

    try {
      // ✅ Solicita permiso de ubicación
      var permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 📍 Obtiene ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String ubicacion =
          "Lat: ${position.latitude}, Lon: ${position.longitude}";

      // 🧠 Prompt que se envía a Gemini
      final prompt = """
Eres un asistente virtual de emergencias.
Tipo de emergencia: $tipo
Ubicación del usuario: $ubicacion

Mensaje del usuario: "$text"

Tu tarea:
- Da instrucciones claras y rápidas.
- Sugiere llamar al número de emergencia correspondiente:
  - Policía (105) si es robo o violencia.
  - Bomberos (116) si es incendio.
  - SAMU (106) si hay heridos o accidente.
Responde de forma empática y breve.
""";

      // 💬 Envía a la IA
      final response = await _chat.sendMessage(Content.text(prompt));

      setState(() {
        _messages.add({
          "sender": "IA",
          "text": response.text ?? "No hubo respuesta de la IA",
        });
      });

      // ☎️ Sugerir llamada según el tipo
      if (tipo == "asalto" || tipo == "violencia") {
        _mostrarBotonLlamada("105", "Policía Nacional del Perú");
      } else if (tipo == "incendio") {
        _mostrarBotonLlamada("116", "Bomberos");
      } else if (tipo == "accidente") {
        _mostrarBotonLlamada("106", "SAMU");
      }
    } catch (e) {
      print("⚠️ Error de conexión o ubicación: $e");
      setState(() {
        _messages.add({
          "sender": "IA",
          "text":
              "Ocurrió un error al contactar con la IA o al obtener tu ubicación.",
        });
      });
    }
  }

  // 📞 Agrega un mensaje con un botón para realizar la llamada
  void _mostrarBotonLlamada(String numero, String servicio) {
    setState(() {
      _messages.add({
        "sender": "IA",
        "text":
            "¿Deseas comunicarte con $servicio? Pulsa el botón para llamar al $numero.",
      });
    });
  }

  Future<void> _llamarEmergencia(String numero) async {
    final Uri url = Uri.parse("tel:$numero");
    print("📞 Intentando abrir marcador con: $url");

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalNonBrowserApplication, // 👈 clave para Xiaomi
      );

      print("🚀 launchUrl ejecutado: $launched");

      if (!launched) {
        print("⚠️ No se pudo abrir el marcador. Intentando con telprompt...");
        // 🔁 Fallback con telprompt
        final fallbackUrl = Uri.parse("telprompt:$numero");
        final fallback = await launchUrl(
          fallbackUrl,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        print("📱 Fallback ejecutado: $fallback");
      }
    } catch (e, st) {
      print("💥 Error al intentar abrir el marcador: $e");
      print(st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistente de Emergencias")),
      body: Column(
        children: [
          // 💬 Zona del chat
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == "Tú";

                // 🎨 Mensaje con estilo tipo burbuja
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.redAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: msg['text']!.contains("105") ||
                            msg['text']!.contains("116") ||
                            msg['text']!.contains("106")
                        ? Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text']!,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final numero = msg['text']!.contains("105")
                                      ? "105"
                                      : msg['text']!.contains("116")
                                          ? "116"
                                          : "106";
                                  await _llamarEmergencia(numero);
                                },
                                icon: const Icon(Icons.call),
                                label: const Text("Llamar ahora"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            msg['text']!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 📥 Caja de texto para escribir
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: "Escribe tu emergencia..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.redAccent),
                  onPressed: () {
                    final text = _controller.text;
                    _controller.clear();
                    _sendMessage(text);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
