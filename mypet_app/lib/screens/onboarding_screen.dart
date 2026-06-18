import 'package:flutter/material.dart';
import '../core/colors.dart';
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _slides = [
    _Slide(
      icon: Icons.favorite_rounded,
      iconBg: Color(0xFFEDE8FB),
      iconColor: AppColors.primary,
      title: 'O melhor para o seu pet',
      subtitle:
          'Encontre clínicas, pet shops, banho e tosa, tudo perto de você em um só lugar.',
      accent: AppColors.primary,
    ),
    _Slide(
      icon: Icons.calendar_month_rounded,
      iconBg: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
      title: 'Agende em minutos',
      subtitle:
          'Escolha o serviço, horário e profissional com apenas alguns toques.',
      accent: Color(0xFF16A34A),
    ),
    _Slide(
      icon: Icons.location_on_rounded,
      iconBg: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
      title: 'Acompanhe em tempo real',
      subtitle:
          'Saiba exatamente onde está o seu pet durante o transporte e as consultas.',
      accent: Color(0xFFD97706),
    ),
    _Slide(
      icon: Icons.verified_rounded,
      iconBg: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0284C7),
      title: 'Profissionais verificados',
      subtitle:
          'Todos os veterinários, motoristas e estabelecimentos são aprovados pela equipe MyPet.',
      accent: Color(0xFF0284C7),
    ),
  ];
  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goWelcome();
    }
  }
  void _goWelcome() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: TextButton(
                  onPressed: _goWelcome,
                  child: const Text('Pular',
                      style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? slide.accent : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        slide.accent,
                        slide.accent.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: slide.accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _next,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _page == _slides.length - 1
                                  ? 'Começar agora'
                                  : 'Próximo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final iconSz = (h * 0.40).clamp(100.0, w * 0.55);
        final innerSz = iconSz * 0.76;
        final iconIcSz = (iconSz * 0.42).clamp(40.0, 100.0);
        final gap1 = (h * 0.06).clamp(12.0, 44.0);
        final gap2 = (h * 0.025).clamp(8.0, 16.0);
        final titleFs = h < 500 ? 20.0 : 26.0;
        final subFs = h < 500 ? 13.0 : 15.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSz,
                height: iconSz,
                decoration: BoxDecoration(
                  color: slide.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: innerSz,
                      height: innerSz,
                      decoration: BoxDecoration(
                        color: slide.iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(slide.icon, size: iconIcSz, color: slide.iconColor),
                  ],
                ),
              ),
              SizedBox(height: gap1),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFs,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                  height: 1.2,
                ),
              ),
              SizedBox(height: gap2),
              Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subFs,
                  color: AppColors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _Slide {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color accent;
  const _Slide({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}
