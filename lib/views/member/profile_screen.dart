import '../../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Non connecté')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F8),
      body: CustomScrollView(
        slivers: [
          // ── App Bar avec avatar ─────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.orange,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              (user.nom.isNotEmpty ? user.nom[0] : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats du membre ─────────────────────
                  _SectionTitle(title: '📊 Mes statistiques'),
                  const SizedBox(height: 12),
                  _StatsGrid(userId: user.uid),

                  const SizedBox(height: 24),

                  // ── Infos du compte ─────────────────────
                  _SectionTitle(title: '👤 Informations'),
                  const SizedBox(height: 12),
                  _InfoCard(user: user),

                  const SizedBox(height: 24),

                  // ── Badge membre depuis ─────────────────
                  _SectionTitle(title: '🏅 Ancienneté'),
                  const SizedBox(height: 12),
                  _AncienneteCard(dateInscription: user.dateInscription),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

// ── Stats Grid ─────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final String userId;
  const _StatsGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _loadStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final stats = snapshot.data ?? {};

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatTile(
              icon: Icons.book_outlined,
              label: 'En cours',
              value: stats['enCours'] ?? 0,
              color: const Color(0xFF3B82F6),
            ),
            _StatTile(
              icon: Icons.check_circle_outline,
              label: 'Retournés',
              value: stats['retournes'] ?? 0,
              color: const Color(0xFF22C55E),
            ),
            _StatTile(
              icon: Icons.rate_review_outlined,
              label: 'Avis donnés',
              value: stats['avis'] ?? 0,
              color: const Color(0xFFF97316),
            ),
            _StatTile(
              icon: Icons.menu_book_outlined,
              label: 'Total emprunts',
              value: stats['total'] ?? 0,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats(String userId) async {
    final db = BookService();
    final authService = AuthService();

    // Emprunts en cours
    final statsMap = await db.getMemberStats(userId);
    // Avis donnés
    final avisCount = await authService.getReviewCount(userId);
    // Total (en cours + retournés)
    final total =
        (statsMap['enCours'] ?? 0) + (statsMap['retournés'] ?? 0);

    return {
      'enCours': statsMap['enCours'] ?? 0,
      'retournes': statsMap['retournés'] ?? 0,
      'avis': avisCount,
      'total': total,
    };
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final dynamic user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Nom',
            value: user.nom ?? '—',
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email ?? '—',
          ),
          if (user.phone != null && user.phone!.isNotEmpty) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: user.phone!,
            ),
          ],
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Rôle',
            value: user.role == 'admin' ? '🛡️ Administrateur' : '👤 Membre',
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.circle,
            label: 'Statut',
            value: user.status == 'active'
                ? '✅ Actif'
                : user.status == 'pending'
                    ? '⏳ En attente'
                    : '🚫 Suspendu',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Ancienneté Card ────────────────────────────────────────────
class _AncienneteCard extends StatelessWidget {
  final DateTime dateInscription;
  const _AncienneteCard({required this.dateInscription});

  @override
  Widget build(BuildContext context) {
    final jours = DateTime.now().difference(dateInscription).inDays;
    final mois = (jours / 30).floor();
    final ans = (jours / 365).floor();

    String duree;
    if (ans > 0) {
      duree = '$ans an${ans > 1 ? 's' : ''}';
    } else if (mois > 0) {
      duree = '$mois mois';
    } else {
      duree = '$jours jour${jours > 1 ? 's' : ''}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Membre depuis $duree',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inscrit le ${dateInscription.day.toString().padLeft(2, '0')}/'
                '${dateInscription.month.toString().padLeft(2, '0')}/'
                '${dateInscription.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}