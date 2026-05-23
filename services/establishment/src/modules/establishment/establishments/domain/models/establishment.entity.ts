export class Establishment {
  private readonly _id?: string;
  private _ownerId!: string;
  private _name!: string;
  private _description!: string;
  private _address!: string;
  private _city!: string;
  private _phone!: string;
  private _type!: string;
  private _rating!: number;
  private _reviewCount!: number;
  private _imageUrl?: string;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get ownerId(): string { return this._ownerId; }
  get name(): string { return this._name; }
  get description(): string { return this._description; }
  get address(): string { return this._address; }
  get city(): string { return this._city; }
  get phone(): string { return this._phone; }
  get type(): string { return this._type; }
  get rating(): number { return this._rating; }
  get reviewCount(): number { return this._reviewCount; }
  get imageUrl(): string | undefined { return this._imageUrl; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withOwnerId(ownerId: string) { this._ownerId = ownerId; return this; }
  withName(name: string) { this._name = name; return this; }
  withDescription(description: string) { this._description = description; return this; }
  withAddress(address: string) { this._address = address; return this; }
  withCity(city: string) { this._city = city; return this; }
  withPhone(phone: string) { this._phone = phone; return this; }
  withType(type: string) { this._type = type; return this; }
  withRating(rating: number) { this._rating = rating; return this; }
  withReviewCount(reviewCount: number) { this._reviewCount = reviewCount; return this; }
  withImageUrl(imageUrl?: string) { this._imageUrl = imageUrl; return this; }

  static restore(props?: {
    id?: string;
    ownerId: string;
    name: string;
    description: string;
    address: string;
    city: string;
    phone: string;
    type: string;
    rating: number;
    reviewCount: number;
    imageUrl?: string | null;
    createdAt?: Date;
    updatedAt?: Date;
  }): Establishment | null {
    if (!props) return null;
    const e = new Establishment(props.id, props.createdAt, props.updatedAt);
    e._ownerId = props.ownerId;
    e._name = props.name;
    e._description = props.description;
    e._address = props.address;
    e._city = props.city;
    e._phone = props.phone;
    e._type = props.type;
    e._rating = props.rating;
    e._reviewCount = props.reviewCount;
    e._imageUrl = props.imageUrl ?? undefined;
    return e;
  }
}
