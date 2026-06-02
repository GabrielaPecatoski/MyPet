export type OrderStatus = "PENDING" | "CONFIRMED" | "DELIVERED" | "CANCELLED";

export class Order {
  private readonly _id?: string;
  private _userId!: string;
  private _total!: number;
  private _status!: OrderStatus;
  private _items!: OrderItemData[];
  private readonly _createdAt?: Date;

  private constructor(id?: string, createdAt?: Date) {
    this._id = id;
    this._createdAt = createdAt;
  }

  get id(): string | undefined { return this._id; }
  get userId(): string { return this._userId; }
  get total(): number { return this._total; }
  get status(): OrderStatus { return this._status; }
  get items(): OrderItemData[] { return this._items; }
  get createdAt(): Date | undefined { return this._createdAt; }

  static restore(props?: {
    id?: string;
    userId: string;
    total: number;
    status: OrderStatus;
    items: OrderItemData[];
    createdAt?: Date;
  }): Order | null {
    if (!props) return null;
    const o = new Order(props.id, props.createdAt);
    o._userId = props.userId;
    o._total = props.total;
    o._status = props.status;
    o._items = props.items;
    return o;
  }
}

export interface OrderItemData {
  id?: string;
  productId: string;
  quantity: number;
  price: number;
}
