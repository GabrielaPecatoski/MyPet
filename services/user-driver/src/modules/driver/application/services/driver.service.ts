import {
  CreateDriverDto,
  UpdateDriverPhotoDto,
} from "@driver/driver/application/dto/create-driver.dto";
import { DriverDto } from "@driver/driver/application/dto/driver.dto";
import { Driver } from "@driver/driver/domain/models/driver.entity";
import {
  DRIVER_REPOSITORY,
  type DriverRepository,
} from "@driver/driver/domain/repositories/driver-repository.interface";
import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";

@Injectable()
export class DriverService {
  constructor(
    @Inject(DRIVER_REPOSITORY)
    private readonly repo: DriverRepository,
  ) {}

  async register(dto: CreateDriverDto): Promise<DriverDto> {
    const byCpf = await this.repo.findByCpf(dto.cpf);
    if (byCpf) throw new ConflictException("CPF já cadastrado como motorista");

    const driver = Driver.restore({
      establishmentId: dto.establishmentId,
      name: dto.name,
      phone: dto.phone,
      cpf: dto.cpf,
      cnh: dto.cnh,
      vehicleType: dto.vehicleType,
      vehicleModel: dto.vehicleModel,
      vehiclePlate: dto.vehiclePlate,
      photoUrl: dto.photoUrl,
      status: "PENDENTE",
    })!;

    const created = await this.repo.create(driver);
    return DriverDto.fromDriver(created)!;
  }

  async findAll(): Promise<DriverDto[]> {
    const rows = await this.repo.findAll();
    return rows.map((d) => DriverDto.fromDriver(d)!);
  }

  async findPending(): Promise<DriverDto[]> {
    const rows = await this.repo.findByStatus("PENDENTE");
    return rows.map((d) => DriverDto.fromDriver(d)!);
  }

  async approve(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withStatus("ATIVO");
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async reject(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withStatus("REJEITADO");
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async findByEstablishment(establishmentId: string): Promise<DriverDto[]> {
    const rows = await this.repo.findByEstablishment(establishmentId);
    return rows.map((d) => DriverDto.fromDriver(d)!);
  }

  async findUnassociated(): Promise<DriverDto[]> {
    const rows = await this.repo.findUnassociated();
    return rows.map((d) => DriverDto.fromDriver(d)!);
  }

  async findByCpf(cpf: string): Promise<DriverDto | null> {
    return DriverDto.fromDriver(await this.repo.findByCpf(cpf));
  }

  async findById(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    return DriverDto.fromDriver(driver)!;
  }

  async updatePhoto(
    id: string,
    dto: UpdateDriverPhotoDto,
  ): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withPhotoUrl(dto.photoUrl);
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async associate(id: string, establishmentId: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    if (driver.establishmentId) {
      throw new ConflictException(
        "Motorista já está associado a um estabelecimento",
      );
    }
    driver.withEstablishment(establishmentId);
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async dissociate(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withEstablishment(undefined);
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async deactivate(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withStatus("INATIVO");
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async activate(id: string): Promise<DriverDto> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    driver.withStatus("ATIVO");
    await this.repo.update(driver);
    return DriverDto.fromDriver(driver)!;
  }

  async remove(id: string): Promise<void> {
    const driver = await this.repo.findById(id);
    if (!driver) throw new NotFoundException("Motorista não encontrado");
    await this.repo.delete(id);
  }
}
