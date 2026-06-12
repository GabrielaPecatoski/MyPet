import type { User } from "@auth/users/domain/models/user.entity";
import { ApiProperty } from "@nestjs/swagger";

export class UserDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() name: string;
  @ApiProperty() email: string;
  @ApiProperty() phone: string;
  @ApiProperty() cpf: string;
  @ApiProperty() role: string;
  @ApiProperty() permissions: string[];
  @ApiProperty() createdAt: Date | undefined;

  private constructor(
    id: string | undefined,
    name: string,
    email: string,
    phone: string,
    cpf: string,
    role: string,
    permissions: string[],
    createdAt: Date | undefined,
  ) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.cpf = cpf;
    this.role = role;
    this.permissions = permissions;
    this.createdAt = createdAt;
  }

  static fromUser(user: User | null): UserDto | null {
    if (!user) return null;
    return new UserDto(
      user.id,
      user.name,
      user.email,
      user.phone,
      user.cpf,
      user.role,
      user.permissions,
      user.createdAt,
    );
  }
}
