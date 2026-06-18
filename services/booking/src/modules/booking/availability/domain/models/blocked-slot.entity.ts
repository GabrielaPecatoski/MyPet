export class BlockedSlot {
  private readonly _id?: string;
  private _establishmentId?: string;
  private _vetId?: string;
  private _date!: string;
  private _startTime!: string;
  private _endTime!: string;
  private _reason?: string;

  private constructor(id?: string) {
    this._id = id;
  }

  get id(): string | undefined {
    return this._id;
  }
  get establishmentId(): string | undefined {
    return this._establishmentId;
  }
  get vetId(): string | undefined {
    return this._vetId;
  }
  get date(): string {
    return this._date;
  }
  get startTime(): string {
    return this._startTime;
  }
  get endTime(): string {
    return this._endTime;
  }
  get reason(): string | undefined {
    return this._reason;
  }

  static restore(props?: {
    id?: string;
    establishmentId?: string | null;
    vetId?: string | null;
    date: string;
    startTime: string;
    endTime: string;
    reason?: string;
  }): BlockedSlot | null {
    if (!props) return null;
    const b = new BlockedSlot(props.id);
    b._establishmentId = props.establishmentId ?? undefined;
    b._vetId = props.vetId ?? undefined;
    b._date = props.date;
    b._startTime = props.startTime;
    b._endTime = props.endTime;
    b._reason = props.reason;
    return b;
  }
}
