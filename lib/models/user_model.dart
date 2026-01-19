class UserModel {
  final String uid;
  final String name;
  final String email;
  final String regNumber;
  final String batch;
  final String role;
  final String? profileImageUrl;
  final List<String> registeredEvents;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.regNumber,
    required this.batch,
    required this.role,
    this.profileImageUrl,
    this.registeredEvents = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      regNumber: map['regNumber'] ?? '',
      batch: map['batch'] ?? '',
      role: map['role'] ?? 'user',
      profileImageUrl: map['profileImageUrl'],
      registeredEvents: List<String>.from(map['registeredEvents'] ?? []),
    );
  }

  factory UserModel.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'regNumber': regNumber,
      'batch': batch,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'registeredEvents': registeredEvents,
    };
  }

  bool get isAdmin => role == 'admin';
}