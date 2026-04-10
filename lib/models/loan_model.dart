import 'package:cloud_firestore/cloud_firestore.dart';

class LoanModel {
  final String id;
  final String userId;
  final String bookId;
  final String bookTitre;
  final String bookAuteur;
  final String? bookImageUrl;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevue;
  final DateTime? dateRetourEffective;
  final String statut; // 'en_cours' | 'retourné' | 'en_retard'

  LoanModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitre,
    required this.bookAuteur,
    this.bookImageUrl,
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourEffective,
    required this.statut,
  });

  factory LoanModel.fromMap(Map<String, dynamic> map, String id) {
    return LoanModel(
      id: id,
      userId: map['userId'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitre: map['bookTitre'] ?? '',
      bookAuteur: map['bookAuteur'] ?? '',
      bookImageUrl: map['bookImageUrl'],
      dateEmprunt: (map['dateEmprunt'] as Timestamp).toDate(),
      dateRetourPrevue: (map['dateRetourPrevue'] as Timestamp).toDate(),
      dateRetourEffective: map['dateRetourEffective'] != null
          ? (map['dateRetourEffective'] as Timestamp).toDate()
          : null,
      statut: map['statut'] ?? 'en_cours',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'bookTitre': bookTitre,
      'bookAuteur': bookAuteur,
      'bookImageUrl': bookImageUrl,
      'dateEmprunt': dateEmprunt,
      'dateRetourPrevue': dateRetourPrevue,
      'dateRetourEffective': dateRetourEffective,
      'statut': statut,
    };
  }

  bool get isLate =>
      statut == 'en_cours' && DateTime.now().isAfter(dateRetourPrevue);

  int get joursRestants =>
      dateRetourPrevue.difference(DateTime.now()).inDays;
}