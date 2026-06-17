import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';

class MypetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool purple;

  const MypetAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.purple = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPurple = purple;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isPurple ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: Colors.transparent,
        elevation: isPurple ? 0 : 0.5,
        shadowColor: Colors.black12,
        child: Container(
          decoration: isPurple
              ? const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7B3FF2), Color(0xFF5B2FBF)],
                  ),
                )
              : const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 1, offset: Offset(0, 0.5)),
                ]),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Voltar',
                        icon: Icon(Icons.chevron_left,
                            size: 28, color: isPurple ? Colors.white : AppColors.dark),
                        onPressed: onBack ?? () => Navigator.pop(context),
                      ),
                    ),
                  Center(
                    child: Image.asset(
                      isPurple ? 'assets/images/logo branca.png' : 'assets/images/logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (actions != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    )
                  else if (!showBack)
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 48,
                        child: Builder(builder: (ctx) {
                          final user = ctx.watch<AuthProvider>().user;
                          return Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                ctx,
                                user != null ? '/home' : '/login',
                                arguments: user != null ? 4 : null,
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: isPurple
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.primaryLight,
                                child: Icon(Icons.person,
                                    size: 18,
                                    color: isPurple ? Colors.white : AppColors.primary),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

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
          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
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
              Image.asset(
                'assets/images/logo branca.png',
                height: 36,
                fit: BoxFit.contain,
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
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.3),
      );
}
