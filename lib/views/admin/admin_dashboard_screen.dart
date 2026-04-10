import 'members_screen.dart';
import 'add_book_screen.dart';
import '../../utils/constants.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;

  late final List<Widget> pages = [
    const _HomeTab(),
    const _CatalogueTab(),
    const MembersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: pages[_index],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: const Color(0xFFFF7A18),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: "Catalogue",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Membres",
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🟠 HOME TAB (LIKE IMAGE + DYNAMIC STATS)
////////////////////////////////////////////////////////////

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Stream<int> countStream(String collection, {String? field, String? value}) {
    final ref = FirebaseFirestore.instance.collection(collection);
    if (field != null && value != null) {
      return ref.where(field, isEqualTo: value).snapshots().map((s) => s.docs.length);
    }
    return ref.snapshots().map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // 🔶 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A18), Color(0xFFFFA726)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Dashboard Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox(streamType: "members"),
                    _StatBox(streamType: "books"),
                    _StatBox(streamType: "loans"),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔶 ALERTS
          _alert("5 comptes en attente", Colors.orange),
          _alert("2 emprunts en retard", Colors.red),

          const SizedBox(height: 20),

          const Text(
            "Actions rapides",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              children: [
                _btn(Icons.add, "Ajouter livre", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddBookScreen()));
                }),
                _btn(Icons.people, "Membres", () {}),
                _btn(Icons.bar_chart, "Stats", () {}),
                _btn(Icons.qr_code, "Scanner", () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _alert(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 STAT WIDGET DYNAMIC
////////////////////////////////////////////////////////////

class _StatBox extends StatelessWidget {
  final String streamType;

  const _StatBox({required this.streamType});

  Stream<int> _stream() {
    final db = FirebaseFirestore.instance;

    if (streamType == "members") {
      return db.collection("users")
          .where("role", isEqualTo: "member")
          .snapshots()
          .map((s) => s.docs.length);
    }

    if (streamType == "books") {
      return db.collection("books").snapshots().map((s) => s.docs.length);
    }

    return db.collection("loans")
        .where("statut", isEqualTo: "en_cours")
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        String label = "";
        IconData icon = Icons.circle;

        if (streamType == "members") {
          label = "Membres";
          icon = Icons.people;
        } else if (streamType == "books") {
          label = "Livres";
          icon = Icons.menu_book;
        } else {
          label = "Emprunts";
          icon = Icons.library_books;
        }

        return Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 5),
            Text(
              "$count",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// 📚 CATALOGUE TAB
////////////////////////////////////////////////////////////

class _CatalogueTab extends StatelessWidget {
  const _CatalogueTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7A18),
        title: const Text("Catalogue"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBookScreen()),
              );
            },
          )
        ],
      ),

      body: StreamBuilder<List<BookModel>>(
        stream: BookService().getCatalogueStream(),
        builder: (context, snapshot) {
          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(
              child: Text("Aucun livre"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final b = books[i];

              return Card(
                child: ListTile(
                  title: Text(b.titre),
                  subtitle: Text(b.auteur),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      BookService().deleteBook(b.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}