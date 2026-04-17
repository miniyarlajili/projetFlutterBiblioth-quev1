import 'dart:io';
import 'isbn_scanner_screen.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import '../../controllers/isbn_scanner_controller.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _titre = TextEditingController();
  final _auteur = TextEditingController();
  final _copies = TextEditingController(text: "1");

  final IsbnScannerController scanner = IsbnScannerController();
  final BookService service = BookService();

  bool loading = false;

  String _selectedGenre = "Roman";

  final List<String> genres = [
    "Roman",
    "Science",
    "SF",
    "Histoire",
    "Biographie",
    "Autre",
  ];

  // ───────── SCANNER ─────────
  void fillFromScanner(String isbn) async {
    setState(() => loading = true);

    final data = await scanner.scanAndFetch(isbn);

    if (data != null) {
      _titre.text = data["titre"] ?? "";
      _auteur.text = data["auteur"] ?? "";
    }

    setState(() => loading = false);
  }

  // ───────── SAVE ─────────
  Future<void> save() async {
    final book = BookModel(
      id: "",
      titre: _titre.text,
      auteur: _auteur.text,
      genre: _selectedGenre,
      statut: "disponible",
      dateAjout: DateTime.now(),
    );

    await service.addBook(book);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5AA8),
        title: const Text("Ajouter un livre"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // ───────── SCANNER CARD ─────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E5AA8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      size: 50, color: Colors.white),

                  const SizedBox(height: 10),

                  const Text(
                    "Scanner ISBN automatique",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E5AA8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IsbnScannerScreen(
                            onDetect: fillFromScanner,
                          ),
                        ),
                      );
                    },
                    child: const Text("Activer caméra"),
                  )
                ],
              ),
            ),

            // ───────── FIELDS ─────────
            _field("Titre du livre", _titre),
            _field("Auteur", _auteur),
            _field("Nombre de copies", _copies,
                type: TextInputType.number),

            const SizedBox(height: 10),

            // ───────── GENRE ─────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Genre",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: genres.map((g) {
                  final selected = g == _selectedGenre;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGenre = g;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1E5AA8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1E5AA8),
                        ),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF1E5AA8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ───────── SAVE BUTTON ─────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5AA8),
                  ),
                  onPressed: loading ? null : save,
                  child: loading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text(
                          "Enregistrer",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}