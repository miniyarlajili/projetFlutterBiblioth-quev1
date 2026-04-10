import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../models/loan_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../controllers/auth_controller.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'My Loans',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveLoansTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 1 — Emprunts en cours
// ══════════════════════════════════════════════════════════════
class _ActiveLoansTab extends StatelessWidget {
  const _ActiveLoansTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.uid ?? '';

    return StreamBuilder<List<LoanModel>>(
      stream: BookService().getActiveLoansStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final loans = snapshot.data ?? [];

        if (loans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Aucun emprunt en cours',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explorez le catalogue pour emprunter un livre',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (context, index) =>
              _LoanCard(loan: loans[index], showReturnButton: true),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB 2 — Historique
// ══════════════════════════════════════════════════════════════
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.uid ?? '';

    return StreamBuilder<List<LoanModel>>(
      stream: BookService().getLoanHistoryStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final loans = snapshot.data ?? [];

        if (loans.isEmpty) {
          return const Center(
            child: Text(
              'Aucun historique',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (context, index) =>
              _LoanCard(loan: loans[index], showReturnButton: false),
        );
      },
    );
  }
}

// ── Loan Card ───────────────────────────────────────────────────
class _LoanCard extends StatelessWidget {
  final LoanModel loan;
  final bool showReturnButton;

  const _LoanCard({required this.loan, required this.showReturnButton});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final isLate = loan.isLate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLate
            ? Border.all(color: Colors.red.shade200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Book icon placeholder
              Container(
                width: 44,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: loan.bookImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          loan.bookImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.menu_book_rounded,
                        color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitre,
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
                      loan.bookAuteur,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Statut badge
                    _LoanStatusBadge(loan: loan),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DateInfo(
                label: 'Emprunté le',
                date: fmt.format(loan.dateEmprunt),
              ),
              _DateInfo(
                label: loan.statut == 'retourné'
                    ? 'Retourné le'
                    : 'Retour prévu',
                date: loan.statut == 'retourné' && loan.dateRetourEffective != null
                    ? fmt.format(loan.dateRetourEffective!)
                    : fmt.format(loan.dateRetourPrevue),
                isLate: isLate,
              ),
            ],
          ),
          // Retard warning
          if (isLate) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: Colors.red, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'En retard de ${loan.joursRestants.abs()} jours',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Bouton retourner
          if (showReturnButton && loan.statut == 'en_cours') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () => _returnBook(context, loan),
                icon: const Icon(Icons.keyboard_return, size: 16),
                label: const Text('Retourner le livre'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _returnBook(BuildContext context, LoanModel loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retourner le livre'),
        content: Text('Confirmez-vous le retour de « ${loan.bookTitre} » ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BookService().retournerLivre(
        loanId: loan.id,
        bookId: loan.bookId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Livre retourné avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _LoanStatusBadge extends StatelessWidget {
  final LoanModel loan;
  const _LoanStatusBadge({required this.loan});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    if (loan.statut == 'retourné') {
      bg = Colors.green.shade50;
      fg = AppColors.success;
      label = 'Retourné';
    } else if (loan.isLate) {
      bg = Colors.red.shade50;
      fg = Colors.red;
      label = 'En retard';
    } else {
      bg = Colors.blue.shade50;
      fg = AppColors.primary;
      label = 'En cours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final bool isLate;

  const _DateInfo({
    required this.label,
    required this.date,
    this.isLate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Text(
          date,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLate ? Colors.red : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}