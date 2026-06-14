import 'package:flutter/material.dart';
import '../core/colors.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int? _selected;

  static const _roles = [
    _RoleData(
      tipo: 0,
      icon: Icons.pets_rounded,
      title: 'Sou Tutor',
      subtitle: 'Agende serviços e cuide bem do seu pet.',
      badge: 'Mais usado',
      badgeIcon: Icons.star_rounded,
      color: AppColors.primary,
    ),
    _RoleData(
      tipo: 1,
      icon: Icons.store_rounded,
      title: 'Estabelecimento',
      subtitle: 'Pet shop, clínica, banho e tosa.',
      badge: 'Para negócios',
      badgeIcon: Icons.business_center_rounded,
      color: Color(0xFF0EA5E9),
    ),
    _RoleData(
      tipo: 3,
      icon: Icons.medical_services_rounded,
      title: 'Sou Veterinário',
      subtitle: 'Atenda pacientes e receba chamados.',
      badge: 'Emergências 24h',
      badgeIcon: Icons.notifications_active_rounded,
      color: Color(0xFF16A34A),
    ),
    _RoleData(
      tipo: 2,
      icon: Icons.airport_shuttle_rounded,
      title: 'Sou Motorista',
      subtitle: 'Transporte pets com segurança.',
      badge: 'Ganhe dinheiro',
      badgeIcon: Icons.attach_money_rounded,
      color: Color(0xFFF97316),
    ),
  ];

  _RoleData? get _selectedRole =>
      _selected == null ? null : _roles.firstWhere((r) => r.tipo == _selected);

  String get _buttonLabel {
    if (_selected == null) return 'Continuar';
    return 'Continuar como ${_selectedRole!.title.replaceFirst('Sou ', '')}';
  }

  Color get _buttonColor => _selectedRole?.color ?? AppColors.primary;

  void _continuar() {
    if (_selected == null) return;
    Navigator.pushReplacementNamed(context, '/register', arguments: _selected);
  }

  void _login() => Navigator.pushReplacementNamed(context, '/login', arguments: -1);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final top = mq.padding.top;
    final bottom = mq.padding.bottom;
    final isMobile  = sw < 600;
    final isDesktop = sw >= 1024;
    final contentMaxW = isDesktop ? 800.0 : isMobile ? double.infinity : 600.0;
    final crossCount = isDesktop ? 4 : 2;
    final headerH = isMobile ? sh * 0.26 : isDesktop ? 220.0 : 230.0;
    final titleFs   = isDesktop ? 28.0 : isMobile ? 22.0 : 25.0;
    final subtitleFs = isDesktop ? 14.0 : isMobile ? 12.0 : 13.0;
    final logoSz    = isDesktop ? 88.0 : isMobile ? 68.0 : 76.0;
    final sectionFs = isDesktop ? 20.0 : isMobile ? 16.0 : 18.0;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: headerH,
              padding: EdgeInsets.fromLTRB(24, top + 16, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5228D8), Color(0xFF9D6AEE)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo branca.png',
                    width: logoSz,
                    height: logoSz,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'MyPet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFs,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'O melhor para o seu pet, na palma da sua mão.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: subtitleFs,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isDesktop ? 28 : 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Como você quer usar o app?',
                              style: TextStyle(
                                fontSize: sectionFs,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Selecione o seu perfil para começar.',
                              style: TextStyle(
                                fontSize: subtitleFs,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 20 : 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LayoutBuilder(
                            builder: (ctx, box) {
                              final spacing = isDesktop ? 16.0 : isMobile ? 8.0 : 12.0;
                              final numRows = (crossCount == 4) ? 1 : 2;
                              final colW = (box.maxWidth - spacing * (crossCount - 1)) / crossCount;
                              final rowH = (box.maxHeight - spacing * (numRows - 1)) / numRows;
                              final ratio = (colW / rowH).clamp(0.60, 2.0);
                              return GridView.count(
                                crossAxisCount: crossCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: ratio,
                                physics: const NeverScrollableScrollPhysics(),
                                children: _roles
                                    .map((r) => _RoleCard(
                                          data: r,
                                          selected: _selected == r.tipo,
                                          onTap: () => setState(
                                              () => _selected = r.tipo),
                                          size: isDesktop
                                              ? _CardSize.large
                                              : isMobile
                                                  ? _CardSize.small
                                                  : _CardSize.medium,
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            24, isDesktop ? 20 : 10, 24, 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: isDesktop ? 56 : 52,
                          decoration: BoxDecoration(
                            gradient: _selected != null
                                ? LinearGradient(
                                    colors: [
                                      _darken(_buttonColor, 0.1),
                                      _buttonColor,
                                    ],
                                  )
                                : null,
                            color: _selected == null
                                ? AppColors.greyLight
                                : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _selected != null
                                ? [
                                    BoxShadow(
                                      color: _buttonColor.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    )
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _selected != null ? _continuar : null,
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _buttonLabel,
                                      style: TextStyle(
                                        color: _selected != null
                                            ? Colors.white
                                            : AppColors.grey,
                                        fontSize: isDesktop ? 16 : 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_selected != null) ...[
                                      const SizedBox(width: 6),
                                      const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: bottom + 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Já tem uma conta? ',
                                style: TextStyle(
                                    color: AppColors.grey,
                                    fontSize: isDesktop ? 15 : 14)),
                            GestureDetector(
                              onTap: _login,
                              child: Text(
                                'Entrar',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: isDesktop ? 15 : 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

enum _CardSize { small, medium, large }

class _RoleData {
  final int tipo;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final IconData badgeIcon;
  final Color color;

  const _RoleData({
    required this.tipo,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeIcon,
    required this.color,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleData data;
  final bool selected;
  final VoidCallback onTap;
  final _CardSize size;

  const _RoleCard({
    required this.data,
    required this.selected,
    required this.onTap,
    this.size = _CardSize.medium,
  });

  double get _pad    => size == _CardSize.large ? 18 : size == _CardSize.small ? 10 : 14;
  double get _iconSz => size == _CardSize.large ? 52 : size == _CardSize.small ? 36 : 44;
  double get _iconIc => size == _CardSize.large ? 26 : size == _CardSize.small ? 18 : 22;
  double get _radio  => size == _CardSize.large ? 24 : size == _CardSize.small ? 18 : 22;
  double get _titleFs => size == _CardSize.large ? 15 : size == _CardSize.small ? 12 : 13.5;
  double get _subFs  => size == _CardSize.large ? 12 : size == _CardSize.small ? 10 : 11;
  double get _badgeFs => size == _CardSize.large ? 11 : size == _CardSize.small ? 8.5 : 9.5;
  double get _badgeIc => size == _CardSize.large ? 12 : size == _CardSize.small ? 9 : 10;

  @override
  Widget build(BuildContext context) {
    final accent = data.color;
    final accentLight = accent.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(_pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _iconSz,
                  height: _iconSz,
                  decoration: BoxDecoration(
                    color: selected
                        ? accentLight
                        : AppColors.greyLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(size == _CardSize.large ? 14 : 12),
                  ),
                  child: Icon(
                    data.icon,
                    color: selected ? accent : AppColors.grey,
                    size: _iconIc,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _radio,
                  height: _radio,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? accent : AppColors.greyLight,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded,
                          color: Colors.white, size: _radio * 0.6)
                      : null,
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _titleFs,
                color: selected ? accent : AppColors.dark,
              ),
            ),
            SizedBox(height: size == _CardSize.small ? 2 : 4),
            Text(
              data.subtitle,
              style: TextStyle(
                  fontSize: _subFs, color: AppColors.grey, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: size == _CardSize.small ? 5 : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size == _CardSize.large ? 9 : 7,
                vertical: size == _CardSize.large ? 5 : 3,
              ),
              decoration: BoxDecoration(
                color: accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.badgeIcon, size: _badgeIc, color: accent),
                  SizedBox(width: size == _CardSize.large ? 5 : 3),
                  Flexible(
                    child: Text(
                      data.badge,
                      style: TextStyle(
                        fontSize: _badgeFs,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
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
