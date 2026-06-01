import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/establishment_provider.dart';
import '../services/driver_service.dart';
import '../widgets/mypet_app_bar.dart';

class EstabMotoristasScreen extends StatefulWidget {
  const EstabMotoristasScreen({super.key});

  @override
  State<EstabMotoristasScreen> createState() => _EstabMotoristasScreenState();
}

class _EstabMotoristasScreenState extends State<EstabMotoristasScreen> {
  List<DriverModel> _motoristas = [];
  bool _loading = true;
  String? _estabId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final estabProvider = context.read<EstablishmentProvider>();
    if (auth.token == null) return;

    if (estabProvider.establishmentId == null) {
      await estabProvider.loadByOwner(
        token: auth.token!,
        ownerId: auth.user!.id,
        ownerName: auth.user!.name,
        ownerPhone: auth.user!.phone,
      );
    }

    final id = estabProvider.establishmentId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    _estabId = id;

    setState(() => _loading = true);
    try {
      final list = await DriverService.fetchByEstablishment(
        token: auth.token!,
        establishmentId: id,
      );
      setState(() => _motoristas = list);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  DriverModel? get _ativo =>
      _motoristas.where((d) => d.isAtivo).firstOrNull;

  Future<void> _desativar(DriverModel driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desativar motorista?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Deseja desativar ${driver.name}? Você poderá cadastrar um novo motorista depois.'),
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
            child: const Text('Desativar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    try {
      await DriverService.deactivate(token: auth.token!, driverId: driver.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Motorista desativado com sucesso'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cadastrar() async {
    final result = await Navigator.pushNamed(
      context,
      '/motorista-cadastro',
      arguments: _estabId,
    );
    if (result != null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _ativo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Motoristas',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Apenas um motorista pode estar ativo por vez.',
                    style: TextStyle(fontSize: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 20),

                  if (ativo != null) ...[
                    _SectionLabel('Motorista ativo'),
                    const SizedBox(height: 8),
                    _DriverCard(
                      driver: ativo,
                      onDesativar: () => _desativar(ativo),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 48, color: AppColors.greyLight),
                          SizedBox(height: 10),
                          Text('Nenhum motorista ativo',
                              style: TextStyle(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Cadastre um motorista para realizar entregas',
                              style:
                                  TextStyle(color: AppColors.grey, fontSize: 13),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _cadastrar,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Cadastrar Motorista',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_motoristas.any((d) => !d.isAtivo)) ...[
                    _SectionLabel('Histórico'),
                    const SizedBox(height: 8),
                    ..._motoristas
                        .where((d) => !d.isAtivo)
                        .map((d) => _DriverCard(driver: d)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.dark),
      );
}

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback? onDesativar;
  const _DriverCard({required this.driver, this.onDesativar});

  IconData get _vehicleIcon {
    switch (driver.vehicleType) {
      case 'MOTO':
        return Icons.two_wheeler;
      case 'VAN':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: driver.isAtivo
                            ? AppColors.primaryLight
                            : AppColors.greyLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_vehicleIcon,
                          color: driver.isAtivo
                              ? AppColors.primary
                              : AppColors.grey,
                          size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.dark)),
                          Text(
                            '${driver.vehicleTypeLabel} • ${driver.vehicleModel}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: driver.isAtivo
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.greyLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        driver.isAtivo ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: driver.isAtivo
                                ? AppColors.success
                                : AppColors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.greyLight),
                const SizedBox(height: 12),
                _row(Icons.confirmation_number_outlined,
                    'Placa: ${driver.vehiclePlate}'),
                const SizedBox(height: 4),
                _row(Icons.credit_card_outlined, 'CNH: ${driver.cnh}'),
                const SizedBox(height: 4),
                _row(Icons.phone_outlined, driver.phone),
              ],
            ),
          ),
          if (onDesativar != null) ...[
            const Divider(height: 1, color: AppColors.greyLight),
            InkWell(
              onTap: onDesativar,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle_outline,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text('Desativar motorista',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Row(children: [
        Icon(icon, size: 14, color: AppColors.grey),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: AppColors.grey))),
      ]);
}
