import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

/// Header branco padrão — usado nas telas de cliente (agenda, histórico, etc.)
class MypetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const MypetAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.chevron_left,
                  size: 28, color: AppColors.dark),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: Image.asset(
        'assets/images/logo.png',
        height: 44,
        fit: BoxFit.contain,
      ),
      actions: actions ??
          [
            Builder(builder: (ctx) {
              final user = ctx.watch<AuthProvider>().user;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    ctx,
                    user != null ? '/home' : '/login',
                    arguments: user != null ? 4 : null,
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person,
                        size: 18, color: AppColors.primary),
                  ),
                ),
              );
            }),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Header roxo com gradiente — reutilizável para telas de estabelecimento.
/// Mostra logo + avatar no topo e os cards de estatísticas abaixo.
class EstabPurpleHeader extends StatelessWidget {
  final int pendentes;
  final int confirmados;
  final String avaliacao;
  final bool showBack;

  const EstabPurpleHeader({
    super.key,
    required this.pendentes,
    required this.confirmados,
    required this.avaliacao,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B3FF2), Color(0xFF5B2FBF)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 28),
                )
              else
                const SizedBox(width: 28),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('$pendentes', 'Pendentes'),
              _divider(),
              _stat('$confirmados', 'Confirmados'),
              _divider(),
              _stat(avaliacao, 'Avaliação'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1, height: 32,
        color: Colors.white.withValues(alpha: 0.3),
      );
}
