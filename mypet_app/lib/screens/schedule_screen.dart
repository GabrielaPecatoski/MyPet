import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../core/constants.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/pet.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_service.dart';
import '../services/availability_service.dart';
import '../widgets/mypet_app_bar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  PetModel? _selectedPet;
  ServiceModel? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTime;
  List<PetModel> _pets = [];
  bool _loadingPets = false;
  List<TimeSlotModel> _slots = [];
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPets());
  }

  Future<void> _loadPets() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _loadingPets = true);
    try {
      final data = await ApiService.get(
        '${ApiConstants.petsEndpoint}/${auth.user!.id}',
        token: auth.token,
      );
      final list = data as List;
      setState(() => _pets = list.map((e) => PetModel.fromJson(e)).toList());
    } catch (_) {
      // silently skip, empty list will show message
    } finally {
      setState(() => _loadingPets = false);
    }
  }

  Future<void> _loadSlots(EstablishmentModel? establishment) async {
    if (_selectedDate == null || establishment == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() { _loadingSlots = true; _selectedTime = null; _slots = []; });
    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      _slots = await AvailabilityService.getAvailability(
        token: auth.token!,
        estabId: establishment.id,
        date: dateStr,
      );
    } catch (_) {
      _slots = [];
    } finally {
      setState(() => _loadingSlots = false);
    }
  }

  List<DateTime> get _availableDates {
    final now = DateTime.now();
    return List.generate(7, (i) => now.add(Duration(days: i + 1)));
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _confirmar(EstablishmentModel? establishment) async {
    if (_selectedPet == null || _selectedService == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o pet, serviço, data e horário'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;

    final timeParts = _selectedTime!.split(':');
    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final booking = await context.read<BookingProvider>().createBooking(
          token: auth.token!,
          userId: auth.user!.id,
          userName: auth.user!.name,
          petId: _selectedPet!.id,
          petName: _selectedPet!.name,
          serviceName: _selectedService!.name,
          establishmentId: establishment?.id ?? '',
          establishmentName: establishment?.name ?? '',
          scheduledAt: scheduledAt,
          price: _selectedService!.price,
        );

    if (!mounted) return;

    if (booking != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Solicitado!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow('Pet:', _selectedPet!.name),
              _confirmRow('Serviço:', _selectedService!.name),
              _confirmRow('Data:', _formatDate(_selectedDate!)),
              _confirmRow(
                  'Valor:', 'R\$ ${_selectedService!.price.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              const Text(
                'Aguarde a confirmação do estabelecimento.',
                style: TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (r) => false,
                      arguments: 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ver Agenda',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else {
      final err = context.read<BookingProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Erro ao agendar'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _confirmRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.grey)),
            const SizedBox(width: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.dark)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final establishment =
        ModalRoute.of(context)?.settings.arguments as EstablishmentModel?;
    final booking = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selecionar pet
                _sectionTitle('Selecione o pet'),
                const SizedBox(height: 10),
                if (_loadingPets)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.primary)))
                else if (_pets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.grey),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Nenhum pet cadastrado. Cadastre um pet primeiro.',
                            style: TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/add-pet'),
                          child: const Text('Cadastrar'),
                        ),
                      ],
                    ),
                  )
                else
                  ..._pets.map((pet) => _PetSelectCard(
                        pet: pet,
                        selected: _selectedPet?.id == pet.id,
                        onTap: () => setState(() => _selectedPet = pet),
                      )),

                const SizedBox(height: 24),

                // Selecionar serviço
                _sectionTitle('Selecione o serviço'),
                const SizedBox(height: 10),
                if (establishment != null && establishment.services.isNotEmpty)
                  ...establishment.services.map((s) => _ServiceSelectCard(
                        service: s,
                        selected: _selectedService?.id == s.id,
                        onTap: () => setState(() => _selectedService = s),
                      ))
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyLight),
                    ),
                    child: const Text(
                      'Nenhum serviço disponível.',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),

                const SizedBox(height: 24),

                // Selecionar data
                _sectionTitle('Selecione a data'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  children: _availableDates.take(6).map((date) => _DateCard(
                    date: date,
                    label: _formatDate(date),
                    selected: _selectedDate == date,
                    onTap: () {
                      setState(() { _selectedDate = date; _selectedTime = null; });
                      _loadSlots(establishment);
                    },
                  )).toList(),
                ),

                if (_selectedDate != null) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Selecione o horário'),
                  const SizedBox(height: 10),
                  if (_loadingSlots)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (_slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: const Text(
                        'Sem horários disponíveis para este dia.',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      children: _slots.where((s) => s.available).map((slot) {
                        final selected = _selectedTime == slot.time;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = slot.time),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.greyLight,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot.time,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: selected ? Colors.white : AppColors.dark,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Botão fixo no rodapé
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: booking.isLoading
                      ? null
                      : () => _confirmar(establishment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: booking.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar Agendamento',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.dark),
      );
}

class _PetSelectCard extends StatelessWidget {
  final PetModel pet;
  final bool selected;
  final VoidCallback onTap;

  const _PetSelectCard(
      {required this.pet, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              child:
                  Text(pet.typeIcon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  Text('${pet.breed} • ${pet.age} anos',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ServiceSelectCard extends StatelessWidget {
  final ServiceModel service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceSelectCard(
      {required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 3),
                  if (service.description != null && service.description!.isNotEmpty)
                    Text(service.description!,
                        style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 3),
                  Text('Duração: ${service.durationMinutes} min',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'R\$ ${service.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 15),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle,
                        color: AppColors.primary, size: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.greyLight,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today,
                size: 14, color: selected ? Colors.white : AppColors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
