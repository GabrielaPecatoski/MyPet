export class EstabService {
  private readonly _id?: string;
  private _establishmentId!: string;
  private _name!: string;
  private _price!: number;
  private _durationMinutes!: number;
  private _description!: string;

  private constructor(id?: string) {
    this._id = id;
  }

  get id(): string | undefined { return this._id; }
  get establishmentId(): string { return this._establishmentId; }
  get name(): string { return this._name; }
  get price(): number { return this._price; }
  get durationMinutes(): number { return this._durationMinutes; }
  get description(): string { return this._description; }

  withEstablishmentId(id: string) { this._establishmentId = id; return this; }
  withName(name: string) { this._name = name; return this; }
  withPrice(price: number) { this._price = price; return this; }
  withDurationMinutes(duration: number) { this._durationMinutes = duration; return this; }
  withDescription(description: string) { this._description = description; return this; }

  static restore(props?: {
    id?: string;
    establishmentId: string;
    name: string;
    price: number;
    durationMinutes: number;
    description: string;
  }): EstabService | null {
    if (!props) return null;
    const s = new EstabService(props.id);
    s._establishmentId = props.establishmentId;
    s._name = props.name;
    s._price = props.price;
    s._durationMinutes = props.durationMinutes;
    s._description = props.description;
    return s;
  }
}
