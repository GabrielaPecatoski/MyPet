import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/vet_profile_provider.dart';
import '../models/veterinarian.dart';
import '../widgets/mypet_app_bar.dart';

class VetPerfilScreen extends StatefulWidget {
  const VetPerfilScreen({super.key});

  @override
  State<VetPerfilScreen> createState() => _VetPerfilScreenState();
}

class _VetPerfilScreenState extends State<VetPerfilScreen> {
  static const _green = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.cpf == null) return;
    await context
        .read<VetProfileProvider>()
        .load(token: auth.token!, cpf: auth.user!.cpf!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vetProfile = context.watch<VetProfileProvider>();
    final vet = vetProfile.vet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: false),
      body: vetProfile.loading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              onRefresh: _load,
              color: _green,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _profileCard(auth, vet),
                  const SizedBox(height: 16),
                  _statsCard(),
                  const SizedBox(height: 16),
                  _infoSection(vet),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined,
                          color: _green),
                      title: const Text('Meus endereços',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark)),
                      subtitle: Text('${auth.user?.addresses.length ?? 0} cadastrado(s)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey)),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.grey),
                      onTap: () =>
                          Navigator.pushNamed(context, '/enderecos'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _logoutButton(auth),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _profileCard(AuthProvider auth, VeterinarianModel? vet) {
    final name = auth.user?.name ?? 'Veterinário';
    final email = auth.user?.email ?? '';
    final phone = auth.user?.phone ?? '';
    final initials = name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
    final crmv = vet?.crmv;
    final esp = vet?.especialidade;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _green.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      color: _green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppColors.dark)),
                const SizedBox(height: 3),
                if (crmv != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${esp != null && esp.isNotEmpty ? esp : 'Clínica geral'} · $crmv',
                      style: const TextStyle(
                          fontSize: 11,
                          color: _green,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (email.isNotEmpty)
                  Text(email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey)),
                if (phone.isNotEmpty)
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
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
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            _statItem(Icons.pets, _green, '0', 'Pacientes'),
            _divider(),
            _statItem(Icons.star_rounded, AppColors.warning, '—', 'Avaliação'),
            _divider(),
            _statItem(Icons.calendar_month_outlined, AppColors.grey, '—', 'Desde'),
          ],
        ),
      );

  Widget _statItem(IconData icon, Color color, String value, String label) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.dark)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.grey)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.greyLight);

  Widget _infoSection(VeterinarianModel? vet) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            _infoTile(
              icon: Icons.badge_outlined,
              iconColor: _green,
              title: 'Registro CRMV',
              subtitle: '${vet?.crmv ?? 'CRMV-SP 12345'} — verificado',
            ),
            const Divider(height: 1, indent: 56, color: AppColors.divider),
            _infoTile(
              icon: Icons.medical_information_outlined,
              iconColor: AppColors.vet,
              title: 'Especialidades',
              subtitle: vet?.especialidade?.isNotEmpty == true
                  ? vet!.especialidade!
                  : 'Clínica geral',
            ),
            const Divider(height: 1, indent: 56, color: AppColors.divider),
            _infoTile(
              icon: Icons.schedule_outlined,
              iconColor: AppColors.warning,
              title: 'Horários de atendimento',
              subtitle: 'Configure seus horários no painel',
            ),
            const Divider(height: 1, indent: 56, color: AppColors.divider),
            _infoTile(
              icon: Icons.settings_outlined,
              iconColor: AppColors.grey,
              title: 'Configurações',
              subtitle: 'Notificações, privacidade',
            ),
          ],
        ),
      );

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.dark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.greyLight, size: 20),
          ],
        ),
      );

  Widget _logoutButton(AuthProvider auth) => GestureDetector(
        onTap: () async {
          await auth.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.danger, size: 18),
              SizedBox(width: 8),
              Text('Sair da conta',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
