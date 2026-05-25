export class Schedule {
  private readonly _id?: string;
  private _establishmentId!: string;
  private _dayOfWeek!: number;
  private _openTime!: string;
  private _closeTime!: string;
  private _slotDuration!: number;
  private _isOpen!: boolean;
  private _capacity!: number;

  private constructor(id?: string) { this._id = id; }

  get id(): string | undefined { return this._id; }
  get establishmentId(): string { return this._establishmentId; }
  get dayOfWeek(): number { return this._dayOfWeek; }
  get openTime(): string { return this._openTime; }
  get closeTime(): string { return this._closeTime; }
  get slotDuration(): number { return this._slotDuration; }
  get isOpen(): boolean { return this._isOpen; }
  get capacity(): number { return this._capacity; }

  static restore(props?: {
    id?: string;
    establishmentId: string;
    dayOfWeek: number;
    openTime: string;
    closeTime: string;
    slotDuration: number;
    isOpen?: boolean;
    capacity?: number;
  }): Schedule | null {
    if (!props) return null;
    const s = new Schedule(props.id);
    s._establishmentId = props.establishmentId;
    s._dayOfWeek = props.dayOfWeek;
    s._openTime = props.openTime;
    s._closeTime = props.closeTime;
    s._slotDuration = props.slotDuration;
    s._isOpen = props.isOpen ?? true;
    s._capacity = props.capacity ?? 1;
    return s;
  }
}
