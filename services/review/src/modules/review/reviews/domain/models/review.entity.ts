export class Review {
  private readonly _id?: string;
  private _establishmentId!: string;
  private _userId!: string;
  private _userName!: string;
  private _bookingId?: string;
  private _rating!: number;
  private _comment!: string;
  private readonly _createdAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined {
    return this._id;
  }
  get establishmentId(): string {
    return this._establishmentId;
  }
  get userId(): string {
    return this._userId;
  }
  get userName(): string {
    return this._userName;
  }
  get bookingId(): string | undefined {
    return this._bookingId;
  }
  get rating(): number {
    return this._rating;
  }
  get comment(): string {
    return this._comment;
  }
  get createdAt(): Date | undefined {
    return this._createdAt;
  }

  static restore(props?: {
    id?: string;
    establishmentId: string;
    userId: string;
    userName: string;
    bookingId?: string | null;
    rating: number;
    comment: string;
    createdAt?: Date;
  }): Review | null {
    if (!props) return null;
    const r = new Review(props.id, props.createdAt);
    r._establishmentId = props.establishmentId;
    r._userId = props.userId;
    r._userName = props.userName;
    r._bookingId = props.bookingId ?? undefined;
    r._rating = props.rating;
    r._comment = props.comment;
    return r;
  }
}
