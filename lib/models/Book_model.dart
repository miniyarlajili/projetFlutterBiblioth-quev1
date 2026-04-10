import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String titre;
  final String auteur;
  final String? isbn;
  final String? resume;
  final String? imageUrl;
  final String genre;
  final String statut; // 'disponible' | 'emprunté' | 'réservé'
  final double rating;
  final int reviewCount;
  final DateTime dateAjout;
  final List<String> tags;

  BookModel({
    required this.id,
    required this.titre,
    required this.auteur,
    this.isbn,
    this.resume,
    this.imageUrl,
    required this.genre,
    required this.statut,
    this.rating = 0,
    this.reviewCount = 0,
    required this.dateAjout,
    this.tags = const [],
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      titre: map['titre'] ?? '',
      auteur: map['auteur'] ?? '',
      isbn: map['isbn'],
      resume: map['resume'],
      imageUrl: map['imageUrl'],
      genre: map['genre'] ?? 'Autre',
      statut: map['statut'] ?? 'disponible',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      dateAjout: map['dateAjout'] != null
          ? (map['dateAjout'] as Timestamp).toDate()
          : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'auteur': auteur,
      'isbn': isbn,
      'resume': resume,
      'imageUrl': imageUrl,
      'genre': genre,
      'statut': statut,
      'rating': rating,
      'reviewCount': reviewCount,
      'dateAjout': dateAjout,
      'tags': tags,
    };
  }

  BookModel copyWith({
    String? statut,
    double? rating,
    int? reviewCount,
    String? imageUrl,
  }) {
    return BookModel(
      id: id,
      titre: titre,
      auteur: auteur,
      isbn: isbn,
      resume: resume,
      imageUrl: imageUrl ?? this.imageUrl,
      genre: genre,
      statut: statut ?? this.statut,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      dateAjout: dateAjout,
      tags: tags,
    );
  }
}