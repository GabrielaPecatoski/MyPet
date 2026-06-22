export type BookingStatus =
  | "AGUARDANDO_PAGAMENTO"
  | "PENDENTE"
  | "CONFIRMADO"
  | "RECUSADO"
  | "CANCELADO"
  | "CONCLUIDO";

export type PaymentStatus = "NONE" | "AUTHORIZED" | "CAPTURED" | "REFUNDED";

export type TransportStatus = "NONE" | "PENDING" | "ACCEPTED";

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
  private _userEmail?: string;
  private _petId!: string;
  private _petName!: string;
  private _petBreed?: string;
  private _petAge?: number;
  private _petPhotoUrl?: string;
  private _serviceName!: string;
  private _servicesJson?: string;
  private _attendancePhotos?: string;
  private _establishmentId?: string;
  private _establishmentName!: string;
  private _establishmentAddress?: string;
  private _driverId?: string;
  private _driverName?: string;
  private _driverPhotoUrl?: string;
  private _transportStatus!: TransportStatus;
  private _vetId?: string;
  private _vetName?: string;
  private _scheduledAt!: Date;
  private _price!: number;
  private _priceVariable!: boolean;
  private _status!: BookingStatus;
  private _paymentStatus!: PaymentStatus;
  private _paymentMethod?: string;
  private _reminderSentAt?: Date;
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
  get userId(): string {
    return this._userId;
  }
  get userName(): string {
    return this._userName;
  }
  get userEmail(): string | undefined {
    return this._userEmail;
  }
  get petId(): string {
    return this._petId;
  }
  get petName(): string {
    return this._petName;
  }
  get petBreed(): string {
    return this._petBreed ?? "";
  }
  get petAge(): number {
    return this._petAge ?? 0;
  }
  get petPhotoUrl(): string | undefined {
    return this._petPhotoUrl;
  }
  get serviceName(): string {
    return this._serviceName;
  }
  get servicesJson(): string | undefined {
    return this._servicesJson;
  }
  get services(): BookingServiceItem[] {
    if (!this._servicesJson) return [];
    try {
      return JSON.parse(this._servicesJson);
    } catch {
      return [];
    }
  }
  get attendancePhotosJson(): string | undefined {
    return this._attendancePhotos;
  }
  get attendancePhotos(): string[] {
    if (!this._attendancePhotos) return [];
    try {
      return JSON.parse(this._attendancePhotos);
    } catch {
      return [];
    }
  }
  get establishmentId(): string | undefined {
    return this._establishmentId;
  }
  get establishmentName(): string {
    return this._establishmentName;
  }
  get establishmentAddress(): string {
    return this._establishmentAddress ?? "";
  }
  get driverId(): string | undefined {
    return this._driverId;
  }
  get driverName(): string | undefined {
    return this._driverName;
  }
  get driverPhotoUrl(): string | undefined {
    return this._driverPhotoUrl;
  }
  get transportStatus(): TransportStatus {
    return this._transportStatus;
  }
  get transportRequested(): boolean {
    return this._transportStatus !== "NONE";
  }
  get vetId(): string | undefined {
    return this._vetId;
  }
  get vetName(): string | undefined {
    return this._vetName;
  }
  get scheduledAt(): Date {
    return this._scheduledAt;
  }
  get price(): number {
    return this._price;
  }
  get priceVariable(): boolean {
    return this._priceVariable;
  }
  get status(): BookingStatus {
    return this._status;
  }
  get paymentStatus(): PaymentStatus {
    return this._paymentStatus;
  }
  get paymentMethod(): string | undefined {
    return this._paymentMethod;
  }
  get reminderSentAt(): Date | undefined {
    return this._reminderSentAt;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }
  get updatedAt(): Date | undefined {
    return this._updatedAt;
  }

  withStatus(status: BookingStatus) {
    this._status = status;
    return this;
  }
  withPayment(paymentStatus: PaymentStatus, method?: string) {
    this._paymentStatus = paymentStatus;
    if (method !== undefined) this._paymentMethod = method;
    return this;
  }
  withReminderSent(at: Date) {
    this._reminderSentAt = at;
    return this;
  }
  withAttendancePhotos(photos: string[]) {
    this._attendancePhotos = JSON.stringify(photos);
    return this;
  }
  withTransportStatus(status: TransportStatus) {
    this._transportStatus = status;
    return this;
  }
  withDriver(id: string, name?: string, photoUrl?: string) {
    this._driverId = id;
    this._driverName = name;
    this._driverPhotoUrl = photoUrl;
    return this;
  }

  static restore(props?: {
    id?: string;
    userId: string;
    userName: string;
    userEmail?: string | null;
    petId: string;
    petName: string;
    petBreed?: string | null;
    petAge?: number | null;
    petPhotoUrl?: string | null;
    serviceName: string;
    servicesJson?: string | null;
    attendancePhotos?: string | null;
    establishmentId?: string | null;
    establishmentName?: string | null;
    establishmentAddress?: string | null;
    driverId?: string | null;
    driverName?: string | null;
    driverPhotoUrl?: string | null;
    transportStatus?: string | null;
    vetId?: string | null;
    vetName?: string | null;
    scheduledAt: Date;
    price: number;
    priceVariable?: boolean | null;
    status: BookingStatus;
    paymentStatus?: PaymentStatus | null;
    paymentMethod?: string | null;
    reminderSentAt?: Date | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): Booking | null {
    if (!props) return null;
    const b = new Booking(props.id, props.createdAt, props.updatedAt);
    b._userId = props.userId;
    b._userName = props.userName;
    b._userEmail = props.userEmail ?? undefined;
    b._petId = props.petId;
    b._petName = props.petName;
    b._petBreed = props.petBreed ?? undefined;
    b._petAge = props.petAge ?? undefined;
    b._petPhotoUrl = props.petPhotoUrl ?? undefined;
    b._serviceName = props.serviceName;
    b._servicesJson = props.servicesJson ?? undefined;
    b._attendancePhotos = props.attendancePhotos ?? undefined;
    b._establishmentId = props.establishmentId ?? undefined;
    b._establishmentName = props.establishmentName ?? "";
    b._establishmentAddress = props.establishmentAddress ?? undefined;
    b._driverId = props.driverId ?? undefined;
    b._driverName = props.driverName ?? undefined;
    b._driverPhotoUrl = props.driverPhotoUrl ?? undefined;
    b._transportStatus = (props.transportStatus as TransportStatus) ?? "NONE";
    b._vetId = props.vetId ?? undefined;
    b._vetName = props.vetName ?? undefined;
    b._scheduledAt = props.scheduledAt;
    b._price = props.price;
    b._priceVariable = props.priceVariable ?? false;
    b._status = props.status as BookingStatus;
    b._paymentStatus = (props.paymentStatus as PaymentStatus) ?? "NONE";
    b._paymentMethod = props.paymentMethod ?? undefined;
    b._reminderSentAt = props.reminderSentAt ?? undefined;
    return b;
  }
}
