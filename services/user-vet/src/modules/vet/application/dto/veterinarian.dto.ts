import type { Veterinarian } from '@vet/vet/domain/models/veterinarian.entity';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class VeterinarianDto {
  @ApiProperty() id: string | undefined;
  @ApiPropertyOptional() establishmentId: string | undefined;
  @ApiProperty() name: string;
  @ApiProperty() phone: string;
  @ApiProperty() cpf: string;
  @ApiProperty() crmv: string;
  @ApiPropertyOptional() especialidade: string | undefined;
  @ApiProperty() status: string;
  @ApiProperty() disponivel: boolean;
  @ApiProperty() atendeDomicilio: boolean;
  @ApiProperty() atende24h: boolean;
  @ApiPropertyOptional() createdAt: Date | undefined;

  private constructor(v: Veterinarian) {
    this.id = v.id;
    this.establishmentId = v.establishmentId;
    this.name = v.name;
    this.phone = v.phone;
    this.cpf = v.cpf;
    this.crmv = v.crmv;
    this.especialidade = v.especialidade;
    this.status = v.status;
    this.disponivel = v.disponivel;
    this.atendeDomicilio = v.atendeDomicilio;
    this.atende24h = v.atende24h;
    this.createdAt = v.createdAt;
  }

  static fromVet(v: Veterinarian | null): VeterinarianDto | null {
    if (!v) return null;
    return new VeterinarianDto(v);
  }
}
