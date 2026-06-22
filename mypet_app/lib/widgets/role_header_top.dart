import 'package:flutter/material.dart';
import 'notification_bell.dart';

/// Faixa superior padronizada dos painéis profissionais (motorista, vet,
/// estabelecimento): logo + "MY PET · CARGO" / nome à esquerda, sino de
/// notificações e um controle opcional (status ou avatar) à direita.
class RoleHeaderTop extends StatelessWidget {
  final String roleLabel;
  final String name;
  final Widget? trailing;

  const RoleHeaderTop({
    super.key,
    required this.roleLabel,
    required this.name,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo branca.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY PET · $roleLabel',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const NotificationBell(iconSize: 24),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
