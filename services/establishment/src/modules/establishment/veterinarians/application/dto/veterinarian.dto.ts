import type { Veterinarian } from '@estab/veterinarians/domain/models/veterinarian.entity';
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
    this.createdAt = v.createdAt;
  }

  static fromVet(v: Veterinarian | null): VeterinarianDto | null {
    if (!v) return null;
    return new VeterinarianDto(v);
  }
}
