import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/pet.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/pagamento_provider.dart';
import '../providers/pet_provider.dart';
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

  static const _weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPets());
  }

  Future<void> _loadPets() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user == null) return;
    setState(() => _loadingPets = true);
    await context.read<PetProvider>().load(auth.user!.id, token: auth.token);
    setState(() {
      _pets = context.read<PetProvider>().pets.toList();
      _loadingPets = false;
    });
  }

  Future<void> _loadSlots(EstablishmentModel? establishment) async {
    if (_selectedDate == null || establishment == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() {
      _loadingSlots = true;
      _selectedTime = null;
      _slots = [];
    });
    try {
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
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
    return List.generate(14, (i) => DateTime(now.year, now.month, now.day + i));
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _confirmar(EstablishmentModel? establishment) async {
    if (_selectedPet == null ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
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

    final dateFormatted =
        '${_weekdays[_selectedDate!.weekday % 7]}, ${_selectedDate!.day} ${_months[_selectedDate!.month - 1]}';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingPaymentSheet(
        pet: _selectedPet!,
        service: _selectedService!,
        scheduledAt: scheduledAt,
        selectedTime: _selectedTime!,
        formattedDate: dateFormatted,
        establishment: establishment,
      ),
    );

    if (!mounted || result == null) return;

    final payStatus = result['status'] as String? ?? '';

    if (payStatus == 'APPROVED') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Agendado!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow('Pet:', _selectedPet!.name),
              _confirmRow('Serviço:', _selectedService!.name),
              _confirmRow('Data:', dateFormatted),
              _confirmRow('Horário:', _selectedTime!),
              _confirmRow('Valor:', 'R\$ ${_selectedService!.price.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              const Text(
                'Pagamento aprovado! Aguarde a confirmação do estabelecimento.',
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
                      context, '/home', (r) => false, arguments: 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ver Agenda', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else if (payStatus == 'PENDING') {
      final pixKey = result['pixKey'] as String?;
      final boletoCode = result['boletoCode'] as String?;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text('Aguardando Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow('Pet:', _selectedPet!.name),
              _confirmRow('Serviço:', _selectedService!.name),
              _confirmRow('Data:', dateFormatted),
              _confirmRow('Horário:', _selectedTime!),
              _confirmRow('Valor:', 'R\$ ${_selectedService!.price.toStringAsFixed(2)}'),
              if (pixKey != null) ...[
                const SizedBox(height: 10),
                const Text('Chave Pix:', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                const SizedBox(height: 2),
                SelectableText(pixKey,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.dark)),
              ],
              if (boletoCode != null) ...[
                const SizedBox(height: 10),
                const Text('Código do Boleto:', style: TextStyle(fontSize: 12, color: AppColors.grey)),
                const SizedBox(height: 2),
                SelectableText(boletoCode,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.dark)),
              ],
              const SizedBox(height: 8),
              const Text(
                'Agendamento criado. Pague para confirmar o serviço.',
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
                      context, '/home', (r) => false, arguments: 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Ok, entendi', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
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
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.dark)),
            ),
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
                _sectionTitle('Selecione o pet'),
                const SizedBox(height: 10),
                if (_loadingPets)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.primary)))
                else if (_pets.isEmpty)
                  GestureDetector(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (r) => false,
                        arguments: 3),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.pets, color: AppColors.primary, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nenhum pet cadastrado',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark,
                                      fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Toque aqui para cadastrar seu pet primeiro',
                                  style: TextStyle(
                                      color: AppColors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.primary, size: 22),
                        ],
                      ),
                    ),
                  )
                else
                  ..._pets.map((pet) => _PetSelectCard(
                        pet: pet,
                        selected: _selectedPet?.id == pet.id,
                        onTap: () => setState(() => _selectedPet = pet),
                      )),

                const SizedBox(height: 24),

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

                _sectionTitle('Selecione a data'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableDates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final date = _availableDates[i];
                      final today = _isToday(date);
                      final selected = _selectedDate?.day == date.day &&
                          _selectedDate?.month == date.month &&
                          _selectedDate?.year == date.year;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedTime = null;
                          });
                          _loadSlots(establishment);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 60,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : today
                                    ? AppColors.primaryLight
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : today
                                      ? AppColors.primary
                                          .withValues(alpha: 0.4)
                                      : AppColors.greyLight,
                              width: selected ? 2 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]
                                : [
                                    const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 1))
                                  ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                today ? 'Hoje' : _weekdays[date.weekday % 7],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: today
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : today
                                          ? AppColors.primary
                                          : AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : today
                                          ? AppColors.primary
                                          : AppColors.dark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _months[date.month - 1],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selected
                                      ? Colors.white70
                                      : AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_selectedDate != null) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('Selecione o horário'),
                  const SizedBox(height: 10),
                  if (_loadingSlots)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
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
                    _SlotGrid(
                      slots: _slots,
                      selectedTime: _selectedTime,
                      selectedDate: _selectedDate!,
                      onSelect: (t) => setState(() => _selectedTime = t),
                    ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

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
                          'Ir para Pagamento',
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

class _SlotGrid extends StatelessWidget {
  final List<TimeSlotModel> slots;
  final String? selectedTime;
  final DateTime selectedDate;
  final ValueChanged<String> onSelect;

  const _SlotGrid({
    required this.slots,
    required this.selectedTime,
    required this.selectedDate,
    required this.onSelect,
  });

  int _hour(String time) => int.tryParse(time.split(':')[0]) ?? 0;
  int _minute(String time) => int.tryParse(time.split(':').elementAtOrNull(1) ?? '0') ?? 0;

  bool _isPast(String time) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    if (!isToday) return false;
    final h = _hour(time);
    final m = _minute(time);
    return h < now.hour || (h == now.hour && m <= now.minute);
  }

  @override
  Widget build(BuildContext context) {
    final manha = slots.where((s) => _hour(s.time) < 12).toList();
    final tarde = slots.where((s) => _hour(s.time) >= 12 && _hour(s.time) < 18).toList();
    final noite = slots.where((s) => _hour(s.time) >= 18).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (manha.isNotEmpty) ...[
          _periodLabel('🌅  Manhã'),
          const SizedBox(height: 8),
          _wrap(manha),
          const SizedBox(height: 16),
        ],
        if (tarde.isNotEmpty) ...[
          _periodLabel('☀️  Tarde'),
          const SizedBox(height: 8),
          _wrap(tarde),
          const SizedBox(height: 16),
        ],
        if (noite.isNotEmpty) ...[
          _periodLabel('🌙  Noite'),
          const SizedBox(height: 8),
          _wrap(noite),
        ],
      ],
    );
  }

  Widget _periodLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
        ),
      );

  Widget _wrap(List<TimeSlotModel> group) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: group.map((slot) {
          final sel = selectedTime == slot.time;
          final avail = slot.available && !_isPast(slot.time);
          return GestureDetector(
            onTap: avail ? () => onSelect(slot.time) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 82,
              height: 44,
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary
                    : avail
                        ? Colors.white
                        : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? AppColors.primary
                      : avail
                          ? AppColors.greyLight
                          : Colors.transparent,
                  width: sel ? 2 : 1,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : avail
                        ? const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ]
                        : null,
              ),
              child: Center(
                child: avail
                    ? Text(
                        slot.time,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: sel ? Colors.white : AppColors.dark,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Icon(Icons.lock_outline,
                              size: 10, color: AppColors.grey),
                        ],
                      ),
              ),
            ),
          );
        }).toList(),
      );
}

class _PetSelectCard extends StatelessWidget {
  final PetModel pet;
  final bool selected;
  final VoidCallback onTap;

  const _PetSelectCard(
      {required this.pet, required this.selected, required this.onTap});

  Widget _buildPetAvatar(PetModel pet, double radius) {
    final url = pet.imageUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image/')) {
        final bytes = base64Decode(url.split(',').last);
        return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
      }
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Text(pet.typeIcon, style: TextStyle(fontSize: radius * 0.9)),
    );
  }

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
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            _buildPetAvatar(pet, 22),
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
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 22),
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
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
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
                  if (service.description != null &&
                      service.description!.isNotEmpty)
                    Text(service.description!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey)),
                  const SizedBox(height: 3),
                  Text('Duração: ${service.durationMinutes} min',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey)),
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

class _BookingPaymentSheet extends StatefulWidget {
  final PetModel pet;
  final ServiceModel service;
  final DateTime scheduledAt;
  final String selectedTime;
  final String formattedDate;
  final EstablishmentModel? establishment;

  const _BookingPaymentSheet({
    required this.pet,
    required this.service,
    required this.scheduledAt,
    required this.selectedTime,
    required this.formattedDate,
    required this.establishment,
  });

  @override
  State<_BookingPaymentSheet> createState() => _BookingPaymentSheetState();
}

class _BookingPaymentSheetState extends State<_BookingPaymentSheet> {
  int _metodoIdx = 0;
  final _cardNumCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();
  int _parcelas = 1;

  static const _metodos = [
    ('PIX',         Icons.qr_code_2,           'Pix'),
    ('CREDIT_CARD', Icons.credit_card,          'Crédito'),
    ('DEBIT_CARD',  Icons.credit_card_outlined, 'Débito'),
    ('CASH',        Icons.money,                'Dinheiro'),
    ('BOLETO',      Icons.receipt_long,         'Boleto'),
  ];

  @override
  void dispose() {
    _cardNumCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  String get _selectedMethod => _metodos[_metodoIdx].$1;
  bool get _isCard => _selectedMethod == 'CREDIT_CARD' || _selectedMethod == 'DEBIT_CARD';

  Future<void> _pay() async {
    if (_isCard && _cardNumCtrl.text.replaceAll(' ', '').length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o número do cartão completo'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final pagamento = context.read<PagamentoProvider>();

    await pagamento.confirmar(
      userId: auth.user?.id ?? 'guest',
      amount: widget.service.price,
      method: _selectedMethod,
      deliveryMethod: 'PICKUP',
      cardNumber: _isCard ? _cardNumCtrl.text.replaceAll(' ', '') : null,
      installments: _selectedMethod == 'CREDIT_CARD' ? _parcelas : null,
    );

    if (!mounted) return;

    if (pagamento.status == PagamentoStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pagamento.errorMessage ?? 'Erro ao processar pagamento'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final payment = pagamento.paymentResult!;
    final payStatus = payment['status'] as String? ?? '';

    if (payStatus == 'REJECTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payment['rejectionReason'] ?? 'Pagamento recusado'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final booking = await context.read<BookingProvider>().createBooking(
      token: auth.token!,
      userId: auth.user!.id,
      userName: auth.user!.name,
      petId: widget.pet.id,
      petName: widget.pet.name,
      serviceName: widget.service.name,
      establishmentId: widget.establishment?.id ?? '',
      establishmentName: widget.establishment?.name ?? '',
      scheduledAt: widget.scheduledAt,
      price: widget.service.price,
    );

    if (!mounted) return;

    if (booking == null) {
      final err = context.read<BookingProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Erro ao criar agendamento'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (widget.establishment != null) {
      final dateStr =
          '${widget.scheduledAt.year}-${widget.scheduledAt.month.toString().padLeft(2, '0')}-${widget.scheduledAt.day.toString().padLeft(2, '0')}';
      try {
        await AvailabilityService.blockSlot(
          token: auth.token!,
          estabId: widget.establishment!.id,
          date: dateStr,
          time: widget.selectedTime,
          reason: 'Agendado',
        );
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pop(payment);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PagamentoProvider>().isLoading ||
        context.watch<BookingProvider>().isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Pagamento do Serviço',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _summaryRow('Serviço:', widget.service.name),
                          _summaryRow('Pet:', widget.pet.name),
                          _summaryRow('Data:', widget.formattedDate),
                          _summaryRow('Horário:', widget.selectedTime),
                          if (widget.establishment != null)
                            _summaryRow('Local:', widget.establishment!.name),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.dark)),
                              Text(
                                'R\$ ${widget.service.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Forma de pagamento',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark)),
                    const SizedBox(height: 12),
                    ...List.generate(
                      _metodos.length,
                      (i) => _SheetPayTile(
                        icon: _metodos[i].$2,
                        label: _metodos[i].$3,
                        selected: _metodoIdx == i,
                        onTap: () => setState(() => _metodoIdx = i),
                      ),
                    ),

                    if (_isCard) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Dados do cartão de ${_selectedMethod == 'CREDIT_CARD' ? 'crédito' : 'débito'}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark),
                      ),
                      const SizedBox(height: 12),
                      _cardField(_cardNumCtrl, 'Número do cartão',
                          maxLen: 19, fmt: [_BookingCardNumFmt()]),
                      const SizedBox(height: 10),
                      _cardField(_cardNameCtrl, 'Nome no cartão',
                          type: TextInputType.text,
                          caps: TextCapitalization.characters),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _cardField(_cardExpCtrl, 'MM/AA',
                                maxLen: 5, fmt: [_BookingExpiryFmt()])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _cardField(_cardCvvCtrl, 'CVV',
                                maxLen: 3, obscure: true)),
                      ]),
                      if (_selectedMethod == 'CREDIT_CARD') ...[
                        const SizedBox(height: 12),
                        const Text('Parcelas',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.grey)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _parcelas,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          items: List.generate(12, (i) => i + 1).map((n) {
                            final val =
                                (widget.service.price / n).toStringAsFixed(2);
                            return DropdownMenuItem(
                                value: n,
                                child: Text('${n}x de R\$ $val'));
                          }).toList(),
                          onChanged: (v) => setState(() => _parcelas = v ?? 1),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirmar Pagamento',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                    fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _cardField(
    TextEditingController ctrl,
    String hint, {
    int? maxLen,
    List<TextInputFormatter>? fmt,
    TextInputType type = TextInputType.number,
    TextCapitalization caps = TextCapitalization.none,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      obscureText: obscure,
      maxLength: maxLen,
      inputFormatters: fmt,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _SheetPayTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetPayTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? AppColors.primary : AppColors.greyLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            Icon(icon,
                size: 22,
                color:
                    selected ? AppColors.primary : AppColors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primary : AppColors.dark,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ]),
        ),
      );
}

class _BookingCardNumFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _BookingExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    String str = digits;
    if (digits.length >= 3) {
      str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (str.length > 5) str = str.substring(0, 5);
    return TextEditingValue(
        text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}
