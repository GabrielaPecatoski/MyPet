class ApiConstants {
  // Para Android emulator: 10.0.2.2 | Para dispositivo físico: IP da máquina
  static const baseUrl = 'http://10.0.2.2:3000';
  static const loginEndpoint = '/auth/login';
  static const registerEndpoint = '/auth/register';

  // Marketplace
  static const productsEndpoint = '/marketplace/products';
  static const cartEndpoint = '/marketplace/cart';
  static const ordersEndpoint = '/marketplace/orders';

  // Pets
  static const petsEndpoint = '/pets/user';

  // Bookings
  static const bookingsEndpoint = '/bookings';

  // Establishments
  static const establishmentsEndpoint = '/establishments';
}
