import { IsIn } from 'class-validator';

export class UpdateBookingStatusDto {
  @IsIn(['CONFIRMADO', 'RECUSADO']) status: 'CONFIRMADO' | 'RECUSADO';
}
