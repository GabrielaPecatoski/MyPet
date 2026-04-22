import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000';
  }

  static const loginEndpoint = '/auth/login';
  static const registerEndpoint = '/auth/register';

  static const productsEndpoint = '/marketplace/products';
  static const cartEndpoint = '/marketplace/cart';
  static const ordersEndpoint = '/marketplace/orders';

  static const petsEndpoint = '/pets/user';
  static const bookingsEndpoint = '/bookings';
  static const establishmentsEndpoint = '/establishments';
  static const reviewsEndpoint = '/reviews';
}
