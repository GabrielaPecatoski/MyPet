import type { User } from "@auth/users/domain/models/user.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class UserDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() name: string;
  @ApiProperty() email: string;
  @ApiProperty() phone: string;
  @ApiProperty() cpf: string;
  @ApiPropertyOptional() birthDate?: string;
  @ApiProperty() role: string;
  @ApiProperty() permissions: string[];
  @ApiProperty() addresses: unknown[];
  @ApiProperty() createdAt: Date | undefined;

  private constructor(
    id: string | undefined,
    name: string,
    email: string,
    phone: string,
    cpf: string,
    birthDate: string | undefined,
    role: string,
    permissions: string[],
    addresses: unknown[],
    createdAt: Date | undefined,
  ) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.cpf = cpf;
    this.birthDate = birthDate;
    this.role = role;
    this.permissions = permissions;
    this.addresses = addresses;
    this.createdAt = createdAt;
  }

  static fromUser(user: User | null): UserDto | null {
    if (!user) return null;
    let addresses: unknown[] = [];
    try {
      const parsed = JSON.parse(user.addresses);
      if (Array.isArray(parsed)) addresses = parsed;
    } catch {
      addresses = [];
    }
    return new UserDto(
      user.id,
      user.name,
      user.email,
      user.phone,
      user.cpf,
      user.birthDate,
      user.role,
      user.permissions,
      addresses,
      user.createdAt,
    );
  }
}
