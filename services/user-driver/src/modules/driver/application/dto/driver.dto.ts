import type { Driver } from "@driver/driver/domain/models/driver.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class DriverDto {
  @ApiProperty() id: string | undefined;
  @ApiPropertyOptional() establishmentId: string | undefined;
  @ApiProperty() name: string;
  @ApiProperty() phone: string;
  @ApiProperty() cpf: string;
  @ApiProperty() cnh: string;
  @ApiProperty() vehicleType: string;
  @ApiProperty() vehicleModel: string;
  @ApiProperty() vehiclePlate: string;
  @ApiProperty() status: string;
  @ApiPropertyOptional() createdAt: Date | undefined;

  private constructor(d: Driver) {
    this.id = d.id;
    this.establishmentId = d.establishmentId;
    this.name = d.name;
    this.phone = d.phone;
    this.cpf = d.cpf;
    this.cnh = d.cnh;
    this.vehicleType = d.vehicleType;
    this.vehicleModel = d.vehicleModel;
    this.vehiclePlate = d.vehiclePlate;
    this.status = d.status;
    this.createdAt = d.createdAt;
  }

  static fromDriver(d: Driver | null): DriverDto | null {
    if (!d) return null;
    return new DriverDto(d);
  }
}
