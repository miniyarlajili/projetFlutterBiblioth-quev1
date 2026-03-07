class UserModel {
  final String uid;
  final String nom;           // ← kima diagramme
  final String email;
  final String role;          // 'visitor' | 'member' | 'admin'
  final String? photoUrl;     // ← zidt
  final DateTime dateInscription; // ← kima diagramme
  final List<String> genresFavoris; // ← kima diagramme
  final String status;        // 'active' | 'pending' | 'suspended'
  final String? phone;
  final int activeLoansCount;

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.role,
    required this.status,
    required this.dateInscription,
    this.photoUrl,
    this.phone,
    this.genresFavoris = const [],
    this.activeLoansCount = 0,
  });

  // Firestore → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'pending',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      genresFavoris: List<String>.from(map['genresFavoris'] ?? []),
      activeLoansCount: map['activeLoansCount'] ?? 0,
      dateInscription: (map['dateInscription'] as dynamic).toDate(),
    );
  }

  // UserModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'role': role,
      'status': status,
      'photoUrl': photoUrl,
      'phone': phone,
      'genresFavoris': genresFavoris,
      'activeLoansCount': activeLoansCount,
      'dateInscription': dateInscription,
    };
  }
}