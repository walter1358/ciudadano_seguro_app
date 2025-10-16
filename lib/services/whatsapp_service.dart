import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhatsAppService {
  // ⭐ CONFIGURA ESTOS VALORES EN TU ARCHIVO .env
  final String _apiUrl = dotenv.env['WHATSAPP_API_URL'] ?? '';
  final String _accessToken = dotenv.env['WHATSAPP_TOKEN'] ?? '';
  final String _policiaPhone = dotenv.env['POLICIA_PHONE'] ?? '51999999999';

  // Nombre de tu plantilla en Meta Business
  final String _templateName = 'alerta_panico';

  /// Envía alerta de pánico a contacto de emergencia
  Future<bool> sendPanicAlert({
    required String recipientPhone,
    required String userName,
    required String locationUrl,
    String? timestamp,
  }) async {
    try {
      // Limpiar número
      String cleanPhone = recipientPhone.replaceAll(RegExp(r'[^\d]'), '');
      if (!cleanPhone.startsWith('51')) {
        cleanPhone = '51$cleanPhone'; // Agregar código de país Perú
      }

      print('📱 Enviando alerta a: $cleanPhone');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': cleanPhone,
          'type': 'template',
          'template': {
            'name': _templateName,
            'language': {
              'code': 'es_PE', // Español
            },
            'components': [
              {
                'type': 'body',
                'parameters': timestamp != null
                    ? [
                        {
                          'type': 'text',
                          "parameter_name": "nombre",
                          'text': userName
                        },
                        {
                          'type': 'text',
                          "parameter_name": "ubicacion",
                          'text': locationUrl
                        },
                        {
                          'type': 'text',
                          "parameter_name": "hora",
                          'text': timestamp
                        },
                      ]
                    : [
                        {
                          'type': 'text',
                          "parameter_name": "nombre",
                          'text': userName
                        },
                        {
                          'type': 'text',
                          "parameter_name": "ubicacion",
                          'text': locationUrl
                        },
                      ],
              }
            ],
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Mensaje enviado exitosamente');
        print('Response: ${response.body}');
        return true;
      } else {
        print('❌ Error al enviar mensaje: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción al enviar mensaje: $e');
      return false;
    }
  }

  /// Envía alerta a la policía
  Future<bool> sendAlertToPolice({
    required String userName,
    required String locationUrl,
    String? timestamp,
  }) async {
    return await sendPanicAlert(
      recipientPhone: _policiaPhone,
      userName: userName,
      locationUrl: locationUrl,
      timestamp: timestamp,
    );
  }

  /// Envía alertas a múltiples destinatarios
  Future<Map<String, bool>> sendMultipleAlerts({
    required String emergencyContactPhone,
    required String userName,
    required String locationUrl,
    String? timestamp,
    bool sendToPolice = true,
  }) async {
    final results = <String, bool>{};

    // Enviar a contacto de emergencia
    print('📤 Enviando a contacto de emergencia...');
    results['emergency_contact'] = await sendPanicAlert(
      recipientPhone: emergencyContactPhone,
      userName: userName,
      locationUrl: locationUrl,
      timestamp: timestamp,
    );

    // Enviar a policía
    if (sendToPolice) {
      print('📤 Enviando a policía...');
      results['police'] = await sendAlertToPolice(
        userName: userName,
        locationUrl: locationUrl,
        timestamp: timestamp,
      );
    }

    return results;
  }
}
