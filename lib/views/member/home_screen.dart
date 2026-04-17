import 'loans_screen.dart';
import '../auth/login_screen.dart';
import '../../utils/constants.dart';
import '../member/loans_screen.dart';
import '../../models/book_model.dart';
import '../member/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../controllers/auth_controller.dart';
import 'package:bookshare/views/member/catalogue_screen.dart';
import 'package:bookshare/views/visitor/book_detail_screen.dart';

//import '../visitor/catalogue_screen.dart';

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
      const _EvenementsPlaceholder(),
      const ProfileScreen(), // ✅ Profil remplace Messages
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F8),
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
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Catalogue',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
          label: 'Emprunts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Événements',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOME TAB
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
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: _SearchBar()),
          SliverToBoxAdapter(
            child: _StatsBar(userId: user?.uid ?? ''),
          ),

          // ── SECTION 1 : TOP RATED ─────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text('🏆 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Recommandés par les membres',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<BookModel>>(
              future: bookService.getTopRatedBooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Aucun livre noté pour le moment',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                final books = snapshot.data!;
                return SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: books.length,
                    itemBuilder: (context, index) => _TopRatedCard(
                      book: books[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookDetailScreen(book: books[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── SECTION 2 : RECOMMANDÉS POUR VOUS ────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text('✨ ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Recommandés pour vous',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<List<BookModel>>(
              future: bookService
                  .getRecommandations(user?.genresFavoris ?? []),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                final books = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: books.length,
                  itemBuilder: (context, index) => _Cartelivre(
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
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour 👋',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  '${user?.nom?.split(' ').first ?? 'Membre'} !',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.orange,
                child: Text(
                  (user?.nom ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
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
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Top Rated Card ─────────────────────────────────────────────
class _TopRatedCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const _TopRatedCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: _CouvertureLivre(imageUrl: book.imageUrl, size: 160),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.titre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.auteur,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _NotesEtoiles(rating: book.rating),
                      const SizedBox(width: 4),
                      Text(
                        '(${book.reviewCount})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: Color(0xFFFFB300)),
                        const SizedBox(width: 2),
                        Text(
                          book.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB300),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textMuted, size: 20),
            SizedBox(width: 8),
            Text(
              'Rechercher un livre...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Bar ───────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final String userId;
  const _StatsBar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: BookService().getMemberStats(userId),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {'enCours': 0, 'retournés': 0, 'notifications': 0};
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: stats['enCours']!,
                  label: 'En cours',
                  icon: Icons.book_outlined,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: stats['retournés']!,
                  label: 'Retournés',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: stats['notifications']!,
                  label: 'Réservés',
                  icon: Icons.bookmark_outline,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte Livre (verticale) ─────────────────────────────────────
class _Cartelivre extends StatelessWidget {
  final BookModel book;
  final VoidCallback onTap;

  const _Cartelivre({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            _CouvertureLivre(imageUrl: book.imageUrl, size: 60),
            const SizedBox(width: 12),
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
                  _NotesEtoiles(rating: book.rating),
                  const SizedBox(height: 6),
                  _BadgeStatut(statut: book.statut),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _BoutonAction(statut: book.statut),
          ],
        ),
      ),
    );
  }
}

// ── Couverture Livre ────────────────────────────────────────────
class _CouvertureLivre extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _CouvertureLivre({this.imageUrl, required this.size});

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

// ── Notes Étoiles ───────────────────────────────────────────────
class _NotesEtoiles extends StatelessWidget {
  final double rating;
  const _NotesEtoiles({required this.rating});

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

// ── Badge Statut ────────────────────────────────────────────────
class _BadgeStatut extends StatelessWidget {
  final String statut;
  const _BadgeStatut({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (statut) {
      case 'emprunté':
        bg = Colors.orange.shade50;
        fg = Colors.orange;
        label = 'Emprunté';
        break;
      case 'réservé':
        bg = Colors.blue.shade50;
        fg = Colors.blue;
        label = 'Réservé';
        break;
      default:
        bg = Colors.green.shade50;
        fg = Colors.green;
        label = 'Disponible';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ── Bouton Action ───────────────────────────────────────────────
class _BoutonAction extends StatelessWidget {
  final String statut;
  const _BoutonAction({required this.statut});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (statut) {
      case 'emprunté':
        label = 'Indisponible';
        color = Colors.grey;
        break;
      case 'réservé':
        label = 'Réserver';
        color = Colors.orange;
        break;
      default:
        label = 'Emprunter';
        color = AppColors.primary;
    }

    return ElevatedButton(
      onPressed: statut == 'emprunté' ? null : () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}

// ── Placeholders ────────────────────────────────────────────────
class _EvenementsPlaceholder extends StatelessWidget {
  const _EvenementsPlaceholder();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Événements — bientôt disponible')),
      );
}