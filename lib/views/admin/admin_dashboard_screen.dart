import 'members_screen.dart';
import 'add_book_screen.dart';
import 'add_event_screen.dart';
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
    _HomeTab(onEventsTap: () => setState(() => _index = 2)),
    const _CatalogueTab(),
    const _EventsTab(),
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
        type: BottomNavigationBarType.fixed,
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
            icon: Icon(Icons.event),
            label: "Événements",
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

// ─────────────────────────────────────────
// 🟠 HOME TAB
// ─────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final VoidCallback onEventsTap;

  const _HomeTab({required this.onEventsTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A18), Color(0xFFFFA726)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dashboard Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _StatBox(streamType: "members"),
                    const _StatBox(streamType: "books"),
                    const _StatBox(streamType: "loans"),
                    // 🔔 Badge notifications events
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("events")
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Stack(
                          children: [
                            const Icon(Icons.notifications,
                                color: Colors.white, size: 30),
                            if (count > 0)
                              Positioned(
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "$count",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _alert("5 comptes en attente", Colors.orange),
          _alert("2 emprunts en retard", Colors.red),

          const SizedBox(height: 20),

          const Text(
            "Actions rapides",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _btn(Icons.add, "Ajouter livre", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AddBookScreen()),
                  );
                }),
                _btn(Icons.people, "Membres", () {}),
                _btn(Icons.event, "Événements", onEventsTap),
                _btn(Icons.bar_chart, "Stats", () {}),
              ],
            ),
          ),
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFF7A18)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 🔥 STAT BOX
// ─────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String streamType;

  const _StatBox({required this.streamType});

  Stream<int> _stream() {
    final db = FirebaseFirestore.instance;

    if (streamType == "members") {
      return db
          .collection("users")
          .where("role", isEqualTo: "member")
          .snapshots()
          .map((s) => s.docs.length);
    }

    if (streamType == "books") {
      return db
          .collection("books")
          .snapshots()
          .map((s) => s.docs.length);
    }

    return db
        .collection("loans")
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

        String label;
        IconData icon;

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
            Text("$count",
                style:
                    const TextStyle(color: Colors.white, fontSize: 18)),
            Text(label,
                style: const TextStyle(color: Colors.white70)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// 📚 CATALOGUE TAB
// ─────────────────────────────────────────

class _CatalogueTab extends StatelessWidget {
  const _CatalogueTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7A18),
        foregroundColor: Colors.white,
        title: const Text("Catalogue"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddBookScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<BookModel>>(
        stream: BookService().getCatalogueStream(),
        builder: (context, snapshot) {
          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(child: Text("Aucun livre"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final b = books[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.book_outlined,
                      color: Color(0xFFFF7A18)),
                  title: Text(b.titre),
                  subtitle: Text(b.auteur),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => BookService().deleteBook(b.id),
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

// ─────────────────────────────────────────
// 📢 EVENTS TAB
// ─────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7A18),
        foregroundColor: Colors.white,
        title: const Text("Événements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddEventScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data?.docs ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("Aucun événement",
                      style:
                          TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFF7A18).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event,
                        color: Color(0xFFFF7A18)),
                  ),
                  title: Text(
                    e['title'] ?? '',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(e['description'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('events')
                        .doc(e.id)
                        .delete(),
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