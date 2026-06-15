export class EstabService {
  private readonly _id?: string;
  private _establishmentId!: string;
  private _name!: string;
  private _price!: number;
  private _priceVariable!: boolean;
  private _durationMinutes!: number;
  private _description!: string;
  private _categoria!: string;
  private _imagemUrl?: string;
  private _ativo!: boolean;

  private constructor(id?: string) {
    this._id = id;
  }

  get id(): string | undefined {
    return this._id;
  }
  get establishmentId(): string {
    return this._establishmentId;
  }
  get name(): string {
    return this._name;
  }
  get price(): number {
    return this._price;
  }
  get priceVariable(): boolean {
    return this._priceVariable;
  }
  get durationMinutes(): number {
    return this._durationMinutes;
  }
  get description(): string {
    return this._description;
  }
  get categoria(): string {
    return this._categoria;
  }
  get imagemUrl(): string | undefined {
    return this._imagemUrl;
  }
  get ativo(): boolean {
    return this._ativo;
  }

  withEstablishmentId(id: string) {
    this._establishmentId = id;
    return this;
  }
  withName(name: string) {
    this._name = name;
    return this;
  }
  withPrice(price: number) {
    this._price = price;
    return this;
  }
  withPriceVariable(v: boolean) {
    this._priceVariable = v;
    return this;
  }
  withDurationMinutes(duration: number) {
    this._durationMinutes = duration;
    return this;
  }
  withDescription(description: string) {
    this._description = description;
    return this;
  }
  withCategoria(categoria: string) {
    this._categoria = categoria;
    return this;
  }
  withImagemUrl(imagemUrl?: string) {
    this._imagemUrl = imagemUrl;
    return this;
  }
  withAtivo(ativo: boolean) {
    this._ativo = ativo;
    return this;
  }

  static restore(props?: {
    id?: string;
    establishmentId: string;
    name: string;
    price: number;
    priceVariable?: boolean | null;
    durationMinutes: number;
    description: string;
    categoria?: string | null;
    imagemUrl?: string | null;
    ativo?: boolean | null;
  }): EstabService | null {
    if (!props) return null;
    const s = new EstabService(props.id);
    s._establishmentId = props.establishmentId;
    s._name = props.name;
    s._price = props.price;
    s._priceVariable = props.priceVariable ?? false;
    s._durationMinutes = props.durationMinutes;
    s._description = props.description;
    s._categoria = props.categoria ?? "outros";
    s._imagemUrl = props.imagemUrl ?? undefined;
    s._ativo = props.ativo ?? true;
    return s;
  }
}
