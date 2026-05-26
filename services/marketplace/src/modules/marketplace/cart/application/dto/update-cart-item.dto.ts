import { ApiProperty } from "@nestjs/swagger";
import { IsInt, Min } from "class-validator";

export class UpdateCartItemDto {
  @ApiProperty({ description: "Nova quantidade", minimum: 1 })
  @IsInt()
  @Min(1)
  quantity!: number;
}
