import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import '../../services/book_service.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final service = BookService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Détail du livre"),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _image(book.imageUrl),
            const SizedBox(height: 16),

            Text(book.titre,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            Text(book.auteur,
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                  i < book.rating.round()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                );
              }),
            ),

            Text("(${book.reviewCount} avis)"),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Résumé",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),

            Text(book.resume ?? "Pas de résumé"),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: book.statut == 'disponible'
                        ? () async {
                            await service.emprunterLivre(
                              userId: "USER_ID",
                              book: book,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Livre emprunté")),
                            );
                          }
                        : null,
                    child: const Text("Emprunter"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("Réserver"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _image(String? url) {
    if (url == null || url.isEmpty || !url.startsWith("http")) {
      return const Icon(Icons.book, size: 100);
    }

    return Image.network(
      url,
      height: 150,
      errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 100),
    );
  }
}