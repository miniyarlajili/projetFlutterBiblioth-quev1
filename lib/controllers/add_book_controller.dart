import '../models/book_model.dart';
import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../services/isbn_service.dart';

class AddBookController {
  final titreCtrl = TextEditingController();
  final auteurCtrl = TextEditingController();
  final isbnCtrl = TextEditingController();
  final resumeCtrl = TextEditingController();
  final imageCtrl = TextEditingController();

  final BookService _bookService = BookService();
  final IsbnService _isbnService = IsbnService();

  bool loading = false;

  // 🔥 SCAN + AUTO FILL
  Future<void> scanIsbn(BuildContext context) async {
    final isbn = isbnCtrl.text.trim();
    if (isbn.isEmpty) return;

    loading = true;

    final data = await _isbnService.fetchBookByIsbn(isbn);

    if (data != null) {
      titreCtrl.text = data["titre"] ?? "";
      auteurCtrl.text = data["auteur"] ?? "";
      resumeCtrl.text = data["resume"] ?? "";
      imageCtrl.text = data["imageUrl"] ?? "";
    }

    loading = false;
  }

  // 💾 SAVE BOOK
  Future<void> save(BuildContext context) async {
    loading = true;

    final book = BookModel(
      id: "",
      titre: titreCtrl.text.trim(),
      auteur: auteurCtrl.text.trim(),
      isbn: isbnCtrl.text.trim(),
      resume: resumeCtrl.text.trim(),
      imageUrl: imageCtrl.text.trim(),
      genre: "Roman",
      statut: "disponible",
      dateAjout: DateTime.now(),
    );

    await _bookService.addBook(book);

    loading = false;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Livre ajouté avec succès")),
    );
  }

  void dispose() {
    titreCtrl.dispose();
    auteurCtrl.dispose();
    isbnCtrl.dispose();
    resumeCtrl.dispose();
    imageCtrl.dispose();
  }
}