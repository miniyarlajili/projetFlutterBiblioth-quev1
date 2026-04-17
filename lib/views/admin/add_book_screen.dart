import 'dart:io';
import 'isbn_scanner_screen.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  final BookService service = BookService();
  final IsbnScannerController scanner = IsbnScannerController();
  final ImagePicker picker = ImagePicker();

  bool loading = false;
  File? _imageFile;

  String _selectedGenre = "Roman";

  final List<String> genres = [
    "Roman",
    "Science",
    "SF",
    "Histoire",
    "Biographie",
    "Autre",
  ];

  // ───────── PICK IMAGE ─────────
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // ───────── UPLOAD IMAGE ─────────
  Future<String?> uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child("books/${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ───────── ISBN SCANNER ─────────
  void fillFromScanner(String isbn) async {
    setState(() => loading = true);

    final data = await scanner.scanAndFetch(isbn);

    if (data != null) {
      _titre.text = data["titre"] ?? "";
      _auteur.text = data["auteur"] ?? "";
    }

    setState(() => loading = false);
  }

  // ───────── SAVE BOOK ─────────
  Future<void> save() async {
    setState(() => loading = true);

    String? imageUrl;

    if (_imageFile != null) {
      imageUrl = await uploadImage(_imageFile!);
    }

    final book = BookModel(
      id: "",
      titre: _titre.text,
      auteur: _auteur.text,
      genre: _selectedGenre,
      imageUrl: imageUrl,
      statut: "disponible",
      dateAjout: DateTime.now(),
    );

    await service.addBook(book);

    setState(() => loading = false);

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

            // ───────── IMAGE PICKER ─────────
            GestureDetector(
              onTap: pickImage,
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40),
                          SizedBox(height: 8),
                          Text("Ajouter une image"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),

            // ───────── SCANNER ─────────
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
                      fontWeight: FontWeight.bold,
                    ),
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

            _field("Titre du livre", _titre),
            _field("Auteur", _auteur),
            _field("Nombre de copies", _copies,
                type: TextInputType.number),

            const SizedBox(height: 10),

            // ───────── GENRE ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Genre",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                            fontWeight: FontWeight.bold,
                          ),
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