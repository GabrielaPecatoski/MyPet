import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../widgets/mypet_app_bar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) return;
    await context.read<DriverProfileProvider>().load(
          token: auth.token!,
          cpf: auth.user!.cpf!,
        );
  }

  Future<void> _dissociar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desassociar estabelecimento?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Você ficará disponível como motorista independente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Desassociar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final success = await context.read<DriverProfileProvider>().dissociate(
          token: auth.token!,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Desassociado com sucesso' : 'Erro ao desassociar'),
      backgroundColor: success ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vm = context.watch<DriverProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.driver))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.driver,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(auth),
                  const SizedBox(height: 20),
                  if (vm.error != null)
                    _errorCard(vm.error!)
                  else if (!vm.hasDriver)
                    _semPerfilCard()
                  else ...[
                    _driverProfileCard(vm),
                    const SizedBox(height: 16),
                    _statusCard(vm),
                    if (vm.driver!.isAssociado) ...[
                      const SizedBox(height: 16),
                      _dissociarCard(),
                    ],
                  ],
                  const SizedBox(height: 32),
                  _logoutBtn(auth),
                ],
              ),
            ),
    );
  }

  Widget _header(AuthProvider auth) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEA580C), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white24,
              child: Icon(Icons.local_shipping, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.user?.name ?? 'Motorista',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  const Text('Painel do Motorista',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _errorCard(String msg) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 10),
            Text(msg,
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.driver,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _semPerfilCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_search_outlined, size: 48, color: AppColors.greyLight),
            SizedBox(height: 12),
            Text('Perfil de motorista não encontrado',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.dark),
                textAlign: TextAlign.center),
            SizedBox(height: 6),
            Text(
              'Seu perfil de motorista ainda não foi cadastrado.',
              style: TextStyle(color: AppColors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _driverProfileCard(DriverProfileProvider vm) {
    final d = vm.driver!;
    final vehicleIcon = switch (d.vehicleType) {
      'MOTO' => Icons.two_wheeler,
      'VAN'  => Icons.airport_shuttle,
      _      => Icons.directions_car,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppColors.driver.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(vehicleIcon, color: AppColors.driver, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.dark)),
                Text('${d.vehicleTypeLabel} • ${d.vehicleModel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.greyLight),
          const SizedBox(height: 12),
          _infoRow(Icons.confirmation_number_outlined, 'Placa: ${d.vehiclePlate}'),
          const SizedBox(height: 4),
          _infoRow(Icons.credit_card_outlined, 'CNH: ${d.cnh}'),
          const SizedBox(height: 4),
          _infoRow(Icons.phone_outlined, d.phone),
        ],
      ),
    );
  }

  Widget _statusCard(DriverProfileProvider vm) {
    final d = vm.driver!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
          const SizedBox(height: 12),
          Row(children: [
            _chip(
              d.isAtivo ? Icons.check_circle_outline : Icons.cancel_outlined,
              d.isAtivo ? 'Ativo' : 'Inativo',
              d.isAtivo ? AppColors.success : AppColors.danger,
            ),
            const SizedBox(width: 12),
            _chip(
              d.isAssociado ? Icons.link : Icons.link_off,
              d.isAssociado ? 'Associado' : 'Independente',
              d.isAssociado ? AppColors.driver : AppColors.grey,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  Widget _dissociarCard() => GestureDetector(
        onTap: _dissociar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(children: [
            Icon(Icons.link_off, color: AppColors.warning, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Desassociar do estabelecimento',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.warning)),
                Text('Fique disponível como motorista independente',
                    style: TextStyle(fontSize: 12, color: AppColors.grey)),
              ]),
            ),
            Icon(Icons.chevron_right, color: AppColors.warning, size: 20),
          ]),
        ),
      );

  Widget _logoutBtn(AuthProvider auth) => GestureDetector(
        onTap: () async {
          await auth.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text('Sair',
                style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.grey))),
      ]);
}
