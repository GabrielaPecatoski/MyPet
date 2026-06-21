import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/pet.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/schedule_provider.dart';
import '../repositories/schedule_repository.dart';
import '../widgets/mypet_app_bar.dart';

class ScheduleArgs {
  final EstablishmentModel establishment;
  final String? vetId;
  final String? vetName;
  const ScheduleArgs({required this.establishment, this.vetId, this.vetName});
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScheduleProvider(ScheduleRepository()),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  PetModel? _selectedPet;
  final List<ServiceModel> _selectedServices = [];
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _wantsTransport = false;
  String? _vetId;
  String? _vetName;
  bool _servicesLoaded = false;

  static const _weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context
            .read<ScheduleProvider>()
            .loadPets(auth.user!.id, token: auth.token);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_servicesLoaded) {
      _servicesLoaded = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      EstablishmentModel? establishment;
      if (args is ScheduleArgs) {
        establishment = args.establishment;
        _vetId = args.vetId;
        _vetName = args.vetName;
      } else if (args is EstablishmentModel) {
        establishment = args;
      }
      if (establishment != null) {
        final estabId = establishment.id;
        final token = context.read<AuthProvider>().token;
        // Defer to after the frame: loadServicesAndDrivers() calls
        // notifyListeners() synchronously, which would mark the provider
        // dirty during build (the '!_dirty' assertion) if called here.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context
              .read<ScheduleProvider>()
              .loadServicesAndDrivers(estabId, token: token);
        });
      }
    }
  }

  EstablishmentModel? _establishment(BuildContext ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments;
    if (args is ScheduleArgs) return args.establishment;
    if (args is EstablishmentModel) return args;
    return null;
  }

  Future<void> _loadSlots(EstablishmentModel? establishment) async {
    if (_selectedDate == null || establishment == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    setState(() => _selectedTime = null);
    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final error = await context.read<ScheduleProvider>().loadSlots(
          estabId: establishment.id,
          date: dateStr,
          token: auth.token!,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar horários: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
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
        _selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o pet, pelo menos um serviço, data e horário'),
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

    final allVariable = _selectedServices.every((s) => s.priceVariable);
    final totalPrice = allVariable ? 0.0 : _selectedServices.fold<double>(0, (s, svc) => s + svc.price);
    final serviceNameDisplay = _selectedServices.map((s) => s.name).join(', ');

    final booking = await context.read<BookingProvider>().createBooking(
          token: auth.token!,
          userName: auth.user!.name,
          petId: _selectedPet!.id,
          petName: _selectedPet!.name,
          petBreed: _selectedPet!.breed,
          petAge: _selectedPet!.age,
          serviceName: serviceNameDisplay,
          establishmentId: establishment?.id ?? '',
          establishmentName: establishment?.name ?? '',
          establishmentAddress: establishment?.address ?? '',
          scheduledAt: scheduledAt,
          price: totalPrice,
          priceVariable: allVariable,
          services: _selectedServices,
          transportRequested: _wantsTransport,
          vetId: _vetId,
          vetName: _vetName,
        );

    if (!mounted) return;

    if (booking != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.payment, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Quase lá!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _confirmRow('Pet:', _selectedPet!.name),
              _confirmRow('Serviço(s):', _selectedServices.map((s) => s.name).join(', ')),
              _confirmRow(
                'Data:',
                '${_weekdays[_selectedDate!.weekday % 7]}, ${_selectedDate!.day} ${_months[_selectedDate!.month - 1]}',
              ),
              _confirmRow('Horário:', _selectedTime!),
              _confirmRow(
                'Valor:',
                allVariable
                    ? 'Sob consulta'
                    : 'R\$ ${totalPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              Text(
                allVariable
                    ? 'O valor será definido pelo estabelecimento após o atendimento.'
                    : 'Realize o pagamento para confirmar o agendamento.',
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
          actions: [
            if (!allVariable) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(
                      context,
                      '/pagamento-agendamento',
                      arguments: booking,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Pagar Agora',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (r) => false,
                        arguments: 1);
                  },
                  child: const Text('Pagar depois',
                      style: TextStyle(color: AppColors.grey)),
                ),
              ),
            ] else
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
                  child: const Text('Ver Minha Agenda',
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
    final establishment = _establishment(context);
    final booking = context.watch<BookingProvider>();
    final schedule = context.watch<ScheduleProvider>();

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
                if (_vetName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined,
                            color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Veterinário: $_vetName',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32)),
                          ),
                        ),
                      ],
                    ),
                  ),
                _sectionTitle('Selecione o pet'),
                const SizedBox(height: 10),
                if (schedule.loadingPets)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppColors.primary)))
                else if (schedule.pets.isEmpty)
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
                  ...schedule.pets.map((pet) => _PetSelectCard(
                        pet: pet,
                        selected: _selectedPet?.id == pet.id,
                        onTap: () => setState(() => _selectedPet = pet),
                      )),

                const SizedBox(height: 24),

                _sectionTitle('Selecione os serviços'),
                const SizedBox(height: 10),
                if (schedule.loadingServices)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (schedule.services.isNotEmpty)
                  ...schedule.services.map((s) {
                    final sel = _selectedServices.any((x) => x.id == s.id);
                    return _ServiceSelectCard(
                      service: s,
                      selected: sel,
                      onTap: () => setState(() {
                        if (sel) {
                          _selectedServices.removeWhere((x) => x.id == s.id);
                        } else {
                          _selectedServices.add(s);
                        }
                      }),
                    );
                  })
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
                if (_selectedServices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: ${_selectedServices.length} serviço(s)',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _selectedServices.every((s) => s.priceVariable)
                                ? 'Sob consulta'
                                : 'R\$ ${_selectedServices.where((s) => !s.priceVariable).fold<double>(0, (acc, svc) => acc + svc.price).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                _sectionTitle('Transporte do pet'),
                const SizedBox(height: 4),
                const Text(
                  'Quer que um motorista leve e traga seu pet? Um motorista disponível será designado automaticamente.',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _wantsTransport
                          ? AppColors.primary
                          : AppColors.greyLight,
                      width: _wantsTransport ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          color: _wantsTransport
                              ? AppColors.primary
                              : AppColors.grey,
                          size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Quero transporte para o pet',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark),
                        ),
                      ),
                      Switch(
                        value: _wantsTransport,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _wantsTransport = v),
                      ),
                    ],
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
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                  if (schedule.loadingSlots)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ))
                  else if (schedule.slots.isEmpty)
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
                      slots: schedule.slots,
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
                  service.priceLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: service.priceVariable ? AppColors.grey : AppColors.primary,
                      fontSize: service.priceVariable ? 13 : 15),
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
