import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2';
    return 'http://localhost';
  }

  static const loginEndpoint = '/auth/login';
  static const registerEndpoint = '/auth/register';
  static const forgotPasswordEndpoint = '/auth/forgot-password';
  static const resetPasswordEndpoint = '/auth/reset-password';

  static const productsEndpoint = '/marketplace/products';
  static const cartEndpoint = '/marketplace/cart';
  static const ordersEndpoint = '/marketplace/orders';
  static const paymentsEndpoint = '/marketplace/payments';

  static const petsEndpoint = '/pets/user';
  static const bookingsEndpoint = '/bookings';
  static const bookingPaymentEndpoint = '/bookings/{id}/pay';
  static const establishmentsEndpoint = '/establishments';
  static const reviewsEndpoint = '/reviews';
  static const driversEndpoint = '/drivers';
  static const veterinariansEndpoint = '/veterinarians';
}
