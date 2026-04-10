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

  void fillFromScanner(String isbn) async {
    setState(() => loading = true);

    final data = await scanner.scanAndFetch(isbn);

    if (data != null) {
      _titre.text = data["titre"] ?? "";
      _auteur.text = data["auteur"] ?? "";
    }

    setState(() => loading = false);
  }

  Future<void> save() async {
    final book = BookModel(
      id: "",
      titre: _titre.text,
      auteur: _auteur.text,
      genre: "Autre",
      statut: "disponible",
      dateAjout: DateTime.now(),
    );

    await service.addBook(book);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE86C1A),
        title: const Text("Add Book"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🔵 SCANNER CARD (LIKE IMAGE)
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
                    "Automatic ISBN scanner",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
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
                    child: const Text("Tap to activate camera"),
                  )
                ],
              ),
            ),

            // 🟡 FORM
            _field("Book Title", _titre),
            _field("Author", _auteur),
            _field("Number of copy", _copies,
                type: TextInputType.number),

            const SizedBox(height: 20),

            // 🔵 SAVE
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save the book",
                          style: TextStyle(color: Colors.white)),
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
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}