export class Product {
  private readonly _id?: string;
  private _establishmentId?: string;
  private _name!: string;
  private _brand!: string;
  private _price!: number;
  private _unit!: string;
  private _category!: string;
  private _description!: string;
  private _stock!: number;
  private _imageUrl?: string;
  private _active!: boolean;
  private readonly _createdAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined { return this._id; }
  get establishmentId(): string | undefined { return this._establishmentId; }
  get name(): string { return this._name; }
  get brand(): string { return this._brand; }
  get price(): number { return this._price; }
  get unit(): string { return this._unit; }
  get category(): string { return this._category; }
  get description(): string { return this._description; }
  get stock(): number { return this._stock; }
  get imageUrl(): string | undefined { return this._imageUrl; }
  get active(): boolean { return this._active; }
  get createdAt(): Date | undefined { return this._createdAt; }

  withName(v: string) { this._name = v; return this; }
  withBrand(v: string) { this._brand = v; return this; }
  withPrice(v: number) { this._price = v; return this; }
  withUnit(v: string) { this._unit = v; return this; }
  withCategory(v: string) { this._category = v; return this; }
  withDescription(v: string) { this._description = v; return this; }
  withStock(v: number) { this._stock = v; return this; }
  withImageUrl(v?: string) { this._imageUrl = v; return this; }
  withActive(v: boolean) { this._active = v; return this; }

  static restore(props?: {
    id?: string;
    establishmentId?: string | null;
    name: string;
    brand: string;
    price: number;
    unit: string;
    category: string;
    description: string;
    stock: number;
    imageUrl?: string | null;
    active: boolean;
    createdAt?: Date;
  }): Product | null {
    if (!props) return null;
    const p = new Product(props.id, props.createdAt);
    p._establishmentId = props.establishmentId ?? undefined;
    p._name = props.name;
    p._brand = props.brand;
    p._price = props.price;
    p._unit = props.unit;
    p._category = props.category;
    p._description = props.description;
    p._stock = props.stock;
    p._imageUrl = props.imageUrl ?? undefined;
    p._active = props.active;
    return p;
  }
}
