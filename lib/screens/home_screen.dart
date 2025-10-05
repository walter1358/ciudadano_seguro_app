import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Buenas tardes\nCiudadano Seguro",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nivel de Riesgo",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Alto",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text("Mantente alerta. Evita salir solo por la noche."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Emergencia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text("Presiona en caso de emergencia inmediata"),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40),
              ),
              onPressed: () {
                // Aquí puedes lanzar una llamada o alerta
              },
              child: const Text(
                "SOS",
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
