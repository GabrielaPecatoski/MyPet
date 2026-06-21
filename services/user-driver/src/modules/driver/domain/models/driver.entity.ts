export type DriverStatus = "PENDENTE" | "ATIVO" | "INATIVO" | "REJEITADO";
export type VehicleType = "CARRO" | "MOTO" | "VAN";

export class Driver {
  private readonly _id?: string;
  private _establishmentId?: string;
  private _name!: string;
  private _phone!: string;
  private _cpf!: string;
  private _cnh!: string;
  private _vehicleType!: VehicleType;
  private _vehicleModel!: string;
  private _vehiclePlate!: string;
  private _photoUrl?: string;
  private _status!: DriverStatus;
  private _online: boolean = false;
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
  get cnh(): string {
    return this._cnh;
  }
  get vehicleType(): VehicleType {
    return this._vehicleType;
  }
  get vehicleModel(): string {
    return this._vehicleModel;
  }
  get vehiclePlate(): string {
    return this._vehiclePlate;
  }
  get photoUrl(): string | undefined {
    return this._photoUrl;
  }
  get status(): DriverStatus {
    return this._status;
  }
  get online(): boolean {
    return this._online;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }
  get updatedAt(): Date | undefined {
    return this._updatedAt;
  }

  withStatus(status: DriverStatus) {
    this._status = status;
    return this;
  }
  withEstablishment(establishmentId: string | undefined) {
    this._establishmentId = establishmentId;
    return this;
  }
  withPhotoUrl(photoUrl: string | undefined) {
    this._photoUrl = photoUrl;
    return this;
  }
  withOnline(online: boolean) {
    this._online = online;
    return this;
  }

  static restore(props?: {
    id?: string;
    establishmentId?: string | null;
    name: string;
    phone: string;
    cpf: string;
    cnh: string;
    vehicleType: string;
    vehicleModel: string;
    vehiclePlate: string;
    photoUrl?: string | null;
    status?: string | null;
    online?: boolean | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): Driver | null {
    if (!props) return null;
    const d = new Driver(props.id, props.createdAt, props.updatedAt);
    d._establishmentId = props.establishmentId ?? undefined;
    d._name = props.name;
    d._phone = props.phone;
    d._cpf = props.cpf;
    d._cnh = props.cnh;
    d._vehicleType = props.vehicleType as VehicleType;
    d._vehicleModel = props.vehicleModel;
    d._vehiclePlate = props.vehiclePlate;
    d._photoUrl = props.photoUrl ?? undefined;
    d._status = (props.status ?? "PENDENTE") as DriverStatus;
    d._online = props.online ?? false;
    return d;
  }
}
