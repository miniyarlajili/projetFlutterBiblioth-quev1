import '../../utils/constants.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../controllers/auth_controller.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;
  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isMember = auth.currentUser?.role == 'member' &&
        auth.currentUser?.status == 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.primary,
            expandedHeight: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Book details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookInfo(context, book),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GenreBadge(genre: book.genre),
                ),

                const SizedBox(height: 20),

                _buildSummarySection(book),

                const SizedBox(height: 20),

                _buildQuickDetails(book),

                const SizedBox(height: 24),

                if (isMember) _buildBorrowButton(context, book, auth),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookInfo(BuildContext context, BookModel book) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(
                        book.imageUrl!,
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _coverPlaceholder(120, 160),
                      )
                    : _coverPlaceholder(120, 160),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            book.titre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            book.auteur,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StarRating(rating: book.rating),
              const SizedBox(width: 6),
              Text(
                '(${book.reviewCount} Review)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BookModel book) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            book.resume ?? 'Aucun résumé disponible pour ce livre.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDetails(BookModel book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _DetailChip(
            icon: Icons.category_outlined,
            label: book.genre,
          ),
          const SizedBox(width: 8),
          if (book.isbn != null)
            _DetailChip(
              icon: Icons.qr_code,
              label: 'ISBN: ${book.isbn}',
            ),
          const SizedBox(width: 8),
          _DetailChip(
            icon: book.statut == 'disponible'
                ? Icons.check_circle_outline
                : Icons.schedule,
            label: book.statut == 'disponible'
                ? 'Disponible'
                : book.statut == 'emprunté'
                    ? 'Emprunté'
                    : 'Réservé',
            color: book.statut == 'disponible'
                ? AppColors.success
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowButton(
      BuildContext context, BookModel book, AuthController auth) {
    if (book.statut != 'disponible') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              book.statut == 'emprunté'
                  ? 'Livre actuellement emprunté'
                  : 'Livre réservé',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _confirmBorrow(context, book, auth),
          icon: const Icon(Icons.library_add_outlined, color: Colors.white),
          label: const Text(
            'Emprunter ce livre',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBorrow(
      BuildContext context, BookModel book, AuthController auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer l\'emprunt'),
        content: Text('Voulez-vous emprunter « ${book.titre} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Emprunter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await BookService().emprunterLivre(
      userId: auth.currentUser!.uid,
      book: book,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Livre emprunté !')),
    );

    Navigator.pop(context);
  }

  Widget _coverPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.menu_book_rounded),
    );
  }
}

class _GenreBadge extends StatelessWidget {
  final String genre;
  const _GenreBadge({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(genre),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}

// ⭐ FIX
class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 16, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 16, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 16, color: Colors.amber);
        }
      }),
    );
  }
}