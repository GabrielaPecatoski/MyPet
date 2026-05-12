import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../services/establishment_service.dart';

class EstablishmentProvider extends ChangeNotifier {
  EstablishmentModel? _establishment;
  bool _loading = false;
  String? _error;

  EstablishmentModel? get establishment => _establishment;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get establishmentId => _establishment?.id;
  List<ServiceModel> get services => _establishment?.services ?? [];

  Future<void> loadByOwner({
    required String token,
    required String ownerId,
    required String ownerName,
    required String ownerPhone,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      var estab = await EstablishmentService.fetchByOwner(
        token: token,
        ownerId: ownerId,
      );
      if (estab == null) {
        estab = await EstablishmentService.create(
          token: token,
          ownerId: ownerId,
          name: ownerName,
          phone: ownerPhone,
        );
      }
      _establishment = estab;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEstablishment({
    required String token,
    required String name,
    required String description,
    required String address,
    required String city,
    required String phone,
    required String type,
    String? imageUrl,
  }) async {
    if (_establishment == null) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await EstablishmentService.update(
        token: token,
        establishmentId: _establishment!.id,
        name: name,
        description: description,
        address: address,
        city: city,
        phone: phone,
        type: type,
        imageUrl: imageUrl,
      );
      _establishment = updated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEstablishment({required String token}) async {
    if (_establishment == null) return false;
    _error = null;
    try {
      await EstablishmentService.delete(
        token: token,
        establishmentId: _establishment!.id,
      );
      _establishment = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addService({
    required String token,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
  }) async {
    if (_establishment == null) return false;
    _error = null;
    try {
      final updated = await EstablishmentService.addService(
        token: token,
        establishmentId: _establishment!.id,
        name: name,
        price: price,
        durationMinutes: durationMinutes,
        description: description,
      );
      _establishment = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeService({
    required String token,
    required String serviceId,
  }) async {
    if (_establishment == null) return false;
    _error = null;
    try {
      final updated = await EstablishmentService.removeService(
        token: token,
        establishmentId: _establishment!.id,
        serviceId: serviceId,
      );
      _establishment = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _establishment = null;
    _error = null;
    notifyListeners();
  }
}
