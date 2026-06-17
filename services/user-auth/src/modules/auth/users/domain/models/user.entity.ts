export type UserRole =
  | "ADMIN"
  | "CLIENTE"
  | "VENDEDOR"
  | "MOTORISTA"
  | "VETERINARIO";

export class User {
  private readonly _id?: string;
  private _name!: string;
  private _email!: string;
  private _password!: string;
  private _phone!: string;
  private _cpf!: string;
  private _role!: UserRole;
  private _permissions!: string[];
  private _photoUrl?: string | null;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined {
    return this._id;
  }
  get name(): string {
    return this._name;
  }
  get email(): string {
    return this._email;
  }
  get password(): string {
    return this._password;
  }
  get phone(): string {
    return this._phone;
  }
  get cpf(): string {
    return this._cpf;
  }
  get role(): UserRole {
    return this._role;
  }
  get permissions(): string[] {
    return this._permissions;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }
  get updatedAt(): Date | undefined {
    return this._updatedAt;
  }

  withName(name: string) {
    this._name = name;
    return this;
  }
  withEmail(email: string) {
    this._email = email;
    return this;
  }
  withPassword(password: string) {
    this._password = password;
    return this;
  }
  withPhone(phone: string) {
    this._phone = phone;
    return this;
  }
  withCpf(cpf: string) {
    this._cpf = cpf;
    return this;
  }
  withRole(role: UserRole) {
    this._role = role;
    return this;
  }
  withPermissions(permissions: string[]) {
    this._permissions = permissions;
    return this;
  }

  static restore(props?: {
    id?: string;
    name: string;
    email: string;
    password: string;
    phone: string;
    cpf: string;
    role: UserRole;
    permissions: string[];
    photoUrl?: string | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): User | null {
    if (!props) return null;
    const user = new User(props.id, props.createdAt, props.updatedAt);
    user._name = props.name;
    user._email = props.email;
    user._password = props.password;
    user._phone = props.phone;
    user._cpf = props.cpf;
    user._role = props.role;
    user._permissions = props.permissions;
    user._photoUrl = props.photoUrl;
    return user;
  }
}
