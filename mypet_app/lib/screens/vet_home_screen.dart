import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../models/emergency_call.dart';
import '../providers/auth_provider.dart';
import '../providers/vet_profile_provider.dart';
import '../services/sse/sse_client.dart';
import '../services/veterinarian_service.dart';

class VetHomeScreen extends StatefulWidget {
  const VetHomeScreen({super.key});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen> {
  static const _green     = Color(0xFF16A34A);
  static const _greenDark = Color(0xFF0F7A35);
  static const _orange    = Color(0xFFF97316);

  Timer? _pollTimer;
  SseSubscription? _sse;
  bool _alarmVisible = false;
  EmergencyCallModel? _incomingCall;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sse?.close();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) return;
    await context.read<VetProfileProvider>().load(
          token: auth.token!,
          cpf: auth.user!.cpf!,
        );
    _resetPollTimer();
  }

  void _resetPollTimer() {
    _pollTimer?.cancel();
    _sse?.close();
    _sse = null;
    final vm = context.read<VetProfileProvider>();
    if (!vm.atende24h || vm.vet == null) return;

    _connectSse();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkEmergencyCalls());
    _checkEmergencyCalls();
  }

  void _connectSse() {
    final auth = context.read<AuthProvider>();
    final vm = context.read<VetProfileProvider>();
    if (auth.token == null || vm.vet == null) return;
    final url =
        '${ApiConstants.baseUrl}/notifications/stream/${vm.vet!.id}?token=${auth.token}';
    _sse = connectSse(url, (data) {
      try {
        final event = jsonDecode(data) as Map<String, dynamic>;
        if (event['type'] == 'EMERGENCY_VET_CALL') _checkEmergencyCalls();
      } catch (_) {}
    });
  }

  Future<void> _checkEmergencyCalls() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null || vm.vet == null) return;
    if (_alarmVisible) return;

    final calls = await VeterinarianService.getPendingEmergencyCalls(
      token: auth.token!,
      vetId: vm.vet!.id,
    );

    if (calls.isNotEmpty && mounted && !_alarmVisible) {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
      setState(() {
        _incomingCall = calls.first;
        _alarmVisible = true;
      });
    }
  }

  Future<void> _dismissAlarm({required bool accept}) async {
    final call = _incomingCall;
    if (call == null) return;
    setState(() {
      _alarmVisible = false;
      _incomingCall = null;
    });
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      await VeterinarianService.acknowledgeEmergencyCall(
        token: auth.token!,
        callId: call.id,
      );
    }
    if (accept && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ligue para ${call.callerPhone} para atender a emergência.'),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ));
    }
  }

  Future<void> _toggleDisponivel() async {
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null) return;
    if (!vm.disponivel && !vm.isAprovado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aguardando aprovação do administrador para ficar disponível.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await vm.updateAvailability(token: auth.token!, disponivel: !vm.disponivel);
    if (!ok && mounted && vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error!),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _toggleEmergencia24h() async {
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null) return;
    if (!vm.isAprovado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aguardando aprovação do administrador para alterar disponibilidade.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await vm.updateAvailability(token: auth.token!, atende24h: !vm.atende24h);
    _resetPollTimer();
  }

  Future<void> _toggleDomicilio() async {
    final auth = context.read<AuthProvider>();
    final vm   = context.read<VetProfileProvider>();
    if (auth.token == null) return;
    if (!vm.isAprovado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aguardando aprovação do administrador para alterar disponibilidade.'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await vm.updateAvailability(token: auth.token!, atendeDomicilio: !vm.atendeDomicilio);
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

    return Stack(
      children: [
        Scaffold(
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
                        icon: Icons.check_circle_outline,
                        color: _green,
                        titleOn: 'Disponível para atendimento',
                        titleOff: vm.isAprovado ? 'Indisponível' : 'Aguardando aprovação do admin',
                        subtitleOn: 'Você aparece como serviço para os clientes',
                        subtitleOff: vm.isAprovado
                            ? 'Ative para aparecer aos clientes'
                            : 'O administrador precisa aprovar seu cadastro',
                        value: vm.disponivel,
                        updating: vm.updating,
                        onToggle: _toggleDisponivel,
                      ),
                      const SizedBox(height: 14),
                      _ToggleCard(
                        icon: Icons.notifications_active_outlined,
                        color: AppColors.danger,
                        titleOn: 'Atender emergências 24h',
                        titleOff: 'Emergências 24h desativado',
                        subtitleOn: 'Você aparece na lista de emergências',
                        subtitleOff: 'Ative para receber chamados urgentes',
                        value: vm.atende24h,
                        updating: vm.updating,
                        onToggle: _toggleEmergencia24h,
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
        ),

        if (_alarmVisible && _incomingCall != null)
          _EmergencyAlarmOverlay(
            call: _incomingCall!,
            onAccept: () => _dismissAlarm(accept: true),
            onDecline: () => _dismissAlarm(accept: false),
          ),
      ],
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


class _EmergencyAlarmOverlay extends StatefulWidget {
  final EmergencyCallModel call;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _EmergencyAlarmOverlay({
    required this.call,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_EmergencyAlarmOverlay> createState() => _EmergencyAlarmOverlayState();
}

class _EmergencyAlarmOverlayState extends State<_EmergencyAlarmOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  final AudioPlayer _siren = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _vibrateRepeat();
    _playSiren();
  }

  Future<void> _playSiren() async {
    try {
      await _siren.setReleaseMode(ReleaseMode.loop);
      await _siren.play(AssetSource('sounds/alarm.wav'), volume: 1.0);
    } catch (_) {}
  }

  Future<void> _vibrateRepeat() async {
    for (int i = 0; i < 6; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _siren.stop();
    _siren.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emergency, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'EMERGÊNCIA!',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chamado de atendimento urgente',
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  _alarmRow(Icons.person_outline, call.callerName),
                  const SizedBox(height: 12),
                  _alarmRow(Icons.phone_outlined, call.callerPhone),
                  if (call.petDescription != null && call.petDescription!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _alarmRow(Icons.pets, call.petDescription!),
                  ],
                ]),
              ),
              const SizedBox(height: 40),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onDecline,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAccept,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Atender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alarmRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white60, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
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
    return GestureDetector(
      onTap: updating ? null : onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
    ),
    );
  }
}
