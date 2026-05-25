import { ApiProperty } from "@nestjs/swagger";
import { IsInt, IsUUID, Min } from "class-validator";

export class AddCartItemDto {
  @ApiProperty({ description: "ID do produto" })
  @IsUUID()
  productId!: string;

  @ApiProperty({ description: "Quantidade", minimum: 1 })
  @IsInt()
  @Min(1)
  quantity!: number;
}
