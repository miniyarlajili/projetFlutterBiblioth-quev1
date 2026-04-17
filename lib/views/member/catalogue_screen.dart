import '../../utils/constants.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import '../visitor/book_detail_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final BookService _bookService = BookService();

  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];

  String _selectedGenre = 'Tous';
  String _searchQuery = '';

  final List<String> genres = [
    'Tous',
    'Roman',
    'Science',
    'SF',
    'Histoire',
    'Biographie',
  ];

  @override
  void initState() {
    super.initState();
    _bookService.getCatalogueStream().listen((data) {
      setState(() {
        _books = data;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    List<BookModel> result = _books;

    if (_selectedGenre != 'Tous') {
      result = result
          .where((b) =>
              b.genre.toLowerCase() == _selectedGenre.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((b) {
        return b.titre.toLowerCase().contains(_searchQuery) ||
            b.auteur.toLowerCase().contains(_searchQuery) ||
            (b.isbn ?? '').toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredBooks = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          _topHeader(),
          const SizedBox(height: 10),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  // ================= TOP HEADER =================
  Widget _topHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 55, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF1E5AA8), // 🔵 bleu principal
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📚 Catalogue",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // SEARCH
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                )
              ],
            ),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.toLowerCase();
                  _applyFilters();
                });
              },
              decoration: const InputDecoration(
                hintText: "Rechercher un livre...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // GENRES (chips scrollables)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: genres.map((g) {
                final selected = g == _selectedGenre;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGenre = g;
                      _applyFilters();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      g,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF1E5AA8)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LIST (cards under each other) =================
  Widget _list() {
    if (_filteredBooks.isEmpty) {
      return const Center(child: Text("Aucun livre trouvé"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: book),
              ),
            );
          },
          child: _bookCard(book),
        );
      },
    );
  }

  // ================= CARD =================
  Widget _bookCard(BookModel book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // IMAGE
          Container(
            width: 80,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: const Icon(
              Icons.menu_book,
              size: 35,
              color: Color(0xFF1E5AA8),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    book.auteur,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < book.rating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 13,
                        color: Colors.amber,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(book.statut).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      book.statut,
                      style: TextStyle(
                        color: _statusColor(book.statut),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'emprunté':
        return Colors.orange;
      case 'réservé':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}