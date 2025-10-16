/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';
import '../models/personal_info.dart';
import '../models/incident.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener UID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== INCIDENTES ====================

  // Referencia a la colección de incidentes
  CollectionReference get _incidentsCollection =>
      _firestore.collection('incidentes');

  // Referencia a la colección de tipos de incidente (si existiera)
  CollectionReference get _incidentTypesCollection =>
      _firestore.collection('tipos_incidente');

  // 1. Guardar un nuevo incidente
  Future<void> saveIncident(Incident incident) async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _incidentsCollection.add(incident.toMap());
      print('Incidente guardado correctamente');
    } catch (e) {
      print('Error guardando incidente: $e');
      rethrow;
    }
  }

  // 2. Stream para obtener incidentes recientes (últimos 10, ordenados por fecha)
  Stream<List<Incident>> recentIncidentsStream() {
    return _incidentsCollection
        .orderBy('fecha', descending: true)
        .limit(10) // Limitar a los 10 más recientes
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. Stream para obtener TODOS los incidentes con coordenadas (para el mapa)
  Stream<List<Incident>> incidentsWithCoordsStream() {
    return _incidentsCollection
        .where('tiene_coordenadas', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // 4. Obtener tipos de incidente (ejemplo de consulta)
  Future<List<String>> getIncidentTypes() async {
    try {
      final snapshot = await _incidentTypesCollection.get();
      return snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['nombre'] as String? ??
              'Otro')
          .toList();
    } catch (e) {
      print('Error obteniendo tipos de incidente: $e');
      // Devolver una lista por defecto si falla la conexión o no existe la colección
      return [
        'Robo',
        'Accidente',
        'Disturbio',
        'Actividad Sospechosa',
        'Homicidio',
      ];
    }
  }

  // ==================== EMERGENCY CONTACT ====================

  // Referencia al documento del usuario actual para contacto de emergencia
  DocumentReference? get _userDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('emergency_contac').doc(userId);
  }

  // Inicializar datos del usuario al hacer login por primera vez
  Future<void> initializeUserData() async {
    final userId = currentUserId;
    if (userId == null) return;

    final userDoc = _firestore.collection('emergency_contac').doc(userId);
    final docSnapshot = await userDoc.get();

    // Solo crear si no existe
    if (!docSnapshot.exists) {
      final user = _auth.currentUser;
      await userDoc.set({
        'email': user?.email ?? '',
        'name': user?.displayName ?? '',
        'photoUrl': user?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'emergencyContact': {
          'name': '',
          'phone': '',
        },
      });
    }
  }

  // Obtener contacto de emergencia
  Future<EmergencyContact> getEmergencyContact() async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return EmergencyContact.empty();

      final snapshot = await userDoc.get();
      if (!snapshot.exists) return EmergencyContact.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('emergencyContact')) {
        return EmergencyContact.empty();
      }

      final contactData = data['emergencyContact'] as Map<String, dynamic>;
      return EmergencyContact.fromMap(contactData);
    } catch (e) {
      print('Error obteniendo contacto de emergencia: $e');
      return EmergencyContact.empty();
    }
  }

  // Guardar/Actualizar contacto de emergencia
  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar set con merge: true crea el documento si no existe
      // y solo actualiza los campos especificados si ya existe
      await userDoc.set({
        'emergencyContact': contact.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Contacto de emergencia guardado correctamente');
    } catch (e) {
      print('Error guardando contacto de emergencia: $e');
      rethrow;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<EmergencyContact> emergencyContactStream() {
    final userDoc = _userDoc;
    if (userDoc == null) {
      return Stream.value(EmergencyContact.empty());
    }

    return userDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return EmergencyContact.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('emergencyContact')) {
        return EmergencyContact.empty();
      }

      final contactData = data['emergencyContact'] as Map<String, dynamic>;
      return EmergencyContact.fromMap(contactData);
    });
  }

  // ==================== PERSONAL INFORMATION ====================

  // Referencia al documento de información personal del usuario actual
  DocumentReference? get _personalInfoDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('personal_information').doc(userId);
  }

  // Obtener información personal
  Future<PersonalInfo> getPersonalInfo() async {
    try {
      final personalInfoDoc = _personalInfoDoc;
      if (personalInfoDoc == null) return PersonalInfo.empty();

      final snapshot = await personalInfoDoc.get();
      if (!snapshot.exists) return PersonalInfo.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return PersonalInfo.empty();

      return PersonalInfo.fromMap(data);
    } catch (e) {
      print('Error obteniendo información personal: $e');
      return PersonalInfo.empty();
    }
  }

  // Guardar/Actualizar información personal
  Future<void> savePersonalInfo(PersonalInfo info) async {
    try {
      final personalInfoDoc = _personalInfoDoc;
      if (personalInfoDoc == null) {
        throw Exception('Usuario no autenticado');
      }

      final user = _auth.currentUser;

      await personalInfoDoc.set({
        'userId': user?.uid,
        'email': user?.email,
        'address': info.address,
        'phone': info.phone,
        'dni': info.dni,
        'birthDate': info.birthDate,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Información personal guardada correctamente');
    } catch (e) {
      print('Error guardando información personal: $e');
      rethrow;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<PersonalInfo> personalInfoStream() {
    final personalInfoDoc = _personalInfoDoc;
    if (personalInfoDoc == null) {
      return Stream.value(PersonalInfo.empty());
    }

    return personalInfoDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return PersonalInfo.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return PersonalInfo.empty();

      return PersonalInfo.fromMap(data);
    });
  }

  // ==================== USER BASIC INFO ====================

  // Actualizar información básica del usuario
  Future<void> updateUserBasicInfo({
    String? name,
    String? photoUrl,
  }) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await userDoc.update(updateData);
    } catch (e) {
      print('Error actualizando información del usuario: $e');
    }
  }
}
*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';
import '../models/personal_info.dart';
import '../models/incident.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener UID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== INCIDENTES ====================

  // Referencia a la colección de incidentes
  CollectionReference get _incidentsCollection =>
      _firestore.collection('incidentes');

  // Referencia a la colección de tipos de incidente (si existiera)
  CollectionReference get _incidentTypesCollection =>
      _firestore.collection('tipos_incidente');

  // 1. Guardar un nuevo incidente
  Future<void> saveIncident(Incident incident) async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _incidentsCollection.add(incident.toMap());
      print('Incidente guardado correctamente');
    } catch (e) {
      print('Error guardando incidente: $e');
      rethrow;
    }
  }

  // 2. Stream para obtener incidentes recientes (últimos 10, ordenados por fecha)
  Stream<List<Incident>> recentIncidentsStream() {
    return _incidentsCollection
        .orderBy('fecha', descending: true)
        .limit(10) // Limitar a los 10 más recientes
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 3. Stream para obtener TODOS los incidentes con coordenadas (para el mapa)
  Stream<List<Incident>> incidentsWithCoordsStream() {
    return _incidentsCollection
        .where('tiene_coordenadas', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // 4. Obtener tipos de incidente (ejemplo de consulta)
  Future<List<String>> getIncidentTypes() async {
    try {
      final snapshot = await _incidentTypesCollection.get();
      return snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['nombre'] as String? ??
              'Otro')
          .toList();
    } catch (e) {
      print('Error obteniendo tipos de incidente: $e');
      // Devolver una lista por defecto si falla la conexión o no existe la colección
      return [
        'Robo',
        'Accidente',
        'Disturbio',
        'Actividad Sospechosa',
        'Homicidio',
      ];
    }
  }

  // ⭐ NUEVO: Stream para contar incidentes del usuario actual
  Stream<int> userIncidentCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _incidentsCollection
        .where('usuario_id', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ⭐ NUEVO: Obtener lista de incidentes del usuario actual
  Stream<List<Incident>> userIncidentsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _incidentsCollection
        .where('usuario_id', isEqualTo: currentUserId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ==================== EMERGENCY CONTACT ====================

  // Referencia al documento del usuario actual para contacto de emergencia
  DocumentReference? get _userDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('emergency_contac').doc(userId);
  }

  // Inicializar datos del usuario al hacer login por primera vez
  Future<void> initializeUserData() async {
    final userId = currentUserId;
    if (userId == null) return;

    final userDoc = _firestore.collection('emergency_contac').doc(userId);
    final docSnapshot = await userDoc.get();

    // Solo crear si no existe
    if (!docSnapshot.exists) {
      final user = _auth.currentUser;
      await userDoc.set({
        'email': user?.email ?? '',
        'name': user?.displayName ?? '',
        'photoUrl': user?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'emergencyContact': {
          'name': '',
          'phone': '',
        },
      });
    }
  }

  // Obtener contacto de emergencia
  Future<EmergencyContact> getEmergencyContact() async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return EmergencyContact.empty();

      final snapshot = await userDoc.get();
      if (!snapshot.exists) return EmergencyContact.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('emergencyContact')) {
        return EmergencyContact.empty();
      }

      final contactData = data['emergencyContact'] as Map<String, dynamic>;
      return EmergencyContact.fromMap(contactData);
    } catch (e) {
      print('Error obteniendo contacto de emergencia: $e');
      return EmergencyContact.empty();
    }
  }

  // Guardar/Actualizar contacto de emergencia
  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) {
        throw Exception('Usuario no autenticado');
      }

      // Usar set con merge: true crea el documento si no existe
      // y solo actualiza los campos especificados si ya existe
      await userDoc.set({
        'emergencyContact': contact.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Contacto de emergencia guardado correctamente');
    } catch (e) {
      print('Error guardando contacto de emergencia: $e');
      rethrow;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<EmergencyContact> emergencyContactStream() {
    final userDoc = _userDoc;
    if (userDoc == null) {
      return Stream.value(EmergencyContact.empty());
    }

    return userDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return EmergencyContact.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('emergencyContact')) {
        return EmergencyContact.empty();
      }

      final contactData = data['emergencyContact'] as Map<String, dynamic>;
      return EmergencyContact.fromMap(contactData);
    });
  }

  // ==================== PERSONAL INFORMATION ====================

  // Referencia al documento de información personal del usuario actual
  DocumentReference? get _personalInfoDoc {
    final userId = currentUserId;
    if (userId == null) return null;
    return _firestore.collection('personal_information').doc(userId);
  }

  // Obtener información personal
  Future<PersonalInfo> getPersonalInfo() async {
    try {
      final personalInfoDoc = _personalInfoDoc;
      if (personalInfoDoc == null) return PersonalInfo.empty();

      final snapshot = await personalInfoDoc.get();
      if (!snapshot.exists) return PersonalInfo.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return PersonalInfo.empty();

      return PersonalInfo.fromMap(data);
    } catch (e) {
      print('Error obteniendo información personal: $e');
      return PersonalInfo.empty();
    }
  }

  // Guardar/Actualizar información personal
  Future<void> savePersonalInfo(PersonalInfo info) async {
    try {
      final personalInfoDoc = _personalInfoDoc;
      if (personalInfoDoc == null) {
        throw Exception('Usuario no autenticado');
      }

      final user = _auth.currentUser;

      await personalInfoDoc.set({
        'userId': user?.uid,
        'email': user?.email,
        'address': info.address,
        'phone': info.phone,
        'dni': info.dni,
        'birthDate': info.birthDate,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Información personal guardada correctamente');
    } catch (e) {
      print('Error guardando información personal: $e');
      rethrow;
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<PersonalInfo> personalInfoStream() {
    final personalInfoDoc = _personalInfoDoc;
    if (personalInfoDoc == null) {
      return Stream.value(PersonalInfo.empty());
    }

    return personalInfoDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return PersonalInfo.empty();

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return PersonalInfo.empty();

      return PersonalInfo.fromMap(data);
    });
  }

  // ==================== USER BASIC INFO ====================

  // Actualizar información básica del usuario
  Future<void> updateUserBasicInfo({
    String? name,
    String? photoUrl,
  }) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await userDoc.update(updateData);
    } catch (e) {
      print('Error actualizando información del usuario: $e');
    }
  }

// Agregar en FirestoreService
  Future<List<Incident>> getIncidentsWithCoords() async {
    try {
      final snapshot = await _incidentsCollection
          .where('tiene_coordenadas', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              Incident.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo incidentes con coordenadas: $e');
      return [];
    }
  }
}
