import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/vet_profile_provider.dart';

class VetHomeScreen extends StatefulWidget {
  const VetHomeScreen({super.key});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen> {
  static const _green     = Color(0xFF16A34A);
  static const _greenDark = Color(0xFF0F7A35);
  static const _orange    = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) return;
    await context.read<VetProfileProvider>().load(
          token: auth.token!,
          cpf: auth.user!.cpf!,
        );
  }

  Future<void> _toggleDisponivel() async {
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null) return;
    await vm.updateAvailability(
      token: auth.token!,
      disponivel: !vm.disponivel,
      atendeDomicilio: vm.atendeDomicilio,
    );
  }

  Future<void> _toggleDomicilio() async {
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null) return;
    await vm.updateAvailability(
      token: auth.token!,
      disponivel: vm.disponivel,
      atendeDomicilio: !vm.atendeDomicilio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vm   = context.watch<VetProfileProvider>();
    final top  = MediaQuery.of(context).padding.top;

    if (vm.loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: _green,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _topHeader(auth, vm, top),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _statsCard(),
                  const SizedBox(height: 14),
                  _ToggleCard(
                    icon: Icons.notifications_active_outlined,
                    color: _green,
                    titleOn: 'Atender emergências 24h',
                    titleOff: 'Indisponível para chamados',
                    subtitleOn: 'Você pode receber chamados urgentes',
                    subtitleOff: 'Ative para receber emergências',
                    value: vm.disponivel,
                    updating: vm.updating,
                    onToggle: _toggleDisponivel,
                  ),
                  if (vm.hasVet) ...[
                    const SizedBox(height: 14),
                    _perfilCard(vm),
                  ],
                  const SizedBox(height: 14),
                  _ToggleCard(
                    icon: Icons.home_outlined,
                    color: _orange,
                    titleOn: 'Atendimento domiciliar ativo',
                    titleOff: 'Atendimento domiciliar inativo',
                    subtitleOn: 'Clientes podem solicitar visita em casa',
                    subtitleOff: 'Ative para oferecer consultas em domicílio',
                    value: vm.atendeDomicilio,
                    updating: vm.updating,
                    onToggle: _toggleDomicilio,
                  ),
                  const SizedBox(height: 14),
                  _consultasCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader(AuthProvider auth, VetProfileProvider vm, double top) {
    final firstName = (auth.user?.name ?? 'Veterinário').split(' ').first;
    final profilePhoto = auth.user?.photoPath;
    final crmv = vm.vet?.crmv;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, _green],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.medical_services_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MY PET · VETERINÁRIO',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.8)),
                Text('Início',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggleDisponivel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    vm.disponivel ? Icons.circle : Icons.circle_outlined,
                    size: 8,
                    color: vm.disponivel ? const Color(0xFF4ADE80) : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    vm.disponivel ? 'Disponível' : 'Indisponível',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: profilePhoto != null && !kIsWeb
                  ? ClipOval(
                      child: Image.file(File(profilePhoto),
                          width: 44, height: 44, fit: BoxFit.cover))
                  : const Icon(Icons.medical_services_outlined,
                      color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Olá, Dr. $firstName',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    vm.disponivel
                        ? 'Disponível para chamados 24h'
                        : 'Indisponível para chamados',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (crmv != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.badge_outlined, color: Colors.white70, size: 13),
                  const SizedBox(width: 5),
                  Text(crmv,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _statsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(Icons.calendar_today_outlined, AppColors.vet, '0', 'Consultas hoje'),
            _vDivider(),
            _stat(Icons.notification_important_outlined, AppColors.warning, '0', 'Chamados'),
            _vDivider(),
            _stat(Icons.attach_money, _green, 'R\$ 0', 'Faturamento'),
            _vDivider(),
            _stat(Icons.star_rounded, const Color(0xFFFBBF24), '—', 'Avaliação'),
          ],
        ),
      );

  Widget _stat(IconData icon, Color color, String value, String label) => Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.dark)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.grey),
              textAlign: TextAlign.center),
        ],
      );

  Widget _vDivider() => Container(width: 1, height: 36, color: AppColors.greyLight);

  Widget _perfilCard(VetProfileProvider vm) {
    final v = vm.vet!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meu perfil',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
          const SizedBox(height: 12),
          _infoRow(Icons.badge_outlined, 'CRMV: ${v.crmv}'),
          if (v.especialidade != null && v.especialidade!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.local_hospital_outlined, 'Especialidade: ${v.especialidade}'),
          ],
          const SizedBox(height: 6),
          _infoRow(Icons.phone_outlined, v.phone),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);

  Widget _consultasCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.event_note_outlined, size: 26, color: _green),
            ),
            const SizedBox(height: 10),
            const Text('Próximas consultas',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.dark)),
            const SizedBox(height: 4),
            const Text('Nenhuma consulta agendada para hoje.',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: _green),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: const Text('Ver agenda',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titleOn, titleOff, subtitleOn, subtitleOff;
  final bool value, updating;
  final VoidCallback onToggle;

  const _ToggleCard({
    required this.icon, required this.color,
    required this.titleOn, required this.titleOff,
    required this.subtitleOn, required this.subtitleOff,
    required this.value, required this.updating, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (value ? color : AppColors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: value ? color : AppColors.grey, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value ? titleOn : titleOff,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: value ? color : AppColors.grey)),
              const SizedBox(height: 2),
              Text(value ? subtitleOn : subtitleOff,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ),
        updating
            ? SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(color: color, strokeWidth: 2.5))
            : GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48, height: 28,
                  decoration: BoxDecoration(
                    color: value ? color : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
      ]),
    );
  }
}
