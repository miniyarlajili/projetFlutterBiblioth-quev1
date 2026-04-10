import 'loans_screen.dart';
import '../auth/login_screen.dart';
import '../../utils/constants.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../visitor/catalogue_screen.dart';
import '../../controllers/auth_controller.dart';
import 'package:bookshare/views/visitor/book_detail_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final BookService _bookService = BookService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    final List<Widget> _screens = [
      _HomeTab(user: user, bookService: _bookService),
      const CatalogueScreen(),
      const LoansScreen(),
      const _EventsPlaceholder(),
      const _MessagesPlaceholder(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      backgroundColor: Colors.white,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Welcome',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Catalog',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
          label: 'Loans',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Event',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME TAB — Welcome + Stats + Recommended
// ══════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final dynamic user;
  final BookService bookService;

  const _HomeTab({required this.user, required this.bookService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── AppBar custom ────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),

          // ── Stats bar ────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsBar(userId: user?.uid ?? ''),
          ),

          // ── Section Recommended ──────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Recommanded for you',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

          // ── Liste recommandations ─────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<BookModel>>(
              stream: bookService.getRecommandationsStream(
                  user?.genresFavoris ?? []),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ));
                }
                final books = snapshot.data!;
                if (books.isEmpty) {
                  return const _EmptyRecommended();
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: books.length,
                  itemBuilder: (context, index) => _BookCard(
                    book: books[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BookDetailScreen(book: books[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              (user?.nom ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${user?.nom?.split(' ').first ?? 'Membre'} 👋',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Text(
                  'Bibliothèque BookShare',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          IconButton(
            onPressed: () {},
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textDark, size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Logout
          IconButton(
            onPressed: () async {
              await context.read<AuthController>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout,
                color: AppColors.textMuted, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Stats Bar ──────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final String userId;
  const _StatsBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: BookService().getMemberStats(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'enCours': 0, 'retournés': 0, 'notifications': 0};
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: stats['enCours']!,
                label: 'In progress',
                icon: Icons.book_outlined,
                color: Colors.blue.shade200,
              ),
              _divider(),
              _StatItem(
                value: stats['retournés']!,
                label: 'returned',
                icon: Icons.check_circle_outline,
                color: Colors.green.shade200,
              ),
              _divider(),
              _StatItem(
                value: stats['notifications']!,
                label: 'reserved',
                icon: Icons.bookmark_outline,
                color: Colors.orange.shade200,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.white24,
      );
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ── Book Card (Recommended) ─────────────────────────────────────
class _BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            _BookCover(imageUrl: book.imageUrl, size: 60),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.auteur,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StarRating(rating: book.rating),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            _StatusBadge(statut: book.statut),
          ],
        ),
      ),
    );
  }
}

// ── Book Cover widget ───────────────────────────────────────────
class _BookCover extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _BookCover({this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size * 1.3,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size * 1.3,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary.withOpacity(0.5),
        size: size * 0.5,
      ),
    );
  }
}

// ── Star Rating ─────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFB300),
          size: 14,
        );
      }),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (statut) {
      case 'emprunté':
        bg = Colors.orange.shade50;
        fg = Colors.orange;
        label = 'Borrow';
        break;
      case 'réservé':
        bg = Colors.blue.shade50;
        fg = Colors.blue;
        label = 'Reserved';
        break;
      default:
        bg = Colors.green.shade50;
        fg = AppColors.success;
        label = 'Available';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyRecommended extends StatelessWidget {
  const _EmptyRecommended();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          'Aucune recommandation pour l\'instant',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _EventsPlaceholder extends StatelessWidget {
  const _EventsPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Événements — bientôt')),
      );
}

class _MessagesPlaceholder extends StatelessWidget {
  const _MessagesPlaceholder();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Messages — bientôt')),
      );
}