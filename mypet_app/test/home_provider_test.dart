import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/models/establishment.dart';
import 'package:mypet_app/providers/home_provider.dart';
import 'package:mypet_app/repositories/establishment_list_repository.dart';

EstablishmentModel _estab(String id, {String type = 'PET_SHOP'}) =>
    EstablishmentModel(
      id: id,
      ownerId: 'owner',
      name: 'Estab $id',
      description: '',
      type: type,
      address: '',
      rawAddress: '',
      city: '',
      phone: '',
      rating: 4.0,
      reviewCount: 0,
    );

class _FakeRepo implements IEstablishmentListRepository {
  _FakeRepo(this.items);
  final List<EstablishmentModel> items;

  @override
  Future<List<EstablishmentModel>> getAll() async => items;
}

void main() {
  group('HomeProvider.distanceKm', () {
    test('é determinística — mesmo id devolve sempre o mesmo valor', () {
      final e = _estab('abc-123');
      expect(HomeProvider.distanceKm(e), HomeProvider.distanceKm(e));
    });

    test('fica na faixa ~0,3–9,7 km para ids variados', () {
      for (final id in ['a', 'b', 'xyz', 'estab-0', 'estab-42', '00000000']) {
        final d = HomeProvider.distanceKm(_estab(id));
        expect(d, greaterThanOrEqualTo(0.3));
        expect(d, lessThan(9.8));
      }
    });
  });

  group('HomeProvider.nearby', () {
    test('ordena do mais próximo ao mais distante e limita a 5', () async {
      final items = List.generate(7, (i) => _estab('estab-$i'));
      final provider = HomeProvider(_FakeRepo(items));
      await provider.load();

      final nearby = provider.nearby;
      expect(nearby.length, 5, reason: 'deve mostrar no máximo 5');

      // distâncias não-decrescentes (mais próximo primeiro)
      for (var i = 1; i < nearby.length; i++) {
        expect(
          HomeProvider.distanceKm(nearby[i]),
          greaterThanOrEqualTo(HomeProvider.distanceKm(nearby[i - 1])),
        );
      }

      // são exatamente os 5 estabelecimentos mais próximos
      final expected = [...items]..sort((a, b) =>
          HomeProvider.distanceKm(a).compareTo(HomeProvider.distanceKm(b)));
      expect(
        nearby.map((e) => e.id),
        expected.take(5).map((e) => e.id),
      );
    });

    test('respeita o filtro de categoria atual', () async {
      final items = [
        _estab('vet-1', type: 'VETERINARIA'),
        _estab('shop-1'),
        _estab('vet-2', type: 'VETERINARIA'),
        _estab('shop-2'),
      ];
      final provider = HomeProvider(_FakeRepo(items));
      await provider.load();

      provider.filterByType('Veterinário');

      expect(provider.nearby, isNotEmpty);
      expect(
        provider.nearby.every((e) => e.isVeterinario),
        isTrue,
        reason: 'só veterinários quando o filtro Veterinário está ativo',
      );
    });
  });
}
