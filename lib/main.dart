import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const CiudadanoSeguroApp());
}

class CiudadanoSeguroApp extends StatefulWidget {
  const CiudadanoSeguroApp({super.key});

  // This widget is the root of your application.
  @override
  State<CiudadanoSeguroApp> createState() => _CiudadanoSeguroAppState();
}

class _CiudadanoSeguroAppState extends State<CiudadanoSeguroApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    EmergencyScreen(),
    AnalysisScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ciudadano Seguro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Inicio"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning),
              label: "Emergencia",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Análisis",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),
      ),
    );
  }
}
