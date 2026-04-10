import '../models/book_model.dart';
import '../models/loan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream catalogue complet ──────────────────────────────
  Stream<List<BookModel>> getCatalogueStream() {
    return _db
        .collection('books')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  // ── Recherche par titre ou auteur ─────────────────────────
  Future<List<BookModel>> searchBooks(String query) async {
    final queryLower = query.toLowerCase();
    final snap = await _db.collection('books').get();
    return snap.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .where((book) =>
            book.titre.toLowerCase().contains(queryLower) ||
            book.auteur.toLowerCase().contains(queryLower) ||
            book.genre.toLowerCase().contains(queryLower))
        .toList();
  }

  // ── Livres récents (nouveautés) ───────────────────────────
  Stream<List<BookModel>> getNouveautesStream({int limit = 5}) {
    return _db
        .collection('books')
        .orderBy('dateAjout', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Livres recommandés (par genre favori) ─────────────────
  Stream<List<BookModel>> getRecommandationsStream(
      List<String> genresFavoris) {
    if (genresFavoris.isEmpty) return getNouveautesStream();
    return _db
        .collection('books')
        .where('genre', whereIn: genresFavoris.take(10).toList())
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Ajouter un livre (admin) ──────────────────────────────
  Future<void> addBook(BookModel book) async {
    await _db.collection('books').add(book.toMap());
  }

  // ── Modifier un livre (admin) ─────────────────────────────
  Future<void> updateBook(String id, Map<String, dynamic> data) async {
    await _db.collection('books').doc(id).update(data);
  }

  // ── Supprimer un livre (admin) ────────────────────────────
  Future<void> deleteBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  // ── Emprunter un livre ────────────────────────────────────
  Future<void> emprunterLivre({
    required String userId,
    required BookModel book,
  }) async {
    final batch = _db.batch();

    // Créer le prêt
    final loanRef = _db.collection('loans').doc();
    final loan = LoanModel(
      id: loanRef.id,
      userId: userId,
      bookId: book.id,
      bookTitre: book.titre,
      bookAuteur: book.auteur,
      bookImageUrl: book.imageUrl,
      dateEmprunt: DateTime.now(),
      dateRetourPrevue: DateTime.now().add(const Duration(days: 14)),
      statut: 'en_cours',
    );
    batch.set(loanRef, loan.toMap());

    // Mettre à jour statut livre
    batch.update(
      _db.collection('books').doc(book.id),
      {'statut': 'emprunté'},
    );

    await batch.commit();
  }

  // ── Retourner un livre ────────────────────────────────────
  Future<void> retournerLivre({
    required String loanId,
    required String bookId,
  }) async {
    final batch = _db.batch();

    batch.update(
      _db.collection('loans').doc(loanId),
      {
        'statut': 'retourné',
        'dateRetourEffective': DateTime.now(),
      },
    );

    batch.update(
      _db.collection('books').doc(bookId),
      {'statut': 'disponible'},
    );

    await batch.commit();
  }

  // ── Emprunts actifs d'un membre ───────────────────────────
  Stream<List<LoanModel>> getActiveLoansStream(String userId) {
    return _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_cours')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Historique emprunts d'un membre ──────────────────────
  Stream<List<LoanModel>> getLoanHistoryStream(String userId) {
    return _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .orderBy('dateEmprunt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LoanModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Stats membre (pour HomeScreen) ───────────────────────
  Future<Map<String, int>> getMemberStats(String userId) async {
    final active = await _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'en_cours')
        .get();

    final returned = await _db
        .collection('loans')
        .where('userId', isEqualTo: userId)
        .where('statut', isEqualTo: 'retourné')
        .get();

    return {
      'enCours': active.docs.length,
      'retournés': returned.docs.length,
      'notifications': 0,
    };
  }
}