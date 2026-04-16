import 'review_screen.dart';
import '../../models/loan_model.dart';
import '../../models/book_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../controllers/auth_controller.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthController>().currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Emprunts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ActiveLoansTab(userId: userId),
            _HistoryLoansTab(userId: userId),
          ],
        ),
      ),
    );
  }
}

// ── Onglet des emprunts en cours ───────────────────────────────
class _ActiveLoansTab extends StatelessWidget {
  final String? userId;

  const _ActiveLoansTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return StreamBuilder<List<LoanModel>>(
      stream: BookService().getActiveLoansStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final loans = snapshot.data!;
        if (loans.isEmpty) {
          return const Center(
            child: Text('Aucun emprunt en cours'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return _LoanCard(
              loan: loan,
              isActive: true,
            );
          },
        );
      },
    );
  }
}

// ── Onglet de l'historique ─────────────────────────────────────
class _HistoryLoansTab extends StatelessWidget {
  final String? userId;

  const _HistoryLoansTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    return StreamBuilder<List<LoanModel>>(
      stream: BookService().getLoanHistoryStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final loans = snapshot.data!;
        if (loans.isEmpty) {
          return const Center(
            child: Text('Aucun historique d\'emprunt'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return _LoanCard(
              loan: loan,
              isActive: false,
            );
          },
        );
      },
    );
  }
}

// ── Carte d'un emprunt ─────────────────────────────────────────
class _LoanCard extends StatefulWidget {
  final LoanModel loan;
  final bool isActive;

  const _LoanCard({
    required this.loan,
    required this.isActive,
  });

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  bool _isReturning = false;

  @override
  Widget build(BuildContext context) {
    final bookService = BookService();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Couverture
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: widget.loan.bookImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.loan.bookImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.loan.bookImageUrl == null
                      ? const Icon(Icons.book, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.loan.bookTitre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.loan.bookAuteur,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.isActive) ...[
                        _buildInfoRow(
                          '📅 Emprunté le',
                          _formatDate(widget.loan.dateEmprunt),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          '⏰ Retour prévu le',
                          _formatDate(widget.loan.dateRetourPrevue),
                          isWarning: widget.loan.dateRetourPrevue
                                  .isBefore(DateTime.now()),
                        ),
                      ] else ...[
                        _buildInfoRow(
                          '✅ Retourné le',
                          _formatDate(widget.loan.dateRetourEffective ??
                              widget.loan.dateRetourPrevue),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Boutons d'action
            if (widget.isActive)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isReturning
                          ? null
                          : () => _retournerLivre(context, bookService),
                      icon: _isReturning
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.assignment_return,
                              size: 18),
                      label: Text(_isReturning ? 'Retour en cours...' : 'Retourner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.alarm, size: 18),
                      label: const Text('Prolonger'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // BOUTON "DONNER MON AVIS" POUR LES LIVRES RETOURNÉS
              FutureBuilder<bool>(
                future: bookService.hasUserReviewedBook(
                  context.read<AuthController>().currentUser!.uid,
                  widget.loan.bookId,
                ),
                builder: (context, snapshot) {
                  final hasReviewed = snapshot.data ?? false;
                  
                  if (hasReviewed) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Vous avez déjà donné votre avis',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(context, widget.loan),
                      icon: const Icon(Icons.rate_review, size: 18),
                      label: const Text('Donner mon avis'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isWarning ? Colors.red : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _retournerLivre(BuildContext context, BookService service) async {
    setState(() => _isReturning = true);

    try {
      await service.retournerLivre(
        loanId: widget.loan.id,
        bookId: widget.loan.bookId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livre retourné avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReturning = false);
      }
    }
  }

  // Afficher le dialogue pour proposer de laisser un avis
  void _showReviewDialog(BuildContext context, LoanModel loan) async {
    // Récupérer les infos du livre
    final bookDoc = await BookService().getBookById(loan.bookId);
    if (bookDoc == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.rate_review, size: 48, color: Color(0xFF3B82F6)),
            const SizedBox(height: 16),
            const Text(
              'Partagez votre avis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Avez-vous aimé "${bookDoc.titre ?? 'ce livre'}" ?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Plus tard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            book: bookDoc,
                            loanId: loan.id,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Donner mon avis'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}