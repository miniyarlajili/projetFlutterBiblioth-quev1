import 'package:cloud_firestore/cloud_firestore.dart';
// models/review_model.dart

class ReviewModel {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final double rating; // 1 à 5
  final String commentaire;
  final DateTime dateCreation;

  ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.commentaire,
    required this.dateCreation,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      bookId: map['bookId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      commentaire: map['commentaire'] ?? '',
      dateCreation: (map['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'commentaire': commentaire,
      'dateCreation': Timestamp.fromDate(dateCreation),
    };
  }
}