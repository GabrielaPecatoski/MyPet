export type VeterinarianStatus = "PENDENTE" | "ATIVO" | "INATIVO" | "REJEITADO";

export class Veterinarian {
  private readonly _id?: string;
  private _establishmentId?: string;
  private _name!: string;
  private _phone!: string;
  private _cpf!: string;
  private _crmv!: string;
  private _especialidade?: string;
  private _photoUrl?: string;
  private _status!: VeterinarianStatus;
  private _disponivel = false;
  private _atendeDomicilio = false;
  private _atende24h = false;
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
  get establishmentId(): string | undefined {
    return this._establishmentId;
  }
  get name(): string {
    return this._name;
  }
  get phone(): string {
    return this._phone;
  }
  get cpf(): string {
    return this._cpf;
  }
  get crmv(): string {
    return this._crmv;
  }
  get especialidade(): string | undefined {
    return this._especialidade;
  }
  get photoUrl(): string | undefined {
    return this._photoUrl;
  }
  get status(): VeterinarianStatus {
    return this._status;
  }
  get disponivel(): boolean {
    return this._disponivel;
  }
  get atendeDomicilio(): boolean {
    return this._atendeDomicilio;
  }
  get atende24h(): boolean {
    return this._atende24h;
  }
  get isAprovado(): boolean {
    return this._status === "ATIVO";
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }
  get updatedAt(): Date | undefined {
    return this._updatedAt;
  }

  withStatus(status: VeterinarianStatus) {
    this._status = status;
    return this;
  }
  withEstablishment(establishmentId: string | undefined) {
    this._establishmentId = establishmentId;
    return this;
  }
  withDisponivel(disponivel: boolean) {
    this._disponivel = disponivel;
    return this;
  }
  withAtendeDomicilio(v: boolean) {
    this._atendeDomicilio = v;
    return this;
  }
  withAtende24h(v: boolean) {
    this._atende24h = v;
    return this;
  }
  withPhotoUrl(photoUrl: string | undefined) {
    this._photoUrl = photoUrl;
    return this;
  }

  static restore(props?: {
    id?: string;
    establishmentId?: string | null;
    name: string;
    phone: string;
    cpf: string;
    crmv: string;
    especialidade?: string | null;
    photoUrl?: string | null;
    status?: string | null;
    disponivel?: boolean | null;
    atendeDomicilio?: boolean | null;
    atende24h?: boolean | null;
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
    v._photoUrl = props.photoUrl ?? undefined;
    v._status = (props.status ?? "PENDENTE") as VeterinarianStatus;
    v._disponivel = props.disponivel ?? false;
    v._atendeDomicilio = props.atendeDomicilio ?? false;
    v._atende24h = props.atende24h ?? false;
    return v;
  }
}
