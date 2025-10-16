class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.phone,
  });

  // Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  // Crear desde Map de Firestore
  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  // Contacto vacío por defecto
  factory EmergencyContact.empty() {
    return EmergencyContact(
      name: 'Sin configurar',
      phone: '',
    );
  }

  bool get isEmpty => name.isEmpty || name == 'Sin configurar';
}
