import '../models/driver.dart';
import '../services/driver_service.dart';

abstract class IDriverRegisterRepository {
  Future<DriverModel> register({
    required String token,
    String? establishmentId,
    required String name,
    required String phone,
    required String cpf,
    required String cnh,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlate,
    String? cnhPhotoUrl,
  });
}

class DriverRegisterRepository implements IDriverRegisterRepository {
  @override
  Future<DriverModel> register({
    required String token,
    String? establishmentId,
    required String name,
    required String phone,
    required String cpf,
    required String cnh,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlate,
    String? cnhPhotoUrl,
  }) =>
      DriverService.register(
        token: token,
        establishmentId: establishmentId,
        name: name,
        phone: phone,
        cpf: cpf,
        cnh: cnh,
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        vehiclePlate: vehiclePlate,
        cnhPhotoUrl: cnhPhotoUrl,
      );
}
