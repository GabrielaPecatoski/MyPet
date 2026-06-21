import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/establishment.dart';
import '../models/veterinarian.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/mypet_app_bar.dart';

class EmergenciaScreen extends StatefulWidget {
  const EmergenciaScreen({super.key});

  @override
  State<EmergenciaScreen> createState() => _EmergenciaScreenState();
}

class _EmergenciaScreenState extends State<EmergenciaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token ?? '';
    await context.read<EmergencyProvider>().loadAll(token: token);
  }

  Future<void> _callVet(VeterinarianModel vet) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final callerName = auth.user?.name ?? 'Cliente';
    final petCtrl = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CallVetSheet(
        vetName: vet.name,
        petCtrl: petCtrl,
      ),
    );

    if (confirmed != true || !mounted) return;

    HapticFeedback.heavyImpact();
    final ok = await context.read<EmergencyProvider>().callVet(
          token: token,
          vetId: vet.id,
          callerName: callerName,
          petDescription:
              petCtrl.text.trim().isEmpty ? null : petCtrl.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chamado enviado! O veterinário foi alertado.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao enviar chamado. Tente ligar diretamente.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EmergencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: Column(
        children: [
          _EmergencyHeader(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.danger,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.danger,
              tabs: const [
                Tab(text: 'Clínicas / Pet shops'),
                Tab(text: 'Veterinários'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _tabEstabs(vm),
                _tabVets(vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabEstabs(EmergencyProvider vm) {
    if (vm.loadingEstabs) {
      return const Center(child: CircularProgressIndicator(color: AppColors.danger));
    }
    if (vm.errorEstabs != null) {
      return _errorView(vm.errorEstabs!, () => context.read<EmergencyProvider>().loadEstabs());
    }
    if (vm.establishments.isEmpty) {
      return _emptyView(
        'Nenhuma clínica disponível',
        'No momento, nenhuma clínica está cadastrada para emergências.',
        Icons.local_hospital_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.danger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vm.establishments.length,
        itemBuilder: (ctx, i) => _EmergencyCard(establishment: vm.establishments[i]),
      ),
    );
  }

  Widget _tabVets(EmergencyProvider vm) {
    if (vm.loadingVets) {
      return const Center(child: CircularProgressIndicator(color: AppColors.danger));
    }
    if (vm.errorVets != null) {
      return _errorView(vm.errorVets!, () {
        final token = context.read<AuthProvider>().token ?? '';
        context.read<EmergencyProvider>().loadVets(token: token);
      });
    }
    final vets24h = vm.vets.where((v) => v.atende24h).toList();
    if (vets24h.isEmpty) {
      return _emptyView(
        'Nenhum veterinário 24h disponível',
        'No momento, nenhum veterinário está disponível para emergências 24h.',
        Icons.medical_services_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.danger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vets24h.length,
        itemBuilder: (ctx, i) => _VetEmergencyCard(
          vet: vets24h[i],
          onCall: () => _callVet(vets24h[i]),
        ),
      ),
    );
  }

  Widget _errorView(String msg, VoidCallback retry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: AppColors.greyLight),
              const SizedBox(height: 12),
              Text(msg,
                  style: const TextStyle(color: AppColors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Tentar novamente',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger, elevation: 0),
              ),
            ],
          ),
        ),
      );

  Widget _emptyView(String title, String subtitle, IconData icon) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.danger, size: 36),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark)),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _EmergencyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(color: AppColors.danger),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.emergency, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text('Emergência Veterinária',
                style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          const Text('Encontre atendimento de urgência para o seu pet',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Em caso de urgência, ligue diretamente para o profissional.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EstablishmentModel establishment;
  const _EmergencyCard({required this.establishment});

  @override
  Widget build(BuildContext context) {
    final e = establishment;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/establishment', arguments: e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                PhotoBox(
                  url: e.imageUrl,
                  size: 56,
                  background: AppColors.danger.withValues(alpha: 0.1),
                  fallback: const Icon(Icons.local_hospital,
                      color: AppColors.danger, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                    const SizedBox(height: 3),
                    Text(e.typeLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    if (e.address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(e.address,
                              style: const TextStyle(fontSize: 12, color: AppColors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                  ]),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grey),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(children: [
                if (e.atendimento24h)
                  _badge(Icons.access_time_filled, '24 horas', AppColors.primary),
                if (e.atendimento24h && e.crmv != null) const SizedBox(width: 8),
                if (e.crmv != null && e.crmv!.isNotEmpty)
                  _badge(Icons.badge_outlined, e.crmv!, const Color(0xFF388E3C)),
                const Spacer(),
                if (e.rating > 0)
                  Row(children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 3),
                    Text(e.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark)),
                    Text(' (${e.reviewCount})',
                        style: const TextStyle(fontSize: 11, color: AppColors.grey)),
                  ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _VetEmergencyCard extends StatelessWidget {
  final VeterinarianModel vet;
  final VoidCallback onCall;
  const _VetEmergencyCard({required this.vet, required this.onCall});

  static const _green = Color(0xFF16A34A);
  static const _orange = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: [
      Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        PhotoBox(
          url: vet.photoUrl,
          size: 52,
          background: _green.withValues(alpha: 0.1),
          fallback: const Icon(Icons.medical_services_rounded,
              color: _green, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. ${vet.name}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.badge_outlined, size: 12, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(vet.crmv,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ]),
            if (vet.especialidade != null && vet.especialidade!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(vet.especialidade!,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(vet.phone,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('Disponível',
                  style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (vet.atendeDomicilio) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.home_outlined, size: 11, color: _orange),
                SizedBox(width: 3),
                Text('Domiciliar',
                    style: TextStyle(
                        fontSize: 10, color: _orange, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          if (vet.isAssociado) ...[
            const SizedBox(height: 6),
            const Row(children: [
              Icon(Icons.store_outlined, size: 11, color: AppColors.grey),
              SizedBox(width: 3),
              Text('Vinculado',
                  style: TextStyle(fontSize: 10, color: AppColors.grey)),
            ]),
          ],
        ]),
      ]),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.emergency, size: 18),
          label: const Text('Chamar veterinário'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ),
  ]),
  );
  }
}


class _CallVetSheet extends StatelessWidget {
  final String vetName;
  final TextEditingController petCtrl;

  const _CallVetSheet({
    required this.vetName,
    required this.petCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emergency, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chamar veterinário', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.dark)),
                Text('Dr. $vetName', style: const TextStyle(fontSize: 13, color: AppColors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: petCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Descreva a situação do pet (opcional)',
              prefixIcon: const Icon(Icons.pets_outlined, color: AppColors.grey, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.emergency, size: 18),
              label: const Text('Enviar chamado de emergência'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
