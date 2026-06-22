import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/colors.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../services/geocoding_service.dart';
import '../widgets/mypet_app_bar.dart';

/// Gerencia os endereços do perfil (vários) de qualquer conta. As coordenadas
/// são obtidas por geocodificação (OSM) ao salvar, para uso em serviços
/// próximos e na rota do transporte.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late List<AddressModel> _addresses;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addresses =
        List.of(context.read<AuthProvider>().user?.addresses ?? const []);
  }

  Future<void> _editAddress({AddressModel? existing}) async {
    final result = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddressForm(existing: existing),
    );
    if (result == null) return;
    setState(() {
      final i = _addresses.indexWhere((a) => a.id == result.id);
      if (i >= 0) {
        _addresses[i] = result;
      } else {
        _addresses.add(result);
      }
    });
  }

  void _remove(AddressModel a) {
    setState(() => _addresses.removeWhere((x) => x.id == a.id));
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _saving = true);

    // Geocodifica os endereços que ainda não têm coordenadas.
    final resolved = <AddressModel>[];
    for (final a in _addresses) {
      if (a.hasCoords || a.fullText.isEmpty) {
        resolved.add(a);
        continue;
      }
      final coords = await GeocodingService.geocode(a.fullText);
      resolved
          .add(coords == null ? a : a.copyWith(lat: coords.lat, lng: coords.lng));
    }

    final ok = await auth.updateProfile(
      name: user.name,
      phone: user.phone,
      addresses: resolved.map((a) => a.toJson()).toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Endereços salvos!' : (auth.error ?? 'Erro ao salvar')),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MypetAppBar(showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editAddress(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Adicionar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: const Icon(Icons.location_on_outlined,
                              size: 34, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('Nenhum endereço cadastrado',
                            style: TextStyle(
                                color: AppColors.dark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Toque em "Adicionar" para cadastrar.',
                            style:
                                TextStyle(color: AppColors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      const Text('Meus endereços',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark)),
                      const SizedBox(height: 4),
                      const Text(
                        'Usados como ponto de coleta/entrega do transporte e para mostrar serviços próximos.',
                        style: TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                      const SizedBox(height: 16),
                      ..._addresses.map(_card),
                    ],
                  ),
          ),
          if (_addresses.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: AppColors.background,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('Salvar endereços',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(AddressModel a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.label.isEmpty ? 'Endereço' : a.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.dark)),
                  const SizedBox(height: 2),
                  Text(a.fullText.isEmpty ? 'Sem detalhes' : a.fullText,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.grey)),
                  if (!a.hasCoords)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Localização será definida ao salvar',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.warning)),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.grey),
              onPressed: () => _editAddress(existing: a),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.danger),
              onPressed: () => _remove(a),
            ),
          ],
        ),
      );
}

class _AddressForm extends StatefulWidget {
  final AddressModel? existing;
  const _AddressForm({this.existing});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final TextEditingController _label;
  late final TextEditingController _cep;
  late final TextEditingController _street;
  late final TextEditingController _number;
  late final TextEditingController _district;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _cep = TextEditingController(text: e?.cep ?? '');
    _street = TextEditingController(text: e?.street ?? '');
    _number = TextEditingController(text: e?.number ?? '');
    _district = TextEditingController(text: e?.district ?? '');
    _city = TextEditingController(text: e?.city ?? '');
  }

  @override
  void dispose() {
    for (final c in [_label, _cep, _street, _number, _district, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final id = widget.existing?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();
    // Mantém coords só se for o mesmo endereço e o texto não mudou;
    // caso contrário deixa nulo para regeocodificar ao salvar.
    final e = widget.existing;
    final unchanged = e != null &&
        e.street == _street.text.trim() &&
        e.number == _number.text.trim() &&
        e.district == _district.text.trim() &&
        e.city == _city.text.trim();
    final result = AddressModel(
      id: id,
      label: _label.text.trim(),
      cep: _cep.text.trim(),
      street: _street.text.trim(),
      number: _number.text.trim(),
      district: _district.text.trim(),
      city: _city.text.trim(),
      lat: unchanged ? e.lat : null,
      lng: unchanged ? e.lng : null,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.existing == null ? 'Novo endereço' : 'Editar endereço',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark)),
            const SizedBox(height: 16),
            _field(_label, 'Identificação (ex: Casa, Trabalho)'),
            _field(_cep, 'CEP', keyboard: TextInputType.number),
            _field(_street, 'Rua'),
            _field(_number, 'Número', keyboard: TextInputType.number),
            _field(_district, 'Bairro'),
            _field(_city, 'Cidade'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar endereço',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
          {TextInputType keyboard = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.greyLight)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      );
}
