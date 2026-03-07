import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Inscription ───────────────────────────────────────────
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nom,        // ← sawweb
    String? phone,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user!.updateDisplayName(nom);

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        nom: nom,               // ← sawweb
        role: 'member',
        status: 'pending',
        phone: phone,
        dateInscription: DateTime.now(),  // ← sawweb
      );

      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Connexion ─────────────────────────────────────────────
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) throw 'Compte introuvable';

      UserModel user = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        cred.user!.uid,
      );

      if (user.status == 'suspended') {
        await _auth.signOut();
        throw 'Votre compte est suspendu. Contactez l\'administrateur.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Déconnexion ───────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Récupérer user courant ────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    DocumentSnapshot doc = await _db
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      firebaseUser.uid,
    );
  }

  // ── Gestion erreurs ───────────────────────────────────────
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible (min 6 caractères).';
      case 'user-not-found':
        return 'Aucun compte avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}