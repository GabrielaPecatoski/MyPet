export type VeterinarianStatus = 'ATIVO' | 'INATIVO';

export class Veterinarian {
  private readonly _id?: string;
  private _establishmentId?: string;
  private _name!: string;
  private _phone!: string;
  private _cpf!: string;
  private _crmv!: string;
  private _especialidade?: string;
  private _status!: VeterinarianStatus;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get establishmentId(): string | undefined { return this._establishmentId; }
  get name(): string { return this._name; }
  get phone(): string { return this._phone; }
  get cpf(): string { return this._cpf; }
  get crmv(): string { return this._crmv; }
  get especialidade(): string | undefined { return this._especialidade; }
  get status(): VeterinarianStatus { return this._status; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withStatus(status: VeterinarianStatus) { this._status = status; return this; }
  withEstablishment(establishmentId: string | undefined) { this._establishmentId = establishmentId; return this; }

  static restore(props?: {
    id?: string;
    establishmentId?: string | null;
    name: string;
    phone: string;
    cpf: string;
    crmv: string;
    especialidade?: string | null;
    status?: string | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): Veterinarian | null {
    if (!props) return null;
    const v = new Veterinarian(props.id, props.createdAt, props.updatedAt);
    v._establishmentId = props.establishmentId ?? undefined;
    v._name = props.name;
    v._phone = props.phone;
    v._cpf = props.cpf;
    v._crmv = props.crmv;
    v._especialidade = props.especialidade ?? undefined;
    v._status = (props.status ?? 'ATIVO') as VeterinarianStatus;
    return v;
  }
}
