class PersonalInfo {
  final String address;
  final String phone;
  final String dni;
  final String birthDate;

  PersonalInfo({
    required this.address,
    required this.phone,
    required this.dni,
    required this.birthDate,
  });

  // Constructor vacío
  factory PersonalInfo.empty() {
    return PersonalInfo(
      address: '',
      phone: '',
      dni: '',
      birthDate: '',
    );
  }

  // Verificar si está vacío
  bool get isEmpty =>
      address.isEmpty && phone.isEmpty && dni.isEmpty && birthDate.isEmpty;

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'phone': phone,
      'dni': dni,
      'birthDate': birthDate,
    };
  }

  // Crear desde Map de Firestore
  factory PersonalInfo.fromMap(Map<String, dynamic> map) {
    return PersonalInfo(
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      dni: map['dni'] ?? '',
      birthDate: map['birthDate'] ?? '',
    );
  }

  // Crear copia con cambios
  PersonalInfo copyWith({
    String? address,
    String? phone,
    String? dni,
    String? birthDate,
  }) {
    return PersonalInfo(
      address: address ?? this.address,
      phone: phone ?? this.phone,
      dni: dni ?? this.dni,
      birthDate: birthDate ?? this.birthDate,
    );
  }
}
