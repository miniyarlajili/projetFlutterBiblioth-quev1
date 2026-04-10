import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Instance de Firebase Authentication (gestion login, register, logout)
  final FirebaseAuth _auth = FirebaseAuth.instance;
    // Instance de Cloud Firestore (base de données)
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Stream qui écoute les changements d'état d'authentification (login/logout)

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Inscription ───────────────────────────────────────────
  Future<UserModel?> register({
    required String email,
    required String password,
    required String nom,
    String? phone,
  }) async {
    try {
       // Création d'un utilisateur dans Firebase Authentication (email + mot de passe)
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user!.updateDisplayName(nom);

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        nom: nom,
        role: 'member',
        status: 'pending',
        phone: phone,
        dateInscription: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      print('❌ Register error: $e');
      throw 'Erreur inscription: $e';
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

      print('📄 Login doc exists: ${doc.exists}');
      print('📄 Login doc data: ${doc.data()}');

      if (!doc.exists) throw 'Compte introuvable dans la base de données';

      UserModel user = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        cred.user!.uid,
      );

      print('✅ Login role: ${user.role}');
      print('✅ Login status: ${user.status}');

      if (user.status == 'suspended') {
        await _auth.signOut();
        throw 'Votre compte est suspendu. Contactez l\'administrateur.';
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      if (e is String) rethrow;
      print('❌ Login error: $e');
      throw 'Erreur connexion: $e';
    }
  }

  // ── Déconnexion ───────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Récupérer user courant ────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        print('❌ No firebase user logged in');
        return null;
      }

      print('🔥 Firebase UID: ${firebaseUser.uid}');

      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      print('📄 Doc exists: ${doc.exists}');
      print('📄 Doc data: ${doc.data()}');

      if (!doc.exists) return null;

      UserModel user = UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        firebaseUser.uid,
      );

      print('✅ Role loaded: ${user.role}');
      print('✅ Status loaded: ${user.status}');

      return user;
    } catch (e) {
      print('❌ getCurrentUser error: $e');
      return null;
    }
  }

  // ── Gestion erreurs Firebase ──────────────────────────────
  String _handleAuthError(FirebaseAuthException e) {
    print('🔥 FirebaseAuthException: ${e.code}');
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
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue: ${e.code}';
    }
  }
}