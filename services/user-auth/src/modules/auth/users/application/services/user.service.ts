import { UpdateUserDto } from "@auth/users/application/dto/update-user.dto";
import { UserDto } from "@auth/users/application/dto/user.dto";
import {
  USER_REPOSITORY,
  type UserRepository,
} from "@auth/users/domain/repositories/user-repository.interface";
import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PaginatedResult, PaginationParams } from "@shared/infra/hateoas";
import * as bcrypt from "bcryptjs";

@Injectable()
export class UserService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
  ) {}

  async findById(id: string): Promise<UserDto | null> {
    const user = await this.userRepository.findById(id);
    return UserDto.fromUser(user);
  }

  async list(): Promise<UserDto[]> {
    const users = await this.userRepository.findAll();
    return users.map((u) => UserDto.fromUser(u)!);
  }

  async listPaginated(
    params: PaginationParams,
  ): Promise<PaginatedResult<UserDto>> {
    const { rows, total } = await this.userRepository.findAllPaginated(params);
    return {
      data: rows.map((u) => UserDto.fromUser(u)!),
      total,
      page: params.page,
      limit: params.limit,
    };
  }

  async update(id: string, dto: UpdateUserDto): Promise<void> {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException("Usuário não encontrado");

    if (dto.email && dto.email !== user.email) {
      const existing = await this.userRepository.findByEmail(dto.email);
      if (existing) throw new ConflictException("Email já em uso");
    }

    if (dto.name) user.withName(dto.name);
    if (dto.email) user.withEmail(dto.email.toLowerCase());
    if (dto.phone) user.withPhone(dto.phone);
    if (dto.photoUrl !== undefined) user.withPhotoUrl(dto.photoUrl);
    if (dto.password) {
      const hashed = await bcrypt.hash(dto.password, 10);
      user.withPassword(hashed);
    }

    await this.userRepository.update(user);
  }

  async remove(id: string): Promise<void> {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException("Usuário não encontrado");
    await this.userRepository.delete(id);
  }
}
