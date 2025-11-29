import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: "assets/.env");
  runApp(const CiudadanoSeguroApp());
}

class CiudadanoSeguroApp extends StatefulWidget {
  const CiudadanoSeguroApp({super.key});

  @override
  State<CiudadanoSeguroApp> createState() => _CiudadanoSeguroAppState();
}

class _CiudadanoSeguroAppState extends State<CiudadanoSeguroApp> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogin() async {
    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        throw Exception('No se pudo completar el inicio de sesión');
      }

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      // Re-lanzar la excepción para que LoginScreen la maneje
      rethrow;
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      _selectedIndex = 0;
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
      home: StreamBuilder(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si NO hay usuario logueado
          if (!snapshot.hasData || snapshot.data == null) {
            return LoginScreen(onLogin: _handleLogin);
          }

          // Usuario logueado - Mostrar app principal
          final userName = _authService.getUserName();
          final userEmail = _authService.getUserEmail();
          final userPhoto = _authService.getUserPhotoUrl();

          final List<Widget> screens = [
            HomeScreen(userName: userName),
            const MapScreen(),
            const EmergencyScreen(),
            //const AnalysisScreen(),
            ProfileScreen(
              onLogout: _handleLogout,
              userName: userName,
              userEmail: userEmail,
              userPhotoUrl: userPhoto,
            ),
          ];

          return Scaffold(
            body: screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.redAccent,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.shield),
                  label: "Inicio",
                ),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: "Mapa"),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: "Emergencia",
                ),
                /*BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Análisis",
                ),*/
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Perfil",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
