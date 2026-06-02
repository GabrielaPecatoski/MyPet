export type ComplaintStatus = "PENDENTE" | "EM_ANALISE" | "RESOLVIDA" | "REJEITADA";

export class Complaint {
  private readonly _id?: string;
  private _establishmentId!: string;
  private _userId!: string;
  private _userName!: string;
  private _bookingId?: string;
  private _subject!: string;
  private _description!: string;
  private _category!: string;
  private _status!: ComplaintStatus;
  private _response?: string;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get establishmentId(): string { return this._establishmentId; }
  get userId(): string { return this._userId; }
  get userName(): string { return this._userName; }
  get bookingId(): string | undefined { return this._bookingId; }
  get subject(): string { return this._subject; }
  get description(): string { return this._description; }
  get category(): string { return this._category; }
  get status(): ComplaintStatus { return this._status; }
  get response(): string | undefined { return this._response; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withStatus(status: ComplaintStatus) { this._status = status; return this; }
  withResponse(response: string) { this._response = response; return this; }

  toJSON() {
    return {
      id: this._id,
      establishmentId: this._establishmentId,
      userId: this._userId,
      userName: this._userName,
      bookingId: this._bookingId,
      subject: this._subject,
      description: this._description,
      category: this._category,
      status: this._status,
      response: this._response,
      createdAt: this._createdAt,
      updatedAt: this._updatedAt,
    };
  }

  static restore(props?: {
    id?: string;
    establishmentId: string;
    userId: string;
    userName: string;
    bookingId?: string;
    subject: string;
    description: string;
    category: string;
    status: ComplaintStatus;
    response?: string;
    createdAt?: Date;
    updatedAt?: Date;
  }): Complaint | null {
    if (!props) return null;
    const c = new Complaint(props.id, props.createdAt, props.updatedAt);
    c._establishmentId = props.establishmentId;
    c._userId = props.userId;
    c._userName = props.userName;
    c._bookingId = props.bookingId;
    c._subject = props.subject;
    c._description = props.description;
    c._category = props.category;
    c._status = props.status;
    c._response = props.response;
    return c;
  }
}
