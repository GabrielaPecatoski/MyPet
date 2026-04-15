import { IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateComplaintStatusDto {
  @IsIn(['PENDENTE', 'RESPONDIDA', 'ARQUIVADA', 'REMOVIDA'])
  status: 'PENDENTE' | 'RESPONDIDA' | 'ARQUIVADA' | 'REMOVIDA';

  @IsOptional() @IsString() moderatorNote?: string;
}
