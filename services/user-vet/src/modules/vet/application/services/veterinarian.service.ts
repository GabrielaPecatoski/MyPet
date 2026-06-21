import {
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import {
  EmergencyExchangeName,
  EmergencyRoutingKey,
} from "@shared/contracts/events/emergency-events.enum";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";
import {
  CreateVeterinarianDto,
  UpdateVetAvailabilityDto,
  UpdateVetPhotoDto,
} from "@vet/vet/application/dto/create-veterinarian.dto";
import { CreateEmergencyCallDto } from "@vet/vet/application/dto/emergency-call.dto";
import { VeterinarianDto } from "@vet/vet/application/dto/veterinarian.dto";
import { Veterinarian } from "@vet/vet/domain/models/veterinarian.entity";
import {
  VETERINARIAN_REPOSITORY,
  type VeterinarianRepository,
} from "@vet/vet/domain/repositories/veterinarian-repository.interface";
import { VetEmergencyCallsRepository } from "@vet/vet/infra/repositories/vet-emergency-calls.repository";

@Injectable()
export class VeterinarianService {
  private readonly logger = new Logger(VeterinarianService.name);

  constructor(
    @Inject(VETERINARIAN_REPOSITORY)
    private readonly repo: VeterinarianRepository,
    private readonly callsRepo: VetEmergencyCallsRepository,
    private readonly messagingService: SharedMessagingService,
  ) {}

  async register(dto: CreateVeterinarianDto): Promise<VeterinarianDto> {
    const byCpf = await this.repo.findByCpf(dto.cpf);
    if (byCpf)
      throw new ConflictException("CPF já cadastrado como veterinário");
    const vet = Veterinarian.restore({
      establishmentId: dto.establishmentId,
      name: dto.name,
      phone: dto.phone,
      cpf: dto.cpf,
      crmv: dto.crmv,
      especialidade: dto.especialidade,
      photoUrl: dto.photoUrl,
      status: "PENDENTE",
      disponivel: false,
      atendeDomicilio: dto.atendeDomicilio ?? false,
      atende24h: dto.atende24h ?? false,
    })!;
    return VeterinarianDto.fromVet(await this.repo.create(vet))!;
  }

  async findAll(): Promise<VeterinarianDto[]> {
    return (await this.repo.findAll()).map((v) => VeterinarianDto.fromVet(v)!);
  }

  async findPending(): Promise<VeterinarianDto[]> {
    return (await this.repo.findByStatus("PENDENTE")).map(
      (v) => VeterinarianDto.fromVet(v)!,
    );
  }

  async findAvailable(): Promise<VeterinarianDto[]> {
    return (await this.repo.findAvailable()).map(
      (v) => VeterinarianDto.fromVet(v)!,
    );
  }

  async findByEstablishment(
    establishmentId: string,
  ): Promise<VeterinarianDto[]> {
    return (await this.repo.findByEstablishment(establishmentId)).map(
      (v) => VeterinarianDto.fromVet(v)!,
    );
  }

  async findUnassociated(): Promise<VeterinarianDto[]> {
    return (await this.repo.findUnassociated()).map(
      (v) => VeterinarianDto.fromVet(v)!,
    );
  }

  async findByCpf(cpf: string): Promise<VeterinarianDto | null> {
    return VeterinarianDto.fromVet(await this.repo.findByCpf(cpf));
  }

  async findById(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    return VeterinarianDto.fromVet(vet)!;
  }

  async approve(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withStatus("ATIVO");
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async reject(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withStatus("REJEITADO").withDisponivel(false);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async updateAvailability(
    id: string,
    dto: UpdateVetAvailabilityDto,
  ): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    if (dto.disponivel === true && vet.status !== "ATIVO") {
      throw new ForbiddenException(
        "Veterinário ainda não foi aprovado pelo administrador",
      );
    }
    if (dto.disponivel !== undefined) vet.withDisponivel(dto.disponivel);
    if (dto.atendeDomicilio !== undefined)
      vet.withAtendeDomicilio(dto.atendeDomicilio);
    if (dto.atende24h !== undefined) vet.withAtende24h(dto.atende24h);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async updatePhoto(
    id: string,
    dto: UpdateVetPhotoDto,
  ): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withPhotoUrl(dto.photoUrl);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async associate(
    id: string,
    establishmentId: string,
  ): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    if (vet.establishmentId)
      throw new ConflictException(
        "Veterinário já está associado a um estabelecimento",
      );
    vet.withEstablishment(establishmentId);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async dissociate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withEstablishment(undefined);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async deactivate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withStatus("INATIVO");
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async activate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    vet.withStatus("ATIVO");
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async remove(id: string): Promise<void> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");
    await this.repo.delete(id);
  }

  async createEmergencyCall(vetId: string, dto: CreateEmergencyCallDto) {
    const vet = await this.repo.findById(vetId);
    if (!vet) throw new NotFoundException("Veterinário não encontrado");

    const call = await this.callsRepo.create({
      vetId,
      callerName: dto.callerName,
      callerPhone: dto.callerPhone ?? "",
      petDescription: dto.petDescription,
    });

    try {
      await this.messagingService.assertExchange(
        EmergencyExchangeName.VET_CALL,
      );
      await this.messagingService.publish(
        EmergencyExchangeName.VET_CALL,
        EmergencyRoutingKey.VET_CALL,
        {
          callId: call.id,
          vetId,
          vetName: vet.name,
          callerName: dto.callerName,
          callerPhone: dto.callerPhone ?? "",
          petDescription: dto.petDescription ?? null,
        },
      );
    } catch (err) {
      this.logger.warn("RabbitMQ publish failed for emergency call", err);
    }

    return call;
  }

  async getPendingEmergencyCalls(vetId: string) {
    return this.callsRepo.findPending(vetId);
  }

  async acknowledgeEmergencyCall(callId: string): Promise<void> {
    await this.callsRepo.acknowledge(callId);
  }
}
