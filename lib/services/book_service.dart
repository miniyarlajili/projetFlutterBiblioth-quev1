import 'dart:math' show log;
import '../models/book_model.dart';
import '../models/loan_model.dart';
import 'package:bookshare/models/ReviewModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// ─────────────────────────────────────────────────────────────
// Seuils pour les recommandations
// ─────────────────────────────────────────────────────────────
const double _kMinRating = 3.5; // note minimale pour être recommandé
const int _kMinReviews = 2; // nombre minimum d'avis requis

class BookService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream catalogue complet ──────────────────────────────
  Stream<List<BookModel>> getCatalogueStream() {
    return _db
        .collection('books')
        .orderBy('dateAjout', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BookModel.fromMap(doc.data(), doc.id))
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

  // ── Stream recommandations (par genre favori) ─────────────
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
        'dateRetourEffective': Timestamp.fromDate(DateTime.now()),
      },
    );

    batch.update(
      _db.collection('books').doc(bookId),
      {'statut': 'disponible'},
    );

    await batch.commit();
  }

  // ── Prolonger un emprunt ──────────────────────────────────
  /// Prolonge de [jours] jours à partir de la date de retour prévue.
  /// Lève une exception si le livre est déjà en retard.
  Future<void> prolongerEmprunt({
    required String loanId,
    required DateTime dateRetourActuelle,
    int jours = 7,
  }) async {
    if (dateRetourActuelle.isBefore(DateTime.now())) {
      throw 'Ce livre est déjà en retard. Vous ne pouvez pas prolonger.';
    }
    final nouvelleDateRetour = dateRetourActuelle.add(Duration(days: jours));
    await _db.collection('loans').doc(loanId).update({
      'dateRetourPrevue': Timestamp.fromDate(nouvelleDateRetour),
      'prolonge': true,
    });
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

  // ── Ajouter une review pour un livre ─────────────────────
  Future<void> addReview({
    required String bookId,
    required String userId,
    required String userName,
    required double rating,
    required String commentaire,
  }) async {
    final reviewRef = _db.collection('reviews').doc();
    final review = ReviewModel(
      id: reviewRef.id,
      bookId: bookId,
      userId: userId,
      userName: userName,
      rating: rating,
      commentaire: commentaire,
      dateCreation: DateTime.now(),
    );

    await reviewRef.set(review.toMap());
    await _updateBookAverageRating(bookId);
  }

  // ── Mettre à jour la note moyenne d'un livre ─────────────
  Future<void> _updateBookAverageRating(String bookId) async {
    final reviewsSnapshot = await _db
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final double averageRating = totalRating / reviewsSnapshot.docs.length;
    final int reviewCount = reviewsSnapshot.docs.length;

    await _db.collection('books').doc(bookId).update({
      'rating': averageRating,
      'reviewCount': reviewCount,
    });
  }

  // ── Récupérer les reviews d'un livre ─────────────────────
  Stream<List<ReviewModel>> getBookReviewsStream(String bookId) {
  return _db
    .collection('reviews')
    .where('bookId', isEqualTo: bookId)
    .snapshots()
    .map((snap) => snap.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ── Vérifier si l'utilisateur a déjà noté un livre ───────
  Future<bool> hasUserReviewedBook(String userId, String bookId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ── Top rated books ───────────────────────────────────────
  Future<List<BookModel>> getTopRatedBooks({int limit = 10}) async {
    final snapshot = await _db
        .collection('books')
        .orderBy('rating', descending: true)
        .where('reviewCount', isGreaterThan: 0)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BookModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Recommandations intelligentes ────────────────────────
  /// Logique en 3 étapes:
  /// 1. Books des genres favoris du member avec rating >= 3.5 ET reviewCount >= 2
  /// 2. Si résultats insuffisants → compléter avec top rated tous genres
  /// 3. Si toujours vide → nouveautés disponibles (fallback)
  ///
  /// Tri par score = rating × ln(reviewCount + 1)
  /// → Équilibre qualité (note) et popularité (nb avis)
  Future<List<BookModel>> getRecommandations(
    List<String> genresFavoris, {
    int limit = 10,
  }) async {
    List<BookModel> results = [];

    // ── Étape 1 : genres favoris bien notés ──────────────
    if (genresFavoris.isNotEmpty) {
      final snap = await _db
          .collection('books')
          .where('genre', whereIn: genresFavoris.take(10).toList())
          .where('reviewCount', isGreaterThanOrEqualTo: _kMinReviews)
          .get();

      results = snap.docs
          .map((doc) => BookModel.fromMap(doc.data(), doc.id))
          .where((b) => b.rating >= _kMinRating)
          .toList();

      results.sort((a, b) => _score(b).compareTo(_score(a)));
      results = results.take(limit).toList();
    }

    // ── Étape 2 : compléter avec top rated si besoin ─────
    if (results.length < limit) {
      final snap = await _db
          .collection('books')
          .where('reviewCount', isGreaterThanOrEqualTo: _kMinReviews)
          .get();

      final existingIds = results.map((b) => b.id).toSet();

      final topRated = snap.docs
          .map((doc) => BookModel.fromMap(doc.data(), doc.id))
          .where((b) =>
              b.rating >= _kMinRating && !existingIds.contains(b.id))
          .toList();

      topRated.sort((a, b) => _score(b).compareTo(_score(a)));
      results.addAll(topRated.take(limit - results.length));
    }

    // ── Étape 3 : fallback → nouveautés disponibles ───────
    if (results.isEmpty) {
      final snap = await _db
          .collection('books')
          .where('statut', isEqualTo: 'disponible')
          .orderBy('dateAjout', descending: true)
          .limit(limit)
          .get();

      results = snap.docs
          .map((doc) => BookModel.fromMap(doc.data(), doc.id))
          .toList();
    }

    return results;
  }

  // ── Score pour le tri des recommandations ─────────────────
  // rating × ln(reviewCount + 1) — donne plus de poids aux livres
  // avec beaucoup d'avis sans pénaliser les livres récents bien notés
  double _score(BookModel b) {
    if (b.reviewCount == 0) return 0;
    return b.rating * log(b.reviewCount + 1);
  }

  // ── Récupérer un livre par son ID ─────────────────────────
  Future<BookModel?> getBookById(String bookId) async {
    final doc = await _db.collection('books').doc(bookId).get();
    if (doc.exists) {
      return BookModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}