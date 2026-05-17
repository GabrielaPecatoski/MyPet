export class Pet {
  private readonly _id?: string;
  private _userId!: string;
  private _name!: string;
  private _type!: string;
  private _breed!: string;
  private _age!: number;
  private _weight!: number;
  private _imageUrl?: string;
  private _notes?: string;
  private readonly _createdAt?: Date;
  private readonly _updatedAt?: Date;

  private constructor(id?: string, createdAt?: Date, updatedAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
    this._updatedAt = updatedAt;
  }

  get id(): string | undefined { return this._id; }
  get userId(): string { return this._userId; }
  get name(): string { return this._name; }
  get type(): string { return this._type; }
  get breed(): string { return this._breed; }
  get age(): number { return this._age; }
  get weight(): number { return this._weight; }
  get imageUrl(): string | undefined { return this._imageUrl; }
  get notes(): string | undefined { return this._notes; }
  get createdAt(): Date | undefined { return this._createdAt; }
  get updatedAt(): Date | undefined { return this._updatedAt; }

  withUserId(userId: string) { this._userId = userId; return this; }
  withName(name: string) { this._name = name; return this; }
  withType(type: string) { this._type = type; return this; }
  withBreed(breed: string) { this._breed = breed; return this; }
  withAge(age: number) { this._age = age; return this; }
  withWeight(weight: number) { this._weight = weight; return this; }
  withImageUrl(imageUrl?: string) { this._imageUrl = imageUrl; return this; }
  withNotes(notes?: string) { this._notes = notes; return this; }

  static restore(props?: {
    id?: string;
    userId: string;
    name: string;
    type: string;
    breed: string;
    age: number;
    weight: number;
    imageUrl?: string;
    notes?: string;
    createdAt?: Date;
    updatedAt?: Date;
  }): Pet | null {
    if (!props) return null;
    const pet = new Pet(props.id, props.createdAt, props.updatedAt);
    pet._userId = props.userId;
    pet._name = props.name;
    pet._type = props.type;
    pet._breed = props.breed;
    pet._age = props.age;
    pet._weight = props.weight;
    pet._imageUrl = props.imageUrl;
    pet._notes = props.notes;
    return pet;
  }
}
