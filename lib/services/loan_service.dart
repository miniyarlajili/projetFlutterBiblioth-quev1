import 'package:cloud_firestore/cloud_firestore.dart';

class LoanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> getTotalLoanCount(String userId) async {
    final snap = await _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getReturnedCount(String userId) async {
    final snap = await _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'retourné') // ✅ FIX: statut + bonne valeur
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getActiveCount(String userId) async {
    final snap = await _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_cours') // ✅ FIX: statut
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> getReservationCount(String userId) async {
    final snap = await _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_attente') // ✅ FIX: statut
        .count()
        .get();
    return snap.count ?? 0;
  }
}