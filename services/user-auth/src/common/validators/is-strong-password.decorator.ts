import { BadRequestException } from "@nestjs/common";
import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from "class-validator";
import { PasswordValidator } from "./password.validator";

@ValidatorConstraint({ name: "isStrongPassword", async: false })
export class IsStrongPasswordConstraint implements ValidatorConstraintInterface {
  validate(password: string): boolean {
    const result = PasswordValidator.validate(password);
    return result.isStrong;
  }

  defaultMessage(): string {
    return "A senha não atende aos critérios de segurança";
  }
}

export function IsStrongPassword(validationOptions?: ValidationOptions) {
  return function (target: object, propertyName: string) {
    registerDecorator({
      target: target.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsStrongPasswordConstraint,
    });
  };
}
