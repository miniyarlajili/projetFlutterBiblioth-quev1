class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String role;
  final String status;
  final String? photoUrl;
  final String? phone;
  final List<String> genresFavoris;
  final int activeLoansCount;
  final DateTime dateInscription;

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.role,
    required this.status,
    this.photoUrl,
    this.phone,
    this.genresFavoris = const [],
    this.activeLoansCount = 0,
    required this.dateInscription,
  });

  // Firestore → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'visitor',
      status: map['status'] ?? 'pending',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      genresFavoris: List<String>.from(map['genresFavoris'] ?? []),
      activeLoansCount: map['activeLoansCount'] ?? 0,
      dateInscription: map['dateInscription'] != null
          ? (map['dateInscription'] as dynamic).toDate()
          : DateTime.now(),
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