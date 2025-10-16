import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Desconectar cualquier sesión previa de Google Sign-In
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el login
        throw Exception('Login cancelado por el usuario');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Verificar que tenemos los tokens necesarios
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Error obteniendo credenciales de Google');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Verificar que el usuario existe
      if (userCredential.user == null) {
        throw Exception('Error al obtener información del usuario');
      }

      print('Login exitoso: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Cerrar sesión de Google en caso de error
      await _googleSignIn.signOut();

      // Manejar errores específicos de Firebase
      print('FirebaseAuthException: ${e.code} - ${e.message}');

      if (e.code == 'user-disabled') {
        throw Exception('Esta cuenta ha sido deshabilitada');
      } else if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Ya existe una cuenta con este correo');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error de autenticación: ${e.message ?? e.code}');
      }
    } catch (e) {
      // Cerrar sesión de Google en caso de error
      await _googleSignIn.signOut();

      print('Error en signInWithGoogle: $e');

      // Si es una excepción ya lanzada, re-lanzarla
      if (e.toString().contains('cancelado') ||
          e.toString().contains('deshabilitada') ||
          e.toString().contains('credenciales')) {
        rethrow;
      }

      throw Exception('Error al iniciar sesión. Por favor, intenta de nuevo.');
    }
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Obtener nombre del usuario
  String getUserName() {
    final name = currentUser?.displayName ?? "Usuario";
    print('getUserName: $name');
    return name;
  }

  // Obtener email del usuario
  String getUserEmail() {
    final email = currentUser?.email ?? "";
    print('getUserEmail: $email');
    return email;
  }

  // Obtener foto de perfil
  String? getUserPhotoUrl() {
    return currentUser?.photoURL;
  }
}
