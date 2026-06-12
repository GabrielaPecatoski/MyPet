export type BookingStatus = "AGUARDANDO_PAGAMENTO" | "PENDENTE" | "CONFIRMADO" | "RECUSADO" | "CANCELADO" | "CONCLUIDO";

export type PaymentStatus = "NONE" | "AUTHORIZED" | "CAPTURED" | "REFUNDED";

export interface BookingServiceItem {
  id: string;
  name: string;
  price: number;
  durationMinutes: number;
}

export class Booking {
  private readonly _id?: string;
  private _userId!: string;
  private _userName!: string;
  private _petId!: string;
  private _petName!: string;
  private _serviceName!: string;
  private _servicesJson?: string;
  private _establishmentId!: string;
  private _establishmentName!: string;
  private _scheduledAt!: Date;
  private _price!: number;
  private _status!: BookingStatus;
  private _paymentStatus!: PaymentStatus;
  private _paymentMethod?: string;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get userId(): string { return this._userId; }
  get userName(): string { return this._userName; }
  get petId(): string { return this._petId; }
  get petName(): string { return this._petName; }
  get serviceName(): string { return this._serviceName; }
  get servicesJson(): string | undefined { return this._servicesJson; }
  get services(): BookingServiceItem[] {
    if (!this._servicesJson) return [];
    try { return JSON.parse(this._servicesJson); } catch { return []; }
  }
  get establishmentId(): string { return this._establishmentId; }
  get establishmentName(): string { return this._establishmentName; }
  get scheduledAt(): Date { return this._scheduledAt; }
  get price(): number { return this._price; }
  get status(): BookingStatus { return this._status; }
  get paymentStatus(): PaymentStatus { return this._paymentStatus; }
  get paymentMethod(): string | undefined { return this._paymentMethod; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withStatus(status: BookingStatus) { this._status = status; return this; }
  withPayment(paymentStatus: PaymentStatus, method?: string) {
    this._paymentStatus = paymentStatus;
    if (method !== undefined) this._paymentMethod = method;
    return this;
  }

  static restore(props?: {
    id?: string;
    userId: string;
    userName: string;
    petId: string;
    petName: string;
    serviceName: string;
    servicesJson?: string | null;
    establishmentId: string;
    establishmentName: string;
    scheduledAt: Date;
    price: number;
    status: BookingStatus;
    paymentStatus?: PaymentStatus | null;
    paymentMethod?: string | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): Booking | null {
    if (!props) return null;
    const b = new Booking(props.id, props.createdAt, props.updatedAt);
    b._userId = props.userId;
    b._userName = props.userName;
    b._petId = props.petId;
    b._petName = props.petName;
    b._serviceName = props.serviceName;
    b._servicesJson = props.servicesJson ?? undefined;
    b._establishmentId = props.establishmentId;
    b._establishmentName = props.establishmentName;
    b._scheduledAt = props.scheduledAt;
    b._price = props.price;
    b._status = props.status as BookingStatus;
    b._paymentStatus = (props.paymentStatus as PaymentStatus) ?? "NONE";
    b._paymentMethod = props.paymentMethod ?? undefined;
    return b;
  }
}
