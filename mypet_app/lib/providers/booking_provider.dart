import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/establishment.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  List<AppointmentModel> _bookings = [];
  bool _loading = false;
  String? _error;

  List<AppointmentModel> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;

  List<AppointmentModel> get confirmados =>
      _bookings.where((b) => b.isConfirmado || b.isACaminho).toList();

  List<AppointmentModel> get pendentes =>
      _bookings.where((b) => b.isPendente || b.isAguardandoPagamento).toList();

  List<AppointmentModel> get ativos =>
      _bookings.where((b) => b.isActive).toList();

  List<AppointmentModel> get historico => _bookings
      .where((b) => b.status == 'CONCLUIDO' || b.status == 'CANCELADO' || b.status == 'RECUSADO')
      .toList();

  Future<void> loadUserBookings({required String token, required String userId}) async {
    _error = null;
    if (_bookings.isEmpty) {
      _loading = true;
      notifyListeners();
    }
    try {
      _bookings = await BookingService.fetchUserBookings(token: token, userId: userId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadEstabBookings({required String token, required String estabId}) async {
    _error = null;
    if (_bookings.isEmpty) {
      _loading = true;
      notifyListeners();
    }
    try {
      _bookings = await BookingService.fetchEstabBookings(token: token, estabId: estabId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AppointmentModel?> createBooking({
    required String token,
    required String userName,
    required String petId,
    required String petName,
    required String serviceName,
    String? establishmentId,
    String? establishmentName,
    required DateTime scheduledAt,
    double price = 0,
    bool priceVariable = false,
    List<ServiceModel>? services,
    String? driverId,
    String? driverName,
    String? vetId,
    String? vetName,
    String? address,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final booking = await BookingService.createBooking(
        token: token,
        userName: userName,
        petId: petId,
        petName: petName,
        serviceName: serviceName,
        establishmentId: establishmentId,
        establishmentName: establishmentName,
        scheduledAt: scheduledAt,
        price: price,
        priceVariable: priceVariable,
        services: services,
        driverId: driverId,
        driverName: driverName,
        vetId: vetId,
        vetName: vetName,
        address: address,
      );
      _bookings.add(booking);
      _loading = false;
      notifyListeners();
      return booking;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking({required String token, required String bookingId}) async {
    _error = null;
    try {
      final updated = await BookingService.cancelBooking(token: token, bookingId: bookingId);
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsPaid({
    required String token,
    required String bookingId,
  }) async {
    _error = null;
    try {
      final updated = await BookingService.markAsPaid(token: token, bookingId: bookingId);
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus({
    required String token,
    required String bookingId,
    required String status,
  }) async {
    _error = null;
    try {
      final updated = await BookingService.updateStatus(
          token: token, bookingId: bookingId, status: status);
      final idx = _bookings.indexWhere((b) => b.id == bookingId);
      if (idx != -1) _bookings[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
